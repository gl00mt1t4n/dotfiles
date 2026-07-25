# Hermes single-owner migration runbook

## Current status: stage 1 is built; do not switch yet

This repository now contains **stage 1**, a reversible remote-backend pilot. It leaves the current shared-state Desktop launcher, host CLI, `~/.hermes` symlink, group membership, and permission-repair timer in place. It adds an opt-in remote client and a supervised `hermes serve` companion so the architecture can be tested without removing the known-good route.

A release gate runs at activation and rejects the pilot while `hermes doctor` reports the SQLite WAL-reset bug. The candidate package currently reports **SQLite 3.51.2**, so `nixos-rebuild switch` must **not** be attempted until the selected runtime is updated and the candidate doctor check is clean.

## Confirmed rollback checkpoint

```text
tag:     hermes-desktop-timer-working
commit:  fa0c3d4145cdee34d11e622dd94d64a6dc40da53
subject: feat(hermes): add desktop shared-state timer
```

This annotated tag is the same commit that was `main` HEAD before this migration work.

Original deployed Hermes input:

```text
NousResearch/hermes-agent@a979ca2a67a6fe3c08dd97a10ec6131aca913c14
https://github.com/NousResearch/hermes-agent/commit/a979ca2a67a6fe3c08dd97a10ec6131aca913c14
```

The candidate lock updates the Hermes input to:

```text
07e97d2f5dc3d2092cfe693ef07b2527a36cd2d8
```

That update did **not** update the NixOS-linked SQLite runtime beyond 3.51.2, so it does not clear the release gate.

## Stage 1: remote-backend pilot

### What is implemented

- `hermes-serve.service` runs inside the existing `hermes-agent` Docker container as `hermes` and binds only to `127.0.0.1:9119`.
- It has `Requires`, `After`, `BindsTo`, and `PartOf` links to `hermes-agent.service`.
- Activation creates one random loopback session token only after the SQLite release gate passes:
  - service copy: `/var/lib/hermes/.hermes/desktop-remote.token`, `hermes:hermes`, `0600`;
  - Desktop copy: `/home/gl00m/.config/Hermes/hermes-remote.token`, `gl00m:users`, `0600`.
- **Hermes** remains the old known-good shared-state Desktop entry.
- **Hermes Remote Pilot** is the new explicit remote-client entry. It uses `HERMES_DESKTOP_REMOTE_URL=http://127.0.0.1:9119` plus the token and does not launch a local server.
- `hermes-recovery` starts an isolated host-native TUI at `~/.local/state/hermes-recovery`.
- Backend terminal tools now include `codex`, `claude-code`, and `tmux`, but no user credential store is copied into the service.

### When SQLite is safe, validation sequence

1. Build and inspect the selected candidate package:

   ```bash
   cd /home/gl00m/dotfiles
   nixos-rebuild build --flake .#gl00m-full --no-write-lock-file
   # Run doctor against the *candidate package*, with an isolated HERMES_HOME.
   ```

   Continue only when it reports no WAL-reset warning.

2. Switch stage 1 manually:

   ```bash
   sudo nixos-rebuild switch --flake /home/gl00m/dotfiles#gl00m-full
   ```

3. Verify the backend before opening the remote client:

   ```bash
   systemctl is-active hermes-agent.service hermes-serve.service
   ss -ltnp | grep ':9119'
   curl -fsS http://127.0.0.1:9119/api/status
   test -r /home/gl00m/.config/Hermes/hermes-remote.token
   ```

4. Launch **Hermes Remote Pilot** from the graphical app menu. Verify real chat, terminal, file read, cron read, LSP, and Linear MCP activity. Confirm only the remote-pilot Desktop process is using the backend and that the original **Hermes** launcher remains available as an immediate fallback.

5. Soak and record health. Do not retire the old path in this stage.

## Stage 2: private state retirement — only after a successful stage-1 soak

Stage 2 must be a separate reviewed generation. It will:

1. make the normal **Hermes** launcher remote-only;
2. remove `gl00m` from `container.hostUsers` and set `addToSystemPackages = false`;
3. remove the legacy `~/.hermes` symlink;
4. stop/disable `hermes-state-permissions.timer`;
5. remove group/other permissions from existing state files and directories;
6. add ordered systemd-tmpfiles `z` rules for `/var/lib/hermes`, `.hermes`, `cron`, `sessions`, `logs`, `memories`, and `plugins` so boot-time tmpfiles does not restore upstream `2770` permissions;
7. only then verify the normal graphical **Hermes** entry and service-owned state.

The explicit tmpfiles step is mandatory: an activation-only `chmod 0700` is not durable because the upstream Hermes module’s tmpfiles rules run afterward and would restore group modes.

## Rollback

### Immediate NixOS generation rollback

```bash
sudo nixos-rebuild switch --rollback
```

This returns to the preceding system generation without deleting SQLite databases, WAL/SHM sidecars, sessions, or auth state.

### Source rollback to the tagged checkpoint

The working tree already contains unrelated uncommitted work (`configuration.nix`, the Linear MCP addition, and `.hermes/`). Preserve it before checking out the tag:

```bash
cd /home/gl00m/dotfiles
git stash push -u -m 'pre-hermes-single-owner-rollback'
git checkout hermes-desktop-timer-working
sudo nixos-rebuild switch --flake /home/gl00m/dotfiles#gl00m-full
```

Never delete canonical state or SQLite WAL/SHM files as a rollback technique.

## Recovery interfaces

- Host `codex` and `claude` stay independent from service state; Claude’s existing host login remains user-private.
- `hermes-recovery` is deliberately separate from canonical production state. It may require its own provider login.
- The backend terminal has Codex/Claude/tmux binaries but intentionally no copied host credentials. If service-side standalone agent auth is desired later, provision a separate SOPS-managed credential with an explicit scope/budget.
