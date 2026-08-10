# Flutter HUD Loading Spinner — Build Artifact

> **Status:** CODE / EXECUTE MODE — complete, ready-to-apply code.  
> **Scope:** 2 new files (`lib/widget/hud_loading_spinner.dart`, `lib/utils/hud_loading.dart`) + 2 targeted modifications (`lib/widget/login_card.dart`, `lib/pages/dashboard.dart`).  
> **Verification note:** No Flutter/Dart SDK is installed in this workspace (`flutter`/`dart` not on PATH), so `flutter analyze` could not be run. All code below is hand-reviewed for zero syntax errors; run `flutter analyze` after applying.

---

## Section 1: Create `lib/widget/hud_loading_spinner.dart`

**Action:** Create this file with the COMPLETE content below.

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// High-tech sci-fi HUD loading spinner ("Arc Reactor" style).
///
/// Paints three animated layers driven by a single [AnimationController]:
///
/// 1. An outer dashed ring rotating clockwise.
/// 2. An inner solid cyan arc rotating counter-clockwise.
/// 3. A glowing cyan core (blurred [Colors.cyanAccent] dot).
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
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
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
/// glowing core, all in [Colors.cyanAccent].
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

    // --- Layer 3: glowing core ---
    final coreRadius = math.max(3.5, radius * 0.12);
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.cyanAccent.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final corePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.cyanAccent
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas
      ..drawCircle(center, coreRadius * 2.4, glowPaint)
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

## Section 2: Create `lib/utils/hud_loading.dart`

**Action:** Create this file with the COMPLETE content below.

```dart
import 'package:flutter/material.dart';

import '../widget/hud_loading_spinner.dart';

/// Global HUD loading overlay helper.
///
/// Shows a full-screen, non-dismissible overlay containing an
/// [HudLoadingSpinner] above a dark barrier. Pair every [HudLoading.show]
/// with a matching [HudLoading.hide] once the blocking operation completes.
class HudLoading {
  HudLoading._();

  /// Tracks whether an overlay is currently on screen so duplicate [show]
  /// calls are ignored and [hide] can never pop a non-overlay route.
  static bool _isShowing = false;

  /// Displays the HUD loading overlay above [context].
  ///
  /// [label] is rendered below the spinner. The overlay cannot be dismissed
  /// by tapping the barrier or by the system back button.
  static void show(BuildContext context, {String? label}) {
    if (_isShowing) return;
    _isShowing = true;

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
    ).whenComplete(() => _isShowing = false);
  }

  /// Dismisses the HUD loading overlay shown via [HudLoading.show].
  ///
  /// Safe to call when no overlay is visible — guarded by the [_isShowing]
  /// flag and a try/catch, so it can never accidentally remove an
  /// application route.
  static void hide(BuildContext context) {
    if (!_isShowing) return;
    _isShowing = false;
    try {
      Navigator.of(context, rootNavigator: true).pop();
    } catch (_) {
      // No overlay to dismiss — ignore.
    }
  }
}
```

---

## Section 3: Modify `lib/widget/login_card.dart`

### 3.1 Add the import

Add this line to the import block at the top of `lib/widget/login_card.dart`:

```dart
import '../utils/hud_loading.dart';
```

### 3.2 Delete the `isLoading` field

Delete this line (currently line 21 of `_LoginCardState`):

```dart
bool isLoading = false;
```

The `isLoading` boolean and its `setState` calls are fully removed — the HUD overlay now owns the loading state.

### 3.3 Replace the entire `login()` method

Replace the whole `Future<void> login() async { ... }` method with the version below. The validation snackbars are unchanged; the loading state, navigation, and all exit paths are refactored.

```dart
  Future<void> login() async {
    final usernameEmpty = usernameController.text.trim().isEmpty;
    final passwordEmpty = passwordController.text.trim().isEmpty;

    setState(() {
      usernameError = usernameEmpty;
      passwordError = passwordEmpty;
    });

    if (usernameEmpty && passwordEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Kredensial tidak valid. Silahkan periksa kembali.",
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (usernameEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text("Username wajib diisi"),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (passwordEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text("Password wajib diisi"),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    // Block the UI with the HUD overlay while the request is in flight.
    HudLoading.show(context, label: "MENGOTENTIKASI...");

    try {
      final response = await http.post(
        Uri.parse("$apiBaseUrl/api/v1/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": usernameController.text,
          "password": passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // --- JARING PENGAMAN NULL ---
        // Response menaruh user sebagai Map<String, dynamic> (JSON Object)
        final payload = data["data"] as Map<String, dynamic>? ?? {};
        final userData = payload["user"] as Map<String, dynamic>? ?? {};

        String token = payload["jwt_token"]?.toString() ?? "";
        String usernameLogin = userData["username"]?.toString() ?? "";
        String poldaLogin = userData["polda_id"]?.toString() ?? "";
        String roleID = userData["roles_id"]?.toString() ?? "";
        String uuid = userData["uuid"]?.toString() ?? "";
        String expired = userData["expired"]?.toString() ?? "";
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", token);
        await prefs.setString("username_login", usernameLogin);
        await prefs.setString("polda_login", poldaLogin);
        await prefs.setString("roleid_login", roleID);
        await prefs.setString("uuid_login", uuid);
        await prefs.setString("expired_login", expired);
        if (!context.mounted) return;
        // pushAndRemoveUntil removes BOTH the login page and the HUD dialog
        // route, so the dashboard becomes the only route on the stack and the
        // back button can never return to the login form.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
          (route) => false,
        );
      } else if (response.statusCode == 403) {
        if (!context.mounted) return;
        HudLoading.hide(context);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Akses Diblokir"),
            content: const Text(
              "Perangkat Anda belum terverifikasi. Sesi login diblokir. "
              "Silahkan hubungi Super Admin Mabes.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Tutup"),
              ),
            ],
          ),
        );
      } else {
        if (!context.mounted) return;
        HudLoading.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Kredensial tidak valid. Silahkan periksa kembali.",
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('Login error: $e\n$st');
      if (!context.mounted) return;
      HudLoading.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Kredensial tidak valid. Silahkan periksa kembali.",
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
    // NOTE: the old `finally { setState(() => isLoading = false); }` block is
    // gone — `isLoading` no longer exists; every exit path above explicitly
    // handles the HUD overlay (success removes it via route removal, all
    // error paths call HudLoading.hide).
  }
```

> **Why `pushAndRemoveUntil` instead of the original `pushReplacement` (deviation from the audit sketch, same intent as the audit's "pop before navigate" note):**
> The HUD dialog is a route on the root navigator, sitting **on top** of `LoginPage`. `Navigator.pushReplacement` replaces the *top-most* route — which would be the dialog itself, leaving `LoginPage` alive underneath `DashboardPage` (back button returns to login). `pushAndRemoveUntil(..., (route) => false)` atomically removes the dialog **and** the login page. This is the same pattern already used by `clearSessionAndLogout()` in `lib/utils/session_util.dart`, so the codebase stays consistent.

### 3.4 Replace the `ElevatedButton`

Replace the button block with `onPressed: login` (the `isLoading` ternary is removed; the overlay prevents any double-tap):

```dart
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: login,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffF6B300),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Masuk ke Sistem",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
```

---

## Section 4: Modify `lib/pages/dashboard.dart`

### 4.1 Add the import

Add this line to the import block at the top of `lib/pages/dashboard.dart` (alongside the other `../widget/...` imports):

```dart
import '../widget/hud_loading_spinner.dart';
```

### 4.2 Update `_buildCommandCenterContent()` — initial map load

Replace only the loading branch (current lines 162-166) of `_buildCommandCenterContent`:

```dart
  Widget _buildCommandCenterContent() {
    if (_isLoadingDashboard) {
      return const Center(
        child: HudLoadingSpinner(
          size: 80,
          label: "MEMUAT DATA NASIONAL...",
        ),
      );
    }
    // ... rest of the method unchanged ...
```

### 4.3 Update `_buildLoading()` inside `_HudDrilldownPanelState` — popup drilldown

Replace the whole `_buildLoading()` method (current lines 896-917) — the `Column`/`SizedBox`/`Text` boilerplate collapses into a single widget:

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

## Apply Order & Post-Apply Verification

1. Create `lib/widget/hud_loading_spinner.dart` (Section 1) — no dependencies.
2. Create `lib/utils/hud_loading.dart` (Section 2) — depends on 1.
3. Modify `lib/widget/login_card.dart` (Section 3).
4. Modify `lib/pages/dashboard.dart` (Section 4).
5. Run `flutter pub get`, then `flutter analyze` — expect zero new issues.
6. Manual smoke test: slow the network (or devtools throttling) and confirm the HUD overlay appears during login, the drilldown popup shows the arc reactor while fetching, and the Command Center initial load shows the 80px spinner with the "MEMUAT DATA NASIONAL..." label.
