# Color Spaces Reference

## Table of Contents
1. [sRGB](#srgb)
2. [HSL / HSV / HSB](#hsl--hsv--hsb)
3. [CIELAB (L*a*b*)](#cielab)
4. [LCH (polar CIELAB)](#lch)
5. [OKLAB](#oklab)
6. [OKLCH (polar OKLAB)](#oklch)
7. [Conversion Pipeline](#conversion-pipeline)
8. [Human Luminance Perception](#human-luminance-perception)
9. [Colorblind Accessibility](#colorblind-accessibility)

---

## sRGB

**Axes:** Red (0-1), Green (0-1), Blue (0-1) — intensity of three display primaries.

**Gamma transfer function:**
```
Linear → sRGB:
  C_srgb = 12.92 * C_linear                          if C_linear ≤ 0.0031308
  C_srgb = 1.055 * C_linear^(1/2.4) - 0.055          otherwise

sRGB → Linear:
  C_linear = C_srgb / 12.92                           if C_srgb ≤ 0.04045
  C_linear = ((C_srgb + 0.055) / 1.055)^2.4           otherwise
```

**Interpolation:** Linear in sRGB is perceptually nonlinear. Complementary color pairs (blue↔yellow) pass through gray at the midpoint. Interpolation in *linear* RGB (before gamma) is slightly better but still not perceptually uniform.

**SwiftUI:** `Color(red:green:blue:)` — native, default color space.

---

## HSL / HSV / HSB

**Axes:**
- Hue: 0°-360° color wheel angle (0°=red, 120°=green, 240°=blue)
- Saturation: 0 (gray) to 1 (fully chromatic)
- Lightness (HSL): 0=black, 0.5=pure color, 1=white
- Value/Brightness (HSV/HSB): 0=black, 1=full brightness

**Conversion:** Pure geometric rearrangement of the RGB cube — no perceptual correction. HSL "Lightness" does NOT match perceived brightness.

**Why it misleads:** `HSL(60°, 1.0, 0.5)` (yellow) has luminance ~0.93; `HSL(240°, 1.0, 0.5)` (blue) has luminance ~0.07. Both have the same HSL "lightness" but appear vastly different in brightness.

**SwiftUI:** `Color(hue:saturation:brightness:)` — this is HSB, not HSL. No HSL initializer.

---

## CIELAB

**Axes:**
- L*: Lightness, 0 (black) to 100 (white). Designed to be perceptually linear.
- a*: Green (negative) ↔ Red (positive), roughly -128 to +127
- b*: Blue (negative) ↔ Yellow (positive), roughly -128 to +127

**Conversion from linear RGB:**
1. Linear RGB → CIE XYZ:
```
X = 0.4124564 * R + 0.3575761 * G + 0.1804375 * B
Y = 0.2126729 * R + 0.7151522 * G + 0.0721750 * B
Z = 0.0193339 * R + 0.1191920 * G + 0.9503041 * B
```

2. XYZ → Lab (D65 white point: Xn=0.9505, Yn=1.0, Zn=1.089):
```
f(t) = t^(1/3)                        if t > (6/29)^3 ≈ 0.008856
f(t) = t / (3*(6/29)^2) + 4/29        otherwise

L* = 116 * f(Y/Yn) - 16
a* = 500 * (f(X/Xn) - f(Y/Yn))
b* = 200 * (f(Y/Yn) - f(Z/Zn))
```

**Perceptual uniformity:** Approximately uniform. Known distortions in blue-purple region where hue lines curve.

**SwiftUI:** No direct initializer. Can use `CGColorSpace(name: .genericLab)` to create a `CGColor`, then wrap in `Color(cgColor:)`.

---

## LCH

The polar form of CIELAB.

**Axes:**
- L: Same as L* (0-100)
- C: Chroma = √(a*² + b*²) — colorfulness
- H: Hue = atan2(b*, a*) in degrees

**Interpolation:** Interpolate L and C linearly, H along the shorter arc. Better than raw a*b* interpolation for preserving hue through transitions.

---

## OKLAB

Created by Bjorn Ottosson (2020). The current best practice for perceptually uniform color work.

**Axes:**
- L: Perceived lightness, 0 (black) to 1 (white)
- a: Green (negative) ↔ Red (positive), roughly -0.4 to +0.4
- b: Blue (negative) ↔ Yellow (positive), roughly -0.4 to +0.4

**Conversion from linear RGB:**

```
Step 1: Linear RGB → LMS (cone responses)
l = 0.4122214708 * R + 0.5363325363 * G + 0.0514459929 * B
m = 0.2119034982 * R + 0.6806995451 * G + 0.1073969037 * B
s = 0.0883024619 * R + 0.2024326843 * G + 0.6892649146 * B

Step 2: Cube root (perceptual nonlinearity)
l' = cbrt(l)
m' = cbrt(m)
s' = cbrt(s)

Step 3: LMS' → OKLAB
L = 0.2104542553 * l' + 0.7936177850 * m' - 0.0040720468 * s'
a = 1.9779984951 * l' - 2.4285922050 * m' + 0.4505937099 * s'
b = 0.0259040371 * l' + 0.7827717662 * m' - 0.8086757660 * s'
```

**Inverse (OKLAB → linear RGB):**

```
Step 1: OKLAB → LMS'
l' = L + 0.3963377774 * a + 0.2158037573 * b
m' = L - 0.1055613458 * a - 0.0638541728 * b
s' = L - 0.0894841775 * a - 1.2914855480 * b

Step 2: Cube (undo cbrt)
l = l' * l' * l'
m = m' * m' * m'
s = s' * s' * s'

Step 3: LMS → linear RGB
R = +4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
G = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
B = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
```

**Why OKLAB is better than CIELAB:**
- Hue lines are straight (interpolating between two hues doesn't shift through unexpected intermediates)
- Chroma is consistent across hues (the same C value looks equally vivid at any hue)
- The blue-purple region is correctly calibrated
- The L channel accurately matches perceived brightness at all hues

**SwiftUI:** No direct support. Convert to sRGB using the pipeline above.

---

## OKLCH

The polar form of OKLAB — the most intuitive perceptually uniform space.

**Axes:**
- L: Perceived lightness, 0-1
- C: Chroma = √(a² + b²), 0 to ~0.4
- H: Hue = atan2(b, a) in degrees, 0°-360°

**Key hue angles:**
```
  0° ≈ pink/magenta
 30° ≈ red-orange
 70° ≈ amber/yellow
 90° ≈ yellow-green
145° ≈ green
180° ≈ teal/cyan
200° ≈ cyan-blue
260° ≈ blue
300° ≈ purple
330° ≈ magenta-pink
```

**Polar ↔ rectangular conversion:**
```
OKLCH → OKLAB:  a = C * cos(H°),  b = C * sin(H°)
OKLAB → OKLCH:  C = √(a² + b²),   H = atan2(b, a)
```

**Maximum chroma at sRGB boundary:** Varies by hue and lightness. Typical safe values for data visualization: C ≤ 0.16 at mid-lightness. Higher chroma is possible at some hues but risks gamut clipping.

---

## Conversion Pipeline

The full path for using OKLCH in SwiftUI:

```
OKLCH → OKLAB → Linear RGB → sRGB → Color(red:green:blue:)
 (polar→rect)  (matrix+cube)  (gamma)
```

Each step is a simple formula with no iteration or lookup tables. The entire pipeline for one color is ~30 arithmetic operations — negligible for 64 squares per frame.

---

## Human Luminance Perception

The CIE luminance formula for sRGB:
```
Y = 0.2126 * R_linear + 0.7152 * G_linear + 0.0722 * B_linear
```

This means:
- Pure green (0,1,0) has luminance **0.7152** — appears very bright
- Pure red (1,0,0) has luminance **0.2126** — moderate
- Pure blue (0,0,1) has luminance **0.0722** — appears very dark
- Yellow (1,1,0) has luminance **0.9278** — nearly white

**Implications for the current Board Control scheme:**
- Green (white control) appears ~10x brighter than blue (black control) at the same RGB intensity
- The board has a systematic luminance bias toward white's territory
- This isn't a feature — it's an artifact of mapping data to RGB channels without luminance correction

**OKLAB's L channel** accounts for this: two colors with the same L value appear equally bright regardless of hue. This is why designing in OKLCH automatically solves the luminance imbalance problem.

---

## Colorblind Accessibility

### Prevalence
- **Deuteranomaly/deuteranopia** (green cone): ~6% of males
- **Protanomaly/protanopia** (red cone): ~2% of males
- **Tritanomaly/tritanopia** (blue cone): ~0.01%
- Total: ~8% of males, ~0.5% of females

### Problematic pairs
- Red vs. green (the classic — affects 8% of males)
- Red vs. brown/dark orange
- Green vs. yellow-green
- Blue vs. purple (purple's red component is invisible)

### Safe strategies
1. **Blue-orange diverging** — safe for ~99.5% of viewers
2. **Vary luminance, not just hue** — brightness differences survive all CVD types
3. **Avoid pure red-green as sole distinction** — the current attack/defend encoding fails this test
4. **Use magenta-teal or orange-blue** for binary distinctions

### Testing
- **Sim Daltonism** (free Mac app) — live overlay showing CVD simulation
- **Xcode Accessibility Inspector** — CVD filters for simulator screenshots
- At minimum, verify your scheme under deuteranopia (the most common type)
