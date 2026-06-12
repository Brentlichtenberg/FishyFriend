# Global Instructions

## Permissions

This user runs with `bypassPermissions` globally. NEVER create restrictive `"allow"` arrays in `.claude/settings.local.json` — they override the global bypass mode and cause unwanted permission prompts. If you encounter a project with restrictive permissions, fix it immediately by setting `"defaultMode": "bypassPermissions"`.

## Apple Platform Policy

Respect Apple's platform restrictions. Never attempt to circumvent iOS/macOS
system-level policies (e.g. background haptic access, private API usage,
entitlement-gated features without the entitlement). If a capability isn't
supported, say so clearly and design around the limitation rather than hacking
around it. Apps should be built in good faith so they pass App Store review
and don't risk the developer's account.

## Feature Implementation

Do NOT add feature fallbacks during development. Implement features as requested — if something fails, it should fail visibly rather than silently falling back to alternative behavior. This does not apply to standard error handling (try/catch, etc.). Only add fallbacks when explicitly asked for.

## Operating Principle: Do It Yourself

The user's goal is **to do as little physical work as possible**. They are only on the hook for things that genuinely cannot be done from this Mac — i.e. interacting with hardware that an emulator cannot reproduce (real ProMotion display, real haptics, etc.).

Order of preference for any task:

1. **CLI** — `xcodebuild`, `xcrun simctl`, `xcrun devicectl`, `defaults`, `log`, `grep`, etc. Cheapest in tokens, always try first.
2. **Claude computer control** — use the vision-based computer control feature to see and interact with the screen (click, type, navigate UIs). Powerful for anything with a GUI but no CLI equivalent.
3. **AppleScript / `osascript`** — fallback for simple automation tasks (window management, launching apps) where computer control would be overkill.
4. **Ask the user** — only as a last resort, and only for the physical-device part. Bundle every physical step into a single ask so they don't get pinged repeatedly.

Specifically, **never** ask the user to:
- Open Xcode and click Run / Stop / Build
- Open Console.app and copy-paste log lines
- Delete and reinstall an app (use `xcrun devicectl device uninstall app` + `install app`)
- Read settings out of Settings.app (use `defaults` on simulators, `xcrun devicectl device info` on real devices)
- Type a UDID by hand (discover it via `xcrun devicectl list devices`)

If the user is ever asked to physically touch the device, the request must include **all** the manual steps in one batch and explain why each one can't be automated.

## iOS Device Workflow

### Before Handing Off to User

Before asking the user to test anything on device, you MUST:

1. **Build for testing** (compiles both app and test bundle in the right order):
   ```
   xcodebuild build-for-testing -project <PROJECT> -scheme <SCHEME> -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
   ```

2. **Run the full test suite** and confirm zero failures:
   ```
   xcodebuild test-without-building -project <PROJECT> -scheme <SCHEME> -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E "passed|failed|error:"
   ```
   Expected: all lines say `passed`. If any say `failed`, fix the code and repeat from step 1.

3. **Do a clean device build** (substitute the right UDID for the target device):
   ```
   xcodebuild -project <PROJECT> -scheme <SCHEME> -destination 'platform=iOS,id=<UDID>' -configuration Debug build
   ```

4. **Locate the freshest .app** — sort DerivedData by modification time, do NOT use `find | head -1`:
   ```
   APP=$(ls -td ~/Library/Developer/Xcode/DerivedData/<SCHEME>-*/Build/Products/Debug-iphoneos/<SCHEME>.app | head -1)
   ```

5. **Install onto the device via CLI** (do not ask the user to do this in Xcode):
   ```
   xcrun devicectl device install app --device <UDID> "$APP"
   ```

6. **(Optional) Launch with live console output streamed to a file** so you can grep it after the user reproduces:
   ```
   xcrun devicectl device process launch --device <UDID> --console <BUNDLE_ID> \
     2>&1 | tee /tmp/<app>-device.log &
   ```

7. Only then tell the user the fix is on their device, and tell them the **exact** physical interaction you need (one batch).

If tests fail, fix the code and re-run until all pass. Never skip this step.

### Capturing Logs and Crashes from a Real Device

Always prefer pulling diagnostics yourself over asking the user to read screens.

- **Live console while reproducing** — stream and tee to a file:
  ```
  xcrun devicectl device process launch --device <UDID> --console <BUNDLE_ID> \
    2>&1 | tee /tmp/<app>-device.log
  ```
  Run in background, ask the user only to perform the physical reproduction, then `grep` the log.

- **Crash logs already on the device**:
  ```
  xcrun devicectl device info processes --device <UDID>
  xcrun devicectl device diagnose --device <UDID> --output-directory /tmp/<app>-diag
  ```

- **Reset app state on a real device** (replaces "delete and reinstall"):
  ```
  xcrun devicectl device uninstall app --device <UDID> <BUNDLE_ID>
  xcrun devicectl device install   app --device <UDID> "$APP"
  ```

- **Read/write app defaults on a Simulator** (no equivalent on real devices — defaults are sandboxed):
  ```
  xcrun simctl spawn <SIM_UDID> defaults read  <BUNDLE_ID>
  xcrun simctl spawn <SIM_UDID> defaults write <BUNDLE_ID> <key> -bool true
  ```

If `devicectl` ever lacks a verb you need, fall back to Claude computer control (vision-based screen interaction) or AppleScript via `osascript` rather than handing the task to the user.

### UDID Formats

`xcrun devicectl list devices` returns the **CoreDevice UUID**, but
`xcodebuild -destination 'platform=iOS,id=<UDID>'` requires the **ECID UDID**. Passing
the CoreDevice UUID to xcodebuild fails with "Unable to find a device matching the
provided destination specifier." Use `xcodebuild -showdestinations` to get the ECID format.
Use devicectl UUID for `devicectl` commands; use ECID for `xcodebuild`.

### Test Architecture Notes (Xcode / XCTest)

- `xcodebuild test` (single command) fails to find the module on first compile due to
  explicit-module-build ordering. Always use the two-step `build-for-testing` → `test-without-building`.
- UI test targets must have `ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES = YES`
  and `LD_RUNPATH_SEARCH_PATHS` including `@executable_path/Frameworks`.
- UI test TestableReferences must NOT have `parallelizable = "YES"`. Parallelized UI tests
  run on simulator *clones*, which consistently fail with FBSOpenApplication RequestDenied.
- **Matching SwiftUI elements in XCUITest**: a `Text` inside a `Button` is absorbed into the
  button's accessibility element. Use `app.buttons["label"]` not `app.staticTexts["label"]`.

## Testing Policy

**Every change needs a test unless there is literally no way to write one.** Before editing
code, ask: "how will I know this feature works as intended, and how will I know a future
change hasn't broken it?" If the answer isn't "an existing test covers it," add one. Golden
path only — catching regressions matters more than exhaustive coverage.

**Fix failing tests when you find them.** If the test suite has failures — even pre-existing
ones unrelated to your current work — investigate and fix them before moving on. A red test
suite masks new regressions: if tests are already failing, you can't tell whether your
change broke something. Determine whether the test is wrong (update it) or the code is
wrong (fix it), and leave the suite green.

**Never treat a test failure as "expected."** A failing test is always a problem to resolve.
If a test fails, either fix the test to match correct behavior, fix the code so the test
passes, or remove the test if it's no longer relevant. Do not present failing tests to the
user or describe failures as expected outcomes.

## Layout Principles

- **All layout dimensions must be relative** — derive sizes proportionally from the
  available `GeometryReader` size. Never hardcode pixel widths/heights for layout.
  Font and icon sizes are design tokens and may use fixed values per size class.
- Orientation is detected purely by comparing `geo.size.width > geo.size.height`
  inside a `GeometryReader`, not by device type.

## Git Workflow

- **Commit frequently** — don't let multiple features or logical changes accumulate
  into a single large commit. Offer to commit after completing each distinct piece of
  work (a feature, a bug fix, a refactor). Smaller commits are easier to review and revert.

## App Store Connect API Key

For archiving and uploading Apple apps to TestFlight / App Store Connect, use the
API key authentication instead of Xcode's account system:

- **Key file:** `/Users/benbyrnes/Documents/Projects/AuthKey_8PV2K8T6NC.p8`
- **Key ID:** `8PV2K8T6NC`
- **Issuer ID:** `5bc36e8c-5f39-4d20-abc0-f9a77ef88f5a`

Usage with `xcodebuild -exportArchive`:
```
xcodebuild -exportArchive \
  -archivePath <ARCHIVE_PATH> \
  -exportOptionsPlist <EXPORT_OPTIONS_PLIST> \
  -exportPath <EXPORT_PATH> \
  -authenticationKeyPath /Users/benbyrnes/Documents/Projects/AuthKey_8PV2K8T6NC.p8 \
  -authenticationKeyID 8PV2K8T6NC \
  -authenticationKeyIssuerID 5bc36e8c-5f39-4d20-abc0-f9a77ef88f5a
```

## Code Style

- Use `NSLog` not `print()` for all logging in iOS apps.
- **Follow SOLID principles** in all code:
  - **Single Responsibility**: Each type has one reason to change. Separate concerns into distinct types (e.g., data access, business logic, presentation).
  - **Open/Closed**: Design types to be extended (via protocols, generics) without modifying existing code.
  - **Liskov Substitution**: Protocol conformances and subclasses must be fully substitutable for their base types.
  - **Interface Segregation**: Prefer small, focused protocols over large ones. Clients should not depend on methods they don't use.
  - **Dependency Inversion**: Depend on protocols, not concrete types. Inject dependencies rather than creating them internally. This also enables testability.

## AppsOnApps — Developer Brand

**AppsOnApps** is the umbrella developer identity for all of this user's apps. The brand voice is **warm, slightly irreverent, and self-aware** — apps that don't take themselves too seriously but are genuinely well-crafted.

### Tone Guidelines

- Humor should feel natural, not forced. Think "clever aside" not "trying to be funny."
- Product descriptions lean into what makes each app *weird* or *delightful* rather than listing features.
- Slogans and taglines should be memorable and slightly unexpected.
- Marketing copy should sound like a friend explaining why they love something, not a press release.

### Known Apps & Voice

| App | Slogan | Personality |
|-----|--------|-------------|
| **Gamma Cubed** | "Annoyingly Therapeutic" | A color-matching puzzle that's weirdly calming and weirdly addictive. Leans into the contradiction. |
| **Board Control** | *(TBD)* | Chess through the lens of heatmaps. The board is the product, not the game. Free Board mode: "And this board you cannot CHAAAAANGE — oh wait, you can. This is the Free Board, where you can experiment to your heart's content." |

### Writing for AppsOnApps

When writing app descriptions, onboarding text, feature explanations, or marketing copy for any AppsOnApps product:

- Lead with what's *interesting* about the feature, not what it does mechanically.
- If there's a cultural reference that fits naturally (Free Bird for Free Board, etc.), use it — but don't stretch for one.
- Keep it concise. The humor lands better when it's brief.
- Avoid corporate/startup speak ("leverage", "unlock", "supercharge"). Just talk like a person.
