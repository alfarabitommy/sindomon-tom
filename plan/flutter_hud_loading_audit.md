# Flutter HUD Loading Spinner — Audit & Architecture Plan

> **Status:** DEBUG / PLAN MODE — no execution code written yet.  
> **Goal:** Replace all `CircularProgressIndicator`s with a custom high-tech sci-fi HUD spinner (Arc Reactor / J.A.R.V.I.S aesthetic), usable both inline and as a global screen-blocking overlay.

---

## 1. Codebase Survey — Current Loading Indicator Landscape

### 1.1 All `CircularProgressIndicator` occurrences (20 total)

| File | Line(s) | Context | Color |
|---|---|---|---|
| `lib/pages/dashboard.dart` | 164 | `_buildCommandCenterContent()` — initial map load | `Colors.cyanAccent` |
| `lib/pages/dashboard.dart` | 903 | `_HudDrilldownPanelState._buildLoading()` — popup drilldown | `Colors.cyanAccent` |
| `lib/pages/personel.dart` | 196 | Entity table loading state | `Colors.amber` |
| `lib/pages/polda.dart` | 193 | Entity table loading state | (default) |
| `lib/pages/polres.dart` | 190 | Entity table loading state | (default) |
| `lib/pages/senjata.dart` | 180 | Entity table loading state, `strokeWidth: 2` | (default) |
| `lib/pages/sarpras.dart` | 235, 329 | Table loading + dropdown loading | `strokeWidth: 2` / (default) |
| `lib/pages/satwa.dart` | 221, 340 | Table loading + dropdown loading | `strokeWidth: 2` / (default) |
| `lib/pages/amunisi.dart` | 302 | Dropdown loading | (default) |
| `lib/pages/master_kategori_senjata.dart` | 541 | Table loading | (default) |
| `lib/widget/app_sidebar.dart` | 204 | Sidebar menu loading | `Colors.amber` |
| `lib/widget/form_input_personel.dart` | 596 | Dropdown loading | (default) |
| `lib/widget/form_input_polda.dart` | 233 | Dropdown loading | (default) |
| `lib/widget/form_input_polres.dart` | 271 | Dropdown loading | (default) |
| `lib/widget/form_input_sarpras.dart` | 503 | Dropdown loading | (default) |
| `lib/widget/form_input_senjata.dart` | 434 | Dropdown loading | (default) |
| `lib/widget/form_input_user.dart` | 526 | Dropdown loading | (default) |
| `lib/widget/form_inputan_satwa.dart` | 196, 599 | Table loading + dropdown loading | `strokeWidth: 2` / (default) |

### 1.2 Login-specific loading pattern (`login_card.dart`)

- **File:** `lib/widget/login_card.dart` (class `_LoginCardState`)
- **Current mechanism:** A boolean `isLoading` (line 21) toggles the `ElevatedButton`'s `onPressed` to `null` (line 304). The button visually greys out but there is **no visible spinner or progress feedback** to the user.
- **Flow:**
  1. `login()` sets `isLoading = true` (line 123-125)
  2. HTTP POST to `/api/v1/auth/login`
  3. On success → `Navigator.pushReplacement` to `DashboardPage`
  4. On any failure → SnackBar or AlertDialog
  5. `finally` block sets `isLoading = false` (line 227-231) — but this only matters if the navigation hasn't happened yet
- **Gap:** If the API is slow, the user sees a dead button with no indication that work is in progress.

### 1.3 Dashboard-specific loading patterns (`dashboard.dart`)

#### Pattern A — Full-page center spinner (line 162-165)
```dart
if (_isLoadingDashboard) {
  return const Center(
    child: CircularProgressIndicator(color: Colors.cyanAccent),
  );
}
```
This is the initial Command Center map payload load. It renders a lone spinner centered on screen.

#### Pattern B — Popup drilldown spinner (lines 896-917, class `_HudDrilldownPanelState`)
```dart
Widget _buildLoading() {
  return const SizedBox(
    height: 140,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.cyanAccent),
          SizedBox(height: 12),
          Text("MEMUAT DATA...", style: TextStyle(...)),
        ],
      ),
    ),
  );
}
```
This is the `FutureBuilder` loading state inside the per-Polda drilldown popup panel.

---

## 2. New File #1: `lib/widget/hud_loading_spinner.dart`

### 2.1 Architecture

```
HudLoadingSpinner (StatefulWidget)
  ├─ AnimationController (SingleTickerProviderStateMixin)
  │   ├─ outerRotation: 0 → 2π (clockwise, 2s period, repeat)
  │   └─ innerRotation: 0 → -2π (counter-clockwise, 1.4s period, repeat)
  └─ CustomPaint(painter: _ArcReactorPainter)
      ├─ Outer dashed ring (24 dashes, cyanAccent, rotating clockwise)
      ├─ Inner solid arc (270° sweep, cyanAccent, rotating counter-clockwise)
      ├─ Glowing core circle (cyanAccent with BoxShadow glow)
      └─ Optional "circuit trace" lines radiating from center
```

### 2.2 Widget API

```dart
class HudLoadingSpinner extends StatefulWidget {
  /// Diameter of the entire spinner, default 80.
  final double size;

  /// Stroke width for outer ring, default 2.5.
  final double outerStrokeWidth;

  /// Stroke width for inner arc, default 3.0.
  final double innerStrokeWidth;

  /// Optional label below the spinner (e.g. "MEMUAT DATA...").
  final String? label;

  /// Text size for the label, default 12.
  final double labelSize;

  /// Whether the widget should animate. Defaults to true.
  /// Set to false to freeze (e.g. when hidden behind route).
  final bool animate;

  const HudLoadingSpinner({
    super.key,
    this.size = 80.0,
    this.outerStrokeWidth = 2.5,
    this.innerStrokeWidth = 3.0,
    this.label,
    this.labelSize = 12.0,
    this.animate = true,
  });
}
```

### 2.3 Painter Design (`_ArcReactorPainter extends CustomPainter`)

The painter will paint in this z-order (back to front):

1. **Drop shadow layer:** A blurred circle behind the spinner to create a "glow" on dark backgrounds.
2. **Outer dashed ring:** A circle divided into ~24 arc segments (each ~10° arc, ~5° gap). The entire group rotates clockwise via a `canvas.rotate()` call driven by `outerRotation`.
3. **Inner solid arc:** A 270° arc (gap at bottom-right), `strokeCap: StrokeCap.round`, rotating counter-clockwise via `innerRotation`.
4. **Core dot:** A small filled circle (radius ~6) at the center, `Colors.cyanAccent`, with a `Paint.maskFilter` blur for the glow.
5. **Optional circuit traces:** Four thin lines extending from slightly off-center to the inner arc boundary, creating a reactor-core feel.

All colors: `Colors.cyanAccent` with varying opacity.

### 2.4 Reusability

The widget is designed so it can be:
- **Used inline:** `<HudLoadingSpinner(size: 60, label: "MEMUAT DATA...") />` — drops directly into any widget tree.
- **Used inside overlay:** The `HudLoading` utility (see §3) wraps it inside a `showDialog`.

---

## 3. New File #2: `lib/utils/hud_loading.dart`

### 3.1 Architecture

```dart
class HudLoading {
  HudLoading._(); // private constructor — static utility only

  /// Shows a full-screen, non-dismissible loading overlay.
  /// Returns a [BuildContext] that can be used to identify the dialog
  /// for dismissal.
  static void show(BuildContext context, {String? label});

  /// Dismisses the most recently shown HudLoading overlay.
  static void hide(BuildContext context);
}
```

### 3.2 Implementation Details

**`show()`:**
- Calls `showDialog(context: context, barrierDismissible: false, builder: ...)`.
- `barrierColor: Colors.black54` (semi-transparent dark backdrop).
- The builder returns a `Material(type: MaterialType.transparency, child: Center(child: HudLoadingSpinner(label: label ?? "MEMUAT...")))`.
- The root widget in the dialog is `PopScope(canPop: false, ...)` to prevent back-button dismissal.

**`hide()`:**
- Calls `Navigator.of(context).pop()` — this pops the dialog route.
- Wrapped in a try/catch to be safe against multiple calls or missing dialog.

### 3.3 Design Trade-off: Singleton vs Context-based

The simplest approach (and what is planned here) is context-based: you need a valid `BuildContext` to both show and hide. This works because:
- On login: `login()` is inside `_LoginCardState` which has `context`.
- On CRUD pages: form submit methods have `context`.

Alternative (not chosen): a global `GlobalKey<NavigatorState>` or `navigatorKey` on `MaterialApp`. Adds complexity with no clear benefit for this codebase.

---

## 4. Injection Point #1: `lib/widget/login_card.dart` — Login Loading

### 4.1 Current Code (lines 21, 123-125, 226-232, 304)

```dart
// Line 21
bool isLoading = false;

// Lines 123-125 (inside login())
setState(() {
  isLoading = true;
});

// Lines 226-232 (finally block)
} finally {
  if (mounted) {
    setState(() {
      isLoading = false;
    });
  }
}

// Line 304 (build method)
onPressed: isLoading ? null : login,
```

### 4.2 Planned Change

```diff
- Line 21:  bool isLoading = false;      // REMOVE
- Lines 123-125: setState(() { isLoading = true; });  // REPLACE
+ Line 123:  HudLoading.show(context, label: "MENGOTENTIKASI...");

- Lines 226-232: finally block         // REPLACE
+ After Navigator.pushReplacement (line 158-161): add HudLoading.hide(context);
+ In error handlers (lines 162-201): add HudLoading.hide(context); before showing dialog/snackbar
+ In catch block (lines 203-225): HudLoading.hide is already handled via finally replacement
```

**Detailed plan:**

| Location | Current | Replacement |
|---|---|---|
| `isLoading` field (line 21) | `bool isLoading = false;` | **Delete** the field entirely |
| `login()` — before HTTP call (lines 123-125) | `setState(() { isLoading = true; });` | `HudLoading.show(context, label: "MENGOTENTIKASI...");` |
| `login()` — after `Navigator.pushReplacement` (line 158-161) | (nothing) | `HudLoading.hide(context);` — but only if still mounted (the push navigates away, so this might not execute). Actually, `pushReplacement` is synchronous only in scheduling — the dialog should be popped before navigation. |
| `login()` — 403 error handler (line 162-179) | (nothing) | `HudLoading.hide(context);` right at line 163, before `showDialog` |
| `login()` — other error handler (line 180-201) | (nothing) | `HudLoading.hide(context);` right at line 180 |
| `login()` — catch block (line 203-225) | (nothing) | `HudLoading.hide(context);` right at line 204 |
| `login()` — finally block (lines 226-232) | `setState(() { isLoading = false; });` | **Replace** with: `HudLoading.hide(context);` (safe-guard in case earlier paths missed it; `hide()` is try/catch safe) |
| `build()` — button (line 304) | `onPressed: isLoading ? null : login,` | `onPressed: login,` (no condition needed anymore; the overlay prevents double-tap) |

**Important caveat for login flow:** After `Navigator.pushReplacement`, the login page context is unmounted. The `HudLoading` dialog is attached to the login page's navigator, so when `pushReplacement` replaces the entire route stack, the dialog is automatically dismissed. This means the explicit `hide()` call after `pushReplacement` may be unnecessary, but we keep `hide()` in the finally block as a defensive measure for error paths where the dialog remains up.

**Proposed insertion order in `login()`:**

```dart
Future<void> login() async {
  // ... validation (unchanged) ...

  HudLoading.show(context, label: "MENGOTENTIKASI...");

  try {
    final response = await http.post(/* ... */);

    if (response.statusCode == 200) {
      // ... parse & save prefs (unchanged) ...
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
      // Dialog auto-dismissed by route replacement
    } else if (response.statusCode == 403) {
      if (!context.mounted) return;
      HudLoading.hide(context);           // <-- NEW
      showDialog(/* ... */);
    } else {
      if (!context.mounted) return;
      HudLoading.hide(context);           // <-- NEW
      ScaffoldMessenger.of(context).showSnackBar(/* ... */);
    }
  } catch (e, st) {
    debugPrint('Login error: $e\n$st');
    if (!context.mounted) return;
    HudLoading.hide(context);             // <-- NEW
    ScaffoldMessenger.of(context).showSnackBar(/* ... */);
  }
  // Remove the finally block entirely since every path now handles hide() explicitly.
}
```

---

## 5. Injection Point #2: `lib/pages/dashboard.dart` — Inline Spinners

### 5.1 Location A: `_buildCommandCenterContent()` (line 162-165)

**Current:**
```dart
if (_isLoadingDashboard) {
  return const Center(
    child: CircularProgressIndicator(color: Colors.cyanAccent),
  );
}
```

**Planned:**
```dart
if (_isLoadingDashboard) {
  return const Center(
    child: HudLoadingSpinner(
      size: 80,
      label: "MEMUAT DATA NASIONAL...",
    ),
  );
}
```

This is a direct 1:1 widget swap. No behavioral changes; just a more impressive visual.

**Import needed at top of `dashboard.dart`:**
```dart
import '../widget/hud_loading_spinner.dart';
```

### 5.2 Location B: `_HudDrilldownPanelState._buildLoading()` (lines 896-917)

**Current:**
```dart
Widget _buildLoading() {
  return const SizedBox(
    height: 140,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.cyanAccent),
          SizedBox(height: 12),
          Text(
            "MEMUAT DATA...",
            style: TextStyle(
              color: Colors.cyanAccent,
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    ),
  );
}
```

**Planned:**
```dart
Widget _buildLoading() {
  return const SizedBox(
    height: 140,
    child: Center(
      child: HudLoadingSpinner(
        size: 60,
        label: "MEMUAT DATA...",
        labelSize: 12,
      ),
    ),
  );
}
```

The `HudLoadingSpinner` widget internally handles the label text, the column layout, and the spacing — so all the explicit `Column`/`SizedBox`/`Text` boilerplate disappears. The `const` keyword is preserved since `HudLoadingSpinner` will have a `const` constructor.

---

## 6. Dependency & Import Map

```
lib/utils/hud_loading.dart
  └─ import '../widget/hud_loading_spinner.dart'
  └─ import 'package:flutter/material.dart'

lib/widget/hud_loading_spinner.dart
  └─ import 'package:flutter/material.dart'
  └─ import 'dart:math' (for pi, sin, cos in painter)
  └─ import 'dart:ui' (for ImageFilter if needed for glow)

lib/widget/login_card.dart           ← adds import '../utils/hud_loading.dart'
lib/pages/dashboard.dart             ← adds import '../widget/hud_loading_spinner.dart'
```

`hud_loading_spinner.dart` has **zero** dependency on the application — it's a pure widget that can be extracted to any Flutter project.

`hud_loading.dart` depends only on `hud_loading_spinner.dart` and Flutter SDK.

---

## 7. Animation Lifecycle Notes

### 7.1 `HudLoadingSpinner`

- `AnimationController` initialized in `initState()`.
- `didUpdateWidget` checks `widget.animate`: if changing from `true` → `false`, calls `_controller.stop()`; if `false` → `true`, calls `_controller.repeat()`.
- `dispose()` properly disposes both `AnimationController` and any `Ticker`.
- `SingleTickerProviderStateMixin` used (not `TickerProviderStateMixin`) — one controller drives both ring animations via two `Listenable.merge`d tweens or two separate animations. Actually: simpler to use separate `CurvedAnimation` children from a single controller — the outer ring uses a `0..1` linear repeat, the inner arc uses the same controller value but mapped to reverse direction.

**Animation math:**
- One `AnimationController(duration: 2000ms)..repeat()`.
- Outer ring rotation: `_controller.drive(Tween(begin: 0, end: 2 * pi))` — clockwise.
- Inner arc rotation: `_controller.drive(Tween(begin: 0, end: -2 * pi))` — counter-clockwise via negative end value.

### 7.2 `HudLoading` overlay

- The `showDialog` builder creates a fresh `HudLoadingSpinner` in the overlay, so animations start fresh.
- When `hide()` pops the dialog, the spinner is disposed with the route — no leaks.

---

## 8. Future Scope (out of this plan)

The 16 remaining `CircularProgressIndicator` occurrences in entity pages (`personel.dart`, `polda.dart`, `polres.dart`, `senjata.dart`, `sarpras.dart`, `satwa.dart`, `amunisi.dart`, `master_kategori_senjata.dart`, form inputs, and `app_sidebar.dart`) can be replaced in a follow-up sweep once the `HudLoadingSpinner` widget is proven. Each is a straightforward inline swap similar to §5.

---

## 9. Verification Checklist (for implementation phase)

- [ ] `HudLoadingSpinner` renders without errors in isolation.
- [ ] `HudLoadingSpinner` animates continuously (outer CW, inner CCW).
- [ ] `HudLoadingSpinner` respects `animate: false` (freezes).
- [ ] `HudLoading.show()` creates a non-dismissible overlay.
- [ ] `HudLoading.hide()` dismisses the overlay gracefully.
- [ ] Double-calling `hide()` does not throw.
- [ ] Login flow: spinner appears during HTTP call, disappears on success (nav replaces route) or on error (explicit hide).
- [ ] Dashboard initial load: spinner replaced, looks consistent.
- [ ] Dashboard drilldown popup: spinner replaced, "MEMUAT DATA..." label preserved.
- [ ] `flutter analyze` passes with no new errors.
- [ ] No widget lifecycle leaks (AnimationController disposed properly).
