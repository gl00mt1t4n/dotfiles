# gl00m — System Context

## Hardware
- ASUS Zenbook Duo UX8406CA, Intel Core Ultra, NPU enabled
- Displays: eDP-1 main (2880x1800@120Hz scale 2) + eDP-2 ScreenPad Plus (under keyboard, always active by design)
- Dual boot: NixOS primary / Windows 11 gaming
- VMD: disabled. Secure Boot: disabled.

## NixOS
- Unstable channel, flakes, username gl00m, timezone America/Chicago
- Shell: bash. WM: Hyprland (Wayland + XWayland)
- home-manager as NixOS module

## Dotfiles
- Repo: ~/dotfiles/ — symlinked to /etc/nixos/
- Build: `make full` (system+user), `make system`, `make user`
- Alias: `nixrebuild` = `make full`
- Edit configs in ~/dotfiles/, never /etc/nixos/ directly
- `cat` is aliased to `bat` — use `\cat` for raw output

## Key files
- ~/dotfiles/configuration.nix — system layer
- ~/dotfiles/home.nix — home-manager root
- ~/dotfiles/modules/ — shell.nix, git.nix, hyprland.nix
- ~/dotfiles/config/ — hyprland.conf, caelestia/shell.json, caelestia/wallpapers, kitty, nvim

## Desktop
- Hyprland compositor with Caelestia shell for launcher, lock, idle, wallpaper, notifications, OSD, dashboard, sidebar, utilities; Kitty terminal

## Pending
- Ricing, Neovim (LSP + AI), Claude Code, asusctl, ScreenPad Plus, pipewire, fonts, wl-clipboard, Docker, Node, Python, Rust
