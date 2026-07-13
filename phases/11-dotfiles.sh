#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./lib/common.sh

PHASE="11-dotfiles"
skip_if_done "$PHASE"
require_sudo

DOTFILES_URL="${DOTFILES_URL:-https://github.com/yourname/dotfiles.git}"

log_info "Phase 11: dotfiles (yadm)"

install_pacman yadm

if [[ -d "${HOME}/.local/share/yadm/repo.git" ]]; then
  log_ok "yadm repo already present, pulling latest."
  yadm pull
else
  yadm clone "$DOTFILES_URL"
fi

mark_done "$PHASE"
log_ok "Phase 11 complete."
