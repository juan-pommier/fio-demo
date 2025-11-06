#!/bin/bash

# Forcefully clean all pods, PVCs, and PVs in the current namespace or all namespaces

NAMESPACE="${1:-default}"  # Default to 'default' if not passed as argument

echo "WARNING: This will delete all pods, PVCs, and PVs in namespace: $NAMESPACE"
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
