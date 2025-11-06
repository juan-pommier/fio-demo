#!/bin/bash

# Debug mode toggle (set to true or false)
DEBUG=false

# Function to print debug messages
debug_log() {
    if [ "$DEBUG" = true ]; then
        echo "DEBUG: $1"
    fi
}

# Colors for better readability
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Array of commands to demonstrate
commands=(
#Deploy the FIO App::
"kubectl apply -f deployment/fio-pvc.yaml"
"kubectl apply -f deployment/fio-deployment.yaml"

#Check the FIO pod status::
"kubectl get pods,pvc -o wide"

#SnapShot The PVC::
"kubectl apply -f snapshot/volumesnapshotclass.yaml"
"kubectl apply -f snapshot/volumesnapshot.yaml"

#Check the snapshot::
"kubectl get volumesnapshot -o wide"

#Deploy App with Clone Data::
"kubectl apply -f clone/clone-pvc-from-snapshot.yaml"
"kubectl apply -f clone/nginx-deployment-clone.yaml"

#Check the Clone Pod Details::
"kubectl get pods,pvc -o wide"
)

# Function to display title with custom ASCII art
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
    echo -e "${RED}         FIO Workload Demo           ${NC}"
    echo -e "${RED}=====================================${NC}"
    echo
    echo -e "${GREEN}Press ENTER after each command to execute${NC}"
    echo -e "${GREEN}Press Ctrl+C to exit the demo${NC}"
    echo
}

# Function to get the current namespace
get_current_namespace() {
    kubectl config view --minify -o jsonpath='{.contexts[0].context.namespace}' 2>/dev/null || echo "default"
}

# Function to get the pod name matching a selector
get_pod_name() {
    local selector=$1
    kubectl get pods -o jsonpath='{.items[0].metadata.name}' --selector=app=$selector 2>/dev/null || echo "ERROR_NO_POD_FOUND"
}

# Main demo function
run_demo() {
    show_title
    
    # Loop through each command
    for cmd in "${commands[@]}"; do
        
        # Display the command with prompt
        echo -e "${CYAN}$ ${cmd}${NC}"
        
        # Wait for user to press ENTER
        read -p ""
        
        # Execute the command
        eval "$cmd"
        
        # Separator for readability
        echo
        echo -e "${YELLOW}-------------------------------------${NC}"
        echo
    done
    
    # Demo completed message
    echo -e "${RED}Demo completed!${NC}"
}

# Run the demo
run_demo
