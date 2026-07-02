# Agent Layer

Orientation for the AI/agent stack in this repo. What runs where, on which port, and why.

## Running services

| Service | Port | Purpose |
|---|---|---|
| `openai-proxy.service` | 127.0.0.1:11435 | Injects the OpenAI API key (from sops-managed `/run/secrets/openai_api_key`) into requests bound for the OpenAI API. Hermes talks to *this*, not to OpenAI directly, so no cloud key touches the config. |
| `hermes-agent.service` | (no exposed port) | The Hermes agent runtime. Uses `openai-proxy` as its `base_url` for `gpt-5-mini`. |
| Ollama (planned, Step 2) | 127.0.0.1:11434 | Local model inference. Runs in parallel with the proxy on a different port; Hermes can be pointed at either. |

## Config files (source of truth)

| File | What it controls |
|---|---|
| `configuration.nix` (services.hermes-agent block) | Hermes *behavioral* settings: model, toolsets, memory, terminal backend. Also `addToSystemPackages = true` so the `hermes` CLI is on your shell PATH. |
| `modules/agent-services.nix` | Wiring: sops secrets for the OpenAI key, the openai-proxy systemd unit, Hermes's configFile / documents / extraPackages (packages the hermes user + service can invoke). |
| `agents/hermes/config.yaml` | Hermes's own YAML config (base_url etc.). Symlinked in by the hermes-agent module via `configFile`. |
| `agents/hermes/USER.md` | User profile document exposed to Hermes. Symlinked via `documents`. |
| `agents/openai-proxy/openai-proxy.py` | Python script for the key-injection proxy. Run under systemd as user `openai-proxy`, not gl00m. |
| `agents/claude/CLAUDE.md` | Global Claude Code instructions (12-rule framework + coding style). Symlinked to `~/.claude/CLAUDE.md` via `modules/agents.nix`. |
| `agents/claude/settings.json` | Claude Code settings. Symlinked to `~/.claude/settings.json`. |
| `agents/codex/config.toml` | Codex CLI config (project trust + plugin enablement). |
| `agents/tmux.conf` | Shared tmux config used by Hermes's terminal toolset. |

## Invocation

- **Claude Code:** `claude` in a terminal (packaged via `modules/agents.nix`).
- **Hermes:** `hermes` (available system-wide because `addToSystemPackages = true`).
- **Codex:** `codex` (packaged in `configuration.nix` systemPackages).

## Port map — why 11434/11435

- `11434` is Ollama's upstream default. Keeping it there means Ollama tooling elsewhere (e.g. `OLLAMA_HOST`) works with no overrides.
- `11435` was chosen for the OpenAI proxy so it's adjacent to Ollama's port but doesn't collide with it. This is why the two can coexist.

## Not yet wired

- No MCP servers configured. `~/.claude/mcp-needs-auth-cache.json` exists as a stub only.
- Ollama is not installed yet — this document is written ahead of Step 2 to establish the port contract.
