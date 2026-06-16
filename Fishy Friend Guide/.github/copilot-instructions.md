# Fishy Friend Guide — Copilot Instructions

## Build & Test

The project uses **xcodegen** to manage the `.xcodeproj`. Run this after editing `project.yml` or adding/removing files:

```bash
cd "Fishy Friend Guide"
xcodegen generate
```

Build:
```bash
xcodebuild -scheme FishyFriendGuide -destination 'platform=macOS' build
```

Run all tests:
```bash
xcodebuild -scheme FishyFriendGuideTests -destination 'platform=macOS' test
```

Run a single test method:
```bash
xcodebuild -scheme FishyFriendGuideTests -destination 'platform=macOS' test \
  -only-testing:FishyFriendGuideTests/RecommendationEngineTests/testCowlitzAppearsInWinterRecommendations
```

Launch the built app:
```bash
open "$(find ~/Library/Developer/Xcode/DerivedData -name 'FishyFriendGuide.app' -path '*/Debug/*' | head -1)"
```

Regenerate the app icon (requires Pillow):
```bash
cd "Fishy Friend Guide"
python3 scripts/generate_icons.swift   # or use the Python block in session history
iconutil -c icns /tmp/FishyFriendGuide.iconset -o FishyFriendGuide/AppIcon.icns
```

## Architecture

### Dependency Flow

```
AppEnvironment (ObservableObject, @MainActor)
  ├── WaterwayRepository      ← western_wa_waterways.json   (static, loaded once)
  ├── RegulationRepository    ← regulations_2025.json       (static, loaded once)
  ├── HistoricalDataRepository ← historical_catch_data.json (static, loaded once)
  ├── RecommendationEngine    ← composed from the three repos above
  └── WDFWCreelService (actor) ← live data.wa.gov Socrata API (6h in-memory cache)
```

`AppEnvironment` is the single dependency container, injected via `.environmentObject()` at the `WindowGroup` level. All feature views receive it via `@EnvironmentObject private var env: AppEnvironment`. Never instantiate repos or the engine inside a view.

### Data Layers

**Static data** (bundle JSON, loaded at app startup):
- `western_wa_waterways.json` — 35 western WA rivers with coordinates, county, region, and `wdfwCRCCode` (WDFW catch area code)
- `regulations_2025.json` — 2025–2026 season dates, bag limits, gear restrictions per waterway/species. `Regulation` is NOT a SwiftData model; it's loaded from JSON only.
- `historical_catch_data.json` — 12-value monthly activity indices (0.0–1.0) per waterway/species, derived from 2021 catch reports and 2025 guide logbook

**Live data** (network, via `WDFWCreelService`):
- `data.wa.gov/resource/dpqw-kc2b.json` — WDFW Creel Summary Counts, updated nightly. Queried by `date_extract_woy()` to get same-week historical aggregates across all years.
- `data.wa.gov/resource/vkjc-s5u8.json` — Creel Fishery Manager lookup for `catch_area_description` by `catch_area_code`.

**User data** (SwiftData):
- `CatchRecord` — user's personal catch log entries

### Waterway ID / CRC Code Relationship

Each `Waterway` has:
- `id: String` — kebab-case key (e.g., `"cowlitz-river"`) used internally across all JSON files and for SwiftData foreign keys
- `wdfwCRCCode: String?` — WDFW catch record area code (e.g., `"561"`) — matches `catch_area_code` in the Socrata API

When matching live API results to waterways, prefer `wdfwCRCCode` exact match over name substring matching.

### Regulation Date Logic

`DateRange` uses a `month * 100 + day` integer encoding for year-agnostic season comparisons. Seasons that wrap the year boundary (e.g., Oct 1 – Mar 31) are handled by the `start > end` branch in `DateRange.contains(month:day:)`. Always use `Regulation.isOpen(on:)` — never compare raw dates.

### Recommendation Engine

`RecommendationEngine.recommendations(for:includeClosedFisheries:)` produces a ranked list by:
1. Linear interpolation of monthly activity indices (smooths the day-within-month transition)
2. Multiplication by regulation weight (open = 1.0, closed = 0.0, unknown = 0.5)
3. 0–1 normalization across the result set

Scores are normalized relative to each other, not absolute. Adding a new waterway with very high historical activity will lower all other scores.

### Navigation

`AppSection` enum drives the five sidebar sections: Map & Waterways, Hatch Guide, Regulations, Historical Catches, Weather. `NavigationState` (`@Observable`) holds `selectedSection` and `showingNewCatch`. The sidebar is in `ContentView.swift` — the `AppSection` switch in `detailContent` is the single place to wire new top-level screens.

## Design System — Arbor & Current

All color and typography tokens live in `Shared/DesignSystem/DesignSystem.swift`. Two parallel token sets exist:

- `Color.appPrimary` etc. — use when you need a `Color` value (fills, backgrounds, computed properties)
- `extension ShapeStyle where Self == Color` — use for `.foregroundStyle(.appPrimary)` dot syntax

**Do not use raw hex literals in views.** All colors go through the token system.

Typography scale: `.headlineLg` / `.headlineMd` / `.headlineSm` / `.bodyLg` / `.bodyMd` / `.labelLg` / `.labelMd` / `.monoData`. Data values (coordinates, regulation codes, catch numbers) use `.monoData`.

### Liquid Glass (macOS 26+)

Glass surfaces use helper modifiers on `View` defined in `DesignSystem.swift`:
- `.floatGlass(cornerRadius:tint:)` — map overlays and floating panels
- `.cardGlass(cornerRadius:)` — content cards
- `.chipGlass()` — tag pills (capsule shape)
- `.sidebarItemGlass(isSelected:)` — nav items

All helpers gate on `#available(macOS 26, *)` with `.regularMaterial` fallbacks. Never call `.glassEffect()` directly in views — use the helpers to keep fallback logic in one place.

For groups of interactive glass controls, wrap in `GlassEffectContainer` and use `.buttonStyle(.glass)` / `.buttonStyle(.glassProminent)`.

### Status Colors

| Token | Hex | Use |
|---|---|---|
| `.statusOpen` | `#006738` | Open fishery, active license |
| `.statusClosed` | `#ba1a1a` | Closed fishery, expired |
| `.statusRestricted` / `.conservationGold` | `#C5A352` | Restricted, check regulations, alerts |

## Key Conventions

- **Every new waterway must have a `wdfwCRCCode`** matching WDFW catch area codes. Without it, the live heatmap cannot match API results to map coordinates.
- **Regulation seasons are year-agnostic.** `openDateRanges` stores `startMonth/startDay/endMonth/endDay` — no year field. Adding year-specific closures requires a separate mechanism.
- **`WDFWCreelService` is an `actor`** — call its methods with `await`. It self-caches for 6 hours; don't add a second caching layer in the view model.
- **Regulations JSON is the source of truth** for season dates, not the WDFW live API. The live API (`WDFWCreelService`) is purely for historical catch volume — not for open/closed status.
- **Project structure changes require `xcodegen generate`** before building. Adding a Swift file in Finder without regenerating will cause "file not found" build errors.
- **App icon**: `AppIcon.icns` is checked in at `FishyFriendGuide/AppIcon.icns` and referenced via `CFBundleIconFile` in `Info.plist`. The asset catalog (`Assets.xcassets`) is present but the icon is not read from it. Regenerate with the Python render script in `scripts/`.

## External APIs

| Dataset | Socrata ID | Used for |
|---|---|---|
| WDFW Creel Summary Counts | `dpqw-kc2b` | Map heatmap: weekly catch by river section |
| Creel Fishery Manager | `vkjc-s5u8` | Section descriptions by `catch_area_code` |

SoQL filter pattern for week-of-year aggregation:
```
date_extract_woy(survey_date) between {startWeek} and {endWeek}
AND species_name in ('Steelhead','Chinook','Coho','Pink')
```
No API key required. Rate limit is generous for read-only queries.
