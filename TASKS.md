# fio-demo - Task List

This file tracks the current tasks and their status for the fio-demo project.

## Pending Tasks (To-Do)

- [ ] Add safety options ( set -euo pipefail , kubectl presence/context checks) to all scripts.
- [ ] Improve error handling and exit on failure in watch_resource and other kubectl calls.
- [ ] Replace fixed sleep for snapshot readiness with a readiness check or kubectl wait.
- [ ] Simplify command arrays (avoid eval strings, favor direct functions/loops).
- [ ] Externalize or clean up long YAML here-docs for better readability.
- [ ] Improve UX/logging (clear step titles, success/failure messages per phase).
- [ ] Parameterize resource names to support multiple concurrent runs.
- [ ] Make force-clean.sh safer (no default namespace, stronger confirmation, avoid cluster-wide PV deletes).

## In Progress

- [x] Simplify command arrays (avoid eval strings, favor direct functions/loops) in fio-demo.sh.
  - Step 1: Create helper functions (echo_header, echo_info, echo_warning, print_separator). (DONE - see REFACTORING_HELPERS.sh)
  - Step 2: Refactor base demo commands into focused functions (deploy_fio_pod, wait_fio_pod, check_fio_status, show_fio_logs).
  - Step 3: Refactor snapshot commands into functions (create_snapshot, check_snapshot).
  - Step 4: Refactor clone commands into functions (deploy_clone_pod, check_clone_status).
  - Step 5: Update run_demo() to call functions directly instead of eval loops.
  - Step 6: Remove old command arrays (commands, snapshot_commands, clone_commands).

## Completed Tasks

- [x] Clarify CLI flags and help text for -c / -s behavior in fio-demo.sh.
  - Step 1: Update help text with detailed OPTIONS section (DONE).
  - Step 2: Add EXAMPLES section showing flag combinations and workflows (DONE).
  - Note: Conservative approach (Option A) - improved help text without changing existing logic.
- [x] Reduce duplication of colors/banners by moving common pieces to a shared script.
  - Step 1: Created common.sh with shared colors and banner.
  - Step 2: Updated fio-demo.sh to source common.sh and removed local colors/banner.
  - Step 3: Updated cleanup.sh to source common.sh and removed local colors/banner.
  - Step 4: Updated force-clean.sh to source common.sh and added colors/banner usage.

---

**Last Updated:** When this file is modified
**Project:** fio-demo (https://github.com/juan-pommier/fio-demo)
