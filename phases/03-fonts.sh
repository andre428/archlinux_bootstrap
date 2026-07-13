#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./lib/common.sh

PHASE="03-fonts"
skip_if_done "$PHASE"
require_sudo

log_info "Phase 03: Fonts (Noto + JetBrains Mono Nerd + Japanese)"

install_pacman_from_list packages/03-fonts.list

mark_done "$PHASE"
log_ok "Phase 03 complete."
