#!/usr/bin/env bash
# Read-only. Never installs or modifies anything.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./lib/common.sh

PASS=0; FAIL=0

check() {
  local desc="$1"; shift
  if "$@" &>/dev/null; then log_ok "$desc"; ((PASS++))
  else log_err "$desc"; ((FAIL++)); fi
}

check_output_contains() {
  local desc="$1" pattern="$2"; shift 2
  local out; out="$("$@" 2>&1)" || true
  if echo "$out" | grep -qi "$pattern"; then log_ok "$desc"; ((PASS++))
  else log_err "$desc"; ((FAIL++)); fi
}

echo "== Core system =="
check "Hyprland installed"      pacman -Qi hyprland
check "greetd installed"        pacman -Qi greetd
check "greetd.service enabled"  systemctl is-enabled greetd
check "NetworkManager enabled"  systemctl is-enabled NetworkManager
check "NetworkManager running"  systemctl is-active NetworkManager
check "paru available"          command -v paru
check "nvim available"          command -v nvim
check "kitty available"         command -v kitty

echo; echo "== PipeWire (user session) =="
check "pipewire active"         systemctl --user is-active pipewire
check "pipewire-pulse active"   systemctl --user is-active pipewire-pulse
check "wireplumber active"      systemctl --user is-active wireplumber

echo; echo "== Graphics — RX 6800 / Mesa =="
if command -v vulkaninfo &>/dev/null; then
  check_output_contains "vulkaninfo reports an AMD device" "AMD" vulkaninfo --summary
else
  log_warn "vulkaninfo missing (pacman -S vulkan-tools) — skipped"
fi
if command -v glxinfo &>/dev/null; then
  check_output_contains "glxinfo reports Mesa" "Mesa" glxinfo
else
  log_warn "glxinfo missing (pacman -S mesa-utils) — skipped"
fi

echo; echo "== Versions (informational) =="
command -v nvim  &>/dev/null && nvim --version | head -n1
command -v kitty &>/dev/null && kitty --version

echo; echo "== systemd --user running services =="
systemctl --user list-units --type=service --state=running --no-pager || true

echo
echo "== Summary: ${PASS} passed, ${FAIL} failed =="
[[ $FAIL -eq 0 ]]
