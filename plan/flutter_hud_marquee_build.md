# HUD Marquee Build — Native Auto-Scrolling Title (Executed)

> **Status:** CODE / EXECUTE MODE — implementation applied and verified.  
> **Target file:** `lib/pages/dashboard.dart`  
> **Changes applied:**
> 1. Added `import 'dart:async';` (line 1) — required for `Timer` cancellation safety.
> 2. Replaced the static `Expanded(child: Text(...))` in `_HudTitleBar` (line 993) with `Expanded(child: _HudMarqueeText(...))`.
> 3. Appended the complete `_HudMarqueeText` / `_HudMarqueeTextState` widgets at the bottom of `dashboard.dart` (after `_HudDivider`, lines 1065–1252).

> **Manual apply instructions (if porting to another copy):** replace the old `_HudTitleBar` class with the new one below, append `_HudMarqueeText` at the bottom of `dashboard.dart`, and add `import 'dart:async';` at the top of the file.

---

## 1. New `_HudTitleBar` (replaces the old class)

```dart
/// HUD title bar: uppercase Polda name + tech close button.
class _HudTitleBar extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _HudTitleBar({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.shield_outlined, size: 18, color: Colors.cyanAccent),
        const SizedBox(width: 8),
        Expanded(
          child: _HudMarqueeText(
            text: title.toUpperCase(),
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        IconButton(
          onPressed: onClose,
          tooltip: 'Tutup',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.close, color: Colors.cyanAccent, size: 20),
        ),
      ],
    );
  }
}
```

**Changes vs. old version:** the `Text` widget (with `maxLines: 1` + `TextOverflow.ellipsis`) is gone; the `Expanded` now hosts `_HudMarqueeText`. The exact `TextStyle` (`Colors.cyanAccent`, `fontSize: 15`, `FontWeight.bold`, `letterSpacing: 1.2`) and `.toUpperCase()` are preserved verbatim.

---

## 2. New `_HudMarqueeText` (append at the bottom of `dashboard.dart`)

```dart
/// HUD auto-scrolling text (native marquee, zero external packages).
///
/// Renders [text] statically when it fits the available width. When the text
/// overflows, it waits [pauseBeforeScroll], then runs a seamless, infinitely
/// looping scroll using only core Flutter primitives: a [TextPainter] width
/// measurement, an [AnimationController] with a linear curve, and a
/// [Transform.translate] shifting two side-by-side copies of the text inside
/// a [ClipRect]. Because the second copy lands exactly where the first copy
/// started when the controller wraps from 1.0 back to 0.0, the loop has no
/// visible jump.
class _HudMarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  /// Idle time before the continuous scroll loop begins.
  final Duration pauseBeforeScroll;

  /// Horizontal gap between the two scrolling copies.
  final double gapBetweenCopies;

  /// Scroll speed in logical pixels per second.
  final double scrollSpeed;

  const _HudMarqueeText({
    required this.text,
    required this.style,
    this.pauseBeforeScroll = const Duration(milliseconds: 1500),
    this.gapBetweenCopies = 40,
    this.scrollSpeed = 30,
  });

  @override
  State<_HudMarqueeText> createState() => _HudMarqueeTextState();
}

class _HudMarqueeTextState extends State<_HudMarqueeText>
    with SingleTickerProviderStateMixin {
  /// Key attached to the rendered content so its laid-out width can be
  /// measured after the first frame.
  final GlobalKey _containerKey = GlobalKey();

  late final AnimationController _controller;
  Timer? _startTimer;

  double _textWidth = 0;
  double _lineHeight = 0;
  double _containerWidth = 0;
  bool _needsMarquee = false;
  bool _measured = false;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndStart());
  }

  @override
  void didUpdateWidget(_HudMarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
      // Text or style changed: cancel any pending scroll and re-measure.
      _startTimer?.cancel();
      _controller
        ..stop()
        ..value = 0;
      _measured = false;
      _containerWidth = 0;
      _needsMarquee = false;
      _retryCount = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndStart());
    }
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Measures the laid-out container width (via the render box) and the
  /// full unclipped text width (via [TextPainter]), then starts the marquee
  /// loop when the text overflows the container.
  void _measureAndStart() {
    if (!mounted) return;

    final renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      // First frame may not be laid out yet — retry on the next frame.
      if (_retryCount++ < 5) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndStart());
      }
      return;
    }

    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();

    if (!mounted) return;

    setState(() {
      _textWidth = textPainter.width;
      _lineHeight = textPainter.height;
      _containerWidth = renderBox.size.width;
      _needsMarquee = _textWidth > _containerWidth;
      _measured = true;
    });

    if (!_needsMarquee) return;

    // Scale the cycle duration with the travelled distance so longer names
    // keep a constant, deliberate HUD scroll speed.
    final totalWidth = _textWidth + widget.gapBetweenCopies;
    final durationMs =
        ((totalWidth / widget.scrollSpeed) * 1000).round().clamp(1500, 12000);
    _controller.duration = Duration(milliseconds: durationMs);

    _startTimer = Timer(widget.pauseBeforeScroll, () {
      if (mounted) _controller.repeat();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_measured || !_needsMarquee) {
      // Static path: text fits (or measurement is still pending).
      return Text(
        widget.text,
        key: _containerKey,
        maxLines: 1,
        softWrap: false,
        style: widget.style,
      );
    }

    // Marquee path: two copies, shifted by the linear controller value.
    // totalWidth is the distance travelled per cycle, so when the controller
    // wraps back to 0.0 the second copy occupies the first copy's exact
    // starting position — a seamless infinite loop.
    final totalWidth = _textWidth + widget.gapBetweenCopies;

    return SizedBox(
      key: _containerKey,
      height: _lineHeight,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return OverflowBox(
              alignment: Alignment.centerLeft,
              clipBehavior: Clip.none,
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: Transform.translate(
                offset: Offset(-_controller.value * totalWidth, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.text,
                      maxLines: 1,
                      softWrap: false,
                      style: widget.style,
                    ),
                    SizedBox(width: widget.gapBetweenCopies),
                    Text(
                      widget.text,
                      maxLines: 1,
                      softWrap: false,
                      style: widget.style,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

---

## 3. Implementation Notes (behavior contract)

| Requirement | How it's satisfied |
|---|---|
| 1.5 s pause before scrolling | `Timer(widget.pauseBeforeScroll, ...)` — `pauseBeforeScroll` defaults to `Duration(milliseconds: 1500)` |
| Seamless infinite loop | Two copies + `Transform.translate` over `totalWidth = textWidth + gap`; controller wraps 1.0 → 0.0 with identical pixels; `AnimationController.repeat()` is linear by default |
| Overflow detection | Post-frame `TextPainter.layout()` width vs. measured `RenderBox` width (`_containerKey`) — no `LayoutBuilder` state mutation in `build` |
| No layout overflow errors | `OverflowBox` (unbounded child constraints, `clipBehavior: Clip.none`) inside `ClipRect` — the `Row` never hits the classic `RenderFlex` overflow |
| Safe disposal | `dispose()` cancels the pending `Timer` and disposes the controller; every async continuation is `mounted`-guarded |
| Text/style changes | `didUpdateWidget` re-measures and restarts cleanly |
| Styling intact | `TextStyle` passed by `_HudTitleBar` unchanged (cyan, 15, bold, letterSpacing 1.2), `.toUpperCase()` applied before passing |

---

## 4. Verification performed

- `flutter analyze` — **not runnable in this environment** (no Flutter/Dart SDK installed on this machine). Run `flutter analyze` on a machine with the SDK before shipping.
- Manual verification: brace/paren/bracket balance (98/499/42 pairs, all `OK`), 12 classes present including `_HudMarqueeText` + `_HudMarqueeTextState`, `_HudTitleBar` no longer contains `TextOverflow.ellipsis` (the only remaining ellipsis at line 437 is pre-existing code in the Sitkamtibmas list, out of scope).
- Manual verification: `_HudTitleBar` → `_HudMarqueeText(text: title.toUpperCase(), style: ...)` wired correctly; icon + close button untouched.

---

*Build executed — ready for `flutter analyze` + on-device smoke test (short name → static; long name → 1.5 s pause then scroll).*
