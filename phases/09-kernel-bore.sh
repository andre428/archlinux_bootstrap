#!/usr/bin/env bash
# OPTIONAL. Not part of the default ./run.sh sequence unless you invoke it
# explicitly: ./run.sh 09
#
# Adds only the cachyos-v3/core-v3/extra-v3 repos (skips the [cachyos] repo
# that ships the forked pacman) and installs linux-cachyos-bore alongside
# your stock `linux` kernel. Stock linux is never removed — it's your
# permanent fallback in the bootloader menu.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./lib/common.sh

PHASE="09-kernel-bore"
skip_if_done "$PHASE"
require_sudo

if ! grep -q '^\[cachyos-v3\]' /etc/pacman.conf; then
  log_info "Registering CachyOS v3 keyring + mirrorlist + repos..."
  tmpdir="$(mktemp -d)"; trap 'rm -rf "$tmpdir"' EXIT
  cd "$tmpdir"
  curl -sO https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-keyring-any.pkg.tar.zst || true
  curl -sO https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-v3-mirrorlist-any.pkg.tar.zst || true
  log_warn "Fetch the exact current package filenames from"
  log_warn "https://mirror.cachyos.org/repo/x86_64/cachyos/ and adjust the URLs above —"
  log_warn "version strings change and this script does not pin them."
  sudo pacman -U --noconfirm ./cachyos-keyring-*.pkg.tar.zst ./cachyos-v3-mirrorlist-*.pkg.tar.zst
  cd - >/dev/null

  sudo tee -a /etc/pacman.conf >/dev/null <<'EOF'

[cachyos-v3]
Include = /etc/pacman.d/cachyos-v3-mirrorlist

[cachyos-core-v3]
Include = /etc/pacman.d/cachyos-v3-mirrorlist

[cachyos-extra-v3]
Include = /etc/pacman.d/cachyos-v3-mirrorlist
EOF
  sudo pacman -Sy
fi

install_pacman linux-cachyos-bore linux-cachyos-bore-headers

mark_done "$PHASE"
request_reboot
log_ok "Phase 09 complete. Select linux-cachyos-bore from the boot menu after reboot."
log_ok "Stock 'linux' kernel is still installed — pick it from the same menu if anything regresses."
