import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sindomon/widget/background.dart';
import 'package:sindomon/widget/cyber_circuit_painter.dart';

/// Renders [painter] at [size] and returns PNG bytes — used to prove the
/// circuit is deterministic (byte-identical frames) and palette-aware.
Future<List<int>> _pngBytes(CyberCircuitPainter painter, Size size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  painter.paint(canvas, size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  picture.dispose();
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

void main() {
  group('CyberCircuitPainter', () {
    test('paints byte-identical frames for the same size (deterministic)', () async {
      final painter = CyberCircuitPainter(brightness: Brightness.dark);
      final first = await _pngBytes(painter, const Size(800, 600));
      final second = await _pngBytes(painter, const Size(800, 600));
      expect(first, equals(second));
    });

    test('two instances with same config share the cache (identical frames)', () async {
      final a =
          await _pngBytes(CyberCircuitPainter(brightness: Brightness.dark), const Size(800, 600));
      final b =
          await _pngBytes(CyberCircuitPainter(brightness: Brightness.dark), const Size(800, 600));
      expect(a, equals(b));
    });

    test('light and dark palettes produce visibly different frames', () async {
      final light =
          await _pngBytes(CyberCircuitPainter(brightness: Brightness.light), const Size(800, 600));
      final dark =
          await _pngBytes(CyberCircuitPainter(brightness: Brightness.dark), const Size(800, 600));
      expect(light, isNot(equals(dark)));
    });

    test('paints at a second size without errors (cache regeneration)', () async {
      final painter = CyberCircuitPainter(brightness: Brightness.light);
      final small = await _pngBytes(painter, const Size(640, 480));
      final large = await _pngBytes(painter, const Size(1600, 900));
      expect(small, isNotEmpty);
      expect(large, isNotEmpty);
      expect(small, isNot(equals(large)));
    });

    test('shouldRepaint only on brightness or painted-size change', () {
      final a = CyberCircuitPainter(brightness: Brightness.dark);
      final b = CyberCircuitPainter(brightness: Brightness.dark);
      // Both never painted → no repaint needed.
      expect(b.shouldRepaint(a), isFalse);

      final light = CyberCircuitPainter(brightness: Brightness.light);
      expect(light.shouldRepaint(a), isTrue); // brightness changed

      // After painting at a size, a fresh painter (unknown size) repaints.
      _pngBytes(a, const Size(800, 600)); // sets a._lastSize
      final fresh = CyberCircuitPainter(brightness: Brightness.dark);
      expect(fresh.shouldRepaint(a), isTrue); // size unknown on new painter

      // Same painter instance never compares against itself.
      expect(a.shouldRepaint(a), isFalse);
    });
  });

  group('AppBackground', () {
    testWidgets('wraps content in CustomPaint in BOTH themes', (tester) async {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness, scaffoldBackgroundColor: Colors.transparent),
            home: Scaffold(
              body: AppBackground(
                child: const Center(child: Text('content')),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: 'brightness=$brightness');
        expect(
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is CyberCircuitPainter,
          ),
          findsOneWidget,
          reason: 'brightness=$brightness',
        );
        expect(find.text('content'), findsOneWidget, reason: 'brightness=$brightness');
      }
    });

    testWidgets('paints the circuit behind content without exceptions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: Colors.transparent),
          home: const Scaffold(body: AppBackground(child: SizedBox.expand())),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
