#!/usr/bin/env bash
# Stage 2: misconfiguration scan of the infrastructure code -- Terraform,
# the Helm chart, the Dockerfile. Reports HIGH and CRITICAL; fails on CRITICAL.
source "$(dirname "$0")/lib.sh"

SKIP=(--skip-dirs reports --skip-dirs .cluster --skip-dirs runner --ignorefile "$ROOT/.trivyignore.yaml")

hr "iac-scan: trivy config"
trivy config "$ROOT" "${SKIP[@]}" --severity HIGH,CRITICAL --format json --output "$REPORTS/trivy-config.json" --quiet
trivy config "$ROOT" "${SKIP[@]}" --severity HIGH,CRITICAL --quiet

hr "gate: CRITICAL misconfigurations"
trivy config "$ROOT" "${SKIP[@]}" --severity CRITICAL --exit-code 1 --quiet --format table >/dev/null && echo "  none"
