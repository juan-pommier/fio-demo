# fio-demo – Dev Notes

This file tracks planned improvements and a history of changes for collaboration.

## To-do

- Clarify CLI flags and help text for -c / -s behavior in fio-demo.sh.
- Add safety options (`set -euo pipefail`, kubectl presence/context checks) to all scripts.
- Improve error handling and exit on failure in watch_resource and other kubectl calls.
- Replace fixed sleep for snapshot readiness with a readiness check or kubectl wait.
- Reduce duplication of colors/banners by moving common pieces to a shared script.
- Simplify command arrays (avoid eval strings, favor direct functions/loops).
- Externalize or clean up long YAML here-docs for better readability.
- Improve UX/logging (clear step titles, success/failure messages per phase).
- Parameterize resource names to support multiple concurrent runs.
- Make force-clean.sh safer (no default namespace, stronger confirmation, avoid cluster-wide PV deletes).

## Done / History

- 2026-03-06: Initial review of fio-demo scripts and creation of this dev notes file as a shared baseline.
