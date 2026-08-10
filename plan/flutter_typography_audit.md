# Flutter Typography Audit — Barlow / Barlow Semi Condensed Migration

**Scope:** Global font injection via `google_fonts` into the SINDOMON theme system.
**Target font:** Barlow Semi Condensed (primary) — tactical, police/military authority, high data density.
**Fallback chain:** `Barlow` (standard width) for headers where Semi Condensed feels too tight.

---

## 1. Dependency Audit

### 1.1 `pubspec.yaml`

```yaml
# line 34 — already present
google_fonts: ^6.3.0
```

**Verdict:** `google_fonts` is **already installed** at `^6.3.0`. No `pubspec.yaml` changes required. The package downloads font assets on first use and caches them in the app's asset bundle at build time (no runtime HTTP fetches — the fonts ship with the APK/EXE).

---

## 2. Current Typography State

### 2.1 `lib/theme/app_theme.dart` — `_build()` method

`ThemeData` is constructed with **no `textTheme` parameter**:

```dart
return ThemeData(
  useMaterial3: true,
  brightness: brightness,
  colorScheme: colorScheme,
  scaffoldBackgroundColor: Colors.transparent,
  // ... divider, popupMenu, tooltip themes
  // ❌ NO textTheme — falls back to Material 3 default (Roboto)
);
```

This means every `Text` widget in the app currently renders in Roboto, the Material 3 default. There is zero custom typography in the theme system.

### 2.2 `GoogleFonts` usage grep

```
lib/**/*.dart: GoogleFonts → NO MATCHES
```

The `google_fonts` package is declared but **never imported or called**. It's dead weight until we wire it in.

### 2.3 `TextTheme` usage grep

```
lib/**/*.dart: TextTheme | textTheme → NO MATCHES
```

No widget, no page, no form file references `Theme.of(context).textTheme`. Every single `TextStyle` in the app is either:
- A `const TextStyle(fontSize: …, fontWeight: …, color: …)` literal (most common — ~100 occurrences across widgets and pages)
- A themed `TextStyle(color: scheme.onSurface, fontSize: …, fontWeight: …)` (the newer, already-migrated widgets)
- A **completely unstyled** `Text("…")` that inherits `DefaultTextStyle` from the ancestor `Material`/`Theme`

**Architectural implication:** Because the app never reads from `ThemeData.textTheme`, injecting a global `textTheme` will **only affect unstyled `Text` widgets and `DefaultTextStyle` propagations** — all explicit `TextStyle(fontSize: ...)` literals override the theme anyway. This is actually *good*: we get Barlow on all unstyled text (labels, hints, dialogs, error messages) without breaking any custom-styled text.

---

## 3. Hardcoded `fontFamily` Scan

Six locations force a specific font family:

| # | File | Line | `fontFamily` | Context | Action |
|---|------|------|-------------|---------|--------|
| 1 | `lib/pages/amunisi.dart` | 390 | `"monospace"` | DataTable cell: kaliber/serial number display | **Flagged — see §3.1** |
| 2 | `lib/pages/master_kategori_senjata.dart` | 634 | `"monospace"` | DataTable cell: kaliber code display | **Flagged — see §3.1** |
| 3 | `lib/pages/sarpras.dart` | 425 | `"monospace"` | DataTable cell: serial/ID number display | **Flagged — see §3.1** |
| 4 | `lib/pages/satwa.dart` | 443 | `"monospace"` | DataTable cell: ID/tag number display | **Flagged — see §3.1** |
| 5 | `lib/pages/senjata.dart` | 390 | `"monospace"` | DataTable cell: nomor_seri display | **Flagged — see §3.1** |
| 6 | `lib/widget/cyber_circuit_painter.dart` | 376 | `"monospace"` | Micro-HUD labels (8px, terminal aesthetic) | **CRITICAL EXCEPTION — DO NOT TOUCH** |

### 3.1 The 5 data-table monospace cells (items 1–5)

All five follow the identical pattern — a `DataCell` containing a `Text` with a serial-number, kaliber-code, or ID-string value, styled with `fontFamily: "monospace"`. Example:

```dart
// amunisi.dart:386-392
Text(
  e["nomor_seri"]?.toString() ?? "-",
  style: const TextStyle(fontFamily: "monospace"),
),
```

**Design rationale for keeping monospace on these cells:**
- Serial numbers, kaliber codes (e.g., `"9mm"`, `"5.56×45mm"`), and inventory IDs have **fixed character widths** — monospace ensures alignment across rows.
- These are **data-readout values**, not prose. Using Barlow here would lose the "instrument panel" feel and the tabular alignment.

**Recommendation:** These 5 `fontFamily: "monospace"` overrides are **intentional and should remain**. They override the global Barlow theme for the specific purpose of code/number display. No action needed.

### 3.2 The cyber_circuit_painter micro-labels (item 6)

```dart
// cyber_circuit_painter.dart:375-381
final labelStyle = TextStyle(
  fontFamily: 'monospace',
  fontSize: 8.0,
  fontWeight: FontWeight.w500,
  letterSpacing: -0.5,
  height: 1.0,
  color: palette.labelColor.withValues(alpha: palette.labelOpacity),
);
```

**CRITICAL EXCEPTION.** This is a `TextPainter` instantiated in a `CustomPainter`'s cache phase, not a widget. Its `fontFamily: 'monospace'` is architecturally isolated from the widget tree's `DefaultTextStyle` — it will never inherit any theme-level `textTheme`. **Untouched. Zero risk.**

---

## 4. Injection Plan — `app_theme.dart`

### 4.1 Add the import

```dart
// At top of app_theme.dart, after flutter/material.dart
import 'package:google_fonts/google_fonts.dart';
```

### 4.2 Build the Barlow Semi Condensed `TextTheme`

Google Fonts provides two paths:

**Option A — `GoogleFonts.barlowSemiCondensedTextTheme()`**
Returns a complete `TextTheme` where every style uses `Barlow Semi Condensed`. This is the simplest approach and works for our use case since every unstyled text should be Barlow Semi Condensed.

**Option B — Merge with a base `TextTheme`**
`GoogleFonts.barlowSemiCondensedTextTheme( Theme.of(context).textTheme )` — merges Barlow into an existing TextTheme. Unnecessary here since we have no existing custom TextTheme to preserve.

**Recommendation: Option A**, called once in `_build()`:

```dart
final baseTextTheme = GoogleFonts.barlowSemiCondensedTextTheme();
```

### 4.3 Apply color inheritance

GoogleFonts' text themes use their own hardcoded colors (typically `Colors.black87` / `Colors.white`). We must **override** the color-sensitive styles to use our `ColorScheme`:

```dart
final textTheme = baseTextTheme.apply(
  bodyColor: colorScheme.onSurface,
  displayColor: colorScheme.onSurface,
  decorationColor: colorScheme.onSurfaceVariant,
);
```

Then inject into `ThemeData`:

```dart
return ThemeData(
  useMaterial3: true,
  brightness: brightness,
  colorScheme: colorScheme,
  textTheme: textTheme,          // ← NEW
  scaffoldBackgroundColor: Colors.transparent,
  // ... rest unchanged
);
```

### 4.4 Complete `_build()` diff

```dart
import 'package:google_fonts/google_fonts.dart';  // NEW import

// Inside _build():
static ThemeData _build({
  required Brightness brightness,
  required ColorScheme colorScheme,
  required Color dividerColor,
}) {
  // ── Barlow Semi Condensed typography ─────────────────────────────────
  final textTheme = GoogleFonts.barlowSemiCondensedTextTheme().apply(
    bodyColor: colorScheme.onSurface,
    displayColor: colorScheme.onSurface,
    decorationColor: colorScheme.onSurfaceVariant,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    textTheme: textTheme,  // ← injected
    scaffoldBackgroundColor: Colors.transparent,
    // ... dividerTheme, popupMenuTheme, tooltipTheme unchanged
  );
}
```

### 4.5 What this changes (impact analysis)

| Widget | Before | After | Risk |
|--------|--------|-------|------|
| `Text("label")` without explicit `style` | Roboto, theme default color | Barlow Semi Condensed, `onSurface` color | ✅ Safe — unstyled text adopts the new font |
| `Text("label", style: TextStyle(fontSize: 14, color: scheme.onSurface))` | Roboto, explicit color + size | **Barlow Semi Condensed**, same color + size | ✅ Safe — explicit `TextStyle` inherits `fontFamily` from `DefaultTextStyle` merge (M3 behavior); explicit `color`/`fontSize` overrides take priority |
| `const Text("label", style: TextStyle(fontSize: 14))` | Roboto, 14px | **Barlow Semi Condensed**, 14px | ✅ Safe — `const` TextStyle has no `fontFamily`, so it inherits from the theme |
| `Text("SINDOMON", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: scheme.onSurface))` | Roboto, explicit everything | **Barlow Semi Condensed**, same size/weight/color | ✅ Intended — title gets Barlow's authoritative geometry |
| DataTable heading cells (`headingTextStyle: TextStyle(...)`) | Explicit style, no fontFamily | **Barlow Semi Condensed** | ✅ Intended — headings get condensed authority |
| `TextPainter` in `cyber_circuit_painter.dart` | `fontFamily: 'monospace'` hardcoded | **Unchanged** — `TextPainter` does not inherit from widget `DefaultTextStyle` | ✅ Zero risk |
| 5 data-table cells with `fontFamily: "monospace"` | `fontFamily: "monospace"` explicit | **Unchanged** — explicit override wins | ✅ Zero risk |

**Key insight:** M3's `TextStyle` resolution chain is `explicit style → DefaultTextStyle → ThemeData.textTheme → Material 3 defaults`. An explicit `TextStyle(fontSize: 14, color: scheme.onSurface)` does NOT set `fontFamily`, so it inherits from the nearest `DefaultTextStyle` which ultimately resolves to `ThemeData.textTheme.bodyMedium?.fontFamily` — our Barlow Semi Condensed. This means **every single existing text widget gets Barlow automatically** without touching any page code.

---

## 5. Edge Cases & Exceptions Summary

### 5.1 Untouchable (by design)
- `cyber_circuit_painter.dart:376` — `fontFamily: 'monospace'` — HUD terminal aesthetic
- 5 data-table serial-number cells — `fontFamily: "monospace"` — tabular code alignment

### 5.2 Potential visual regressions to check manually

| Concern | Severity | Mitigation |
|---------|----------|-----------|
| Semi Condensed is ~5-8% narrower than Roboto — existing `SizedBox`/`Container` widths may need minor adjustment if text was hitting width limits | Low | Most data tables use `Expanded`/`Flexible`; only hardcoded-width labels might clip |
| `fontWeight: FontWeight.w800` on "SINDOMON" title — Barlow Semi Condensed ExtraBold may feel heavier than Roboto ExtraBold | Low | Barlow's design is more geometric; the tactical look is intentional |
| Sidebar menu items (13px, FontWeight.w500/w600) — condensed font at this size may feel slightly smaller | Low | Can be verified visually; tweak to 13.5px or bump weight if needed |
| Indonesian text rendering — Barlow has full Latin-1 + Latin Extended-A coverage; all characters used in Indonesian (a-z, no diacritics) are supported | None | Barlow fully covers Indonesian orthography |

### 5.3 What does NOT need changing
- **Zero page/widget files need editing** — the global `textTheme` injection inherits downward
- **Zero form input files** — their explicit `TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onSurface)` picks up Barlow from the cascade without code changes
- **The 5 monospace cells** — untouched
- **The circuit painter** — untouched

---

## 6. Execution Checklist

When moving to CODE/EXECUTE mode:

1. [ ] **Add** `import 'package:google_fonts/google_fonts.dart';` to `lib/theme/app_theme.dart`
2. [ ] **Build** `textTheme` in `_build()` using `GoogleFonts.barlowSemiCondensedTextTheme().apply(bodyColor: ..., displayColor: ..., decorationColor: ...)`
3. [ ] **Inject** `textTheme: textTheme` into the `ThemeData(...)` constructor
4. [ ] **Run** `flutter pub get` (should be no-op since google_fonts is already in pubspec)
5. [ ] **Run** `flutter analyze` — confirm zero new warnings
6. [ ] **Visual QA:** Toggle light/dark themes — verify all text renders in Barlow Semi Condensed, monospace cells are unchanged, circuit labels still monospace, no clipping/overflow

---

## 7. File Manifest

| File | Action | Lines Changed |
|------|--------|:------------:|
| `lib/theme/app_theme.dart` | **EDIT** — add import + textTheme injection | ~6 lines |
| All other files | **NONE** — font inherits via theme cascade | 0 |

**Total blast radius: 1 file, ~6 lines.** This is the minimum viable font migration.
