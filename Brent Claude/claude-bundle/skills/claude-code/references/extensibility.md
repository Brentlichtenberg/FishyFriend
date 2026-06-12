# Claude Code extensibility

Five major extension points. Pick the right one for the user's goal — they overlap in confusing ways.

| Mechanism | What it adds | Lives in | When to use |
|-----------|--------------|----------|-------------|
| **Skills** | New procedural knowledge / workflows for Claude | `~/.claude/skills/<name>/SKILL.md`, `.claude/skills/`, plugin `skills/` | Domain expertise, multi-step procedures, project-specific workflows |
| **Subagents** | Spawnable specialist agents (parent-child) | `~/.claude/agents/`, `.claude/agents/`, or `--agents '{...}'` | Parallelizable independent work, context isolation, specific tool/model needs |
| **MCP servers** | New tools backed by external systems | `~/.claude.json` (user/local), `.mcp.json` (project) | Integrate external systems (DBs, APIs, file systems, vendor tools) |
| **Hooks** | Code that runs on harness events | `settings.json` `hooks` block | Automated behaviors, policy enforcement, telemetry, auto-formatting |
| **Plugins** | Bundles of all the above | `~/.claude/plugins/` | Distribute a coherent feature set, install from a marketplace |

## Skills

Markdown file with YAML frontmatter, plus optional bundled scripts/references/assets.

```yaml
---
name: my-skill
description: When to trigger and what it does
when_to_use: optional extra triggering hint
argument-hint: optional arg shape
disable-model-invocation: false
user-invocable: true
allowed-tools: Read, Edit, Bash
model: opus
effort: high
context: fork           # fork = run in subagent
agent: my-subagent      # which subagent runs the skill
hooks: { ... }
paths: src/**/*.ts      # only trigger in matching paths
shell: bash
---

The skill body — instructions for Claude.
```

Substitutions available in skill bodies:
- `$ARGUMENTS` — full args string
- `$1`, `$2`, `$N` — positional args
- `${CLAUDE_SESSION_ID}` — current session
- `${CLAUDE_SKILL_DIR}` — this skill's directory
- Inline `` !`cmd` `` and ```` ```! ```` blocks — shell output gets preprocessed into the prompt

Live change detection — edit a skill file and it picks up next invocation.

**Bundled skills that ship with the CLI**: `/simplify`, `/loop`, `/debug`, `/claude-api`. The `/commands` reference marks built-ins vs skills.

**Custom commands** (`.claude/commands/*.md`) have been **merged into skills** and still work — same loader, same frontmatter rules.

Docs: https://code.claude.com/docs/en/skills

## Subagents

Markdown + YAML frontmatter in `.claude/agents/` or `~/.claude/agents/`. Or pass JSON inline with `claude --agents '{"my-agent": {...}}'`.

```yaml
---
description: When to use this agent
prompt: System prompt for the agent
tools: Read, Edit, Bash       # whitelist
disallowedTools: WebFetch     # blacklist
model: opus
permissionMode: plan
mcpServers: { ... }
hooks: { ... }
maxTurns: 50
skills: [skill-a, skill-b]
initialPrompt: optional starter
memory: optional memory dir
effort: high
background: false
isolation: worktree
color: cyan
---
```

**Built-in subagents** (always available):
- **`Explore`** — Haiku, read-only, fast codebase exploration
- **`Plan`** — read-only, used internally by plan mode
- **`general-purpose`** — full toolset, all-purpose
- Internal: `statusline-setup`, `Claude Code Guide`

Manage interactively with `/agents`.

**Subagent vs Agent Team distinction** — subagents are parent-child (results-only return). Agent Teams (A2A) are peer-to-peer with a mailbox. See `features.md`.

Docs: https://code.claude.com/docs/en/sub-agents

## MCP servers

Model Context Protocol — servers expose tools that Claude can call. Three transports: stdio, HTTP, SSE.

Add via:
```bash
claude mcp add <name> <command-or-url> [args...]
```

Project-scoped via `.mcp.json`:
```json
{
  "mcpServers": {
    "playwright": { "command": "npx", "args": ["-y", "@executeautomation/playwright-mcp-server"] }
  }
}
```

Managed/policy controls:
- `allowedMcpServers` / `deniedMcpServers` — allow/deny lists
- `allowManagedMcpServersOnly` — lock to admin-pushed servers
- OAuth via RFC 9728 supported for HTTP/SSE servers

**MCP elicitation** — server can request structured input mid-call.
**MCP prompts** surface as slash commands: `/mcp__<server>__<prompt>`.

Manage with `/mcp`.

Docs: https://code.claude.com/docs/en/mcp

## Hooks

Code that runs on harness events. 29 event types as of recent docs:

**Session phase**: `SessionStart`, `SessionEnd`, `Stop`, `StopFailure`, `UserPromptSubmit`, `Notification`
**Tool phase**: `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest`, `PermissionDenied`
**Subagent/Task phase**: `SubagentStart`, `SubagentStop`, `TaskCreated`, `TaskCompleted`
**Agent Teams**: `TeammateIdle`
**File/Config phase**: `FileChanged`, `ConfigChange`, `CwdChanged`, `WorktreeCreate`, `WorktreeRemove`
**Compact / MCP**: `PreCompact`, `PostCompact`, `Elicitation`, `ElicitationResult`
**Other**: `InstructionsLoaded`, `CronCreate`

Hook handler types:
- `command` — shell command
- `http` — POST to a URL
- `prompt` — Claude-evaluated prompt
- `agent` — spawn a specific subagent

Exit code 2 from a hook **blocks the action**. JSON output supports `permissionDecision`, `updatedInput`, `additionalContext`, `sessionTitle`, etc.

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [{ "type": "command", "command": "/usr/local/bin/policy-check.sh" }] }
    ]
  }
}
```

Browse with `/hooks`. Docs: https://code.claude.com/docs/en/hooks

**Important**: automated behaviors ("from now on, do X each time Y") require hooks — they cannot be implemented via memory or preferences alone, because the harness (not Claude) triggers them. Use the `update-config` skill when the user asks for something automated.

## Plugins

Installable bundles containing any combination of skills, agents, hooks, MCP servers, monitors. Install from a **marketplace** (Anthropic hosts an official one; third parties exist).

`/plugin` — manage installed plugins
`/reload-plugins` — re-scan after changes

Plugin manifest keys include: `monitors`, `effort`, `maxTurns`, `disallowedTools`, `source: 'settings'`.

Env vars within plugins: `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PLUGIN_DATA}` (persistent state).

Restrictions:
- `strictKnownMarketplaces` — only allow trusted marketplaces
- `blockedMarketplaces` — deny list
- `allowedChannelPlugins` — gate Channels-related plugins

## Choosing the right mechanism

User wants to... → use...

- "Have Claude do X reliably every time" → **Skill** (Claude reads it on relevant prompts)
- "Have Claude run X subagent for Y kinds of tasks" → **Subagent**
- "Have Claude be able to call out to Postgres / a vendor API" → **MCP server**
- "Run a command before/after every file edit" → **Hook**
- "Distribute a bundle of all the above to my team" → **Plugin** (and host it on a marketplace)

When ambiguous, the question is "who decides when this runs?":
- **Claude decides** → skill or subagent
- **Harness decides on event** → hook
- **External system decides** → MCP server (Claude calls when needed) or hook (event-driven)
