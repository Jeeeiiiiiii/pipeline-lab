#!/usr/bin/env bash
# Stage 4: what is in the image, and what is wrong with it.
#   SBOM   CycloneDX, every package in the image, for the artifact store.
#   Vulns  HIGH and CRITICAL, reported. A CRITICAL with a fix available
#          fails the pipeline: a fix exists and we did not take it.
source "$(dirname "$0")/lib.sh"

IMAGE=$(cat "$REPORTS/image.txt")

hr "sbom: $IMAGE"
trivy image "$IMAGE" --format cyclonedx --output "$REPORTS/sbom.cdx.json" --quiet
python3 - "$REPORTS/sbom.cdx.json" <<'PY'
import json, sys
print(f"  {len(json.load(open(sys.argv[1])).get('components', []))} components")
PY

hr "vulnerabilities: HIGH, CRITICAL"
trivy image "$IMAGE" --severity HIGH,CRITICAL --format json --output "$REPORTS/trivy-image.json" --quiet
trivy image "$IMAGE" --severity HIGH,CRITICAL --quiet

hr "gate: CRITICAL with a fix"
trivy image "$IMAGE" --severity CRITICAL --ignore-unfixed --exit-code 1 --quiet --format table >/dev/null && echo "  none"
