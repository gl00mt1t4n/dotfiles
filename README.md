# gl00m's dotfiles

NixOS configuration for ASUS Zenbook Duo UX8406CA (dual screen, Intel Core Ultra).

---

## Hardware

- **Machine:** ASUS Zenbook Duo UX8406CA
- **CPU:** Intel Core Ultra (NPU enabled)
- **Displays:** Dual screen — eDP-1 (main) + eDP-2 (ScreenPad Plus)
- **Resolution:** 2880x1800@120Hz, scale 2, both screens
- **OS:** NixOS unstable (dual boot with Windows)

---

## Structure
dotfiles/
├── flake.nix                     # single entry point for entire system
├── flake.lock                    # pinned inputs
├── Makefile                      # build commands
├── configuration.nix             # system layer (kernel, drivers, services, users)
├── hardware-configuration.nix    # auto-generated hardware config
├── home.nix                      # home-manager root (imports all modules)
├── modules/
│   ├── shell.nix                 # bash config, aliases, CLI tools
│   ├── git.nix                   # git, delta, gh CLI
│   └── hyprland.nix              # hyprland + related tool symlinks
└── config/
├── hypr/
│   ├── hyprland.conf         # hyprland compositor config
│   └── hypridle.conf         # idle daemon config
├── hyprpaper/
│   └── hyprpaper.conf        # wallpaper config
└── mako/
└── config                # notification daemon config

---

## Commands

| Command | Action |
|---|---|
| `make system` | rebuild system config only (`configuration.nix`) |
| `make user` | rebuild user config only (home-manager) |
| `make full` | rebuild both system and user |
| `make update` | update flake inputs (`nix flake update`) |
| `make clean` | garbage collect old nix generations |
| `nixrebuild` | alias for `make full` |
| `nixrebuild -system` | alias for `make system` |
| `nixrebuild -user` | alias for `make user` |

---

## Aliases

| Alias | Command |
|---|---|
| `dotfiles` | `cd /home/gl00m/dotfiles` |
| `nixconf` | open `configuration.nix` in vim |
| `hyprconf` | open `hyprland.conf` in vim |
| `ls` | `eza --icons` |
| `ll` | `eza -la --icons` |
| `cat` | `bat` |

---

## Symlinks (home-manager managed)

These files live in `~/dotfiles/config/` and are symlinked into place by home-manager on every `make user` or `make full`.

| Dotfiles path | System path |
|---|---|
| `config/hypr/hyprland.conf` | `~/.config/hypr/hyprland.conf` |
| `config/hypr/hypridle.conf` | `~/.config/hypr/hypridle.conf` |
| `config/hyprpaper/hyprpaper.conf` | `~/.config/hyprpaper/hyprpaper.conf` |
| `config/mako/config` | `~/.config/mako/config` |

---

## System Symlinks (manual, one-time setup)

| Dotfiles path | System path | Purpose |
|---|---|---|
| `flake.nix` | `/etc/nixos/flake.nix` | `nixos-rebuild` finds flake automatically |
| `flake.nix` | `~/.config/home-manager/flake.nix` | `home-manager` finds flake automatically |

---

## Implemented Features

### System
- NixOS unstable channel
- Flakes enabled
- Home-manager unified (runs as NixOS module, single `make full` applies everything)
- Intel NPU enabled
- Bluetooth enabled (`blueman` for GUI)
- Wayland session (Hyprland)
- XWayland enabled

### Desktop
- **Hyprland** — tiling Wayland compositor
- **Waybar** — status bar (top)
- **Hyprlauncher** — first-party app launcher (`SUPER + R`)
- **Hyprlock** — screen lock (`SUPER + L`)
- **Hypridle** — idle daemon (locks after 5min, suspends after 10min)
- **Hyprpaper** — wallpaper daemon
- **Mako** — notification daemon (5s default timeout)
- **Dual monitor** — eDP-1 main display, eDP-2 ScreenPad Plus

### Shell (bash)
- `eza` — modern `ls` replacement
- `bat` — modern `cat` replacement
- `ripgrep` — fast grep
- `fd` — fast find
- `fzf` — fuzzy finder
- `zoxide` — smart `cd`

### Git
- `delta` — syntax highlighted diffs
- `gh` — GitHub CLI
- SSH auth (no password prompts)
- `pull.rebase = true`, `push.autoSetupRemote = true`

### Editors
- `neovim` — primary editor (configuration coming)
- `vim` — fallback

---

## Pending / In Progress

- Ricing (colorscheme, waybar config, kitty theme, fonts)
- Neovim full config (LSP, completion, treesitter, AI extensions)
- AI tooling (avante.nvim, Claude Code, MCP servers)
- Dev tooling (Node, Python, Rust, direnv, Docker)
- Zenbook-specific (asusctl, ScreenPad Plus)
- Must-have utilities (pipewire, fonts, screenshots, clipboard)
