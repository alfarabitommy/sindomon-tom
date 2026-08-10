# Flutter HUD Map Audit — Sci-Fi/J.A.R.V.I.S. Command Center Upgrade

**Target file:** `lib/pages/dashboard.dart` (709 lines, 1 file)
**Models referenced:** `lib/models/dashboard_model.dart` (PetaNode, DashboardDrilldown)
**Existing glass-morphism reference:** `lib/widget/login_card.dart:237-248` (ClipRRect + BackdropFilter pattern)

---

## 1. High-Tech Marker — "Pulsating Radar Blip"

### 1.1 Current State (lines 206–228)

```dart
// line 206
MarkerLayer(
  markers: petaNodes
      .where((n) => n.hasValidCoordinates)
      .map((n) {
        return Marker(
          point: n.latLng,
          width: 50,
          height: 50,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showDrilldownDialog(n),
            child: Tooltip(
              message: n.namaPolda,
              child: const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40,
              ),
            ),
          ),
        );
      }).toList(),
),
```

**Problems:**
- Static red `Icons.location_on` — no animation, no sci-fi feel
- 50×50 container is tight for a pulsing ring
- No glow, no crosshair, no radar aesthetic

### 1.2 Target Architecture

Replace the inline `Icon` child with a new **`_HudMarker`** `StatefulWidget` (private to `dashboard.dart`).

```
_HudMarker (StatefulWidget)
  └─ _HudMarkerState (SingleTickerProviderStateMixin)
       ├─ AnimationController (duration: 1500ms, repeat forever)
       ├─ _pulseScale:  Tween<double>(1.0 → 2.5)  + Curves.easeOut
       ├─ _pulseOpacity: Tween<double>(0.8 → 0.0)  + Curves.easeOut
       └─ build():
            GestureDetector(onTap) → Tooltip → SizedBox(80×80)
              └─ Stack(alignment: center)
                   ├─ [bottom]   Outer pulse ring  (AnimatedBuilder → Transform.scale + Opacity)
                   ├─ [middle]   Secondary pulse ring (offset phase: begin 0.7, same tween)
                   ├─ [top]      Inner solid dot (12×12 cyan, BoxShape.circle + BoxShadow glow)
                   └─ [optional] Crosshair lines (4 thin cyan lines at 45° offsets)
```

**Visual layers from back to front:**

| Z-order | Element | Description |
|---------|---------|-------------|
| 0 | Pulse ring 1 | Expanding cyan circle border, fades 0.8 → 0.0, scale 1.0 → 2.5 |
| 1 | Pulse ring 2 | Same as ring 1 but animation offset by 750ms (staggered) |
| 2 | Crosshair NW | 6px cyan line from center to top-left |
| 3 | Crosshair NE | 6px cyan line from center to top-right |
| 4 | Crosshair SW | 6px cyan line from center to bottom-left |
| 5 | Crosshair SE | 6px cyan line from center to bottom-right |
| 6 | Core dot | 10px solid `Colors.cyanAccent` with `BoxShadow` glow (blur 8, spread 2) |

### 1.3 New `_HudMarker` Class (insert after `_ExecMenuItem`, before end of file)

```dart
// ── Pulsating HUD Marker (Sci-Fi radar blip) ──────────────────────────────
class _HudMarker extends StatefulWidget {
  final PetaNode node;
  final VoidCallback onTap;
  const _HudMarker({required this.node, required this.onTap});

  @override
  State<_HudMarker> createState() => _HudMarkerState();
}

class _HudMarkerState extends State<_HudMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;
  late final Animation<double> _pulseScale2;
  late final Animation<double> _pulseOpacity2;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _pulseScale = Tween(begin: 1.0, end: 2.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    // Staggered secondary pulse
    _pulseScale2 = Tween(begin: 1.0, end: 2.5).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    _pulseOpacity2 = Tween(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Tooltip(
        message: widget.node.namaPolda,
        child: SizedBox(
          width: 80,
          height: 80,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Stack(
              alignment: Alignment.center,
              children: [
                // ── Outer pulse ring 1 ──
                Transform.scale(
                  scale: _pulseScale.value,
                  child: Opacity(
                    opacity: _pulseOpacity.value,
                    child: _pulseRing(),
                  ),
                ),
                // ── Staggered pulse ring 2 ──
                Transform.scale(
                  scale: _pulseScale2.value,
                  child: Opacity(
                    opacity: _pulseOpacity2.value,
                    child: _pulseRing(),
                  ),
                ),
                // ── Crosshair lines (static) ──
                ..._crosshairLines(),
                // ── Core dot ──
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.cyanAccent,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withValues(alpha: 0.9),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pulseRing() => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.cyanAccent, width: 1.5),
        ),
      );

  List<Widget> _crosshairLines() {
    const len = 8.0;
    const thick = 1.0;
    const clr = Color(0x88 cyanAccent-like); // Colors.cyanAccent.withValues(alpha: 0.4)
    return [
      // top
      Positioned(
        top: 30, left: 39,
        child: Container(width: thick, height: len, color: Colors.cyanAccent.withValues(alpha: 0.5)),
      ),
      // bottom
      Positioned(
        top: 42, left: 39,
        child: Container(width: thick, height: len, color: Colors.cyanAccent.withValues(alpha: 0.5)),
      ),
      // left
      Positioned(
        top: 39, left: 30,
        child: Container(width: len, height: thick, color: Colors.cyanAccent.withValues(alpha: 0.5)),
      ),
      // right
      Positioned(
        top: 39, left: 42,
        child: Container(width: len, height: thick, color: Colors.cyanAccent.withValues(alpha: 0.5)),
      ),
    ];
  }
}
```

### 1.4 MarkerLayer Modification

**Lines 206–228** become:

```dart
MarkerLayer(
  markers: petaNodes
      .where((n) => n.hasValidCoordinates)
      .map((n) => Marker(
            point: n.latLng,
            width: 80,   // ← was 50
            height: 80,  // ← was 50
            child: _HudMarker(
              node: n,
              onTap: () => _showDrilldownDialog(n),
            ),
          ))
      .toList(),
),
```

The `GestureDetector` and `Tooltip` are now handled inside `_HudMarker` — they are removed from the `MarkerLayer` block.

---

## 2. HUD-Style Drilldown Popup

### 2.1 Current State (lines 483–601)

- `_showDrilldownDialog` (lines 483–581): Standard `AlertDialog`
  - `backgroundColor: Color(0xff1E1B4B)` — dark indigo, no transparency
  - Rounded corners (Material default: 28px radius)
  - Standard `title` Text widget
  - `FutureBuilder<DashboardDrilldown>` inside `content`
  - `actions: [TextButton("Tutup")]` — amber text
- `_drilldownRow` (lines 583–601): Simple `Row` with `MainAxisAlignment.spaceBetween`

### 2.2 Target Architecture

Replace the entire `_showDrilldownDialog` + `_drilldownRow` with:

```
_showDrilldownDialog(node)
  └─ showDialog(…)
       └─ Dialog(backgroundColor: Colors.transparent)
            └─ _HudDrilldownPanel (StatefulWidget)
                 ├─ initState: starts _fetchDrilldown(node.poldaId)
                 ├─ build: ClipRRect(borderRadius: 4) → BackdropFilter(blur 12)
                 │    └─ Container(black 60%, cyan border, neon boxShadow)
                 │         └─ Column
                 │              ├─ _HudTitleBar (namaPolda + X close icon)
                 │              ├─ _HudDivider
                 │              ├─ FutureBuilder → _HudDataRows or _HudLoading
                 │              └─ (optional) _HudFooter with coordinates
                 └─ _HudDataRows: Column of _HudDrilldownRow widgets
```

**Design tokens (all hardcoded in the widget, no theme dependency):**

| Token | Value | Usage |
|-------|-------|-------|
| `_hudBg` | `Colors.black.withValues(alpha: 0.60)` | Panel background |
| `_hudBorder` | `Colors.cyanAccent.withValues(alpha: 0.55)` | Outer border |
| `_hudGlow` | `Colors.cyanAccent.withValues(alpha: 0.12)` | BoxShadow blur 14 |
| `_hudTextPrimary` | `Colors.cyanAccent` | Titles, data values |
| `_hudTextSecondary` | `Colors.white70` | Labels, coordinates |
| `_hudDivider` | `Colors.cyanAccent.withValues(alpha: 0.25)` | Row separators |
| `_hudRadius` | `4.0` | Border radius (sharp) |
| `_hudBlur` | `sigmaX: 12, sigmaY: 12` | BackdropFilter |

### 2.3 Detailed Layout

```
┌──────────────────────────────────────────────┐
│  POLDA METRO JAYA                        [X] │  ← _HudTitleBar
│──────────────────────────────────────────────│  ← _HudDivider (1px)
│                                              │
│  PERSONEL          153,500                   │  ← _HudDrilldownRow
│  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ │  ← subtle divider between rows
│  SENJATA             2,847                   │
│  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ │
│  SARPRAS               412                   │
│  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ │
│  SATWA K9               38                   │
│  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ │
│  VAKANSI                12                   │
│                                              │
│  📍 -6.2088, 106.8456                       │  ← _HudFooter
└──────────────────────────────────────────────┘
```

### 2.4 New Widget Classes

All private to `dashboard.dart`, inserted after `_ExecMenuItem`.

#### `_HudDrilldownPanel`

```dart
class _HudDrilldownPanel extends StatefulWidget {
  final PetaNode node;
  final Future<DashboardDrilldown> Function() fetchDrilldown;
  const _HudDrilldownPanel({required this.node, required this.fetchDrilldown});

  @override
  State<_HudDrilldownPanel> createState() => _HudDrilldownPanelState();
}

class _HudDrilldownPanelState extends State<_HudDrilldownPanel> {
  late final Future<DashboardDrilldown> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.fetchDrilldown();
  }

  @override
  Widget build(BuildContext context) {
    // ClipRRect → BackdropFilter → Container → Column
    //   ├─ _HudTitleBar
    //   ├─ _HudDivider(thickness: 1)
    //   ├─ FutureBuilder → _HudLoading / _HudError / _HudDataRows
    //   └─ _HudDivider(thickness: 1)
    //   └─ _HudFooter
  }
}
```

#### `_HudTitleBar`

```dart
class _HudTitleBar extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  // Row: [Icon(Icons.shield, cyan, 18)] + [SizedBox(8)] + [Text(title, cyan, bold, 16)]
  //       + Spacer + [IconButton(Icons.close, cyan, onTap: onClose)]
}
```

#### `_HudDrilldownRow`

```dart
class _HudDrilldownRow extends StatelessWidget {
  final String label;
  final String value;
  // Row(spaceBetween):
  //   label: white70, fontSize 14, letterSpacing 0.5
  //   value: cyanAccent, bold, fontSize 16, fontFeatures: [FontFeature.tabularFigures()]
  // Between each pair in the column: a 0.5px cyanDivider
}
```

#### `_HudDivider`

```dart
class _HudDivider extends StatelessWidget {
  // Container(height: 1, color: cyanAccent.withValues(alpha: 0.25))
}
```

### 2.5 Modified `_showDrilldownDialog` (line 483)

```dart
void _showDrilldownDialog(PetaNode node) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 120),
      child: _HudDrilldownPanel(
        node: node,
        fetchDrilldown: () => _fetchDrilldown(node.poldaId),
      ),
    ),
  );
}
```

Note: The `_fetchDrilldown` method on `_DashboardPageState` stays unchanged — we just wrap it in a closure.

### 2.6 Remove `_drilldownRow` (lines 583–601)

The old `_drilldownRow` method is deleted. Its replacement `_HudDrilldownRow` is a `StatelessWidget` with the HUD styling.

### 2.7 Loading & Error States

Both states use the same HUD panel shell (glass background + cyan border), with content swapped:

**Loading:** `SizedBox(height: 120)` + `CircularProgressIndicator(color: Colors.cyanAccent)` + `Text("MEMUAT DATA...", style: cyan, letterSpacing: 2)`

**Error:** `Icon(Icons.error_outline, cyanAccent, 40)` + `Text("GAGAL MEMUAT", cyan)` + `Text(error details, white38)`

---

## 3. Complete Modification Map

| # | Lines | Change | Risk |
|---|-------|--------|------|
| 1 | **206–228** | Replace `MarkerLayer` content: swap inline `Icon` → `_HudMarker` widget; increase width/height 50→80 | Low |
| 2 | **483–581** | Rewrite `_showDrilldownDialog`: `AlertDialog` → `Dialog(transparent)` wrapping `_HudDrilldownPanel` | Medium |
| 3 | **583–601** | Delete `_drilldownRow` method | Low |
| 4 | **689–709** (after) | Append 4 new private widget classes: `_HudMarker`, `_HudDrilldownPanel`, `_HudTitleBar`, `_HudDrilldownRow`, `_HudDivider` | Low |

**Total net line delta:** approximately +180 lines added, −50 lines removed = ~130 net new lines. File grows from ~709 to ~840 lines.

---

## 4. Imports & Dependencies

### 4.1 No new pub dependencies required

All styling uses core Flutter (`dart:ui` for `ImageFilter`, `widgets.dart` for `AnimatedBuilder`/`BackdropFilter` etc.). No `google_fonts` needed unless we want a specific monospace font — `FontFeature.tabularFigures()` on the default font achieves the tech-readout look without a dependency.

### 4.2 Existing imports check

`dashboard.dart` already imports:
- `dart:ui` — ✓ needed for `ImageFilter` (already used on line 315)
- `package:flutter/material.dart` — ✓

No new imports needed.

---

## 5. Performance & Animation Considerations

### 5.1 Marker count

The `petaNodes` list comes from `_nasionalData?.peta`. For Indonesia there are ~34 Polda. Even if all 34 have valid coordinates:
- Each `_HudMarker` spawns one `AnimationController` with a 1.5s repeating timer
- 34 concurrent animations is well within Flutter's budget (each marker's `AnimatedBuilder` only rebuilds its own 80×80 subtree)
- The `Marker` widget itself is a `Positioned` inside flutter_map's internal stack — only on-screen markers are actually laid out

**No performance risk.**

### 5.2 Dialog backdrop filter

`BackdropFilter` with `sigmaX: 12` on a single dialog is cheap. The blur is GPU-accelerated on all platforms (Impeller on modern Flutter). No risk.

### 5.3 Memory

`AnimationController` per marker: ~2KB each. 34 controllers = ~68KB, fully negligible. Controllers are disposed in `_HudMarkerState.dispose()`.

---

## 6. Verification Checklist (for implementation phase)

- [ ] Role "3" (Command Center) sees the new pulsating markers instead of red pins
- [ ] Tapping a marker opens the new HUD glass-panel dialog
- [ ] Dialog shows loading spinner while fetching drilldown
- [ ] Dialog shows error state on network failure
- [ ] Dialog data rows match the old `_drilldownRow` values (Personel, Senjata, Sarpras, Satwa K9, Vakansi)
- [ ] Close button (X icon) dismisses the dialog
- [ ] Clicking outside the dialog dismisses it (default `showDialog` barrierDismissible)
- [ ] Other roles ("1", "2") are unaffected — they still see the placeholder
- [ ] No regressions in `flutter analyze` output
- [ ] Map pan/zoom still works normally
- [ ] Animations stop when navigating away (dispose called)
