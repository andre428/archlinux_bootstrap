#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./lib/common.sh

PHASE="05-login"
skip_if_done "$PHASE"
require_sudo

CONFIG_ARCHIVE="${CONFIG_ARCHIVE:-$HOME/bootstrap/config-archive}"

log_info "Phase 05: greetd + tuigreet"

install_pacman_from_list packages/05-login.list

sudo mkdir -p /etc/greetd
sudo cp "${CONFIG_ARCHIVE}/etc/greetd/config.toml" /etc/greetd/config.toml
service_enable_now greetd.service

mark_done "$PHASE"
request_reboot
log_ok "Phase 05 complete. After reboot: confirm tuigreet appears, log in, confirm Hyprland launches (bare/unconfigured is fine at this point)."
