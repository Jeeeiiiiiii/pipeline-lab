#!/usr/bin/env bash
# Stage 7: dynamic scan of the running app. OWASP ZAP baseline: spider it,
# passively check every response. Authenticates with the DAST token from
# Secrets Manager so /work is in scope too. Fails only on FAIL-level rules
# (none by default); WARN goes in the report.
#
# ZAP runs as a container on the emulator network and insists on a mounted
# /zap/wrk for its report. A bind mount would need a host path, which the
# runner does not have, so the mount is a named Docker volume and the report
# is copied out of it afterwards.
#
# DAST_MODE=full runs the active scan instead (attacks the app, ~10 min).
source "$(dirname "$0")/lib.sh"

TOKEN=$(aws secretsmanager get-secret-value --secret-id "${CLUSTER}/dast/token" --query SecretString --output text)
TARGET="${DAST_TARGET:-$APP_URL}"
MODE="${DAST_MODE:-baseline}"
ZAP_IMAGE="ghcr.io/zaproxy/zaproxy:stable"

hr "dast: zap ${MODE} against ${TARGET}"
docker rm -f zap >/dev/null 2>&1 || true
docker volume rm -f zap-wrk >/dev/null 2>&1 || true
docker volume create zap-wrk >/dev/null
# ZAP runs as uid 1000 and a fresh volume is root-owned.
docker run --rm -v zap-wrk:/zap/wrk alpine:3.20 chown 1000:1000 /zap/wrk

set +e
docker run --name zap --network floci_default -v zap-wrk:/zap/wrk "$ZAP_IMAGE" \
  "zap-${MODE}.py" -t "$TARGET" -I \
  -r "zap-${MODE}.html" -J "zap-${MODE}.json" \
  -z "-config replacer.full_list(0).description=auth -config replacer.full_list(0).enabled=true -config replacer.full_list(0).matchtype=REQ_HEADER -config replacer.full_list(0).matchstr=Authorization -config replacer.full_list(0).regex=false -config replacer.full_list(0).replacement=Bearer\ ${TOKEN}" \
  2>&1 | grep -E "^(PASS|WARN|FAIL|Total)" | sed 's/^/  /' | sort | uniq -c | sort -rn | head -40
RC=${PIPESTATUS[0]}
set -e

docker run --rm -v zap-wrk:/w alpine:3.20 tar c -C /w . | tar x -C "$REPORTS"
docker rm -f zap >/dev/null 2>&1 || true
docker volume rm zap-wrk >/dev/null

echo "report: reports/zap-${MODE}.html"
# 0 = pass, 2 = warnings only (-I), 1 = a FAIL rule matched
[ "$RC" -ne 1 ]
