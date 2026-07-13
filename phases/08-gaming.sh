#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./lib/common.sh

PHASE="08-gaming"
skip_if_done "$PHASE"
require_sudo

log_info "Phase 08-gaming: Gaming (AMD stack, Steam, Lutris, Wine, GameMode)"

install_pacman_from_list packages/08-gaming.list

mark_done "$PHASE"
log_ok "Phase 08-gaming complete."
