# fio-demo Refactoring Plan: Simplify Command Arrays

## Overview
This document provides a comprehensive plan to refactor `fio-demo.sh` by replacing command arrays and `eval` loops with proper shell functions.

## Current Problem
The current implementation uses three arrays to store shell commands as strings:
- `commands` array: Base demo commands
- `snapshot_commands` array: Snapshot creation commands
- `clone_commands` array: Clone deployment commands

These commands are executed using `eval` loops, which:
1. Makes code harder to understand and maintain
2. Introduces security risks from unintended command evaluation
3. Makes debugging difficult
4. Reduces code reusability

## Solution Architecture
Replace arrays with focused functions that each perform a specific task:

### Phase 1: Helper Functions (COMPLETED)
✓ Created in `REFACTORING_HELPERS.sh`
- `echo_header()` - Display colored headers
- `echo_info()` - Display info messages  
- `echo_warning()` - Display warnings
- `echo_success()` - Display success messages
- `print_separator()` - Print separators
- `show_title()` - Show title banner

### Phase 2: Refactor Base Demo Functions (IN PROGRESS)
Replace the `commands` array with these functions:

```bash
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
```

### Phase 3: Refactor Snapshot Functions (PENDING)
Replace the `snapshot_commands` array:

```bash
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
```

### Phase 4: Refactor Clone Functions (PENDING)
Replace the `clone_commands` array:

```bash
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
```

### Phase 5: Update run_demo() Function (PENDING)
Replace the eval loops with direct function calls:

```bash
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
```

### Phase 6: Remove Old Command Arrays (PENDING)
Delete lines containing:
- `commands=(...)`  
- `snapshot_commands=(...)`
- `clone_commands=(...)`
- All the old eval loops in `run_demo()`

## Benefits After Refactoring

1. **Readability**: Code flow is clear and easy to follow
2. **Maintainability**: Each function has a single responsibility
3. **Reusability**: Functions can be called independently
4. **Error Handling**: Better error checking with proper return codes
5. **Testability**: Functions can be tested in isolation
6. **Security**: No eval command injection risks
7. **Documentation**: Self-documenting code with function names

## Implementation Notes

- All helper functions are already defined in `REFACTORING_HELPERS.sh`
- Copy all functions from `REFACTORING_HELPERS.sh` into `fio-demo.sh`
- Update the `run_demo()` function to call these functions directly
- Remove the old command arrays entirely
- Test thoroughly before committing

## Testing Checklist

- [ ] Base demo runs without -s or -c flags
- [ ] Snapshot creation works with -s flag
- [ ] Clone deployment works with -c flag
- [ ] Error handling works (failed commands stop execution)
- [ ] All kubectl calls use proper error checking
- [ ] Output formatting is consistent
- [ ] help text still works correctly

## Progress Tracking

See `TASKS.md` for overall progress and `REFACTORING_HELPERS.sh` for completed helper functions.
