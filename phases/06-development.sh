#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./lib/common.sh

PHASE="06-development"
skip_if_done "$PHASE"
require_sudo

log_info "Phase 06-development: Development toolchain"

install_pacman_from_list packages/06-development.list

mark_done "$PHASE"
log_ok "Phase 06-development complete."
