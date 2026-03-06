#!/bin/bash
# Helper functions for fio-demo.sh refactoring (Step 1)
# These functions replace the command arrays and eval loops

# ============================================================================
# STEP 1: HELPER FUNCTIONS - Echo and Formatting Functions
# ============================================================================

# Echo colored header message
echo_header() {
    local message="$1"
    echo ""
    echo -e "${CYAN}━━━ $message ━━━${NC}"
    echo -e "${CYAN}${message}${NC}"
    echo ""
}

# Echo info message
echo_info() {
    local message="$1"
    echo -e "${CYAN}ℹ $message${NC}"
}

# Echo warning message
echo_warning() {
    local message="$1"
    echo -e "${YELLOW}⚠ $message${NC}"
}

# Echo success message
echo_success() {
    local message="$1"
    echo -e "${GREEN}✓ $message${NC}"
}

# Print separator line
print_separator() {
    echo -e "${YELLOW}─────────────────────────────────────${NC}"
}

# Show title banner
show_title() {
    clear
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║    FIO Workload Demo - Performance     ║${NC}"
    echo -e "${CYAN}║       Benchmarking & Snapshots         ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
}

# ============================================================================
# STEP 2: BASE DEMO FUNCTIONS - Deploy and Wait Functions
# ============================================================================

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

# ============================================================================
# STEP 3: SNAPSHOT FUNCTIONS
# ============================================================================

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

# ============================================================================
# STEP 4: CLONE FUNCTIONS
# ============================================================================

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

# ============================================================================
# STEP 5: COMPLETION MESSAGE
# ============================================================================

show_completion_message() {
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN} ✓ Demo completed successfully!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}You can now:${NC}"
    echo -e " • View full FIO logs: ${CYAN}kubectl logs fio-pod${NC}"
    echo -e " • View clone logs: ${CYAN}kubectl logs fio-clone-pod${NC}"
    echo -e " • Check all resources: ${CYAN}kubectl get all,pvc,volumesnapshot${NC}"
}

# ============================================================================
# NOTE:
# These functions replace the command arrays and eval loops in fio-demo.sh
# The refactored run_demo() function will call these functions directly
# instead of iterating through and executing eval commands
# ============================================================================
