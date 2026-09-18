#!/usr/bin/env bash
# Stage 5: the image passed; publish it. Immutable tag, so a second push of
# the same commit is refused by the registry -- which is what we want.
source "$(dirname "$0")/lib.sh"

need_report image.txt build
IMAGE=$(cat "$REPORTS/image.txt")
PUSH=$(push_ref "$IMAGE")

hr "push: $IMAGE"
if [ "$PUSH" != "$IMAGE" ]; then
  echo "  via $PUSH (emulator registry alias)"
  docker tag "$IMAGE" "$PUSH"
else
  aws ecr get-login-password | docker login --username AWS --password-stdin "${IMAGE%%/*}"
fi
docker push -q "$PUSH"
# The fact deploy.sh needs: this exact ref is in the registry.
echo "$IMAGE" > "$REPORTS/pushed.txt"
