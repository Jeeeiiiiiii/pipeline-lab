#!/usr/bin/env bash
# The operating theatre: run the pipeline stage by stage and watch each gate,
# then break the app and watch the alert. Needs the lab up (terraform applied,
# platform-up.sh, the toolbox image built) and kubectl on the PATH.
set -euo pipefail
cd "$(dirname "$0")/.."

PY="$(command -v python3 || command -v python)"
echo "open http://localhost:${OPS_PORT:-8097}"
exec "$PY" ops/server.py
