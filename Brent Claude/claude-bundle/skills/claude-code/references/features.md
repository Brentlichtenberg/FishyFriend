# Claude Code features and slash commands

The catalog. Verify against the live `/commands` reference (`https://code.claude.com/docs/en/commands`) before quoting — names get added, removed, and renamed regularly.

## Modes (the big ones)

Permission modes — toggle via `Shift+Tab`:

- **`default`** — confirms risky actions
- **`plan`** — read-only, builds a plan; `/plan [desc]` to enter explicitly
- **`acceptEdits`** — auto-accept file edits, still confirm shell etc.
- **`bypassPermissions`** — full auto (also via `--dangerously-skip-permissions`)
- **`auto`** — classifier-based mode; configured via `autoMode` in settings

Other modes:
- **`/fast`** — fast mode (same model, faster output). Same Opus 4.6, doesn't switch models.
- **`/effort low|medium|high|max|auto`** — reasoning effort. `max` requires Opus 4.6.

## Agent Teams (a.k.a. "A2A" — Agent-to-Agent)

**This is the feature most likely to be the answer when a user mentions "A2A" or "Agent Teams" or "teammates."**

Multiple full Claude Code instances running in parallel on one project, coordinating peer-to-peer.

- **Enable**: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in `settings.json` env block (use the **`update-config`** skill for this).
- **Status**: Experimental, disabled by default. Requires v2.1.32+.
- **Plans**: Pro / Max / Team / Enterprise.

Concept:
- One **lead** instance, N **teammate** instances
- Shared task list at `~/.claude/tasks/{team-name}/` (file-locked claiming, dependency resolution)
- Team config at `~/.claude/teams/{team-name}/config.json` (auto-managed; do not hand-edit)
- Mailbox for direct messages: `message` (1:1) and `broadcast` (all)

Vs subagents: subagents return results to a parent (parent-child). Teammates communicate peer-to-peer and the user can talk to any of them directly.

**Display modes**:
- **`in-process`** (default in plain terminals) — `Shift+Down` to cycle teammates, `Ctrl+T` toggles task list
- **`tmux`** / split-pane — auto if already in tmux; requires tmux or iTerm2 with `it2`. **Not supported in VS Code integrated terminal, Windows Terminal, or Ghostty** — falls back to `in-process`.
- Override via `teammateMode` in `~/.claude.json` or `claude --teammate-mode in-process`

**Hooks**:
- `TeammateIdle` — exit code 2 sends feedback and keeps teammate working
- `TaskCreated` — exit 2 prevents creation
- `TaskCompleted` — exit 2 prevents completion

**Permissions**: teammates inherit the lead's mode at spawn (including `--dangerously-skip-permissions`). Per-teammate mode changeable after spawn but not at spawn time.

**Limitations**:
- `/resume` and `/rewind` don't restore in-process teammates
- One team per session; no nested teams; no leadership transfer
- Token cost scales linearly (5 teammates ≈ 5× tokens)
- Subagent definitions are reusable as teammates but only honor `tools` and `model`, not `skills`/`mcpServers`

Docs: https://code.claude.com/docs/en/agent-teams

## Sessions and history

| Command | What it does |
|---------|--------------|
| `/resume` | Resume a previous session |
| `/rewind` (`/checkpoint`, `/undo`) | Forks conversation and/or code state |
| `/branch` (formerly `/fork`) | Branch the conversation |
| `/rename` | Rename current session |
| `/diff` | Show file diffs |
| `/export` | Export conversation |
| `/recap` | Auto-summary after long absence (≥75 min if `CLAUDE_CODE_ENABLE_AWAY_SUMMARY` set) |

## Workflow / scheduling

These are three **distinct schedulers** — don't conflate:

| Mechanism | Where it runs | When |
|-----------|---------------|------|
| **`/loop [interval] [prompt]`** | In-session | Recurring task within current session. Omit interval → model self-paces. |
| **`/schedule`** | Cloud (Anthropic infra) — "Routines" | Cron-style triggers, run remotely. Independent of your local session. |
| **Desktop scheduled tasks** | Local desktop app | Local cron-like, runs on your machine. |

Other workflow:
- `/ultraplan` — plan in cloud, review in browser, execute remotely or teleport
- `/desktop` — hand off CLI session to desktop app
- `/teleport` (`/tp`) — pull cloud session back to local
- `/remote-control` (`/rc`) — mirror local CLI to claude.ai for phone control
- `/voice` — voice input
- `/tasks` (alias `/bashes`) — view background tasks
- `/autofix-pr` — auto-fix a GitHub PR

## Built-in skills shipped with the CLI

These are real skills (not hard-coded built-ins), available everywhere:

- **`/simplify`** — parallel-agent code review and simplification
- **`/loop`** — recurring tasks
- **`/debug`** — diagnostic helper
- **`/claude-api`** — Claude API / Anthropic SDK skill (also a separate registered skill `claude-api`)

## Init / config / install

- **`/init`** — initialize a new CLAUDE.md from the codebase
- **`/memory`** — manage auto-memory (`autoMemoryDirectory` config)
- **`/permissions`** — manage permissions
- **`/mcp`** — manage MCP servers
- **`/agents`** — manage subagents
- **`/skills`** — manage skills
- **`/hooks`** — manage hooks
- **`/plugin`** — manage plugins
- **`/statusline`** — customize statusline (use the `statusline-setup` agent)
- **`/sandbox`** — sandbox config
- **`/install-github-app`** — install GitHub app
- **`/install-slack-app`** — install Slack app
- **`/team-onboarding`** — onboard new team member
- **`/web-setup`** — set up web Claude Code
- **`/remote-env`** — manage cloud VM environments
- **`/keybindings`** — manage keybindings (also `keybindings-help` skill)
- **`/config`** — interactive settings editor

## Stats / observability

- **`/usage`**, **`/cost`**, **`/extra-usage`**, **`/stats`**, **`/insights`**

## Recent additions worth knowing (2.1.71 → 2.1.110, ~Q1 2026)

- **Routines** (cloud-scheduled tasks via `/schedule`)
- **`/loop`** (in-session recurring)
- **`/team-onboarding`**
- **`/powerup`**
- **Auto memory** (`/memory`, `autoMemoryDirectory`)
- **1M context for Opus 4.6** (default for Max/Team/Enterprise)
- **Opus 4.6 default effort raised to High**
- **Session recap** after 75+ min away (`CLAUDE_CODE_ENABLE_AWAY_SUMMARY`)
- **Checkpointing / `/rewind`** (forks conversation and/or code)
- **Auto-fix PRs**
- **Ultraplan**
- **Dispatch** (mobile-to-Desktop handoff)
- **PowerShell tool** (`CLAUDE_CODE_USE_POWERSHELL_TOOL=1`)
- **PID-isolated sandbox** on Linux
- **New hooks**: `CronCreate`, `CwdChanged`, `FileChanged`, `TaskCreated`, `TaskCompleted`, `Elicitation`/`ElicitationResult`, `PreCompact`/`PostCompact`, `PermissionDenied`, `StopFailure`, `TeammateIdle`
- **Channels** (Telegram/Discord/iMessage/webhooks) — admin-gated by `channelsEnabled` and `allowedChannelPlugins`
- **Cache controls**: `ENABLE_PROMPT_CACHING_1H`, `FORCE_PROMPT_CACHING_5M`

## Recently removed / deprecated (don't recommend)

- **`/review`** — deprecated; install `code-review@claude-plugins-official` instead
- **`/vim`** — removed; use `/config` → Editor mode
- **`/pr-comments`** — removed
- **`/output-style`** — removed
- **`/tag`** — removed

## Glossary of feature names that are easy to confuse

- **Subagents** = parent-child specialists, results-only return (built-in: Explore, Plan, general-purpose)
- **Agent Teams (A2A)** = peer-to-peer multi-instance with mailbox (experimental)
- **Routines** = cloud-scheduled cron-like tasks via `/schedule`
- **`/loop`** = in-session recurring task
- **Desktop scheduled tasks** = local desktop cron
- **Channels** = inbound events from Telegram/Discord/iMessage/webhooks
- **Dispatch** = phone → desktop task handoff
- **Remote Control** = mirror local CLI to phone via claude.ai
- **`--remote`** = push session to cloud VM
- **`/teleport`** (`/tp`) = pull cloud session back to local
- **Computer Use** = desktop app feature where Claude clicks/types/screenshots the OS
- **Plan mode** = read-only planning before execution
- **Ultraplan** = cloud plan + browser review + remote execute / teleport
- **Plugins** = installable bundles of skills/agents/hooks/MCP
- **Plugin Marketplace** = source of plugins (`claude-plugins-official` is Anthropic's)

## When asked "what version am I on"

```bash
claude --version
```

Recent changelog: https://code.claude.com/docs/en/changelog (or `/changelog` URL on the docs site).
