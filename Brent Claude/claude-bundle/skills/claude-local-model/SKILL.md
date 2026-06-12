---
name: claude-local-model
description: Swap Claude Code's haiku and/or sonnet tier to a local llama.cpp server on Ben's RTX 5090 (Gaminator3) while keeping opus (and the untouched tier) on the real Anthropic API. Use this skill any time the user says "switch haiku to my 5090", "use my local model for haiku", "run sonnet on the 5090", "route haiku to Qwen", "switch haiku back to Claude", "go back to real Claude", "put haiku back on Anthropic", "stop using my local model", "point haiku at my own GPU", or anything that sounds like moving a specific Claude model tier onto/off of local inference. Also use when the user asks what's currently routed where, whether the local proxy is running, or wants to change which local model serves a swapped tier. Owns the LiteLLM proxy on localhost:4000, the swap state file, and the ANTHROPIC_BASE_URL entry in ~/.claude/settings.json. Delegates all RTX 5090 / llama-server lifecycle to the `llama-cpp-rtx5090` skill — never hardcode 5090 endpoints, ports, or SSH details; always read them from that skill.
---

# claude-local-model

Swap Claude Code's **haiku** or **sonnet** tier onto a local llama.cpp server (default: Qwen3.6-27B on Ben's RTX 5090) without taking opus or the other tier offline. This is not an all-or-nothing cut-over — each tier is controlled independently.

## Why a local proxy

Claude Code has no per-tier base URL. `ANTHROPIC_BASE_URL` redirects *everything*, and `ANTHROPIC_DEFAULT_{HAIKU,SONNET,OPUS}_MODEL` only changes the model *name* sent in the request. So "haiku to 5090, everything else to Anthropic" cannot be done with env vars alone.

The fix: run a tiny **LiteLLM proxy on `localhost:4000`** that speaks the Anthropic Messages API (`/v1/messages`). Claude Code talks to the proxy; the proxy fans requests out by model name — swapped tiers go to the 5090, everything else passes through to `api.anthropic.com`. When no tier is swapped, the proxy is stopped and `ANTHROPIC_BASE_URL` is removed, so the user is back to vanilla Claude Code with zero overhead.

llama.cpp's `llama-server` supports the Anthropic Messages API natively (shipped early 2026), so no second adapter is needed on the 5090 side. LiteLLM can hit it directly as `anthropic/<alias>` with `api_base=http://<5090>:8080`.

## What the skill owns vs. delegates

**This skill owns:**
- `~/.claude-local-model/` — state file, LiteLLM config, pidfile, log.
- `scripts/swap.py` — the orchestrator. Anything that changes swap state goes through it.
- The `ANTHROPIC_BASE_URL` entry in `~/.claude/settings.json`.
- Starting/stopping the LiteLLM proxy.

**Delegates to `llama-cpp-rtx5090`:**
- Everything about the 5090: SSH host, llama-server URL/port, which GGUF to serve, how to spin it up/down, how to check if it's running, what model alias to pass. Load that skill whenever a swap touches the 5090.

## The flow when the user says "switch haiku to my 5090"

Work through this in order. Don't skip the delegation to `llama-cpp-rtx5090` — the endpoint and model alias live there, and they can change.

1. **Parse intent.** Extract:
   - `tier` — `haiku` or `sonnet`.
   - `target` — `local` (switching to 5090) or `claude` (reverting to Anthropic).
   - `model` — if unspecified, default `qwen3.6-27b` (the dense 27B). If the user says "use the MoE" / "35B-A3B" / "use Qwen MoE", use `qwen3.6-35b-a3b`. Other aliases: pass through verbatim and trust the `llama-cpp-rtx5090` skill to serve that model.

2. **If target is `local`:** consult the `llama-cpp-rtx5090` skill.
   - Ask it for the current server state (is it running, which model is loaded, what's the base URL).
   - If no server is running → tell it to spin up the requested model (default 27B).
   - If a *different* model is running → stop it, then spin up the requested one. Only one llama-server fits in 32 GiB VRAM.
   - If the requested model is already running → reuse it.
   - Take the resulting **upstream URL** (e.g. `http://192.168.1.29:8080`) and the **model alias** the server reports (the `--alias` value — e.g. `qwen3.6-27b`). Do not hardcode either.

3. **Apply the swap** via `scripts/swap.py apply`:
   ```bash
   python3 /Users/benbyrnes/.claude/skills/claude-local-model/scripts/swap.py apply \
     --tier <haiku|sonnet> \
     --target local \
     --model <alias-from-5090-skill> \
     --upstream <url-from-5090-skill>
   ```
   This updates `~/.claude-local-model/state.json`, regenerates `litellm.yaml`, bounces the proxy, and writes `ANTHROPIC_BASE_URL=http://localhost:4000` into `~/.claude/settings.json`.

4. **If target is `claude`:** revert.
   ```bash
   python3 .../scripts/swap.py apply --tier <haiku|sonnet> --target claude
   ```
   `swap.py` will figure out whether any other tier is still swapped. If none are, it stops the proxy and removes `ANTHROPIC_BASE_URL`. Then ask the `llama-cpp-rtx5090` skill to spin the server down (assuming no other tier is using it — check state first).

5. **Tell the user what to do next.** Claude Code reads `settings.json` at **session start**, not mid-session. So the change only kicks in on their *next* Claude Code session. Call that out explicitly: "Restart Claude Code (quit, reopen) to pick this up. This session will keep running on the old routing." Don't lie about it taking effect live.

## Parsing natural language to `tier` + `target`

| User says | tier | target | model (if specified) |
|---|---|---|---|
| "switch haiku to my 5090" | haiku | local | default |
| "route haiku to the MoE" | haiku | local | `qwen3.6-35b-a3b` |
| "use my local model for sonnet" | sonnet | local | default |
| "put haiku back on Claude" | haiku | claude | — |
| "switch haiku back" | haiku | claude | — |
| "go back to real Claude" (no tier) | **ask which tier, or revert both if both are swapped** | claude | — |
| "swap both to 5090" | haiku *and* sonnet | local | default (one `swap.py apply` per tier) |

When the user's phrasing is ambiguous about which tier, check state first (`swap.py status`) and confirm — don't guess.

## Model → upstream resolution

The user only names a *model* (e.g. "Qwen MoE"). This skill doesn't know where it runs — it asks `llama-cpp-rtx5090`. That skill is the source of truth for:

- Which models exist (`qwen3.6-27b`, `qwen3.6-35b-a3b`, and any future additions).
- How to start each one (script paths, Scheduled Task names, VRAM).
- The LAN URL of the server (`http://192.168.1.29:8080` today, but read it fresh).
- The alias the server reports on that model.

If the user ever says "use the OSS 120B" or some model `llama-cpp-rtx5090` doesn't serve, relay that skill's answer and stop — don't invent endpoints.

## Reverting the whole setup

"Go back to normal" / "stop using the 5090 entirely":

```bash
python3 .../scripts/swap.py apply --tier haiku --target claude
python3 .../scripts/swap.py apply --tier sonnet --target claude
# proxy will have stopped and ANTHROPIC_BASE_URL will be gone after the last revert
```

Then tell `llama-cpp-rtx5090` to spin the server down. Then tell the user to restart Claude Code.

## Status

When the user asks "what's my current setup" / "what's routed where":

```bash
python3 .../scripts/swap.py status
```

Returns the state dict, proxy running flag, and whether `ANTHROPIC_BASE_URL` is set. Surface it in plain English — which tier is on what, whether the 5090 is currently being hit.

## First-time setup (one-off, flag if missing)

Before the first swap, verify these are in place. Don't silently try to fix — tell the user what's missing and offer to do it.

1. **LiteLLM installed.** Check with `which litellm` (and `litellm --version`). If missing:
   ```bash
   pipx install "litellm[proxy]"
   ```
   `pipx` isolates the install so LiteLLM's deps don't pollute the user's venvs. If the user doesn't have pipx, `brew install pipx && pipx ensurepath`.

2. **`ANTHROPIC_API_KEY` exported in the shell that launches Claude Code.** The proxy forwards sonnet/opus (and any unswapped tier) to `api.anthropic.com` using this key. `swap.py` inherits the var from Claude Code when spawning LiteLLM, so it needs to be in the environment *at Claude Code launch time* — not just in the current terminal.

   Get one from [console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys), then:
   ```bash
   echo 'export ANTHROPIC_API_KEY="sk-ant-api03-..."' >> ~/.zshrc
   ```
   New terminal + new Claude Code session to pick it up. If the key isn't present when a swap is applied, the proxy will 401 on all Anthropic-bound traffic — verify with `echo $ANTHROPIC_API_KEY` before the first swap.

   (An OAuth-passthrough mode via `forward_client_headers_to_llm_api: true` also works in LiteLLM ≥ 1.81.15 and avoids the separate API key, but it's fiddlier to verify and bills against the user's Claude Max quota in surprising ways. API key is the default here.)

3. **Mac can reach the 5090 on port 8080.** Covered by the `llama-cpp-rtx5090` skill (the firewall rule it adds). Quick probe: `curl -fsS http://192.168.1.29:8080/health` should return `{"status":"ok"}` once the server is up.

## Files and where they live

| Path | Purpose |
|---|---|
| `~/.claude-local-model/state.json` | Per-tier swap state. Source of truth. |
| `~/.claude-local-model/litellm.yaml` | Generated from state. Regenerated on every `swap.py apply`. |
| `~/.claude-local-model/proxy.pid` | PID of the running LiteLLM proxy. |
| `~/.claude-local-model/proxy.log` | Proxy stdout/stderr. First place to look if routing breaks. |
| `~/.claude/settings.json` | Claude Code settings; this skill only touches `env.ANTHROPIC_BASE_URL`. |

## Common failure modes

- **Proxy didn't bind port 4000.** Something else is on it (`lsof -iTCP:4000 -sTCP:LISTEN`), or LiteLLM's config is malformed. Check `~/.claude-local-model/proxy.log`.
- **Unswapped tiers return 401.** `ANTHROPIC_API_KEY` isn't in the proxy's environment. See first-time setup step 2.
- **Swapped tier times out.** The 5090 server isn't reachable from the Mac. `curl http://192.168.1.29:8080/health` from the Mac to confirm; if it fails, defer to `llama-cpp-rtx5090`.
- **Change didn't take effect.** The current Claude Code session was already running when `settings.json` changed. Quit + reopen.

## When to defer to another skill

- Anything about the 5090 server itself (start/stop/health/which model/VRAM/CUDA/flags): **`llama-cpp-rtx5090`**.
- SSH / rsync / cmd.exe-vs-PowerShell mechanics on the PC: **`train-on-rtx5090`** (chained by `llama-cpp-rtx5090`).
- Editing `settings.json` beyond the `ANTHROPIC_BASE_URL` env var (permissions, hooks, other keys): **`update-config`**.
