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
