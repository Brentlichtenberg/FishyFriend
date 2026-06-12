# Claude Code settings

For any actual settings change, **invoke the `update-config` skill** rather than hand-editing — it knows the schema, scopes, and merge semantics. This file is a map.

## Scope precedence (highest → lowest)

1. **Managed** — server-pushed (claude.ai admin console), MDM, or `managed-settings.json` files
2. **Local** — `.claude/settings.local.json` (gitignored, per-user-per-project)
3. **Project** — `.claude/settings.json` (committed, shared with team)
4. **User** — `~/.claude/settings.json`

A managed setting will override every lower scope. A user setting is the floor.

## File locations

| File | Purpose |
|------|---------|
| `~/.claude/settings.json` | User-scope settings (env, hooks, permissions, plugins) |
| `~/.claude.json` | User preferences, OAuth, user/local MCP servers, per-project state cache |
| `.claude/settings.json` | Project-scope settings (committed) |
| `.claude/settings.local.json` | Local-scope settings (gitignored) |
| `.mcp.json` | Project-scope MCP servers (committed) |
| `.claude/CLAUDE.md` | Project memory |
| `.claude/agents/` | Project subagents |
| `.claude/skills/` | Project skills |
| `.claude/commands/` | Legacy custom commands (now merged into skills) |
| `.claude/rules/` | Rule files |
| `.claude/hooks/` | Hook scripts (referenced from settings.json) |

## Managed settings (admin/policy)

Three sources for managed settings, **all of which override user/project**:

1. **Server-managed** — pushed from claude.ai admin console (Team/Enterprise plans)
2. **MDM** — macOS plist `com.anthropic.claudecode` or Windows registry `HKLM\SOFTWARE\Policies\ClaudeCode`
3. **Local managed files** — `managed-settings.json` plus drop-in `managed-settings.d/*.json` (systemd-style merging)

Local managed file paths:
- macOS: `/Library/Application Support/ClaudeCode/`
- Linux: `/etc/claude-code/`
- Windows: `C:\Program Files\ClaudeCode\` (the legacy `C:\ProgramData\ClaudeCode` location was removed in 2.1.75)

For multi-tenant or restricted deployments, this is how IT pushes policy — useful to mention if a user is hitting "you don't have permission" walls in a corporate setting.

## settings.json schema (top-level keys)

Add `"$schema": "https://json.schemastore.org/claude-code-settings.json"` for editor autocomplete.

Common keys:

- **`permissions`** — allow/deny lists for tool calls (e.g. `Bash(npm install)`, `Bash(git push)`)
- **`env`** — environment variables Claude Code starts with (this is where `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` goes)
- **`hooks`** — event handlers; see `extensibility.md` for events list
- **`mcpServers`** — define MCP servers
- **`enabledMcpjsonServers`** — gate which `.mcp.json` servers actually load
- **`enabledPlugins`** — installed plugin names
- **`agent`** — default subagent settings
- **`effortLevel`** — default reasoning effort
- **`availableModels`** — restrict which models are selectable
- **`attribution`** — co-author tag in commits
- **`autoMode`** — auto-mode classifier config
- **`cleanupPeriodDays`** — log/cache retention
- **`companyAnnouncements`** — admin announcements
- **`allowedHttpHookUrls`** — whitelist for HTTP-type hooks
- **`allowManagedHooksOnly`** — restrict hooks to admin-defined
- **`disableSkillShellExecution`** — disable inline `` !`cmd` `` shell preprocessing
- **`forceLoginMethod`** — restrict auth method
- **`forceRemoteSettingsRefresh`** — force re-pull of managed settings
- **`worktree.sparsePaths`** — sparse-checkout paths for worktree subagents
- **`channelsEnabled`** — toggle Channels feature
- **`allowedChannelPlugins`** — restrict which Channels plugins load
- **`autoMemoryDirectory`** — where auto-memory writes
- **`teammateMode`** — `in-process` or `tmux` for Agent Teams
- **`strictKnownMarketplaces`** / **`blockedMarketplaces`** — plugin marketplace policy

…plus many more. Run `/config` for an interactive view, or check the docs page.

## Settings vs `Config` tool

For the simplest settings (theme, model, default editor), the **`Config` tool** (built-in to Claude Code) handles them more cleanly than editing `settings.json`. Use Config for:

- Theme
- Model selection
- Editor mode (vim/emacs/default)
- Effort level
- Notification preferences

Use the **`update-config` skill** (which edits `settings.json`) for everything else: env vars, hooks, permissions, MCP servers, plugin gating.

## Merging semantics

- Lists (e.g. `permissions.allow`) merge by union across scopes (managed wins ties).
- Objects (e.g. `env`, `hooks`) merge per-key (managed wins ties).
- Scalar settings (e.g. `effortLevel`) take the highest-precedence value.

The drop-in `managed-settings.d/*.json` files merge alphabetically (systemd-style) into the base `managed-settings.json`.

## Common settings.json examples

### Enable Agent Teams (A2A)

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

### Allow specific bash commands without prompting

```json
{
  "permissions": {
    "allow": [
      "Bash(npm install)",
      "Bash(npm test)",
      "Bash(git status)"
    ]
  }
}
```

### Add a hook to format on edit

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": "prettier --write $CLAUDE_TOOL_FILE_PATH" }
        ]
      }
    ]
  }
}
```

### Restrict MCP servers to only managed ones

```json
{
  "allowManagedMcpServersOnly": true
}
```

## Diagnostic commands

```bash
claude --version              # version
claude --help                 # all flags
/config                       # interactive settings editor
/permissions                  # current permissions view
/mcp                          # MCP server status
/hooks                        # hooks reference + current
/agents                       # subagents
/skills                       # skills
/plugin                       # plugins
```

When troubleshooting "why isn't X working":

1. Check what scope the setting is in (user/project/local/managed)
2. Check whether a managed setting is overriding it
3. Check `claude --help` for the current flag/env name (renames happen)
4. Check the changelog (https://code.claude.com/docs/en/changelog) for recent removals
