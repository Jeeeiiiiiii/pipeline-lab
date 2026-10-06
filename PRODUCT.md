# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Stack

Static HTML/CSS/JS in one file (`ops/index.html`), served by a standard-library Python server (`ops/server.py`) on the operator's machine, started by `scripts/ops.sh`. It runs the pipeline's stage scripts in the `toolbox` container (`runner/docker-compose.yml`), reads the reports they write, and talks to the cluster through `kubectl` with `.cluster/kubeconfig.yaml` (API-server service proxy to the app and Prometheus). No build step, nothing new deployed. Chosen by the user, matching the sibling labs' pages.

## Users

One DevOps engineer, the lab's owner, learning CI/CD security gates and Kubernetes observability, on their own Windows laptop with the lab running locally. They run pipelines at work; they want to *see* each stage, what each gate looked at and why it passed or stopped the line, and the platform reacting to a broken app, rather than scroll terminal output. They prefer plain-language explanations and cause → effect they can trigger themselves.

## Product Purpose

The page lets them run the real pipeline and watch it stage by stage, plant a vulnerability and watch the gates stop it with nothing pushed, and break the deployed app and watch the error-rate alert walk inactive → pending → firing. Success: they can explain, from what they watched, what each stage checks and produces, why the gates fail only on CRITICAL (and only with a fix for images), why a refused image is never deployed (`pushed.txt`), and how the PrometheusRule turns a run of 500s into a firing alert after its `for: 1m`.

Scenario scope (confirmed by the user): run the pipeline; plant a vulnerability (`PLANT_VULN=1`, scan mode); break the app and fire the alert (`/boom`). Out of scope for now: following one request's trace id through Loki and Tempo.

## Positioning

Every state comes from the running lab: stage status is each stage script's own exit code and output, run in the same image the GitHub runner uses; gate verdicts are read from the reports the scanners wrote (`reports/semgrep.json`, `trivy-config.json`, `trivy-image.json`, `zap-baseline.json`); deploy state from Helm and the cluster; alert state from Prometheus's own `/api/v1/alerts`. Nothing is replayed or simulated.

## Operating Context

- Started after the lab is up: Floci, `terraform apply`, `platform-up.sh`, the toolbox image built. After a Docker restart the cluster needs `terraform apply -replace=aws_eks_cluster.this` and the user deletes the dead node.
- A full run takes about four minutes; the first scan of a session pulls rule sets and vulnerability databases. The page must make long stages legible, not look stuck.
- Runs mutate the lab: a full run pushes a new image tag to ECR, upgrades the Helm release, and writes reports to S3. A scan-mode (`PLANT_VULN=1`) run stops before push.
- Port 8080 is held by `wslrelay` on this machine; the page reaches the app and Prometheus through the API-server service proxy, not port-forwards.

## Capabilities and Constraints

- Stages, in order: prepare, sast (Semgrep), iac-scan (Trivy config), build, image-scan (Trivy image + SBOM), push (ECR), deploy (Helm), dast (ZAP baseline), publish-reports (S3). Pull-request mode stops after image-scan.
- Gates: sast fails on any ERROR; iac-scan on a CRITICAL not in `.trivyignore.yaml`; image-scan on a CRITICAL with a fixed version; dast on a FAIL-level rule.
- App routes: `/`, `/work` (needs the API key from Secrets Manager via ESO), `/boom` (500), `/healthz`, `/metrics`. Alert: error rate > 5% for 1m (`helm/app/templates/prometheusrule.yaml`).
- Terminology: stage, gate, finding, severity, fix available, accepted (ignore file), tag, pushed, release, rollout, alert state (inactive / pending / firing).

## Evidence on Hand

The README's "What the scanners found, and what happened" section, the reports from earlier runs in `reports/`, and the planted fixtures in `scripts/ci/fixtures/`. The GitHub → runner hop has never run (no remote); the page runs the stages the way the runner would and must say so.

## Product Principles

1. Show the gate's evidence, not just its verdict: what was found, at what severity, and which rule decided.
2. A stopped line is a success of the gate, not a failure of the page.
3. Long waits are explained while they happen.
4. Say what the page changed: a new tag, a new release, a firing alert.
