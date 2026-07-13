#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./lib/common.sh

PHASE="02-aur"
skip_if_done "$PHASE"
require_user   # must NOT be root — makepkg refuses

log_info "Phase 02: AUR helper (paru)"

if command -v paru &>/dev/null; then
  log_ok "paru already installed."
else
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT
  # paru-bin = prebuilt binary, much faster on a fresh box than compiling
  # paru     = build from source, if you'd rather compile it yourself
  git clone https://aur.archlinux.org/paru-bin.git "$tmpdir/paru-bin"
  (cd "$tmpdir/paru-bin" && makepkg -si --noconfirm)
fi

mark_done "$PHASE"
log_ok "Phase 02 complete."
