#!/usr/bin/env bash
# Stage 3: build the image. Nothing else -- scanning is the next stage, and
# the image does not leave this machine until it passes.
source "$(dirname "$0")/lib.sh"

IMAGE=$(image_ref)
hr "build: $IMAGE"
docker build \
  --build-arg "PLANT_VULN=${PLANT_VULN:-0}" \
  --label "org.opencontainers.image.revision=$(cat "$REPORTS/tag.txt")" \
  -t "$IMAGE" "$ROOT/app"
echo "$IMAGE" > "$REPORTS/image.txt"
