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
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function to watch a resource until it's ready or timeout
watch_resource() {
    local resource_type="$1"
    local resource_name="$2"
    local timeout="${3:-30}"
    
    echo -e "${CYAN}Watching $resource_type/$resource_name...${NC}"
    
    # Use timeout with kubectl get -w to watch the resource
    timeout $timeout kubectl get $resource_type $resource_name -o wide -w 2>/dev/null &    local watch_pid=$!
    
    # Wait for the background process or timeout
    wait $watch_pid 2>/dev/null
    
    echo -e "${GREEN}✓ Resource check complete${NC}"
    echo
}

# Array of commands to demonstrate
commands=(
#Deploy the FIO App::
"echo -e \"${BLUE}━━━ Deploying FIO Workload Pod ━━━${NC}\""
"echo -e \"${BLUE}This will create a PVC and deploy a FIO pod that runs I/O benchmarks...${NC}\""
"kubectl apply -f deployment/fio-pvc.yaml"
"watch_resource pvc fio-pvc 30"
"kubectl apply -f deployment/fio-deployment.yaml"
"watch_resource pod fio-pod 60"

#Wait for pod to be ready::
"echo -e \"${BLUE}━━━ Waiting for FIO Pod to be Ready ━━━${NC}\""
"kubectl wait --for=condition=ready pod/fio-pod --timeout=300s || echo -e \"${YELLOW}Warning: Pod may still be starting...${NC}\""

#Check the FIO pod status::
"echo -e \"${BLUE}━━━ Checking FIO Pod Status ━━━${NC}\""
"kubectl get pods,pvc -o wide"

#Monitor FIO output::
"echo -e \"${BLUE}━━━ FIO Benchmark Output (first 20 lines) ━━━${NC}\""
"kubectl logs fio-pod --tail=20 || echo -e \"${YELLOW}Pod logs not yet available...${NC}\""

#SnapShot The PVC::
"echo -e \"${BLUE}━━━ Creating Volume Snapshot ━━━${NC}\""
"echo -e \"${BLUE}This captures the current state of the PVC for cloning...${NC}\""
"kubectl apply -f snapshot/volumesnapshotclass.yaml"
"kubectl apply -f snapshot/volumesnapshot.yaml"

#Wait for snapshot to be ready::
"echo -e \"${BLUE}━━━ Waiting for Snapshot to be Ready ━━━${NC}\""
"sleep 3"

#Check the snapshot::
"echo -e \"${BLUE}━━━ Checking Snapshot Status ━━━${NC}\""
"kubectl get volumesnapshot,volumesnapshotcontent -o wide"

#Deploy App with Clone Data::
"echo -e \"${BLUE}━━━ Deploying Clone from Snapshot ━━━${NC}\""
"echo -e \"${BLUE}This creates a new PVC from the snapshot and deploys a clone pod...${NC}\""
"kubectl apply -f clone/clone-pvc-from-snapshot.yaml"
"watch_resource pvc fio-clone-pvc 30"
"kubectl apply -f clone/fio-deployment-clone.yaml"
"watch_resource pod fio-clone-pod 60"

#Wait for clone pod::
"echo -e \"${BLUE}━━━ Waiting for Clone Pod to be Ready ━━━${NC}\""
"kubectl wait --for=condition=ready pod/fio-clone-pod --timeout=300s || echo -e \"${YELLOW}Warning: Clone pod may still be starting...${NC}\""

#Check the Clone Pod Details::
"echo -e \"${BLUE}━━━ Checking Clone Pod Status ━━━${NC}\""
"kubectl get pods,pvc -o wide"

#Show clone logs::
"echo -e \"${BLUE}━━━ Clone FIO Benchmark Output (first 20 lines) ━━━${NC}\""
"kubectl logs fio-clone-pod --tail=20 || echo -e \"${YELLOW}Clone pod logs not yet available...${NC}\""
)

# Function to display title with custom ASCII art
show_title() {
    clear
    echo -e "${RED} ********** ** ** ** ** ** **** **** ** ${NC}"
    echo -e "${RED}/////**/// // /** // /** /**/**/** **/** /** ${NC}"
    echo -e "${RED}     /**    **  *******  ******  ******  ** /**  /**/**//**  ** /**  ******  ******  ******  ******  ***** ${NC}"
    echo -e "${RED}     /**   /**//**///**///**/ //**//*/** //** ** /**  //*** /**  **//// ///**/ **////**//**//* **///**${NC}"
    echo -e "${WHITE}     /**   /**  /**  /**  /**   /**  / /** //** ** /**   //* /**//***** /**   /**  /**  /** / /*******${NC}"
    echo -e "${WHITE}     /**   /**  /**  /**  /**   /**   /**  //**** /**    / /** /////** /**   /**  /**  /** /////// ${NC}"
    echo -e "${WHITE}     /**   /**  *** /**  //**  //***  /**   //** /**      /**  ****** //** //****** //*** //******${NC}"
    echo -e "${WHITE}     //    //  /// //    //   ///   //     //  //       //  //////  //  //////  ///  ////// ${NC}"
    echo
    echo -e "${RED}=====================================${NC}"
    echo -e "${RED}       FIO Workload Demo${NC}"
    echo -e "${RED}=====================================${NC}"
    echo
    echo -e "${GREEN}Running automatically with delays for readability${NC}"
    echo -e "${GREEN}Press Ctrl+C to exit the demo${NC}"
    echo
}

# Main demo function
run_demo() {
    show_title
    
    # Loop through each command
    for cmd in "${commands[@]}"; do
        
        # Display the command with prompt (skip echo commands)
        if [[ ! "$cmd" =~ ^echo ]]; then
            echo -e "${CYAN}$ ${cmd}${NC}"
        fi        sleep 0.5
        
        # Execute the command
        eval "$cmd" 2>&1
        
        # Separator for readability
        echo
        echo -e "${YELLOW}─────────────────────────────────────${NC}"
        echo
        
        # Small delay between commands
        sleep 1
    done
    
    # Demo completed message
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}       ✓ Demo completed successfully!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo -e "${BLUE}You can now:${NC}"
    echo -e "  • View full FIO logs: ${CYAN}kubectl logs fio-pod${NC}"
    echo -e "  • View clone logs: ${CYAN}kubectl logs fio-clone-pod${NC}"
    echo -e "  • Check all resources: ${CYAN}kubectl get all,pvc,volumesnapshot${NC}"
}

# Run the demo
run_demo
