# gl00m's dotfiles

NixOS configuration for ASUS Zenbook Duo UX8406CA. Everything — system, desktop, shell, tools — is declared here. One repo, one command to rebuild the entire machine.

---

## Design Philosophy

The goal is a fully reproducible system where no manual post-install steps exist (outside of secrets). If this repo is cloned onto a fresh NixOS install and `nixos-rebuild switch --flake .#gl00m-full` is run, the result should be identical to the current machine — same packages, same config, same desktop, same shell behavior.

---

## Architecture

### Why NixOS

Traditional Linux distros are stateful — you install packages over time, edit config files, and the system slowly drifts from any reproducible baseline. NixOS inverts this: the entire system is declared in text files and built atomically. Every change produces a new "generation" you can boot into or roll back from. The system state is always derivable from the repo.

### Why Flakes

Before flakes, NixOS used `nix-channel` to pull nixpkgs. Channels are not pinned — two machines running the same config on different days could get different package versions. Flakes solve this by declaring all inputs explicitly and locking their exact git commits in `flake.lock`. The result is deterministic: same repo + same lock file = identical system, always.

### Why Home-manager

NixOS's `configuration.nix` manages the system layer — kernel, hardware, services, system-wide packages. It requires root and has no concept of per-user configuration. Home-manager fills the gap: it manages everything under `~/` declaratively, as the user, without root. Shell config, dotfiles, user packages, and terminal settings all live here. This separation also means user-level changes (`nixrebuild -user`) are faster and don't touch the system.

Home-manager runs as a NixOS module in this config (the `gl00m-full` flake target), meaning `make full` applies both system and user changes in a single command. The standalone `gl00m` target exists for user-only rebuilds via `nixrebuild -user`.

### Why Hyprland

Hyprland is a tiling Wayland compositor. The choice over a full desktop environment (GNOME, KDE) was deliberate:

- **Control**: every behavior is explicitly configured — no hidden defaults or global settings menus overriding things
- **Performance**: no DE overhead; just the compositor, a bar, a notification daemon, and what you choose to add
- **Wayland-native**: XWayland support is included for legacy apps, but the session itself is modern Wayland
- **Composability**: each component (launcher, lock screen, idle daemon, wallpaper) is a separate tool you choose and configure independently

The tradeoff is that nothing works out of the box — you have to wire everything together yourself, which is what this repo is.

### Modular Structure

Home-manager config is split into modules (`modules/`) rather than one large `home.nix`. Each module owns one concern: shell tooling, git, desktop symlinks, terminal, bar. This makes it easy to find and change things without understanding the entire config. `home.nix` is just the import list.

### The nixrebuild Flow

The `nixrebuild` function enforces a workflow: stage changes → commit → dry-activate (build without applying) → if clean, push → apply. This ensures:

1. The git tree is clean when nix evaluates (no "dirty tree" warnings, no testing uncommitted state)
2. A broken config never gets pushed to the remote — the dry run catches it first
3. If the dry run fails, the local commit is automatically rolled back (`git reset --soft HEAD~1`), leaving changes staged but uncommitted

### Why No Secrets Manager (Agenix Removed)

Agenix was originally used to manage the Hermes API key. It decrypts secrets to `/run/agenix/` at activation time — but `/run/` is a tmpfs (RAM only). If the private age key was unavailable during activation, the secret was silently absent and Hermes started without an API key. The fix was to remove agenix entirely and use a manually-managed env file at `/var/lib/hermes/env`. This file is not tracked by nix, survives all rebuilds and reboots, and is created once by the user.

---

## Hardware

| Component | Details |
|-----------|---------|
| Machine | ASUS Zenbook Duo UX8406CA |
| CPU | Intel Core Ultra (with NPU) |
| Displays | eDP-1 (main) + eDP-2 (ScreenPad Plus, below keyboard) |
| Resolution | 2880×1800@120Hz, scale 2, both screens |
| OS | NixOS unstable |
| Boot | systemd-boot, EFI |

The Intel NPU is enabled (`hardware.cpu.intel.npu.enable = true`). The ASUS-specific daemons `asusd` and `supergfxd` handle fan curves, keyboard backlight, and GPU switching.

---

## File Structure

```
dotfiles/
├── flake.nix                    # Entry point — declares inputs and the three build targets
├── flake.lock                   # Pinned input versions (do not edit manually)
├── Makefile                     # Pure build commands (no git logic)
├── configuration.nix            # System layer: hardware, kernel, services, users
├── hardware-configuration.nix   # Auto-generated, do not edit
├── home.nix                     # User layer root: imports all modules
│
├── modules/
│   ├── shell.nix                # Bash config, aliases, CLI tools, nixrebuild function
│   ├── git.nix                  # Git identity, delta, gh CLI
│   ├── hyprland.nix             # Symlinks all hypr/desktop configs into ~/.config/
│   ├── waybar.nix               # Symlinks waybar config + CSS
│   └── kitty.nix                # Symlinks kitty terminal config
│
├── config/
│   ├── hypr/
│   │   ├── hyprland.conf        # Compositor: monitors, keybinds, animations, rules
│   │   ├── hypridle.conf        # Idle daemon: lock after 5min, suspend after 10min
│   │   ├── hyprlock.conf        # Lock screen: blurred background, clock, password field
│   │   └── hyprpaper.conf       # Wallpaper daemon (wallpaper lines commented, add when ready)
│   ├── waybar/
│   │   ├── config               # Bar layout, modules
│   │   └── style.css            # Bar styling (Catppuccin Mocha)
│   ├── mako/
│   │   └── config               # Notification daemon styling
│   └── kitty/
│       └── kitty.conf           # Terminal font, padding, cursor
│
└── hermes/
    └── USER.md                  # System context document fed to the Hermes AI agent
```

---

## Flake Targets

| Target | Command | What it builds |
|--------|---------|----------------|
| `gl00m-full` | `make full` | System + home-manager (use this) |
| `nixos` | `make system` | System only (`configuration.nix`) |
| `gl00m` | `make user` | Home-manager only (`home.nix`) |

---

## Commands

| Command | Action |
|---------|--------|
| `nixrebuild` | Full rebuild: stage → commit → dry run → push → switch |
| `nixrebuild -system` | System-only rebuild |
| `nixrebuild -user` | User-only rebuild (faster, no sudo) |
| `make full` | Raw full rebuild (no git flow) |
| `make update` | Update all flake inputs |
| `make clean` | Garbage collect old nix store paths |

---

## Shell Aliases

| Alias | Expands to |
|-------|-----------|
| `dotfiles` | `cd /home/gl00m/dotfiles` |
| `nixconf` | `sudo nvim .../configuration.nix` |
| `hyprconf` | `nvim .../hyprland.conf` |
| `ls` | `eza --icons` |
| `ll` | `eza -la --icons` |
| `cat` | `bat` |

---

## Keybindings

| Binding | Action |
|---------|--------|
| `SUPER + Q` | Open terminal (kitty) |
| `SUPER + C` | Close active window |
| `SUPER + R` | Open app launcher |
| `SUPER + E` | File manager (dolphin) |
| `SUPER + V` | Toggle floating |
| `SUPER + L` | Lock screen |
| `SUPER + M` | Exit Hyprland |
| `SUPER + S` | Toggle scratchpad |
| `SUPER + [1–9]` | Switch to workspace |
| `SUPER + SHIFT + [1–9]` | Move window to workspace |
| `SUPER + arrows` | Move focus |
| `SUPER + scroll` | Scroll through workspaces |
| `Print` | Screenshot to ~/Pictures/ |
| `SUPER + SHIFT + Print` | Region screenshot |
| `XF86` volume/brightness keys | Volume and brightness |

**Gestures:**
- 3-finger horizontal swipe: switch workspaces

---

## Workspace Philosophy

Workspaces are used as independent work contexts — not OS-level profiles. Workspace 1 is the default landing point. The scratchpad (`SUPER+S`) is for persistent apps (e.g. Spotify, a pinned terminal) that should float above any workspace.

---

## After a Fresh Install

1. Clone this repo and symlink or copy to `/etc/nixos/`
2. Run `sudo nixos-rebuild switch --flake .#gl00m-full`
3. Create the Hermes API key file:
   ```bash
   sudo mkdir -p /var/lib/hermes
   sudo tee /var/lib/hermes/env << 'EOF'
   OPENROUTER_API_KEY=your-key-here
   EOF
   sudo chmod 600 /var/lib/hermes/env
   ```
4. Set a wallpaper: place an image, then edit `config/hypr/hyprpaper.conf` and uncomment the three lines

---

## Pending

- Neovim full config (LSP, treesitter, completion, AI extensions)
- Wallpaper selection
- Dev tooling (Node, Python, Rust, direnv, Docker)
- ScreenPad Plus advanced usage (asusctl profiles)
- Widget layer for workspace 1 (eww or AGS — not yet decided)
