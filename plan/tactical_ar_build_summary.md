# Tactical AR Day-Mode — Build Summary

**Scope:** Light-mode aesthetic overhaul of the SINDOMON circuit background system.
**Files touched (3):** `lib/widget/background.dart`, `lib/widget/cyber_circuit_painter.dart`, `lib/widget/glass_surface.dart`
**Dark mode:** zero drift (verified — see §6).
**Analyzer:** `dart analyze` on all three files → **No issues found.**

---

## 1. What was built

The light mode went from "blank white paper" to a layered **Tactical AR day-mode** composition:

```
┌────────────────────────────────────────────────┐
│  AppBackground                                 │
│  └─ Container                                 │
│     └─ gradient: 3-stop holographic ice-blue  │  ← canvas
│        └─ CustomPaint (CyberCircuitPainter)    │  ← blueprint watermark
│           └─ child (page content)              │
│              └─ GlassSurface                   │  ← frosted glass panels
│                 └─ ClipRRect                   │
│                    └─ BackdropFilter (σ=12)    │  ← physical frost
│                       └─ Container             │
│                          └─ page widgets       │
└────────────────────────────────────────────────┘
```

Three layers, each with one job:

| Layer | File | Job |
|-------|------|-----|
| **Canvas** | `background.dart` | Backlit AR projection-screen gradient |
| **Watermark** | `cyber_circuit_painter.dart` | Slate blueprint circuit + cyan "live" IC nodes |
| **Surface** | `glass_surface.dart` | Physical frosted-glass panels over the circuit |

---

## 2. Layer 1 — Canvas (`background.dart`)

**`_lightGradient`** (replaces flat slate-50 → slate-200):

```dart
static const LinearGradient _lightGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFFF8FCFF), // icy white
    Color(0xFFE8F4FB), // frost blue-white
    Color(0xFFD2E8F5), // pale cyan-blue
  ],
  stops: [0.0, 0.5, 1.0],
);
```

Design intent: **backlit projection-screen illusion** — brightest at the top, darkest tint at the bottom, like light from a HUD projector. The deepest stop (`#D2E8F5`) is deliberately kept at the pale end of the luminance scale so slate-800 body text keeps AA-grade contrast through the frosted panels.

**Dark gradient unchanged:** radial `#1B1240 → #0F0B2E → #070A1F` (topLeft, radius 1.6).

---

## 3. Layer 2 — Watermark (`cyber_circuit_painter.dart`)

### 3.1 Current light palette (after Tactical AR re-tune)

| Element | Color | Opacity | Stroke |
|---------|-------|:-------:|:------:|
| nano traces (tier 0, <160px) | slate-400 `0xFF94A3B8` | 0.06 | 0.5 px |
| mid traces (tier 1) | slate-500 `0xFF64748B` | 0.08 | 1.0 px |
| bus lanes (parallel copies) | slate-500 `0xFF64748B` | 0.07 | 0.8 px |
| major arteries (tier 2, ≥350px) | slate-600 `0xFF475569` | 0.12 | 1.5 px |
| crosshairs | slate-400 `0xFF94A3B8` | 0.08 | 0.5 px |
| via rings | slate-400 `0xFF94A3B8` | 0.10 | 1.0 px |
| via fills | slate-600 `0xFF475569` | 0.14 | — |
| **chip fill** | **Jarvis cyan `0xFF00E5FF`** | **0.14** | — |
| **chip stroke** | **Jarvis cyan `0xFF00E5FF`** | **0.20** | 1.0 px |
| **micro-labels** | **Jarvis cyan `0xFF00E5FF`** | **0.18** | — |

`chipGlow: false` in light mode (blur glow is a dark-mode-only effect).

**Strategy: "activate, don't respray."** The blueprint infrastructure (traces, crosshairs, vias) stays slate and ghostly; only the IC chips, chip strokes, and micro-labels switch to Jarvis Cyan. This creates the "system is live" readout without making the background compete with content. All slate opacities were bumped 2–4 points (nano 0.04→0.06, mid 0.06→0.08, bus 0.05→0.07, major 0.09→0.12, via 0.10→0.14, ring 0.07→0.10, crosshair 0.06→0.08) to compensate for the blur pass that frosted glass now applies over them.

### 3.2 Dark palette (unchanged)

All traces Jarvis Cyan `0xFF00E5FF` @ 0.06–0.13; chips **brand gold `0xFFF6B300`** @ 0.10 fill / 0.16 stroke with `MaskFilter.blur(2.0)` glow; labels cyan @ 0.16; `chipGlow: true`.

### 3.3 The deterministic engine (60 FPS guarantee)

- **`_SeededRandom`** — hand-rolled xorshift32 PRNG, seed `0x504342` ("PCB"), state masked to 31 bits for platform-stable integer math. Same seed → same layout on every rebuild and every device.
- **Static geometry cache** `_cacheBySize` keyed on the full tuning tuple:
  `(Size, Brightness, seed, stepSize, density, jitter, chamferSize, busSpacing, maxBusLanes)`.
  Brightness is in the key because label colors differ per theme — a theme toggle regenerates once, then caches.
- **Bounded cache** (max 8 entries, cleared on overflow) so a long resize drag can't leak geometry entries.
- **`shouldRepaint`** returns true only on `brightness` change or size change.
- Result: `paint()` is pure draw — path replay + pre-laid-out text. **Zero layout work per frame.**

### 3.4 Generation pipeline (once per cache entry)

1. **Anchor grid** — cells of `stepSize: 90`, spanning one extra cell beyond every edge (traces flow off-canvas naturally). ~50% occupancy (`density: 0.50`), each anchor jittered by ±25 px (`jitter: 25`). ~7% of anchors upgrade to chip (IC) nodes.
2. **Connections** — raster-scan neighbor selection: ≤2 cells = "near", ≤6 = "far"; per-anchor lottery (2 near @ 0.55, guaranteed 1 @ 0.9 if none, 1 far @ 0.3, max 3 connections).
3. **Routing** — style lottery per trace: **L-shape 60% / Z-shape 30% / S-route 10%**, then **chamfered** (`chamferSize: 8`) so all corners are 45° cuts — the PCB signature look.
4. **Tiering** by straight-line distance: `<160px` → nano, `<350px` → mid, `≥350px` → major.
5. **Data bus** — 30% of major arteries spawn 2–3 parallel lanes (`busSpacing: 5`, `maxBusLanes: 3`): the raw route is translated by a constant perpendicular unit vector (axis = dominant route axis, sign scattered both sides), then chamfered at `8 × 0.65`. Lanes keep the exact same corners as the parent artery.
6. **Ornaments** — crosshairs (30% of empty intersections, 4-px arms, batched into one `Path`); micro-labels at 20% of chips + 8% of empty cells.
7. **Micro-labels** — `TextPainter` instances are **created and laid out inside `_generate`** (the cache phase), stored as `_LabelEntry(offset, painter)`. `paint()` only calls `painter.paint(canvas, offset)`. Font: `monospace`, 8 px, `TextScaler.noScaling`, 20-word pool (`SYS:ON`, `0x8FA`, `DATA_LINK`, `NET_OK`, `NODE_42`, `FREQ:114`, …), placed NE/SE/SW/NW of the anchor.
8. **Draw order** (bottom → top): nano → mid → bus → major → crosshairs → via rings → via fills → chips → labels.

### 3.5 Production constraints on the painter

- `stepSize: 90.0`, `density: 0.50`, `jitter: 25.0`, `chamferSize: 8.0`, `busSpacing: 5.0`, `maxBusLanes: 3`, seed `0x504342` — all tunable constructor params, cache key covers them.
- Tier thresholds (`_nanoMaxDistance: 160`, `_majorMinDistance: 350`) are physical pixels, independent of `stepSize`.
- Stroke caps/joins are round so chamfered corners stay clean at 0.5 px widths.

---

## 4. Layer 3 — Surface (`glass_surface.dart`)

`build()` restructured: the decorated `Container` is extracted to a local, then dispatched:

```dart
final container = Container( ... decoration: BoxDecoration(
  color: scheme.surface.withValues(alpha: isDark ? 0.75 : 0.80),
  borderRadius: radius,
  border: Border.all(
    color: isDark ? white @ 0.10 : white @ 0.35,   // glass-edge highlight
    width: 1.0,
  ),
  boxShadow: isDark ? null : [ black @ 0.06, blur 12, offset (0,4) ],
) ... );

if (isDark) return container;                       // ← dark mode: identical behavior

return ClipRRect(                                    // ← light mode: frosted glass
  borderRadius: radius,
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
    child: container,
  ),
);
```

Light-mode glass physics:

| Property | Value | Purpose |
|----------|-------|---------|
| Fill | `surface @ 0.80` alpha | 20% transparency → circuit + ice-blue canvas shimmer through |
| Blur | `ImageFilter.blur(σ=12)` | Turns the dense circuit into an elegant, non-distracting texture |
| Border | `white @ 0.35`, 1 px | Bright glass-edge highlight on the AR canvas |
| Shadow | `black @ 0.06`, blur 12, (0,4) | Soft depth lift, kept faint so it doesn't muddy the bright canvas |
| Clip | `ClipRRect` (radius) | Blur + border must not leak outside the rounded corners |

---

## 5. Performance budget

| Concern | Mitigation |
|---------|-----------|
| Path generation per frame | Never happens — geometry cached per `(Size, Brightness)`; `paint()` replays `Path`s |
| Text layout per frame | Never happens — `TextPainter.layout()` runs once in the cache phase |
| Resize storms | Bounded 8-entry cache, cleared on overflow |
| Theme toggle | One regeneration, then cached again |
| BackdropFilter cost | Single blur pass, gated to **light mode only**; the 18 dark-mode surfaces return the plain container (no filter) |
| MaskFilter cost | `chipGlow` blur only on ~7% of anchors, dark mode only |

---

## 6. Dark-mode integrity checklist

- [x] `_darkGradient` untouched (`background.dart`)
- [x] Dark `_CircuitPalette` block byte-identical (edit receipt confirmed only the light block changed)
- [x] `glass_surface.dart` dark path returns `container` directly — no `BackdropFilter`, no shadow, `surface @ 0.75`, `white10` border
- [x] Cache key already includes `Brightness` — light/dark caches never collide

---

## 7. Verification performed

- `dart analyze` on all three files → **No issues found** (exit 0)
- Edit receipts confirmed surgical diffs (light block only; gradient const only)
- Painter internals re-read post-edit: palette constants, cache tuple, tier thresholds, bus-lane math, label pre-layout, draw order — all consistent

## 8. Manual QA checklist (visual)

1. Toggle Light/Dark — dark must look identical to before.
2. Light: login page, one data table, one add form, profile — check glass frost + circuit shimmer.
3. Resize the window — circuit must reflow once (not flicker) and stay cached.
4. Zoom text/DPI change — labels should not distort (`TextScaler.noScaling`).
5. Confirm body text contrast on the frost: slate-800 on `surface @ 0.80` over `#D2E8F5` remains readable (worst case is bottom of screen + dark chips behind text).

---

## 9. Open notes

- **Blur is GPU-backed on desktop** (`ImageFilter.blur`), so 12σ on ~19 surfaces is acceptable — but if a low-end device ever stutters, the first lever is `sigma: 12 → 8`.
- The cyan label/chip palette at 0.14–0.20 alpha is tuned for the ice-blue canvas; if the gradient ever deepens, cyan opacity may need a 1–2 point drop.
- `glass_surface.dart` uses `withValues(alpha:)` (Flutter 3.27+ API) — do not downgrade the SDK below that without migrating to `withOpacity`.
