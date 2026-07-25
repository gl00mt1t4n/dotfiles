# Hermes Single-Owner Backend and Recovery Access Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Replace the current cross-user, group-writable Hermes runtime with a service-private `hermes:hermes` canonical state and a Desktop remote-client connection, while retaining a verified rollback path and an independent debugging/coding escape hatch.

**Architecture:** Keep one canonical `/var/lib/hermes/.hermes` owned only by the persistent container/service identity (`hermes:hermes`). Run the upstream-supported Desktop backend (`hermes serve`) as a separately supervised companion in that *same existing container* and connect the Electron Desktop as a saved remote client over host-loopback. The messaging gateway and the serve backend remain separate upstream processes, but no longer cross UID/group ownership boundaries. Keep the user-facing Codex/Claude/Hermes CLIs independent of canonical production state; optionally expose explicitly provisioned recovery CLIs through the service terminal only after credentials and isolation are validated.

**Tech Stack:** NixOS flake/module, Docker host networking, systemd, Hermes Agent v0.19+, Hermes Desktop remote gateway mode, SQLite, SOPS-managed service secrets, Codex CLI, Claude Code, tmux.

---

## Scope and evidence collected

### Linear requirements

- **GL0-5 — Design Hermes single-owner backend architecture**: migrate from group-shared state and the 30-second permission repair timer; validate remote Desktop; make `hermes` the only owner; define migration, acceptance tests, rollback, and timer/symlink retirement.
- **GL0-6 — Investigate and upstream**: reproduce/document current Nix module behavior, establish whether remote Desktop is supported, verify CLI/cron/workspace/auth/SQLite/LSP implications, identify upstream ownership, and prepare a sanitized issue only after maintainers’ direction.

### Actual local state (2026-07-25)

- `/home/gl00m/dotfiles/modules/hermes.nix` launches a Docker-host-networked persistent Ubuntu container through `hermes-agent.service`.
- The in-container gateway runs as `hermes` and is healthy: `hermes gateway run --replace`.
- The desktop wrapper exports `HERMES_HOME=/var/lib/hermes/.hermes`; the running Electron Desktop consequently spawned a *second* `hermes serve --host 127.0.0.1 --port 0` as `gl00m` against the same state.
- `/var/lib/hermes/.hermes` is currently `2770 hermes:hermes`; `state.db` is `0664` and `auth.json` is `0660`. `gl00m` belongs to `hermes`. `state.db` and `kanban.db` use WAL; copied/read-only checks returned `integrity=ok` at investigation time, which is a baseline rather than proof of safety under continued split ownership.
- `hermes-state-permissions.timer` walks and changes group permissions every 30 seconds, including the large `lsp/node_modules` tree. It was actively scanning the state tree during investigation.
- The installed package is Hermes **v0.19.0**. `hermes doctor` reports SQLite **3.51.2**, which it flags as vulnerable to the SQLite WAL-reset bug. Do not migrate the live production DB while that warning remains.
- `codex` 0.130.0 and `claude` 2.1.137 are already installed for `gl00m`; Claude has an active user login. `tmux` is declared by Home Manager but was not currently on the invoking shell PATH. The service container currently has none of `codex`, `claude`, or `tmux` on PATH.
- The Git working tree is already dirty: `modules/hermes.nix` has an unrelated/uncommitted Linear MCP addition, `configuration.nix` has an unrelated sudo timestamp policy addition, and `.hermes/` is untracked. This migration must not absorb, overwrite, or accidentally commit any of them.

### Upstream findings that constrain the design

1. Hermes documents an explicit remote Desktop flow: a **running `hermes serve`** backend, kept alive by the operator/systemd, is selected in **Desktop → Settings → Gateway → Remote gateway**. Gateway messaging remains a separate long-running process. Source: `website/docs/user-guide/desktop.md`, “Connecting to a remote backend”.
2. Remote mode makes the server the execution boundary: terminal, tools, and file operations occur on the remote server, not the computer rendering Desktop. This is desirable for the service-owned production backend but means local break-glass tooling must be deliberately separate.
3. Remote Desktop is not an experimental protocol: upstream has active remote-mode work including PRs #62575 (remote-only Desktop build), #69059 (remote restart readiness), and #69061 (multi-client session synchronization). These are useful evidence, but they are **open**, not a dependency to assume merged.
4. Upstream’s Docker documentation warns never to run two **gateway containers** against one mutable data directory. This deployment will retain only one gateway/container. It must still test `gateway + serve` concurrent behavior because both are stateful processes.
5. The current NixOS module intentionally supports shared state: `container.hostUsers`, `addToSystemPackages`, a `~/.hermes` symlink, group-writable paths, and `UMask=0007`. This is the direct upstream module scope for the proposed enhancement. Existing related reports include #9383, #14181, #29660, #68055, and #59706; none is the precise service-private/remote-Desktop mode requested here.
6. A different PID/UID problem is being solved from a different class of SQLite problem. Moving Desktop from `gl00m` to a remote `hermes` backend removes cross-UID permissions/atomic-replace races, but it does **not** prove two Python processes can safely write all shared state. The upstream remote architecture expects a separate `gateway` and `serve`; the pilot therefore needs functional and integrity tests, and migration is blocked on the doctor SQLite warning.

## Non-goals

- Do not change the Hermes service user to `gl00m`.
- Do not expose the service backend beyond loopback during the first migration.
- Do not remove existing state, auth, sessions, cron jobs, or the working directory.
- Do not use a second container with the same canonical data directory.
- Do not call a newly created service `serve` companion “single process” or claim it eliminates all SQLite concurrency risk.
- Do not put Codex/Claude user auth files or API secrets into the shared/canonical state as a shortcut.

## Proposed decision

Proceed only with a **two-stage, rollback-first migration**:

1. Upgrade or otherwise validate a Hermes/Nix closure whose embedded SQLite passes `hermes doctor`; then use an isolated pilot profile/state to prove the exact Desktop remote handshake and service supervision.
2. Move the production Desktop to that remote backend while retaining the old launcher/timer/symlink configuration in a dedicated rollback commit. Remove the shared-state bridge only after a defined soak period and clean integrity/ownership evidence.

The recommended service topology is:

```text
Electron Desktop (gl00m; client-only preferences in ~/.config/Hermes)
      | authenticated HTTP/WebSocket over 127.0.0.1:<fixed-port>
      v
systemd hermes-serve companion ─ docker exec as hermes ─ same existing container
      |                                            |
      |                                            v
      |                               /data/.hermes (0600/0700 hermes:hermes)
      v
existing hermes gateway process (same container/service identity)
      |
      └── messaging + cron
```

Use a fixed loopback port (not `--port 0`) for a systemd-managed service. Use basic auth or a supported OAuth provider even on loopback until the Desktop connection test demonstrates exactly which standalone-loopback authentication contract applies. Store only service-side auth configuration in the existing SOPS-managed service secret flow; store the Desktop’s remembered remote connection in its user-private Electron configuration.

---

### Task 1: Create a clean migration baseline and explicit rollback point

**Objective:** Make it impossible for this work to overwrite the current working setup or unrelated uncommitted changes.

**Files:**
- Modify: `modules/hermes.nix` (only in a new, narrowly scoped migration commit)
- Preserve: current uncommitted Linear MCP block in `modules/hermes.nix`
- Preserve: untracked `.hermes/`
- Create: `docs/hermes-single-owner-runbook.md` (or a clearly named equivalent in the repo)

**Step 1: Record baseline, without staging unrelated changes**

Run:
```bash
git -C /home/gl00m/dotfiles status --short
git -C /home/gl00m/dotfiles diff -- modules/hermes.nix
git -C /home/gl00m/dotfiles rev-parse HEAD
systemctl status hermes-agent.service --no-pager
docker exec hermes-agent /data/current-package/bin/hermes doctor
```

Expected: the only known tracked edit is the Linear MCP addition; no migration files are staged; doctor warning is captured.

**Step 2: Make a recoverable snapshot before any switch**

Use Hermes’ supported backup mechanism from the service context, save the produced archive outside the canonical state, and record its checksum and restore command in the runbook. Also record the active Nix generation and flake lock revision.

**Step 3: Commit the current known-good shared-state configuration separately**

Create a commit containing only the intentional pre-existing `modules/hermes.nix` change(s), or explicitly stash/restore those changes before the migration branch. Do not commit `.hermes/` runtime output.

**Step 4: Create a migration branch and a `shared-state-last-known-good` tag**

The tag must point at the exact configuration that launches Desktop successfully from the graphical application menu and has a healthy gateway.

**Step 5: Verify rollback mechanics before changing architecture**

From a test branch, demonstrate that checking out the tag plus `nixos-rebuild switch --flake /home/gl00m/dotfiles#gl00m-full` restores the current Desktop launcher, service, timer, and symlink behavior. Return to the migration branch without editing runtime state.

**Step 6: Commit**

```bash
git add docs/hermes-single-owner-runbook.md
git commit -m "docs: record Hermes shared-state rollback baseline"
```

---

### Task 2: Resolve the SQLite release gate before touching production state

**Objective:** Ensure the future production package does not retain the doctor-reported WAL-reset vulnerability.

**Files:**
- Modify only if required after investigation: `flake.lock`, `flake.nix`, or a dedicated narrowly-scoped Nix package override
- Test: documented commands in `docs/hermes-single-owner-runbook.md`

**Step 1: Write the failing release gate**

Add a runbook check that fails if the service package reports a vulnerable SQLite version:
```bash
docker exec hermes-agent /data/current-package/bin/hermes doctor
```

Expected current result: warning for SQLite 3.51.2 and WAL-reset bug.

**Step 2: Identify the smallest declarative remediation**

Evaluate the current flake revision against upstream fixes, especially #70200 and the container-image concern #70480. Do not assume updating the lock alone fixes this Nix/container closure; build the candidate closure and inspect the actual runtime used by `hermes doctor`.

**Step 3: Rebuild an isolated candidate, not live production**

Use a Nix build/evaluation and a temporary candidate service/container/state path. Do not run a general `hermes doctor --fix` against the production service because it is package-managed and the live state is canonical.

**Step 4: Verify the candidate runtime**

Run `hermes doctor` in the candidate environment. Expected: no SQLite WAL-reset warning. Confirm the runtime sees the same sealed interpreter that will run gateway and serve.

**Step 5: Preserve the fallback**

If no safe closure is available, stop here. Keep the current service untouched, document the blocker in GL0-5/GL0-6, and upstream the Nix/container-specific version evidence. Do not paper over the warning by forcing journal mode or deleting WAL sidecars.

**Step 6: Commit**

```bash
git add flake.lock flake.nix modules/hermes.nix docs/hermes-single-owner-runbook.md
git commit -m "fix(hermes): use SQLite-safe runtime closure"
```

Only stage files actually changed by the validated remediation.

---

### Task 3: Prove the upstream remote-Desktop flow in isolated state

**Objective:** Validate Desktop remote mode, authentication, and restart behavior without accessing production canonical state.

**Files:**
- Create: a pilot-only Nix module or clearly gated service configuration (exact path selected after inspecting the project’s module conventions)
- Modify: `docs/hermes-single-owner-runbook.md`

**Step 1: Create a separate pilot Hermes state and port**

Use a non-production state directory, a non-production profile name, and a fixed loopback-only port. It must not symlink `~/.hermes`, must not use `container.hostUsers`, and must not point at production auth/session/cron databases.

**Step 2: Start one pilot `gateway` and one supervised pilot `serve` backend**

Run `serve` as `hermes` inside the same pilot container identity. Prefer a dedicated systemd unit whose lifecycle is coupled to `hermes-agent.service` (`Requires=`, `After=`, `PartOf=`); never a user-launched background process.

**Step 3: Configure an authentication test**

Use a service-private credential provisioned through the declarative secret mechanism. Verify:
- `127.0.0.1:<pilot-port>/api/status` requires/supplies the expected auth behavior;
- Desktop can perform both HTTP and WebSocket connection tests;
- no raw static token or password is added to Git, shell history, logs, or the Desktop launcher.

**Step 4: Configure Desktop in remote mode**

Launch the existing graphical Desktop app, select **Settings → Gateway → Remote gateway**, set the loopback pilot URL, sign in, save/reconnect, and close/reopen Desktop. Confirm the saved remote connection is retained in user-private Desktop preferences, not in pilot or production `HERMES_HOME`.

**Step 5: Prove execution placement and client separation**

Create a harmless marker via a Desktop chat terminal/file operation and verify it is created in the pilot backend workspace as `hermes`, not under `/home/gl00m` or the production workspace. Confirm Desktop no longer spawns a local `hermes serve` for this remote profile.

**Step 6: Restart tests**

Restart the pilot serve companion, then the pilot gateway/container. Verify Desktop reconnects, a new session works, and no `gl00m` process opens the pilot SQLite files. Capture `journalctl`, Docker logs, and Desktop logs with secrets redacted.

**Step 7: Integrity and ownership tests**

After concurrent gateway/serve activity, run read-only SQLite `quick_check`/`integrity_check` on a stopped copied pilot DB, inspect WAL/shm sidecars, and verify all pilot state is `hermes:hermes` with no group write. Exercise a pilot cron job and confirm it persists/runs through the gateway.

**Step 8: Pilot failure criteria**

Abort the production migration if any of the following occurs: Desktop needs direct `HERMES_HOME` access; remote HTTP/WS cannot authenticate reliably; restart loses sessions; serve/gateway contention produces DB errors; a service process creates group-accessible secrets; or the SQLite release gate fails.

---

### Task 4: Implement production service-private state mode

**Objective:** Replace the shared-state launcher, symlink, and repair timer only after pilot acceptance.

**Files:**
- Modify: `modules/hermes.nix`
- Modify: `docs/hermes-single-owner-runbook.md`
- Test: Nix evaluation/build plus service/desktop smoke evidence

**Step 1: Stop exporting canonical `HERMES_HOME` to interactive users**

Set `services.hermes-agent.addToSystemPackages = false` (or use an equivalent upstream-supported service-private option if landed). Remove `container.hostUsers = [ "gl00m" ]` only after identifying a replacement that does not alter the `gl00m` Home Manager declaration.

**Step 2: Replace the Desktop launcher with client-only semantics**

Remove the wrapper’s export of `/var/lib/hermes/.hermes`. Keep the graphical app menu launcher, but configure the Desktop to use its saved remote backend. If upstream lands the standalone remote Desktop artifact (#62575), evaluate it separately; do not block this plan on that currently-open PR.

**Step 3: Add a supervised serve companion**

Create a host systemd unit that runs `docker exec` into **the already existing** `hermes-agent` container as the `hermes` identity:
```text
hermes serve --host 127.0.0.1 --port <fixed-production-port>
```

Require/start after the container gateway unit; stop it before/restart it with the container; bound restart rate; avoid `--port 0`; log to a service-owned location; do not create a second container or mount production state into a `gl00m` process.

**Step 4: Keep canonical state private**

After switching, make production state owner-only (expected directories `0700`, secrets/DB sidecars `0600`, no group write) and remove group traversal for `gl00m`. Confirm `gl00m` cannot read `auth.json`, `state.db`, cron definitions, or service private MCP token caches.

**Step 5: Retire the permission-repair timer and shared bridge**

Remove `hermes-state-permissions.service`, `hermes-state-permissions.timer`, and the broad group repair scan only after Desktop/gateway/cron tests pass. Remove the `~/.hermes` symlink only once host CLI behavior is explicitly redirected to the documented maintenance/recovery path.

**Step 6: Narrow the container attack surface as a separate reviewed follow-up**

The current `--privileged`, `--pid=host`, `--ipc=host`, and `/:/host:rw` grants are not required to prove remote Desktop. Do not mix their removal into the state migration. Create a follow-up issue/plan to inventory actual tool requirements and reduce mounts/capabilities one at a time with rollback tests.

**Step 7: Commit**

```bash
git add modules/hermes.nix docs/hermes-single-owner-runbook.md
git commit -m "feat(hermes): make production state service-private"
```

---

### Task 5: Validate production cutover, soak, and rollback

**Objective:** Establish that the new architecture works and that reverting it works before declaring the timer retired.

**Files:**
- Modify: `docs/hermes-single-owner-runbook.md`

**Step 1: Pre-cutover checkpoint**

Take another supported Hermes backup and record state DB size/checksum, Nix generation, commit, and Desktop remote connection state (without copying tokens).

**Step 2: Switch declaratively**

Run the standard flake switch. Verify unit enablement, container restart, serve companion health, fixed loopback listener, and Desktop remote reconnection.

**Step 3: Acceptance matrix**

| Surface | Required evidence |
|---|---|
| Gateway | remains active across container restart; can complete an inference turn |
| Desktop | launch from graphical app menu; attaches to remote URL; does not spawn local serve; can use chat, files, preview, terminal pane, and session resume |
| Cron | create/run a bounded test job through gateway; persists after service restart |
| State | every canonical file/sidecar owned by `hermes:hermes`; `gl00m` has no read/write access; no repair timer exists |
| DB | post-soak copy passes `PRAGMA quick_check`, `integrity_check`, and relevant application checks |
| Auth/MCP | OpenAI Codex and Linear MCP work after restart without exposing their cached credentials to `gl00m` |
| Rollback | tag/previous Nix generation restores old Desktop shared-state behavior and data remains intact |

**Step 4: Soak window**

Maintain the backup, last-known-good tag, and rollback runbook for a defined interval (at least several normal Desktop sessions, one cron execution, and one container restart). Do not delete the old fallback until this window passes.

**Step 5: Execute and verify one rollback drill**

Roll back to the tagged configuration in a controlled maintenance window, verify Desktop/gateway state continuity, then return to the new configuration. This proves that rollback is executable rather than merely documented.

**Step 6: Commit**

```bash
git add docs/hermes-single-owner-runbook.md
git commit -m "docs: verify Hermes single-owner cutover and rollback"
```

---

### Task 6: Provide reliable break-glass assistance without reintroducing shared production state

**Objective:** Ensure the user can still obtain coding/debugging assistance if the primary remote backend fails.

**Files:**
- Modify: `configuration.nix` only if the user chooses a host-side launcher/menu entry
- Modify: `modules/hermes.nix` only if the user chooses service-side agent CLIs
- Modify: `modules/agents.nix` only if needed for an explicit recovery launcher or tmux path
- Create: `docs/hermes-recovery.md`

**Step 1: Preserve the already-independent host escape hatch**

The host already has `codex` and `claude`, and Claude is authenticated as `gl00m`. Document a graphical terminal launcher (Kitty or preferred terminal) that starts a clean tmux session in the intended project. This is the strongest recovery path because it does not depend on the Hermes container, remote backend, or canonical state.

**Step 2: Add a host `hermes --tui` recovery profile only if wanted**

Do **not** point it at `/var/lib/hermes/.hermes`. Give it a separate `HERMES_HOME` under `gl00m` (for example a recovery-only directory), separate credentials, and a bounded/safe tool configuration. This is a distinct emergency assistant, not a production state client.

**Step 3: Decide whether service-terminal Codex/Claude is needed**

Hermes Desktop’s terminal rail and remote-agent terminal tools run on the backend host. To make `codex`, `claude`, and `tmux` runnable there, add the packages through `services.hermes-agent.extraPackages`, which upstream places on the service user’s PATH. This makes executables available, but **does not authenticate the standalone CLIs**.

**Step 4: Treat standalone CLI auth as a separate security design**

- Codex CLI normally uses its own `~/.codex/auth.json`; Hermes’ `openai-codex` provider auth is not automatically a standalone Codex CLI login.
- Claude Code uses service-local Claude OAuth or an `ANTHROPIC_API_KEY`; `gl00m`’s existing Claude login must not be bind-mounted/copied into the service casually.
- Prefer the independent host terminal for interactive Codex/Claude. If backend-side CLIs are necessary, provision separate service-scoped credentials via SOPS and explicitly decide their spend/permission boundaries.

**Step 5: Validate the chosen recovery route**

From the graphical desktop, test: open recovery terminal; attach/create tmux; run `codex --version`, `claude --version`, `claude auth status`; perform a harmless read-only project analysis; simulate a stopped `hermes-agent.service`; and confirm the recovery route still works.

**Step 6: Commit**

```bash
git add configuration.nix modules/hermes.nix modules/agents.nix docs/hermes-recovery.md
git commit -m "feat(hermes): add independent recovery agent access"
```

Only include files corresponding to the option actually selected.

---

### Task 7: Prepare upstream work after local pilot evidence

**Objective:** Upstream a narrow, reproducible design request rather than a local configuration dump.

**Files:**
- Create: `docs/upstream-hermes-service-private-state.md`
- Potential future upstream changes: `nix/nixosModules.nix`, NixOS VM integration test files, Desktop remote-mode docs/tests

**Step 1: Search again immediately before filing**

Re-run focused GitHub searches for `NixOS shared state`, `hostUsers`, `remote Desktop`, `SQLite WAL`, `serve`, and `single writer`. Link related issues rather than duplicating them: #9383, #14181, #29660, #68055, #59706, #70480, #62575, #69059, #69061.

**Step 2: Write a sanitized reproduction**

Use a minimal generic NixOS configuration. Exclude local usernames, paths, OAuth data, host mounts, workspace content, auth files, and privileged-container details.

**Step 3: State the correct request precisely**

Request an opt-in NixOS **service-private-state / remote-Desktop mode**, with:
- `hermes:hermes` owner-only canonical state;
- no `hostUsers` symlink or group-writable interactive state;
- a documented/systemd-supervised `hermes serve` companion or an explicit module option for it;
- Desktop remote connection documentation and test coverage;
- retained backward-compatible shared-state mode for users who deliberately choose it;
- explicit statement that this addresses cross-user ownership, while gateway/serve concurrency still follows upstream SQLite/state guarantees.

**Step 4: Include test expectations**

Propose NixOS VM/integration tests for service boot, loopback serve health, no host-user state access, desktop remote protocol smoke (where feasible), cron persistence, restart behavior, and migration/rollback docs. Coordinate with the existing Nix VM test work in #69496.

**Step 5: Ask maintainers for ownership before a PR**

File the issue in `NousResearch/hermes-agent` because the NixOS module lives there. Do not open a broad PR until maintainers confirm the desired module API and whether the companion service belongs in the module or only documentation/examples.

**Step 6: Update GL0-5/GL0-6 with links and evidence**

Only after local pilot and upstream issue creation, comment with sanitized results, commands, test outcomes, upstream URL, risks, and rollback status.

---

## Risks and tradeoffs

| Proposal | Why it is attractive | Side effects / failure mode | Mitigation / decision gate |
|---|---|---|---|
| Keep current shared state + permission timer | No migration work | Timer cannot serialize SQLite/WAL, cron, sessions, atomic writes, or secrets; scan is expensive and continuously races live mutations | Treat as last-known-good rollback only, not a long-term architecture |
| Desktop remote client + service-private `serve` | Upstream-documented; removes Desktop’s direct state writes; preserves graphical app workflow | Requires stable supervision and an authenticated connection; Desktop tools execute remotely; gateway + serve remain two processes | Isolated pilot, fixed loopback port, auth/WS/restart tests, SQLite-safe runtime gate |
| Separate second container for `serve` with same volume | Seems operationally tidy | Recreates multi-container shared mutable state; conflicts with upstream Docker safety warning | Reject |
| Run Desktop-local `serve` with a new user-local state | Avoids production DB writes | Creates a second disconnected Hermes identity; sessions/auth/MCP/cron no longer production-parity | Suitable only as a recovery profile, not primary Desktop |
| Bind `serve` publicly for convenience | Easy remote access | Full agent command/filesystem authority exposed; password-only access is unsafe on public internet | First phase loopback only; VPN/OAuth only if later remote access is explicitly required |
| Put Codex/Claude credentials in the service container | Makes backend terminal agent CLIs convenient | Couples emergency access to failed service, expands secret scope, risks billing/credential exposure | Prefer independent host CLIs; service credentials only with separate SOPS-scoped accounts and explicit approval |
| Update Hermes closure before migration | Addresses doctor’s WAL warning | May introduce package/module regression | Candidate build + isolated pilot + tagged rollback generation |

## Final acceptance criteria

- [ ] `hermes doctor` on the exact deployed closure has no WAL-reset warning.
- [ ] Production `/var/lib/hermes/.hermes` is owner-private to `hermes:hermes`.
- [ ] Desktop starts from the graphical menu and attaches to a supervised remote `hermes serve`; it does not launch a `gl00m` local serve against production state.
- [ ] Gateway and cron remain operational after container and serve-companion restarts.
- [ ] No permission repair timer, shared `~/.hermes` symlink, or `gl00m` group write to canonical state remains.
- [ ] SQLite integrity checks pass after a real activity/restart soak.
- [ ] A documented rollback to `shared-state-last-known-good` has been executed once successfully.
- [ ] An independent graphical host recovery route can launch Codex/Claude (and, if desired, a separate-state Hermes TUI) while the service is stopped.
- [ ] Upstream issue is sanitized, non-duplicative, and requests maintainer direction before implementation PR work.
