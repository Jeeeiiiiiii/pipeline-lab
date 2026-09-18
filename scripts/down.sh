#!/usr/bin/env bash
# Tear everything down. Destroying the EKS cluster removes the k3s container
# and everything installed in it, so there is no Helm uninstall step.
set -euo pipefail
cd "$(dirname "$0")/.."

CLUSTER=$(terraform -chdir=terraform output -raw cluster_name 2>/dev/null || echo pipeline-lab)

docker compose -f runner/docker-compose.yml down >/dev/null 2>&1 || true
terraform -chdir=terraform destroy -auto-approve
rm -rf .cluster reports

# Floci keeps the k3s data directory in a named volume that survives the
# cluster being deleted, so the next apply would come back with the
# platform already in it. Remove it for a genuinely fresh cluster.
if docker volume rm "floci-eks-${CLUSTER}" >/dev/null 2>&1; then
  echo "removed cluster volume floci-eks-${CLUSTER}"
fi

echo "done. The emulator itself is still running: cd ../floci-ui && docker compose down"
