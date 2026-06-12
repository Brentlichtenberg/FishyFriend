# Global Instructions

## Permissions

Run with `bypassPermissions` globally. NEVER create restrictive `"allow"` arrays in `.claude/settings.local.json` — they override bypass mode and cause permission prompts. If a project has restrictive permissions, fix it: set `"defaultMode": "bypassPermissions"`.

## Apple Platform Policy

Respect Apple's platform restrictions. Never circumvent iOS/macOS system-level policies (background haptics, private APIs, entitlement-gated features without the entitlement). If a capability isn't supported, say so and design around it rather than hacking. Apps must pass App Store review and not risk the developer account.

## Feature Implementation

No feature fallbacks during development. Implement features as requested — failures should be visible, not silently substituted. Standard error handling (try/catch) is fine. Only add fallbacks when explicitly asked.

## Operating Principle: Do It Yourself

The user's goal is **to do as little physical work as possible**. They are only on the hook for hardware an emulator can't reproduce (real ProMotion, real haptics, real device cameras, etc.).

Order of preference for any task:

1. **XcodeBuildMCP** — preferred for every iOS/macOS lifecycle step. See the `ios-debugger-agent` and `xcodebuildmcp` skills.
2. **CLI** — `xcodebuild`, `xcrun simctl`, `xcrun devicectl`, `defaults`, `log`, `grep`. Use when the MCP doesn't cover the task (archive/export, simulator defaults, crash dumps, xcframeworks).
3. **In-app Darwin-notification hooks** — for navigating an installed app (changing tabs, drilling into a list, triggering an action). Project apps that ship a `NavigationCommand` bridge expose Darwin notification names you can post via `xcrun simctl spawn <sim> notifyutil -p <name>` (simulator) or `xcrun devicectl device notification post --device <udid> --name <name>` (device). **Always prefer this over computer control when an equivalent command exists** — it's faster, deterministic, doesn't require the simulator window to be focused, and works identically on physical devices. **If a navigation step you need isn't covered, add a new command to the project's `NavigationCommand` enum** rather than falling through to clicks. The bridge is cheap to extend.
4. **`pymobiledevice3`** — real-device gap-filler for scoped `os.Logger` streaming and DVT screenshots. See the `pymobiledevice3-ios` skill.
5. **Claude computer control** — vision-based GUI interaction when no CLI/MCP/Darwin-hook exists. Reach for this only after confirming no nav command can be added; once you find yourself clicking the same thing twice, stop and add a Darwin command instead.
6. **AppleScript / `osascript`** — simple automation (window management, launching apps) where computer control is overkill.
7. **Ask the user** — last resort, only for the physical-device part, bundled into one ask.

Specifically, **never** ask the user to:
- Open Xcode and click Run / Stop / Build
- Open Console.app and copy-paste log lines
- Delete and reinstall an app (use `xcrun devicectl device uninstall app` + `install app`)
- Read settings out of Settings.app (use `defaults` on sims, `xcrun devicectl device info` on devices)
- Type a UDID by hand (discover via `xcrun devicectl list devices`)

If the user must physically touch the device, bundle every manual step into a single ask and explain why each one can't be automated.

Detailed iOS lifecycle procedures — log capture, headless screenshots, unattended device loop, UDID formats, XCTest architecture — live in the `ios-debugger-agent` and `pymobiledevice3-ios` skills. Don't duplicate them here.

## Testing Policy

**Every change needs a test unless there is literally no way to write one.** Before editing code, ask: "how will I know this works as intended, and how will I know a future change hasn't broken it?" If the answer isn't "an existing test covers it," add one. Golden path only — catching regressions matters more than exhaustive coverage.

**Fix failing tests when you find them**, even pre-existing ones. A red suite masks new regressions — you can't tell what your change broke. Decide whether the test is wrong (update it) or the code is wrong (fix it), and leave the suite green.

**Never treat a test failure as "expected."** Fix the test, fix the code, or remove the test if it's no longer relevant. Do not present failures as expected outcomes.

## Git Workflow

- **Commit frequently.** Offer to commit after each distinct piece of work (feature, bug fix, refactor). Small commits are easier to review and revert.

## Planning

When you produce an implementation plan — in plan mode, via the `Plan` agent, or as a standalone document — split it into two parts. This applies to any non-trivial plan the user will review or hand off to an executing agent.

**Human plan (for review):** intent, trade-offs, scope, verification strategy. Skim-length. This is what the user reads to decide "yes, do that."

**Agent plan (for execution):** enough detail that the executing agent starts cutting code without re-exploring. If the executor is saying "let me explore the engine structure before I start" for anything beyond topping-up details, the plan failed. Include:

- **File paths with line numbers** (`Path/File.swift:123`) for every function, type, or call site to read, modify, or extend. Paste short snippets when surrounding context matters.
- **Architecture overview** of the affected slice — how components currently wire together, not just the target shape. The executor needs the before-picture too.
- **Concrete edits per file**: what changes where, new files to create, things to delete.
- **Data-flow / API contracts** that cross the change boundary: types, function signatures, persisted shapes, protocol conformances.
- **Gotchas**: non-obvious invariants, fragile areas, prior incidents, platform constraints.
- **Verification steps** specific enough to run verbatim: build/test commands, test targets, simulator actions, device destinations.

If you catch yourself writing "explore X first" or "check how Y works" in the agent plan, do that research now and fold the findings in. A good agent plan is read once, not researched from.

## Skills Maintenance

Skills are living documents, not write-once artifacts. Keep them current, and re-work them when they don't fit.

**Rejection as signal.** If the user rejects a skill's output more than once on the same axis — "no, not like that," "that's not what I wanted," redoing the work by hand, correcting the same class of mistake — treat it as a signal that the skill itself is miscalibrated, not just this one invocation. Patching locally fixes the current turn; editing the skill fixes every future turn. The second is almost always the right cost-benefit.

When you notice the pattern:

1. **Read the current skill** and form a hypothesis about what's misaligned — stale assumption, missing context, wrong default, over-prescriptive instruction, a trigger that fires too broadly.
2. **Propose an edit, not just a retry.** "The `foo` skill keeps producing X but you wanted Y — want me to update the skill so future invocations default to Y?"
3. **Use the `skill-creator` skill** to iterate. It's built for this — it knows how to preserve frontmatter, improve triggering descriptions, and measure whether the revision actually helps.

**Drift detection.** Skills can also go stale in ways the user doesn't flag explicitly — a referenced file path no longer exists, a command's flag changed, a library was renamed, a bundled script references a deleted helper. When you notice drift while using a skill, fix it in the same session. Don't leave the next invocation to hit the same wall.

**The only reason not to edit.** The correction is genuinely one-off (this user, this task, this unusual preference) rather than a pattern. If you're unsure, ask: "is this a one-time preference or a rule you'd want me to remember?"

## App Store Connect API Key

For archiving and uploading to TestFlight / App Store Connect, use API key auth, not Xcode's account system. Fill in your own values:

- **Key file:** `<PATH_TO_YOUR_AuthKey_XXXXXXXXXX.p8>`
- **Key ID:** `<YOUR_KEY_ID>`
- **Issuer ID:** `<YOUR_ISSUER_ID>`

```
xcodebuild -exportArchive \
  -archivePath <ARCHIVE_PATH> \
  -exportOptionsPlist <EXPORT_OPTIONS_PLIST> \
  -exportPath <EXPORT_PATH> \
  -authenticationKeyPath <PATH_TO_YOUR_AuthKey_XXXXXXXXXX.p8> \
  -authenticationKeyID <YOUR_KEY_ID> \
  -authenticationKeyIssuerID <YOUR_ISSUER_ID>
```

## Color

Prefer **OKLCH / OKLab** for all color math — palette design, gradient ramps, interpolation, blending. sRGB channel arithmetic is perceptually non-uniform, so sRGB should only be the final output space. Specify anchor colors in OKLCH (lightness, chroma, hue) so each axis can be tuned independently; gamut-map when coordinates fall outside sRGB. See the `color-theory` skill.

## Code Style

- Apple logging: prefer `os.Logger` with a subsystem+category (filterable in Console.app, streamable via `pymobiledevice3 syslog live -pn`). Use `NSLog` for quick stdout that `devicectl --console` catches. Never `print()`.
- **Follow SOLID**:
  - **SRP** — one reason to change per type (separate data access, business logic, presentation).
  - **OCP** — extend via protocols/generics; don't modify existing code.
  - **LSP** — subtypes fully substitutable for their base.
  - **ISP** — small, focused protocols over large ones.
  - **DIP** — depend on protocols, inject dependencies. Enables testability.

## AppsOnApps — Developer Brand

**AppsOnApps** is the umbrella identity for all of this user's apps. Voice: **warm, slightly irreverent, self-aware** — apps that don't take themselves too seriously but are genuinely well-crafted.

### Tone

- Humor should feel natural, not forced. "Clever aside," not "trying to be funny."
- Descriptions lean into what makes each app *weird* or *delightful* rather than listing features.
- Slogans and taglines should be memorable and slightly unexpected.
- Marketing copy = friend explaining why they love something, not a press release.
- Avoid corporate/startup speak ("leverage", "unlock", "supercharge"). Just talk.
- If a cultural reference fits naturally, use it — don't stretch for one.
- Keep it concise. Humor lands better when it's brief.

### Known Apps

| App | Slogan | Personality |
|-----|--------|-------------|
| **Gamma Cubed** | "Annoyingly Therapeutic" | A color-matching puzzle that's weirdly calming and weirdly addictive. Leans into the contradiction. |
| **Board Control** | *(TBD)* | Chess through the lens of heatmaps. The board is the product, not the game. Free Board mode: "And this board you cannot CHAAAAANGE — oh wait, you can." |
