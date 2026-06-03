# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This repo is a Kubernetes-based FIO (Flexible I/O) benchmarking demo that showcases storage volume performance testing, volume snapshots, and clone-from-snapshot workflows. It is primarily used for live demos (e.g., KubeCon) against Tintri storage.

## Running the Demo

All scripts require `kubectl` with an active cluster context.

```bash
# Core demo script
./fio-demo.sh                # deploy FIO pod + PVC, run benchmark
./fio-demo.sh -s             # + create volume snapshot
./fio-demo.sh -c             # + snapshot + clone from snapshot
./fio-demo.sh -p <1-7> <N>  # generate N instances of profile (1=100%read, 7=100%write)

# Automated continuous workload (KubeCon AMS 2026 variant)
./kubecon2026ams-demo.sh     # runs random profiles in a loop, logs to fio-demo-kubecon2026ams.log

# Cleanup
./cleanup.sh                 # graceful teardown in reverse-deploy order
./force-clean.sh <namespace> # aggressive cleanup; requires "yes" + "I understand" confirmations
```

Key environment variable overrides (all scripts): `FIO_NAMESPACE`, `FIO_PVC_NAME`, `FIO_POD_NAME`.

## Architecture

```
fio-demo/
├── common.sh                        # sourced by all scripts: colors, banner, logging helpers
├── fio-demo.sh                      # main orchestration script
├── kubecon2026ams-demo.sh           # looping automation for demo booths
├── cleanup.sh / force-clean.sh      # teardown scripts
├── deployment/                      # Kubernetes manifests and envsubst templates
│   ├── fio-pvc.yaml / fio-deployment.yaml          # standard single-run resources
│   └── fio-profile-*-template.yaml                 # multi-instance profile templates
├── snapshot/                        # VolumeSnapshotClass + VolumeSnapshot manifests
└── clone/                           # PVC-from-snapshot + clone deployment manifests
```

**fio-demo.sh flow:** checks prerequisites -> `ensure_namespace()` -> `deploy_fio_pod()` -> `wait_fio_pod()` -> optionally `create_snapshot()` -> optionally `deploy_clone_pod()`. Each function is independently callable.

**Profile mode** (`-p`): uses `envsubst` on the `fio-profile-*-template.yaml` files to generate a multi-instance YAML bundle that is piped directly to `kubectl apply -f -`. Profile number maps to `rwmixread` percentage (profile 1 = 100% read, profile 7 = 0% read).

**kubecon2026ams-demo.sh**: runs in an infinite loop, randomly picks a profile (1-7) and instance count (MIN_PODS..MAX_PODS), deploys via `fio-demo.sh -p`, waits RUN_DURATION, then cleans up with `cleanup.sh`, waits PAUSE_DURATION, and repeats. Traps SIGINT/SIGTERM for clean exit.

## Conventions

- All scripts: `#!/bin/bash` + `set -euo pipefail`
- Source `common.sh` for all colored output and logging; never use raw `echo` for user-facing messages
- Use `echo_header`, `echo_info`, `echo_warning`, `echo_error` from `common.sh`
- Resource readiness: use `kubectl wait` or the `watch_resource()` function; avoid fixed `sleep` delays
- Inline YAML (heredoc in shell functions) for standard manifests; `envsubst` templates only for parameterized multi-instance cases
- Flag parsing with `getopts`; `-c` (clone) implies `-s` (snapshot)
- Storage class name: `vmstore-csi-file-driver-sc`; snapshot class: `vmstore-snapshot`
