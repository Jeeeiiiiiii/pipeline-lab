#!/usr/bin/env bash
# Stage 1: static analysis of the source. Semgrep with the Python, secrets
# and Dockerfile rulesets. Reports every finding; fails only on ERROR.
source "$(dirname "$0")/lib.sh"

hr "sast: semgrep"
TARGETS=("$ROOT/app")
[ "${PLANT_VULN:-0}" = "1" ] && TARGETS+=("$ROOT/scripts/ci/fixtures")

RULES=(--config p/python --config p/secrets --config p/dockerfile)
semgrep scan "${TARGETS[@]}" "${RULES[@]}" --metrics off --quiet --json  --output "$REPORTS/semgrep.json"  || true
semgrep scan "${TARGETS[@]}" "${RULES[@]}" --metrics off --quiet --sarif --output "$REPORTS/semgrep.sarif" || true

python3 - "$REPORTS/semgrep.json" <<'PY'
import json, sys
results = json.load(open(sys.argv[1]))["results"]
by = {}
for f in results:
    by.setdefault(f["extra"]["severity"], []).append(f)
for sev in ("ERROR", "WARNING", "INFO"):
    for f in by.get(sev, []):
        print(f"  [{sev}] {f['path']}:{f['start']['line']}  {f['check_id'].split('.')[-1]}")
errors = len(by.get("ERROR", []))
print(f"findings: {len(results)}  (ERROR: {errors})")
sys.exit(1 if errors else 0)
PY
