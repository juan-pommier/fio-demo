#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "${SCRIPT_DIR}/common.sh"

# Array of cleanup commands in reverse order (opposite of deployment)
cleanup_commands=(
#Delete Clone Resources::
"echo -e \"${CYAN}━━━ Deleting Clone Pod ━━━${NC}\""
"kubectl delete -f clone/fio-deployment-clone.yaml --ignore-not-found"

"echo -e \"${CYAN}━━━ Deleting Clone PVC ━━━${NC}\""
"kubectl delete -f clone/clone-pvc-from-snapshot.yaml --ignore-not-found"

#Delete Snapshots::
"echo -e \"${CYAN}━━━ Deleting Volume Snapshot ━━━${NC}\""
"kubectl delete -f snapshot/volumesnapshot.yaml --ignore-not-found"

"echo -e \"${CYAN}━━━ Deleting Volume Snapshot Class ━━━${NC}\""
"kubectl delete -f snapshot/volumesnapshotclass.yaml --ignore-not-found"

#Delete Original Deployment::
"echo -e \"${CYAN}━━━ Deleting FIO Pod ━━━${NC}\""
"kubectl delete -f deployment/fio-deployment.yaml --ignore-not-found"

"echo -e \"${CYAN}━━━ Deleting FIO PVC ━━━${NC}\""
"kubectl delete -f deployment/fio-pvc.yaml --ignore-not-found"

#Final Check::
"echo -e \"${CYAN}━━━ Verifying Cleanup ━━━${NC}\""
"kubectl get pods,pvc,volumesnapshot 2>/dev/null | grep -E 'fio|clone|snapshot' || echo -e \"${GREEN}✓ All resources cleaned up successfully!${NC}\""
)

# Main cleanup function
run_cleanup() {
    show_title
    
    echo -e "${YELLOW}Cleaning up FIO demo resources...${NC}"
    echo
    echo -e "${CYAN}Current resources:${NC}"
    kubectl get pods,pvc,volumesnapshot 2>/dev/null | grep -E 'fio|clone|snapshot' || echo -e "${GREEN}No resources found${NC}"
    echo
    
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}      Starting Cleanup Process        ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    
    # Loop through each cleanup command
    for cmd in "${cleanup_commands[@]}"; do
        # Execute the command
        eval "$cmd" 2>&1
        
        # Small delay for readability
        sleep 0.5
        echo
    done
    
    # Cleanup completed message
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}       ✓ Cleanup completed!          ${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
}

# Run the cleanup
run_cleanup
