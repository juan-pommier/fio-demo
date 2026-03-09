# fio-demo - Task List

This file tracks the current tasks and their status for the fio-demo project.

## Pending Tasks (To-Do)



- [ ] Externalize or clean up long YAML here-docs for better readability.
- [ ]     - **Implementation Plan:** Replace the inline YAML here-docs in `run_profile_deployment()` function (fio-demo.sh, lines 286-344) with `envsubst` calls using template files.
- [ ]     - **Details:** Use `fio-profile-pvc-template.yaml` and `fio-profile-deployment-template.yaml` with variable substitution instead of embedding 60-line YAML blocks inline.


## Completed Tasks
- [x] Replace fixed sleep for snapshot readiness with a readiness check or kubectl wait.
- [ ]     - Step 1: Modified check_snapshot_status() in fio-demo.sh (line 159).
- [ ]     - Step 2: Replaced 'sleep 3' with 'kubectl wait --for=condition=readyToUse volumesnapshot --timeout=60s'
- [ ]     - Step 3: Actively waits for volumesnapshot readiness condition instead of fixed 3-second delay.
- [ ]     - Step 4: Committed changes with message 'Improve: Replace fixed sleep with kubectl wait for snapshot readiness'.
- [x] Improve error handling and exit on failure in watch_resource and other kubectl calls.
- [ ]     - Step 1: Removed '2>/dev/null' redirects from kubectl get commands in watch_resource function (lines 87, 92, 100).
- [ ]     - Step 2: These redirects were hiding failures from kubectl commands, preventing proper error detection and propagation.
- [ ]     - Step 3: Committed changes with message 'Fix: Remove error-hiding 2>/dev/null redirects from watch_resource function'.
- [ ]     - Step 4: Fixes align with WORKFLOW.md guidelines: errors now properly surface and can be caught by '|| return 1' patterns in calling functions.
- [x] Add safety options (set -euo pipefail, kubectl presence/context checks) to all scripts.
   - Added set -euo pipefail to all shell scripts
   - Added kubectl presence and context checks to all scripts
   - - [x] Improve UX/logging (clear step titles, success/failure messages per phase).
     - [ ]   - echo_header, echo_info, echo_warning functions provide consistent messaging
     - [ ]     - All major phases have clear step titles and status messages
    
- [x] Simplify command arrays (avoid eval strings, favor direct functions/loops) in fio-demo.sh.
  - Step 1: Create helper functions (echo_header, echo_info, echo_warning, print_separator). (DONE - see REFACTORING_HELPERS.sh)
  - Step 2: Refactor base demo commands into focused functions (deploy_fio_pod, wait_fio_pod, check_fio_status, show_fio_logs). (DONE)
  - Step 3: Refactor snapshot commands into functions (create_snapshot, check_snapshot). (DONE)
  - Step 4: Refactor clone commands into functions (deploy_clone_pod, check_clone_status). (DONE)
  - Step 5: Update run_demo() to call functions directly instead of eval loops. (DONE)
  - Step 6: Remove old command arrays (commands, snapshot_commands, clone_commands). (DONE)
  - Completed in commit 6a7e43e (Phase 2-6: Simplify Command Arrays)

- [x] Clarify CLI flags and help text for -c / -s behavior in fio-demo.sh.
  - Step 1: Update help text with detailed OPTIONS section (DONE).
  - Step 2: Add EXAMPLES section showing flag combinations and workflows (DONE).
  - Note: Conservative approach (Option A) - improved help text without changing existing logic.
- [x] Reduce duplication of colors/banners by moving common pieces to a shared script.
  - Step 1: Created common.sh with shared colors and banner.
  - Step 2: Updated fio-demo.sh to source common.sh and removed local colors/banner.
  - Step 3: Updated cleanup.sh to source common.sh and removed local colors/banner.
  - Step 4: Updated force-clean.sh to source common.sh and added colors/banner usage.
     
  - - [x] 56
    - [ ]  to support multiple concurrent runs.
  - Step 1: Added FIO_NAMESPACE variable with configurable default ("default" namespace).
  - Step 2: Added ensure_namespace() function to create namespace if it doesn't exist.
  - Step 3: Added namespace flags (-n) to all kubectl commands in deploy_fio_pod and watch_resource functions.
  - Step 4: Updated watch_resource function to use namespace for kubectl get and kubectl wait commands.
  - Step 5: Committed changes with message 'Feat: Add namespace parameterization and auto-creation for FIO resources'.
  - Step 6: Enables concurrent runs with isolated namespaces via FIO_NAMESPACE environment variable.
  -   - Step 7: Modified FIO_NAMESPACE to detect the current context's default namespace using 'kubectl config view' with fallback to 'default'.
      -   - Step 8: Committed changes with message 'Feat: Use current context namespace by default for FIO_NAMESPACE'.
          - 
          - [x] **Fix critical syntax error** in fio-demo.sh (missing `fi` to close if statement).
          - [ ]   - Step 1: Added missing `fi` statement at end of script to close the conditional block starting at line 356 (if [ "$RUN_PROFILE" = true ]; then).
          - [ ]     - Step 2: This fixed the bash syntax error: "./fio-demo.sh: line 362: syntax error: unexpected end of file".
          - [ ]   - Committed changes with message 'Fix: Add missing fi to close if statement at end of script'.


-  Make force-clean.sh safer (no default namespace, stronger confirmation, avoid cluster-wide PV deletes).
-      - Step 1: Modified force-clean.sh to require explicit namespace argument (no default to prevent accidents).
-      - Step 2: Enhanced confirmation requirements: user must type 'yes' for namespace cleanup and 'I understand' for cluster-wide PV deletion.
-      - Step 3: Added safety checks to prevent cluster-wide PV deletion without explicit user confirmation.
-      - Step 4: Committed changes with message 'Refactor: Make force-clean.sh safer with required namespace and PV confirmation checks'.
---

**Last Updated:** When this file is modified
**Project:** fio-demo (https://github.com/juan-pommier/fio-demo)
