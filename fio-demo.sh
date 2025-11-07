#!/bin/bash

# Parse command line arguments

RUN_SNAPSHOT=false
RUN_CLONE=false

while [[ $# -gt 0 ]]; do
    case $1 in
            -s)
              RUN_SNAPSHOT=true
              shift
              ;;
            -c)
              RUN_SNAPSHOT=true
              RUN_CLONE=true
              shift
              ;;
            -h|--help)
                          echo "Usage: $0 [-s] [-c]"
              
              echo "  -s              Run snapshot commands"
              echo "  -c              Run clone commands (includes snapshot)"
              exit 0
              ;;
            *)
              echo "Unknown option: $1"
              echo "Use -h or --help for usage information"
              exit 1
              ;;
    esac
done

# Colors for better readability
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function to watch a resource until it's ready or timeout

watch_resource() {
    local resource_type="$1"
    local resource_name="$2"
    local timeout="${3:-30}"
    
    echo -e "${CYAN}Watching $resource_type/$resource_name...${NC}"
    
    local start_time=$(date +%s)
    local end_time=$((start_time + timeout))
    
    # Loop until resource is ready or timeout
    while true; do
        local current_time=$(date +%s)
        
        # Check if timeout reached
        if [ $current_time -ge $end_time ]; then
            echo -e "${YELLOW}Timeout reached${NC}"
            break
        fi
        
        # Display current status
        clear
        echo -e "${CYAN}Watching $resource_type/$resource_name... ($(($end_time - $current_time))s remaining)${NC}"
        kubectl get $resource_type $resource_name -o wide 2>/dev/null
        
        # Check if resource is ready
        if [ "$resource_type" = "pvc" ]; then
            # For PVC, check if status is Bound
            local status=$(kubectl get pvc $resource_name -o jsonpath='{.status.phase}' 2>/dev/null)
            if [ "$status" = "Bound" ]; then
                echo -e "${GREEN}✓ PVC is Bound!${NC}"
                sleep 2
                break
            fi
        elif [ "$resource_type" = "pod" ]; then
            # For Pod, check if all containers are ready
            local ready=$(kubectl get pod $resource_name -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
            if [ "$ready" = "True" ]; then
                echo -e "${GREEN}✓ Pod is Ready!${NC}"
                sleep 2
                break
            fi
        fi
        
        # Wait 2 seconds before next check (like watch -n 2)
        sleep 2
    done
    
    echo
}
# Array of commands to demonstrate
commands=(
#Deploy the FIO App::
"echo -e \"${CYAN}━━━ Deploying FIO Workload Pod ━━━${NC}\""
"echo -e \"${CYAN}This will create a PVC and deploy a FIO pod that runs I/O benchmarks...${NC}\""
"kubectl apply -f deployment/fio-pvc.yaml"
"watch_resource pvc fio-pvc 30"
"kubectl apply -f deployment/fio-deployment.yaml"
"watch_resource pod fio-pod 60"

#Wait for pod to be ready::
"echo -e \"${CYAN}━━━ Waiting for FIO Pod to be Ready ━━━${NC}\""
"kubectl wait --for=condition=ready pod/fio-pod --timeout=300s || echo -e \"${YELLOW}Warning: Pod may still be starting...${NC}\""

#Check the FIO pod status::
"echo -e \"${CYAN}━━━ Checking FIO Pod Status ━━━${NC}\""
"kubectl get pods,pvc -o wide"

#Monitor FIO output::
"echo -e \"${CYAN}━━━ FIO Benchmark Output (first 20 lines) ━━━${NC}\""
"kubectl logs fio-pod --tail=20 || echo -e \"${YELLOW}Pod logs not yet available...${NC}\""
)

# Snapshot commands (run only with -s or --snapshot flag)
snapshot_commands=(

#SnapShot The PVC::
"echo -e \"${CYAN}━━━ Creating Volume Snapshot ━━━${NC}\""
"echo -e \"${CYAN}This captures the current state of the PVC for cloning...${NC}\""
"kubectl apply -f snapshot/volumesnapshotclass.yaml"
"kubectl apply -f snapshot/volumesnapshot.yaml"

#Wait for snapshot to be ready::
"echo -e \"${CYAN}━━━ Waiting for Snapshot to be Ready ━━━${NC}\""
"sleep 3"

#Check the snapshot::
"echo -e \"${CYAN}━━━ Checking Snapshot Status ━━━${NC}\""
"kubectl get volumesnapshot,volumesnapshotcontent -o wide"
)

# Clone commands (run with -c flag, includes snapshot)
clone_commands=(

#Deploy App with Clone Data::
"echo -e \"${CYAN}━━━ Deploying Clone from Snapshot ━━━${NC}\""
"echo -e \"${CYAN}This creates a new PVC from the snapshot and deploys a clone pod...${NC}\""
"kubectl apply -f clone/clone-pvc-from-snapshot.yaml"
"watch_resource pvc fio-clone-pvc 30"
"kubectl apply -f clone/fio-deployment-clone.yaml"
"watch_resource pod fio-clone-pod 60"

#Wait for clone pod::
"echo -e \"${CYAN}━━━ Waiting for Clone Pod to be Ready ━━━${NC}\""
"kubectl wait --for=condition=ready pod/fio-clone-pod --timeout=300s || echo -e \"${YELLOW}Warning: Clone pod may still be starting...${NC}\""

#Check the Clone Pod Details::
"echo -e \"${CYAN}━━━ Checking Clone Pod Status ━━━${NC}\""
"kubectl get pods,pvc -o wide"

#Show clone logs::
"echo -e \"${CYAN}━━━ Clone FIO Benchmark Output (first 20 lines) ━━━${NC}\""
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
run_demo(){
    show_title
    
        # Run base commands
    for cmd in "${commands[@]}"; do
        
        # Display the command with prompt (skip echo commands)
        if [[ ! "$cmd" =~ ^echo ]]; then
            echo -e "${CYAN}$ ${cmd}${NC}"
        fi
        sleep 0.5
        
        # Execute the command
        eval "$cmd" 2>&1
        
        # Separator for readability
        echo
        echo -e "${YELLOW}─────────────────────────────────────${NC}"
        echo
        
        # Small delay between commands
        sleep 1
    done
    
    # Run snapshot commands if flag is set
        # Run snapshot commands if flag is set
    if [ "$RUN_SNAPSHOT" = true ]; then
        echo -e "${CYAN}━━━ Running Snapshot Commands ━━━${NC}"
        for cmd in "${snapshot_commands[@]}"; do
            
            # Display the command with prompt (skip echo commands)
            if [[ ! "$cmd" =~ ^echo ]]; then
                echo -e "${CYAN}$ ${cmd}${NC}"
            fi
            sleep 0.5
            
            # Execute the command
            eval "$cmd" 2>&1
            
            # Separator for readability
            echo
            echo -e "${YELLOW}─────────────────────────────────────${NC}"
            echo
            
            # Small delay between commands
            sleep 1
        done
    fi
    
    # Run clone commands if flag is set (includes snapshot)
    if [ "$RUN_CLONE" = true ]; then
        # First run snapshot commands if not already run
        if [ "$RUN_SNAPSHOT" != true ]; then
            echo -e "${CYAN}━━━ Running Snapshot Commands (required for clone) ━━━${NC}"
            for cmd in "${snapshot_commands[@]}"; do
                
                # Display the command with prompt (skip echo commands)
                if [[ ! "$cmd" =~ ^echo ]]; then
                    echo -e "${CYAN}$ ${cmd}${NC}"
                fi
                sleep 0.5
                
                # Execute the command
                eval "$cmd" 2>&1
                
                # Separator for readability
                echo
                echo -e "${YELLOW}─────────────────────────────────────${NC}"
                echo
                
                # Small delay between commands
                sleep 1
            done
        fi
        
        # Now run clone commands
        echo -e "${CYAN}━━━ Running Clone Commands ━━━${NC}"
        for cmd in "${clone_commands[@]}"; do
            
            # Display the command with prompt (skip echo commands)
            if [[ ! "$cmd" =~ ^echo ]]; then
                echo -e "${CYAN}$ ${cmd}${NC}"
            fi
            sleep 0.5
            
            # Execute the command
            eval "$cmd" 2>&1
            
            # Separator for readability
            echo
            echo -e "${YELLOW}─────────────────────────────────────${NC}"
            echo
            
            # Small delay between commands
            sleep 1
        done
 fi
    # Demo completed message
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}       ✓ Demo completed successfully!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo -e "${CYAN}You can now:${NC}"
    echo -e "  • View full FIO logs: ${CYAN}kubectl logs fio-pod${NC}"
    echo -e "  • View clone logs: ${CYAN}kubectl logs fio-clone-pod${NC}"
    echo -e "  • Check all resources: ${CYAN}kubectl get all,pvc,volumesnapshot${NC}"
}

# Run the demo
run_demo
