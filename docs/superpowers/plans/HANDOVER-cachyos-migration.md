# CachyOS Migration Handover

## How to use this

Paste this entire file into a new Claude Code session. It contains everything Claude needs to assist you through the full NixOS → CachyOS migration from wherever you are in the process.

---

## Who you are

User: **gl00m** (UID=1000, GID=100/users)
Machine: ASUS laptop
Home dir: `/home/gl00m`
Dotfiles repo: `~/dotfiles` (git repo, pushed to remote)
Previous OS: NixOS 26.05 (nixos-unstable flake)
Target OS: CachyOS (Arch-based)

---

## Hardware

- Intel CPU with NPU (`hardware.cpu.intel.npu.enable = true`)
- Intel Arc integrated GPU — uses iHD VA-API driver (`LIBVA_DRIVER_NAME=iHD`)
- Bluetooth adapter
- ASUS-specific hardware: keyboard backlight (`asus::kbd_backlight`), fan control, power profiles
- 2880x1800 @ 120Hz HiDPI display (eDP-1, scale factor 2)
- External monitor: HDMI-A-1 (1920x1080@60, mirrors eDP-1 when connected)

---

## Disk Layout (single NVMe: nvme0n1, 953.9G total)

```
nvme0n1p1   1G    vfat   SYSTEM   → EFI System Partition (shared Windows+Linux)
nvme0n1p2  16M    (none)          → Windows MSR — DO NOT TOUCH
nvme0n1p3 509G    ntfs   OS       → Windows C: drive — DO NOT TOUCH
nvme0n1p4   1.3G  ntfs            → Windows recovery — DO NOT TOUCH
nvme0n1p5  20G    ntfs   RESTORE  → ASUS factory restore — DO NOT TOUCH
nvme0n1p6 260M    vfat   MYASUS   → ASUS tools — DO NOT TOUCH
nvme0n1p7  50G    ext4            → WAS NixOS / root → CachyOS installs here
nvme0n1p8 372G    ext4            → /home (SEPARATE PARTITION — SURVIVES WIPE)
```

**Critical fact:** /home is its own partition (nvme0n1p8). It is NOT part of the NixOS root. When CachyOS installs over nvme0n1p7, /home is completely untouched. All of gl00m's files, configs, SSH keys, Steam games, browser profiles, and the dotfiles repo survive automatically.

---

## What was on NixOS (needs to be reinstalled on CachyOS)

### Desktop
- Hyprland (WM) + xwayland
- Caelestia shell — custom quickshell-based desktop shell, built from source at `~/dotfiles/caelestia/` using CMake + clang. This is the most complex part of the reinstall.
- caelestia-cli — separate Rust binary from `github:caelestia-dots/cli`
- lxqt-policykit-agent (polkit)
- nm-applet (network tray)

### Audio
- pipewire + pipewire-alsa + pipewire-pulse + wireplumber
- pavucontrol, qpwgraph, pamixer, alsa-utils

### System tools
- networkmanager + networkmanager-openvpn
- bluez + blueman
- upower + power-profiles-daemon
- asusctl (ASUS fan/LED/power control) — AUR
- supergfxctl (ASUS GPU switching) — AUR
- Thunar + thunar-archive-plugin + thunar-volman + gvfs + tumbler
- xdg-desktop-portal-hyprland + xdg-desktop-portal-gtk
- steam + gamemode + gamescope + mangohud + protonup-qt
- AppImage support (fuse2 / appimagelauncher)
- docker (gl00m was in docker group)

### GUI Apps
- kitty (terminal)
- zen-browser (AUR: zen-browser-bin) — Firefox-based, Brave Sync is on for Brave, Zen uses Firefox Sync
- brave-browser
- telegram-desktop
- vesktop (AUR) — Discord client
- mpv, imv

### CLI Tools
- eza, bat, ripgrep, fd, fzf, zoxide, starship
- wl-clipboard, grim, slurp, cliphist, wofi
- brightnessctl, playerctl
- git + delta + github-cli (gh)
- jq, neovim, btop, nvtop
- blueman

### AI/Dev Tools
- claude-code (npm: `@anthropic-ai/claude-code`)
- codex (npm: `@openai/codex`)

### Fonts
- Inter, Noto (sans/serif/CJK/emoji), JetBrains Mono Nerd, FiraCode Nerd, Meslo Nerd, Symbols-only Nerd, CaskaydiaCove Nerd, Material Symbols, Rubik

### Theme/Icons/Cursors
- catppuccin-gtk-theme-mocha (mauve accent, standard, rimless)
- papirus-icon-theme
- catppuccin-cursors-mocha (mocha dark, size 24)

### Spicetify
- spotify + spicetify-cli — for theming Spotify, config at `~/.config/spicetify/`

---

## What survives on /home (no action needed)

Everything in `/home/gl00m/`:
- `~/dotfiles/` — entire config repo with all configs
- `~/.ssh/id_ed25519` + `.pub` — SSH keys intact
- `~/.gnupg/` — GPG keyring intact
- `~/.config/` — all app configs: hypr, kitty, nvim, caelestia, zen, brave, btop, starship.toml, etc.
- `~/.local/share/Steam/` — all Steam games (61G total in ~/.local)
- `~/.local/share/` — all app data
- `~/.claude/` + `~/.claude.json` — Claude Code config and memory
- `~/.bashrc`, `~/.bash_history` — shell config and history
- `~/.cache/` — 6.3G, can be deleted or kept
- Browser profiles (Brave, Zen) with all history/extensions/passwords

**What does NOT survive (lives on the root partition that gets wiped):**
- `/etc/NetworkManager/system-connections/` — **Wi-Fi passwords are LOST, must re-enter**
- `/etc/asusd/` — ASUS power/LED profiles
- All system packages
- All systemd unit files in /etc/systemd/
- Nix store (`/nix/`) — gone entirely, good

---

## Current state of ~/.bashrc

home-manager wrote the shell config to `~/.bashrc`. Some lines reference Nix store paths like:
```bash
eval "$(/nix/store/HASH-zoxide-VERSION/bin/zoxide init bash)"
eval "$(/nix/store/HASH-fzf-VERSION/bin/fzf --bash)"
```
These paths break after the Nix store is gone. Early in post-install, these lines need to be replaced with:
```bash
eval "$(zoxide init bash)"
eval "$(fzf --bash)"
```

---

## Hyprland config symlinks

home-manager created these symlinks (they still exist in ~/.config/hypr/ on /home):
```
~/.config/hypr/hyprland.conf      → ~/dotfiles/config/hypr/hyprland.conf
~/.config/hypr/view-logs.sh       → ~/dotfiles/config/hypr/scripts/view-logs.sh
~/.config/hypr/screenshot.sh      → ~/dotfiles/config/hypr/scripts/screenshot.sh
~/.config/hypr/kbd-backlight.sh   → ~/dotfiles/config/hypr/scripts/kbd-backlight.sh
~/.config/hypr/brightness.sh      → ~/dotfiles/config/hypr/scripts/brightness.sh
~/.config/hypr/space-action.sh    → ~/dotfiles/config/hypr/scripts/space-action.sh
```
These symlinks already exist in /home and should still be valid. Just verify they resolve after CachyOS is installed.

---

## Caelestia shell build details

Caelestia is a custom shell built on quickshell. Source is at `~/dotfiles/caelestia/`. The NixOS flake built it with clangStdenv. On CachyOS:

**Dependencies:**
- quickshell (from CachyOS repo or AUR: `quickshell-git`)
- cmake, clang, ninja
- Qt6: qt6-base, qt6-declarative, qt6-wayland, qt6-svg, qt6-imageformats

**Build:**
```bash
cd ~/dotfiles/caelestia
cmake -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DVERSION=local \
  -DGIT_REVISION=$(git rev-parse HEAD)
cmake --build build --parallel $(nproc)
sudo cmake --install build
```

**Caelestia config setup** (home-manager did this, now must be done manually):
```bash
config_dir="$HOME/.config/caelestia"
[ -L "$config_dir" ] && rm "$config_dir"
mkdir -p "$config_dir"
cp -RL ~/dotfiles/config/caelestia/. "$config_dir/"
mkdir -p "$config_dir/monitors"
chmod -R u+w "$config_dir"
```

**caelestia-cli:** Rust binary from `github:caelestia-dots/cli`. Build with:
```bash
sudo pacman -S rustup && rustup default stable
git clone https://github.com/caelestia-dots/cli /tmp/caelestia-cli
cd /tmp/caelestia-cli && cargo build --release
sudo install -m755 target/release/caelestia-cli /usr/local/bin/caelestia
```

---

## System services that need manual recreation

### 1. Power profile stay-on-balanced (prevents display stutter)
`/etc/systemd/system/power-profile-balanced.service`
```ini
[Unit]
Description=Set balanced power profile
After=dbus.service power-profiles-daemon.service
Wants=power-profiles-daemon.service

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'for i in $(seq 1 20); do powerprofilesctl list >/dev/null 2>&1 && exec powerprofilesctl set balanced; sleep 0.5; done; powerprofilesctl set balanced'

[Install]
WantedBy=graphical.target
```
`sudo systemctl enable --now power-profile-balanced.service`

### 2. Lid switch suspend
`/etc/systemd/logind.conf.d/lid.conf`
```ini
[Login]
HandleLidSwitch=suspend
HandleLidSwitchExternalPower=suspend
HandleLidSwitchDocked=ignore
```

### 3. Backlight udev rules
`/etc/udev/rules.d/90-backlight.rules`
```
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", RUN+="/usr/bin/chgrp video /sys%p/brightness", RUN+="/usr/bin/chmod g+w /sys%p/brightness"
ACTION=="add", SUBSYSTEM=="leds", KERNEL=="asus::kbd_backlight", RUN+="/usr/bin/chgrp video /sys%p/brightness", RUN+="/usr/bin/chmod g+w /sys%p/brightness"
```

### 4. Kernel parameter (brightness keys → Hyprland)
Edit `/etc/default/grub`, add to GRUB_CMDLINE_LINUX_DEFAULT:
```
video.brightness_switch_enabled=0
```
Then: `sudo grub-mkconfig -o /boot/grub/grub.cfg`

### 5. Intel VA-API
`/etc/environment`:
```
LIBVA_DRIVER_NAME=iHD
MOZ_ENABLE_WAYLAND=1
```

### 6. i2c for external monitor brightness (caelestia uses ddcutil)
```bash
echo "i2c-dev" | sudo tee /etc/modules-load.d/i2c.conf
echo 'KERNEL=="i2c-[0-9]*", GROUP="video", MODE="0660"' | sudo tee /etc/udev/rules.d/45-ddcutil-i2c.conf
sudo usermod -aG i2c gl00m 2>/dev/null || true
sudo udevadm control --reload-rules && sudo udevadm trigger
```

---

## Git config (needs to be set post-install)

```bash
git config --global user.name "gl00mt1t4n"
git config --global user.email "gloomtitan1337@gmail.com"
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global core.editor nvim
git config --global push.autoSetupRemote true
git config --global delta.navigate true
git config --global "delta.side-by-side" true
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
```

---

## The migration phases — where you are

### PHASE 1: Pre-flight (NixOS, before USB boot)
- [ ] `cd ~/dotfiles && git status` — nothing uncommitted
- [ ] `git push` — remote is up to date
- [ ] Note your Wi-Fi passwords — they will be lost
- [ ] Note ASUS power profile: `asusctl profile -l`
- [ ] SSH keys are in ~/.ssh/ — no action needed (survives on /home)

### PHASE 2: Create bootable USB
- Download: **CachyOS GUI Installer (KDE edition)** from cachyos.org
- Write to USB: `sudo dd if=cachyos-*.iso of=/dev/sdX bs=4M status=progress oflag=sync`
  - Or: Rufus on Windows in **DD mode** (not ISO mode)
  - Or: Balena Etcher

### PHASE 3: Install CachyOS (YOU ARE ALONE HERE — NO CLAUDE)
Boot from USB (ASUS: tap F2 at POST to get boot menu).

In calamares installer:
1. Language/timezone: en_US, America/New_York
2. Desktop selection: **Hyprland**
3. **MANUAL PARTITIONING** — do not use auto:

| Partition  | Action             | Mount Point | Format? |
|------------|--------------------|-------------|---------|
| nvme0n1p1  | Mount only         | /boot/efi   | **NO**  |
| nvme0n1p7  | Format as ext4     | /           | YES     |
| nvme0n1p8  | Mount only         | /home       | **NO**  |

4. User: `gl00m`, password of your choice
5. Bootloader: **GRUB** (leave default) — auto-detects Windows
6. Review — confirm NO format on p1 and p8 — Install
7. Reboot, remove USB
8. GRUB shows CachyOS + Windows
9. Boot Windows to verify it works, then back to CachyOS

### PHASE 4: First boot — update and paru
```bash
sudo pacman -Syu
# If kernel updated, reboot first

sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/paru.git /tmp/paru
cd /tmp/paru && makepkg -si
cd ~
```

### PHASE 5: Install all packages
See the "What was on NixOS" section above. Install in this order:
1. System tools (pipewire, networkmanager, bluez, upower, thunar, xdg-portals)
2. CLI tools (eza, bat, ripgrep, fd, fzf, zoxide, starship, wl-clipboard, grim, etc.)
3. Fonts
4. Theme/icons/cursors (paru)
5. Hyprland ecosystem (verify from desktop install, supplement if needed)
6. GUI apps (kitty, brave, zen-browser-bin via paru, vesktop via paru, telegram, etc.)
7. Gaming (steam, gamemode, gamescope, mangohud, protonup-qt via paru)
8. ASUS tools (paru -S asusctl supergfxctl)
9. Intel GPU (intel-media-driver, onevpl-intel-gpu, intel-compute-runtime, vulkan-intel)
10. AI tools (claude-code, codex via npm)

### PHASE 6: Dotfiles and shell cleanup
1. Verify hyprland symlinks in ~/.config/hypr/ still resolve
2. Fix ~/.bashrc nix store paths (replace `/nix/store/.../zoxide` with `zoxide`, same for fzf)
3. Verify git config (`git config --global user.name`)
4. Set up caelestia config (see caelestia section above)

### PHASE 7: Build caelestia shell
See caelestia build details section above. This is the hardest part.

### PHASE 8: System services
Re-create all 6 services/configs listed in "System services that need manual recreation" above.

### PHASE 9: Remaining apps
- spicetify: `paru -S spicetify-cli && spicetify apply`
- nvim: open nvim, let plugins auto-install
- Steam: launch, sign in, games already in ~/.local/share/Steam

### PHASE 10: Verify everything
- Hyprland starts
- Caelestia bar appears
- Brightness keys work
- Audio works
- Bluetooth works
- ASUS tools work (`asusctl profile -l`)
- VA-API: `vainfo` shows iHD driver
- Steam + games work
- Windows dual-boot works

---

## Full plan document
The complete detailed plan (with exact commands per step) is saved at:
`~/dotfiles/docs/superpowers/plans/2026-07-25-nixos-to-cachyos-migration.md`

Read that file for the full step-by-step with exact commands. This handover is the summary Claude needs to assist you through it.

---

## How to continue with Claude

At any point after CachyOS is installed:
1. Install Claude Code: `npm install -g @anthropic-ai/claude-code`
2. Run: `claude`
3. Paste this entire document into the first message
4. Tell Claude which phase you're on and what just happened
5. Claude will pick up from there with full context

The detailed plan is also at `~/dotfiles/docs/superpowers/plans/2026-07-25-nixos-to-cachyos-migration.md` — Claude can read that file directly once you're in CachyOS.
