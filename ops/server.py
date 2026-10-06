"""Operating theatre: run the pipeline stage by stage, and watch the patient.

Runs on your machine. Two halves:

  the checklist  -- runs each stage script in the toolbox container, in the
                    order .github/workflows/pipeline.yml runs them, one
                    `docker compose run` per stage (so each stage's exit code
                    and timing are its own), then reads the report the stage
                    wrote to decide what to show as its evidence
  the monitor    -- the deployed app and Prometheus, through `kubectl proxy`
                    on the lab's kubeconfig: the app's own request counter,
                    the AppHighErrorRate expression exactly as the
                    PrometheusRule evaluates it, and Prometheus's alert state

Nothing is replayed: every tick is an exit code, every finding is a line in
a report, every point on the trace is a Prometheus sample.

Standard library only. Started by scripts/ops.sh.
"""

import json
import os
import re
import subprocess
import threading
import time
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
PORT = int(os.environ.get("OPS_PORT", "8097"))
PROXY_PORT = int(os.environ.get("KUBE_PROXY_PORT", "8098"))
KUBECONFIG = os.environ.get("KUBECONFIG_LAB", os.path.join(ROOT, ".cluster", "kubeconfig.yaml"))
REPORTS = os.path.join(ROOT, "reports")
COMPOSE = ["docker", "compose", "-f", os.path.join(ROOT, "runner", "docker-compose.yml")]
PROXY = f"http://127.0.0.1:{PROXY_PORT}"
APP = PROXY + "/api/v1/namespaces/app/services/app:80/proxy"
PROM = PROXY + "/api/v1/namespaces/monitoring/services/kube-prometheus-stack-prometheus:9090/proxy"

# (id, script, phase): the workflow's order. Pull requests stop after image-scan.
STAGES = [
    ("prepare", "prepare.sh", "sign-in"), ("sast", "sast.sh", "sign-in"), ("iac-scan", "iac-scan.sh", "sign-in"),
    ("build", "build.sh", "sign-in"), ("image-scan", "image-scan.sh", "sign-in"),
    ("push", "push.sh", "procedure"), ("deploy", "deploy.sh", "procedure"),
    ("dast", "dast.sh", "sign-out"), ("publish-reports", "publish-reports.sh", "sign-out"),
]
SCAN_STOP = "image-scan"

# The PrometheusRule's expression (helm/app/templates/prometheusrule.yaml), namespace "app".
ERROR_RATIO = ('sum(rate(flask_http_request_total{status=~"5..", namespace="app"}[1m]))'
               ' / sum(rate(flask_http_request_total{namespace="app"}[1m]))')
REQ_RATE = 'sum(rate(flask_http_request_total{namespace="app"}[1m]))'


def read(path, default=None):
    try:
        with open(os.path.join(REPORTS, path), encoding="utf-8") as f:
            return f.read().strip()
    except OSError:
        return default


def read_json(path):
    try:
        with open(os.path.join(REPORTS, path), encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


# --- a stage's evidence, read from the report it wrote -----------------------------

def evidence(stage):
    if stage == "sast":
        d = read_json("semgrep.json")
        if d is None:
            return None
        res = d.get("results", [])
        sev = {}
        for r in res:
            sev[r["extra"]["severity"]] = sev.get(r["extra"]["severity"], 0) + 1
        return {"tool": "Semgrep", "rule": "stops on any ERROR", "counts": sev,
                "items": [{"sev": r["extra"]["severity"], "what": r["check_id"].split(".")[-1],
                           "where": f'{r["path"].removeprefix("/workspace/")}:{r["start"]["line"]}'}
                          for r in sorted(res, key=lambda r: r["extra"]["severity"] != "ERROR")][:8]}
    if stage == "iac-scan":
        d = read_json("trivy-config.json")
        if d is None:
            return None
        mis = [(r.get("Target"), m) for r in d.get("Results", []) for m in r.get("Misconfigurations", []) or []]
        sev = {}
        for _, m in mis:
            sev[m["Severity"]] = sev.get(m["Severity"], 0) + 1
        order = ["CRITICAL", "HIGH", "MEDIUM", "LOW"]
        return {"tool": "Trivy config", "rule": "stops on a CRITICAL not accepted in .trivyignore.yaml", "counts": sev,
                "items": [{"sev": m["Severity"], "what": f'{m["ID"]} {m.get("Title", "")}', "where": t}
                          for t, m in sorted(mis, key=lambda x: order.index(x[1]["Severity"]) if x[1]["Severity"] in order else 9)][:8]}
    if stage == "image-scan":
        d = read_json("trivy-image.json")
        if d is None:
            return None
        vulns = [v for r in d.get("Results", []) for v in r.get("Vulnerabilities", []) or []]
        sev, crit_fix = {}, []
        for v in vulns:
            sev[v["Severity"]] = sev.get(v["Severity"], 0) + 1
            if v["Severity"] == "CRITICAL" and v.get("FixedVersion"):
                crit_fix.append(v)
        crit = [v for v in vulns if v["Severity"] == "CRITICAL"]
        sbom = read_json("sbom.cdx.json") or {}
        return {"tool": "Trivy image", "rule": "stops on a CRITICAL that has a fixed version", "counts": sev,
                "critical_with_fix": len(crit_fix), "sbom_components": len(sbom.get("components", [])),
                "image": read("image.txt"),
                "items": [{"sev": v["Severity"], "what": f'{v["VulnerabilityID"]} in {v["PkgName"]} {v.get("InstalledVersion", "")}',
                           "where": f'fixed in {v["FixedVersion"]}' if v.get("FixedVersion") else "no fix yet"}
                          for v in sorted(crit, key=lambda v: not v.get("FixedVersion"))][:8]}
    if stage == "dast":
        d = read_json("zap-baseline.json")
        if d is None:
            return None
        alerts = [a for s in d.get("site", []) for a in s.get("alerts", [])]
        sev = {}
        for a in alerts:
            k = a.get("riskdesc", "").split(" ")[0] or "Info"
            sev[k] = sev.get(k, 0) + 1
        return {"tool": "OWASP ZAP baseline", "rule": "stops on a FAIL-level rule; warnings are reported",
                "counts": sev, "items": [{"sev": a.get("riskdesc", "").split(" ")[0], "what": a.get("name", ""),
                                          "where": f'{a.get("count", "?")} instance(s)'} for a in alerts][:8]}
    if stage == "push":
        return {"pushed": read("pushed.txt"), "image": read("image.txt")}
    if stage in ("build", "prepare"):
        return {"tag": read("tag.txt"), "image": read("image.txt")}
    return None


# --- running the checklist -----------------------------------------------------------

class Theatre:
    def __init__(self):
        self.lock = threading.Lock()
        self.run = None
        self.proc = None

    def start(self, mode):
        with self.lock:
            if self.run and self.run["state"] == "running":
                raise RuntimeError("a run is already under way")
            plant = mode == "planted"
            last = SCAN_STOP if plant else STAGES[-1][0]
            stages = []
            for sid, script, phase in STAGES:
                stages.append({"id": sid, "phase": phase, "state": "waiting", "lines": [],
                               "skipped_by_mode": plant and [s[0] for s in STAGES].index(sid) > [s[0] for s in STAGES].index(last)})
            self.run = {"mode": mode, "plant": plant, "state": "running", "started": int(time.time() * 1000),
                        "stages": stages, "until": last}
        threading.Thread(target=self._go, daemon=True).start()
        return self.snapshot()

    def _go(self):
        r = self.run
        env = {**os.environ, "PLANT_VULN": "1" if r["plant"] else "0"}
        for i, st in enumerate(r["stages"]):
            if st["skipped_by_mode"]:
                st["state"] = "not in this procedure"
                continue
            if r["state"] != "running":
                st["state"] = "not started"
                continue
            script = STAGES[i][1]
            cmd = f"bash scripts/ci/{script}"
            if i == 0:
                cmd = "rm -rf reports && " + cmd   # pipeline.sh starts from a clean reports/
            st.update(state="running", started=int(time.time() * 1000))
            p = subprocess.Popen(COMPOSE + ["run", "--rm", "toolbox", cmd], cwd=ROOT, env=env,
                                 stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
                                 encoding="utf-8", errors="replace", bufsize=1)
            self.proc = p
            for line in p.stdout:
                line = re.sub(r"\x1b\[[0-9;]*m", "", line.rstrip())
                if line:
                    st["lines"].append(line)
                    del st["lines"][:-400]
            code = p.wait()
            st.update(exit=code, finished=int(time.time() * 1000), evidence=evidence(st["id"]),
                      state="go" if code == 0 else "no-go")
            if code != 0:
                r["state"] = "stopped"
                r["stopped_at"] = st["id"]
        if r["state"] == "running":
            r["state"] = "done"
        r["finished"] = int(time.time() * 1000)
        r["pushed"] = read("pushed.txt")
        self.proc = None

    def snapshot(self):
        with self.lock:
            return json.loads(json.dumps(self.run)) if self.run else None


THEATRE = Theatre()


# --- the patient --------------------------------------------------------------------

def kubectl_proxy():
    """One long-lived `kubectl proxy`, restarted if it dies."""
    while True:
        p = subprocess.Popen(["kubectl", "--kubeconfig", KUBECONFIG, "proxy", f"--port={PROXY_PORT}"],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        p.wait()
        time.sleep(3)


def get(url, timeout=6):
    with urllib.request.urlopen(url, timeout=timeout) as r:
        return r.status, r.read()


def prom(path, **params):
    _, body = get(f"{PROM}/api/v1/{path}?{urllib.parse.urlencode(params)}")
    return json.loads(body)["data"]


def patient():
    out, errors = {}, []

    def attempt(label, fn):
        try:
            return fn()
        except Exception as e:
            errors.append(f"{label}: {e}")
            return None

    dep = attempt("deployment", lambda: json.loads(get(f"{PROXY}/apis/apps/v1/namespaces/app/deployments/app")[1]))
    if dep:
        c = dep["spec"]["template"]["spec"]["containers"][0]
        out["deployment"] = {"image": c["image"], "tag": c["image"].rsplit(":", 1)[-1],
                             "replicas": dep["spec"].get("replicas"), "ready": dep["status"].get("readyReplicas", 0),
                             "revision": dep["metadata"].get("annotations", {}).get("deployment.kubernetes.io/revision")}
    now = time.time()
    rng = attempt("error ratio", lambda: prom("query_range", query=ERROR_RATIO, start=now - 600, end=now, step=10))
    # query_range answers {"resultType": "matrix", "result": [{"values": [[t, "v"], ...]}]};
    # an empty result means no traffic in the window (0/0 has no samples).
    # A window with no requests is 0/0 = NaN: a gap in the trace, not a value (and not valid JSON).
    out["error_ratio"] = ([[p[0], float(p[1])] for p in rng["result"][0]["values"] if p[1] not in ("NaN", "+Inf", "-Inf")]
                          if rng["result"] else []) if rng is not None else None
    rate = attempt("request rate", lambda: prom("query", query=REQ_RATE))
    rr = float(rate["result"][0]["value"][1]) if rate and rate["result"] else 0.0
    out["req_rate"] = rr if rr == rr else 0.0   # NaN guard
    alerts = attempt("alerts", lambda: prom("alerts"))
    mine = [a for a in (alerts or {}).get("alerts", []) if a["labels"].get("alertname") == "AppHighErrorRate"]
    out["alert"] = {"state": mine[0]["state"], "active_at": mine[0].get("activeAt"), "value": mine[0].get("value")} if mine else {"state": "inactive"}
    rules = attempt("rules", lambda: prom("rules", type="alert"))
    rule = next((r for g in (rules or {}).get("groups", []) for r in g["rules"] if r["name"] == "AppHighErrorRate"), None)
    if rule:
        out["rule"] = {"for_s": rule.get("duration"), "query": rule.get("query"), "health": rule.get("health")}
    out["errors"] = errors
    return out


class Snapshot:
    """The patient, refreshed in the background; requests read the latest copy."""

    def __init__(self):
        self.lock = threading.Lock()
        self.data = None

    def loop(self):
        while True:
            try:
                d = patient()
            except Exception as e:
                d = {"errors": [f"patient: {e}"]}
            d["read_at"] = int(time.time() * 1000)
            with self.lock:
                self.data = d
            time.sleep(4)

    def get(self):
        with self.lock:
            return self.data or {"reading": True, "errors": []}


PATIENT = Snapshot()


def treat(kind, count):
    """Send real requests to the app through the API server proxy."""
    count = max(1, min(60, count))
    path = {"boom": "/boom", "ok": "/", "health": "/healthz"}[kind]

    def one(_):
        t0 = time.monotonic()
        try:
            status, _ = get(APP + path, timeout=10)
        except urllib.error.HTTPError as e:
            status = e.code
        except Exception:
            status = 0
        return status, round((time.monotonic() - t0) * 1000)

    with ThreadPoolExecutor(max_workers=8) as pool:
        res = list(pool.map(one, range(count)))
    codes = {}
    for s, _ in res:
        codes[str(s)] = codes.get(str(s), 0) + 1
    return {"sent": count, "path": path, "codes": codes, "ms": sorted(m for _, m in res)[len(res) // 2]}


def cluster_name():
    """The EKS cluster's name from the Terraform outputs, read once."""
    try:
        out = subprocess.run(["terraform", f"-chdir={os.path.join(ROOT, 'terraform')}", "output", "-json"],
                             capture_output=True, text=True, timeout=60).stdout
        tf = {k: v["value"] for k, v in json.loads(out).items()}
        return next((v for k, v in tf.items() if "cluster" in k and "name" in k and isinstance(v, str)), None) \
            or next((v for k, v in tf.items() if k.startswith("cluster") and isinstance(v, str)), None)
    except Exception:
        return None


CLUSTER = cluster_name()


def chart():
    tag, repo = read("tag.txt"), read("repository.txt")
    return {"tag": tag, "image": read("image.txt"), "repository": repo, "pushed": read("pushed.txt"), "cluster": CLUSTER,
            "reports": sorted(os.listdir(REPORTS)) if os.path.isdir(REPORTS) else []}


# --- HTTP ---------------------------------------------------------------------

import urllib.error  # noqa: E402

FONT_TYPES = {".woff2": "font/woff2"}


class Handler(BaseHTTPRequestHandler):
    def send(self, status, body, ctype="application/json"):
        data = body if isinstance(body, bytes) else json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        path = self.path.split("?")[0]
        if path in ("/", "/index.html"):
            with open(os.path.join(HERE, "index.html"), "rb") as f:
                self.send(200, f.read(), "text/html; charset=utf-8")
        elif path == "/api/run":
            self.send(200, {"run": THEATRE.snapshot(), "chart": chart(), "now": int(time.time() * 1000)})
        elif path == "/api/patient":
            self.send(200, PATIENT.get())
        elif path == "/frame":
            q = self.path.partition("?")[2]
            w = re.search(r"(?:^|&)w=(\d+)", q)
            inner = re.sub(r"(?:^|&)w=\d+", "", q).lstrip("&")
            self.send(200, (f'<!doctype html><body style="margin:0"><iframe src="/?{inner}" '
                            f'style="width:{w[1] if w else 390}px;height:100vh;border:0;display:block"></iframe>').encode(),
                      "text/html; charset=utf-8")
        elif path.startswith("/fonts/") and "/" not in path[7:] and ".." not in path:
            f = os.path.join(HERE, "fonts", path[7:])
            if not os.path.isfile(f):
                return self.send(404, {"error": "no such font"})
            with open(f, "rb") as fh:
                self.send(200, fh.read(), FONT_TYPES.get(os.path.splitext(f)[1], "application/octet-stream"))
        else:
            self.send(404, {"error": f"no route for {path}"})

    def do_POST(self):
        path = self.path.split("?")[0]
        try:
            body = json.loads(self.rfile.read(int(self.headers.get("Content-Length") or 0)) or b"{}")
        except ValueError:
            return self.send(400, {"error": "body is not JSON"})
        try:
            if path == "/api/run":
                mode = body.get("mode")
                if mode not in ("full", "planted"):
                    return self.send(400, {"error": "mode must be full or planted"})
                self.send(200, THEATRE.start(mode))
            elif path == "/api/treat":
                kind = body.get("kind")
                if kind not in ("boom", "ok", "health"):
                    return self.send(400, {"error": "kind must be boom, ok or health"})
                self.send(200, treat(kind, int(body.get("count", 20))))
            else:
                self.send(404, {"error": f"no route for {path}"})
        except Exception as e:
            self.send(502, {"error": str(e)})

    def log_message(self, fmt, *args):
        if "/api/run" not in self.path and "/api/patient" not in self.path:
            print(f"{self.command} {self.path} -> {args[1] if len(args) > 1 else ''}", flush=True)


if __name__ == "__main__":
    threading.Thread(target=kubectl_proxy, daemon=True).start()
    threading.Thread(target=PATIENT.loop, daemon=True).start()
    print(f"operating theatre on http://localhost:{PORT}  (kubectl proxy :{PROXY_PORT}, kubeconfig {KUBECONFIG})", flush=True)
    ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
