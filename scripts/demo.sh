#!/usr/bin/env bash
# After the pipeline has deployed: exercise the app and look at it through
# the platform. Assumes scripts/forward.sh is running in another terminal.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/ci/lib.sh
write_kubeconfig "$PWD/.cluster/kubeconfig.yaml"

APP="${APP_URL:-http://localhost:8080}"
PROM="http://localhost:9090"

hr "1. The deployed version, through the ingress"
curl -sS "$APP/"; echo

hr "2. The secret arrived: /work needs the API key from Secrets Manager"
printf "    without a token  -> "; curl -s -o /dev/null -w '%{http_code}\n' "$APP/work"
KEY=$(aws secretsmanager get-secret-value --secret-id "${CLUSTER}/app/api-key" --query SecretString --output text)
printf "    with the key     -> "; curl -s -w '  %{http_code}\n' -H "Authorization: Bearer $KEY" "$APP/work"
echo
echo "    The key is not in the image, the chart, or git. ESO wrote it into"
echo "    the Secret the pod mounts:"
kubectl -n app get externalsecret app-secrets -o custom-columns='NAME:.metadata.name,STORE:.spec.secretStoreRef.name,STATUS:.status.conditions[0].reason,SYNCED:.status.conditions[0].lastTransitionTime' | sed 's/^/    /'

hr "3. Traffic, so the dashboard has something to show"
for _ in $(seq 1 40); do curl -s -o /dev/null -H "Authorization: Bearer $KEY" "$APP/work"; done
for _ in $(seq 1 10); do curl -s -o /dev/null "$APP/"; done
echo "    50 requests sent. Grafana -> Dashboards -> 'pipeline-lab app'"

hr "4. Metrics: Prometheus is scraping the app (via its ServiceMonitor)"
sleep 20
curl -s "$PROM/api/v1/query" --data-urlencode 'query=sum(rate(flask_http_request_total{namespace="app"}[1m]))' \
  | py -c "$(cat <<'PYC'
import json, sys
r = json.load(sys.stdin)["data"]["result"]
print(f"    requests/s over the last minute: {float(r[0]['value'][1]):.2f}" if r else "    (no samples yet; give it a minute)")
PYC
)"

hr "5. Logs and traces: one request, one trace id, in Loki and in Tempo"
TRACE=$(curl -s -H "Authorization: Bearer $KEY" -D - -o /dev/null "$APP/work" | tr -d '\r' | awk -F': ' 'tolower($1)=="traceparent"{print $2}' | cut -d- -f2)
if [ -z "$TRACE" ]; then
  TRACE=$(kubectl -n app logs deploy/app --tail=5 | py -c 'import json,sys
for l in sys.stdin:
    try: d=json.loads(l)
    except Exception: continue
    if "trace_id" in d: print(d["trace_id"])' | tail -1)
fi
echo "    trace_id: ${TRACE:-?}"
echo "    the log line, from the pod:"
kubectl -n app logs deploy/app --tail=20 | grep -F "${TRACE:-work done}" | tail -1 | sed 's/^/      /'
echo
echo "    In Grafana: Explore -> Loki -> {namespace=\"app\"} | json"
echo "    click the trace_id on any line -> the trace opens in Tempo."

hr "6. Alerting: trip the error-rate alert"
echo "    hitting /boom 60 times over ~30s..."
for _ in $(seq 1 60); do curl -s -o /dev/null "$APP/boom"; sleep 0.5; done
echo "    the rule needs the rate above 5% for 1m. Waiting for it to fire..."
for i in $(seq 1 24); do
  STATE=$(curl -s "$PROM/api/v1/alerts" | py -c "$(cat <<'PYC'
import json, sys
a = [x for x in json.load(sys.stdin)["data"]["alerts"] if x["labels"]["alertname"] == "AppHighErrorRate"]
print(a[0]["state"] if a else "inactive")
PYC
)")
  echo "      $STATE"
  [ "$STATE" = firing ] && break
  sleep 10
done
echo
echo "    Alertmanager: http://localhost:9093   Prometheus alerts: http://localhost:9090/alerts"
echo "    It clears on its own once /boom stops."

hr "7. The artifacts: image in ECR, reports in S3"
# The emulator's ECR API does not list images (its registry does); in AWS
# this is `aws ecr describe-images --repository-name pipeline-lab/app`.
REG=$(aws ecr describe-repositories --repository-names "${CLUSTER}/app" --query 'repositories[0].repositoryUri' --output text)
REG_HOST=$(push_ref "$REG"); REG_HOST=${REG_HOST%%/*}
curl -s "http://${REG_HOST}/v2/${CLUSTER}/app/tags/list" | py -c 'import json,sys; [print("    ", t) for t in json.load(sys.stdin)["tags"]]' 
echo
BUCKET="${CLUSTER}-reports"
aws s3 ls "s3://${BUCKET}/" | sed 's/^/    /'
LAST=$(aws s3 ls "s3://${BUCKET}/" | awk '{print $2}' | tail -1)
aws s3 ls "s3://${BUCKET}/${LAST}" | awk '{printf "      %8s  %s\n", $3, $4}'
echo
echo "Console: http://localhost:4500 (ECR, S3, Secrets Manager, EKS)"
