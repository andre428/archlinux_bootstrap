#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./lib/common.sh

PHASE="07-applications"
skip_if_done "$PHASE"
require_sudo

log_info "Phase 07-applications: Everyday applications"

install_pacman_from_list packages/07-applications.list
install_aur downgrade

mark_done "$PHASE"
log_ok "Phase 07-applications complete."
