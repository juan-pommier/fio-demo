#!/bin/bash

# Parse command line arguments

RUN_PROFILE=false
RUN_SNAPSHOT=false
RUN_CLONE=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "${SCRIPT_DIR}/common.sh"

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
                      -p)
            RUN_PROFILE=true
            shift
            ;;
            -h|--help)
              echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "OPTIONS:"
            echo "  -s, --snapshot    Run base demo + create snapshot (2 phases)"
            echo "  -c, --clone       Run base demo + snapshot + clone from snapshot (3 phases)"
            echo "  -p, --profile     Generate profile-based multi-instance YAML bundle"
            echo ""
            echo "EXAMPLES:"
            echo "  $0              # Run base demo only"
            echo "  $0 -s           # Run: base demo → snapshot"
            echo "  $0 -c           # Run: base demo → snapshot → clone"
            
            ;;
            *)
              echo "Unknown option: $1"
              echo "Use -h or --help for usage information"
              exit 1
              ;;
    esac
done

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
# Deploy FIO pod and PVC
deploy_fio_pod() {
    echo_header "Deploying FIO Workload Pod"
    echo_info "This will create a PVC and deploy a FIO pod that runs I/O benchmarks..."

    kubectl apply -f deployment/fio-pvc.yaml || return 1
    watch_resource pvc fio-pvc 30 || return 1

    kubectl apply -f deployment/fio-deployment.yaml || return 1
    watch_resource pod fio-pod 60 || return 1
}

# Wait for FIO pod to be ready
wait_fio_pod() {
    echo_header "Waiting for FIO Pod to be Ready"
    kubectl wait --for=condition=ready pod/fio-pod --timeout=300s || \
        echo_warning "Warning: Pod may still be starting..."
}

# Check FIO pod status
check_fio_status() {
    echo_header "Checking FIO Pod Status"
    kubectl get pods,pvc -o wide
}

# Show FIO logs
show_fio_logs() {
    echo_header "FIO Benchmark Output (first 20 lines)"
    kubectl logs fio-pod --tail=20 || \
        echo_warning "Pod logs not yet available..."
}

# Snapshot commands (run only with -s or --snapshot flag)
# Create volume snapshot
create_snapshot() {
    echo_header "Creating Volume Snapshot"
    echo_info "This captures the current state of the PVC for cloning..."

    kubectl apply -f snapshot/volumesnapshotclass.yaml || return 1
    kubectl apply -f snapshot/volumesnapshot.yaml || return 1
}

# Check snapshot status
check_snapshot_status() {
    echo_header "Waiting for Snapshot to be Ready"
    sleep 3

    echo_header "Checking Snapshot Status"
    kubectl get volumesnapshot,volumesnapshotcontent -o wide
}

# Clone commands (run with -c flag, includes snapshot)
# Deploy clone from snapshot
deploy_clone_pod() {
    echo_header "Deploying Clone from Snapshot"
    echo_info "This creates a new PVC from the snapshot and deploys a clone pod..."

    kubectl apply -f clone/clone-pvc-from-snapshot.yaml || return 1
    watch_resource pvc fio-clone-pvc 30 || return 1

    kubectl apply -f clone/fio-deployment-clone.yaml || return 1
    watch_resource pod fio-clone-pod 60 || return 1
}

# Wait for clone pod
wait_clone_pod() {
    echo_header "Waiting for Clone Pod to be Ready"
    kubectl wait --for=condition=ready pod/fio-clone-pod --timeout=300s || \
        echo_warning "Warning: Clone pod may still be starting..."
}

# Check clone pod status
check_clone_status() {
    echo_header "Checking Clone Pod Status"
    kubectl get pods,pvc -o wide
}

# Show clone logs
show_clone_logs() {
    echo_header "Clone FIO Benchmark Output (first 20 lines)"
    kubectl logs fio-clone-pod --tail=20 || \
        echo_warning "Clone pod logs not yet available..."
}

# Main demo function
run_demo() {
    show_title

    # Run base demo commands
    deploy_fio_pod || { echo_warning "Failed to deploy FIO pod"; return 1; }
    wait_fio_pod
    check_fio_status
    show_fio_logs

    # Run snapshot commands if flag is set
    if [ "$RUN_SNAPSHOT" = true ]; then
        echo -e "${CYAN}━━━ Running Snapshot Commands ━━━${NC}"
        create_snapshot || { echo_warning "Failed to create snapshot"; return 1; }
        check_snapshot_status
    fi

    # Run clone commands if flag is set (includes snapshot)
    if [ "$RUN_CLONE" = true ]; then
        if [ "$RUN_SNAPSHOT" != true ]; then
            echo -e "${CYAN}━━━ Running Snapshot Commands (required for clone) ━━━${NC}"
            create_snapshot || { echo_warning "Failed to create snapshot"; return 1; }
            check_snapshot_status
        fi

        echo -e "${CYAN}━━━ Running Clone Commands ━━━${NC}"
        deploy_clone_pod || { echo_warning "Failed to deploy clone pod"; return 1; }
        wait_clone_pod
        check_clone_status
        show_clone_logs
    fi

    show_completion_message
}

# Function to run profile-based deployment
run_profile_deployment() {
    echo -e "${CYAN}━━━ FIO Profile-Based Multi-Instance Deployment ━━━${NC}"
    echo
    
    # User input for profile selection
    echo "Select FIO profile:"
    echo "1) 80/20 Read/Write"
    echo "2) 90/10 Read/Write"
    echo "3) 70/30 Read/Write"
    echo "4) 10/90 Read/Write"
    echo "5) 1/99 Read/Write"
    read -p "Enter choice [1-5]: " profile_choice
    
    case $profile_choice in
        1) PROFILE="8020"; RWMIX=80;;
        2) PROFILE="9010"; RWMIX=90;;
        3) PROFILE="7030"; RWMIX=70;;
        4) PROFILE="1090"; RWMIX=10;;
        5) PROFILE="199";  RWMIX=1;;
        *) echo -e "${RED}Invalid choice${NC}"; exit 1;;
    esac
    
    read -p "How many instances (pods)?: " INSTANCES
    if ! [[ "$INSTANCES" =~ ^[0-9]+$ ]] || [ "$INSTANCES" -le 0 ]; then
        echo -e "${RED}Invalid number of instances${NC}"
        exit 1
    fi
    
    STORAGECLASS="vmstore-csi-file-driver-sc"
    PVC_SIZE="25Gi"
    TS=$(date +%s)
    BASE_NAME="fio-${PROFILE}-${TS}"
    
    OUTFILE="${BASE_NAME}-bundle.yaml"
    > $OUTFILE
    
    echo -e "${CYAN}Generating YAML bundle...${NC}"
    
    for i in $(seq 1 $INSTANCES); do
        PVC_NAME="${BASE_NAME}-pvc-${i}"
        DEPLOY_NAME="${BASE_NAME}-deploy-${i}"
        
        cat <<EOF >> $OUTFILE
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${PVC_NAME}
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: ${PVC_SIZE}
  storageClassName: ${STORAGECLASS}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${DEPLOY_NAME}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${DEPLOY_NAME}
  template:
    metadata:
      labels:
        app: ${DEPLOY_NAME}
    spec:
      containers:
      - name: fio
        image: ljishen/fio
        command:
          - /bin/sh
          - -c
          - |
            set -e
            fallocate -l 10G /data/testfile || dd if=/dev/zero of=/data/testfile bs=1M count=10240
            fio --name=${PROFILE}demo-pvc-perf \\
                --filename=/data/testfile \\
                --bs=8k \\
                --size=10G \\
                --rw=randrw \\
                --rwmixread=${RWMIX} \\
                --iodepth=4 \\
                --numjobs=1 \\
                --direct=1 \\
                --runtime=600 \\
                --time_based \\
                --group_reporting \\
                --ioengine=libaio \\
                --thread
        volumeMounts:
        - name: fio-pvc
          mountPath: /data
      volumes:
      - name: fio-pvc
        persistentVolumeClaim:
          claimName: ${PVC_NAME}
EOF
    done
    
    echo
    echo -e "${GREEN}✓ YAML bundle generated: $OUTFILE${NC}"
    echo -e "${CYAN}To deploy, run: ${WHITE}kubectl apply -f $OUTFILE${NC}"
    echo
}

# Run the demo
# Choose which mode to run
if [ "$RUN_PROFILE" = true ]; then
    run_profile_deployment
else
    run_demo
fi
