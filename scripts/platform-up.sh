#!/usr/bin/env bash
# Install the platform on the cluster: ingress, secrets, observability.
# Everything the app chart depends on. Runs once after `terraform apply`;
# safe to re-run.
#
#   ingress-nginx          the front door (NodePort 30080)
#   external-secrets       Secrets Manager -> Kubernetes Secrets
#   kube-prometheus-stack  Prometheus, Alertmanager, Grafana
#   loki-stack             Loki + Promtail (logs)
#   tempo                  traces
set -euo pipefail
cd "$(dirname "$0")/.."

source scripts/ci/lib.sh
write_kubeconfig "$PWD/.cluster/kubeconfig.yaml"
echo "kubeconfig: .cluster/kubeconfig.yaml"

INGRESS_NGINX_VERSION=4.15.1
EXTERNAL_SECRETS_VERSION=2.10.0
KUBE_PROMETHEUS_STACK_VERSION=91.4.1
LOKI_STACK_VERSION=2.10.3
TEMPO_VERSION=1.24.4

hr "waiting for the node"
until kubectl get nodes 2>/dev/null | grep -q " Ready "; do sleep 3; done
kubectl get nodes

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null 2>&1 || true
helm repo add external-secrets https://charts.external-secrets.io >/dev/null 2>&1 || true
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo add grafana https://grafana.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update >/dev/null

hr "ingress-nginx"
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --version "$INGRESS_NGINX_VERSION" -f platform/ingress-nginx.yaml \
  --wait --timeout 5m

hr "external-secrets"
# Pods cannot resolve the emulator by name (CoreDNS does not see Docker's
# embedded DNS), so the operator gets its IP. In AWS this substitution is
# not made and the operator talks to the real endpoint.
FLOCI_IP=$(docker inspect floci-ui-floci-1 --format '{{(index .NetworkSettings.Networks "floci_default").IPAddress}}')
sed "s/FLOCI_IP/${FLOCI_IP}/g" platform/external-secrets.yaml > .cluster/external-secrets.values.yaml
helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets --create-namespace \
  --version "$EXTERNAL_SECRETS_VERSION" -f .cluster/external-secrets.values.yaml \
  --wait --timeout 5m

hr "secret stores"
kubectl apply -f platform/secret-stores.yaml
kubectl -n monitoring wait externalsecret/grafana-admin --for=condition=Ready --timeout=2m
echo "  grafana-admin synced from Secrets Manager"

hr "kube-prometheus-stack"
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --version "$KUBE_PROMETHEUS_STACK_VERSION" -f platform/kube-prometheus-stack.yaml \
  --wait --timeout 10m

hr "loki-stack"
helm upgrade --install loki-stack grafana/loki-stack \
  --namespace monitoring \
  --version "$LOKI_STACK_VERSION" -f platform/loki-stack.yaml \
  --wait --timeout 5m

hr "tempo"
helm upgrade --install tempo grafana/tempo \
  --namespace monitoring \
  --version "$TEMPO_VERSION" -f platform/tempo.yaml \
  --wait --timeout 5m

echo
kubectl get pods -A | grep -vE "kube-system"
echo
echo "Platform ready. Next: run the pipeline, then scripts/demo.sh"
