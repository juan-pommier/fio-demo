#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "${SCRIPT_DIR}/common.sh"

# Forcefully clean all pods, PVCs, and PVs in the current namespace or all namespaces

show_title

NAMESPACE="${1:-default}"  # Default to 'default' if not passed as argument
echo -e "${YELLOW}Namespace to clean:${NC} $NAMESPACE"

echo -e "${RED}WARNING:${NC} This will delete resources in namespace '$NAMESPACE'."
echo -e "${GREEN}Type 'yes' to confirm:${NC}"
read -p "Are you sure? Type 'yes' to continue: " confirm

if [[ "$confirm" != "yes" ]]; then
  echo "Cleanup aborted."
  exit 1
fi

echo " Deleting Pods in $NAMESPACE..."
kubectl delete pods --all -n "$NAMESPACE" --grace-period=0 --force

echo "Deleting PVCs in $NAMESPACE..."
kubectl delete pvc --all -n "$NAMESPACE"

echo "Deleting PVs cluster-wide..."
kubectl delete pv --all

echo "Cleanup complete!"
