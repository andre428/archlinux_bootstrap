# bootstrap

An idempotent, resumable post-install pipeline for Arch Linux — turns a fresh
`archinstall` (root + sudo user + NetworkManager, nothing else) into a
terminal-first Hyprland setup for development and gaming, in a repeatable
way on the same PC or a different one.

This repo only installs packages and enables system-level services. It
deliberately does not manage your `$HOME` config — two sibling repos handle
that:

| Repo | Owns | Tool |
|---|---|---|
| **bootstrap** (this repo) | phase scripts, package lists | plain bash |
| **config-archive** | system-level `/etc` files (greetd, sysctl, udev, systemd overrides) | plain `cp` |
| **dotfiles** | your actual `$HOME` configs (hypr, waybar, kitty, nvim) | **yadm** |

Nothing in this repo touches `$HOME`. Everything user-facing lives in
`dotfiles` and is pulled in by phase 11 via yadm.

---

## Running it

Always run as your normal sudo user — never as root (AUR builds refuse
root outright, and half this pipeline is meaningless run any other way).

```bash
./run.sh              # run everything in order, stopping at reboot checkpoints
./run.sh --list        # show phase completion state
./run.sh 05 06          # run specific phases only
./run.sh --from 04      # resume from a given phase onward
./run.sh --force 01     # rerun a phase even if marked done
```

**Reboot checkpoints are real, not just a note in this file.** Phases 01,
03, and 09 call `request_reboot` at the end. When `run.sh` sees that
marker, it stops the batch and tells you to reboot before continuing —
it will not silently barrel through a phase that needed a fresh boot
first. After rebooting, just run `./run.sh` again; completed phases are
skipped automatically via the state files in
`~/.local/state/bootstrap/`.

---

## Phase map

| # | Name | Reboot after? | Notes |
|---|---|---|---|
| 00 | Bootstrap | – | core CLI tools (git, curl, base-devel, ripgrep, etc.) |
| 01 | Pacman | **yes** | pacman.conf tuning, multilib, mirrors, `-Syyu` |
| 02 | AUR | – | installs `paru` |
| 03 | Fonts | – | Noto set + CJK/emoji, JetBrains Mono Nerd, IPA |
| 04 | Desktop | – | Hyprland + Wayland utils — must exist before phase 05 |
| 05 | Login | **yes** | greetd + tuigreet, configured to launch Hyprland (now installed). Test login before continuing. |
| 06 | Development | – | Python, Rust, Neovim, Kate |
| 07 | Applications | – | Firefox, Dolphin, yazi, mpv, Obsidian, Zathura |
| 08 | Gaming | – | AMD Vulkan stack, Steam, Lutris, Wine, MangoHud, Gamescope, GameMode |
| 09 | Kernel (bore) | **yes** | **optional** — `linux-cachyos-bore`, not run by default |
| 10 | Tuning | – | zram/sysctl/udev tunables borrowed from cachyos-settings |
| 11 | Dotfiles | – | yadm clone/pull of your `$HOME` configs |
| 12 | Verify | – | **read-only**, checks the whole system |

**Why login comes after desktop, not before:** phase 05's greetd config
points `tuigreet --cmd` at `Hyprland` directly. If login ran first,
rebooting to "test" it would authenticate fine but fail to launch a
session — Hyprland wouldn't be installed yet. Desktop has to land first
so the login checkpoint actually proves the whole chain, not just
greetd/PAM in isolation.

Phase 09 is intentionally excluded from a bare `./run.sh` — invoke it
explicitly with `./run.sh 09` if/when you want to try it. Everything else
runs in the default full sequence.

---

## Full walkthrough, fresh machine to finished desktop

### 1. Get the repos onto the box

```bash
sudo pacman -S --needed git
mkdir -p ~/projects && cd ~/projects
git clone https://github.com/yourname/bootstrap.git
git clone https://github.com/yourname/config-archive.git
```

`dotfiles` is not cloned by hand — yadm does that in phase 11.

### 2. Point bootstrap at your config-archive checkout (if not the default path)

```bash
export CONFIG_ARCHIVE="$HOME/projects/config-archive"
```
(Default in the scripts is already `$HOME/projects/config-archive` — only
needed if you put it somewhere else.)

### 3. Run it

```bash
cd ~/projects/bootstrap
./run.sh
```

### 4. It stops at phase 01 — reboot

```
>>> Reboot required. Reboot now, then run ./run.sh again
```
Reboot. Log back in to the TTY.

### 5. Continue — it runs phases 02–04 (AUR, fonts, desktop), then stops after phase 05

```bash
cd ~/projects/bootstrap
./run.sh
```
Phase 04 installs Hyprland and the Wayland utilities. Phase 05 installs
greetd/tuigreet, points it at the now-installed `Hyprland`, enables the
service, then asks for another reboot.

### 6. Reboot, and this time actually test the login chain

Confirm:
- tuigreet appears on tty1
- you can log in with your sudo user
- `Hyprland` launches (bare/unconfigured is fine — you're proving the
  chain works, not that it looks good yet)

If it fails here, don't panic and don't keep running phases — this is
the cheapest point to debug, since nothing downstream depends on much
yet. Check `journalctl -u greetd` and `journalctl --user -b` for errors.

### 7. Continue the rest of the sequence

```bash
cd ~/projects/bootstrap
./run.sh
```
This runs 06 through 08 (dev, apps, gaming) straight through — no
reboot needed for any of these, they're just package installs.

### 8. Tuning phase

```bash
./run.sh 10
```
Applies the borrowed zram/sysctl/udev tunables (see below for exactly
what these are). No reboot required, though a fresh session for the
zram swap to attach cleanly doesn't hurt.

### 9. Dotfiles

```bash
./run.sh 11
```
Clones your `dotfiles` repo via yadm directly into `$HOME` — your real
Hyprland/waybar/kitty/nvim configs land in their real locations. This is
the first point your desktop actually looks like *your* desktop instead
of package defaults.

### 10. Verify

```bash
./run.sh 12
```
Read-only sanity check — confirms Hyprland/greetd/NetworkManager/PipeWire
are all in the state you expect, checks `paru`, `nvim`, `kitty` are
reachable, and runs `vulkaninfo`/`glxinfo` to confirm the RX 6800 is
actually being picked up by Mesa. Safe to rerun any time, changes
nothing.

### 11. (Optional) try the CachyOS BORE kernel

```bash
./run.sh 09
```
This is deliberately never part of the default sequence — you opt in
explicitly. It adds only the `cachyos-v3`/`core-v3`/`extra-v3` repos
(not the `[cachyos]` repo that ships a forked pacman), installs
`linux-cachyos-bore` alongside your stock `linux` kernel, and asks for a
reboot to select it from the boot menu.

**Stock `linux` is never removed** — it's your fallback if anything
regresses. Select it from the same bootloader menu if the new kernel
misbehaves.

To roll back later:
```bash
sudo pacman -Rns linux-cachyos-bore linux-cachyos-bore-headers
# then remove the three [cachyos-*-v3] blocks from /etc/pacman.conf
sudo pacman -Sy
```

To update it going forward: nothing special, it's a normal pacman
package — `sudo pacman -Syu` picks it up like anything else.

---

## Day-to-day dotfiles workflow (yadm)

Once phase 11 has run, yadm behaves like plain git pointed at your real
`$HOME` — no staging directory, no render step, no symlinks.

**Editing an already-tracked file:**
```bash
# just edit the real file, e.g. ~/.config/hypr/hyprland.conf
yadm status
yadm commit -am "tweak hyprland config"
yadm push
```

**Tracking a config you've never tracked before:** add the path to
`yadm-track.sh` (lives in the `dotfiles` repo, not this one) and run it:
```bash
./yadm-track.sh
yadm commit -m "track new config"
yadm push
```

**On a brand-new machine:** this is exactly phase 11 —
```bash
sudo pacman -S --needed yadm
yadm clone https://github.com/yourname/dotfiles.git
```

---

## What phase 10 (tuning) actually applies, and why

Borrowed from CachyOS's `cachyos-settings` package — but as plain config
files copied from `config-archive`, not as a dependency on their repo or
package. Applied from `config-archive/etc/...`:

- `systemd/zram-generator.conf` — zstd-compressed ZRAM swap
- `sysctl.d/99-zram-tuning.conf` — `vm.swappiness=150`, tuned for ZRAM
  specifically (this value only makes sense with fast ZRAM swap backing
  it — don't carry it over to a disk-swap system)
- `udev/rules.d/60-ioschedulers.rules` — bfq for spinning disks,
  mq-deadline for SATA SSDs, none for NVMe
- `systemd/system.conf.d/timeouts.conf` — shorter start/stop timeouts
- `systemd/journald.conf.d/size-cap.conf` — caps journal size at 50M

None of this depends on the CachyOS repos being reachable or trusted
long-term — it's just settings, sourced once, kept in your own repo.

---

## Conventions

- Package lists are plain text under `packages/`, one name per line,
  `#` for comments. Edit those, not the bash logic in `phases/`.
- Every phase checks current state before acting — safe to rerun the
  whole pipeline on a half-finished install (`FORCE=1` to force a
  specific phase to redo its work regardless).
- AUR installs (`install_aur`, `install_aur_from_list` in
  `lib/common.sh`) always run as the normal user; pacman/systemctl calls
  go through `sudo` internally.
- A phase that needs a reboot calls `request_reboot` at the end — this
  is a real mechanism (`run.sh` checks for the marker and stops), not
  just documentation.
- `phases/12-verify.sh` never installs or modifies anything.
