#!/usr/bin/env bash
# OPTIONAL. Not part of the default ./run.sh sequence unless you invoke it
# explicitly: ./run.sh 09
#
# Adds only the cachyos-v3/core-v3/extra-v3 repos (skips the [cachyos] repo
# that ships the forked pacman) and installs linux-cachyos-bore alongside
# your stock `linux` kernel. Stock linux is never removed — it's your
# permanent fallback in the bootloader menu.
#
# Verify the current package/version before relying on this script:
# https://packages.cachyos.org/ (search linux-cachyos-bore)
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./lib/common.sh

PHASE="09-kernel-bore"
skip_if_done "$PHASE"
require_sudo

CACHYOS_KEY="F3B607488DB35A47"
CACHYOS_MIRROR="https://mirror.cachyos.org/repo/x86_64/cachyos"

if ! grep -q '^\[cachyos-v3\]' /etc/pacman.conf; then
  log_info "Trusting the CachyOS signing key..."
  sudo pacman-key --recv-keys "$CACHYOS_KEY" --keyserver keyserver.ubuntu.com
  sudo pacman-key --lsign-key "$CACHYOS_KEY"

  log_info "Looking up current keyring + v3-mirrorlist package filenames..."
  tmpdir="$(mktemp -d)"; trap 'rm -rf "$tmpdir"' EXIT
  cd "$tmpdir"

  listing="$(curl -sL "${CACHYOS_MIRROR}/")"
  keyring_file="$(grep -oE 'cachyos-keyring-[^"]+\.pkg\.tar\.zst' <<< "$listing" | head -n1)"
  mirrorlist_file="$(grep -oE 'cachyos-v3-mirrorlist-[^"]+\.pkg\.tar\.zst' <<< "$listing" | head -n1)"

  if [[ -z "$keyring_file" || -z "$mirrorlist_file" ]]; then
    log_err "Could not find current keyring/mirrorlist filenames at ${CACHYOS_MIRROR}/"
    log_err "Check the URL manually and adjust this script if the mirror layout changed."
    exit 1
  fi

  log_info "Fetching ${keyring_file} and ${mirrorlist_file}..."
  curl -sO "${CACHYOS_MIRROR}/${keyring_file}"
  curl -sO "${CACHYOS_MIRROR}/${mirrorlist_file}"
  sudo pacman -U --noconfirm "./${keyring_file}" "./${mirrorlist_file}"
  cd - >/dev/null

  log_info "Registering cachyos-v3 / core-v3 / extra-v3 repos (not [cachyos] itself)..."
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
