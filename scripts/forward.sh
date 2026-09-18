#!/usr/bin/env bash
# Port-forwards from the laptop to the things worth looking at. Leave it
# running in a terminal; Ctrl-C stops all of them.
#
#   http://localhost:8080        the app, through ingress-nginx
#   http://localhost:3000        Grafana  (admin / the password below)
#   http://localhost:9090        Prometheus
#   http://localhost:9093        Alertmanager
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/ci/lib.sh
write_kubeconfig "$PWD/.cluster/kubeconfig.yaml"

echo "Grafana admin password (from Secrets Manager):"
echo "  $(aws secretsmanager get-secret-value --secret-id "${CLUSTER}/grafana/admin" --query SecretString --output text | py -c 'import json,sys; print(json.load(sys.stdin)["admin-password"])')"
echo

kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 8080:80 >/dev/null 2>&1 &
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80 >/dev/null 2>&1 &
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090 >/dev/null 2>&1 &
kubectl -n monitoring port-forward svc/kube-prometheus-stack-alertmanager 9093:9093 >/dev/null 2>&1 &
trap 'kill $(jobs -p) 2>/dev/null' EXIT

echo "  app          http://localhost:8080"
echo "  grafana      http://localhost:3000   (dashboard: pipeline-lab app)"
echo "  prometheus   http://localhost:9090"
echo "  alertmanager http://localhost:9093"
echo
echo "Ctrl-C to stop."
wait
