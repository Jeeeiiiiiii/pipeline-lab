#!/usr/bin/env bash
# Stage 0: decide what this run is building. Writes reports/tag.txt and
# reports/repository.txt so every later stage agrees on the image name.
source "$(dirname "$0")/lib.sh"

hr "prepare"
mkdir -p "$REPORTS"

if [ -n "${GITHUB_SHA:-}" ]; then
  TAG="${GITHUB_SHA:0:12}"
elif git -C "$ROOT" diff --quiet 2>/dev/null && git -C "$ROOT" rev-parse HEAD >/dev/null 2>&1; then
  TAG="$(git -C "$ROOT" rev-parse --short=12 HEAD)"
else
  TAG="local-$(date -u +%Y%m%d%H%M%S)"
fi

REPO="${ECR_REPOSITORY:-}"
if [ -z "$REPO" ]; then
  # From the Terraform outputs if they are next to us; otherwise ask ECR.
  REPO=$(terraform -chdir="$ROOT/terraform" output -raw ecr_repository_url 2>/dev/null \
    || aws ecr describe-repositories --repository-names "${CLUSTER}/app" --query 'repositories[0].repositoryUri' --output text)
fi

echo "$TAG"  > "$REPORTS/tag.txt"
echo "$REPO" > "$REPORTS/repository.txt"
echo "image: ${REPO}:${TAG}"
[ "${PLANT_VULN:-0}" = "1" ] && echo "PLANT_VULN=1: this run carries deliberate findings" || true
