---
name: apple-design-intent
description: Sanity-check iOS/iPadOS/macOS design decisions against Apple's intent (HIG, WWDC, Liquid Glass) before writing custom chrome. Use this skill whenever the user is making a UI design choice — "make X look like Y", "should this be a sidebar / inspector / tab bar / sheet", picking colors / fonts / symbols, refactoring for iOS 26 Liquid Glass, or about to hand-roll something the system already provides. Trigger especially when the user proposes replacing a system control with a custom one (custom glass blur, custom navigation column, custom tab bar, custom sheet), when symmetry between two system slots is requested (e.g. "make the inspector look like the sidebar"), or when an iOS-26-era request would naturally inherit Liquid Glass from a native control. The point is to surface Apple's design *intent* — what they meant, not just what they shipped — so the user can choose system-aligned defaults rather than relearning Apple's asymmetries the hard way. Companion to `swiftui-liquid-glass` (which covers *how* to implement Liquid Glass once a decision is made); this skill covers *whether* and *why*.
---

# Apple Design Intent

## What this skill is for

Help the user default to Apple's intended design when building iOS / iPadOS / macOS UI, and **flag drift before custom code gets written**. Apple ships intentional design decisions whose reasoning is often hidden in WWDC sessions or HIG passages — by the time the user notices "this looks off," they've usually already paid for the custom code.

The user is candid that they're inexperienced in design and prefers shipping native rather than fighting the OS. This skill is the "is this aligned with what Apple wants?" check at decision time.

It is *not* a code recipe. For implementation patterns, defer to:
- `swiftui-liquid-glass` — how to apply `.glassEffect`, `GlassEffectContainer`, glass button styles correctly
- `swiftui-ui-patterns` — TabView / NavigationStack / sheets / state ownership
- `swiftui-view-refactor`, `swiftui-performance-audit` — code-level concerns

## How to apply

When you spot a design decision being made, run this check **before suggesting custom code**:

1. **Does Apple already ship this?** Sidebar, inspector, tab bar, navigation bar, toolbar, sheet, popover, alert, menu, share sheet, contextual menu, search field — these all have system implementations that get Liquid Glass and accessibility for free.

2. **What's Apple's *intent* for it?** If the user wants two system slots to look identical, or wants a system control to behave differently, check whether Apple meant for them to differ. WWDC sessions are the source of truth — they explicitly explain *why* things look the way they do, in a way the API docs don't.

3. **If there's a mismatch:**
   - Is the user's need a *real* product requirement (custom interaction, brand identity, a feature Apple doesn't expose), or is it *aesthetic preference* (looks better to me)?
   - For aesthetic mismatches, surface Apple's intent and recommend going with it. The user explicitly asked to be flagged here — they want to default to native.
   - For real product needs, document the trade-off (what you're giving up: Liquid Glass auto-apply, sidebar collapse, accessibility, future iOS updates) before writing the custom version.

4. **Phrase the flag clearly.** Something like:
   > "Apple actually styles these two slots differently on purpose — [WWDC quote / HIG link]. Going with the system gives you [X for free]. The custom version costs [Y]. Want to follow Apple's default, or do you have a reason to override?"

   Then wait for the user to choose. Don't write custom chrome unless they confirm.

## Load-bearing intents to know

These are non-obvious places where Apple's design *contradicts* what an inexperienced eye would design. Mention them whenever they're relevant.

### Sidebar vs inspector are asymmetric on purpose (iPadOS 26)

`NavigationSplitView`'s sidebar is a **floating glass pane** that hovers over the content. `.inspector(isPresented:)` is **edge-to-edge glass alongside the content** — flat, no rounding, bleeds to the screen edges.

> *"Sidebars appear as a pane of glass that floats above the window's content, whereas inspectors use an edge-to-edge glass that sits alongside the content."* — WWDC25 session 310

The inspector's chrome is **not user-replaceable** in the public API (FB12326152 confirms `presentationBackground` is ignored on inspectors; `.containerBackground(.clear, for: .navigationSplitView)` targets the split-view backdrop, not the inspector column). Mail, Notes, Reminders, Files all accept this asymmetry. If the user asks to make an inspector "look like the sidebar," surface this — it's not solvable in public SwiftUI and Apple intentionally distinguishes them.

### Liquid Glass is inherited, not painted

iOS 26+ system controls (sidebars, tab bars, nav bars, toolbars, sheets) get Liquid Glass automatically. The user's job is to **stop covering it up** — full-bleed colored backgrounds on these controls hide the glass. `glassEffect(.regular, in:)` is for *custom* surfaces (cards, chips, custom buttons), not for replacing system column chrome.

When someone says "the system X doesn't look glassy enough," check first whether they're painting over it (a `Color.background` that ignoresSafeArea is a common offender).

### Tab bar vs sidebar is platform-driven

iPhone gets a **tab bar** (Liquid Glass capsule on iOS 26). iPad regular gets a **sidebar** in `NavigationSplitView`. iPad compact (split-screen multitasking) gets the tab bar back. SwiftUI's `TabView` + `NavigationSplitView` paired together handles this transition — don't pick one or the other globally.

### Don't replace system sheets / alerts / menus

`.sheet`, `.alert`, `.confirmationDialog`, `Menu`, `.popover`, `.fileImporter`, `ShareLink`, `EditButton`, `SearchField` — all get Liquid Glass and OS-level integrations (drag-to-dismiss, dynamic type, voiceover, focus). Custom popovers using `ZStack` overlays usually regress accessibility and miss future iOS updates. Almost always the answer is "use the system one."

### Symbols: SF Symbols is the default

SF Symbols is integrated with system controls (auto-tinted, auto-scaled, accessible labels). Mixing custom symbol fonts (Material Symbols, Phosphor, etc.) is fine in app *content*, but for **system control affordances** (toolbar buttons, tab bar items, navigation bar icons), SF Symbols is what Apple expects. Custom symbol fonts in those slots can break dynamic type and dark mode tinting.

### Color: prefer semantic, prefer system

`.primary`, `.secondary`, `Color(.systemBackground)`, `.tint`, `.accentColor` all adapt to dark mode, reduced transparency, and high contrast for free. Custom hex colors don't. For app brand color, use `.tint(...)` at the root rather than hard-coding into individual controls.

For Board Control specifically, the heatmap palettes are an explicit product concern (see `board-control-colors`); the framing here applies to everything *outside* the board.

## When to defer to other skills

| If the question is about… | Use this skill |
|--------------------------|----------------|
| **Should** I use Liquid Glass / a sidebar / a tab bar / X system control? | This one |
| Is my custom design fighting Apple's intent? | This one |
| **How** do I write `.glassEffect` correctly? | `swiftui-liquid-glass` |
| **How** do I structure TabView + NavigationStack? | `swiftui-ui-patterns` |
| Specific SwiftUI performance / refactor / concurrency? | The dedicated SwiftUI skills |
| Color math (OKLab, gradient ramps, palettes)? | `color-theory`, `board-control-colors` |
| M3 / Material design? | `material-3` (deliberately *not* the iOS-native track) |

## Authoritative sources

When you need to verify Apple's intent live, fetch these (WebFetch is fine — Apple's design guidance evolves between iOS major versions, so don't rely on training data):

- **WWDC25 session 310** — "Build an AppKit app with the new design" — sidebar/inspector intent, AppKit but the design language carries to SwiftUI
  https://developer.apple.com/videos/play/wwdc2025/310/
- **WWDC25 session 323** — "Build a SwiftUI app with the new design" — SwiftUI-side Liquid Glass adoption guide
  https://developer.apple.com/videos/play/wwdc2025/323/
- **Adopting Liquid Glass** — Apple's official adoption guide, updated each iOS version
  https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass
- **Human Interface Guidelines** — sections on Sidebars, Inspectors, Tab bars, Sheets, Toolbars, Materials
  https://developer.apple.com/design/human-interface-guidelines/
- **iOS 26 / iPadOS 26 release notes** — when the user asks why something changed mid-version
  https://developer.apple.com/documentation/ios-ipados-release-notes

For implementation specifics (exact modifiers, parameters, examples), use `context7` to fetch live SwiftUI / Apple SDK docs — don't recite from training data, since Apple changes APIs between iOS majors.

## How to phrase the flag (examples)

**Good — surfaces intent, presents the trade-off, lets the user choose:**
> "Apple actually styles inspectors edge-to-edge on iPadOS 26 — sidebars float, inspectors don't (WWDC25 session 310). The asymmetry is deliberate. We can build a custom rail to match, but we'd give up the system's auto-collapse-and-redistribute when the sidebar hides. Want symmetric, or want to roll with Apple's default?"

**Bad — too pushy, doesn't explain why:**
> "You can't do that, Apple doesn't allow it."

**Bad — surfaces nothing, just builds the custom thing:**
> *(silently writes `.glassEffect` and padding)*

The point is to inform the choice, not block it. Default to system; opt out with eyes open.

## When the user explicitly says "I want custom"

Then build it. Capture *why* in a comment near the custom code so future revisits know the trade-off was deliberate. Save a project memory if the override is load-bearing (a brand decision, a recurring pattern). Move on.
