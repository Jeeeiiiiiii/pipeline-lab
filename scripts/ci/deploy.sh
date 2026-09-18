#!/usr/bin/env bash
# Stage 6: roll the image out with Helm and prove the new version answers.
source "$(dirname "$0")/lib.sh"

# Only what push.sh published, and only if it is this run's image. A run
# the gates stopped leaves tag.txt pointing at an image that is not in the
# registry; a stale pushed.txt from an earlier run would name one that is --
# the wrong one.
need_report pushed.txt push
IMAGE=$(cat "$REPORTS/pushed.txt")
[ "$IMAGE" = "$(image_ref)" ] || { echo "reports/pushed.txt ($IMAGE) is not this run's image ($(image_ref)); run push.sh" >&2; exit 1; }
REPO="${IMAGE%:*}"; TAG="${IMAGE##*:}"
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
