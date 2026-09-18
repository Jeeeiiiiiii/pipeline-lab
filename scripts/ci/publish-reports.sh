#!/usr/bin/env bash
# Stage 8: everything the pipeline learned goes next to the image, keyed by
# its tag. The bucket is versioned, so re-running a commit keeps both.
source "$(dirname "$0")/lib.sh"

BUCKET="${REPORTS_BUCKET:-${CLUSTER}-reports}"
TAG=$(cat "$REPORTS/tag.txt")

hr "publish: s3://${BUCKET}/${TAG}/"
aws s3 cp "$REPORTS" "s3://${BUCKET}/${TAG}/" --recursive --exclude "*.txt" --quiet
aws s3 ls "s3://${BUCKET}/${TAG}/" | awk '{printf "  %8s  %s\n", $3, $4}'
