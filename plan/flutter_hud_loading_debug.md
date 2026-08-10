# Flutter HUD Loading Spinner — Debug & Fix Plan

> **Status:** DEBUG MODE — diagnostic analysis; no code changes yet.  
> **Symptom:** The `HudLoadingSpinner` is completely invisible — both inline in Dashboard and inside the global `HudLoading` dialog overlay.

---

## Root Cause Hypothesis (Ranked by Likelihood)

After tracing the full rendering pipeline, **two independent bugs** combine to produce the reported "completely invisible" symptom:

| Rank | Root Cause | Affects | Mechanism |
|------|-----------|---------|-----------|
| **#1** | `MaskFilter.blur` on Impeller | **Both** dialog + inline | The `_ArcReactorPainter` uses `MaskFilter.blur(BlurStyle.normal, 12)` on `glowPaint` and `(..., 4)` on `corePaint`. On Flutter's Impeller rendering backend (default on iOS, opt-in on Android/Desktop), `MaskFilter.blur` with `BlurStyle.normal` causes the entire `CustomPaint` layer to silently fail compositing — the canvas records the draw commands but the layer tree drops them. No crash, no error log, just an empty render. |
| **#2** | `_isShowing` static flag stuck at `true` | **Dialog only** | If `_isShowing` remains `true` (after hot reload, exception between `_isShowing = true` and `showDialog`, or `whenComplete` delay after `pushAndRemoveUntil`), every subsequent `HudLoading.show()` silently returns at line 283 without calling `showDialog`. The overlay barrier never appears. |
| **#3** | `AnimatedBuilder` parameter mismatch | **Both** | In Flutter ≥ 3.10, the `AnimatedBuilder` constructor parameter was renamed from `animation` to `listenable` via `super.listenable`. The build artifact uses `animation: _controller` — a compile error on Flutter 3.10+. If the user corrected this locally, verify the corrected name. Also, `AnimatedBuilder` is deprecated since Flutter 3.24 in favor of `ListenableBuilder`. |

---

## Step 1: CustomPaint Sizing Analysis

### User hypothesis
> `CustomPaint` without explicit `size` property and with no child defaults to `Size.zero`, making the painter draw into a 0×0 canvas despite the wrapping `SizedBox(width: 80, height: 80)`.

### Analysis

`RenderCustomPaint` extends `RenderProxyBox`. Its `performLayout()` path when **no child** and **no explicit `size`** is supplied:

```dart
// RenderProxyBox.performLayout (inherited by RenderCustomPaint)
size = computeSizeForNoChild(constraints);
// computeSizeForNoChild defaults to:
//   return constraints.smallest;
```

The `SizedBox(width: 80, height: 80)` creates `BoxConstraints.tightFor(width: 80, height: 80)` which evaluates to `BoxConstraints(minW: 80, maxW: 80, minH: 80, maxH: 80)`. Calling `.smallest` on tight constraints returns `Size(80, 80)` — **not** `Size.zero`.

**Verdict:** CustomPaint sizing is **NOT** the root cause. The painter receives `Size(80, 80)`.

**Recommendation (defensive):** Add `size: Size(widget.size, widget.size)` to the `CustomPaint` constructor to make the sizing explicit and eliminate any platform-specific edge case in constraint resolution. Belt-and-suspenders.

### Targeted fix

```dart
// Inside the AnimatedBuilder/ListenableBuilder builder:
return CustomPaint(
  size: Size(widget.size, widget.size),  // <-- ADD THIS LINE
  painter: _ArcReactorPainter(
    outerRotation: _outerRotation.value,
    innerRotation: _innerRotation.value,
    outerStrokeWidth: widget.outerStrokeWidth,
    innerStrokeWidth: widget.innerStrokeWidth,
  ),
);
```

---

## Step 2: Static `_isShowing` Trap — Deep Analysis

### User hypothesis
> A hot reload, navigation abort, or unhandled exception could leave `_isShowing == true`, causing all future `show()` calls to silently return without creating the dialog.

### Analysis

```dart
static bool _isShowing = false;

static void show(BuildContext context, {String? label}) {
  if (_isShowing) return;        // <-- SILENT NO-OP if flag is stuck
  _isShowing = true;
  showDialog<void>(...).whenComplete(() => _isShowing = false);
}
```

**This IS a real bug for the dialog case.** The flag has multiple failure modes:

#### Failure mode A: Exception window (set-true → exception before showDialog)
```dart
_isShowing = true;          // set
// If ANY exception is thrown here (unlikely but possible in edge cases)...
showDialog<void>(...);      // never reached
```
If an OOM or framework exception occurs between the set and the call, `_isShowing` stays `true` permanently.

#### Failure mode B: `whenComplete` never fires after `pushAndRemoveUntil`
In `login_card.dart`, the success path uses `Navigator.pushAndRemoveUntil(...)`. This atomically removes the HUD dialog route. The dialog route's `dispose()` should complete the `showDialog` future, triggering `whenComplete`. However, `pushAndRemoveUntil` calls `Route.dispose()` on removed routes *synchronously within the same microtask* — but the `whenComplete` callback is scheduled via `.then()` on the dialog's Completer. In some Flutter versions, the Completer may not fire its `.then()` callbacks until the next microtask or frame. There is a narrow window (1 frame) where `_isShowing` is still `true` after the route has been removed. If a subsequent `show()` call lands in that frame, it's silently ignored.

#### Failure mode C: Hot reload preserves static state
Flutter hot reload preserves `static` variable values. If the HUD was showing during a hot reload (or the flag was stuck from a previous debugging session), `_isShowing` remains `true` across reloads. All future `show()` calls return immediately — no dialog appears, no barrier, no spinner.

#### Failure mode D: `hide()` in `catch`/error path with stale flag
If `HudLoading.hide(context)` sets `_isShowing = false` but the `Navigator.pop()` fails (e.g., wrong context after route change), the dialog route remains visible but the flag says it's not showing. Subsequent `show()` would try to show a second dialog overlay on top. Not a "silent no-op" but a different kind of broken — two overlays stack.

#### Why this doesn't explain the inline Dashboard failure
The inline spinner usage in `dashboard.dart` does NOT use `HudLoading.show()` at all — it directly embeds `<HudLoadingSpinner size: 80 .../>`. The static flag is irrelevant there. So **Bug #2 only explains the dialog case**, not the inline case.

### Targeted fix

**Option A (recommended): Replace static flag with a Completer-based guard that can be reset**

```dart
static Completer<void>? _completer;

static void show(BuildContext context, {String? label}) {
  // If a dialog is already showing, pop it first and re-show.
  hide(context);

  _completer = Completer<void>();

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    useRootNavigator: true,
    builder: (_) => PopScope(
      canPop: false,
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: HudLoadingSpinner(size: 80, label: label ?? 'MEMUAT...'),
        ),
      ),
    ),
  ).whenComplete(() {
    _completer?.complete();
    _completer = null;
  });
}

static void hide(BuildContext context) {
  if (_completer == null) return;
  final c = _completer;
  _completer = null;
  c!.complete(); // Prevent whenComplete from trying to pop
  try {
    Navigator.of(context, rootNavigator: true).pop();
  } catch (_) {}
}
```

**Option B (simpler): Remove the guard entirely — allow stacking, trust callers**

```dart
static void show(BuildContext context, {String? label}) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    useRootNavigator: true,
    builder: (_) => PopScope(
      canPop: false,
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: HudLoadingSpinner(size: 80, label: label ?? 'MEMUAT...'),
        ),
      ),
    ),
  );
}

static void hide(BuildContext context) {
  try {
    Navigator.of(context, rootNavigator: true).pop();
  } catch (_) {}
}
```

> **Decision:** Option A is more robust. Option B is simpler but allows double-dialogs if `show()` is called twice without `hide()` in between. Given that `login()` calls `show()` once and covers all exit paths with `hide()`, Option B is actually safe for this codebase. **Recommend Option B** for simplicity — the complexity of the static guard adds more bugs than it prevents.

---

## Step 3: MaskFilter Compatibility on Impeller

### User hypothesis
> `MaskFilter.blur` inside `_ArcReactorPainter` could cause silent rendering failures on specific platforms (Web/Wasm, Impeller).

### Analysis

```dart
final glowPaint = Paint()
  ..style = PaintingStyle.fill
  ..color = Colors.cyanAccent.withValues(alpha: 0.25)
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

final corePaint = Paint()
  ..style = PaintingStyle.fill
  ..color = Colors.cyanAccent
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
```

**This is highly likely the root cause for BOTH the dialog and inline failures.**

Flutter's Impeller rendering backend (default on iOS since 3.22, default on Android since 3.27, opt-in on desktop) has **well-documented issues** with `MaskFilter.blur`:

1. **`BlurStyle.normal`**: On Impeller, `BlurStyle.normal` with large blur sigma can cause the entire draw call's layer to be silently discarded. The canvas records the `drawCircle` commands, but when the layer tree is composited, Impeller's blur shader fails to allocate or samples out-of-bounds, and the SAFE_MATH/validation path drops the layer. No crash, no error in console (unless `flutter run --enable-impeller-validation` is used).

2. **Multiple MaskFilters in one layer**: Using two different `MaskFilter.blur` instances (sigma 12 and 4) within the same `CustomPaint` layer can confuse Impeller's save/restore tracking. Each `MaskFilter` requires a separate saveLayer, and Impeller's saveLayer coalescing can merge them incorrectly, dropping both.

3. **Web/Wasm (CanvasKit/Skia):** `MaskFilter.blur` works correctly on Skia/CanvasKit. So if the user is testing on Web, this is NOT the issue. But on native mobile (iOS/Android with Impeller), it IS the issue.

4. **The non-blurred arcs work?** The outer dashes and inner arc use `Paint()` without `maskFilter`. These should render correctly even on Impeller. But if the glow/core layer fails, it might take the ENTIRE `CustomPaint` with it — Impeller composites the whole `CustomPaint` layer as one operation; a failure in one draw command can abort the entire layer.

**Verdict:** MaskFilter is **the most likely root cause** for the "completely invisible" symptom on both dialog and inline. It also explains why the label text might render (it's a separate `Text` widget, not part of the `CustomPaint`) while the spinner graphics don't.

### Targeted fix

**Strategy: Remove `MaskFilter` from the painter entirely. Use a widget-level glow via `BackdropFilter` or concentric circles.**

```dart
// --- Layer 3: glowing core (NO MaskFilter) ---
final coreRadius = math.max(3.5, radius * 0.12);

// Replace MaskFilter glow with concentric circles at decreasing opacity.
final glow1 = Paint()
  ..style = PaintingStyle.fill
  ..color = Colors.cyanAccent.withValues(alpha: 0.08);
final glow2 = Paint()
  ..style = PaintingStyle.fill
  ..color = Colors.cyanAccent.withValues(alpha: 0.15);
final glow3 = Paint()
  ..style = PaintingStyle.fill
  ..color = Colors.cyanAccent.withValues(alpha: 0.30);
final corePaint = Paint()
  ..style = PaintingStyle.fill
  ..color = Colors.cyanAccent;

canvas
  ..drawCircle(center, coreRadius * 4.0, glow1)
  ..drawCircle(center, coreRadius * 2.5, glow2)
  ..drawCircle(center, coreRadius * 1.4, glow3)
  ..drawCircle(center, coreRadius, corePaint);
```

This produces a similar glow effect using only opacity falloff — zero `MaskFilter`, zero Impeller incompatibility. Four concentric circles with `PaintingStyle.fill` at decreasing radius and increasing opacity create a convincing glow on dark backgrounds.

---

## Additional Finding: `AnimatedBuilder` Parameter Name & Deprecation

### Analysis

The build artifact uses:
```dart
AnimatedBuilder(
  animation: _controller,   // <-- this parameter name
  builder: (context, _) { ... },
)
```

**Flutter version timeline:**

| Flutter Version | `AnimatedBuilder` param name | Status |
|---|---|---|
| < 3.10 | `animation` | Valid |
| 3.10 – 3.23 | `listenable` (via `super.listenable`) | `animation:` is a **compile error** |
| 3.24+ | `listenable` | `AnimatedBuilder` **deprecated**, use `ListenableBuilder` |

Since the codebase already uses `withValues(alpha: ...)` (Flutter ≥ 3.27), the user's Flutter version is **≥ 3.27**. On this version:

1. `AnimatedBuilder(animation: ...)` → **compile error** (unknown named parameter `animation`). The user must have corrected this to `listenable:` or the code wouldn't compile.
2. `AnimatedBuilder` → deprecated; `ListenableBuilder` is the recommended replacement.

**Recommendation:** Migrate to `ListenableBuilder`:

```dart
child: ListenableBuilder(
  listenable: _controller,
  builder: (context, _) {
    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: _ArcReactorPainter(
        outerRotation: _outerRotation.value,
        innerRotation: _innerRotation.value,
        outerStrokeWidth: widget.outerStrokeWidth,
        innerStrokeWidth: widget.innerStrokeWidth,
      ),
    );
  },
),
```

`ListenableBuilder` has identical semantics to `AnimatedBuilder` — it rebuilds the subtree whenever the `listenable` notifies. No behavioral difference, just a non-deprecated API.

---

## Summary: Exact Lines to Fix

### File: `lib/widget/hud_loading_spinner.dart`

| Line(s) | Issue | Fix |
|---|---|---|
| 119 | `AnimatedBuilder` deprecated / wrong param | Replace with `ListenableBuilder(listenable: _controller, ...)` |
| 122-129 | `CustomPaint` missing explicit `size` | Add `size: Size(widget.size, widget.size)` |
| 231-238 | `MaskFilter.blur` on `glowPaint` and `corePaint` | Replace with concentric-circle opacity falloff (remove both `maskFilter` lines) |

### File: `lib/utils/hud_loading.dart`

| Line(s) | Issue | Fix |
|---|---|---|
| 276 | `static bool _isShowing` — volatile flag can get stuck | Delete the flag entirely |
| 283-284 | `if (_isShowing) return; _isShowing = true;` | Remove both lines |
| 305 | `.whenComplete(() => _isShowing = false)` | Remove the `.whenComplete` call |
| 314-315 | `if (!_isShowing) return; _isShowing = false;` | Replace with plain try/catch pop |

### File: `lib/widget/login_card.dart`

No additional changes needed — the `HudLoading.show/hide` calls already handle all exit paths. However, verify that `HudLoading.hide(context)` is called BEFORE showing the 403 `AlertDialog` (line where `HudLoading.hide(context)` is called) — this is correct in the build artifact.

### File: `lib/pages/dashboard.dart`

No changes needed — the inline `HudLoadingSpinner` usage is correct; the fix to `hud_loading_spinner.dart` propagates automatically.

---

## Verification After Fix

1. **Cold start test:** Fresh app launch → login → verify HUD overlay appears during authentication (barrier dims + spinner + "MENGOTENTIKASI..." label).
2. **Impeller test:** Run with `flutter run --enable-impeller` (or on iOS/Android where it's default) → verify spinner arcs and core are visible.
3. **Inline test:** Navigate to Dashboard as Command Center (role 3) → verify spinner shows briefly while map data loads.
4. **Drilldown test:** Tap a Polda marker → verify spinner shows inside the popup while drilldown data fetches.
5. **Double-show test:** Rapidly tap login twice → verify no crash (only one dialog should appear, or at worst two stack — both visible).
6. **Error path test:** Enter wrong credentials → verify spinner hides before error snackbar appears.
7. **Hot reload test:** Hot reload during spinner display → verify subsequent `show()` calls still work.
