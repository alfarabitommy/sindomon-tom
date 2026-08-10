import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Reusable theme-aware surface — the single source of truth for the
/// "Promax Glassmorphism" container standard.
///
/// - **Light mode ("Tactical AR Day-Mode"):** true frosted glass — a
///   [BackdropFilter] blur (σ=12) behind a semi-transparent surface at 80%
///   alpha, with a thin white glass-edge border and a soft drop shadow. The
///   holographic ice-blue canvas and cyan circuit shimmer through the frost.
/// - **Dark mode:** semi-transparent `ColorScheme.surface` at 75% alpha so the
///   cyber circuit background glows through, with a thin `white10` edge
///   border simulating glass reflection. Shadows are intentionally omitted —
///   they look muddy on transparent surfaces.
///
/// Replaces every hardcoded `Container(color: Colors.white, ...)` panel.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.width,
    this.height,
    this.constraints,
  });

  /// The content rendered above the glass layer.
  final Widget child;

  /// Corner radius (defaults to 12).
  final BorderRadiusGeometry? borderRadius;

  /// Inner padding applied to [child].
  final EdgeInsetsGeometry? padding;

  final double? width;
  final double? height;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final radius = borderRadius ?? BorderRadius.circular(12);

    final container = Container(
      width: width,
      height: height,
      constraints: constraints,
      padding: padding,
      decoration: BoxDecoration(
        // Dark: glass at 75% — the circuit background glows through.
        // Light: frosted glass at 80% — the ice-blue canvas tints the frost.
        color: scheme.surface.withValues(alpha: isDark ? 0.75 : 0.80),
        borderRadius: radius,
        // Dark: thin glass edge reflection. Light: bright glass-edge highlight.
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.35),
          width: 1.0,
        ),
        // Dark: no shadow (muddy on transparent glass). Light: soft shadow.
        boxShadow: isDark
            ? null
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

    // Dark mode returns the container directly — no blur pass on the 18
    // dark-mode surfaces. Light mode gains a single-pass frosted-glass blur.
    if (isDark) return container;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: container,
      ),
    );
  }
}
