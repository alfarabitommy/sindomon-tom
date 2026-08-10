# Tactical AR Day-Mode — Light Mode Promax Audit

> **Status:** DEBUG / PLAN MODE — architectural audit for the Light Mode overhaul.
> **Goal:** Upgrade Light Mode from "corporate blueprint" to "Tactical AR Day-Mode" (holographic ice-blue canvas, physical frosted glass, active micro-HUD accents). Dark Mode remains untouched.

---

## 1. `lib/widget/background.dart` — Holographic Ice-Blue Canvas

### 1.1 Current State (line 38–46)

```dart
static const LinearGradient _lightGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFFF8FAFC), // slate-50
    Color(0xFFE2E8F0), // slate-200
  ],
);
```

This reads as "warm gray paper" — correct for a corporate document, *not* a tactical AR projection.

### 1.2 Proposed Upgrade — "Ice-Blue Holographic Projection"

Replace with a three-stop linear gradient that reads as a brilliant, cold holographic canvas:

```dart
/// Holographic ice-blue AR projection: brilliant ice → soft arctic cyan.
static const LinearGradient _lightGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFFF8FCFF), // brilliant ice white
    Color(0xFFE8F4FB), // soft holographic blue (midpoint glow)
    Color(0xFFD2E8F5), // deeper arctic cyan
  ],
  stops: [0.0, 0.5, 1.0],
);
```

**Design rationale:**

| Stop | Hex | Role |
|------|-----|------|
| `0.0` — `#F8FCFF` | Ice-white with a whisper of cyan (RGB: 248, 252, 255). Feels like a clean AR projection surface under overhead light. |
| `0.5` — `#E8F4FB` | Soft holographic blue at the midpoint. Creates the "glow behind the frosted glass" when the Circuit Painter's cyan chips shimmer through. |
| `1.0` — `#D2E8F5` | Deeper arctic cyan at the bottom. Anchors the projection plane — prevents the screen from fading into indistinguishable white at the lower edge. |

**Impact on existing structure:** Zero. Only `_lightGradient` changes; `_darkGradient` is untouched. The `build` method (line 48–63) already selects the gradient via `isDark ? _darkGradient : _lightGradient` — no layout or widget-tree change required.

### 1.3 Verification Checklist

- [ ] `_lightGradient` replaced with three-stop ice-blue.
- [ ] `_darkGradient` (line 28–36) untouched.
- [ ] Build method unchanged — single-line gradient swap.

---

## 2. `lib/widget/glass_surface.dart` — True Frosted Glassmorphism

### 2.1 Current State (line 38–75)

In Light Mode the `GlassSurface` is a **solid-opaque** `scheme.surface` container with a soft drop shadow — indistinguishable from the old `Card(color: Colors.white)` pattern. The circuit background is completely hidden behind it.

### 2.2 Proposed Upgrade — Physical Frosted Glass

Inject a `ClipRRect` + `BackdropFilter(ImageFilter.blur)` path for Light Mode, making the surface a genuine frosted glass panel that partially reveals the blurred circuit board underneath.

#### 2.2.1 Widget Tree Transformation

```
BEFORE (Light): Container(solid white, shadow)

AFTER (Light):  ClipRRect(borderRadius)
                  └─ BackdropFilter(blur sigma 12)
                       └─ Container(semi-transparent 80%, border, shadow)
```

#### 2.2.2 Full Implementation Plan

```dart
import 'dart:ui' show ImageFilter;  // ← NEW import at top
// ... existing material.dart import ...

class GlassSurface extends StatelessWidget {
  // ... constructor unchanged ...

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final radius = borderRadius ?? BorderRadius.circular(12);

    // ── Shared container: the surface itself ──────────────────────
    //
    // In Light Mode the color is now semi-transparent (80 %) so the
    // blurred circuit shows through.  The white border provides the
    // glass edge-highlight common to real frosted-glass panels.

    final container = Container(
      width: width,
      height: height,
      constraints: constraints,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surface.withValues(alpha: 0.75)      // dark: 75% glass
            : scheme.surface.withValues(alpha: 0.80),     // light: 80% frost
        borderRadius: radius,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)       // dark: subtle edge
              : Colors.white.withValues(alpha: 0.35),      // light: visible rim
          width: 1.0,
        ),
        boxShadow: isDark
            ? null                                         // dark: no shadow
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );

    // Dark: transparent glass already shows the background — no
    // BackdropFilter needed (it would be wasted GPU work).
    if (isDark) return container;

    // Light: true frosted glass.  ClipRRect is required because
    // BackdropFilter bleeds beyond rounded corners without it.
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: container,
      ),
    );
  }
}
```

#### 2.2.3 Parameter Rationale

| Parameter | Before (Light) | After (Light) | Why |
|-----------|:---:|:---:|---|
| Surface opacity | `1.00` (solid) | `0.80` | 20% transparency lets the ice-blue gradient + cyan chips shimmer through. At 80% the surface still reads as a clean white card — the blur ensures the underlying pattern is a soft "watermark," not a distraction. |
| Border | `null` | `white @ 0.35` | Frosted glass panels have a distinct light rim. 35% white on an ice-blue background is visible but not harsh — it frames the panel elegantly. |
| Shadow | `alpha 0.05, blur 10` | `alpha 0.06, blur 12` | Slightly deeper and softer to reinforce the "floating glass" parallax illusion against the blurred background. |
| Blur sigma | `0` (no filter) | `12.0` | 12 px sigma produces a smooth Gaussian blur — enough to turn the dense circuit into a soft, elegant texture without smearing it into a uniform color. |

#### 2.2.4 Performance Note — `BackdropFilter` on Desktop

`BackdropFilter` uses the GPU scene-builder's `SaveLayer` + blur shader. On mobile, large blurs during scroll can trigger jank; on **desktop** (Linux/Windows/macOS — this app's target), modern GPUs handle sigma ≤ 16 at 60 FPS without measurable frame-time impact. The circuit painter is static (no animation), so the blur is computed once and cached by the compositor.  If the `child` scrolls (e.g., in a long DataTable), the blur is re-sampled, but the desktop GPU cost is negligible — the blurred region is still just a few screen-filling quads.

### 2.3 Verification Checklist

- [ ] `import 'dart:ui' show ImageFilter;` added.
- [ ] Container extracted to local variable.
- [ ] Light mode: `surface @ 0.80`, white border `@ 0.35`, shadow `(0.06, 12, 4)`.
- [ ] Dark mode: identical behavior to current (no regression).
- [ ] Light mode returns `ClipRRect → BackdropFilter → container`.
- [ ] Dark mode returns `container` directly.

---

## 3. `lib/widget/cyber_circuit_painter.dart` — Active Micro-HUD Accents

### 3.1 Current Light Palette (line 110–133)

Every element uses a monochrome slate scale (`#94A3B8` / `#64748B` / `#475569`) at very low opacity. The circuit reads as a uniform gray architectural blueprint — technically correct but visually "dead."

### 3.2 Proposed Upgrade — "Activated" Light Palette

Preserve the blueprint-gray **infrastructure** (nano/mid/bus traces, crosshairs, via fills and rings) while **activating** the chip nodes, their outlines, and the micro-label readouts with Jarvis Cyan (`#00E5FF`). The result is a holographic AR overlay: a gray circuit grid with glowing cyan data nodes.

```dart
if (brightness == Brightness.light) {
  // "Tactical AR Day-Mode" — ice-blue blueprint with active cyan nodes.
  return const _CircuitPalette(
    // ── Infrastructure: slate blueprint texture ──────────────────
    nanoTraceColor:  Color(0xFF94A3B8),   // slate-400
    nanoTraceOpacity: 0.06,                // +0.02 from current (needs to punch through frost)
    midTraceColor:    Color(0xFF64748B),   // slate-500
    midTraceOpacity:  0.08,                // +0.02
    busTraceColor:    Color(0xFF64748B),   // slate-500
    busTraceOpacity:  0.07,                // +0.02
    majorTraceColor:  Color(0xFF475569),   // slate-600
    majorTraceOpacity:0.12,                // +0.03

    crosshairColor:   Color(0xFF94A3B8),   // slate-400
    crosshairOpacity: 0.08,                // +0.02

    viaColor:         Color(0xFF475569),   // slate-600
    viaOpacity:       0.14,                // +0.04
    ringColor:        Color(0xFF94A3B8),   // slate-400
    ringOpacity:      0.10,                // +0.03

    // ── ★ Activated accents: Jarvis Cyan ─────────────────────────
    chipColor:        Color(0xFF00E5FF),   // jarvis cyan  ← WAS slate-500
    chipOpacity:      0.14,                // +0.06 — bright enough to glow through frost
    chipStrokeColor:  Color(0xFF00E5FF),   // jarvis cyan  ← WAS slate-600
    chipStrokeOpacity:0.20,                // +0.06
    labelColor:       Color(0xFF00E5FF),   // jarvis cyan  ← WAS slate-600
    labelOpacity:     0.18,                // +0.06 — legible through 80% frost + blur
    chipGlow:         false,               // no GPU blur on light background
  );
}
```

#### 3.2.1 Opacity Adjustment Rationale

Every infrastructure opacity is bumped 2–4 percentage points. This compensates for the `BackdropFilter(blur: 12)` in GlassSurface — traces that were barely visible at `0.04` alpha would vanish completely behind frosted glass. The new floor is `0.06` for nano traces, with vias and major traces reaching `0.12–0.14`.

**The cyan elements** (`0.14–0.20`) are set deliberately higher than their slate predecessors because:
1. Cyan on ice-white is a lower-contrast combination than slate on white — it needs more opacity to "pop."
2. Through 80% frost + 12 px blur, a `0.14` alpha cyan chip will appear as a soft, elegant glow, not an LED.

#### 3.2.2 What Changes vs. What Stays

| Element | Light Mode Change | Rationale |
|---------|:---:|---|
| Nano traces | Slate-400, opacity `0.04→0.06` | Faint background texture — still the "canvas fuzz." |
| Mid traces | Slate-500, `0.06→0.08` | Standard PCB routing — still architectural. |
| Bus traces | Slate-500, `0.05→0.07` | Data bus offset copies — subtle. |
| Major traces | Slate-600, `0.09→0.12` | Data arteries — slightly more visible, still blueprint. |
| Crosshairs | Slate-400, `0.06→0.08` | Registration marks. |
| Via fills | Slate-600, `0.10→0.14` | Solder pads — more present through frost. |
| Via rings | Slate-400, `0.07→0.10` | Ring outlines. |
| **Chip fills** | **Slate → Cyan**, `0.08→0.14` | ★ The "activation." IC nodes now glow cyan. |
| **Chip strokes** | **Slate → Cyan**, `0.14→0.20` | ★ Crisp cyan outline makes chips read as "live." |
| **Labels** | **Slate → Cyan**, `0.12→0.18` | ★ `SYS:ON`, `NET_OK` etc. become active HUD readouts. |
| `chipGlow` | stays `false` | MaskFilter blur on a light background produces a muddy shadow, not a glow. |

### 3.3 Cache & Performance — Zero Risk

The `_CircuitCache` key **already includes `Brightness`** (line 101–104):
```dart
static final Map<
    (Size, Brightness, int, double, double, double, double, double, int),
    _CircuitCache> _cacheBySize = {};
```

And `_cacheFor` at line 261:
```dart
final key = (size, brightness, seed, stepSize, density, jitter,
             chamferSize, busSpacing, maxBusLanes);
```

Palette changes are purely a data change inside `_paletteFor()` → no cache key format change, no codegen change, no recache logic change. Toggling Light ↔ Dark clears the cache naturally (different `Brightness` in the tuple), and the next paint generates fresh geometry with the new palette.

`shouldRepaint` (line 242–245) already checks `oldDelegate.brightness != brightness` → returns `true` on theme toggle, triggering a single repaint. No perpetual rebuild loop.

### 3.4 Dark Mode — Untouched

The dark palette (line 135–158) and the rest of the painter logic stays exactly as-is. The entire change is confined to the `Brightness.light` branch of `_paletteFor`.

### 3.5 Verification Checklist

- [ ] Dark mode palette (line 135–158) byte-for-byte identical to current.
- [ ] Light mode: nano/mid/bus/major/via/ring stay slate; chip/chipStroke/label become `0xFF00E5FF`.
- [ ] Light mode opacities bumped per the table above.
- [ ] `chipGlow` stays `false` in light mode.
- [ ] No cache key format changes needed.
- [ ] No algorithm changes in `_generate`, `_routeTrace`, or any paint method.

---

## 4. Execution Order & Risk Assessment

| Step | File | Action | Risk | Rollback |
|------|------|--------|:--:|----|
| 1 | `background.dart` | Replace `_lightGradient` | **None** — single const swap | Revert the 4-line gradient definition |
| 2 | `cyber_circuit_painter.dart` | Replace light palette in `_paletteFor` | **None** — pure data change in one function | Revert the `_CircuitPalette(...)` block |
| 3 | `glass_surface.dart` | Restructure `build` to add `BackdropFilter` for light mode | **Low-Medium** — widget tree changes; verify Dark Mode is unchanged | Revert to previous `build` method; no other files depend on GlassSurface internals |

**Recommended execution order:** Step 1 → Step 2 → Step 3. Steps 1 and 2 are independent of each other and can be done in either order. Step 3 depends on Step 1 (the ice-blue gradient is the canvas the frosted glass blurs) and benefits from Step 2 (the activated cyan chips create the "holographic" feel through the blur), but is functionally independent — it works with or without Steps 1 and 2.

**Post-execution verification:**
```bash
dart analyze                          # 0 errors expected
```
Manual visual check:
- Toggle to Light Mode → ice-blue canvas with frosted glass panels and soft cyan chip glows.
- Toggle to Dark Mode → identical J.A.R.V.I.S cyberpunk experience (zero regression).

---

## 5. Summary — Before / After Comparison

| Aspect | Before (Current Light Mode) | After (Tactical AR Day-Mode) |
|--------|----------------------------|-----------------------------|
| Background gradient | Slate-50 → Slate-200 (warm gray paper) | Ice-white → Arctic cyan (holographic projection) |
| GlassSurface appearance | Solid opaque white card | Frosted glass panel — 80% white with blur behind |
| GlassSurface border | None | White rim at 35% (glass edge highlight) |
| Circuit trace palette | All slate, uniform | Slate infrastructure + cyan chip/label accents |
| Visual hierarchy | Flat gray blueprint | Blueprint grid with glowing AR data nodes |
| Dark Mode impact | N/A | **None** — all changes confined to `Brightness.light` paths |
| Performance | O(1) paint | O(1) paint + 1 `SaveLayer` blur (desktop GPU ≈ free) |
| Cache invalidation | Size-only | Size + Brightness (already built-in) |

---

## 6. Files Touched

| File | Change Type | Lines Affected |
|------|:---:|---:|
| `lib/widget/background.dart` | **EDIT** — `_lightGradient` definition | ~4 |
| `lib/widget/cyber_circuit_painter.dart` | **EDIT** — light branch in `_paletteFor()` | ~12 |
| `lib/widget/glass_surface.dart` | **EDIT** — `build` restructured with `BackdropFilter` | ~30 |

**Zero files created. Zero files deleted. Dark Mode unchanged.**
