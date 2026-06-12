---
name: color-theory
description: >
  General color theory and perceptually uniform color math. Use whenever
  the user asks about color spaces (RGB/HSL/OKLab/OKLCH), picking palettes,
  gradient ramps, perceptual uniformity, luminance balance, colorblind
  accessibility, contrast/readability, blending or interpolation between
  colors, gamut mapping, or diagnosing "why do these colors look wrong."
  Applies to UI design, data-viz heatmaps, charts, diverging/sequential/
  bivariate scales, and any color-math question — not just blending.
  For Board Control's domain-specific color rules, see `board-control-colors`.
---

# Color Theory

Default recommendation: **design color ramps and do all interpolation /
blending in OKLab or OKLCH.** sRGB channel math is perceptually
non-uniform; equal numeric steps produce unequal perceived changes.
Reserve sRGB for the final output color only. The rest of this skill
covers when and how to apply that.

## Board Control context (historical)

## What We're Visualizing

Board Control is a chess heatmap. Every square encodes **who controls it and how intensely**. The data per square is a set of integer counts:

| Data | Meaning |
|------|---------|
| `safeWhite` / `safeBlack` | How many pieces of each side can reach this **empty** square |
| `attackWhite` / `attackBlack` | How many pieces of each side can **capture** an enemy piece here |
| `defendWhite` / `defendBlack` | How many pieces of each side **protect** a friendly piece here |

The visualization must communicate:
1. **Which side dominates** (direction)
2. **How strongly** (magnitude)
3. **Whether it's contested** (both sides present)
4. **The nature of the relationship** (safe vs. attack vs. defend)

This is fundamentally a **bivariate** problem: two competing quantities (white vs. black) mapped to color simultaneously, with additional categorical context (empty/attacked/defended/king).

## The Current Approach: Direct RGB Channel Mapping

The current `ColorMapper.swift` assigns each data dimension to a raw RGB channel:

```
Empty squares:   Green = white control, Blue = black control
Occupied pieces: Red = attack intensity, Green = defend intensity
King:            Purple (safe) or Red (in check)
```

Each channel is normalized against a global max:
```swift
let unit = 1.0 / Double(maxCombined)
let g = Double(safeW) * unit   // green channel
let b = Double(safeB) * unit   // blue channel
```

**What this gets right:**
- Two variables map to independent channels, so mixed colors (cyan, yellow) emerge naturally
- Global normalization preserves relative intensity across the board
- Black background means "no control" — absence = darkness

**What this gets wrong perceptually:**
- **Unequal brightness across hues.** Green appears ~3.5x brighter than blue at the same RGB value (luminance: G=0.7152, B=0.0722). A square with safeW=3 looks dramatically brighter than one with safeB=3, even though both represent equal control intensity. White's territory always "pops" more than black's.
- **Non-uniform interpolation.** The step from 1→2 pieces looks like a bigger change than 5→6 pieces in sRGB, because sRGB gamma compresses highlights.
- **Contested squares are ambiguous.** Cyan (green+blue) and yellow (red+green) don't have intuitive "tug-of-war" semantics. A viewer must learn that cyan means "contested empty" and yellow means "well-defended."
- **Red-green problem.** The attack/defend encoding (red vs. green) is invisible to the ~8% of males with red-green color vision deficiency.

## Intensity Scaling: The Transfer Function

Before worrying about *which* color space to blend in, consider *how* you map the raw count to an intensity value. The current code uses linear scaling:

```swift
let intensity = Double(count) / Double(maxValue)  // linear: 0, 0.125, 0.25, ... 1.0
```

This is mathematically clean but perceptually misleading. The goal isn't to show an exact count — it's to convey the **sense of control**. In chess, the jump from "nobody reaches this square" to "one piece reaches it" is the most important distinction. The jump from "6 pieces" to "7 pieces" barely matters. Linear scaling gives them equal visual weight.

### The Problem with Linear

With `maxSafe = 8` and linear scaling:
- 0 pieces → 0.000 (black)
- 1 piece  → 0.125 (barely visible — but this is the most important transition!)
- 2 pieces → 0.250
- 8 pieces → 1.000

The first piece of control is nearly invisible. Meanwhile, the high end is wasted on distinctions nobody cares about.

### Transfer Function Options

A **transfer function** (or tone curve) reshapes the input before it becomes color intensity. Think of it like the contrast/brightness curves in photo editing — same data, different emphasis.

#### Power Curve (Gamma)

```swift
func powerScale(_ t: Double, gamma: Double) -> Double {
    // gamma < 1 emphasizes low values (opens up shadows)
    // gamma > 1 emphasizes high values (compresses shadows)
    return pow(t, gamma)
}
```

- `gamma = 0.5` (square root): `1/8 → 0.35`, `2/8 → 0.50`, `4/8 → 0.71`. Low counts get much more visual space.
- `gamma = 0.33` (cube root): Even more aggressive. `1/8 → 0.50`. One piece of control is already half brightness.
- `gamma = 1.0`: Linear (current behavior).

**Recommendation:** `gamma ≈ 0.45–0.55` is a good starting point. The first piece of control becomes clearly visible, while the difference between 5 and 8 pieces compresses into a small range — matching how players think about control.

#### Logarithmic

```swift
func logScale(_ t: Double) -> Double {
    guard t > 0 else { return 0 }
    // log1p(t * base) / log1p(base) maps [0,1] → [0,1] with a log curve
    let base = 6.0  // higher = more compression at the top
    return log(1.0 + t * base) / log(1.0 + base)
}
```

Similar feel to a low gamma but with a different curve shape. The `base` parameter controls how aggressively it compresses the high end.

#### Step / Quantized

```swift
func stepScale(_ t: Double, steps: Int) -> Double {
    // Quantize to N discrete levels
    return (floor(t * Double(steps)) / Double(steps - 1)).clamped(to: 0...1)
}
```

Reduces the gradient to discrete bands (like a topographic map). With `steps = 4`, you get four clear zones: none, light, medium, heavy. This trades precision for readability — you can't tell the difference between 5 and 6, but the four levels are unambiguous at a glance.

#### Sigmoid / S-Curve

```swift
func sigmoidScale(_ t: Double, midpoint: Double = 0.3, steepness: Double = 8.0) -> Double {
    // Logistic function remapped to [0,1]
    let x = (t - midpoint) * steepness
    let s = 1.0 / (1.0 + exp(-x))
    let s0 = 1.0 / (1.0 + exp(midpoint * steepness))
    let s1 = 1.0 / (1.0 + exp(-(1.0 - midpoint) * steepness))
    return (s - s0) / (s1 - s0)
}
```

Creates a "snap" around a midpoint — values below it compress toward dark, values above compress toward bright, and the transition zone has maximum contrast. With `midpoint = 0.25` (2 pieces out of 8), the biggest visual change happens right around "is there meaningful control here?" This is the most opinionated option but can produce the most readable boards if tuned well.

### How Transfer Functions Interact with Color Spaces

The transfer function is applied **before** the color mapping, regardless of which approach you use:

```swift
let rawT = Double(count) / Double(maxValue)     // 0...1
let t = powerScale(rawT, gamma: 0.5)            // reshaped 0...1

// Then use t in any color approach:
// Approach 1 (diverging): feed t into L and C calculations
// Approach 2 (bivariate OKLAB): use t as the channel weight
// Current RGB: use t as the channel value
```

This means you can experiment with transfer functions independently of the color scheme — they're orthogonal improvements. A power curve of 0.5 applied to the current RGB scheme would already be a significant improvement in readability, with a one-line change.

### Applying to the Current Code

The simplest possible improvement to the current `ColorMapper.swift`:

```swift
// Add this helper
private static func scale(_ count: Int, max: Int) -> Double {
    guard max > 0 else { return 0 }
    let t = Double(count) / Double(max)
    return pow(t, 0.5)  // square root — opens up low values
}

// Then replace all the linear divisions:
// Before: let intensity = Double(safeW) / Double(max(maxValues.maxSafe, 1))
// After:  let intensity = scale(safeW, max: maxValues.maxSafe)
```

### Choosing a Transfer Function

| Function | Best for | Feel |
|----------|----------|------|
| Power (gamma 0.5) | General use, safe default | Smooth, natural, "one piece matters" |
| Power (gamma 0.33) | Very sparse positions | Aggressive — even trace control glows |
| Logarithmic | Wide count ranges | Similar to power, slightly different curve |
| Sigmoid (mid=0.25) | Emphasizing the "is it controlled?" threshold | Snappy, binary feel with smooth edges |
| Step (4 levels) | Maximum readability | Topographic map, loses precision |

Start with **power 0.5** and adjust from there. It's the least opinionated nonlinear option and produces immediately better results than linear.

## Color Spaces: A Quick Reference

Read `references/color-spaces.md` for full mathematical details and conversion code. The key takeaway:

| Space | Uniform? | Intuitive axes? | SwiftUI native? |
|-------|----------|-----------------|-----------------|
| sRGB | No | No (device channels) | Yes |
| HSL/HSV | No | Somewhat (hue/sat/light) | HSB only |
| CIELAB | Approximately | Yes (L/green-red/blue-yellow) | Via CGColor |
| OKLAB | Yes | Yes (same axes, better calibrated) | Manual conversion |
| OKLCH | Yes | Best (lightness/chroma/hue) | Manual conversion |

**OKLCH is the recommended space for designing color scales.** You specify lightness, colorfulness, and hue angle independently — and equal numeric steps produce equal perceived changes.

## Alternative Approaches

### Approach 1: OKLCH Diverging Scale (recommended starting point)

Map white-vs-black control to a **diverging scale** — one hue for white-dominant, another for black-dominant, neutral center for contested/empty.

```
Strong Black    ←——→    Neutral    ←——→    Strong White
deep teal              dark gray           warm amber
L=0.35, C=0.12        L=0.25, C=0        L=0.35, C=0.12
H=200°                 —                   H=70°
```

**Design:**
- The **sign** of (whiteControl - blackControl) picks the hue
- The **magnitude** controls chroma and lightness deviation from neutral
- Equal control cancels to neutral gray — instantly readable as "contested"
- Luminance is symmetric: equal white and black intensities produce equal brightness

```swift
func emptySquareColor(safeW: Int, safeB: Int, maxSafe: Int) -> Color {
    let wNorm = Double(safeW) / Double(max(maxSafe, 1))
    let bNorm = Double(safeB) / Double(max(maxSafe, 1))
    
    // Net control: positive = white dominant, negative = black dominant
    let net = wNorm - bNorm
    // Total intensity: how "active" this square is
    let intensity = (wNorm + bNorm) / 2.0
    
    let hue: Double = net >= 0 ? 70.0 : 200.0    // amber vs teal
    let t = abs(net)
    
    // Lightness: dark base, gets slightly lighter with more activity
    let L = 0.20 + intensity * 0.15 + t * 0.20
    // Chroma: zero when balanced, increases with dominance
    let C = t * 0.14
    
    return oklchToColor(L: L, C: C, H: hue)
}
```

**Pros:** Intuitive "temperature" metaphor, colorblind-safe (blue-orange axis), perceptually uniform, contested squares are visually distinct.
**Cons:** Loses the independent magnitude information — "1 white + 1 black" and "5 white + 5 black" both map to neutral, though intensity can modulate lightness to recover some of this.

### Approach 2: OKLAB Bivariate Blend

Keep the two-channel independence of the current approach but do the blending in OKLAB for perceptual uniformity.

Define two "pure" endpoints in OKLAB:
```
White control at full intensity: OKLCH(L=0.75, C=0.16, H=145°)  → vivid green
Black control at full intensity: OKLCH(L=0.75, C=0.16, H=260°)  → vivid blue
No control:                      OKLCH(L=0.15, C=0.00, H=—)     → near-black
```

For each square, compute the OKLAB coordinates of each side's contribution and **add** them:

```swift
func emptySquareColor(safeW: Int, safeB: Int, maxCombined: Int) -> Color {
    let unit = 1.0 / Double(max(maxCombined, 1))
    let wt = Double(safeW) * unit  // 0...1
    let bt = Double(safeB) * unit  // 0...1
    
    // White control direction in OKLAB (green-ish)
    let wLab = oklchToOklab(L: 0, C: 0.16, H: 145)  // just the a,b direction
    // Black control direction in OKLAB (blue-ish)
    let bLab = oklchToOklab(L: 0, C: 0.16, H: 260)
    
    // Combine: base darkness + each side's contribution to lightness and chromaticity
    let L = 0.15 + wt * 0.30 + bt * 0.30
    let a = wt * wLab.a + bt * bLab.a
    let b = wt * wLab.b + bt * bLab.b
    
    return oklabToColor(L: L, a: a, b: b)
}
```

**Pros:** Preserves independent magnitude (1+1 vs 5+5 are visually distinct), perceptually uniform, keeps the "additive light" metaphor.
**Cons:** The mixed color (green + blue in OKLAB) may land on a hue the user doesn't expect. Needs careful endpoint tuning. More complex than the diverging approach.

### Approach 3: Luminance-Encoded with Hue Category

Use **lightness** as the primary intensity channel and **hue** only for the categorical distinction (who dominates):

```
Empty, white controls:    Hue = warm (amber/orange), L scales with count
Empty, black controls:    Hue = cool (teal/cyan), L scales with count
Empty, contested:         Hue = neutral/white, L scales with total count
Attacked piece:           Hue = red/magenta, L scales with attack count
Defended piece:           Hue = yellow/gold, L scales with defense count
Contested piece:          Hue shifts red→yellow based on attack/defend ratio, L scales with total
```

```swift
func emptySquareColor(safeW: Int, safeB: Int, maxSafe: Int, maxCombined: Int) -> Color {
    if safeW > 0 && safeB > 0 {
        // Contested: hue encodes ratio, lightness encodes total
        let ratio = Double(safeW) / Double(safeW + safeB)  // 0=all black, 1=all white
        let hue = 200.0 + ratio * (70.0 - 200.0)           // teal → amber
        let total = Double(safeW + safeB) / Double(max(maxCombined, 1))
        return oklchToColor(L: 0.20 + total * 0.55, C: 0.10 + total * 0.06, H: hue)
    } else if safeW > 0 {
        let t = Double(safeW) / Double(max(maxSafe, 1))
        return oklchToColor(L: 0.20 + t * 0.55, C: t * 0.14, H: 70)
    } else if safeB > 0 {
        let t = Double(safeB) / Double(max(maxSafe, 1))
        return oklchToColor(L: 0.20 + t * 0.55, C: t * 0.14, H: 200)
    }
    return .black
}
```

**Pros:** Lightness carries the most perceptual weight, so intensity differences are immediately obvious. Hue is categorical — it tells you *who*, lightness tells you *how much*. Prints well in grayscale. Accessible.
**Cons:** Contested squares use a continuous hue shift which may be harder to read than a discrete mixed color. You lose the "additive" visual where two armies "pile up" on a square.

### Approach 4: Perceptually Corrected RGB (minimal change)

Keep the current RGB channel mapping but correct for luminance imbalance. Apply a perceptual correction so that equal counts produce equal perceived brightness:

```swift
// Attempt to equalize perceived brightness across channels
func correctedChannel(_ value: Double, channel: ColorChannel) -> Double {
    // Approximate perceptual correction factors
    // These compensate for sRGB luminance coefficients (R=0.2126, G=0.7152, B=0.0722)
    let correction: Double
    switch channel {
    case .red:   correction = 1.0      // baseline
    case .green: correction = 0.55     // green is too bright, scale it down
    case .blue:  correction = 2.5      // blue is too dim, scale it up (clamped later)
    }
    return min(value * correction, 1.0)
}
```

**Pros:** Minimal code change, preserves the existing color language, easy to A/B test.
**Cons:** Still not perceptually uniform (just less wrong), still has the red-green accessibility issue, doesn't solve the conceptual problems with the color mapping.

## Piece Colors and Attack/Defend

The same principles apply to occupied squares. The current scheme:
- Attacked only → red gradient
- Defended only → yellow gradient  
- Both → red + green (R=attacks, G=defends)

Alternative mappings in OKLCH:

| State | Current | OKLCH Diverging | OKLCH Categorical |
|-------|---------|-----------------|-------------------|
| Attacked only | Red | Warm red, L by count | H=25 (red-orange), L by count |
| Defended only | Yellow | Cool green, L by count | H=145 (green), L by count |
| Contested | R+G mix | Hue from red→green by ratio, L by total | Same, perceptually uniform |

For colorblind safety, consider replacing red/green with **magenta/teal** or **orange/blue** for the attack/defend axis. These remain distinguishable under deuteranopia/protanopia.

## Implementation Guide

### OKLAB/OKLCH Conversion in Swift

Add these types and conversions. They have no dependencies and are fast enough for per-frame board rendering (64 squares):

```swift
struct OKLab {
    var L: Double  // 0...1 (perceived lightness)
    var a: Double  // ~-0.4...0.4 (green ← → red)
    var b: Double  // ~-0.4...0.4 (blue ← → yellow)
}

struct OKLCH {
    var L: Double  // 0...1
    var C: Double  // 0...~0.4 (chroma / colorfulness)
    var H: Double  // 0...360 (hue angle in degrees)
    
    var lab: OKLab {
        let hRad = H * .pi / 180.0
        return OKLab(L: L, a: C * cos(hRad), b: C * sin(hRad))
    }
}

extension OKLab {
    var color: Color {
        let (r, g, b) = toLinearRGB()
        return Color(
            red: linearToSRGB(clamp01(r)),
            green: linearToSRGB(clamp01(g)),
            blue: linearToSRGB(clamp01(b))
        )
    }
    
    func toLinearRGB() -> (Double, Double, Double) {
        let l_ = L + 0.3963377774 * a + 0.2158037573 * b
        let m_ = L - 0.1055613458 * a - 0.0638541728 * b
        let s_ = L - 0.0894841775 * a - 1.2914855480 * b
        
        let l = l_ * l_ * l_
        let m = m_ * m_ * m_
        let s = s_ * s_ * s_
        
        let r = +4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
        let g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
        let b = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
        
        return (r, g, b)
    }
    
    private func linearToSRGB(_ c: Double) -> Double {
        c <= 0.0031308 ? 12.92 * c : 1.055 * pow(c, 1.0 / 2.4) - 0.055
    }
    
    private func clamp01(_ v: Double) -> Double { min(max(v, 0), 1) }
}

extension OKLCH {
    var color: Color { lab.color }
}
```

### Testing Color Schemes

When evaluating a new scheme:

1. **Check the starting position.** Most squares should show some control. The two rows in front of each army should glow with that side's color. The center should be contested.

2. **Play 1. e4.** The d5/f5 squares should shift toward white control (pawn diagonals). The e4 square changes from empty-controlled to occupied.

3. **Check luminance symmetry.** A square with safeW=3, safeB=0 and one with safeW=0, safeB=3 should appear equally bright/prominent (just different hue). If one pops more than the other, there's a luminance imbalance.

4. **Drag a piece.** The live preview should show smooth color transitions as the piece moves across the board. Jarring jumps suggest a discontinuity in the color function.

5. **Check colorblind safety.** Open Sim Daltonism (free Mac app) or use Xcode's accessibility inspector to simulate deuteranopia. All categories should remain distinguishable.

6. **Verify on black background.** The board background is black. Low-intensity colors should still be visible (not lost in the background). If your scheme uses very dark colors for low counts, consider adding a minimum lightness floor.

## Decision Framework

| Priority | Approach 1 (Diverging) | Approach 2 (OKLAB Bivariate) | Approach 3 (Luminance-first) | Approach 4 (Corrected RGB) |
|----------|----------------------|----------------------------|-----------------------------|-----------------------------|
| "Feels like chess territory" | Best | Good | Good | Fair |
| Colorblind safe | Best (blue-orange) | Good (tune endpoints) | Best | Poor (red-green) |
| Shows independent magnitudes | Needs intensity encoding | Best | Good | Good |
| Minimal code change | Moderate | Moderate | Moderate | Minimal |
| Perceptual uniformity | Best | Best | Best | Fair |
| Familiar to current users | Different | Similar | Different | Very similar |

Start with **Approach 1** if you want the clearest "who controls what" reading. Use **Approach 2** if preserving the independent-magnitude information (seeing that 5+5 is more intense than 1+1) is important. Use **Approach 4** if you want a quick improvement with minimal risk.

## Gamut Clamping

OKLCH can produce colors outside the sRGB gamut (the linear RGB values go below 0 or above 1). When this happens, the simple `clamp01` approach clips the color, which shifts its hue. For more accurate gamut mapping, reduce chroma iteratively until the color fits:

```swift
extension OKLCH {
    /// Reduce chroma until the color fits within sRGB gamut
    var gamutMapped: OKLCH {
        var c = self
        for _ in 0..<20 {
            let (r, g, b) = c.lab.toLinearRGB()
            if r >= 0 && r <= 1 && g >= 0 && g <= 1 && b >= 0 && b <= 1 {
                return c
            }
            c.C *= 0.95
        }
        c.C = 0  // fall back to achromatic
        return c
    }
}
```

This is rarely needed for the muted colors typical in data visualization, but it's essential if you push chroma high.
