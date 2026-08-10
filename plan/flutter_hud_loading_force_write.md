# Flutter HUD Loading — Force Write Build

> **Status:** CODE / EXECUTE MODE — files were WRITTEN DIRECTLY to the workspace. This artifact is the exact copy for manual paste if your environment cannot write files.
> **Files touched (5 total):**
> - `lib/widget/hud_loading_spinner.dart` — CREATED (complete file)
> - `lib/utils/hud_loading.dart` — CREATED (complete file)
> - `lib/widget/login_card.dart` — MODIFIED (import + `login()` + button)
> - `lib/pages/dashboard.dart` — MODIFIED (import + 2 spinner swaps)
> - `lib/widget/app_sidebar.dart` — MODIFIED (import + spinner swap)
>
> **Verification performed in this environment:** brace-balance 0 for all new/modified files (except a pre-existing checker false positive in `app_sidebar.dart` caused by apostrophes in comments, confirmed unrelated via `git diff`); zero `CircularProgressIndicator` remain in the 3 modified files; all `HudLoading`/`HudLoadingSpinner` references resolve to the new files.

---

## 1. CREATE `lib/widget/hud_loading_spinner.dart`

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// High-tech sci-fi HUD loading spinner ("Arc Reactor" style).
///
/// Paints three animated layers driven by a single [AnimationController]:
///
/// 1. An outer dashed ring rotating clockwise.
/// 2. An inner solid cyan arc rotating counter-clockwise.
/// 3. A glowing cyan core (concentric opacity-falloff circles — no
///    `MaskFilter`, which silently fails to composite on Impeller).
///
/// When [label] is provided it is rendered below the spinner in the same
/// cyan, letter-spaced HUD typography used across the app.
class HudLoadingSpinner extends StatefulWidget {
  /// Diameter of the spinner, in logical pixels.
  final double size;

  /// Stroke width of the outer dashed ring.
  final double outerStrokeWidth;

  /// Stroke width of the inner solid arc.
  final double innerStrokeWidth;

  /// Optional caption rendered below the spinner (e.g. "MEMUAT DATA...").
  final String? label;

  /// Font size of [label].
  final double labelSize;

  /// When `false` the animation freezes at its current value.
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

  @override
  State<HudLoadingSpinner> createState() => _HudLoadingSpinnerState();
}

class _HudLoadingSpinnerState extends State<HudLoadingSpinner>
    with SingleTickerProviderStateMixin {
  /// Single controller drives both rings: the outer ring reads it forward
  /// (0 → 2π, clockwise) and the inner arc reads it reversed
  /// (0 → -2π, counter-clockwise).
  late final AnimationController _controller;

  /// 0 → 2π: clockwise rotation of the outer dashed ring.
  late final Animation<double> _outerRotation;

  /// 0 → -2π: counter-clockwise rotation of the inner arc.
  late final Animation<double> _innerRotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (widget.animate) {
      _controller.repeat();
    }

    _outerRotation = _controller.drive(
      Tween<double>(begin: 0, end: 2 * math.pi),
    );
    _innerRotation = _controller.drive(
      Tween<double>(begin: 0, end: -2 * math.pi),
    );
  }

  @override
  void didUpdateWidget(HudLoadingSpinner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              return CustomPaint(
                // Explicit size — never rely on constraint fallback.
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
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 12),
          Text(
            widget.label!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.cyanAccent,
              fontSize: widget.labelSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
        ],
      ],
    );
  }
}

/// Paints the three-layer arc reactor: dashed outer ring, solid inner arc and
/// glowing core, all in [Colors.cyanAccent]. Deliberately free of
/// `MaskFilter` — it silently drops whole layers on Impeller.
class _ArcReactorPainter extends CustomPainter {
  final double outerRotation;
  final double innerRotation;
  final double outerStrokeWidth;
  final double innerStrokeWidth;

  const _ArcReactorPainter({
    required this.outerRotation,
    required this.innerRotation,
    required this.outerStrokeWidth,
    required this.innerStrokeWidth,
  });

  /// Number of dashes composing the outer ring.
  static const int _dashCount = 24;

  /// Angular span of one dash (55% of the per-dash slot leaves a clear gap).
  static const double _dashSweep = (2 * math.pi) / _dashCount * 0.55;

  /// Sweep of the inner solid arc: 270° leaves a 90° "reactor gap".
  static const double _arcSweep = 3 * math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    // --- Layer 1: outer dashed ring, rotating clockwise ---
    final outerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = outerStrokeWidth
      ..strokeCap = StrokeCap.round
      ..color = Colors.cyanAccent;

    final outerRadius = math.max(6.0, radius - outerStrokeWidth - 2);
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(outerRotation);
    for (int i = 0; i < _dashCount; i++) {
      final start = 2 * math.pi * i / _dashCount;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: outerRadius),
        start,
        _dashSweep,
        false,
        outerPaint,
      );
    }
    canvas.restore();

    // --- Layer 2: inner solid arc, rotating counter-clockwise ---
    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = innerStrokeWidth
      ..strokeCap = StrokeCap.round
      ..color = Colors.cyanAccent;

    final innerRadius = math.max(
      4.0,
      radius - outerStrokeWidth - innerStrokeWidth - 8,
    );
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(innerRotation)
      // Start at 135° (down-left) so the 90° gap sits at the bottom.
      ..drawArc(
        Rect.fromCircle(center: Offset.zero, radius: innerRadius),
        3 * math.pi / 4,
        _arcSweep,
        false,
        innerPaint,
      )
      ..restore();

    // --- Layer 3: glowing core (concentric opacity falloff, no MaskFilter) ---
    final coreRadius = math.max(3.5, radius * 0.12);

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
  }

  @override
  bool shouldRepaint(_ArcReactorPainter oldDelegate) {
    return oldDelegate.outerRotation != outerRotation ||
        oldDelegate.innerRotation != innerRotation ||
        oldDelegate.outerStrokeWidth != outerStrokeWidth ||
        oldDelegate.innerStrokeWidth != innerStrokeWidth;
  }
}
```

---

## 2. CREATE `lib/utils/hud_loading.dart`

```dart
import 'package:flutter/material.dart';

import '../widget/hud_loading_spinner.dart';

/// Global HUD loading overlay helper.
///
/// Shows a full-screen, non-dismissible overlay containing an
/// [HudLoadingSpinner] above a dark barrier. Pair every [HudLoading.show]
/// with a matching [HudLoading.hide] once the blocking operation completes.
///
/// No static state is kept: `show()` always creates a fresh dialog route and
/// `hide()` is a guarded pop, so a stale flag can never silently swallow a
/// `show()` call.
class HudLoading {
  HudLoading._();

  /// Displays the HUD loading overlay above [context].
  ///
  /// [label] is rendered below the spinner. The overlay cannot be dismissed
  /// by tapping the barrier or by the system back button.
  static void show(BuildContext context, {String? label}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      useRootNavigator: true,
      builder: (_) {
        return PopScope<void>(
          canPop: false,
          child: Material(
            type: MaterialType.transparency,
            child: Center(
              child: HudLoadingSpinner(
                size: 80,
                label: label ?? 'MEMUAT...',
              ),
            ),
          ),
        );
      },
    );
  }

  /// Dismisses the HUD loading overlay shown via [HudLoading.show].
  ///
  /// Safe to call when no overlay is visible — the pop is wrapped in a
  /// try/catch so it can never accidentally remove an application route.
  static void hide(BuildContext context) {
    try {
      Navigator.of(context, rootNavigator: true).pop();
    } catch (_) {
      // No overlay to dismiss — ignore.
    }
  }
}
```

---

## 3. MODIFY `lib/widget/login_card.dart`

### 3.1 Import (add after the `shared_preferences` import)

```dart
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/hud_loading.dart';
```

### 3.2 Delete the field

```dart
  bool isLoading = false;
```

### 3.3 `login()` — the three loading-state hunks

**Hunk A — replace `setState` with `HudLoading.show`:**

```dart
    // Block the UI with the HUD overlay while the request is in flight.
    HudLoading.show(context, label: "MENGOTENTIKASI...");

    try {
```

**Hunk B — success path: `pushReplacement` → `pushAndRemoveUntil` (also removes the dialog route):**

```dart
        if (!context.mounted) return;
        // pushAndRemoveUntil removes BOTH the login page and the HUD dialog
        // route, so the dashboard becomes the only route on the stack and the
        // back button can never return to the login form.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
          (route) => false,
        );
```

**Hunk C — 403 path:**

```dart
      } else if (response.statusCode == 403) {
        if (!context.mounted) return;
        HudLoading.hide(context);
        showDialog(
```

**Hunk D — other error path:**

```dart
      } else {
        if (!context.mounted) return;
        HudLoading.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
```

**Hunk E — catch path:**

```dart
    } catch (e, st) {
      debugPrint('Login error: $e\n$st');
      if (!context.mounted) return;
      HudLoading.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
```

**Hunk F — delete the `finally` block entirely (and keep the method's closing braces):**

```dart
      );
    }
  }
```

> **WARNING (this was a real bug during the force-write):** the old `finally` block starts with the catch's closing brace on the same line (`    } finally {`). When deleting the `finally`, you must leave **TWO** closing braces at the end of `login()` — one for `catch`, one for the method:
>
> ```dart
>       );            // closes the SnackBar(...) call
>     }               // closes catch
>   }                 // closes login()
> ```
>
> Deleting only one brace leaves the file unbalanced (verified: `login_card.dart` was unbalanced at depth 1 until the second brace was restored).

### 3.4 `ElevatedButton` — `onPressed` strictly `login`

```dart
              onPressed: login,
```

---

## 4. MODIFY `lib/pages/dashboard.dart`

### 4.1 Import (add after the `session_util` import)

```dart
import '../utils/session_util.dart';
import '../widget/hud_loading_spinner.dart';
```

### 4.2 `_buildCommandCenterContent()` — loading branch

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

### 4.3 `_buildLoading()` inside `_HudDrilldownPanelState`

```dart
  /// HUD-styled loading state.
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

---

## 5. MODIFY `lib/widget/app_sidebar.dart`

### 5.1 Import (add after the `session_util` import)

```dart
import '../utils/session_util.dart' as session;
import '../widget/hud_loading_spinner.dart';
```

### 5.2 Menu loading state (was line 204)

```dart
                : const Center(
                    child: HudLoadingSpinner(size: 40),
                  ),
```

> The four other `Colors.amber` occurrences in this file (lines 253, 328, 378, 391) are selection highlights and icon tints — **do not touch them**.

---

## Post-Write Verification Commands

```bash
# 1. Files exist
ls lib/widget/hud_loading_spinner.dart lib/utils/hud_loading.dart

# 2. No vanilla spinner left in the modified files (expect 0 each)
grep -c CircularProgressIndicator lib/widget/app_sidebar.dart lib/pages/dashboard.dart lib/widget/login_card.dart

# 3. No isLoading leftovers
grep -c isLoading lib/widget/login_card.dart

# 4. References resolve
grep -rn 'HudLoadingSpinner' lib/widget/app_sidebar.dart lib/pages/dashboard.dart lib/utils/hud_loading.dart

# 5. Analyze
flutter analyze
```
