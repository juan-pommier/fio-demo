#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "${SCRIPT_DIR}/common.sh"

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    echo_error "kubectl is not installed."
    exit 1
fi

# Forcefully clean all pods, PVCs, and PVs in the current namespace or all namespaces

show_title

# Require explicit namespace - no default to prevent accidents
if [ -z "${1:-}" ]; then
  echo_error "ERROR: Namespace argument required!"
  echo_info "Usage: $0 <namespace>"
  exit 1
fi
NAMESPACE="$1"

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



echo_warning "WARNING: Cluster-wide PV deletion is DANGEROUS and may affect other namespaces!"
read -p "Do you REALLY want to delete ALL PVs cluster-wide? Type 'I understand': " pv_confirm
if [[ "$pv_confirm" != "I understand" ]]; then
  echo_info "Cluster-wide PV deletion skipped."
else
  echo " Deleting PVs cluster-wide..."
  kubectl delete pv --all
fi

echo "Cleanup complete!"
