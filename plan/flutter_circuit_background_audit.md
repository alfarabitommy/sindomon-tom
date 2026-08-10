# Flutter PCB Circuit Background — Architectural Audit & Implementation Plan

> **Status:** DEBUG / PLAN MODE — no code written yet.
> **Goal:** Replace the current Dark-only square grid with a Cyber Circuit Board (PCB) background that renders elegantly in **both** Light and Dark modes.

---

## 1. Current State Analysis

### 1.1 `lib/widget/background.dart` — `AppBackground`

```dart
// line 52-57 (simplified)
child: isDark
    ? CustomPaint(
        painter: const CyberGridPainter(),
        child: child,
      )
    : child,
```

**The problem:** `CustomPaint` (and therefore any decorative overlay) is **only** present in Dark mode. Light mode gets a plain `LinearGradient` (`slate-50` → `slate-200`) with zero texture — hence the "blank white paper" complaint from the user.

The fix is straightforward: **always wrap `child` in `CustomPaint`**, and let the painter decide what to draw based on the active brightness. The painter must receive the `Brightness` (or a lightweight theme-mode flag) so it can select its palette internally.

### 1.2 `lib/widget/cyber_grid_painter.dart` — `CyberGridPainter`

A simple `CustomPainter` that draws a rectangular grid of horizontal and vertical lines (`Canvas.drawLine`). Every 4th line is "major" (higher opacity). Good performance — pure line draws, no shaders, no `saveLayer`. But visually: it's a flat HUD grid, not a circuit board.

**Verdict:** This file will be **renamed/replaced** by the new `CyberCircuitPainter`. No need to keep both; no other widget references `CyberGridPainter` directly (it is only used inside `AppBackground`).

### 1.3 Theming Infrastructure

| Component | File | Notes |
|-----------|------|-------|
| `ThemeController` | `lib/theme/theme_controller.dart` | `ValueNotifier<ThemeMode>`, persisted to `SharedPreferences` key `"theme_mode"`. |
| `AppThemeData` | `lib/theme/app_theme.dart` | Defines `light` / `dark` `ThemeData` factories. Both use `scaffoldBackgroundColor: Colors.transparent` so the `AppBackground` gradient shows through. |
| `MaterialApp` wiring | `lib/main.dart:41-50` | `ValueListenableBuilder<ThemeMode>` → `themeMode: themeMode`. |
| Brightness detection | Everywhere | `Theme.of(context).brightness == Brightness.dark` (used in ~10 widgets). |

**Design decision:** The `CyberCircuitPainter` will accept a `Brightness` parameter (not a `ThemeMode`) because:
- `Brightness` is the two-value enum (`light` / `dark`) — exactly what we need to pick between two palettes.
- It's already used pervasively in this codebase.
- `ThemeMode.system` resolves to a concrete `Brightness` at the `ThemeData` level, so we don't need to handle the "system" case separately.

### 1.4 Call Sites

`AppBackground` is instantiated in exactly **2** places:

| File | Context |
|------|---------|
| `lib/pages/login_page.dart:11` | Wraps the login form directly |
| `lib/widget/app_scaffold.dart:66` | Wraps every authenticated page (`AppScaffold.body`) |

Both pass a single `child` widget. No call site needs to change — the upgrade is fully internal to `AppBackground` + the painter.

---

## 2. Target Design: PCB Circuit Board Pattern

### 2.1 Visual Specification

A **Cyber Circuit Board** aesthetic: procedural lines with 45°/90° turns, terminating at small filled circles ("vias" / solder pads), with occasional larger nodes. The pattern should read as a premium watermark — high-tech but not distracting.

#### Light Mode Palette — "Clean Corporate Blueprint"

| Element | Color | Opacity | Notes |
|---------|-------|---------|-------|
| Circuit traces | `Color(0xFF64748B)` (slate-500) | 0.06–0.10 | Thin 1.0–1.5px lines, no glow |
| Vias (small dots) | `Color(0xFF475569)` (slate-600) | 0.12–0.18 | 2.5–3.0dp radius filled circles |
| Via rings | `Color(0xFF94A3B8)` (slate-400) | 0.08–0.14 | 1.0px stroke ring around vias |
| Large nodes | `Color(0xFF64748B)` (slate-500) | 0.10–0.15 | 6–8dp chips/ICs |

The overall effect should resemble a **faint architectural blueprint** — silver/slate on clean white-to-light-slate gradient.

#### Dark Mode Palette — "J.A.R.V.I.S Cyberpunk"

| Element | Color | Opacity | Notes |
|---------|-------|---------|-------|
| Circuit traces | `Color(0xFF00E5FF)` (Jarvis Cyan) | 0.08–0.12 | 1.0–1.5px lines |
| Vias (small dots) | `Color(0xFF00E5FF)` (Cyan) | 0.15–0.22 | 2.5–3.0dp filled, subtle blur glow |
| Via rings | `Color(0xFF00E5FF)` (Cyan) | 0.10–0.16 | 1.0px stroke ring |
| Large nodes | `Color(0xFFF6B300)` (Brand Gold) | 0.12–0.18 | 6–8dp accent chips |
| Glow effect | `Color(0xFF00E5FF)` | — | `MaskFilter.blur(BlurStyle.normal, 2.0)` on select elements |

### 2.2 Circuit Generation Algorithm (Deterministic, Seeded PRNG)

**Performance requirement:** The circuit pattern must paint in < 1ms on a 1920×1080 canvas to maintain 60 FPS. Procedural random generation on every `paint` call is unacceptable. The solution: **pre-compute a seeded deterministic set of paths once** and reuse them.

#### Algorithm Outline

```
SEED = fixed integer constant (e.g. 0x504342)  // "PCB" in hex

function generateCircuitPaths(canvasWidth, canvasHeight):
    rng = SeededRandom(SEED)

    // 1. Generate anchor points (via positions) on a coarse grid with jitter
    anchors = []
    for y in [0, STEP, 2*STEP, ..., canvasHeight]:
        for x in [0, STEP, 2*STEP, ..., canvasWidth]:
            if rng.nextDouble() < DENSITY:           // ~30-40% fill
                jx = x + rng.nextDoubleRange(-JITTER, JITTER)
                jy = y + rng.nextDoubleRange(-JITTER, JITTER)
                anchors.add(Point(jx, jy))

    // 2. Connect anchors with Manhattan+45° paths
    paths = []
    for each anchor A:
        // Pick 1-3 nearest neighbors (by index proximity, not distance scan)
        neighbors = pickNeighbors(A, anchors, rng, maxConnections=3)
        for each neighbor B:
            path = buildCircuitPath(A, B, rng)
            paths.add(path)

    return paths
```

#### Path Construction: `buildCircuitPath(A, B, rng)`

Each circuit trace between two anchor points uses a **staircase with 45° chamfers**:

```
Given: start point A(x1, y1), end point B(x2, y2)

1. Primary axis = the axis with greater delta (horizontal or vertical)
2. Choose route style (weighted random):
   - 60%: "L-shape" — one horizontal segment, one vertical segment, meeting at a corner
   - 30%: "Z-shape" — three segments, two corners
   - 10%: "Straight with chamfer" — direct path with 45° chamfer at one end

3. For L-shape:
   - Pick corner point C at either (x1, y2) or (x2, y1) based on coin flip
   - Optionally chamfer the corner: replace the 90° turn with two 45° segments
     with a short diagonal (length = CHAMFER_SIZE), creating a small via at the corner

4. For Z-shape:
   - Split the primary axis into two segments at a random ratio (0.3–0.7)
   - Two corners instead of one
   - Optional chamfer on each corner

5. Collect path as list of [MoveTo, LineTo, LineTo, ...] commands
```

#### Via / Node Placement

- **Vias:** Placed at every anchor point (small filled circle, radius 2.5–3.0 dp).
- **Corner vias:** Placed at every path turn/corner (same size).
- **Large nodes (ICs/chips):** A random subset (~5-8%) of anchors are upgraded to a larger node: filled rectangle or rounded rect (6–8 dp) with a thin stroke border, representing a "chip" on the board.

#### Clipping / Boundary Handling

- Paths that extend beyond the canvas are naturally clipped by the `Canvas` — no special handling needed beyond `canvas.clipRect`.
- Anchor grid should extend slightly beyond the visible bounds (+1 STEP margin) so circuits flow off the edges naturally, avoiding abrupt cutoffs.

### 2.3 Performance Strategy

| Concern | Mitigation |
|---------|------------|
| Recomputing paths on every frame | Paths are **computed once** in the painter constructor (or lazily on first paint) and cached in instance fields. `shouldRepaint` returns `false` unless size or brightness changes. |
| Large path list | A 1920×1080 canvas with STEP=120px and DENSITY=0.35 yields ~50–70 anchors and ~100–200 path segments. Drawing 200 lines + 70 dots per frame is negligible (sub-millisecond). |
| `shouldRepaint` granularity | Only repaint when `size` changes (window resize) or `brightness` changes (theme toggle). |
| Glow/blur in dark mode | Apply `MaskFilter.blur` **selectively** — only to large nodes (chips), not to every trace. The glow is a premium accent, not a universal effect. |
| No `saveLayer` | All drawing uses direct `canvas.drawLine`, `canvas.drawCircle`, `canvas.drawRRect` — no layer compositing overhead. |

### 2.4 Deterministic Seed Approach

The critical insight: we must **not** call `Random()` (unseeded) in `paint()`. Instead:

```dart
class _SeededRandom {
  _SeededRandom(this._state);
  int _state;

  // Simple xorshift* PRNG — fast, deterministic, good enough for placement
  double nextDouble() {
    _state ^= _state >> 12;
    _state ^= _state << 25;
    _state ^= _state >> 27;
    // Normalize to [0, 1)
    return (_state * 0x2545F4914F6CDD1D) / 2.0.pow(64);  // truncated mask
  }
}
```

The seed is a compile-time constant. Same seed + same canvas size = identical circuit pattern every time, no jitter, no frame-to-frame variation.

---

## 3. Implementation Plan

### Step 1: Rename & Rewrite the Painter

1. **Delete** `lib/widget/cyber_grid_painter.dart`.
2. **Create** `lib/widget/cyber_circuit_painter.dart` containing:
   - `CyberCircuitPainter extends CustomPainter`
   - Constructor takes `Brightness brightness` + optional tuning params (`density`, `stepSize`, `seed`).
   - Private `_SeededRandom` class.
   - `_generatePaths(Size size)` method — called lazily, cached in a `_CircuitCache?` field.
   - `paint(Canvas canvas, Size size)` — draws from cache, falls back to generation on first call or size change.
   - `shouldRepaint(CyberCircuitPainter old)` — compare `brightness` and `size`.

### Step 2: Update `AppBackground`

In `lib/widget/background.dart`:

```dart
@override
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final brightness = Theme.of(context).brightness;  // pass through

  return Container(
    decoration: BoxDecoration(
      gradient: isDark ? _darkGradient : _lightGradient,
    ),
    child: CustomPaint(                              // ← ALWAYS wrap
      painter: CyberCircuitPainter(
        brightness: brightness,
      ),
      child: child,
    ),
  );
}
```

Key changes:
- Remove the `isDark ? CustomPaint(...) : child` ternary.
- Always wrap in `CustomPaint`.
- Pass `Brightness` (not just `isDark`) to the painter so it can select its palette internally.
- The existing `_darkGradient` / `_lightGradient` stay unchanged — the circuit pattern is an overlay on top of the gradient.

### Step 3: Import Update

- `background.dart`: change `import 'cyber_grid_painter.dart'` → `import 'cyber_circuit_painter.dart'`.
- No other files import `cyber_grid_painter.dart` directly — verified via grep.

### Step 4: Visual Tuning Parameters

Expose these as constructor parameters with sensible defaults so we can tweak without code changes later if needed:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `brightness` | `Brightness` | required | Selects light/dark palette |
| `stepSize` | `double` | `140.0` | Anchor grid spacing (logical px) |
| `density` | `double` | `0.35` | Probability an anchor point is occupied (0.0–1.0) |
| `jitter` | `double` | `30.0` | Max random offset from grid point |
| `chamferSize` | `double` | `12.0` | Length of 45° chamfer at corners |
| `seed` | `int` | `0x504342` | PRNG seed for deterministic generation |

---

## 4. Palette Reference Table

### Light Mode (`Brightness.light`)

| Element | Base Color | `withValues(alpha:)` | Paint style |
|---------|-----------|----------------------|-------------|
| Circuit trace | `0xFF64748B` (slate-500) | `0.07` | `strokeWidth: 1.0`, `strokeCap: StrokeCap.round` |
| Major trace (every 5th) | `0xFF475569` (slate-600) | `0.10` | `strokeWidth: 1.5` |
| Via (fill) | `0xFF475569` (slate-600) | `0.15` | `style: PaintingStyle.fill` |
| Via ring | `0xFF94A3B8` (slate-400) | `0.10` | `style: PaintingStyle.stroke`, `strokeWidth: 1.0` |
| Chip (fill) | `0xFF64748B` (slate-500) | `0.12` | `RRect`, 7×7 dp |
| Chip stroke | `0xFF475569` (slate-600) | `0.18` | `style: PaintingStyle.stroke` |

### Dark Mode (`Brightness.dark`)

| Element | Base Color | `withValues(alpha:)` | Paint style |
|---------|-----------|----------------------|-------------|
| Circuit trace | `0xFF00E5FF` (Jarvis Cyan) | `0.10` | `strokeWidth: 1.0`, `strokeCap: StrokeCap.round` |
| Major trace | `0xFF00E5FF` (Cyan) | `0.15` | `strokeWidth: 1.5` |
| Via (fill) | `0xFF00E5FF` (Cyan) | `0.20` | `style: PaintingStyle.fill` |
| Via ring | `0xFF00E5FF` (Cyan) | `0.14` | `style: PaintingStyle.stroke`, `strokeWidth: 1.0` |
| Glow chip (fill) | `0xFFF6B300` (Gold) | `0.15` | `RRect`, 7×7 dp, `maskFilter: blur(2.0)` |
| Chip stroke | `0xFFF6B300` (Gold) | `0.22` | `style: PaintingStyle.stroke` |

---

## 5. Risk Assessment & Edge Cases

| Risk | Impact | Mitigation |
|------|--------|------------|
| Poor performance on low-end devices | Frame drops | Pre-computed paths, no shaders, simple draw primitives. Verified by limiting path count to ~200. |
| Pattern looks "too busy" | Cluttered UI | Low opacity (max 0.22 in dark, max 0.18 in light). Density tuned to 35%. |
| Pattern invisible on certain monitors | Wasted effort | Opacities calibrated for both high-contrast (OLED) and low-contrast (matte LCD) screens. |
| Window resize causes regeneration | Brief stutter | Paths only regenerate when `Size` actually changes (rare). `shouldRepaint` guards this. |
| Theme toggle at runtime | Visual glitch | `Brightness` change triggers `shouldRepaint` → redraws with correct palette. |
| Login page vs. authenticated pages | Inconsistent look | Both call sites use the same `AppBackground` widget — change applies universally. |
| Existing `_darkGradient` / `_lightGradient` | Circuit invisible over gradient | Both gradients are dark-ish at edges; circuit sits on top at low opacity. The existing gradients are fine as-is — the circuit adds texture, not replaces the gradient. |

---

## 6. Verification Checklist (for execution phase)

- [ ] `cyber_grid_painter.dart` deleted, `cyber_circuit_painter.dart` created.
- [ ] `background.dart` imports updated, `CustomPaint` wraps `child` unconditionally.
- [ ] `flutter analyze` passes with zero errors.
- [ ] Light mode: circuit pattern visible as faint slate blueprint over light gradient.
- [ ] Dark mode: circuit pattern visible as cyan/gold cyberpunk PCB over dark gradient.
- [ ] Toggle theme at runtime → pattern redraws in correct palette without visual glitch.
- [ ] Resize window → pattern regenerates for new size, no artifacts at edges.
- [ ] Login page and authenticated pages both show the circuit background.
- [ ] No frame drops when scrolling pages with DataTables (the pattern is static background).

---

## 7. Files Touched (planned)

| File | Action | Notes |
|------|--------|-------|
| `lib/widget/cyber_grid_painter.dart` | **DELETE** | Replaced by circuit painter |
| `lib/widget/cyber_circuit_painter.dart` | **CREATE** | New PCB circuit `CustomPainter` |
| `lib/widget/background.dart` | **MODIFY** | Always wrap in `CustomPaint`, pass `Brightness` |

**Total: 3 files. Zero call-site changes.** The upgrade is fully encapsulated within the background subsystem.
