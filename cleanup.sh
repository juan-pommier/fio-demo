#!/bin/bash

# Colors for better readability
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to display title
show_title() {
    clear
    echo -e "${RED} ********** ** ** ** ** ** **** **** ** ${NC}"
    echo -e "${RED}/////**/// // /** // /** /**/**/** **/** /** ${NC}"
    echo -e "${RED}     /**     **  *******  ******  ******  **  /**  /**/**//**  **  /**  ******  ******  ******  ******  ***** ${NC}"
    echo -e "${RED}     /**    /**//**///**///**/ //**//*/**  //** **  /**  //***  /**  **//// ///**/ **////**//**//*  **///**${NC}"
    echo -e "${WHITE}     /**    /**  /**  /**  /**    /**  / /**  //** **  /**   //*  /**//***** /**    /**  /**  /**  / /*******${NC}"
    echo -e "${WHITE}     /**    /**  /**  /**  /**    /**    /**  //**** /**    /   /** /////** /**    /**  /**  /**    /////// ${NC}"
    echo -e "${WHITE}     /**    /**  *** /**  //**  //***    /**   //**  /**   /**  ****** //**  //****** //***  //******${NC}"
    echo -e "${WHITE}     //     //  /// //    //   ///     //     //   //    //   //////  //    //////  ///    ////// ${NC}"
    echo
    echo -e "${RED}=====================================${NC}"
    echo -e "${RED}        FIO Demo Cleanup Tool        ${NC}"
    echo -e "${RED}=====================================${NC}"
    echo
}

# Array of cleanup commands in reverse order (opposite of deployment)
cleanup_commands=(
#Delete Clone Resources::
"echo -e \"${BLUE}━━━ Deleting Clone Pod ━━━${NC}\""
"kubectl delete -f clone/fio-deployment-clone.yaml --ignore-not-found"

"echo -e \"${BLUE}━━━ Deleting Clone PVC ━━━${NC}\""
"kubectl delete -f clone/clone-pvc-from-snapshot.yaml --ignore-not-found"

#Delete Snapshots::
"echo -e \"${BLUE}━━━ Deleting Volume Snapshot ━━━${NC}\""
"kubectl delete -f snapshot/volumesnapshot.yaml --ignore-not-found"

"echo -e \"${BLUE}━━━ Deleting Volume Snapshot Class ━━━${NC}\""
"kubectl delete -f snapshot/volumesnapshotclass.yaml --ignore-not-found"

#Delete Original Deployment::
"echo -e \"${BLUE}━━━ Deleting FIO Pod ━━━${NC}\""
"kubectl delete -f deployment/fio-deployment.yaml --ignore-not-found"

"echo -e \"${BLUE}━━━ Deleting FIO PVC ━━━${NC}\""
"kubectl delete -f deployment/fio-pvc.yaml --ignore-not-found"

#Final Check::
"echo -e \"${BLUE}━━━ Verifying Cleanup ━━━${NC}\""
"kubectl get pods,pvc,volumesnapshot 2>/dev/null | grep -E 'fio|clone|snapshot' || echo -e \"${GREEN}✓ All resources cleaned up successfully!${NC}\""
)

# Main cleanup function
run_cleanup() {
    show_title
    
    echo -e "${YELLOW}⚠️  WARNING: This will delete all FIO demo resources!${NC}"
    echo -e "${YELLOW}   - FIO pod and clone pod${NC}"
    echo -e "${YELLOW}   - All PVCs (fio-pvc, fio-clone-pvc)${NC}"
    echo -e "${YELLOW}   - Volume snapshots${NC}"
    echo
    echo -e "${CYAN}Current resources to be deleted:${NC}"
    kubectl get pods,pvc,volumesnapshot 2>/dev/null | grep -E 'fio|clone|snapshot' || echo -e "${GREEN}No resources found${NC}"
    echo
    
    read -p "$(echo -e ${YELLOW}Are you sure you want to continue? \(y/N\): ${NC})" -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Cleanup cancelled.${NC}"
        exit 0
    fi
    
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
