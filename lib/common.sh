#!/usr/bin/env bash
# lib/common.sh — shared helpers for all phase scripts.
# Source this, don't execute it: `source ./lib/common.sh`
set -euo pipefail

C_RESET='\033[0m'; C_INFO='\033[1;34m'; C_OK='\033[1;32m'
C_WARN='\033[1;33m'; C_ERR='\033[1;31m'

log_info() { printf "${C_INFO}[INFO]${C_RESET} %s\n" "$*"; }
log_ok()   { printf "${C_OK}[ OK ]${C_RESET} %s\n" "$*"; }
log_warn() { printf "${C_WARN}[WARN]${C_RESET} %s\n" "$*"; }
log_err()  { printf "${C_ERR}[FAIL]${C_RESET} %s\n" "$*" >&2; }

# ---- context guards ----
# Run everything as the normal sudo user; AUR builds refuse root outright.
require_user() {
  if [[ "${EUID}" -eq 0 ]]; then
    log_err "Run this as your normal sudo user, not root (AUR builds refuse root)."
    exit 1
  fi
}

require_sudo() {
  require_user
  sudo -v || { log_err "sudo credentials required."; exit 1; }
}

# ---- state tracking (enables safe re-runs / resume after reboot) ----
STATE_DIR="${HOME}/.local/state/bootstrap"
mkdir -p "${STATE_DIR}"

phase_done()  { [[ -f "${STATE_DIR}/${1}.done" ]]; }
mark_done()   { touch "${STATE_DIR}/${1}.done"; }

skip_if_done() {
  local phase="$1"
  if phase_done "${phase}" && [[ "${FORCE:-0}" -ne 1 ]]; then
    log_ok "Phase ${phase} already completed — skipping (FORCE=1 to rerun)."
    exit 0
  fi
}

# ---- pacman helpers ----
pkg_installed() { pacman -Qi "$1" &>/dev/null; }

install_pacman() {
  local -a pkgs=("$@") missing=()
  for p in "${pkgs[@]}"; do pkg_installed "$p" || missing+=("$p"); done
  if [[ ${#missing[@]} -eq 0 ]]; then
    log_ok "All ${#pkgs[@]} pacman packages already present."
    return 0
  fi
  log_info "Installing: ${missing[*]}"
  sudo pacman -S --needed --noconfirm "${missing[@]}"
}

# Package list files: one pkg per line, '#' comments allowed, blank lines ignored.
install_pacman_from_list() {
  local list_file="$1"
  [[ -f "$list_file" ]] || { log_err "Missing package list: $list_file"; exit 1; }
  local -a pkgs=()
  while IFS= read -r line; do
    line="${line%%#*}"
    line="$(echo -n "$line" | xargs)"
    [[ -z "$line" ]] && continue
    pkgs+=("$line")
  done < "$list_file"
  install_pacman "${pkgs[@]}"
}

# ---- AUR helper ----
install_aur() {
  require_user
  local -a pkgs=("$@") missing=()
  for p in "${pkgs[@]}"; do pkg_installed "$p" || missing+=("$p"); done
  if [[ ${#missing[@]} -eq 0 ]]; then
    log_ok "All ${#pkgs[@]} AUR packages already present."
    return 0
  fi
  command -v paru &>/dev/null || { log_err "paru missing — run phase 02 first."; exit 1; }
  log_info "Installing (AUR): ${missing[*]}"
  paru -S --needed --noconfirm "${missing[@]}"
}

install_aur_from_list() {
  local list_file="$1"
  [[ -f "$list_file" ]] || { log_err "Missing package list: $list_file"; exit 1; }
  local -a pkgs=()
  while IFS= read -r line; do
    line="${line%%#*}"
    line="$(echo -n "$line" | xargs)"
    [[ -z "$line" ]] && continue
    pkgs+=("$line")
  done < "$list_file"
  install_aur "${pkgs[@]}"
}

service_enable_now() { sudo systemctl enable --now "$1"; }

# ---- reboot checkpoints ----
# Call this at the end of a phase that needs a reboot before the next
# phase can safely run (new kernel, display/login manager, etc).
# run.sh checks for this marker after every phase and stops the batch.
request_reboot() {
  touch "${STATE_DIR}/REBOOT_REQUIRED"
  log_warn "This phase requires a reboot before continuing."
}
