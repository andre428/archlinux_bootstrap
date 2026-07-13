#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

PHASES_DIR="./phases"

usage() {
  cat <<EOF
Usage: ./run.sh [options] [phase-number...]

Options:
  --list        Show all phases and their completion state
  --from N      Run phase N onward
  --force       Rerun even if marked complete (same as FORCE=1)
  -h, --help    This help

Examples:
  ./run.sh                  # run everything, skip already-done phases
  ./run.sh 05 06             # run only phases 05 and 06
  ./run.sh --from 03         # run phase 03 onward
  ./run.sh --force 01        # force-rerun phase 01
EOF
}

mapfile -t ALL_PHASES < <(find "${PHASES_DIR}" -maxdepth 1 -name '*.sh' | sort)

list_phases() {
  for p in "${ALL_PHASES[@]}"; do
    local name; name="$(basename "$p" .sh)"
    if [[ -f "${HOME}/.local/state/bootstrap/${name}.done" ]]; then
      printf "  [x] %s\n" "$name"
    else
      printf "  [ ] %s\n" "$name"
    fi
  done
}

REBOOT_MARKER="${HOME}/.local/state/bootstrap/REBOOT_REQUIRED"

run_phase() {
  local script="$1"
  echo; echo "==== Running $(basename "$script" .sh) ===="
  bash "$script"
  if [[ -f "$REBOOT_MARKER" ]]; then
    rm -f "$REBOOT_MARKER"
    echo
    echo ">>> Reboot required. Reboot now, then run ./run.sh again"
    echo ">>> to continue with the remaining phases (completed ones are skipped)."
    exit 0
  fi
}

FROM=""
declare -a SELECTED=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --list) list_phases; exit 0 ;;
    --from) FROM="$2"; shift 2 ;;
    --force) export FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) SELECTED+=("$1"); shift ;;
  esac
done

if [[ ${#SELECTED[@]} -gt 0 ]]; then
  for name in "${SELECTED[@]}"; do
    match="$(find "${PHASES_DIR}" -maxdepth 1 -name "${name}*.sh" | sort | head -n1)"
    [[ -z "$match" ]] && { echo "No phase matching '${name}'"; exit 1; }
    run_phase "$match"
  done
  exit 0
fi

for p in "${ALL_PHASES[@]}"; do
  name="$(basename "$p" .sh)"; num="${name%%-*}"
  if [[ -n "$FROM" && "$num" < "$FROM" ]]; then continue; fi
  run_phase "$p"
done
