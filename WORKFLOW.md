# fio-demo Project Workflow

## Project Overview

This project is a Kubernetes-based FIO (Flexible I/O) benchmarking tool that demonstrates volume snapshots, cloning, and performance testing on Kubernetes clusters.

## Development Workflow & Standards

### 1. Code Safety & Error Handling

**All bash scripts must include:**
```bash
#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures
```

**kubectl Validation:**
- Check kubectl installation: `if ! command -v kubectl &> /dev/null; then ...`
- Verify cluster connectivity: `if ! kubectl cluster-info &> /dev/null; then ...`
- These checks must come right after sourcing common.sh

### 2. Function Standards

**Error Handling Pattern:**
```bash
function_name() {
    echo_header "Step Title"
    command1 || return 1  # Return on failure
    command2 || return 1
}
```

**Messaging Pattern:**
- Use `echo_header` for major section titles
- Use `echo_info` for informational messages
- Use `echo_warning` for warnings
- All defined in common.sh

### 3. Task Management

**TASKS.md Structure:**
- **Pending Tasks (To-Do)**: `- [ ] Task description`
- **Completed Tasks**: `- [x] Task description` with sub-items
- Track progress by moving tasks between sections
- Add sub-items with `  - ` indentation to show implementation steps

### 4. Script Modifications Workflow

When modifying scripts:

1. **Read & Analyze**: Use `get_page_text` to understand full content
2. **Plan Changes**: Identify exactly which lines/functions need changes
3. **Edit Files**: Navigate to file, click Edit, make focused changes
4. **Test Mentally**: Verify logic won't break existing functionality
5. **Commit**: Use descriptive messages like "Add feature X to script.sh"
6. **Update TASKS.md**: Move task to Completed with implementation details
7. **Update DEV_NOTES.md**: Document significant changes

### 5. When to Avoid Changes

- Don't add `2>/dev/null` redirects (hides errors)
- Don't use default values for critical parameters
- Don't hardcode resource names (use parameters for concurrent runs)
- Don't skip error checking in kubectl operations

### 6. Documentation Requirements

**DEV_NOTES.md**:
- Document architectural decisions
- Explain non-obvious code sections
- List known limitations
- Track refactoring efforts

**Code Comments**:
- Explain WHY, not WHAT
- Comment complex logic and edge cases
- Keep comments in sync with code

### 7. Git Commit Standards

**Commit Message Format:**
```
[Feature/Fix/Refactor] Description of change
Optional detailed explanation
```

**Examples:**
- `Add safety: set -euo pipefail to common.sh`
- `Fix: Remove 2>/dev/null from kubectl calls`
- `Refactor: Extract YAML templates to separate files`

### 8. Task Progression

**Typical workflow for completing a task:**

1. Task is in "Pending Tasks" section
2. Move to "Working Tasks" section (mark with [x])
3. Implement changes across scripts
4. Update related documentation (TASKS.md, DEV_NOTES.md)
5. Commit changes with descriptive message
6. Move task to "Completed Tasks" with:
   - Main task marked with [x]
   - Sub-items showing what was done
   - Details of implementation approach

## Quick Reference Commands

### GitHub Web Editing
- Edit file: Click pencil icon in file view
- New file: Navigate to /new/main
- Find & replace: Ctrl+H in editor
- Go to line: Ctrl+G in editor

### Common File Operations
- Cut line: Triple-click to select, Ctrl+X
- Delete line: Ctrl+Shift+K (in VS Code style editors)
- Move text: Cut and paste
- Comment/uncomment: Varies by editor

## Known Challenges & Solutions

### Challenge: Large YAML Inline
**Solution**: Extract to separate files in deployment/snapshot/clone directories

### Challenge: Hardcoded Resource Names
**Solution**: Use variables passed as parameters or environment variables

### Challenge: Silent Failures
**Solution**: Always use error checking, remove `2>/dev/null` redirects

### Challenge: Complex Nested Functions
**Solution**: Break into smaller, single-purpose functions

## Future Improvement Areas

1. **Parameterize resource names** for concurrent runs
2. **Externalize YAML** templates from shell scripts
3. **Replace sleep with kubectl wait** for readiness checks
4. **Add kubectl wait** patterns throughout
5. **Make force-clean.sh safer** with namespace requirements
6. **Add comprehensive logging** with timestamps
7. **Create shell utility library** for common patterns

## Project Structure

```
fio-demo/
├── TASKS.md                 # Task tracking
├── WORKFLOW.md              # This file
├── DEV_NOTES.md             # Technical documentation
├── fio-demo.sh              # Main script
├── common.sh                # Shared functions & colors
├── cleanup.sh               # Cleanup resources
├── force-clean.sh           # Aggressive cleanup
├── deployment/              # Kubernetes deployment files
├── snapshot/                # Volume snapshot configs
└── clone/                   # Clone-related configs
```

## Contact & Notes

- Project Owner: juan-pommier
- Repository: https://github.com/juan-pommier/fio-demo
- Last Updated: March 6, 2026
