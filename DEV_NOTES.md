# fio-demo – Dev Notes

This file tracks planned improvements and a history of changes for collaboration.

## Task Tracking

**Note:** Task lists have been consolidated into [`TASKS.md`](TASKS.md) for better tracking and organization.

For current status on all pending tasks, in-progress work, and completed items, please refer to **[TASKS.md](TASKS.md)**.

Files in this project:
- **TASKS.md** - Primary task tracking with checkbox status (Pending, In Progress, Completed)
- **REFACTORING_PLAN.md** - Detailed refactoring guide with code examples and implementation phases
- **REFACTORING_HELPERS.sh** - Pre-written helper functions for the refactoring task
- **DEV_NOTES.md** - Development history and collaboration notes (this file)

## History

- 2026-03-06: Created TASKS.md as the primary task tracking file to consolidate and standardize task management across the project.
- 2026-03-06: Created REFACTORING_PLAN.md with detailed 6-phase implementation guide for simplifying command arrays.
- 2026-03-06: Created REFACTORING_HELPERS.sh with all helper functions needed for the refactoring (Step 1 complete).
- 2026-03-06: Initial review of fio-demo scripts and creation of this dev notes file as a shared baseline.
- 2026-03-06: Added common.sh with shared color definitions and banner (Step 1 for deduplicating colors/banners).
- 2026-03-06: Completed all 4 steps for reducing duplication: created common.sh and updated all three scripts (fio-demo.sh, cleanup.sh, force-clean.sh) to source and use shared colors/banner.
- 2026-03-06: Clarified CLI flags -s and -c: improved help text with detailed OPTIONS and EXAMPLES sections explaining phase counts and workflows.
