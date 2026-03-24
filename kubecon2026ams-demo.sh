#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIO_DEMO_SCRIPT="${SCRIPT_DIR}/fio-demo.sh"
LOG_FILE="${SCRIPT_DIR}/fio-demo-kubecon2026ams.log"

MIN_PODS=1
MAX_PODS=15
RUN_DURATION=900
PAUSE_DURATION=900

CURRENT_OUTFILE=""
CURRENT_PROFILE_CHOICE=""
CURRENT_INSTANCES=""

log() {
  local msg="$*"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${msg}" | tee -a "$LOG_FILE"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Required command not found: $1" >&2
    exit 1
  }
}

profile_code_from_choice() {
  case "$1" in
    1) echo "991" ;;
    2) echo "9010" ;;
    3) echo "7030" ;;
    4) echo "5050" ;;
    5) echo "3070" ;;
    6) echo "1090" ;;
    7) echo "199" ;;
    *) return 1 ;;
  esac
}

profile_label_from_choice() {
  case "$1" in
    1) echo "99/1" ;;
    2) echo "90/10" ;;
    3) echo "70/30" ;;
    4) echo "50/50" ;;
    5) echo "30/70" ;;
    6) echo "10/90" ;;
    7) echo "1/99" ;;
    *) return 1 ;;
  esac
}

pick_random_profile_choice() {
  echo $(( RANDOM % 7 + 1 ))
}

pick_random_instances() {
  echo $(( RANDOM % (MAX_PODS - MIN_PODS + 1) + MIN_PODS ))
}

find_latest_bundle_for_profile() {
  local profile_code="$1"

  find "$SCRIPT_DIR" -maxdepth 1 -type f -name "fio-${profile_code}-*-bundle.yaml" -printf '%T@ %p\n' 2>/dev/null \
    | sort -nr \
    | head -n1 \
    | cut -d' ' -f2-
}

generate_bundle() {
  local profile_choice="$1"
  local instances="$2"
  local profile_code
  local profile_label
  local expected_ts

  profile_code="$(profile_code_from_choice "$profile_choice")"
  profile_label="$(profile_label_from_choice "$profile_choice")"
  expected_ts="$(date +%s)"
  CURRENT_OUTFILE="${SCRIPT_DIR}/fio-${profile_code}-${expected_ts}-bundle.yaml"

  log "Generating bundle: profile_choice=${profile_choice} profile=${profile_label} profile_code=${profile_code} pods=${instances}"

  printf "%s\n%s\n" "$profile_choice" "$instances" | bash "$FIO_DEMO_SCRIPT" -p | tee -a "$LOG_FILE"

  if [[ ! -f "${CURRENT_OUTFILE}" ]]; then
    log "Predicted bundle not found, searching fallback for newest matching bundle"
    CURRENT_OUTFILE="$(find_latest_bundle_for_profile "$profile_code")"
  fi

  if [[ -z "${CURRENT_OUTFILE}" || ! -f "${CURRENT_OUTFILE}" ]]; then
    log "Failed to locate generated bundle for profile_code=${profile_code}"
    exit 1
  fi

  log "Bundle generated successfully: ${CURRENT_OUTFILE}"
}

deploy_bundle() {
  log "Applying bundle ${CURRENT_OUTFILE}"
  kubectl apply -f "${CURRENT_OUTFILE}"
}

delete_bundle() {
  if [[ -n "${CURRENT_OUTFILE}" && -f "${CURRENT_OUTFILE}" ]]; then
    log "Deleting bundle ${CURRENT_OUTFILE}"
    kubectl delete -f "${CURRENT_OUTFILE}" --ignore-not-found=true || true
    rm -f "${CURRENT_OUTFILE}" || true
    CURRENT_OUTFILE=""
  fi
}

cleanup_on_exit() {
  log "Interrupt received, cleaning up current bundle if present"
  delete_bundle
  exit 0
}

main() {
  require_cmd bash
  require_cmd kubectl
  require_cmd tee
  require_cmd find
  require_cmd sort
  require_cmd head
  require_cmd cut

  if [[ ! -f "${FIO_DEMO_SCRIPT}" ]]; then
    echo "Cannot find fio-demo.sh in ${SCRIPT_DIR}" >&2
    exit 1
  fi

  if (( MAX_PODS < MIN_PODS )); then
    echo "Invalid pod range: MIN_PODS=${MIN_PODS}, MAX_PODS=${MAX_PODS}" >&2
    exit 1
  fi

  trap cleanup_on_exit INT TERM

  log "Starting fio-demo-kubecon2026ams loop"
  log "Config: MIN_PODS=${MIN_PODS} MAX_PODS=${MAX_PODS} RUN_DURATION=${RUN_DURATION}s PAUSE_DURATION=${PAUSE_DURATION}s"

  while true; do
    CURRENT_PROFILE_CHOICE="$(pick_random_profile_choice)"
    CURRENT_INSTANCES="$(pick_random_instances)"

    log "Selected random run: profile_choice=${CURRENT_PROFILE_CHOICE} instances=${CURRENT_INSTANCES}"

    generate_bundle "${CURRENT_PROFILE_CHOICE}" "${CURRENT_INSTANCES}"
    deploy_bundle

    log "Sleeping ${RUN_DURATION}s while workload runs"
    sleep "${RUN_DURATION}"

    delete_bundle

    log "Sleeping ${PAUSE_DURATION}s before next run"
    sleep "${PAUSE_DURATION}"
  done
}

main "$@"
