#!/usr/bin/env bash
# Stage 6: roll the image out with Helm and prove the new version answers.
source "$(dirname "$0")/lib.sh"

# Only what push.sh published. A scan-only run (or a run the gates stopped)
# leaves tag.txt pointing at an image that is not in the registry.
need_report pushed.txt push
IMAGE=$(cat "$REPORTS/pushed.txt"); REPO="${IMAGE%:*}"; TAG="${IMAGE##*:}"
write_kubeconfig "$ROOT/.cluster/kubeconfig.ci.yaml"

hr "deploy: helm upgrade --install app (${TAG})"
helm upgrade --install app "$ROOT/helm/app" \
  --namespace app \
  --set image.repository="$REPO" \
  --set image.tag="$TAG" \
  --wait --timeout 5m
kubectl -n app get pods

hr "smoke: $APP_URL"
for _ in $(seq 1 20); do
  if curl -fsS -m 5 "$APP_URL/" | grep -q "\"version\": *\"$TAG\""; then
    curl -sS "$APP_URL/"; echo
    exit 0
  fi
  sleep 3
done
echo "the deployed app did not answer with version $TAG" >&2
curl -sS "$APP_URL/" || true
exit 1
