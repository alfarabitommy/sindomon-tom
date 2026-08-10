import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Dense "Micro-HUD Promax" circuit board backdrop, painted behind content.
///
/// Evolved from the sparse PCB design: the canvas is packed with a
/// hierarchical circuit layout while staying a faint, elegant watermark:
///
/// - **Nano traces** (0.5 px): ultra-thin background fuzz between nearby
///   anchors — density without clutter.
/// - **Mid traces** (1.0 px): standard PCB routing.
/// - **Data arteries** (1.5 px): long through-lines; ~30% of them carry a
///   parallel **data bus** — 2–3 offset lane copies following the same turns.
/// - **Crosshairs** (`+`): registration marks on empty grid intersections.
/// - **Micro-labels**: pre-laid-out monospace `TextPainter`s (`SYS:ON`,
///   `0x8FA`, …) hovering near chips and scattered empty cells.
///
/// Light mode renders slate/silver at 0.04–0.14 alpha (corporate blueprint);
/// dark mode renders Jarvis cyan + gold chips at 0.06–0.16 alpha with a blur
/// glow on the gold chips only.
///
/// ## Determinism & performance
///
/// All geometry — including the text labels — is generated once per
/// `(Size, Brightness)` pair in [_generate] using a seeded xorshift PRNG and
/// cached in a static map. [paint] only replays cached `Path`s and
/// pre-laid-out `TextPainter`s: no per-frame `Random()`, no per-frame text
/// layout, no shaders except the single chip glow. A few hundred cheap GPU
/// primitives ≈ well under 1 ms — comfortable 60 FPS headroom.
///
/// `shouldRepaint` only fires when the [Brightness] changes (theme toggle) or
/// the painted [Size] changes; identical rebuilds reuse the cached layer.
class CyberCircuitPainter extends CustomPainter {
  CyberCircuitPainter({
    this.brightness = Brightness.dark,
    this.stepSize = 90.0,
    this.density = 0.50,
    this.jitter = 25.0,
    this.chamferSize = 8.0,
    this.busSpacing = 5.0,
    this.maxBusLanes = 3,
    this.seed = 0x504342, // "PCB" — fixed seed keeps the layout stable.
  });

  /// Active theme brightness — selects the palette and label style.
  final Brightness brightness;

  /// Anchor grid spacing in logical pixels.
  final double stepSize;

  /// Probability (0.0–1.0) that a grid point becomes an anchor.
  final double density;

  /// Maximum random offset applied to each anchor, in logical pixels.
  final double jitter;

  /// Length of the 45° chamfer inserted at trace corners, in logical pixels.
  final double chamferSize;

  /// Perpendicular pitch between parallel data-bus lanes, in logical pixels.
  final double busSpacing;

  /// Maximum parallel lane count for a data bus (2–3 typically).
  final int maxBusLanes;

  /// PRNG seed — change to get a different (still deterministic) layout.
  final int seed;

  // ── Element metrics ──────────────────────────────────────────────────────
  static const double _viaRadius = 2.0;
  static const double _ringRadius = 3.5;
  static const double _chipSize = 7.0;
  static const double _chipCornerRadius = 2.0;
  static const double _crosshairArm = 3.0;

  // ── Tier thresholds (physical pixels, independent of stepSize) ───────────
  static const double _nanoMaxDistance = 160.0;
  static const double _majorMinDistance = 350.0;

  // ── Ornament probabilities ───────────────────────────────────────────────
  static const double _busChance = 0.30;
  static const double _crosshairChance = 0.30;
  static const double _emptyLabelChance = 0.08;
  static const double _chipLabelChance = 0.20;
  static const double _busChamferFactor = 0.65;

  /// Hardcoded terminal-style readouts assigned to micro-labels.
  static const List<String> _labelPool = [
    'SYS:ON', '0x8FA', 'DATA_LINK', 'NET_OK', 'NODE_42',
    'FREQ:114', 'LINK_UP', '0x1B2', 'CTRL_A', 'V_SYNC',
    'SIG:OK', '0x00F', 'CH_04', 'RDY', 'CLK_SRC',
    'NODE_7A', 'PING_OK', 'IRQ:01', 'DMA_1', '0xFFE0',
  ];

  /// Size last painted at; used by [shouldRepaint] to detect resizes.
  Size? _lastSize;

  /// Static cache: one entry per unique (size, brightness, tuning) tuple.
  /// Geometry AND pre-laid-out label painters live here, so widget rebuilds
  /// never regenerate anything — only a resize or a theme toggle does.
  /// Brightness is part of the key because label colors differ per theme.
  static final Map<
      (Size, Brightness, int, double, double, double, double, double, int),
      _CircuitCache> _cacheBySize = {};

  // ── Palette ──────────────────────────────────────────────────────────────

  static _CircuitPalette _paletteFor(Brightness brightness) {
    if (brightness == Brightness.light) {
      // "Tactical AR Day-Mode" — slate blueprint underlay, cyan live nodes.
      return const _CircuitPalette(
        nanoTraceColor: Color(0xFF94A3B8), // slate-400
        nanoTraceOpacity: 0.06,
        midTraceColor: Color(0xFF64748B), // slate-500
        midTraceOpacity: 0.08,
        busTraceColor: Color(0xFF64748B), // slate-500
        busTraceOpacity: 0.07,
        majorTraceColor: Color(0xFF475569), // slate-600
        majorTraceOpacity: 0.12,
        crosshairColor: Color(0xFF94A3B8), // slate-400
        crosshairOpacity: 0.08,
        viaColor: Color(0xFF475569), // slate-600
        viaOpacity: 0.14,
        ringColor: Color(0xFF94A3B8), // slate-400
        ringOpacity: 0.10,
        chipColor: Color(0xFF00E5FF), // jarvis cyan
        chipOpacity: 0.14,
        chipStrokeColor: Color(0xFF00E5FF), // jarvis cyan
        chipStrokeOpacity: 0.20,
        labelColor: Color(0xFF00E5FF), // jarvis cyan
        labelOpacity: 0.18,
        chipGlow: false,
      );
    }
    // "J.A.R.V.I.S Hypergrid" — cyan traces, gold chip accents with glow.
    return const _CircuitPalette(
      nanoTraceColor: Color(0xFF00E5FF), // jarvis cyan
      nanoTraceOpacity: 0.06,
      midTraceColor: Color(0xFF00E5FF), // jarvis cyan
      midTraceOpacity: 0.08,
      busTraceColor: Color(0xFF00E5FF), // jarvis cyan
      busTraceOpacity: 0.07,
      majorTraceColor: Color(0xFF00E5FF), // jarvis cyan
      majorTraceOpacity: 0.13,
      crosshairColor: Color(0xFF00E5FF), // jarvis cyan
      crosshairOpacity: 0.08,
      viaColor: Color(0xFF00E5FF), // jarvis cyan
      viaOpacity: 0.14,
      ringColor: Color(0xFF00E5FF), // jarvis cyan
      ringOpacity: 0.10,
      chipColor: Color(0xFFF6B300), // brand gold
      chipOpacity: 0.10,
      chipStrokeColor: Color(0xFFF6B300), // brand gold
      chipStrokeOpacity: 0.16,
      labelColor: Color(0xFF00E5FF), // jarvis cyan
      labelOpacity: 0.16,
      chipGlow: true,
    );
  }

  // ── CustomPainter API ────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    _lastSize = size;
    final palette = _paletteFor(brightness);
    final circuit = _cacheFor(size, brightness);

    // 1–4. Tiered traces, bottom → top: nano → mid → bus lanes → arteries.
    canvas.drawPath(
      circuit.nanoTraces,
      _strokePaint(palette.nanoTraceColor, palette.nanoTraceOpacity, 0.5),
    );
    canvas.drawPath(
      circuit.midTraces,
      _strokePaint(palette.midTraceColor, palette.midTraceOpacity, 1.0),
    );
    canvas.drawPath(
      circuit.busTraces,
      _strokePaint(palette.busTraceColor, palette.busTraceOpacity, 0.8),
    );
    canvas.drawPath(
      circuit.majorTraces,
      _strokePaint(palette.majorTraceColor, palette.majorTraceOpacity, 1.5),
    );

    // 5. Crosshair registration marks.
    canvas.drawPath(
      circuit.crosshairs,
      _strokePaint(palette.crosshairColor, palette.crosshairOpacity, 0.5),
    );

    // 6. Via rings (stroked) — before fills so fills sit on top.
    final ringPaint = Paint()
      ..color = palette.ringColor.withValues(alpha: palette.ringOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true;
    for (final via in circuit.vias) {
      canvas.drawCircle(via, _ringRadius, ringPaint);
    }

    // 7. Via fills (small solder pads).
    final viaPaint = Paint()
      ..color = palette.viaColor.withValues(alpha: palette.viaOpacity)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    for (final via in circuit.vias) {
      canvas.drawCircle(via, _viaRadius, viaPaint);
    }

    // 8. Chip nodes (ICs) — blur glow on gold chips in dark mode only.
    final chipFillPaint = Paint()
      ..color = palette.chipColor.withValues(alpha: palette.chipOpacity)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    if (palette.chipGlow) {
      chipFillPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    }
    final chipStrokePaint = Paint()
      ..color =
          palette.chipStrokeColor.withValues(alpha: palette.chipStrokeOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true;
    for (final chip in circuit.chips) {
      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: chip, width: _chipSize, height: _chipSize),
        const Radius.circular(_chipCornerRadius),
      );
      canvas.drawRRect(rrect, chipFillPaint);
      canvas.drawRRect(rrect, chipStrokePaint);
    }

    // 9. Micro-labels — pre-laid-out TextPainters, zero layout cost per frame.
    for (final label in circuit.labels) {
      label.painter.paint(canvas, label.offset);
    }
  }

  @override
  bool shouldRepaint(CyberCircuitPainter oldDelegate) {
    return oldDelegate.brightness != brightness ||
        oldDelegate._lastSize != _lastSize;
  }

  /// Shared stroke paint for the tiered and crosshair paths.
  static Paint _strokePaint(Color color, double opacity, double width) {
    return Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
  }

  // ── Cache ────────────────────────────────────────────────────────────────

  _CircuitCache _cacheFor(Size size, Brightness brightness) {
    final key = (
      size,
      brightness,
      seed,
      stepSize,
      density,
      jitter,
      chamferSize,
      busSpacing,
      maxBusLanes,
    );
    final cached = _cacheBySize[key];
    if (cached != null) return cached;
    // Bounded cache: a long resize drag must not leak geometry entries.
    if (_cacheBySize.length >= 8) _cacheBySize.clear();
    final generated = _generate(size, brightness);
    _cacheBySize[key] = generated;
    return generated;
  }

  // ── Geometry generation (deterministic, seeded) ──────────────────────────

  _CircuitCache _generate(Size size, Brightness brightness) {
    final rng = _SeededRandom(seed);
    final anchors = <_Anchor>[];
    final crosshairPositions = <Offset>[];
    final labelPositions = <Offset>[];

    // Anchor grid extends one cell beyond every edge so traces flow off the
    // canvas naturally instead of stopping abruptly at the border.
    final minCol = -1;
    final maxCol = (size.width / stepSize).ceil() + 1;
    final minRow = -1;
    final maxRow = (size.height / stepSize).ceil() + 1;
    for (var gy = minRow; gy <= maxRow; gy++) {
      for (var gx = minCol; gx <= maxCol; gx++) {
        if (rng.nextDouble() < density) {
          final x = gx * stepSize + rng.nextRange(-jitter, jitter);
          final y = gy * stepSize + rng.nextRange(-jitter, jitter);
          // ~7% of anchors are upgraded to chip (IC) nodes.
          anchors.add(
            _Anchor(Offset(x, y), gx, gy, isChip: rng.nextDouble() < 0.07),
          );
        } else {
          // Empty intersection: possibly a crosshair and/or a micro-label.
          final px = gx * stepSize;
          final py = gy * stepSize;
          if (rng.nextDouble() < _crosshairChance) {
            crosshairPositions.add(Offset(px, py));
          }
          if (rng.nextDouble() < _emptyLabelChance) {
            labelPositions.add(Offset(px, py));
          }
        }
      }
    }

    final nanoTraces = Path();
    final midTraces = Path();
    final busTraces = Path();
    final majorTraces = Path();
    final vias = <Offset>[];
    final chips = <Offset>[];

    for (final (i, j) in _pickConnections(anchors, rng)) {
      final a = anchors[i].position;
      final b = anchors[j].position;
      final cornerVias = <Offset>[];
      final route = _routeTrace(a, b, rng, cornerVias);
      if (route == null) continue; // too short / coincident anchors
      final smooth = _chamferRoute(route, chamferSize);
      final distance = (a - b).distance;

      if (distance < _nanoMaxDistance) {
        _appendPath(nanoTraces, smooth); // tier 0: background fuzz
      } else if (distance < _majorMinDistance) {
        _appendPath(midTraces, smooth); // tier 1: standard PCB routing
      } else {
        _appendPath(majorTraces, smooth); // tier 2: data artery
        // ~30% of arteries carry a parallel data bus.
        if (rng.nextDouble() < _busChance) {
          for (final lane in _buildBusLanes(route, rng)) {
            _appendPath(
              busTraces,
              _chamferRoute(lane, chamferSize * _busChamferFactor),
            );
          }
        }
      }
      vias.addAll(cornerVias);
    }

    // Crosshair path — every mark batched into a single Path.
    final crosshairs = Path();
    for (final p in crosshairPositions) {
      crosshairs
        ..moveTo(p.dx - _crosshairArm, p.dy)
        ..lineTo(p.dx + _crosshairArm, p.dy)
        ..moveTo(p.dx, p.dy - _crosshairArm)
        ..lineTo(p.dx, p.dy + _crosshairArm);
    }

    // Anchor pads: chips replace the plain via at their position.
    for (final anchor in anchors) {
      if (anchor.isChip) {
        chips.add(anchor.position);
      } else {
        vias.add(anchor.position);
      }
    }

    // Micro-labels — TextPainters are created AND laid out here, once per
    // cache entry, so paint() never pays for text layout.
    final palette = _paletteFor(brightness);
    final labelStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 8.0,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.5,
      height: 1.0,
      color: palette.labelColor.withValues(alpha: palette.labelOpacity),
    );
    final labels = <_LabelEntry>[];
    for (final anchor in anchors) {
      if (anchor.isChip && rng.nextDouble() < _chipLabelChance) {
        labels.add(_buildLabel(anchor.position, rng, labelStyle));
      }
    }
    for (final pos in labelPositions) {
      labels.add(_buildLabel(pos, rng, labelStyle));
    }

    return _CircuitCache(
      nanoTraces: nanoTraces,
      midTraces: midTraces,
      busTraces: busTraces,
      majorTraces: majorTraces,
      crosshairs: crosshairs,
      vias: vias,
      chips: chips,
      labels: labels,
    );
  }

  /// Generates 2–3 parallel offset copies of a raw (pre-chamfer) route.
  ///
  /// Every point of the route is shifted by a constant perpendicular vector
  /// (uniform translation), so the lanes keep the exact same corners as the
  /// parent artery. The dominant axis decides the offset axis; the sign
  /// scatters lanes on both sides of the artery.
  List<List<Offset>> _buildBusLanes(List<Offset> route, _SeededRandom rng) {
    final lanes = rng.nextBool() ? 3 : 2;
    final laneCount = math.min(maxBusLanes, lanes);
    final a = route.first;
    final b = route.last;
    final horizontalPrimary = (b.dx - a.dx).abs() >= (b.dy - a.dy).abs();
    final sign = rng.nextBool() ? 1.0 : -1.0;
    final unit = horizontalPrimary ? const Offset(0, 1.0) : const Offset(1.0, 0.0);

    return [
      for (var lane = 1; lane <= laneCount; lane++)
        [for (final p in route) p + unit * (busSpacing * lane * sign)],
    ];
  }

  /// Selects 1–3 neighbors per anchor (raster scan, so every pair is
  /// considered once) and returns the connection index pairs.
  List<(int, int)> _pickConnections(
    List<_Anchor> anchors,
    _SeededRandom rng,
  ) {
    final result = <(int, int)>[];
    for (var i = 0; i < anchors.length; i++) {
      final a = anchors[i];
      final near = <int>[];
      final far = <int>[];
      for (var j = i + 1; j < anchors.length; j++) {
        final b = anchors[j];
        final dgx = (b.gridX - a.gridX).abs();
        final dgy = (b.gridY - a.gridY).abs();
        if (dgx <= 2 && dgy <= 2) {
          near.add(j);
        } else if (dgx <= 6 && dgy <= 6) {
          far.add(j);
        }
        if (near.length >= 8 && far.length >= 4) break;
      }

      _shuffle(near, rng);
      _shuffle(far, rng);

      var made = 0;
      for (final j in near) {
        if (made >= 2) break;
        if (rng.nextDouble() < 0.55) {
          result.add((i, j));
          made++;
        }
      }
      // Guarantee most anchors participate in the circuit.
      if (made == 0 && near.isNotEmpty && rng.nextDouble() < 0.9) {
        result.add((i, near.first));
        made = 1;
      }
      // Occasional long trace for elegance (max 3 connections per anchor).
      if (made < 3 && far.isNotEmpty && rng.nextDouble() < 0.3) {
        result.add((i, far.first));
      }
    }
    return result;
  }

  /// Builds the raw polyline (before chamfering) for a trace from [a] to [b].
  ///
  /// Style lottery — L-shape 60%, Z-shape 30%, S-route 10%. Sharp corners are
  /// recorded into [cornerVias] so every bend gets a small solder pad.
  List<Offset>? _routeTrace(
    Offset a,
    Offset b,
    _SeededRandom rng,
    List<Offset> cornerVias,
  ) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final adx = dx.abs();
    final ady = dy.abs();

    if (adx < 0.5 && ady < 0.5) return null; // coincident anchors
    if (adx + ady < 2 * chamferSize + 24) return null; // too short to route

    // Nearly axis-aligned: straight run, or a chamfered dog-leg jog.
    if (adx < 0.5 || ady < 0.5) {
      if (adx + ady > 4 * chamferSize && rng.nextDouble() < 0.35) {
        return _jogTrace(a, b, rng);
      }
      return [a, b];
    }

    final style = rng.nextDouble();
    if (style < 0.60) return _lTrace(a, b, rng, cornerVias);
    if (style < 0.90) return _zTrace(a, b, rng, cornerVias);
    return _sTrace(a, b, rng, cornerVias);
  }

  /// L-shape: one horizontal + one vertical segment meeting at a corner.
  List<Offset> _lTrace(
    Offset a,
    Offset b,
    _SeededRandom rng,
    List<Offset> cornerVias,
  ) {
    final corner = rng.nextBool() ? Offset(b.dx, a.dy) : Offset(a.dx, b.dy);
    cornerVias.add(corner);
    return [a, corner, b];
  }

  /// Z-shape: primary axis split at a random ratio → two corners.
  List<Offset> _zTrace(
    Offset a,
    Offset b,
    _SeededRandom rng,
    List<Offset> cornerVias,
  ) {
    final t = rng.nextRange(0.3, 0.7);
    if (rng.nextBool()) {
      final mid = a.dx + (b.dx - a.dx) * t;
      final m1 = Offset(mid, a.dy);
      final m2 = Offset(mid, b.dy);
      cornerVias
        ..add(m1)
        ..add(m2);
      return [a, m1, m2, b];
    }
    final mid = a.dy + (b.dy - a.dy) * t;
    final m1 = Offset(a.dx, mid);
    final m2 = Offset(b.dx, mid);
    cornerVias
      ..add(m1)
      ..add(m2);
    return [a, m1, m2, b];
  }

  /// S-route: five segments with four chamfered bends — premium PCB detail.
  List<Offset> _sTrace(
    Offset a,
    Offset b,
    _SeededRandom rng,
    List<Offset> cornerVias,
  ) {
    final t1 = rng.nextRange(0.2, 0.45);
    final t2 = rng.nextRange(0.55, 0.8);
    final horizontalPrimary = (b.dx - a.dx).abs() >= (b.dy - a.dy).abs();

    if (horizontalPrimary) {
      final x1 = a.dx + (b.dx - a.dx) * t1;
      final x2 = a.dx + (b.dx - a.dx) * t2;
      final yMid = a.dy + (b.dy - a.dy) / 2;
      final pts = [
        Offset(x1, a.dy),
        Offset(x1, yMid),
        Offset(x2, yMid),
        Offset(x2, b.dy),
      ];
      cornerVias.addAll(pts);
      return [a, ...pts, b];
    }
    final y1 = a.dy + (b.dy - a.dy) * t1;
    final y2 = a.dy + (b.dy - a.dy) * t2;
    final xMid = a.dx + (b.dx - a.dx) / 2;
    final pts = [
      Offset(a.dx, y1),
      Offset(xMid, y1),
      Offset(xMid, y2),
      Offset(b.dx, y2),
    ];
    cornerVias.addAll(pts);
    return [a, ...pts, b];
  }

  /// Dog-leg jog for axis-aligned pairs: two short 45°-chamfered stubs with a
  /// parallel offset run between them — like real PCB trace routing.
  List<Offset> _jogTrace(Offset a, Offset b, _SeededRandom rng) {
    final jog = 10.0 + rng.nextDouble() * 12.0; // 10–22 px offset
    final horizontal = (b.dx - a.dx).abs() >= (b.dy - a.dy).abs();
    final ch = chamferSize;

    if (horizontal) {
      final y = rng.nextBool() ? a.dy + jog : a.dy - jog;
      return [
        a,
        Offset(a.dx + ch, a.dy),
        Offset(a.dx + ch, y),
        Offset(b.dx - ch, y),
        Offset(b.dx - ch, b.dy),
        b,
      ];
    }
    final x = rng.nextBool() ? a.dx + jog : a.dx - jog;
    return [
      a,
      Offset(a.dx, a.dy + ch),
      Offset(x, a.dy + ch),
      Offset(x, b.dy - ch),
      Offset(b.dx, b.dy - ch),
      b,
    ];
  }

  /// Replaces every interior 90° corner with a 45° chamfer.
  ///
  /// For a corner [c] between [prev] and [next], the trace cuts from
  /// `c - uIn * ch` to `c + uOut * ch` (uIn/uOut = normalized segment
  /// directions), producing the classic PCB 45° bend. Chamfer length is
  /// clamped to half of the shorter adjacent segment so short runs stay valid.
  List<Offset> _chamferRoute(List<Offset> route, double ch) {
    if (route.length < 3) return route;
    final result = <Offset>[route.first];
    for (var i = 1; i < route.length - 1; i++) {
      final c = route[i];
      final prev = route[i - 1];
      final next = route[i + 1];
      final inLen = (c - prev).distance;
      final outLen = (next - c).distance;
      final chEff = math.min(ch, math.min(inLen / 2, outLen / 2));
      if (chEff < 1.0) {
        result.add(c); // segment too short for a meaningful chamfer
        continue;
      }
      final uIn = (c - prev) / inLen;
      final uOut = (next - c) / outLen;
      result
        ..add(c - uIn * chEff)
        ..add(c + uOut * chEff);
    }
    result.add(route.last);
    return result;
  }

  /// Appends [polyline] as one subpath of [path].
  static void _appendPath(Path path, List<Offset> polyline) {
    path.moveTo(polyline.first.dx, polyline.first.dy);
    for (var k = 1; k < polyline.length; k++) {
      path.lineTo(polyline[k].dx, polyline[k].dy);
    }
  }

  /// Builds and lays out one micro-label near [anchor].
  _LabelEntry _buildLabel(Offset anchor, _SeededRandom rng, TextStyle style) {
    final text = _labelPool[(rng.nextDouble() * _labelPool.length).floor()];
    final direction = (rng.nextDouble() * 4).floor();
    final offset = switch (direction) {
      0 => const Offset(6, -8), // NE
      1 => const Offset(6, 10), // SE
      2 => const Offset(-6, 10), // SW
      _ => const Offset(-6, -8), // NW
    };
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      textScaler: TextScaler.noScaling,
    )..layout();
    return _LabelEntry(offset: anchor + offset, painter: painter);
  }

  /// In-place Fisher–Yates shuffle driven by the seeded PRNG.
  void _shuffle<T>(List<T> list, _SeededRandom rng) {
    for (var i = list.length - 1; i > 0; i--) {
      final k = (rng.nextDouble() * (i + 1)).floor();
      final tmp = list[i];
      list[i] = list[k];
      list[k] = tmp;
    }
  }
}

// ── Support types ─────────────────────────────────────────────────────────

/// One anchor point of the circuit grid.
class _Anchor {
  const _Anchor(this.position, this.gridX, this.gridY, {required this.isChip});

  /// Jittered position in logical pixels.
  final Offset position;

  /// Grid cell coordinates (used for neighbor proximity, not distance scans).
  final int gridX;
  final int gridY;

  /// When true, this anchor renders as a chip node instead of a via.
  final bool isChip;
}

/// Pre-built drawable geometry (and pre-laid-out labels) for one
/// (size, brightness) pair.
class _CircuitCache {
  const _CircuitCache({
    required this.nanoTraces,
    required this.midTraces,
    required this.busTraces,
    required this.majorTraces,
    required this.crosshairs,
    required this.vias,
    required this.chips,
    required this.labels,
  });

  /// Tier 0: ultra-thin background traces (0.5 px).
  final Path nanoTraces;

  /// Tier 1: standard PCB routing traces (1.0 px).
  final Path midTraces;

  /// Parallel offset copies of data arteries (0.8 px).
  final Path busTraces;

  /// Tier 2: long data arteries (1.5 px).
  final Path majorTraces;

  /// `+` registration marks at empty grid intersections (0.5 px).
  final Path crosshairs;

  /// Solder-pad positions: anchors + trace corner bends.
  final List<Offset> vias;

  /// IC node positions.
  final List<Offset> chips;

  /// Pre-laid-out micro-labels — zero text layout work in [paint].
  final List<_LabelEntry> labels;
}

/// One micro-label: a ready-to-paint [TextPainter] and its anchor offset.
class _LabelEntry {
  const _LabelEntry({required this.offset, required this.painter});

  /// Top-left paint position.
  final Offset offset;

  /// Pre-laid-out painter (created once inside `_generate`).
  final TextPainter painter;
}

/// Per-brightness color + opacity set (see [CyberCircuitPainter._paletteFor]).
class _CircuitPalette {
  const _CircuitPalette({
    required this.nanoTraceColor,
    required this.nanoTraceOpacity,
    required this.midTraceColor,
    required this.midTraceOpacity,
    required this.busTraceColor,
    required this.busTraceOpacity,
    required this.majorTraceColor,
    required this.majorTraceOpacity,
    required this.crosshairColor,
    required this.crosshairOpacity,
    required this.viaColor,
    required this.viaOpacity,
    required this.ringColor,
    required this.ringOpacity,
    required this.chipColor,
    required this.chipOpacity,
    required this.chipStrokeColor,
    required this.chipStrokeOpacity,
    required this.labelColor,
    required this.labelOpacity,
    required this.chipGlow,
  });

  final Color nanoTraceColor;
  final double nanoTraceOpacity;
  final Color midTraceColor;
  final double midTraceOpacity;
  final Color busTraceColor;
  final double busTraceOpacity;
  final Color majorTraceColor;
  final double majorTraceOpacity;
  final Color crosshairColor;
  final double crosshairOpacity;
  final Color viaColor;
  final double viaOpacity;
  final Color ringColor;
  final double ringOpacity;
  final Color chipColor;
  final double chipOpacity;
  final Color chipStrokeColor;
  final double chipStrokeOpacity;
  final Color labelColor;
  final double labelOpacity;

  /// Dark mode only — applies a subtle blur glow to the chip fills.
  final bool chipGlow;
}

/// Tiny xorshift32 PRNG — fast, deterministic, and platform-stable.
///
/// The same seed always yields the same sequence, so the circuit layout is
/// identical on every rebuild and across devices. State is masked to 31 bits
/// to avoid any platform-dependent integer-overflow behavior.
class _SeededRandom {
  _SeededRandom(int seed) : _state = (seed & 0x7FFFFFFF) | 1;

  int _state;

  /// Next double in the half-open range [0, 1).
  double nextDouble() {
    var x = _state;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    _state = x & 0x7FFFFFFF;
    return _state / 0x7FFFFFFF;
  }

  bool nextBool() => nextDouble() < 0.5;

  double nextRange(double min, double max) =>
      min + nextDouble() * (max - min);
}
