# TODO

---

## Ricing & Visual

- [ ] **kitty.conf** — JetBrainsMono Nerd Font size 13, Catppuccin Mocha colors, padding, cursor shape
- [ ] **Caelestia wallpaper set** — replace the placeholder repo wallpaper in `config/caelestia/wallpapers/` with real images
- [ ] **Caelestia lock tuning** — profile image, notification visibility, fingerprint only if fprintd is configured
- [ ] **GTK theming** — catppuccin-gtk + papirus-icon-theme + catppuccin-cursors; wire via `gtk.enable`, `home.pointerCursor` in home.nix
- [ ] **Hyprland animations** — tune bezier curves, window open/close/workspace slide animations in hyprland.conf
- [ ] **Caelestia launcher tuning** — favorite apps, hidden apps, action list, wallpaper/scheme entries

---

## Workspace & Navigation

- [ ] **Hyprspace** — workspace overview plugin (Mission Control / Activities style); replaces or complements current workspace binds
- [ ] **Smart workspace script** — move to next WS, auto-open launcher if workspace is empty
- [ ] **Second screen (eDP-2)** — currently hard-disabled; plan workspace routing before re-enabling (which workspaces go where, primary/secondary behavior, hotplug handling)
- [ ] **Per-monitor workspace config** — once eDP-2 is re-enabled: assign workspaces 1-5 to eDP-1, 6-10 to eDP-2

---

## Hardware

- [ ] **Fan control** — add `auto-cpufreq` to configuration.nix; configure governor (powersave on battery, performance on AC); stops fans spiking on minor CPU bursts
- [ ] **Generation limit + GC** — `boot.loader.systemd-boot.configurationLimit = 10` + `nix.gc` weekly `--delete-older-than 30d` in configuration.nix
- [ ] **ASUS pen (Bluetooth stylus)** — investigate pairing; check if `blueman` or `bluetoothctl` can pair it; may need `xf86-input-wacom` or `libwacom` for pressure sensitivity in Hyprland
- [ ] **Keyboard backlight** — revisit on future kernel/asusd update; check `find /sys -name "*kbd*backlight*"` and `asusctl --help`

---

## Apps & Daemons

- [ ] **Spotify/Spicetify polish** — Caelestia theme is vendored and applied at build time; next tune color.ini against the active Caelestia palette
- [ ] **Clipboard manager** — add `cliphist` + `wl-clipboard`; bind `SUPER+V` to clipboard history picker in hyprland.conf
- [ ] **Screenshot improvements** — current `screenshot.sh` uses basic tools; consider `grimblast` for region/window/monitor modes with annotation
- [ ] **Webull** — Linux availability unclear; try via Bottles (Wine wrapper in a Flatpak sandbox) first

---

## AI & Automation

- [ ] **Understand Hermes agent** — `hermes-agent` is in the flake from NousResearch (open-weight Hermes LLM series); figure out: what model it runs, what interface it exposes, how it differs from Claude Code (local vs API, offline capable, different strengths), what tasks it's best suited for
- [ ] **Browser hands (browser-use)** — give AI agents control of Zen Browser via `browser-use` (Python framework); lets Hermes or Claude drive the browser: fill forms, scrape, navigate; wire into Hermes agent tasks
- [ ] **Second brain** — set up either:
  - **Obsidian** — GUI knowledge base, vault in `~/notes`, community plugins for daily notes/graph view; or
  - **gbrain framework** — investigate Gary Trans's repository, understand the structure, adapt to this setup
  - Both: decide which is primary, whether they sync/complement each other
- [ ] **everything-claude-code** — audit the `hesreallyhim/awesome-claude-code` repo (or equivalent); extract: useful CLAUDE.md patterns, hooks, slash commands, MCP server configs worth adding to this setup
- [ ] **Projects folder** — create `~/projects/` as sibling to `~/dotfiles/`; soft-symlink into a known location so both Hermes and Claude Code can access it; add to Claude Code's allowed paths; document structure (one repo per subdirectory)
- [ ] **Claude Code MCP servers** — evaluate which MCP servers are worth adding: filesystem, memory, browser, shell; configure in `.claude/settings.json`
- [ ] **Hermes + Claude handoff** — define which tasks go to which agent: Hermes for local/offline/background tasks, Claude Code for interactive coding; avoid overlap

---

## Bug Fixes

- [ ] **Phantom wallet (Zen Browser)** — extension popup closes on hover-out; likely Wayland focus issue; fix via Hyprland `windowrulev2` targeting the popup window class

---

## Done

- [x] Volume keys — F1/F2/F3 binds for Fn Lock keysyms
- [x] asusd crash at boot — tmpfiles rule creates /etc/asusd
- [x] Brightness control — intel_backlight udev rule + brightness.sh with -d flag
- [x] Brightness OSD — handled by Caelestia brightness monitoring
- [x] Zen Browser — flake input + overlay in flake.nix
- [x] Keyboard backlight graceful failure — desktop notification instead of silent error
- [x] Neovim basic config — nvim-tree, bufferline, catppuccin-mocha, keymaps
- [x] Scripts reorganized — moved to config/hypr/scripts/
- [x] GNOME leftover cleanup — removed ~15 orphaned config/data directories
- [x] sops/age orphan removed
