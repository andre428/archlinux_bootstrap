#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./lib/common.sh

PHASE="00-bootstrap"
skip_if_done "$PHASE"
require_sudo

log_info "Phase 00: core bootstrap tools"

install_pacman_from_list packages/00-bootstrap.list

mark_done "$PHASE"
log_ok "Phase 00 complete."
