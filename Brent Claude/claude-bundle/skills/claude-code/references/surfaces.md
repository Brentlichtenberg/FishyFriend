# Claude Code surfaces

Claude Code is one engine, many surfaces. The `CLAUDE.md`, `~/.claude/settings.json`, MCP servers, skills, and hooks are shared. Sessions can be moved between surfaces.

Docs root: `https://code.claude.com/docs/en/` (the older `docs.claude.com/en/docs/claude-code/*` paths now 301 here).

## Terminal CLI

The flagship. Mac, Linux, WSL, native Windows. Install paths:

- macOS/Linux: `curl ... claude.ai/install.sh`
- macOS via Homebrew: `brew install --cask claude-code`
- Windows: `winget install Anthropic.ClaudeCode` or native PowerShell installer
- Standalone: download from `https://claude.ai/download`

Has the full feature set. CLI-only goodies:

- `!<command>` — runs bash inline so output lands in the conversation
- Tab completion across files, slash commands, agents, skills
- All flags: `--worktree`, `--teleport`, `--remote`, `--bare`, `--dangerously-skip-permissions`, `--agents '{...}'`, `--teammate-mode <mode>`, etc.

## VS Code / Cursor extension

Marketplace: `anthropic.claude-code`.

Inline features:
- Inline diffs and side-by-side review
- `@`-mentions of files/symbols (`Option/Alt+K`)
- Plan-mode markdown editing in the editor
- Conversation history with **Local** and **Remote** tabs (Remote = your `claude.ai/code` cloud sessions)
- Checkpointing + `/rewind` integration
- `vscode://anthropic.claude-code/open?prompt=...` URI handler
- Built-in **`ide` MCP server** with tools: `mcp__ide__getDiagnostics` (read editor diagnostics), `mcp__ide__executeCode` (execute Jupyter cells)

Limitation: **VS Code's integrated terminal does not support tmux/split-pane mode** (relevant for Agent Teams display).

## JetBrains plugin

IntelliJ, PyCharm, WebStorm, GoLand, etc. Plugin id 27310. **Beta** as of 2026.

Features: interactive diff viewer, selection context sharing. Less mature than the VS Code extension.

## Desktop app

macOS, Windows x64, Windows ARM64. Download: `https://claude.ai/download`.

Desktop-exclusive features:
- **Parallel sessions** — auto-isolated by git worktree per session
- **Drag-and-drop pane layout** — terminal + editor + preview side-by-side
- **Side chats** — branch a conversation without polluting the main thread
- **Computer use** — Claude controls the desktop UI (clicks, screenshots, keystrokes)
- **Dispatch** — queue tasks from your phone; they run on the desktop
- **GitHub PR monitoring** — auto-fix, auto-merge, auto-archive workflows
- **SSH sessions** — connect to remote machines
- **Scheduled tasks** — local cron-like scheduling (separate from cloud Routines)
- **`/desktop`** — hand off a CLI session to the desktop app

## Web (`claude.ai/code`)

Cloud-hosted Claude Code sessions in browser. Available on **Pro / Max / Team / Enterprise** (research preview).

Capabilities:
- Cloud VMs: 4 vCPU / 16 GB RAM / 30 GB disk
- Preinstalled toolchains: Python, Node, Ruby, Go, Rust, Java, Docker
- **Per-environment setup scripts** — declarative env provisioning
- **Network access levels**: None / Trusted / Full / Custom — with default allowlist
- **`--remote`** to push a local session to the cloud
- **`--teleport`** / **`/teleport`** / **`/tp`** to pull a cloud session back to local
- **`/ultraplan`** — plan in cloud, review in browser, execute remotely or teleport
- **Auto-fix PRs** via the Claude GitHub App

Also reachable via the Claude iOS app.

## Slack

`@Claude` mention in a Slack channel. Install via `/install-slack-app` from the CLI or via Slack app directory.

## GitHub Actions

Triggered Claude runs from CI. Common pattern: PR-opened → Claude reviews; comment "@claude" → Claude responds. Install via `/install-github-app` or via GitHub Marketplace.

## GitLab CI/CD

Same idea as GitHub Actions; integration via GitLab CI runners.

## Chrome extension

`@browser` — Claude can drive a browser tab. Useful for web-research workflows.

## Channels

Push events from external systems into a Claude session. Supported: **Telegram, Discord, iMessage, generic webhooks**.

Admin-gated by `channelsEnabled` in settings and `allowedChannelPlugins`. Useful for "tell me when X happens and let me ask Claude about it."

## Remote Control

`/remote-control` (alias `/rc`) — distinct from `--remote`. Mirrors a local CLI session to `claude.ai` so you can drive it from your phone.

## Moving between surfaces

| Goal | Command |
|------|---------|
| Local CLI → Desktop app | `/desktop` |
| Local CLI → Cloud VM | `claude --remote` |
| Cloud VM → Local CLI | `/teleport` (also `/tp`) |
| Local CLI → mobile control | `/remote-control` |
| Phone → Desktop | Dispatch (in mobile app) |

## Surface-restricted features (don't recommend on the wrong surface)

- **Agent Teams (A2A)** tmux/split-pane mode: requires tmux or iTerm2 with `it2`. **Not supported in VS Code integrated terminal, Windows Terminal, Ghostty.** Falls back to in-process mode.
- **Computer use**: Desktop app only (macOS/Windows).
- **Cloud VMs / web sessions**: require Pro+ plan.
- **Native bash hook execution**: Linux/macOS easier than Windows; some hooks expect Unix shell.

## When the user is on a specific surface

Adapt recommendations:

- **Windows Terminal user wanting Agent Teams** → recommend in-process mode (default), explain tmux mode requires WSL+tmux or iTerm2
- **VS Code integrated terminal user** → flag the same Agent Teams restriction
- **Mobile-only user** → mention Dispatch + Remote Control as the path
- **Cloud-VM-only user** → mention `/teleport` as the bring-it-back path
