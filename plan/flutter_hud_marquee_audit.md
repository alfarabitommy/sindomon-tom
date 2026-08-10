# HUD Marquee Audit — Native Auto-Scrolling Title for Drilldown Panel

> **Status:** PLAN / DEBUG MODE — analysis & architectural blueprint only.  
> **Target file:** `lib/pages/dashboard.dart`  
> **Affected widget:** `_HudTitleBar` (lines 980–1014)  
> **Problem:** Long Polda names (e.g. `POLDA KALIMANTAN BARAT`) are truncated with `TextOverflow.ellipsis`, breaking the sci-fi/J.A.R.V.I.S aesthetic.

---

## 1. Current `_HudTitleBar` Anatomy

**Location:** `lib/pages/dashboard.dart:980–1014`

```dart
class _HudTitleBar extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _HudTitleBar({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.shield_outlined, size: 18, color: Colors.cyanAccent),   // 18 px
        const SizedBox(width: 8),                                                  //  8 px
        Expanded(                             // ← constrained width = 300 - padding(32) - 18 - 8 - 48 = ~194 px
          child: Text(
            title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,  // ← TRUNCATION POINT
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        IconButton(                           // ← 48 px (24 icon + 2×12 padding)
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

### Width budget (panel is 300 px wide, 16 px padding each side → 284 px usable):

| Element              | Width  |
|----------------------|--------|
| Shield icon          | 18 px  |
| `SizedBox` gap       | 8 px   |
| **Available for text** | **~210 px** |
| Close `IconButton`   | 48 px  |

At `fontSize: 15` + `letterSpacing: 1.2` + bold, `"POLDA KALIMANTAN BARAT"` is approximately **240–250 px** wide, which exceeds the ~210 px budget → truncated to `"POLDA KALIMANTAN..."`.

### Invocation site (line 839):

```dart
_HudTitleBar(
  title: widget.node.namaPolda,
  onClose: () => Navigator.of(context).pop(),
),
```

---

## 2. Architectural Plan — `_HudMarqueeText`

### 2.1 Widget Signature

```dart
class _HudMarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration? pauseBeforeScroll;   // default: 1.5 s — J.A.R.V.I.S. "read first" pause
  final double gapBetweenCopies;       // default: 40 px — spacing between duplicated text
  final double scrollSpeed;            // default: 30 px/s — controls scroll duration

  const _HudMarqueeText({
    required this.text,
    required this.style,
    this.pauseBeforeScroll,
    this.gapBetweenCopies = 40,
    this.scrollSpeed = 30,
  });
}
```

### 2.2 State & Lifecycle

```
State mixin: SingleTickerProviderStateMixin
```

**Key state fields:**

| Field              | Type               | Purpose |
|--------------------|--------------------|---------|
| `_controller`      | `AnimationController` | Drives the translate offset (0.0 → 1.0 linear) |
| `_textWidth`       | `double`           | Measured width of one copy of the text |
| `_containerWidth`  | `double`           | Available width from `LayoutBuilder` |
| `_needsMarquee`    | `bool`             | `_textWidth > _containerWidth` |
| `_measured`        | `bool`             | Guards single measurement pass |

**Lifecycle:**

```
initState()
  ├─ Create AnimationController (duration placeholder, vsync: this)
  └─ (measurement deferred to post-frame)

build() → LayoutBuilder → captures constraints.maxWidth into _containerWidth
  └─ addPostFrameCallback → _measureAndStart()

_measureAndStart()
  ├─ TextPainter.layout() → _textWidth
  ├─ _needsMarquee = _textWidth > _containerWidth
  ├─ IF needsMarquee:
  │    ├─ duration = (_textWidth / scrollSpeed) seconds
  │    ├─ _controller.duration = duration
  │    └─ Future.delayed(pauseBeforeScroll) → _controller.repeat()
  └─ setState() → rebuild

dispose()
  └─ _controller.dispose()
```

### 2.3 Build Logic (Pseudocode)

```dart
@override
Widget build(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      // Capture available width on first meaningful layout pass.
      if (!_measured && constraints.maxWidth > 0 && _containerWidth == 0) {
        _containerWidth = constraints.maxWidth;
        WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndStart());
      }

      // --- Static path: text fits ---
      if (_measured && !_needsMarquee) {
        return Text(text, style: style, maxLines: 1);
      }

      // --- Static fallback before measurement ---
      if (!_measured) {
        return Text(text, style: style, maxLines: 1);
      }

      // --- Marquee path ---
      return SizedBox(
        height: _lineHeight, // from TextPainter
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final offset = -_controller.value * (_textWidth + gapBetweenCopies);
              return Transform.translate(
                offset: Offset(offset, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(text, style: style),
                    SizedBox(width: gapBetweenCopies),
                    Text(text, style: style),
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );
}
```

### 2.4 Seamless Loop Mechanics

```
                   VISIBLE WINDOW (containerWidth)
                   |                              |
Start (value=0):   [TEXT COPY 1    ][gap][TEXT COPY 2    ]
                   ^visible start

End (value=1):            [TEXT COPY 1    ][gap][TEXT COPY 2    ]
                                                ^visible start (IDENTICAL visual)
```

- Scrolled distance per cycle = `_textWidth + gapBetweenCopies`
- At the exact moment `_controller.value` wraps from 1.0 back to 0.0, the visible pixels are identical, so the viewer perceives an **infinite, seamless scroll**.
- Requires `Curves.linear` (no easing) on the `AnimationController`.

### 2.5 Edge Cases & Safeguards

| Scenario                     | Behavior |
|------------------------------|----------|
| Text fits                     | Render static `Text` — zero overhead |
| Text is empty / null          | Render empty `SizedBox.shrink()` or single-space `Text` |
| Panel / window resizes        | `LayoutBuilder` triggers rebuild → re-measure → toggle marquee on/off |
| `pauseBeforeScroll` elapsed after dispose | `mounted` guard before `_controller.repeat()` |
| Rapid open/close of panel     | `dispose()` cancels timer + disposes controller |

---

## 3. Integration Plan — Swapping in `_HudTitleBar`

### 3.1 Target Change (lines 992–1004)

**Before (current):**
```dart
Expanded(
  child: Text(
    title.toUpperCase(),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(
      color: Colors.cyanAccent,
      fontSize: 15,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
    ),
  ),
),
```

**After (planned):**
```dart
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
```

### 3.2 Styling Preservation Checklist

- ✅ `color: Colors.cyanAccent`
- ✅ `fontSize: 15`
- ✅ `fontWeight: FontWeight.bold`
- ✅ `letterSpacing: 1.2`
- ✅ `text.toUpperCase()` applied before passing to widget
- ✅ Icon and close button remain untouched

### 3.3 Widget Tree Change

```
Row
├── Icon (shield_outlined)          ← UNCHANGED
├── SizedBox(width: 8)              ← UNCHANGED
├── Expanded
│   └── _HudMarqueeText             ← NEW (replaces Text)
└── IconButton (close)              ← UNCHANGED
```

---

## 4. Implementation Checklist

### Phase 1: Create `_HudMarqueeText` (private widget, same file)

- [ ] Define widget class with `SingleTickerProviderStateMixin`
- [ ] Implement `LayoutBuilder` + `TextPainter` measurement
- [ ] Implement `AnimationController` with `Curves.linear`
- [ ] Build static path (text fits → plain `Text`)
- [ ] Build marquee path (`ClipRect` → `Transform.translate` → `Row` of 2 copies)
- [ ] Wire `pauseBeforeScroll` `Future.delayed` → `_controller.repeat()`
- [ ] Implement `dispose()` cleanup

### Phase 2: Swap in `_HudTitleBar`

- [ ] Replace `Expanded(child: Text(...))` with `Expanded(child: _HudMarqueeText(...))`
- [ ] Remove `maxLines: 1` and `overflow: TextOverflow.ellipsis` (handled internally)

### Phase 3: Test

- [ ] Short Polda name (e.g. `POLDA BALI`) → no scroll, static display
- [ ] Long Polda name (e.g. `POLDA KALIMANTAN BARAT`) → 1.5 s pause, then smooth scroll
- [ ] Very long Polda name → correct scroll speed scaling, seamless loop
- [ ] Close/reopen panel → clean dispose + re-init
- [ ] Rapid open/close → no memory leaks or orphaned timers

---

## 5. Rationale for Chosen Approach

| Alternative                  | Rejected Because |
|------------------------------|------------------|
| `SingleChildScrollView` + `ScrollController` | Scroll physics can fight animation; harder to achieve seamless infinite loop |
| `Marquee` package from pub.dev | External dependency not allowed per requirement |
| Smaller font / multi-line    | Breaks the HUD single-line aesthetic; looks cramped |
| `Stack` + `Positioned` animation | More complex layout math for seamless loop vs. `Transform.translate` |
| Duplicate text only (no `Transform`) + animate padding | Won't produce a seamless wrap-around |

The `Transform.translate` + duplicated-text approach is **zero-allocation during animation** (no `setState` calls per frame — `AnimatedBuilder` rebuilds only the subtree), **standard Flutter primitives only**, and produces a genuinely seamless infinite scroll.

---

## 6. Appendix: `TextPainter` Measurement Detail

```dart
void _measureAndStart() {
  final textPainter = TextPainter(
    text: TextSpan(text: widget.text, style: widget.style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout(maxWidth: double.infinity);

  final measuredWidth = textPainter.width;
  final lineHeight = textPainter.height;

  if (!mounted) return;

  setState(() {
    _textWidth = measuredWidth;
    _lineHeight = lineHeight;
    _needsMarquee = _textWidth > _containerWidth;
    _measured = true;
  });

  if (_needsMarquee) {
    final scrollDurationMs =
        ((_textWidth + widget.gapBetweenCopies) / widget.scrollSpeed * 1000)
            .round()
            .clamp(1500, 12000);

    _controller.duration = Duration(milliseconds: scrollDurationMs);

    Future.delayed(widget.pauseBeforeScroll ?? const Duration(milliseconds: 1500), () {
      if (mounted) _controller.repeat();
    });
  }
}
```

- `maxWidth: double.infinity` ensures we measure the **unconstrained** text width (the full length it would occupy if nothing clipped it).
- Scroll duration scales linearly with text width so longer names don't scroll absurdly fast, and short names don't crawl.
- Clamped to [1.5 s, 12 s] to stay within reasonable UX bounds.

---

*Audit completed — ready for implementation sign-off.*
