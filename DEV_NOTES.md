# fio-demo – Dev Notes

This file tracks planned improvements and a history of changes for collaboration.

## To-do

- Add safety options (`set -euo pipefail`, kubectl presence/context checks) to all scripts.
- Improve error handling and exit on failure in watch_resource and other kubectl calls.
- Replace fixed sleep for snapshot readiness with a readiness check or kubectl wait.
- Simplify command arrays (avoid eval strings, favor direct functions/loops).
- Externalize or clean up long YAML here-docs for better readability.
- Improve UX/logging (clear step titles, success/failure messages per phase).
- Parameterize resource names to support multiple concurrent runs.
- Make force-clean.sh safer (no default namespace, stronger confirmation, avoid cluster-wide PV deletes).

## Working on

- Nothing

## Done

- Clarify CLI flags and help text for -c / -s behavior in fio-demo.sh.
  - Step 1: Update help text with detailed OPTIONS section (DONE).
  - Step 2: Add EXAMPLES section showing flag combinations and workflows (DONE).
  - Note: Conservative approach (Option A) - improved help text without changing existing logic.

- Reduce duplication of colors/banners by moving common pieces to a shared script.
  - Step 1: Created common.sh with shared colors and banner.
  - Step 2: Updated fio-demo.sh to source common.sh and removed local colors/banner.
  - Step 3: Updated cleanup.sh to source common.sh and removed local colors/banner.
  - Step 4: Updated force-clean.sh to source common.sh and added colors/banner usage.

## History

- 2026-03-06: Initial review of fio-demo scripts and creation of this dev notes file as a shared baseline.
- 2026-03-06: Added common.sh with shared color definitions and banner (Step 1 for deduplicating colors/banners).
- 2026-03-06: Completed all 4 steps for reducing duplication: created common.sh and updated all three scripts (fio-demo.sh, cleanup.sh, force-clean.sh) to source and use shared colors/banner.
- 2026-03-06: Clarified CLI flags -s and -c: improved help text with detailed OPTIONS and EXAMPLES sections explaining phase counts and workflows.
