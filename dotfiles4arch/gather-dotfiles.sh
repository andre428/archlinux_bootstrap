#!/usr/bin/env bash
# gather-dotfiles.sh — stage new/changed dotfiles for yadm.
# Safe to re-run: existing tracked files just restage if changed, no-ops if not.
set -uo pipefail   # deliberately no -e: one missing path shouldn't kill the batch

command -v yadm &>/dev/null || { echo "yadm not installed." >&2; exit 1; }
yadm status &>/dev/null || { echo "No yadm repo yet — run 'yadm init' or 'yadm clone <url>' first." >&2; exit 1; }

FILES=(
  "$HOME/.config/godot"
  "$HOME/.config/hypr"
  "$HOME/.config/waybar"
  "$HOME/.config/kitty"
  "$HOME/.config/nvim"
  "$HOME/.config/oxicord"
  "$HOME/.config/shell"
  "$HOME/.config/mako/config"
  "$HOME/.config/mpv"
  "$HOME/.config/zathura"
  "$HOME/.bashrc"
  "$HOME/.gitconfig"
  "$HOME/.config/mimeapps.list"
  "$HOME/.local/bin/power-menu.sh"
  "$HOME/.local/bin/restart-desktop.sh"
)

added=(); missing=()

for f in "${FILES[@]}"; do
  if [[ -e "$f" ]]; then
    yadm add "$f" && added+=("$f")
  else
    missing+=("$f")
  fi
done

echo; echo "== Staged (${#added[@]}) =="
printf '  %s\n' "${added[@]}"

if [[ ${#missing[@]} -gt 0 ]]; then
  echo; echo "== Skipped, path not found (${#missing[@]}) =="
  printf '  %s\n' "${missing[@]}"
fi

echo; yadm status
echo; echo "Review above, then: yadm commit -m '...' && yadm push"
