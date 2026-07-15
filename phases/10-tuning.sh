#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./lib/common.sh
PHASE="10-tuning"
skip_if_done "$PHASE"
require_sudo

CONFIG_ARCHIVE="${CONFIG_ARCHIVE:-$HOME/archlinux_bootstrap/config-archive}"

log_info "Phase 10: system tuning (zram, sysctl, udev I/O schedulers)"
install_pacman zram-generator

sudo mkdir -p /etc/systemd/system.conf.d /etc/systemd/journald.conf.d

# Copies a config into place and stamps it with a marker comment (idempotent —
# safe to re-run; won't double-stamp a file that already has it).
deploy_managed_conf() {
    local src="$1" dest="$2"
    sudo cp "$src" "$dest"
    local marker="# managed-by-bootstrap — source: ${src}, do not edit in place"
    grep -qF "$marker" "$dest" 2>/dev/null || sudo sed -i "1i ${marker}" "$dest"
}

deploy_managed_conf "${CONFIG_ARCHIVE}/etc/systemd/zram-generator.conf"           /etc/systemd/zram-generator.conf
deploy_managed_conf "${CONFIG_ARCHIVE}/etc/systemd/system.conf.d/timeouts.conf"   /etc/systemd/system.conf.d/timeouts.conf
deploy_managed_conf "${CONFIG_ARCHIVE}/etc/systemd/journald.conf.d/size-cap.conf" /etc/systemd/journald.conf.d/size-cap.conf
deploy_managed_conf "${CONFIG_ARCHIVE}/etc/sysctl.d/99-zram-tuning.conf"          /etc/sysctl.d/99-zram-tuning.conf
deploy_managed_conf "${CONFIG_ARCHIVE}/etc/udev/rules.d/60-ioschedulers.rules"    /etc/udev/rules.d/60-ioschedulers.rules
deploy_managed_conf "${CONFIG_ARCHIVE}/etc/pacman.d/hooks/clean_cache.hook"       /etc/pacman.d/hooks/clean_cache.hook

sudo sysctl --system
sudo udevadm control --reload
sudo systemctl daemon-reexec
sudo systemctl restart systemd-journald
sudo systemctl restart systemd-zram-setup@zram0.service 2>/dev/null || true
sudo systemctl enable --now fstrim.timer

mark_done "$PHASE"
log_ok "Phase 10 complete."
