# Micro-HUD Promax — Architectural Audit & Upgrade Plan

> **Status:** DEBUG / PLAN MODE — no code written yet.
> **Target:** `lib/widget/cyber_circuit_painter.dart` (+ `lib/widget/background.dart` minor update).
> **Goal:** Transform the current sparse PCB backdrop into a dense, busy "Micro-HUD Promax" aesthetic while remaining an elegant, low-opacity watermark. Strict 60 FPS via deterministic `_CircuitCache`.

---

## 1. Current Baseline (Post-PCB Upgrade)

### 1.1 Geometry Stats (1920 × 1080 canvas)

| Metric | Value |
|--------|-------|
| `stepSize` | 140 px |
| `density` | 0.35 |
| `jitter` | 30 px |
| `chamferSize` | 12 px |
| Grid cells | ~187 (17 × 11) |
| Anchors | ~65 |
| Traces (total) | ~100 |
| Via draws (rings + fills) | ~200 |
| Chips | ~5 |

### 1.2 Paint Layers (current)

| Layer | Path | Stroke | Opacity (light/dark) |
|-------|------|--------|-----------------------|
| Regular traces | `traces` | 1.0 px | 0.07 / 0.10 |
| Major traces (every 5th) | `majorTraces` | 1.5 px | 0.10 / 0.15 |
| Via rings | `drawCircle` × N | 1.0 px | 0.10 / 0.14 |
| Via fills | `drawCircle` × N | — | 0.15 / 0.20 |
| Chip fills + strokes | `drawRRect` × N | 1.0 px | 0.12–0.18 / 0.15–0.22 + glow |

### 1.3 `_CircuitCache` Shape

```dart
class _CircuitCache {
  final Path traces;
  final Path majorTraces;
  final List<Offset> vias;
  final List<Offset> chips;
}
```

Cache key: `(Size, int seed, double stepSize, double density, double jitter, double chamferSize)` — **brightness-independent** (geometry identical; palette selected at draw time).

### 1.4 Painter Tunables (constructor)

```dart
CyberCircuitPainter({
  this.brightness = Brightness.dark,
  this.stepSize = 140.0,
  this.density = 0.35,
  this.jitter = 30.0,
  this.chamferSize = 12.0,
  this.seed = 0x504342,
});
```

### 1.5 Verdict

The pattern works but reads as "sparse" — the user sees too much empty canvas between traces. There is **no line-thickness hierarchy**, **no parallel bus lines**, **no micro-ornaments** (crosshairs, text labels). The upgrade must pack 3–4× the visual information density into the same canvas while keeping opacity low enough that the pattern reads as an elegant watermark.

---

## 2. Target Design: Micro-HUD Promax

### 2.1 Visual Concept

| Element | Role | Visual Weight |
|---------|------|---------------|
| **Nano traces** (0.5 px) | Background noise — dense, faint, fills the canvas | Minimal |
| **Mid traces** (1.0 px) | Standard PCB routing — visible but subordinate | Medium |
| **Data arteries** (1.5–2.0 px) | Major through-lines — the "hero" traces | High |
| **Bus lanes** (0.8 px) | 2–3 parallel offset copies of ~30% of arteries | Medium (bus effect) |
| **Crosshairs** `+` | Registration marks at empty grid intersections | Low |
| **Micro-text** | Terminal-style labels near chips/nodes | Accent |

The hierarchy creates a **natural focal flow**: eye is drawn to the bold arteries → follows bus lanes → discovers crosshair details → reads micro-labels. Dense but legible.

### 2.2 Density Targets

| Param | Old | New | Rationale |
|-------|-----|-----|-----------|
| `stepSize` | 140.0 | **90.0** | 1.56× more cells per axis → 2.4× more grid cells |
| `density` | 0.35 | **0.50** | 1.43× more anchors per cell |
| `jitter` | 30.0 | **25.0** | Slightly tighter (smaller grid = less jitter needed) |
| `chamferSize` | 12.0 | **8.0** | Thinner traces → tighter chamfers |
| `nearWindow` | 2 | **2** | Same Chebyshev window (covers 180 px in new grid) |
| `farWindow` | 5 | **6** | Slightly wider far-reach for longer arteries |

**Resulting geometry (1920 × 1080):**
- Grid cells: `(ceil(1920/90)+2) × (ceil(1080/90)+2)` = `24 × 14` = **336 cells**
- Anchors: 336 × 0.50 ≈ **168** (up from 65)
- Traces: ~168 × 1.6 avg ≈ **270** connections (up from 100)
- Tier split: ~110 nano + ~100 mid + ~60 major
- Bus lanes: ~60 × 0.30 × 2.5 avg = **45** parallel traces
- Crosshairs: ~30% of remaining empty cells ≈ **50** marks
- Labels: ~20% of chips + ~5% of empty cells ≈ **20–25** labels

---

## 3. Line Thickness Hierarchy & Tier Assignment

### 3.1 Tier Assignment Algorithm

Currently, "major" is every 5th-generated trace (arbitrary). Replace with a **distance-based heuristic** applied during the connection loop in `_generate()`:

```dart
// For each connection (i, j):
final physicalDistance = (anchors[i].position - anchors[j].position).distance;

if (physicalDistance < 160.0) {
  tier = _TraceTier.nano;       // short cells → background fuzz
} else if (physicalDistance < 350.0) {
  tier = _TraceTier.mid;        // medium range → standard PCB
} else {
  tier = _TraceTier.major;      // long spanning → data artery
}
```

Thresholds are in physical pixels (independent of `stepSize`). With `stepSize = 90`, this maps to:
- Nano: typically ≤ 1.8 cells (adjacent/short diagonal)
- Mid: 2–4 cells
- Major: 5+ cells (spanning the canvas)

### 3.2 Path Organization (New)

Replace the flat `traces` / `majorTraces` pair with four tiered `Path` objects:

| Path | Stroke | Typical trace count | Draw order |
|------|--------|---------------------|------------|
| `nanoTraces` | 0.5 px | ~110 | 1st (bottom) |
| `midTraces` | 1.0 px | ~100 | 2nd |
| `busTraces` | 0.8 px | ~45 | 3rd |
| `majorTraces` | 1.5–2.0 px | ~60 | 4th (top) |

Drawing order: nano → mid → bus lanes → major center-lines. The major arteries sit on top visually (as the "center rail"), with bus lanes slightly underneath. Both share the same color family.

### 3.3 Via / Chip Resizing

Higher density means vias must shrink to avoid smudging into each other:

| Element | Old size | New size | Reason |
|---------|---------|----------|--------|
| Via fill radius | 2.5 px | **2.0 px** | ~36 guides per cell, need them distinct |
| Via ring radius | 4.5 px | **3.5 px** | Smaller halo |
| Chip size | 8.0 px | **7.0 px** | Slightly more compact |

---

## 4. Data Bus: Parallel Line Generation

### 4.1 When

A connection assigned to `_TraceTier.major` has a **30% chance** (`rng.nextDouble() < 0.30`) of generating a parallel bus alongside it. This is evaluated inside `_generate()` after the route polyline is built but before `_chamferRoute` is applied.

### 4.2 Algorithm: Constant-Vector Offset

All route polylines are composed of axis-aligned segments (horizontal/vertical) plus 45° diagonal chamfers. Offsetting the **entire** polyline by a constant pixel vector preserves segment parallelism at all corners — the offset is uniform.

```dart
/// Returns a list of [laneCount] polylines, each offset from [route]
/// by successively larger perpendicular steps.
List<List<Offset>> _buildBusLanes(
  List<Offset> route,  // already chamfered, or pre-chamfer raw
  int laneCount,
  double spacing,
  bool horizontalPrimary,  // dx >= dy
  int sign,                // +1 or –1
) {
  final unit = horizontalPrimary ? const Offset(0, 1.0) : const Offset(1.0, 0.0);
  final lanes = <List<Offset>>[];
  for (var lane = 1; lane <= laneCount; lane++) {
    final offset = unit * (spacing * lane * sign);
    final shifted = route.map((p) => p + offset).toList();
    lanes.add(shifted);
  }
  return lanes;
}
```

**Perpendicular direction:**
- If `|dx| >= |dy|` (horizontal dominant): offset in **Y** (unit = `Offset(0, 1.0)`)
- Else (vertical dominant): offset in **X** (unit = `Offset(1.0, 0.0)`)

**Sign:** deterministic per connection — `rng.nextBool() ? 1 : -1`. This scatters bus lanes on both sides of their parent artery.

### 4.3 Chamfer Handling

The bus lanes are offset copies of the **pre-chamfered** route (raw corners), and then each lane is independently chamfered with a smaller `chEff = chamferSize * 0.65`. This creates a "stacked chamfer" effect: the center artery has full 8 px chamfers, lane 1 has ~5.2 px chamfers, lane 2 has ~5.2 px — the parallel cuts stack up cleanly.

**Edge case — short segments:** The `_chamferRoute` helper already clamps `chEff` to `min(ch, inLen/2, outLen/2)`. The smaller bus-lane chamfer plus identical segment lengths means the clamped value is the same as requested — no extra degeneracy risk.

### 4.4 Performance

For each bus-qualified major connection (~18 connections), the offset computation is a trivial list-map of `Offset + Offset` (5–10 points each, O(50) arithmetic ops). The chamfered result is then appended to the single `busTraces` Path via `moveTo`/`lineTo`. Zero extra draw calls — the bus lanes live in one batched `Path`.

### 4.5 Visual Distinction

Bus lanes use the same color as mid traces but at a slightly lower opacity (see palette table below) and 0.8 px stroke. The center artery at 1.5–2.0 px reads as the dominant rail, with 2–3 ghost-lanes running parallel. This is the defining "data bus" motif of a high-tech HUD.

---

## 5. Micro-UI Ornaments

### 5.1 Crosshairs (`+` Marks)

**Selection:** Every empty grid cell (where `rng.nextDouble() >= density`, i.e., no anchor spawned) has a **30% probability** of receiving a crosshair. This is evaluated during the grid-scan loop in `_generate()`.

**Geometry:** For a crosshair at `(x, y)`:
```
armLength = 3.0  // half-arm, so full arm = 6 px
horizontal: (x - armLength, y) → (x + armLength, y)
vertical:   (x, y - armLength) → (x, y + armLength)
```

**Batching:** All crosshairs are drawn into a single `Path crosshairs`:
```dart
final crosshairPath = Path();
for each crosshair position (x, y):
  crosshairPath.moveTo(x - armLength, y);
  crosshairPath.lineTo(x + armLength, y);
  crosshairPath.moveTo(x, y - armLength);
  crosshairPath.lineTo(x, y + armLength);
```

Single `canvas.drawPath(crosshairPath, …)` with `strokeWidth: 0.5`, `strokeCap: StrokeCap.round`. No per-element loop in `paint()`.

**Count estimate:** ~168 empty cells × 0.30 ≈ **50 crosshairs** → 100 subpaths in one Path → negligible GPU cost.

### 5.2 Micro-Text Labels

#### 5.2.1 Label Candidates

Labels are placed at:
1. **~20% of chip anchors** — the chip node is a visual anchor, label gives it a "callout" identity.
2. **~5% of empty grid cells** — scattered terminal readouts across the canvas.

Pick during the grid scan in `_generate()`: for each anchor where `isChip == true` and `rng.nextDouble() < 0.20`, assign a label. For empty cells where `rng.nextDouble() < 0.05`, also assign a label.

**Total:** ~(13 chips × 0.20) + (168 empty × 0.05) ≈ 3 + 8 ≈ **~11 labels**. Hmm, 11 might feel sparse. Increase empty-cell probability to **0.08** → 13 labels. Plus maybe add labels to a few major (non-chip) anchors: ~5 more. Target: **~20 labels**.

#### 5.2.2 Label Content Pool

Hardcoded deterministic pool of 20 strings (indexed by `rng.nextInt` modulo pool size):

```
'SYS:ON',  '0x8FA',   'DATA_LINK', 'NET_OK',   'NODE_42',
'FREQ:114', 'LINK_UP', '0x1B2',    'CTRL_A',   'V_SYNC',
'SIG:OK',  '0x00F',   'CH_04',     'RDY',      'CLK_SRC',
'NODE_7A', 'PING_OK', 'IRQ:01',    'DMA_1',    '0xFFE0'
```

#### 5.2.3 Label Positioning

Each label is offset from its anchor point by 6–10 px in a random cardinal/ordinal direction (NE/SE/SW/NW, picked per label via `rng`):

| Direction | Offset |
|-----------|--------|
| NE | `+6, -8` |
| SE | `+6, +10` |
| SW | `-6, +10` |
| NW | `-6, -8` |

The vertical bias (8–10 px vs 6 px) accounts for the text baseline; the text sits slightly below the offset point's y coordinate (TextPainter draws from baseline upward).

#### 5.2.4 TextPainter Caching Strategy (Critical for 60 FPS)

**Problem:** Creating `TextPainter` + calling `.layout()` on every `paint()` frame is expensive — `TextPainter.layout()` performs line-breaking, font shaping, and glyph cache lookup. For ~20 labels, this adds 0.5–2 ms per frame, killing 60 FPS.

**Solution:** Pre-create and pre-layout all `TextPainter` instances inside `_generate()` (the geometry cache phase). Store the pre-laid-out painters in `_CircuitCache`. The `paint()` method only calls `textPainter.paint(canvas, offset)` — zero layout work.

```dart
class _LabelEntry {
  const _LabelEntry({required this.offset, required this.painter});
  final Offset offset;
  final TextPainter painter;
}

// Inside _generate():
final textStyle = TextStyle(
  fontFamily: 'monospace',
  fontSize: 8.0,
  fontWeight: FontWeight.w500,
  letterSpacing: -0.5,
  color: brightness == Brightness.light
      ? const Color(0xFF475569).withValues(alpha: 0.12)  // slate-600
      : const Color(0xFF00E5FF).withValues(alpha: 0.16),  // cyan
);
for each label assigned:
  final tp = TextPainter(
    text: TextSpan(text: labelText, style: textStyle),
    textDirection: TextDirection.ltr,
  )..layout();
  labels.add(_LabelEntry(offset: anchorPos + directionOffset, painter: tp));
```

**Cache key change:** Since text style depends on `brightness`, the cache key must now include brightness so light/dark produce different text colors. Update cache key from:
```
(Size, int, double, double, double, double)
```
to:
```
(Size, Brightness, int, double, double, double, double)
```

The geometry `Path` objects will be **duplicated** for light/dark (same trace coordinates, different text layer). This wastes ~10–20 KB of Path memory — trivially acceptable.

**Cache cap:** remains 8 entries. With 2 brightness values × up to 4 window sizes = 8 entries before clear. Safe.

#### 5.2.5 `TextStyle` — `fontFamily: 'monospace'`

We intentionally do **not** use `GoogleFonts.jetBrainsMonoTextStyle()` because:
- `google_fonts` 6.x may trigger an HTTP fetch on first access (or use bundled font files).
- The TextPainter is created inside `_generate()`, which is called during `cacheFor()` → during `paint()` for the first frame. Introducing an async HTTP fetch mid-paint is a crash risk.
- `fontFamily: 'monospace'` is universally available on Windows, Linux, macOS — every platform ships a monospace system font. At 8 px semi-transparent, the exact glyph shape is irrelevant; the "terminal" vibe comes from the monospaced rhythm + small size + scattered placement.

---

## 6. Updated Palette Tables

### 6.1 Light Mode — "Corporate Blueprint Pro"

| Element | Color | `withValues(alpha:)` | Stroke / Size |
|---------|-------|----------------------|---------------|
| Nano traces (0.5 px) | `0xFF94A3B8` (slate-400) | `0.04` | `strokeCap: round`, `strokeJoin: round` |
| Mid traces (1.0 px) | `0xFF64748B` (slate-500) | `0.06` | `strokeCap: round`, `strokeJoin: round` |
| Bus lanes (0.8 px) | `0xFF64748B` (slate-500) | `0.05` | `strokeCap: round`, `strokeJoin: round` |
| Major arteries (1.5 px) | `0xFF475569` (slate-600) | `0.09` | `strokeCap: round`, `strokeJoin: round` |
| Crosshairs (0.5 px) | `0xFF94A3B8` (slate-400) | `0.06` | `strokeCap: round` |
| Via rings (1.0 px) | `0xFF94A3B8` (slate-400) | `0.07` | radius 3.5 px |
| Via fills | `0xFF475569` (slate-600) | `0.10` | radius 2.0 px |
| Chip fills | `0xFF64748B` (slate-500) | `0.08` | 7×7 px, radius 2 |
| Chip strokes (1.0 px) | `0xFF475569` (slate-600) | `0.14` | same rect |
| Micro-text (mono 8 pt) | `0xFF475569` (slate-600) | `0.12` | `FontWeight.w500`, `letterSpacing: -0.5` |

**Key:** The nano layer at 0.04 alpha is the critical "density without clutter" lever — dense background fuzz that barely registers individually but collectively fills the white space. Mid traces at 0.06 provide the readable PCB structure. Arteries at 0.09 provide the hierarchy anchors. Everything stays under 0.15 except chip strokes (which need slightly more to define the rect shape).

### 6.2 Dark Mode — "J.A.R.V.I.S Hypergrid"

| Element | Color | `withValues(alpha:)` | Stroke / Size |
|---------|-------|----------------------|---------------|
| Nano traces (0.5 px) | `0xFF00E5FF` (cyan) | `0.06` | `strokeCap: round`, `strokeJoin: round` |
| Mid traces (1.0 px) | `0xFF00E5FF` (cyan) | `0.08` | `strokeCap: round`, `strokeJoin: round` |
| Bus lanes (0.8 px) | `0xFF00E5FF` (cyan) | `0.07` | `strokeCap: round`, `strokeJoin: round` |
| Major arteries (1.5 px) | `0xFF00E5FF` (cyan) | `0.13` | `strokeCap: round`, `strokeJoin: round` |
| Crosshairs (0.5 px) | `0xFF00E5FF` (cyan) | `0.08` | `strokeCap: round` |
| Via rings (1.0 px) | `0xFF00E5FF` (cyan) | `0.10` | radius 3.5 px |
| Via fills | `0xFF00E5FF` (cyan) | `0.14` | radius 2.0 px |
| Chip fills | `0xFFF6B300` (gold) | `0.10` | 7×7 px, radius 2, **glow** `blur(2.0)` |
| Chip strokes (1.0 px) | `0xFFF6B300` (gold) | `0.16` | same rect |
| Micro-text (mono 8 pt) | `0xFF00E5FF` (cyan) | `0.16` | `FontWeight.w500`, `letterSpacing: -0.5` |

**Key:** Dark mode opacities are ~30% higher than light mode (dark backgrounds need more contrast for the same perceived visibility). The gold chips retain their `MaskFilter.blur(2.0)` glow — the only element with a shader effect. Micro-text at 0.16 cyan is readable but ghostly.

---

## 7. `_CircuitCache` — New Shape

```dart
class _CircuitCache {
  const _CircuitCache({
    required this.nanoTraces,       // Path — 0.5 px tier 0
    required this.midTraces,        // Path — 1.0 px tier 1
    required this.busTraces,        // Path — 0.8 px parallel offsets
    required this.majorTraces,      // Path — 1.5–2.0 px data arteries
    required this.crosshairs,       // Path — '+' marks
    required this.vias,             // List<Offset>
    required this.chips,            // List<Offset>
    required this.labels,           // List<_LabelEntry>
  });
  // ... fields ...
}

class _LabelEntry {
  const _LabelEntry({required this.offset, required this.painter});
  final Offset offset;
  final TextPainter painter;
}
```

### Cache Key Update

```dart
// OLD
static final Map<(Size, int, double, double, double, double), _CircuitCache> _cacheBySize;

// NEW — brightness included so text color is correct per-theme
static final Map<(Size, Brightness, int, double, double, double, double), _CircuitCache> _cacheBySize;
```

### `_CircuitPalette` — New Fields

The palette struct grows from 8 to 14 fields:

```dart
class _CircuitPalette {
  const _CircuitPalette({
    // existing (renamed for clarity)
    required this.midTraceColor,        // was traceColor
    required this.midTraceOpacity,      // was traceOpacity
    required this.majorTraceColor,
    required this.majorTraceOpacity,
    required this.viaColor,
    required this.viaOpacity,
    required this.ringColor,
    required this.ringOpacity,
    required this.chipColor,
    required this.chipOpacity,
    required this.chipStrokeColor,
    required this.chipStrokeOpacity,
    required this.chipGlow,
    // NEW
    required this.nanoTraceColor,
    required this.nanoTraceOpacity,
    required this.busTraceColor,
    required this.busTraceOpacity,
    required this.crosshairColor,
    required this.crosshairOpacity,
    required this.labelColor,
    required this.labelOpacity,
  });
}
```

---

## 8. `paint()` — Updated Draw Order

```dart
void paint(Canvas canvas, Size size) {
  _lastSize = size;
  final palette = _paletteFor(brightness);
  final circuit = _cacheFor(size);

  // 1. Nano traces (background fuzz, drawn first = bottom layer)
  canvas.drawPath(circuit.nanoTraces, _makeStrokePaint(palette.nanoTraceColor, palette.nanoTraceOpacity, 0.5));

  // 2. Mid traces
  canvas.drawPath(circuit.midTraces, _makeStrokePaint(palette.midTraceColor, palette.midTraceOpacity, 1.0));

  // 3. Bus lanes (under center artery)
  canvas.drawPath(circuit.busTraces, _makeStrokePaint(palette.busTraceColor, palette.busTraceOpacity, 0.8));

  // 4. Major arteries (on top = center rail)
  canvas.drawPath(circuit.majorTraces, _makeStrokePaint(palette.majorTraceColor, palette.majorTraceOpacity, 1.5));

  // 5. Crosshairs
  canvas.drawPath(circuit.crosshairs, _makeStrokePaint(palette.crosshairColor, palette.crosshairOpacity, 0.5));

  // 6. Via rings + fills
  // ... (unchanged, but radius constants updated)

  // 7. Chips
  // ... (unchanged, but size constant updated)

  // 8. Micro-text labels
  for (final label in circuit.labels) {
    label.painter.paint(canvas, label.offset);
  }
}
```

Helper to reduce boilerplate:
```dart
static Paint _makeStrokePaint(Color color, double opacity, double width) {
  return Paint()
    ..color = color.withValues(alpha: opacity)
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;
}
```

---

## 9. `_generate()` — Revised Logic Flow

```
_generate(Size size):
    rng = _SeededRandom(seed)
    anchors = []

    // Grid scan — denser, smaller step
    for each grid cell (gx: -1..maxCol, gy: -1..maxRow):
        if rng < density:
            anchor = new _Anchor(…, isChip = rng < 0.07)
            anchors.add(anchor)
        else:
            // EMPTY cell: maybe crosshair? maybe label?
            if rng < 0.30: crosshairs.add(Offset(gx*step, gy*step))
            if rng < 0.08: labelCandidates.add((pos, pool[rng]))

    // Connections (existing _pickConnections, same window/sampling logic)
    connections = _pickConnections(anchors, rng)
    // Note: farWindow updated from 5 to 6

    for each connection (i, j):
        dist = anchors[i] - anchors[j] distance
        assign tier: nano / mid / major based on distance thresholds

        route = _routeTrace(a, b, rng, cornerVias)
        if null continue
        smooth = _chamferRoute(route, chamferSize)

        // Emit to tiered path
        switch tier:
            nano → nanoPath.addPolyline(smooth)
            mid  → midPath.addPolyline(smooth)
            major:
                majorPath.addPolyline(smooth)
                // Data bus chance (30%)
                if rng < 0.30:
                    busLanes = _buildBusLanes(route, rng)  // pre-chamfer raw
                    for each lane:
                        chamferedLane = _chamferRoute(lane, chamferSize * 0.65)
                        busPath.addPolyline(chamferedLane)

    // Text labels
    textEntries = []
    for each chip anchor with rng < 0.20:
        assign label
    for each labelCandidate from empty cells:
        assign label
    for each assigned label:
        TextPainter → layout → _LabelEntry

    return _CircuitCache(
        nanoTraces, midTraces, busTraces, majorTraces,
        crosshairs, vias, chips, labels
    )
```

---

## 10. Tunables Summary (New Defaults)

```dart
CyberCircuitPainter({
  this.brightness = Brightness.dark,
  this.stepSize = 90.0,         // 140 → 90 (denser grid)
  this.density = 0.50,          // 0.35 → 0.50 (more anchors)
  this.jitter = 25.0,           // 30 → 25 (tighter to grid)
  this.chamferSize = 8.0,       // 12 → 8 (tighter corners)
  this.busSpacing = 5.0,        // NEW: lane-to-lane pitch
  this.maxBusLanes = 3,         // NEW: 2 or 3 lanes per bus
  this.seed = 0x504342,
});
```

| Param | Default | Description |
|-------|---------|-------------|
| `stepSize` | 90.0 | Grid spacing (logical px) |
| `density` | 0.50 | Anchor probability |
| `jitter` | 25.0 | Max random pixel offset |
| `chamferSize` | 8.0 | 45° chamfer length |
| `busSpacing` | 5.0 | Pixels between parallel bus lanes |
| `maxBusLanes` | 3 | Max parallel copies (actual = 2 + rng) |
| `seed` | 0x504342 | Determinism seed |

**Tier distance thresholds (hardcoded):**
| Threshold | Value | Role |
|-----------|-------|------|
| `kNanoMaxDistance` | 160.0 px | Below = nano |
| `kMajorMinDistance` | 350.0 px | Above = major (data artery) |
| (mid is everything in between) | | |

---

## 11. Performance Budget

| Layer | Primitives | GPU Calls | Estimate |
|-------|-----------|-----------|----------|
| `nanoTraces` Path (~110 traces) | 1 `drawPath` | 1 | ~50 μs |
| `midTraces` Path (~100 traces) | 1 `drawPath` | 1 | ~50 μs |
| `busTraces` Path (~45 traces) | 1 `drawPath` | 1 | ~30 μs |
| `majorTraces` Path (~60 traces) | 1 `drawPath` | 1 | ~30 μs |
| `crosshairs` Path (~50 × 2 arms) | 1 `drawPath` | 1 | ~20 μs |
| Via rings (~280 × stroked circle) | 280 `drawCircle` | 280 | ~200 μs |
| Via fills (~280 × filled circle) | 280 `drawCircle` | 280 | ~200 μs |
| Chips (~12 × fill + stroke) | 24 `drawRRect` | 24 | ~30 μs |
| Labels (~20 × text) | 20 `textPainter.paint` | 20 | ~100 μs |
| **Total** | ~628 | **609** | **~700 μs = 0.7 ms** |

0.7 ms out of a 16.67 ms frame budget (~4%). Well within 60 FPS. The bulk of cost is the 560 `drawCircle` calls — these are small-radius axis-aligned circles that GPU hardware handles natively.

---

## 12. `shouldRepaint` — No Changes

```dart
@override
bool shouldRepaint(CyberCircuitPainter oldDelegate) {
  return oldDelegate.brightness != brightness ||
      oldDelegate._lastSize != _lastSize;
}
```

Unchanged. Adding `busSpacing` and `maxBusLanes` to the comparison is unnecessary since those tunables are unlikely to change at runtime (they're part of the cache key, so a change would produce a cache miss anyway). But for strict correctness per the existing pattern, comparing only brightness + size is consistent with how the cache key includes all tunables.

---

## 13. Files Touched (Planned)

| File | Action | Lines Affected |
|------|--------|---------------|
| `lib/widget/cyber_circuit_painter.dart` | **HEAVY MODIFY** | ~200 lines changed/added (restructure `_generate`, `_CircuitCache`, `_CircuitPalette`, `paint`, add bus/crosshair/label logic) |
| `lib/widget/background.dart` | **NO CHANGE** | The `AppBackground` widget is already passing `brightness` and wrapping in `CustomPaint` unconditionally — zero modifications needed. |
| `test/background_test.dart` | **MODIFY** | Update assertions for new cache key (brightness-inclusive), verify crosshair/label paths exist, verify bus traces render |

---

## 14. Verification Checklist (for execution phase)

- [ ] `dart analyze` passes with zero errors on changed files.
- [ ] Existing 6 tests still pass (determinism, palette difference, cache regeneration, shouldRepaint, CustomPaint presence, no-exceptions).
- [ ] New or updated tests: crosshair `Path` is non-empty when density=0.5; labels list is non-empty; bus lane count > 0 for large canvas.
- [ ] Cycle: generate at 1920×1080 dark → verify paint completes in < 2 ms (subjective timing check).
- [ ] Visual: dense nano traces fill the canvas without overwhelming; major arteries with bus lanes stand out; crosshairs and micro-text add "found" detail.
- [ ] The pattern is deterministic: two `CyberCircuitPainter` instances with same tunables + same brightness + same size produce identical PNG bytes.
