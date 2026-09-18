#!/usr/bin/env bash
# The whole pipeline, in order. This is what .github/workflows/pipeline.yml
# does, stage for stage; it exists so the same thing can be run by hand.
#
#   scripts/pipeline.sh              everything
#   scripts/pipeline.sh scan         stop after the scans (what a PR gets)
#   PLANT_VULN=1 scripts/pipeline.sh watch the gates fail
#
# Runs where the tools are: inside the runner image. From the laptop:
#   docker compose -f runner/docker-compose.yml run --rm toolbox scripts/pipeline.sh
set -euo pipefail
cd "$(dirname "$0")/.."

UNTIL="${1:-all}"
S=scripts/ci

rm -rf reports
bash $S/prepare.sh
bash $S/sast.sh
bash $S/iac-scan.sh
bash $S/build.sh
bash $S/image-scan.sh
[ "$UNTIL" = scan ] && { echo; echo "scans passed; stopping before push (scan mode)"; exit 0; }
bash $S/push.sh
bash $S/deploy.sh
bash $S/dast.sh
bash $S/publish-reports.sh

echo
echo "pipeline complete: $(cat reports/image.txt)"
