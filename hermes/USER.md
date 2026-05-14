# gl00m — System Context

## Hardware

- **Machine:** ASUS Zenbook Duo UX8406CA
- **CPU:** Intel Core Ultra (NPU enabled)
- **Displays:** eDP-1 (main, 2880x1800@120Hz, scale 2) + eDP-2 (ScreenPad Plus, same res, physically under keyboard — always active by design, not a bug)
- **EFI partition:** 1GB (was resized from 260MB during install)
- **Dual boot:** NixOS (primary dev OS) / Windows 11 (gaming/media)
- **Bluetooth:** enabled (blueman for GUI)

## Hardware Warnings

- **VMD:** disabled (confirmed via `lspci` — no VMD controller present). Was disabled prior to NixOS install. Windows survived the toggle because Intel RST drivers were prepped beforehand. No action needed.
- **Secure Boot:** disabled
- **Fast Boot:** disabled
- **BitLocker:** off

---

## Operating System

- **NixOS unstable channel**
- **Flakes enabled**
- **Username:** gl00m
- **Hostname:** nixos
- **Timezone:** America/Chicago
- **Shell:** bash
- **WM:** Hyprland (Wayland), XWayland enabled

---

## Dotfiles Structure

```
~/dotfiles/
├── flake.nix                     ← single entry point (symlinked to /etc/nixos/flake.nix)
├── flake.lock
├── Makefile                      ← all build commands
├── configuration.nix             ← system layer (kernel, drivers, services, users)
├── hardware-configuration.nix
├── home.nix                      ← home-manager root (imports all modules)
├── modules/
│   ├── shell.nix
│   ├── git.nix
│   └── hyprland.nix
└── config/
    ├── hypr/
    │   ├── hyprland.conf
    │   └── hypridle.conf
    ├── hyprpaper/
    │   └── hyprpaper.conf
    └── mako/
        └── config
```

**Symlinks:**
- `~/dotfiles/flake.nix` → `/etc/nixos/flake.nix`
- `~/dotfiles/flake.nix` → `~/.config/home-manager/flake.nix`
- Config files in `~/dotfiles/config/` are symlinked into `~/.config/` by home-manager

---

## Build System

home-manager runs as a NixOS module — a single `make full` applies both system and user config.

| Command | What it does |
|---|---|
| `make full` | Rebuild system + user (nixosConfigurations.gl00m-full) |
| `make system` | Rebuild system only (nixosConfigurations.nixos) |
| `make user` | Rebuild user only (home-manager) |
| `make update` | `nix flake update` — update all inputs |
| `make clean` | `nix-collect-garbage` — remove old generations |
| `nixrebuild` | Alias for `make full` |
| `nixrebuild -system` | Alias for `make system` |
| `nixrebuild -user` | Alias for `make user` |

**Important:** Always `cd ~/dotfiles/` before running make commands. Config lives in the repo, not in `/etc/nixos/` directly.

**Reboots:** Only needed after kernel updates. Normal config/package/service changes activate immediately with `switch` — no reboot needed.

---

## Flake Inputs (current)

- `nixpkgs` → nixpkgs/nixos-unstable
- `home-manager` → follows nixpkgs

**Hermes Agent** is being added as the next flake input (`github:NousResearch/hermes-agent`). Not yet applied.

---

## Desktop

- **Hyprland** — tiling Wayland compositor
- **Waybar** — status bar (top)
- **Hyprlauncher** — app launcher (SUPER+R)
- **Hyprlock** — screen lock (SUPER+L)
- **Hypridle** — idle daemon (locks 5min, suspends 10min)
- **Hyprpaper** — wallpaper daemon
- **Mako** — notifications (5s default timeout)
- **Kitty** — terminal emulator
- **Monitor layout:** eDP-1 main (top), eDP-2 ScreenPad Plus (bottom, under keyboard)

---

## Shell & CLI Tools

- `eza` — ls replacement (`ls` and `ll` aliased)
- `bat` — cat replacement (**`cat` is aliased to `bat`** — use `\cat` to bypass and get raw output)
- `ripgrep` — fast grep
- `fd` — fast find
- `fzf` — fuzzy finder
- `zoxide` — smart cd

**Key aliases:**
- `dotfiles` → `cd /home/gl00m/dotfiles`
- `nixconf` → open configuration.nix in vim
- `hyprconf` → open hyprland.conf in vim
- `ls` → `eza --icons`
- `ll` → `eza -la --icons`
- `cat` → `bat`

---

## Git

- `delta` — syntax highlighted diffs
- `gh` — GitHub CLI
- SSH auth (no password prompts)
- `pull.rebase = true`, `push.autoSetupRemote = true`

---

## Editors

- `neovim` — primary editor (not yet configured, config in progress)
- `vim` — fallback

---

## Pending / In Progress

### Immediate
- **Hermes Agent** — installing as NixOS module (current task)

### Next
- **Ricing** — colorscheme, waybar config, kitty theme, fonts
- **Neovim** — LSP, completion, treesitter, AI extensions (avante.nvim)
- **AI tooling** — Claude Code in terminal, MCP servers, everything-claude-code repo
- **Dev tooling** — Node, Python, Rust, direnv, Docker
- **Zenbook-specific** — asusctl, ScreenPad Plus management via `github.com/alesya-h/zenbook-duo-2024-ux8406ma-linux`
- **Must-have utilities** — pipewire (audio), fonts, screenshot tool, wl-clipboard

---

## AI Stack (planned)

- **Hermes Agent** (Nous Research) — always-on system AI, NixOS module, Anthropic backend
- **Claude Code** — terminal coding agent
- **avante.nvim** — neovim AI integration
- **MCP servers** — tool integrations

**Model strategy:** Default to cheap model (haiku or gemini-flash via OpenRouter), bump to sonnet only when task demands it. OpenRouter as base_url for multi-model access. Separate cheaper summary_model for context compression.

---

## Notes for Hermes

- When suggesting NixOS config changes, always target `~/dotfiles/configuration.nix` or the relevant module file — not `/etc/nixos/` directly
- The rebuild command is `make full` from `~/dotfiles/`
- If asked to edit a file, the user's `cat` is aliased to `bat` — raw file reads work fine for you via tools, but remind the user to use `\cat` if they're copying output manually
- ScreenPad Plus being active is expected and intentional — do not suggest disabling it unless asked
- VMD is disabled — confirmed via lspci. The previous boot loop was Windows-side (no RST drivers). NixOS sees NVMe normally.
