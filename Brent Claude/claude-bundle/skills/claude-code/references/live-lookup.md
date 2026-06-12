# Live-lookup playbook for Claude Code

Claude Code ships **multiple updates per week**. The other reference files in this skill freeze information at a point in time and decay quickly. When in doubt — and especially when you don't recognize a feature name — fetch live.

## Primary URLs

Bookmark these mentally:

- **Docs root**: `https://code.claude.com/docs/en/`
- **Index (great for grep)**: `https://code.claude.com/docs/llms.txt`
- **Changelog**: `https://code.claude.com/docs/en/changelog`
- **Commands reference**: `https://code.claude.com/docs/en/commands`
- **Settings reference**: `https://code.claude.com/docs/en/settings`
- **Hooks reference**: `https://code.claude.com/docs/en/hooks`
- **Skills**: `https://code.claude.com/docs/en/skills`
- **Subagents**: `https://code.claude.com/docs/en/sub-agents`
- **MCP**: `https://code.claude.com/docs/en/mcp`
- **Agent Teams** (the A2A docs): `https://code.claude.com/docs/en/agent-teams`
- **VS Code**: `https://code.claude.com/docs/en/vs-code`
- **Desktop**: `https://code.claude.com/docs/en/desktop`
- **Web**: `https://code.claude.com/docs/en/claude-code-on-the-web`
- **Costs**: `https://code.claude.com/docs/en/costs`

The older `docs.claude.com/en/docs/claude-code/*` URLs now 301-redirect to `code.claude.com/docs/en/*`. If the user pastes an old URL, follow the redirect.

For the **Claude API** (different product — distinct from Claude Code):
- **API docs root**: `https://docs.claude.com/en/api/` (or `docs.anthropic.com/en/api/`)
- The `claude-api` skill has more on this.

For **Claude.ai** plans/billing:
- `https://claude.com/pricing`
- `https://claude.com/pricing/team`

## When to fetch live

**Always fetch live when:**

- The user names a feature you don't recognize. Default assumption: it exists, you haven't seen it. Search the docs root or `llms.txt` index first.
- Quoting a flag, env var, settings key, or command name. Spelling and naming change.
- Quoting "what version added X" or "as of v2.1.X". Versions move daily.
- The user references docs.claude.com or code.claude.com. Read the page they're pointing at.
- Anything related to Agent Teams, Routines, Channels, Dispatch — these are all recent and evolving.

**Probably skip live fetch when:**

- You're explaining a long-stable concept (what skills are, what subagents are, how settings.json scopes work).
- The user is asking conceptually, not for current syntax.

## Search patterns

### Looking up an unrecognized feature name

```
WebFetch https://code.claude.com/docs/llms.txt
```

The `llms.txt` index is plain-text and grep-friendly. Search it for the term first; it'll give you the right docs URL.

If still not found in code.claude.com, try:

```
WebSearch "<term> claude code"
WebSearch "<term> CLAUDE_CODE_EXPERIMENTAL"
WebSearch site:code.claude.com <term>
```

### Looking up a flag or setting

```
WebFetch https://code.claude.com/docs/en/settings
WebFetch https://code.claude.com/docs/en/commands
```

Or run locally:

```bash
claude --help
/config
/permissions
/hooks
```

### Looking up "what changed recently"

```
WebFetch https://code.claude.com/docs/en/changelog
```

Or search the user's recent issue:

```
WebSearch "<feature> claude code changelog 2026"
```

### Cross-referencing community knowledge

When official docs are sparse and the user is asking how something works in practice:

- `WebSearch "<term> claude code reddit"` — `r/ClaudeAI` and `r/ClaudeCode`
- `WebSearch "<term> site:medium.com claude code"` — community blog posts
- `WebSearch "<term> github.com anthropic"` — official repos and issues

## Verification etiquette

When you cite a URL, **actually fetch it**. Don't say "according to the docs at X" without having read X — the URL might be wrong, the page might have moved, or the content might have changed. If the fetch fails, say so explicitly rather than papering over.

When you quote a setting name, env var, or command:

- Use the **exact spelling** from the doc page
- Note the **scope** (env var? settings.json key? CLI flag?)
- Note **where it goes** (which file, which scope)

## When you're truly stuck

If after fetching live docs the answer still isn't clear:

1. **Tell the user** what you've checked and what you couldn't find
2. **Ask one focused question** — usually "where did you see X mentioned" so they can point you at the source
3. Don't make up plausible-sounding flag names. The user will try to use them and they won't work.

## Related skills

When the user's question is in scope for another skill, defer:

- **`update-config`** — actually changing settings.json (don't hand-edit — invoke this)
- **`keybindings-help`** — keybinding changes
- **`claude-api`** — Anthropic SDK / Claude API / Managed Agents
- **`schedule`** — managing scheduled remote agents (Routines)
- **`loop`** — recurring `/loop` tasks
- **`skill-creator`** — building new skills
- **`init`** — initializing a CLAUDE.md
- **`security-review`**, **`review`** — code review workflows

For "I want to know about X" questions stay here. For "I want to do X" questions, defer to the action skill.
