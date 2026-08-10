import 'package:flutter/material.dart';
import 'cyber_circuit_painter.dart';

/// Full-screen, theme-aware, **code-generated** background.
///
/// Replaces the old static image wallpapers (`mabes-wp.png` /
/// `wp-putih-mabes.png`) with zero-asset rendering:
///
/// - **Dark mode ("J.A.R.V.I.S Cyberpunk"):** deep void purple/navy radial
///   gradient with a cyan/gold PCB circuit board painted by
///   [CyberCircuitPainter].
/// - **Light mode ("Tactical AR Day-Mode"):** holographic ice-blue
///   projection-screen gradient (icy white → frost blue → arctic cyan) with
///   a slate blueprint circuit watermark and cyan live nodes.
///
/// The circuit layer is painted in **both** modes: [AppBackground] always
/// wraps its child in a [CustomPaint] and hands the active [Brightness] to
/// the painter so it can select the right palette internally. Brightness is
/// read from `Theme.of(context)`, so the background reacts automatically to
/// the global [ThemeMode] toggle — no rebuild wiring needed at the call site.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  /// The page content rendered above the background layer.
  final Widget child;

  /// Deep void radial gradient: purple glow (top-left) → indigo → navy.
  static const RadialGradient _darkGradient = RadialGradient(
    center: Alignment.topLeft,
    radius: 1.6,
    colors: [
      Color(0xFF1B1240), // deep void purple
      Color(0xFF0F0B2E), // dark indigo
      Color(0xFF070A1F), // near-black navy
    ],
  );

  /// Tactical AR day-mode holographic canvas: icy white → frost blue →
  /// arctic cyan (backlit projection-screen illusion, darkest at the bottom).
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? _darkGradient : _lightGradient,
      ),
      child: CustomPaint(
        painter: CyberCircuitPainter(
          brightness: Theme.of(context).brightness,
        ),
        child: child,
      ),
    );
  }
}
