# Flutter Unused Parameter Audit — `lib/pages/dashboard.dart`

> **Audit date:** 2025-06-19  
> **Lint rule:** `unused_element_parameter`  
> **Severity:** warning (3 occurrences)  
> **Status:** DEBUG / PLAN MODE — no code written yet

---

## 1. Warning Summary

| # | Line | Parameter | Default value |
|---|------|-----------|---------------|
| 1 | 1092 | `pauseBeforeScroll` | `const Duration(milliseconds: 1500)` |
| 2 | 1093 | `gapBetweenCopies` | `40` |
| 3 | 1094 | `scrollSpeed` | `30` |

All three belong to the private `_HudMarqueeText` widget (line 1076).

---

## 2. Root Cause

The `_HudMarqueeText` widget declares three optional constructor parameters with defaults (lines 1080–1094):

```dart
class _HudMarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration pauseBeforeScroll;   // line 1081
  final double gapBetweenCopies;      // line 1084
  final double scrollSpeed;           // line 1087

  const _HudMarqueeText({
    required this.text,
    required this.style,
    this.pauseBeforeScroll = const Duration(milliseconds: 1500),  // line 1092
    this.gapBetweenCopies = 40,                                    // line 1093
    this.scrollSpeed = 30,                                        // line 1094
  });
```

The fields **are** referenced in `_HudMarqueeTextState` via `widget.pauseBeforeScroll`, `widget.gapBetweenCopies`, and `widget.scrollSpeed` (lines 1185, 1187, 1190, 1212). However, the Dart analyzer's `unused_element_parameter` lint for Dart SDK 3.7 does **not** trace through `widget.xxx` access in a separate `State<T>` class as "usage" of the constructor parameter on `T` — it considers the `this.xxx` constructor parameters unused on the widget class itself.

This is a known behavioral edge case in the lint: `this.xxx` initializer parameters on a `StatefulWidget` whose state accesses them only via the `widget` getter may trigger `unused_element_parameter`.

---

## 3. Fix Plan: Remove parameters, hardcode defaults

### 3.1 Why removal is safe

The **only** instantiation of `_HudMarqueeText` (line 995) passes **only** `text` and `style`:

```dart
_HudMarqueeText(
  text: title.toUpperCase(),
  style: const TextStyle(
    color: Colors.cyanAccent,
    fontSize: 15,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
  ),
)
```

All three parameters have always used their defaults. Hardcoding the defaults removes the parameters without any behavioral change.

### 3.2 Detailed changes

**Step 1 — Remove field declarations (lines 1080–1087):**

```dart
// DELETE:
  /// Idle time before the continuous scroll loop begins.
  final Duration pauseBeforeScroll;

  /// Horizontal gap between the two scrolling copies.
  final double gapBetweenCopies;

  /// Scroll speed in logical pixels per second.
  final double scrollSpeed;
```

**Step 2 — Remove constructor entries (lines 1092–1094):**

```dart
// BEFORE:
  const _HudMarqueeText({
    required this.text,
    required this.style,
    this.pauseBeforeScroll = const Duration(milliseconds: 1500),  // DELETE
    this.gapBetweenCopies = 40,                                    // DELETE
    this.scrollSpeed = 30,                                        // DELETE
  });

// AFTER:
  const _HudMarqueeText({
    required this.text,
    required this.style,
  });
```

**Step 3 — Replace `widget.xxx` with hardcoded defaults in `_HudMarqueeTextState`:**

| Line | Before | After |
|------|--------|-------|
| 1185 | `final totalWidth = _textWidth + widget.gapBetweenCopies;` | `final totalWidth = _textWidth + 40;` |
| 1187 | `((totalWidth / widget.scrollSpeed) * 1000).round().clamp(1500, 12000);` | `((totalWidth / 30) * 1000).round().clamp(1500, 12000);` |
| 1190 | `_startTimer = Timer(widget.pauseBeforeScroll, () {` | `_startTimer = Timer(const Duration(milliseconds: 1500), () {` |
| 1212 | `final totalWidth = _textWidth + widget.gapBetweenCopies;` | `final totalWidth = _textWidth + 40;` |

---

## 4. Total Change Set

| File | Area | Lines | Change |
|------|------|-------|--------|
| `dashboard.dart` | `_HudMarqueeText` fields | 1080–1087 | Remove 3 field declarations (+ 3 doc comments) |
| `dashboard.dart` | `_HudMarqueeText` constructor | 1092–1094 | Remove 3 parameter entries |
| `dashboard.dart` | `_HudMarqueeTextState._measureAndStart()` | 1185, 1187, 1190 | Replace `widget.gapBetweenCopies`→`40`, `widget.scrollSpeed`→`30`, `widget.pauseBeforeScroll`→`Duration(ms:1500)` |
| `dashboard.dart` | `_HudMarqueeTextState.build()` | 1212 | Replace `widget.gapBetweenCopies`→`40` |

**17 lines deleted, 4 lines inlined. Zero logic change — runtime behavior is byte-for-byte identical.**

---

## 5. Verification

```bash
flutter analyze lib/pages/dashboard.dart
```

Expected: 3 `unused_element_parameter` warnings cleared. No new warnings introduced.

Manual test: verify the HUD marquee text still scrolls with identical timing (1500ms pause, 30px/s speed, 40px gap between copies) on any dashboard alert.
