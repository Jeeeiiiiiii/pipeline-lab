#!/usr/bin/env bash
# Shared by every pipeline stage. Sourced, not run.
#
# The stages run in two places: on the GitHub runner (a container on the
# emulator's network) and on the laptop (through the same image, via
# `docker compose run toolbox`). The differences between the two are all
# addresses, and they are all decided here.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPORTS="${REPORTS:-$ROOT/reports}"
mkdir -p "$REPORTS"

# Git Bash rewrites Unix-looking arguments into Windows paths before handing
# them to native binaries -- /aws/lambda/x becomes C:/.../aws/lambda/x. The
# paths handed to `docker exec` below are written with a doubled leading
# slash, which Git Bash leaves alone. kubectl, on the other hand, needs its
# KUBECONFIG converted, hence hostpath().
if command -v cygpath >/dev/null 2>&1; then
  hostpath() { cygpath -w "$1"; }
else
  hostpath() { echo "$1"; }
fi

export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
export AWS_PAGER=""

CLUSTER="${CLUSTER_NAME:-pipeline-lab}"
NODE_CONTAINER="floci-eks-${CLUSTER}"

# Inside a container on the emulator's network, the emulator and the cluster
# node are reachable by name. On the host they are published ports.
if [ -f /.dockerenv ]; then
  IN_NETWORK=1
  export AWS_ENDPOINT_URL="${AWS_ENDPOINT_URL:-http://floci:4566}"
  APP_URL="${APP_URL:-http://${NODE_CONTAINER}:30080}"
else
  IN_NETWORK=0
  export AWS_ENDPOINT_URL="${AWS_ENDPOINT_URL:-http://localhost:4566}"
  APP_URL="${APP_URL:-http://localhost:8080}"   # scripts/forward.sh
fi

# Windows installs Python as `python`; Linux as `python3`.
py() { if command -v python3 >/dev/null 2>&1; then python3 "$@"; else python "$@"; fi; }

# No AWS CLI on this machine? Use the official image. Only the host-side
# scripts (forward, demo) hit this; the runner image has the CLI.
if ! command -v aws >/dev/null 2>&1; then
  aws() {
    docker run --rm --network floci_default       -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_DEFAULT_REGION -e AWS_PAGER       amazon/aws-cli --endpoint-url=http://floci:4566 "$@"
  }
fi

# The image. Tag is the commit, so a tag can never mean two things. Outside
# git (or with a dirty tree) fall back to a timestamp so local runs do not
# collide with the immutable tag of a real commit.
image_ref() {
  local repo
  repo=$(cat "$REPORTS/repository.txt" 2>/dev/null || true)
  if [ -z "$repo" ]; then
    echo "reports/repository.txt missing: run scripts/ci/prepare.sh first" >&2
    return 1
  fi
  echo "${repo}:$(cat "$REPORTS/tag.txt")"
}

# The emulator names its registry <account>.dkr.ecr.<region>.localhost:5100.
# From the host daemon that name resolves unreliably on Windows; it is the
# same registry as localhost:5100, so push there. The cluster pulls by the
# ECR name -- the emulated node is preconfigured to map it. In AWS both are
# the real ECR hostname and this function is the identity.
push_ref() {
  local ref="$1"
  case "$ref" in
    *.localhost:*) echo "localhost:${ref#*.localhost:}" ;;
    *) echo "$ref" ;;
  esac
}

# Write the kubeconfig for wherever we are. In AWS this is
# `aws eks update-kubeconfig`; locally the credentials come out of the k3s
# container, with the server address depending on which side of the Docker
# network we stand.
write_kubeconfig() {
  local out="$1" port
  mkdir -p "$(dirname "$out")"
  if [ "$IN_NETWORK" = 1 ]; then
    docker exec "$NODE_CONTAINER" cat //etc/rancher/k3s/k3s.yaml \
      | sed "s|https://127.0.0.1:6443|https://${NODE_CONTAINER}:6443|" \
      | sed "s|    server: |    tls-server-name: localhost\n    server: |" \
      > "$out"
  else
    port=$(docker port "$NODE_CONTAINER" 6443/tcp | head -1 | sed 's/.*://')
    docker exec "$NODE_CONTAINER" cat //etc/rancher/k3s/k3s.yaml \
      | sed "s|https://127.0.0.1:6443|https://localhost:${port}|" \
      > "$out"
  fi
  export KUBECONFIG="$out"
}

hr() { echo; echo "==> $*"; }
