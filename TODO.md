# TODO

## Desktop Polish
- [ ] `hyprlock.conf` — blur background, clock, password field
- [ ] `hyprpaper.conf` — wallpaper (decide: repo asset, ~/Pictures, or solid Catppuccin color)
- [ ] `kitty.conf` — JetBrainsMono Nerd Font size 13, Catppuccin Mocha, padding
- [ ] GTK/cursor theming — catppuccin-gtk, papirus-icon-theme, catppuccin-cursors, home.pointerCursor

## System / Hardware
- [ ] Fan control — add `auto-cpufreq` to manage CPU frequency scaling and fan curves
- [ ] Generation limit + GC — `boot.loader.systemd-boot.configurationLimit = 10` + `nix.gc` weekly
- [ ] Keyboard backlight — revisit on future kernel/asusd update (`find /sys -name "*kbd*backlight*"`)

## Workspace Experience
- [ ] Smart workspace nav — script: move to next WS, open launcher if empty
- [ ] Hyprexpo (`SUPER+TAB`) — zoom-out workspace overview via Hyprland plugins
- [ ] Waybar workspace styling — visual distinction for active/occupied/empty workspaces

## Apps
- [ ] Spotify — one line in home.nix, `allowUnfree` already set
- [ ] Webull — check Linux availability, may need Bottles/Wine

## Bug Fixes
- [ ] Phantom wallet extension in Zen Browser — popup closes on hover-out (Wayland focus issue, needs Hyprland windowrule)

## AI / Second Brain
- [ ] Hermes agent + browser harness + Claude Code second brain

## Done
- [x] Volume keys (F2/F3 binds for Fn Lock)
- [x] asusd crash at boot (tmpfiles rule for /etc/asusd)
- [x] Brightness control (intel_backlight udev rule + brightness.sh)
- [x] Brightness OSD (notify-send via mako)
- [x] Zen Browser installed
- [x] Keyboard backlight graceful failure notification
- [x] Neovim basic config (nvim-tree, bufferline, catppuccin)
