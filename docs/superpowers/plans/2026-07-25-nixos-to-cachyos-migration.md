# NixOS → CachyOS Migration Plan

> **This is a system migration plan, not a software development plan. Steps are sequential and must be executed in order. Each phase has a verification gate before moving on.**

**Goal:** Replace the NixOS root partition with CachyOS while preserving the separate /home partition, Windows dual-boot, and the existing dotfiles-based configuration.

**Architecture:** The /home partition (nvme0n1p8, 372G) is physically separate from the NixOS root (nvme0n1p7, 50G), so it survives the reinstall untouched. The EFI partition (nvme0n1p1, 1G) is shared with Windows and must not be formatted — the CachyOS installer will add GRUB entries alongside the existing Windows entries. Post-install, apps are restored by running install commands that mirror what the Nix flake was declaring, then pointing configs at the existing dotfiles.

**Tech Stack:** CachyOS (Arch-based), pacman + paru (AUR), Hyprland, quickshell, caelestia-shell (CMake build from ~/dotfiles/caelestia), systemd, pipewire.

## Global Constraints

- nvme0n1p1 (EFI, 1G, label SYSTEM): mount as /boot/efi — NEVER format or wipe
- nvme0n1p8 (/home, 372G, ext4): mount as /home — NEVER format or wipe
- nvme0n1p7 (root, 50G, ext4): format and install CachyOS here
- User gl00m must be created with UID=1000, GID=100 (users) — matches existing /home ownership
- nvme0n1p3/p4/p5/p6 are all Windows — do not touch

---

## Phase 1: Pre-Flight — Back Up Critical State

Do this while still on NixOS, before rebooting to the USB.

### Task 1.1: Verify dotfiles are pushed

- [ ] Run `cd ~/dotfiles && git status` — confirm nothing uncommitted
- [ ] Run `git push` — confirm remote is up to date
- [ ] If there are uncommitted changes: `git add -A && git commit -m "pre-migration snapshot" && git push`

### Task 1.2: Verify SSH keys exist in /home

- [ ] Run `ls -la ~/.ssh/` — confirm `id_ed25519` and `id_ed25519.pub` exist
- [ ] Run `ssh-add -l` or `ssh -T git@github.com` to confirm the key works

### Task 1.3: Check Zen sync status

Zen is Firefox-based. If you use Firefox Sync, your tabs/passwords/bookmarks sync to the cloud and will be restored when you log into Zen on CachyOS. If you don't use sync, your Zen profile is at `~/.config/zen/` which lives on /home and survives untouched.

- [ ] Open Zen, confirm sync is active (Settings → Sync), OR confirm you're OK relying on the profile in /home

### Task 1.4: Note your current ASUS fan/power profiles

asusctl stores profiles in `/etc/asusd/`. These will be lost when the root partition is wiped. Note your preferred power profile.

- [ ] Run `asusctl profile -l` — note current profile
- [ ] Run `asusctl led-mode -l` — note keyboard LED settings if you care about them

### Task 1.5: Snapshot GPG trust db (optional)

Your GPG keyring is at `~/.gnupg/` on the /home partition and survives automatically. This step is just for confidence.

- [ ] Run `gpg --list-keys` — confirm keys are visible
- [ ] Skip export — the keyring is already on /home

---

## Phase 2: Download CachyOS and Create Bootable USB

Do this from another machine, from Windows, or from NixOS before shutting down.

### Task 2.1: Download CachyOS ISO

- [ ] Go to cachyos.org → Download
- [ ] Choose **CachyOS GUI Installer (KDE)** — it bundles calamares and lets you select a desktop during install. You will pick **Hyprland** as the desktop group.
- [ ] Verify the SHA256 checksum listed on the download page against the downloaded file:
  ```
  sha256sum cachyos-*.iso
  ```

### Task 2.2: Write the ISO to a USB drive

From NixOS (replace `/dev/sdX` with your USB device — check `lsblk` first):
```bash
lsblk   # identify your USB drive
sudo dd if=cachyos-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

Or from Windows: use **Rufus** → DD mode (not ISO mode). Balena Etcher also works.

---

## Phase 3: CachyOS Installation

Boot from the USB. Your UEFI boot key is likely `F2` or `Esc` on ASUS.

### Task 3.1: Boot from USB

- [ ] Power off
- [ ] Insert USB, power on, tap `F2`/`Esc` to enter UEFI, select USB boot
- [ ] Select **CachyOS Live Environment** from the GRUB menu

### Task 3.2: Launch the installer

- [ ] Once the desktop loads, open the **Install CachyOS** app (calamares)

### Task 3.3: Language and location — standard selections

- [ ] Set language, timezone (America/New_York), keyboard layout (en_US)

### Task 3.4: Desktop selection — choose Hyprland

- [ ] When the installer asks which desktop to install, select **Hyprland**
- [ ] This installs hyprland, waybar, wofi, and basic wayland tooling alongside the base system

### Task 3.5: Partitioning — THIS IS THE CRITICAL STEP

Choose **Manual partitioning**. Do NOT use "auto-install alongside Windows" — it won't know about your existing /home partition.

Configure the following mount points:

| Partition   | Size  | Action                     | Mount Point | Format? |
|-------------|-------|----------------------------|-------------|---------|
| nvme0n1p1   | 1G    | **Mount only (NO format)**  | /boot/efi   | **NO**  |
| nvme0n1p7   | 50G   | Format as ext4              | /           | **YES** |
| nvme0n1p8   | 372G  | **Mount only (NO format)**  | /home       | **NO**  |

Do NOT assign any mount point to p2, p3, p4, p5, p6.

- [ ] Set nvme0n1p1 → mount as /boot/efi, format = NO
- [ ] Set nvme0n1p7 → format ext4, mount as /
- [ ] Set nvme0n1p8 → mount as /home, format = NO
- [ ] Confirm no other partitions are selected

### Task 3.6: User creation

- [ ] Username: `gl00m`
- [ ] This MUST match the /home partition. Calamares on CachyOS will assign UID 1000 automatically for the first user, which matches the existing /home ownership.
- [ ] Set a password
- [ ] Hostname: whatever you want (e.g., `cachyos`)

### Task 3.7: Bootloader

- [ ] The installer defaults to GRUB. Leave it at GRUB — it will auto-detect Windows on nvme0n1p3 and add an entry. Do not change this.

### Task 3.8: Review and install

- [ ] Review the partition summary. Double-check that /boot/efi and /home show NO format.
- [ ] Click Install
- [ ] Wait ~10-20 minutes

### Task 3.9: Reboot verification

- [ ] When prompted, remove USB and reboot
- [ ] GRUB menu should appear with two entries: CachyOS and Windows
- [ ] Boot into Windows first to confirm it works
- [ ] Reboot back into CachyOS

---

## Phase 4: First Boot — Base System Setup

You're now in CachyOS with your /home intact and Hyprland installed. The caelestia shell is not running yet, so you'll be using whatever Hyprland's default bar is.

### Task 4.1: Connect to the internet

- [ ] Run `nmtui` or use the network applet to connect to Wi-Fi

### Task 4.2: Full system update

```bash
sudo pacman -Syu
```

- [ ] Run the above and accept all updates. Reboot if the kernel was updated.

### Task 4.3: Install paru (AUR helper)

```bash
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/paru.git /tmp/paru
cd /tmp/paru && makepkg -si
cd ~ && rm -rf /tmp/paru
```

- [ ] Confirm: `paru --version`

---

## Phase 5: Install System Packages

CachyOS has most packages in their optimized repos. Install in batches.

### Task 5.1: Core system tools

```bash
sudo pacman -S --needed \
  pipewire pipewire-alsa pipewire-pulse wireplumber \
  networkmanager networkmanager-openvpn \
  bluez bluez-utils blueman \
  upower power-profiles-daemon \
  thunar thunar-archive-plugin thunar-volman \
  gvfs tumbler \
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
  polkit-gnome
```

- [ ] Enable services:
```bash
sudo systemctl enable --now bluetooth
sudo systemctl enable --now power-profiles-daemon
```

### Task 5.2: CLI tools (mirrors shell.nix)

```bash
sudo pacman -S --needed \
  eza bat ripgrep fd fzf zoxide \
  wl-clipboard grim slurp \
  brightnessctl playerctl \
  wofi \
  mpv imv \
  git delta github-cli jq \
  alsa-utils pamixer \
  neovim \
  btop nvtop
```

Then install cliphist from AUR:
```bash
paru -S cliphist
```

### Task 5.3: Fonts (mirrors configuration.nix fonts.packages)

```bash
sudo pacman -S --needed \
  inter-font \
  noto-fonts noto-fonts-cjk noto-fonts-emoji \
  ttf-jetbrains-mono-nerd ttf-firacode-nerd \
  ttf-meslo-nerd \
  ttf-nerd-fonts-symbols-common
```

Install CaskaydiaCove, Rubik, Material Symbols from AUR:
```bash
paru -S ttf-cascadia-code-nerd ruby-rubocop-rspec
# For Material Symbols:
paru -S ttf-material-symbols-variable-git
# Rubik font:
paru -S ttf-rubik
```

### Task 5.4: GTK theme and icons (mirrors home.nix gtk)

```bash
paru -S catppuccin-gtk-theme-mocha papirus-icon-theme catppuccin-cursors-mocha
```

### Task 5.5: Hyprland ecosystem

These should already be installed from the desktop selection in phase 3. Verify/supplement:
```bash
sudo pacman -S --needed \
  hyprland xwayland \
  waybar \
  dunst \
  lxqt-policykit \
  nm-applet
```

### Task 5.6: GUI apps

```bash
sudo pacman -S --needed \
  kitty \
  firefox \
  brave-browser \
  telegram-desktop \
  pavucontrol \
  qpwgraph \
  zenity \
  libnotify \
  iw
```

Install Zen browser (AUR):
```bash
paru -S zen-browser-bin
```

Install vesktop (AUR):
```bash
paru -S vesktop
```

### Task 5.7: Gaming

```bash
sudo pacman -S --needed \
  steam \
  gamemode lib32-gamemode \
  gamescope \
  mangohud lib32-mangohud
```

Install protonup-qt from AUR:
```bash
paru -S protonup-qt
```

Enable steam:
```bash
# Steam opens first-time setup on launch — no service needed
```

### Task 5.8: ASUS hardware support

```bash
paru -S asusctl supergfxctl
sudo systemctl enable --now asusd
sudo systemctl enable --now supergfxd
```

Configure power profile (restore what you noted in Task 1.4):
```bash
asusctl profile -P Balanced   # or Performance/Quiet
```

### Task 5.9: Intel graphics and VA-API

```bash
sudo pacman -S --needed \
  intel-media-driver \
  onevpl-intel-gpu \
  intel-compute-runtime \
  libva-utils \
  vulkan-intel lib32-vulkan-intel
```

Set VA-API driver in `/etc/environment`:
```
LIBVA_DRIVER_NAME=iHD
MOZ_ENABLE_WAYLAND=1
```

- [ ] Add those two lines to `/etc/environment`

### Task 5.10: AI / dev tools

Install Claude Code:
```bash
paru -S claude-code
# OR via npm if not in AUR:
npm install -g @anthropic-ai/claude-code
```

Install codex:
```bash
npm install -g @openai/codex
```

Install starship:
```bash
sudo pacman -S starship
```

---

## Phase 6: Dotfiles and Shell Setup

Your dotfiles are at `~/dotfiles` on the surviving /home partition. The Nix-specific parts don't apply anymore, but the config files under `~/dotfiles/config/` are plain config files that work directly.

### Task 6.1: Restore hyprland config symlinks

The home-manager module was creating symlinks like `~/.config/hypr/hyprland.conf → ~/dotfiles/config/hypr/hyprland.conf`. Do this manually:

```bash
mkdir -p ~/.config/hypr
ln -sf ~/dotfiles/config/hypr/hyprland.conf ~/.config/hypr/hyprland.conf
ln -sf ~/dotfiles/config/hypr/scripts/view-logs.sh ~/.config/hypr/view-logs.sh
ln -sf ~/dotfiles/config/hypr/scripts/screenshot.sh ~/.config/hypr/screenshot.sh
ln -sf ~/dotfiles/config/hypr/scripts/kbd-backlight.sh ~/.config/hypr/kbd-backlight.sh
ln -sf ~/dotfiles/config/hypr/scripts/brightness.sh ~/.config/hypr/brightness.sh
ln -sf ~/dotfiles/config/hypr/scripts/space-action.sh ~/.config/hypr/space-action.sh
```

- [ ] Run the above, then `ls -la ~/.config/hypr/` to verify all symlinks resolve

### Task 6.2: Restore kitty config

```bash
# ~/.config/kitty/ already exists from /home - check if it's already linked to dotfiles
ls -la ~/.config/kitty/
# If it points to dotfiles already, nothing to do.
# If not: ln -sf ~/dotfiles/config/kitty ~/.config/kitty
```

### Task 6.3: Set up shell (bash + starship + aliases)

The shell config from `modules/shell.nix` was written to `~/.bashrc` by home-manager. Since /home survived, `~/.bashrc` is intact and the config is still there. Verify:

```bash
source ~/.bashrc
eza --version    # should work if eza is installed
zoxide --version
```

If ~/.bashrc references nix store paths (e.g., `eval "$(${pkgs.zoxide}/bin/zoxide init bash)"`), these paths no longer exist. Replace the home-manager-generated lines with plain equivalents:

- [ ] Open `~/.bashrc`
- [ ] Find lines like `eval "$(/nix/store/.../zoxide init bash)"` and replace with:
  ```bash
  eval "$(zoxide init bash)"
  eval "$(fzf --bash)"
  ```
- [ ] Confirm `~/.bash_profile` or `~/.profile` doesn't have stale nix paths either

### Task 6.4: Git config

The git config from `modules/git.nix` was written to `~/.config/git/config` by home-manager. Since /home survived, git should be configured. Verify:

```bash
git config --global user.name   # should return gl00mt1t4n
git config --global user.email  # should return gloomtitan1337@gmail.com
```

If git config is missing (home-manager may have written to `~/.config/git/config`), set manually:
```bash
git config --global user.name "gl00mt1t4n"
git config --global user.email "gloomtitan1337@gmail.com"
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global core.editor nvim
git config --global push.autoSetupRemote true
git config --global delta.navigate true
git config --global delta.side-by-side true
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
```

---

## Phase 7: Caelestia Shell (Most Complex Part)

Caelestia is your custom quickshell-based desktop shell, built from source in `~/dotfiles/caelestia/`. On CachyOS this must be compiled manually.

### Task 7.1: Install quickshell

CachyOS may have quickshell in their community repo. Check first:
```bash
sudo pacman -Ss quickshell
```

If found, install it:
```bash
sudo pacman -S quickshell
```

If not found, install from AUR:
```bash
paru -S quickshell-git
```

- [ ] Verify: `quickshell --version`

### Task 7.2: Install caelestia build dependencies

```bash
sudo pacman -S --needed \
  cmake clang ninja \
  qt6-base qt6-declarative qt6-wayland \
  qt6-svg qt6-imageformats \
  wayland wayland-protocols \
  pipewire-jack
```

### Task 7.3: Build caelestia-shell from dotfiles

```bash
cd ~/dotfiles/caelestia

# The NixOS build used clangStdenv and passed the quickshell cmake dir.
# On CachyOS, cmake can find it via the system install.
cmake -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DVERSION=local \
  -DGIT_REVISION=$(git rev-parse HEAD)

cmake --build build --parallel $(nproc)
sudo cmake --install build
```

Expected: `caelestia-shell` binary in `/usr/local/bin/` or similar.

- [ ] Run `which caelestia-shell` to confirm installation
- [ ] Test: `caelestia-shell --version` or just `caelestia-shell` (it will try to start the Wayland shell)

### Task 7.4: Install caelestia-cli

caelestia-cli is from a separate flake (`github:caelestia-dots/cli`). Check if it's in AUR:
```bash
paru -Ss caelestia-cli
```

If not, build from source:
```bash
# Install Rust first if not present
sudo pacman -S rustup
rustup default stable

git clone https://github.com/caelestia-dots/cli /tmp/caelestia-cli
cd /tmp/caelestia-cli
cargo build --release
sudo install -m755 target/release/caelestia-cli /usr/local/bin/caelestia
```

- [ ] Verify: `caelestia --version`

### Task 7.5: Set up caelestia config

The caelestia module did this via home-manager activation. Do it manually:

```bash
config_dir="$HOME/.config/caelestia"

# If it's a symlink from old home-manager, remove it
[ -L "$config_dir" ] && rm "$config_dir"

mkdir -p "$config_dir"
cp -RL ~/dotfiles/config/caelestia/. "$config_dir/"
mkdir -p "$config_dir/monitors"
chmod -R u+w "$config_dir"
```

- [ ] Check `ls ~/.config/caelestia/` for the expected config structure

### Task 7.6: Test caelestia in Hyprland

- [ ] Log into Hyprland (logout and re-login, or restart the session)
- [ ] Check if caelestia-shell starts via the exec-once in hyprland.conf
- [ ] If it fails: run `caelestia-shell` manually in a kitty terminal and read the error output
- [ ] Common issue: missing Qt plugins — install `qt6-multimedia` or `qt6-5compat` if needed

---

## Phase 8: Remaining App Configs

### Task 8.1: Spicetify

Spicetify on Arch/CachyOS: install the CLI tool and apply themes.

```bash
paru -S spicetify-cli
# Install spotify first if not done:
paru -S spotify

# Then apply configs from dotfiles (if ~/.config/spicetify exists from /home):
spicetify apply
```

If the old spicetify config references Nix paths, you may need to run `spicetify backup` and re-apply from scratch with the theme files in `~/dotfiles/config/spicetify/`.

### Task 8.2: Neovim

Neovim config is at `~/.config/nvim/` — on /home, so it survived. On first launch, the plugin manager (lazy.nvim likely) will auto-install plugins.

```bash
nvim --headless +qa   # trigger plugin sync
# OR just open nvim normally and let it install
```

- [ ] Open nvim and confirm plugins load

### Task 8.3: Starship prompt

Starship config is at `~/.config/starship.toml` — survived on /home. Just verify it loads:
```bash
source ~/.bashrc
# prompt should show the starship-style "❯" character
```

### Task 8.4: btop / nvtop configs

These configs survived in `~/.config/btop/` and `~/.config/nvtop/`. No action needed.

### Task 8.5: AppImage setup

The `appimage-install` helper script was written to `~/.local/bin/appimage-install` by home-manager. It should still be there on /home. Verify:
```bash
ls -la ~/.local/bin/appimage-install
chmod +x ~/.local/bin/appimage-install  # re-set if needed
```

For AppImage binfmt support on CachyOS (Arch-based):
```bash
paru -S appimagelauncher
# OR just use appimage-run:
sudo pacman -S fuse2
```

---

## Phase 9: System Services and Environment

### Task 9.1: zram swap

CachyOS enables zram by default. Verify:
```bash
zramctl
```

If not active, install and enable:
```bash
sudo pacman -S zram-generator
# Config at /etc/systemd/zram-generator.conf
```

### Task 9.2: i2c for ddcutil (caelestia external monitor brightness)

```bash
sudo modprobe i2c-dev
echo "i2c-dev" | sudo tee /etc/modules-load.d/i2c.conf
sudo usermod -aG i2c gl00m   # if i2c group exists
# Or use udev rule:
echo 'KERNEL=="i2c-[0-9]*", GROUP="video", MODE="0660"' | sudo tee /etc/udev/rules.d/45-ddcutil-i2c.rules
```

### Task 9.3: Backlight udev rules

The NixOS config had udev rules for backlight and keyboard LED sysfs access. Re-create them:

Create `/etc/udev/rules.d/90-backlight.rules`:
```
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", RUN+="/usr/bin/chgrp video /sys%p/brightness", RUN+="/usr/bin/chmod g+w /sys%p/brightness"
ACTION=="add", SUBSYSTEM=="leds", KERNEL=="asus::kbd_backlight", RUN+="/usr/bin/chgrp video /sys%p/brightness", RUN+="/usr/bin/chmod g+w /sys%p/brightness"
```

```bash
sudo udevadm control --reload-rules && sudo udevadm trigger
```

### Task 9.4: Kernel parameters

The NixOS config had `video.brightness_switch_enabled=0` to let Hyprland handle brightness keys. Set it in GRUB:

Edit `/etc/default/grub`:
```
GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=3 video.brightness_switch_enabled=0"
```

Then rebuild GRUB:
```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### Task 9.5: Power profile keep-on-balanced service

The NixOS config had a systemd oneshot to reset power profile to balanced after boot (to prevent auto-switching to power-saver which caused display stutter). Re-create it:

Create `/etc/systemd/system/power-profile-balanced.service`:
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

```bash
sudo systemctl enable --now power-profile-balanced.service
```

### Task 9.6: Lid switch behavior (suspend on close)

```bash
sudo mkdir -p /etc/systemd/logind.conf.d
cat <<EOF | sudo tee /etc/systemd/logind.conf.d/lid.conf
[Login]
HandleLidSwitch=suspend
HandleLidSwitchExternalPower=suspend
HandleLidSwitchDocked=ignore
EOF
sudo systemctl restart systemd-logind
```

### Task 9.7: nix-ld equivalent (run unpackaged ELFs)

CachyOS doesn't need nix-ld. Dynamic ELF binaries work normally. AppImages use FUSE. No action needed.

---

## Phase 10: Verification

### Task 10.1: Boot and display

- [ ] Boot into CachyOS, Hyprland starts
- [ ] `hyprctl monitors` shows correct output (eDP-1 at 2880x1800@120, scale 2)
- [ ] Brightness keys work (F5/F6)
- [ ] Keyboard backlight key (F4) works

### Task 10.2: Audio

- [ ] `wpctl status` shows audio sinks
- [ ] `pactl list short sinks` shows pipewire sinks
- [ ] Volume keys work
- [ ] `pavucontrol` opens

### Task 10.3: ASUS hardware

- [ ] `asusctl profile -l` works
- [ ] `asusctl led-mode -l` works
- [ ] `supergfxctl -s` works

### Task 10.4: VA-API video decode

```bash
vainfo   # should show iHD driver and H264/HEVC decode profiles
```

### Task 10.5: Steam and gaming

- [ ] Steam launches
- [ ] Existing games visible (Steam library is in ~/.local/share/Steam which is on /home)
- [ ] `gamemode --status` works

### Task 10.6: Caelestia shell

- [ ] Bar/shell appears after Hyprland starts
- [ ] Workspace switching works
- [ ] `caelestia wallpaper set <path>` works (if caelestia-cli is installed)

### Task 10.7: Windows dual-boot

- [ ] Reboot, GRUB shows Windows entry
- [ ] Windows boots (BitLocker is already disabled so no issues)
- [ ] Reboot back into CachyOS

### Task 10.8: Network and VPN

- [ ] Wi-Fi connects via NetworkManager
- [ ] `nmcli con show` shows saved connections from /home NetworkManager profiles (these survived on /home if NM stores them there — actually NM stores connections in /etc/NetworkManager/system-connections/ which is on the root partition, so saved Wi-Fi passwords are LOST)
- [ ] Re-enter Wi-Fi passwords for your networks
- [ ] OpenVPN NetworkManager plugin: `sudo pacman -S networkmanager-openvpn` if not already installed

> **Note:** NetworkManager connections live in /etc on root, not /home. Wi-Fi passwords must be re-entered after migration. Plan for this.

---

## Appendix: What Survived (on /home) vs What Needs Manual Restoration

### Survived automatically (on nvme0n1p8 /home):
- `~/dotfiles/` — entire NixOS config repo
- `~/.ssh/` — SSH keys
- `~/.gnupg/` — GPG keyring
- `~/.config/` — all app configs (hypr, kitty, nvim, btop, caelestia, zen, etc.)
- `~/.local/share/Steam/` — all Steam games
- `~/.local/share/` — app data, installed games
- `~/.claude/`, `~/.claude.json` — Claude Code config
- `~/.bash_history`, `~/.bashrc` — shell history and config
- Browser profiles (Brave, Zen) — all history, extensions, settings

### Needs re-installation (was on /var or /nix on root):
- All system packages (pacman/paru)
- ASUS asusd profiles (/etc/asusd/)
- NetworkManager Wi-Fi credentials (/etc/NetworkManager/system-connections/)
- System services (systemd units in /etc/systemd/)
- Udev rules
- GRUB config
- Font cache (rebuilds automatically on first login)

### Needs manual action (were Nix-generated, now need plain equivalents):
- `~/.bashrc` lines with `/nix/store/...` paths → replace with plain commands
- Caelestia shell binary → build from `~/dotfiles/caelestia/`
- caelestia-cli binary → build from source or AUR
- Home-manager symlinks → recreate manually (Phase 6)
