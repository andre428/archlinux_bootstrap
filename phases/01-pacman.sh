#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./lib/common.sh

PHASE="01-pacman"
skip_if_done "$PHASE"
require_sudo

CONF=/etc/pacman.conf
BACKUP=/etc/pacman.conf.bak.bootstrap

log_info "Phase 01: pacman.conf + mirrors + multilib + full upgrade"

[[ -f "$BACKUP" ]] || sudo cp "$CONF" "$BACKUP"

sudo sed -i \
  -e 's/^#Color/Color/' \
  -e 's/^#VerbosePkgLists/VerbosePkgLists/' \
  -e 's/^#CheckSpace/CheckSpace/' \
  -e 's/^#ParallelDownloads.*/ParallelDownloads = 3/' \
  "$CONF"

grep -q '^Color'             "$CONF" || echo "Color"                              | sudo tee -a "$CONF" >/dev/null
grep -q '^CheckSpace'        "$CONF" || echo "CheckSpace"                         | sudo tee -a "$CONF" >/dev/null
grep -q '^VerbosePkgLists'   "$CONF" || echo "VerbosePkgLists"                    | sudo tee -a "$CONF" >/dev/null
grep -q '^ParallelDownloads' "$CONF" || echo "ParallelDownloads = 3"              | sudo tee -a "$CONF" >/dev/null
grep -q '^HookDir'           "$CONF" || echo "HookDir     = /etc/pacman.d/hooks/" | sudo tee -a "$CONF" >/dev/null
sudo mkdir -p /etc/pacman.d/hooks

# Enable [multilib] block (uncomment the section header + its Include line)
sudo sed -i '/^\[multilib\]/,/^Include/ s/^#//' "$CONF"

log_info "Refreshing mirrorlist with reflector (adjust --country to taste)..."
sudo reflector \
  --country 'PL,DE,NL' \
  --age 12 \
  --protocol https \
  --sort rate \
  --save /etc/pacman.d/mirrorlist

log_info "Running pacman -Syyu..."
sudo pacman -Syyu --noconfirm

mark_done "$PHASE"
request_reboot
log_ok "Phase 01 complete."
