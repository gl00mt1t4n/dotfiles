# Hermes Single-Owner Backend Migration Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Replace the current `gl00m` + `hermes` shared-runtime-state arrangement with a hermes-owned server architecture: Desktop is a remote client, cron remains gateway-owned, and no interactive host process writes the production Hermes state tree.

**Architecture:** Treat `/var/lib/hermes/.hermes` as an application database, not a shared home directory. The `hermes` service identity owns it mode `0700`; client surfaces reach a long-running Hermes server over loopback HTTP/WebSocket. A separate, client-only Desktop state directory stays under `gl00m`. The messaging gateway and `serve` dashboard are distinct upstream processes, but both run as `hermes` in the same managed container and are the only allowed writers to production state.

**Tech Stack:** NixOS, systemd, Docker persistent container, Hermes Agent 0.19.0, Hermes `gateway`, Hermes `serve` / dashboard HTTP+WebSocket API, Electron Desktop remote-backend mode.

---

## 1. Premise and observed state

### The actual problem

Unix group access solves “may this process open this file?” It does **not** solve “which process owns lifecycle and serialization of this mutable application database?”

The current checkpoint deliberately allows both service and GUI identities to write `/var/lib/hermes/.hermes`:

- `hermes` runs the persistent `hermes gateway run --replace` process.
- `gl00m` currently runs a Desktop-spawned `hermes serve --host 127.0.0.1 --port 0` process.
- Host CLI commands can also modify the same config, sessions, auth, cron, plugin, LSP, and workspace tree.
- `modules/hermes.nix:108-170` repairs resulting group modes on a 30-second timer.

Live evidence collected on 2026-07-24:

```text
PID 212632 hermes  hermes gateway run --replace
PID 165285 gl00m   hermes serve --host 127.0.0.1 --port 0
```

The host alias path `/home/gl00m/.hermes` is also an absolute symlink to
`/var/lib/hermes/.hermes`. It makes accidental direct-mode host clients use
the production database even if they do not inherit `HERMES_HOME`; removing
that link is therefore a required late-stage cutover action.

The timer works as an interim permission bridge, but its broad reconciliation takes about 18–20 seconds and is intentionally eventual. It cannot provide a concurrency boundary for SQLite/WAL files, atomic rewrites, locks, or process-local caches.

There is an additional migration prerequisite: current service logs verify
that the pinned Hermes runtime links SQLite 3.51.2, which Hermes warns is
affected by the SQLite WAL-reset corruption bug. The warning explicitly
recommends SQLite 3.51.3+ (or the cited backports). Because this is a
Nix-pinned package, address it by testing a Hermes flake update in a
disposable build/switch path, never by running imperative `hermes update`.

### The desired boundary

```text
Desktop Electron shell (gl00m) ───────┐
                                       │ HTTPS/loopback HTTP + WebSocket
Dashboard/browser client (gl00m) ─────┼────> hermes `serve` (hermes)
                                       │              │
Messaging platforms ──────────────────┼────> gateway (hermes) ──> cron (hermes)
                                       │              │
Admin maintenance only ───────────────┘              └──> /var/lib/hermes/.hermes

Desktop client-only files: /home/gl00m/.config/Hermes and a dedicated client HERMES_HOME
Authoritative runtime state: /var/lib/hermes/.hermes, hermes:hermes, 0700
```

The correct success criterion is **one authoritative state owner**, not necessarily one Linux PID. Current upstream documentation explicitly describes `hermes serve` as the Desktop backend and the messaging gateway as a separate process. Both must therefore be supervised under the same `hermes` identity. Desktop and host CLI must no longer be independent state writers.

### Upstream capability findings

1. Hermes Desktop officially supports a remote backend. Official Desktop docs state that the default Desktop launch starts a local backend, but `Settings → Gateway → Remote gateway` attaches to a running `hermes serve` process. The packaged Desktop implementation confirms remote URL/token/OAuth support and bypasses local spawning when remote is selected.
2. `hermes serve` is an HTTP/WebSocket backend used by Desktop and remote clients. It exposes `/api/status` and `/api/ws`; live inspection found the current Desktop local server on `127.0.0.1:38933`.
3. Cron execution is gateway-owned: the official cron docs say the gateway daemon ticks the scheduler every 60 seconds and holds `~/.hermes/cron/.tick.lock`.
4. The upstream architecture documents SQLite/FTS5 session persistence and describes CLI, gateway, and cron as different execution paths.
5. Current CLI help has no supported “connect this CLI to a remote `serve` backend” option. Do **not** invent one or treat raw `/api/ws` as a stable CLI protocol.
6. Desktop connection configuration belongs to Electron user-data (`/home/gl00m/.config/Hermes/connection.json` on this host), not `HERMES_HOME`. The packaged app stores a remote token in the OS keychain when available; environment overrides are available as fallback.
7. The pinned upstream NixOS module is explicitly designed for filesystem sharing: `container.hostUsers` creates a user `~/.hermes` symlink and `hermes` group membership, while `addToSystemPackages` exports the service `HERMES_HOME` to interactive shells. The migration must deliberately opt out of both mechanisms; changing modes alone is not enough.
8. Even in remote mode, Desktop writes `$HERMES_HOME/logs/desktop.log` and Electron user-data. Therefore the launcher must give Desktop a gl00m-private **client** `HERMES_HOME`, never leave it pointed at production state.

### Important limitation

A fully remote Desktop is supported. A fully remote interactive Hermes CLI is **not validated as a supported feature** in the current 0.19.0 CLI surface. Therefore this migration must not promise that `hermes -z`, `hermes cron`, or arbitrary CLI management commands become transparent remote clients.

The supported operating model after migration is:

- Desktop remote UI and dashboard UI are normal interactive/admin surfaces.
- Gateway owns cron execution and messaging.
- Production CLI state mutations occur only as the `hermes` identity in the managed container and only for explicit maintenance.
- A later upstream-supported remote CLI/client feature can replace that restricted maintenance path.

## 2. Non-goals and constraints

- Keep the dedicated `hermes:hermes` service identity. Do not change the service user to `gl00m`.
- Do not expose Hermes HTTP/WebSocket outside localhost unless a deliberate later security design chooses a VPN/Tailscale/OAuth deployment.
- Do not embed passwords, OAuth tokens, dashboard session tokens, or API keys in the Nix store, desktop entry, or repository. Represent secret values as `[REDACTED]` in documentation/logging.
- Do not delete the existing timer checkpoint until remote Desktop and cron are proven through reboot/restart tests.
- Do not rely on an unversioned raw WebSocket script as a permanent CLI substitute.
- Do not run a second container against the production Hermes data volume. Upstream documentation warns that simultaneous containers sharing a Hermes home can corrupt session and memory stores.
- Preserve the existing persistent container until a separately planned security hardening effort addresses its intentional `/:/host:rw`, privileged, PID, and IPC access.

## 3. Proposed end state

### Process ownership

| Role | Runtime identity | Starts/restarts | May write production `HERMES_HOME`? |
|---|---|---|---|
| `hermes gateway run --replace` | `hermes` inside persistent container | Existing NixOS service | Yes |
| `hermes serve --host 127.0.0.1 --port <stable>` | `hermes` inside the same persistent container | New companion systemd/container service | Yes |
| Cron scheduler and job runs | `hermes` via gateway | Gateway | Yes |
| Electron Desktop | `gl00m` | graphical launcher | No |
| Browser dashboard | `gl00m` | browser | No |
| Host `hermes` CLI | `gl00m` | interactive shell | No for production profile; remove/avoid direct production `HERMES_HOME` access |

### Storage ownership

| Path | Owner/mode target | Purpose |
|---|---|---|
| `/var/lib/hermes/.hermes` | `hermes:hermes`, `0700` root; private descendants | authoritative config, sessions, auth, cron, plugins, LSP/runtime state |
| `/var/lib/hermes/workspace` | `hermes:hermes`, least privilege required for intended tool work | managed agent workspace |
| `/home/gl00m/.config/Hermes` | `gl00m:users` | Electron connection/session/keychain metadata |
| `${XDG_STATE_HOME:-$HOME/.local/state}/hermes-desktop-client` | `gl00m:users`, `0700` | Desktop client logs/cache/plugin-local state if Hermes requires `HERMES_HOME` even in remote mode |

### Network boundary

Phase 1 uses loopback only:

```text
hermes `serve` in host-networked persistent container
  bind: 127.0.0.1:<stable-port>
Desktop remote URL: http://127.0.0.1:<stable-port>
```

The stable port must be chosen only after checking actual Nix module/container networking. Do not keep Desktop pointed at a transient `--port 0` instance.

For a future cross-device deployment, use Tailscale or an authenticated non-loopback listener. The official docs require an auth provider for non-loopback binding; OAuth is preferred for internet-reachable endpoints and username/password is only for trusted network/VPN use.

## 4. Implementation plan

### Task 0: Resolve the pinned SQLite WAL-reset prerequisite

**Objective:** Do not expand concurrent backend usage while the pinned Hermes
runtime is linked against the SQLite version that Hermes itself flags as
vulnerable to WAL-reset corruption.

**Files:**
- Modify later, after a successful disposable build: `flake.lock`
- Do not modify: production runtime state during evaluation

**Step 1: Capture a quiesced, verified backup**

Use the Hermes-supported backup/export route where available. Do not copy
live SQLite `-wal`, `-shm`, lock, or PID files as an application-consistent
backup.

**Step 2: Update only the pinned Hermes flake input in a disposable branch or worktree**

Use the Nix-managed update path, then inspect the resulting runtime/version
and service logs. Do not run `hermes update`.

**Step 3: Prove the warning is gone before migration**

After a test switch, check `hermes doctor` and the `hermes-agent.service`
journal. Continue only when the linked runtime is no longer 3.51.2 and no
WAL-reset warning appears for state or cron databases.

### Task 1: Create a disposable remote-backend spike

**Objective:** Prove the exact supported Desktop-to-`serve` authentication flow without modifying the production profile.

**Files:**
- Create: a temporary, ignored spike configuration under `/tmp` or a disposable named Hermes profile
- Do not change: `modules/hermes.nix`

**Step 1: Inspect the current upstream Nix module options and container entrypoint**

Run read-only inspection of the pinned Hermes flake/module. Determine whether it can launch an additional in-container command or whether a companion NixOS service must use `docker exec`.

**Step 2: Start a disposable `hermes serve` as `hermes`**

Use an isolated disposable `HERMES_HOME`, bind only to loopback on a stable test port, and capture only non-secret `/api/status` fields.

**Step 3: Validate Desktop remote connection**

In the Desktop Settings → Gateway UI, point a test-only connection at the disposable server. Verify all of:

```text
GET /api/status reachable
Desktop remote connection established
Desktop chat works over /api/ws
No new local `hermes serve` child is spawned
No write occurs in the production /var/lib/hermes/.hermes tree from Desktop
```

**Step 4: Record authentication result**

Determine, from actual behavior, which configuration works for same-host loopback:

- unauthenticated loopback remote session,
- Desktop-provided token, or
- an explicit basic/OAuth auth provider.

Do not copy a token into a desktop `.desktop` entry or Nix derivation. If an auth secret is required, plan it as a runtime systemd credential/secret with mode `0600` owned by `hermes`.

**Step 5: Remove the disposable environment**

Return the Desktop setting to the current known-good local connection if the spike does not pass. Preserve the current checkpoint untouched.

### Task 2: Add a hermes-owned `serve` companion to the persistent container

**Objective:** Make the supported Desktop backend long-lived, deterministic, and owned by `hermes`.

**Files:**
- Modify: `modules/hermes.nix`
- Potentially create: a narrowly scoped helper script under the Nix module only if the upstream module cannot supervise a second in-container process directly

**Step 1: Choose supervision method from the spike findings**

Preferred: a NixOS `hermes-dashboard.service` that:

- `Requires=` and starts `After=hermes-agent.service`;
- executes `docker exec` into the already-created persistent container;
- explicitly runs as the container’s `hermes` identity, not host `gl00m`;
- invokes the versioned in-container `/data/current-package/bin/hermes serve` path;
- binds `127.0.0.1` on a fixed port;
- restarts on failure and stops cleanly before container shutdown.

If upstream exposes a declarative second-process option, use it instead of `docker exec`.

Do not start a second persistent container for this server: it would create the exact shared-volume multi-container condition upstream warns can corrupt Hermes session and memory stores.

**Step 2: Keep authentication and bind scope deliberate**

For localhost-only mode, retain loopback binding and validate Desktop behavior. Do not use `--insecure` as an auth bypass. For any non-loopback mode, add an explicit auth provider and secret provisioning design before enabling the listener.

**Step 3: Verify process identity and persistence**

Run:

```bash
systemctl is-active hermes-agent.service hermes-dashboard.service
ps -o pid,user,cmd -C python3.12
curl -fsS http://127.0.0.1:<port>/api/status | jq '{gateway_running,auth_required,auth_providers,hermes_home}'
```

Expected:

```text
one `gateway run` process as hermes
one `serve` process as hermes
both report /var/lib/hermes/.hermes as the production state root
```

### Task 3: Convert Desktop to a pure remote client

**Objective:** Desktop stops spawning a `gl00m` backend and stops using production `HERMES_HOME` as its local runtime directory.

**Files:**
- Modify: `modules/hermes.nix:11-22` (Desktop wrapper and desktop entry)

**Step 1: Change the launcher contract**

Replace the current production-state export:

```text
HERMES_HOME=/var/lib/hermes/.hermes
```

with a gl00m-local client-only directory based on `XDG_STATE_HOME`/`HOME`. Set `HERMES_DESKTOP_REMOTE_URL` to the fixed loopback `serve` URL only after Task 1 proves the authentication configuration.

Never set a static remote token in the generated desktop entry. Let Desktop save its authenticated connection in the Electron keychain/user-data, or use a runtime-only secret mechanism justified by the spike.

**Step 2: Make accidental local fallback visible**

Add launch-time guards/logging that fail clearly if Desktop tries to create a local Hermes backend in the client-only directory. Do not silently fall back to a local server, because that recreates the multi-writer problem.

**Step 3: Test Desktop lifecycle**

From the graphical launcher:

```text
Desktop opens and connects to the fixed remote URL.
Desktop creates/resumes a session.
Desktop settings/cron UI works.
No gl00m-owned `hermes serve` exists.
No new gl00m-owned files appear in /var/lib/hermes/.hermes.
```

### Task 4: Remove host production-state access from the ordinary CLI

**Objective:** Stop `gl00m` CLI commands from opening or mutating the production state directory.

**Files:**
- Modify: `modules/hermes.nix`
- Potentially modify: shell aliases or a dedicated wrapper package, only after deciding the user-facing command names

**Step 1: Inventory commands that currently require direct state**

Classify `hermes` commands into:

- client-safe via Desktop/dashboard/API UI;
- maintenance-only actions that must run inside the container as `hermes`;
- unsupported remote-CLI operations requiring upstream support.

At minimum include: chat, sessions, cron create/list/edit/run, model/config, plugins, auth/login, backups, update, LSP, and gateway lifecycle.

**Step 2: Choose explicit maintenance ergonomics**

Provide a clearly named `hermes-service`/`hermes-admin` wrapper for rare maintenance that executes in the container as `hermes`. It must not masquerade as a remote client and must not run while an operation requires exclusive state access unless documented.

Do not retain an unqualified host `hermes` command pointing to production `HERMES_HOME`.

**Step 3: Prefer server UI for normal operations**

Use remote Desktop/dashboard for sessions, configuration, and cron management. This makes the normal user path API-mediated instead of a second direct state writer.

**Step 4: Decide policy for host CLI**

Choose one and document it:

1. remove it from the normal host PATH;
2. retain it only for an isolated local profile under `~/.hermes` for experimentation; or
3. reserve a stable, upstream-supported remote client mechanism if one becomes available.

Do not claim option 3 until it is implemented upstream and validated against the pinned version.

### Task 5: Tighten filesystem ownership and delete the timer

**Objective:** Make shared state private because it is no longer shared.

**Files:**
- Modify: `modules/hermes.nix:103-170`
- Remove: `hermes-state-permissions.service` and `hermes-state-permissions.timer`

**Step 1: Stop and disable the timer only after Tasks 2–4 pass**

Do not remove the working timer during the remote-backend spike.

**Step 2: Restore strict modes**

Use declarative tmpfiles/activation handling for initial ownership only:

```text
/var/lib/hermes              hermes:hermes 0700
/var/lib/hermes/.hermes      hermes:hermes 0700
/var/lib/hermes/workspace    hermes:hermes 0700 or the least privilege required by agent workspaces
```

Leave `.env` private and do not make auth material group-readable.

**Step 3: Remove `container.hostUsers = [ "gl00m" ]`**

Only remove it after confirming it is no longer needed for Desktop, host CLI, or host workspace access. This removes the primary shared-group bridge.

**Step 4: Regression test permission denial intentionally**

As `gl00m`, verify that direct reads/writes of production auth, cron, and session files fail. Then verify Desktop and remote dashboard operations still succeed.

### Task 6: End-to-end failure and rollback validation

**Objective:** Prove the new architecture handles real lifecycle events without reintroducing multi-writer state.

**Files:**
- Modify: `modules/hermes.nix` only if validation reveals a concrete defect
- Create: optional documented smoke-test script under the repository’s existing test convention, if one exists

**Step 1: Functional tests**

1. Start Desktop from graphical launcher; create a chat; verify it appears in the remote server session list.
2. Create/list/run a cron through the remote UI; confirm gateway executes it as `hermes`.
3. Restart the gateway service; confirm the companion `serve` server and Desktop reconnect correctly.
4. Restart the companion `serve` service; confirm gateway cron remains available and Desktop reconnects.
5. Reboot; verify both services, Desktop remote connection, authenticated provider access, and cron scheduler state.
6. Verify only `hermes` owns production state files after each action.
7. Verify no `gl00m` `hermes serve` process exists after Desktop launch.

**Step 2: Failure tests**

1. Stop `serve`; Desktop must show an actionable remote-backend failure, not silently spawn local Hermes.
2. Block the loopback port temporarily; Desktop must fail closed and preserve current connection configuration.
3. Ensure a malformed/missing auth configuration for non-loopback binding fails closed.
4. Start a host CLI against an isolated profile; prove it cannot alter `/var/lib/hermes/.hermes`.

**Step 3: Rollback**

Keep tag `hermes-desktop-timer-working` as the rollback point. A rollback must:

1. restore the previous Nix generation or revert only the single-owner migration commit;
2. restart `hermes-agent.service` and re-enable the permission timer;
3. restore the previous Desktop wrapper using production `HERMES_HOME`;
4. validate `hermes cron list` and a one-shot inference before declaring rollback complete.

## 5. Acceptance criteria

The migration is complete only when all statements are true:

- `/var/lib/hermes/.hermes` is private to `hermes`; `gl00m` cannot directly read its auth, session, or cron files.
- `/home/gl00m/.hermes` no longer resolves to the production state root.
- Exactly no Desktop-spawned or host-CLI-spawned `hermes serve` process runs as `gl00m` against production state.
- A supervised `hermes serve` and the existing gateway run as `hermes` in the persistent container.
- Desktop connects in remote mode to the supervised server and does not fall back to local mode.
- Gateway-owned cron survives a service restart and executes as `hermes`.
- The permission repair service/timer has been removed from the activated configuration.
- Nix flake checks, system build, post-switch service checks, Desktop GUI smoke test, cron test, and inference test pass.
- A new, accurately named commit/tag documents the single-owner architecture; the current `hermes-desktop-timer-working` tag remains available as rollback.

## 6. Risks, decisions, and open questions

1. **Remote Desktop authentication on same-host loopback is unproven in this deployment.** The official docs clearly support remote Desktop plus auth providers, but the exact no-auth loopback/token behavior must be proven in Task 1. Do not ship a guessed token mechanism.
2. **Gateway and `serve` remain two upstream processes.** This is an upstream design boundary. The plan removes Desktop/host CLI as filesystem writers; it does not claim Hermes currently offers one literal PID for gateway, web server, cron, and every chat.
3. **CLI parity is the main product gap.** The current CLI help does not expose a supported remote-backend client mode. The recommended migration changes the normal interactive surface to Desktop/dashboard and limits direct CLI mutation to explicit service maintenance.
4. **The existing container is privileged and mounts `/` read/write.** State ownership migration improves correctness and confidentiality of Hermes state, not containment. Container privilege reduction is a separate, potentially breaking security project.
5. **Do not commit dashboard credentials in Nix.** If a remote auth provider is required, inject secret values at runtime with a NixOS-compatible secret manager/systemd credentials, or use Nous OAuth registration. Keep all values `[REDACTED]` in plans and logs.
6. **Desktop client state still exists.** Electron’s connection metadata lives under the user’s GUI config directory. That is acceptable because it is client metadata, not authoritative Hermes sessions/auth/cron state; protect it as `gl00m` private state.
