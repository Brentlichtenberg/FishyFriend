---
name: ios-debugger-agent
description: Build, deploy, and debug iOS apps. Prefers XcodeBuildMCP for every lifecycle step (build, install, launch, UI automation, logs, LLDB) on both simulators and physical devices. Trigger when asked to run an iOS app, interact with the simulator UI, inspect on-screen state, capture logs/console output, diagnose runtime behavior, test on a physical device, or add Darwin-notification remote control so an installed app can be navigated from the terminal without screen taps.
---

# iOS Debugger Agent

## Prime directive: use XcodeBuildMCP, not raw CLI

The `xcodebuildmcp` MCP server is installed at user scope and exposes tools for every stage of the iOS lifecycle — project discovery, build, install, launch, test, log capture, UI automation, LLDB, and code coverage. **Prefer MCP tools over `xcodebuild` / `xcrun simctl` / `xcrun devicectl` / `idevicesyslog` / in-app log scraping.** Only fall back to shell commands for steps the MCP genuinely does not cover (see "When you still need the CLI" at the end).

Before running any MCP tool, invoke the shipped **`xcodebuildmcp` skill** — it establishes session conventions (always call `session_show_defaults` first, don't chain build-then-build-and-run, etc.) that this skill builds on.

## Workflow coverage (default vs. gated)

XcodeBuildMCP ships with **only the simulator workflow enabled by default**. Other workflows are gated behind `.xcodebuildmcp/config.yaml`:

| Workflow | Default? | How to enable |
|----------|----------|---------------|
| simulator | ✅ | always on |
| device (physical iPhone/iPad) | ❌ | add `device` to enabled workflows |
| macos | ❌ | add `macos` |
| debugging (LLDB) | ❌ | add `debugging` |
| ui-automation | ❌ | add `ui-automation` |
| logging (device log capture) | ❌ | add `logging` |
| coverage | ❌ | add `coverage` |
| swift-package | ❌ | add `swift-package` |
| project-scaffolding | ❌ | add `project-scaffolding` |

If you need a tool and it's not present, check the server's config first — don't silently fall back to the CLI without telling the user they can enable the workflow. See https://github.com/getsentry/XcodeBuildMCP/blob/main/docs/CONFIGURATION.md.

## Simulator workflow (default — always use MCP)

The loop: **set session defaults → build-and-run → inspect UI / capture logs → iterate.**

1. **Confirm session defaults** — call `session_show_defaults` before the first build/run. If project/workspace or scheme is missing, call the project discovery tool to find them.
2. **Pick a booted simulator** — list iOS simulators and select one with state `Booted`. If none are booted, ask the user (don't boot automatically unless asked).
3. **Build + run in one shot** — use the combined build-and-run simulator tool. Don't chain build-only then run — that's the stale pattern the MCP's own skill warns against.
4. **Verify launch** — capture a screenshot or the view-hierarchy snapshot to confirm the app actually rendered. A clean build exit is not the same as a running app.
5. **Interact with UI** — use the ui-automation tools (`tap`, `swipe`, `type-text`, `gesture`, hardware button presses) by accessibility id/label where possible; coordinates only as a fallback.
6. **Capture logs** — start simulator log capture scoped to your bundle id, reproduce, then stop and read the returned log blob. Don't reinvent via `xcrun simctl spawn ... log stream`.
7. **Coverage / LLDB** — if `coverage` or `debugging` workflows are enabled, get per-target coverage from the xcresult bundle and run LLDB commands (`attach`, `add-breakpoint`, `continue`, `stack`, `variables`) without opening Xcode.

For reading/writing simulator `UserDefaults` (setting feature flags for tests), the MCP does not expose this — fall back to `xcrun simctl spawn <UDID> defaults write <BUNDLE_ID> <key> ...`.

## When do I need a physical device?

Most of the app runs fine in the simulator. A real device is **required** for:

| Need | Why the sim isn't enough |
|------|--------------------------|
| ProMotion 120 Hz (real frame pacing) | sim reports 60 Hz regardless of host |
| Core Haptics / `UIImpactFeedbackGenerator` | sim silently no-ops |
| Real camera, LiDAR, ARKit world tracking | sim cameras are synthetic |
| GameKit turn-based with real Apple IDs | sandbox accounts require device sign-in |
| Neural Engine perf (Core ML latency, `.all` compute units) | sim runs on CPU — latency numbers are meaningless |
| Background modes (real suspend/resume, background tasks) | sim lifecycle is not representative |
| App Store screenshot capture with device chrome | sim screenshots are rejected by ASC device-frame reviewers |

Start in the sim. Move to device only when you hit something in the list above. Per the project's Testing Policy, hardware-only behavior gets a UI test pinned to the physical-device destination, not the sim.

## Physical device workflow

### First-time device pairing

When a new device is plugged into this Mac for the first time:

1. **Enable Developer Mode on the device** — Settings → Privacy & Security → Developer Mode → On (requires reboot). Install fails with `Developer Mode disabled on this device` until this is done. One of the few steps that genuinely requires the user's hands.
2. **Accept the trust prompt** on first USB connect. The device shows a "Trust This Computer?" dialog.
3. **Discover both UDID formats** — `xcodebuild` wants ECID, `devicectl` wants CoreDevice UUID:
   ```bash
   xcodebuild -showdestinations -project <PROJECT>.xcodeproj -scheme <SCHEME> 2>&1 | grep "platform:iOS,"
   xcrun devicectl list devices
   ```
4. **Record the device in the project's CLAUDE.md** Known Devices table (Name, Kind, ECID, CoreDevice UUID). Future sessions should never have to re-discover.
5. **Auto-provision on first build** — registers the device with the team and generates a development profile:
   ```bash
   xcodebuild -allowProvisioningUpdates -project <PROJECT>.xcodeproj -scheme <SCHEME> \
     -destination 'platform=iOS,id=<ECID>' build
   ```
   Requires a cached Apple ID sign-in in Xcode or the App Store Connect API key (see the user's CLAUDE.md). Subsequent builds don't need `-allowProvisioningUpdates` until the profile expires.

### MCP + CLI loop

**If the `device` workflow is enabled in XcodeBuildMCP**, prefer these MCP tools:

- list connected devices
- build for device
- **build-and-run** (builds, installs, launches in one call — this is the preferred entry point)
- install app, launch app, stop app
- start/stop device log capture (scoped to bundle id — returns logs as a blob when stopped)
- test on device
- LLDB attach (if `debugging` is also enabled)

**If the `device` workflow is NOT enabled**, fall back to the CLI loop documented in the project CLAUDE.md and the `pymobiledevice3-ios` skill:

```bash
# Discovery: xcodebuild wants ECID, devicectl wants CoreDevice UUID — don't cross them
xcodebuild -project <PROJECT>.xcodeproj -scheme <SCHEME> -showdestinations 2>&1 | grep "platform:iOS,"
xcrun devicectl list devices

# Build → install → launch with streaming console
xcodebuild -project <PROJECT>.xcodeproj -scheme <SCHEME> \
  -destination 'platform=iOS,id=<ECID>' build
xcrun devicectl device install app --device <COREDEVICE_UUID> <APP_PATH>
xcrun devicectl device process launch --device <COREDEVICE_UUID> \
  --console <BUNDLE_ID> > /tmp/<app>_log.txt 2>&1 &
```

Even when CLI-building, **device screenshots and unified log streaming (`os.Logger`/`Logger` output)** always go through `pymobiledevice3` — those aren't in `devicectl` and aren't reliably in XcodeBuildMCP's device tools either:

```bash
python3 -m pymobiledevice3 syslog live -pn <ProcessName> > /tmp/<app>-live.log &
python3 -m pymobiledevice3 developer dvt screenshot /tmp/<app>-shot.png
```

See the `pymobiledevice3-ios` skill for the full picture on real-device log capture.

## Running tests on a physical device

The only thing that changes between sim and device for XCUITest runs is `-destination`. The two-step build-for-testing → test-without-building pattern, `-only-testing` filters, result bundles, and the XCUITest accessibility API all work identically on device.

```bash
# Build the test bundle once against the device
xcodebuild build-for-testing -project <PROJECT>.xcodeproj -scheme <SCHEME> \
  -destination 'platform=iOS,id=<ECID>'

# Run a specific UI test against the device
xcodebuild test-without-building -project <PROJECT>.xcodeproj -scheme <SCHEME> \
  -destination 'platform=iOS,id=<ECID>' \
  -only-testing:<UITestTarget>/<TestClass>/<testMethod> \
  2>&1 | grep -E "passed|failed|error:"
```

Device auto-lock **must** be Never, or the test run stalls mid-launch with `FBSOpenApplicationServiceErrorDomain error 1, Locked` (same constraint as the autonomous iteration loop below). XCUITest screenshot attachments on device capture real hardware pixels — Dynamic Island, notch, real safe areas — which is exactly what catches the layout bugs the sim papers over.

### Two-device / multiplayer test runs

For GameKit turn-based, peer-to-peer, or any test that needs two real Apple IDs talking to each other, `xcodebuild test` accepts multiple `-destination` flags and runs the same test bundle against each:

```bash
xcodebuild test -project <PROJECT>.xcodeproj -scheme <SCHEME> \
  -destination 'platform=iOS,id=<ECID_DEVICE_A>' \
  -destination 'platform=iOS,id=<ECID_DEVICE_B>' \
  -only-testing:<UITestTarget>/<MultiplayerTestClass> \
  -parallel-testing-enabled YES -parallel-testing-worker-count 2
```

Caveats specific to this mode:
- **Each device needs its own Game Center sandbox Apple ID.** Same account on both shows up as "already in match" and GameKit silently drops the invite.
- **XCUITest workers don't share state.** Use a launch argument (e.g., `--role A` / `--role B`) to distinguish sides, and an external rendezvous (iCloud KV, a shared file on the Mac, a small HTTP echo) for the actual handoff data. Don't try to use `XCTAttachment` or test-bundle globals for cross-device sync.
- **`parallelizable = "YES"` on the testable reference breaks device runs.** That flag triggers simulator-clone behavior; on physical devices it causes `FBSOpenApplication RequestDenied`. Keep it off and rely on the multiple `-destination` flags instead.
- **One-device-plus-one-sim works for a lot of cases.** Pass one device destination + one simulator destination; GameKit sandbox flows across the mix. Use this when you only have one physical device paired and don't need real hardware on both sides.

For the Board Control GameKit Phase 5 case specifically: BPhone + BiPad is the natural pairing (both already in the Known Devices table). Log the matching UDIDs from CLAUDE.md and drive both with role-distinguishing launch arguments.

### Signing and entitlements gotchas

On-device install failures almost always trace to signing, not code. Diagnose before rebuilding:

```bash
# What entitlements does the built .app actually claim?
codesign -d --entitlements :- <APP_PATH>

# What does the embedded provisioning profile grant?
security cms -D -i <APP_PATH>/embedded.mobileprovision

# Team / signature details
codesign -dvvv <APP_PATH>
```

Common failure modes:

- **No profile for this bundle id.** First build on a new device needs `-allowProvisioningUpdates`. Symptom: `No profiles for '<bundle id>' were found`.
- **Entitlement the profile can't grant.** GameKit, Push Notifications, Associated Domains, iCloud, App Groups, HealthKit require a paid team. Free provisioning gets you basic sandboxing only. Symptom: install fails silently, or `A valid provisioning profile for this executable was not found`.
- **Entitlements claimed ≠ entitlements granted.** You added a capability in Xcode but didn't refresh the profile. The `.app` now claims something the embedded `.mobileprovision` doesn't allow, and the device rejects install with a generic "install failed." Re-run with `-allowProvisioningUpdates`.
- **Expired development profile.** 7 days on a free team, ~1 year on paid. `-allowProvisioningUpdates` refreshes.
- **Wrong team on a multi-team Apple ID.** Check `codesign -dvvv` — if the `Authority` chain doesn't name the expected team, Xcode picked the wrong one. Fix in project settings or pass `DEVELOPMENT_TEAM=<ID>` to `xcodebuild`.

## Logging best practices (tool-agnostic)

**Structured prefixes** for easy scanning:
```swift
NSLog("[Feature] event — key=%@, value=%@", key, value ? "true" : "false")
```

Prefer `os.Logger` with a subsystem+category for anything you'd want to filter in Console.app or stream scoped via `pymobiledevice3 syslog live -pn`. `NSLog` is fine for quick stdout that `devicectl --console` can catch.

**Measurement logging** for verifying timing/Hz/frame rates:
```swift
private var eventCount = 0
private var windowStart: CFTimeInterval = 0

eventCount += 1
let elapsed = now - windowStart
if elapsed >= 2.0 {
    let hz = Double(eventCount) / elapsed
    NSLog("[Feature] Hz: measured=%.1f (events=%d in %.1fs)", hz, eventCount, elapsed)
    eventCount = 0
    windowStart = now
}
```

**State transition logging** — log enough context to understand sequences:
```swift
NSLog("[Feature] stateChange — from=%@ to=%@ reason=%@", oldState, newState, reason)
```

## When you still need the CLI

Things XcodeBuildMCP does **not** cover today:

- **Archive + export for TestFlight / App Store** (`xcodebuild archive` / `-exportArchive`). Still a CLI job with the App Store Connect API key documented in the user's CLAUDE.md.
- **Reading/writing Simulator `UserDefaults`** (`xcrun simctl spawn ... defaults`). Required for setting `@AppStorage` overrides before UI tests.
- **Pulling crash logs from a real device** (`xcrun devicectl device diagnose`).
- **Real-device unified log streaming of `os.Logger` output**, **real-device screenshots** — use `pymobiledevice3` for both.
- **Building xcframeworks / static libs for third-party vendoring** (`xcodebuild -create-xcframework`, `xcrun libtool`). Not an app lifecycle concern — the tools are the right choice.

## UDID formats (ECID vs CoreDevice UUID)

`xcrun devicectl list devices` returns the **CoreDevice UUID**. `xcodebuild -destination 'platform=iOS,id=<UDID>'` requires the **ECID UDID**. Passing a CoreDevice UUID to `xcodebuild` fails with *"Unable to find a device matching the provided destination specifier."*

- Use **ECID** for `xcodebuild` (build, test). Get it via `xcodebuild -showdestinations`.
- Use **CoreDevice UUID** for `devicectl` (install, uninstall, process launch, diagnose).

## Autonomous on-device iteration (no unlock dance)

Goal: rebuild → install → launch → capture UI → diagnose, without the user touching the device between iterations.

**Lock is the hard blocker.** `devicectl device process launch` fails on a locked device with `FBSOpenApplicationServiceErrorDomain error 1, Locked`. No supported bypass — device must be unlocked *and* auto-lock set to **Never** (Settings → Display & Brightness → Auto-Lock → Never). Setting survives reboots but reverts under Low Power Mode.

**Prefer iPad over iPhone for long-running iteration** when MDM blocks auto-lock=Never on the phone. iPhone Mirroring is NOT a workaround — it requires the phone locked and suspends ARKit camera sessions.

**Check device state before launching:**
```
xcrun devicectl device info lockState --device <UDID>   # expect: unlocked
xcrun devicectl device info displays  --device <UDID>   # backlightState: On
```

**Headless screenshots via `pymobiledevice3`.** Legacy `idevicescreenshot` is broken on iOS 17+; `devicectl` has no screenshot command. `pymobiledevice3` reimplements the DVT channel:
```
pymobiledevice3 developer dvt screenshot /tmp/<app>-shot.png
# wireless / iOS 17+: start the tunnel once (sudo for NC-pair), then screenshot
sudo pymobiledevice3 remote start-tunnel
```

Do NOT add an in-app snapshot recorder — `UIGraphicsImageRenderer + drawHierarchy` runs on main thread and stalls render-heavy apps (ARKit, Metal). External screenshots only.

**Pull app-written files** (crash dumps, legit PNGs) — paths are relative to container root:
```
xcrun devicectl device copy from --device <UDID> \
  --domain-type appDataContainer --domain-identifier <BUNDLE_ID> \
  --source /Documents/<subdir>/ --destination /tmp/<app>-out/
```

**Full unattended loop:**
1. Edit code → `xcodegen generate` if project uses xcodegen and files changed.
2. Build + install + launch — MCP device `build-and-run` (one call) or CLI fallback above.
3. `python3 -m pymobiledevice3 syslog live -pn <ProcessName> > /tmp/<app>-live.log &`
4. `pymobiledevice3 developer dvt screenshot /tmp/<app>-shot.png` when needed.
5. **Navigate the app via Darwin notifications** (see next section) — no screen taps required.
6. Read screenshot, grep log. User positions device once, then stays hands-off.

## Remote app control via Darwin notifications

**Every app in this portfolio should ship a `#if DEBUG`-gated Darwin notification bridge.** It's the missing piece of the autonomous loop: a way to drive navigation, toggle feature flags, or trigger debug actions from the Mac with no screen taps. GlutenMeNot (`DebugNotificationBridge.swift` — flag toggling) and Board Control (`NavigationNotificationBridge.swift` — tab + drill-down navigation) both ship one. Add it to new apps at the same time you wire up the root view.

**Always prefer Darwin notifications over computer control for in-app navigation.** If you find yourself reaching for `mcp__computer-use__left_click` to tap a tab bar / list row / nav button, stop — extend the bridge instead. Adding a new `NavigationCommand` case takes ~3 lines (enum + switch arm) and gives you a deterministic, simulator-agnostic, device-portable, focus-independent navigation primitive. Computer control should be reserved for genuine pixel interactions (specific board square, drag gesture, drawing) where adding an enum case isn't feasible. **A second click of the same button is a signal: stop, add the command.**

### Why this, not alternatives

- **URL schemes (`openURL`)**: rewind to cold-launch state, defeating the iteration you're mid-way through.
- **UserDefaults polling**: burns CPU, adds latency, needs a poll loop.
- **In-app HTTP server**: extra dependency, needs a port, Wi-Fi-only, fragile with IP changes.
- **XCUITest automation**: great for assertions, but ~3–5 s per command via xctrunner. Darwin is <100 ms and doesn't relaunch the app.

Darwin notifications need zero infrastructure — `xcrun devicectl` and `xcrun simctl` already ship with the Xcode toolchain.

### Architecture

```
Mac terminal                           iOS app (device or sim)
─────────────                          ──────────────────────
xcrun devicectl device                 CFNotificationCenterAddObserver
  notification post      ────────►         for every Command.allCases
  --name <prefix>.<raw>                              │
                                                     ▼
                                         C callback → Task { @MainActor }
                                                     │
                                                     ▼
                                         mutate @Observable state /
                                         post NotificationCenter /
                                         invoke injected closure
```

### Paste-ready template

One file at `<App>/Debug/<App>NotificationBridge.swift`, entirely `#if DEBUG`:

```swift
#if DEBUG
import Foundation
import os

enum RemoteCommand: String, CaseIterable, Sendable {
    case tabHome     = "tab.home"
    case tabSettings = "tab.settings"
    // …extend with whatever the app needs

    static let prefix = "com.example.myapp.debug"

    /// In-process notification that SwiftUI views subscribe to.
    static let localName  = Notification.Name("MyApp.debug.remote")
    static let commandKey = "command"

    var darwinName: String { "\(Self.prefix).\(rawValue)" }

    static func command(from darwinName: String) -> RemoteCommand? {
        let p = "\(prefix)."
        guard darwinName.hasPrefix(p) else { return nil }
        return RemoteCommand(rawValue: String(darwinName.dropFirst(p.count)))
    }
}

@MainActor
final class RemoteNotificationBridge {
    private static let log = Logger(subsystem: "com.example.myapp", category: "debug-remote")
    private let center = CFNotificationCenterGetDarwinNotifyCenter()

    init() {
        let ptr = Unmanaged.passUnretained(self).toOpaque()
        for c in RemoteCommand.allCases {
            let n = CFNotificationName(c.darwinName as CFString)
            CFNotificationCenterAddObserver(center, ptr, Self.cb, n.rawValue, nil, .deliverImmediately)
        }
    }

    private static let cb: CFNotificationCallback = { _, observer, name, _, _ in
        guard let observer, let name,
              let command = RemoteCommand.command(from: name.rawValue as String) else { return }
        let bridge = Unmanaged<RemoteNotificationBridge>.fromOpaque(observer).takeUnretainedValue()
        Task { @MainActor in bridge.handle(command) }
    }

    private func handle(_ command: RemoteCommand) {
        Self.log.info("applied=\(command.rawValue, privacy: .public)")
        NotificationCenter.default.post(
            name: RemoteCommand.localName,
            object: nil,
            userInfo: [RemoteCommand.commandKey: command]
        )
    }
}
#endif
```

Hold it alive at App scope so the unretained pointer remains valid:

```swift
@main
struct MyApp: App {
    #if DEBUG
    @State private var bridge: RemoteNotificationBridge?
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
            #if DEBUG
                .task { if bridge == nil { bridge = RemoteNotificationBridge() } }
            #endif
        }
    }
}
```

Consume in the root view:

```swift
#if DEBUG
.onReceive(NotificationCenter.default.publisher(for: RemoteCommand.localName)) { note in
    guard let c = note.userInfo?[RemoteCommand.commandKey] as? RemoteCommand else { return }
    switch c {
    case .tabHome:     selectedTab = .home
    case .tabSettings: selectedTab = .settings
    }
}
#endif
```

### Consumer wiring — pick by where the state lives

- **SwiftUI `@State` inside a view** (Board Control's case): bridge republishes via `NotificationCenter.default`, view subscribes with `.onReceive`. Minimal invasion — no new observable class.
- **A single `@Observable` settings object** (GlutenMeNot's case): inject it into the bridge and mutate directly. Cleaner when the target state already has a single owner.
- **Ad-hoc callback closure**: inject a `(RemoteCommand) -> Void` at init. Useful for tests or when the dispatch target isn't stable at bridge init.

### Driving it from the Mac

Simulator (no ID needed — hits the currently booted sim):
```bash
xcrun simctl notify_post com.example.myapp.debug.tab.home
```

Physical device:
```bash
xcrun devicectl device notification post \
  --device <CoreDevice UUID> \
  --name com.example.myapp.debug.tab.home
```

(CoreDevice UUID comes from `xcrun devicectl list devices` — *not* the ECID used by `xcodebuild`.)

### Design rules

- **One enum is the source of truth.** Observer registration iterates `allCases`; the handler switches on the same enum. Adding a command = adding one case.
- **Prefix names with your bundle id.** Darwin notifications are process-wide; other apps observing would receive bare names.
- **Use `.deliverImmediately`.** Without it the C callback can be arbitrarily deferred.
- **Hop to `@MainActor` inside the callback.** The C callback arrives on an arbitrary thread.
- **Pass `self` unretained and keep the bridge alive via `@State` at App scope.** That's what makes the opaque pointer safe for the process lifetime. Don't `passRetained` unless you also manage teardown.
- **No payloads.** Darwin notifications carry only a name. Parameterise via enumerated commands (`tab.home` / `tab.settings`) or pre-write `UserDefaults` before posting. There is no `userInfo` dictionary.
- **Unit-test the parser.** Round-trip every `allCases` value through `command(from:)` and assert name uniqueness. No observer needed — it's pure string math, so no XCTest-in-simulator quirks.
- **Gate everything on `#if DEBUG`.** The file, the `@State`, the `.onReceive`. Shipping the bridge to production is a latent remote-control surface.

### When to add it to a new app

At the same commit you wire up the root view and tab bar. Cost: ~80 LoC + one test file. Payoff: every future iteration loop on that app is screen-tap-free and every XCUITest / agent workflow can preposition the app without tapping through chrome.

## Test architecture notes (Xcode / XCTest)

- `xcodebuild test` (single command) fails to find the module on first compile due to explicit-module-build ordering. Always use two-step `build-for-testing` → `test-without-building`.
- UI test targets need `ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES = YES` and `LD_RUNPATH_SEARCH_PATHS` including `@executable_path/Frameworks`. Without these, xctrunner launches but immediately dies with "ipc/mig server died" / SBMainWorkspace denial.
- UI test TestableReferences must NOT have `parallelizable = "YES"`. Parallel UI tests run on simulator *clones*, which fail with FBSOpenApplication RequestDenied.
- **Matching SwiftUI elements in XCUITest**: a `Text` inside a `Button` is absorbed into the button's accessibility element. Use `app.buttons["label"]`, not `app.staticTexts["label"]`.
- **Resetting between runs**: launch with explicit argument-domain overrides for any `@AppStorage` keys that must be deterministic — `removePersistentDomain` alone is unreliable, the UserDefaults argument domain has higher precedence.

## Troubleshooting

- **Tool not found in MCP** → check enabled workflows in `.xcodebuildmcp/config.yaml`. Missing ≠ broken; it's probably gated.
- **Build fails on simulator** → retry with `preferXcodebuild: true` in the MCP call, or inspect the build output directly.
- **UI element not hittable** → re-snapshot the view hierarchy after the layout change; the old coordinates are stale.
- **Wrong app launches** → confirm scheme + bundle id via the project-discovery and get-app-bundle-id tools.
- **MCP server disconnected** → stdio servers don't auto-reconnect. Exit Claude Code and resume with `claude --continue` / `claude -c`.
- **`FBSOpenApplicationServiceErrorDomain error 1, Locked`** on device test run → auto-lock kicked in. Set Auto-Lock to Never (see Autonomous on-device iteration). Low Power Mode reverts this.
- **`No profiles for '<bundle id>' were found`** → first build on a new device. Re-run with `-allowProvisioningUpdates` (see First-time device pairing).
- **Silent install failure on device after capability change** → entitlements now exceed what the embedded profile grants. Diagnose with `codesign -d --entitlements :- <APP>` vs `security cms -D -i <APP>/embedded.mobileprovision`, then rebuild with `-allowProvisioningUpdates`.
- **Two-device test run fails with `RequestDenied`** → `parallelizable = "YES"` on the testable reference triggers sim-clone behavior that breaks on real hardware. Remove it; use multiple `-destination` flags instead.
