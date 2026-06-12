---
name: claude-code
description: Authoritative reference for what Claude Code can do — surfaces (CLI, desktop, web, VS Code, JetBrains, Slack, GitHub Actions, Channels), built-in slash commands, configuration (settings.json scopes, managed settings, .claude/ structure), extensibility (skills, subagents, MCP, hooks, plugins), and features that move fast (Agent Teams / "A2A", Routines, Dispatch, ultraplan, plan mode, fast mode, /loop, checkpointing, auto memory). Use this skill whenever the user asks "can Claude do X", mentions a Claude Code feature by name (especially obscure or recent ones — Routines, Dispatch, A2A, Channels, ultraplan, Remote Control, Teleport, /powerup, agent teams, teammates, /tp, /rc), asks about enabling/configuring something in Claude Code, references docs.claude.com or code.claude.com, or asks about Anthropic offerings (Claude API, Agent SDK, Claude.ai plans). Trigger especially when you don't recognize a feature name — Claude Code ships multiple times a week, your training data is stale, and the right move is to consult this skill (which points at live docs) before guessing or asking the user "what is X". Companion to claude-api skill (which covers the Anthropic SDK side); this one covers the Claude Code product itself.
---

# Claude Code: knowing your own capabilities

Claude Code ships **multiple updates per week**. Features land, get renamed, get deprecated. You (Claude) almost certainly have stale knowledge from training data, and asking the user "what is X feature" when X is a real, documented thing is embarrassing and unhelpful.

**This skill exists to stop that failure mode.** It tells you (a) where to look, (b) what's actually current as of recent research, and (c) how to recognize features you might not know.

## Prime directive: don't guess at feature names

When a user mentions a Claude Code or Anthropic-product term you don't recognize, the wrong move is "I don't know what X is." The right move is:

1. **Assume it's real** until proven otherwise. Anthropic ships fast; the term probably exists.
2. **Check `references/features.md`** in this skill — it's the most up-to-date catalog I have, including obscure things like Agent Teams (A2A), Routines, Dispatch, Channels, ultraplan, Remote Control, Teleport.
3. **If still unrecognized, fetch live docs** — see `references/live-lookup.md` for URLs. Default starting point: `https://code.claude.com/docs/en/`.
4. **Only ask the user as a last resort**, and if you do, frame it as "I want to verify what you mean before doing anything risky" — not "I have no idea what that is."

A recent embarrassing example: a user asked "Enable Claude A2A Teams." The right answer was to recognize that **A2A = Agent-to-Agent Teams**, an experimental Claude Code feature enabled via `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in `settings.json`'s env block. See `references/features.md`.

## Claude Code surfaces — high-level

Claude Code is one engine across many surfaces. CLAUDE.md, settings, MCP servers, skills, hooks travel with you. Sessions can be moved between them via `/teleport`, `/desktop`, `--remote`.

| Surface | What's it for |
|---------|---------------|
| **Terminal CLI** (Mac/Linux/WSL/Windows) | Default. Full feature set. `!` runs bash inline. |
| **VS Code / Cursor extension** | Inline diffs, `@`-mentions, plan-mode markdown editing, side-by-side review |
| **JetBrains plugin** (beta) | Inline diff viewer, selection sharing |
| **Desktop app** (macOS, Windows x64/ARM64) | Parallel sessions auto-isolated by git worktree, drag-and-drop pane layout, computer use, **Dispatch** (mobile→desktop handoff), GitHub PR auto-fix |
| **Web** (`claude.ai/code`) | Cloud VMs (4 vCPU / 16GB / 30GB), preinstalled toolchains, network access levels, ultraplan |
| **Slack / GitHub Actions / GitLab CI / Chrome extension / Channels (Telegram, Discord, iMessage, webhooks)** | Triggered/event-driven Claude |

See `references/surfaces.md` for what's exclusive to each surface and how to move sessions between them.

## When asked "can Claude do X" — decision flow

1. **Is X a Claude Code feature?** Check `references/features.md` table of contents for the name. If found, you have a starting point — confirm it's still current via the URL listed.
2. **Is X in `references/extensibility.md`?** Skills, subagents, MCP, hooks, plugins are the major extension points.
3. **Is X about configuration?** See `references/settings.md` (settings.json schema, scopes, file locations).
4. **Is X a surface (where Claude runs)?** See `references/surfaces.md`.
5. **Still unrecognized?** Fetch from `https://code.claude.com/docs/en/` (and search the `llms.txt` index there). See `references/live-lookup.md` for the playbook.
6. **Final fallback only**: tell the user you didn't find it documented and ask for a pointer — but only after exhausting steps 1–5.

## Reference map

| File | When to read |
|------|--------------|
| `references/surfaces.md` | User asks where Claude Code runs, how to move a session, what's available in VS Code vs CLI vs Desktop, IDE-specific features |
| `references/extensibility.md` | User asks about skills, subagents, MCP, hooks, plugins, marketplaces, custom commands |
| `references/features.md` | User mentions an unfamiliar feature name (A2A/Agent Teams, Routines, Dispatch, Channels, ultraplan, Teleport, Remote Control, /powerup, /focus, /loop, /schedule), asks about plan/fast/auto modes, checkpointing, /rewind, auto memory |
| `references/settings.md` | User asks about settings.json, .claude.json, MDM/managed config, scopes, file locations, env vars |
| `references/live-lookup.md` | Anything not covered above, or when you suspect the references are stale — this file lists URLs and search patterns |

## When the user says "enable X"

If X is a real Claude Code feature, "enable" usually means one of:

- **A settings.json change** (env var, hook, permission, MCP server) — invoke the **`update-config`** skill, which is built for this. Don't hand-edit settings yourself.
- **A slash command in-session** (e.g. `/fast` toggles fast mode) — tell the user the command and let them run it.
- **An OS-level install** (e.g. install the GitHub app) — `/install-github-app`, `/install-slack-app`.
- **A subscription/plan upgrade** — flag this and don't pretend you can do it.

For the A2A Teams example: enabling means setting `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in the `env` block of settings.json. That's an `update-config` skill invocation, not something to do raw.

## Anthropic product portfolio — quick orientation

Don't conflate these:

- **Claude Code** — this product. CLI/IDE/web/desktop coding agent. Documented at `code.claude.com/docs/en/`.
- **Claude Agent SDK** — Python/TypeScript SDK to build your own agents on top of Claude. Different docs.
- **Claude API** (formerly Anthropic API) — raw model API at `api.anthropic.com`. Includes **Managed Agents** (`/v1/agents`, `/v1/sessions`, `/v1/environments`). The `claude-api` skill covers this.
- **Claude.ai** — the consumer chat product. Has plan tiers: Free, Pro, Max, Team, Enterprise. The "Team" plan is a billing tier — **distinct from "Agent Teams" / "A2A"** which is a Claude Code feature.

## Style guide for answering Claude Code questions

- **Cite docs URLs** when giving non-obvious facts. The user can verify and you stay honest.
- **Quote the exact flag/env var/setting key**, not a paraphrase. "Enable agent teams" is incomplete; "set `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in `settings.json` env block" is complete.
- **Note experimental status** — many recent features are gated. Mention it.
- **Note OS/surface restrictions** — some features only work on macOS, some only in tmux, some not in VS Code's integrated terminal. Check `surfaces.md`.
- **Verify before quoting versions** — don't say "as of v2.1.110" without checking; ship rate is high enough that this rots.

## When this skill itself is wrong

The references in this skill were drafted from research at a specific point in time. If something here contradicts what `code.claude.com` says today, **trust the live docs** and update the reference file. Don't propagate stale information.
