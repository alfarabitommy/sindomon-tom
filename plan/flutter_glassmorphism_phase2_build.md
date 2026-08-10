# Phase 2 Build Report — Glassmorphism Injection (Data Table Pages + Profile)

> **Status:** COMPLETED — all 11 target files patched, verified with `dart analyze` (0 errors).
> Phase 1 delivered `GlassSurface` + 4 shared widgets; Phase 2 replaces the hardcoded white panels and dark text in the data pages and profile page.

---

## 1. Files Successfully Patched (11/11)

| # | File | Import added | White Container → `GlassSurface` | Title → `scheme.onSurface` | DataTable theme colors | Bonus fixes |
|---|------|:---:|:---:|:---:|:---:|---|
| 1 | `lib/pages/user_page.dart` | ✅ | ✅ | ✅ | ✅ | — |
| 2 | `lib/pages/personel.dart` | ✅ | ✅ | ✅ | ✅ | error text + empty state |
| 3 | `lib/pages/polda.dart` | ✅ | ✅ | ✅ | ✅ | error text + empty state |
| 4 | `lib/pages/polres.dart` | ✅ | ✅ | ✅ | ✅ | error text + empty state |
| 5 | `lib/pages/senjata.dart` | ✅ | ✅ | ✅ | ✅ | — |
| 6 | `lib/pages/satwa.dart` | ✅ | ✅ | ✅ | ✅ | — |
| 7 | `lib/pages/sarpras.dart` | ✅ | ✅ | ✅ | ✅ | — |
| 8 | `lib/pages/amunisi.dart` | ✅ | ✅ | ✅ | ✅ | — |
| 9 | `lib/pages/inventaris.dart` | ✅ | ✅ | ✅ | ✅ | — |
| 10 | `lib/pages/master_kategori_senjata.dart` | ✅ | ✅ | ✅ | ✅ | `_buildErrorState` text |
| 11 | `lib/pages/pangaturan.dart` (Profile) | ✅ | ✅ (2 cards: info + binding) | ✅ | — | card labels → `onSurfaceVariant` |

## 2. Standard Applied Per Data Page

Every page now extracts at the top of `build`:
```dart
final scheme = Theme.of(context).colorScheme;
final isDark = Theme.of(context).brightness == Brightness.dark;
```

**Table wrapper** — every `Container(decoration: BoxDecoration(color: Colors.white, ...))` replaced by:
```dart
GlassSurface(
  borderRadius: BorderRadius.circular(12),
  child: Column(...),
)
```

**DataTable colors** — the uniform replacement:
| Property | Before | After |
|---|---|---|
| `headingRowColor` | `WidgetStateProperty.all(Colors.grey.shade50)` | `WidgetStateProperty.all(isDark ? scheme.surfaceContainerHighest : const Color(0xFFF9FAFB))` |
| `headingTextStyle` | `const TextStyle(..., color: Color(0xFF6B7280))` | `TextStyle(..., color: scheme.onSurfaceVariant)` |
| `dataTextStyle` | `const TextStyle(..., color: Color(0xFF374151))` | `TextStyle(..., color: scheme.onSurface)` |
| `border.horizontalInside` | `const BorderSide(color: Color(0xFFE5E7EB))` | `BorderSide(color: scheme.outlineVariant)` |

**Titles** — `const Text(..., color: Colors.black)` → `Text(..., color: scheme.onSurface)` with `const` removed.

## 3. Bonus Fixes (same bug class, same files)

- **personel / polda / polres**: error-state text `Colors.black87` → `scheme.onSurface`; empty-state text `Colors.black54` → `scheme.onSurfaceVariant` (const subtree converted).
- **master_kategori_senjata**: `_buildErrorState()` text `Colors.black87` → `scheme.onSurface`.
- **pangaturan**: card labels `Colors.grey.shade600` → `scheme.onSurfaceVariant`; `Colors.black87` values → `scheme.onSurface`.

## 4. Verification

### 4.1 Hardcoded white wrappers — NONE REMAIN

`grep -n "color: Colors.white"` on all 11 files → **0 matches**.

### 4.2 Hardcoded table/text colors — NONE REMAIN in tables/titles

`grep -n "Color(0xFF6B7280)\|Color(0xFF374151)\|Color(0xFFE5E7EB)\|Colors.grey.shade50\|Colors.black87\|Colors.black54"` on all 11 files → only 4 matches remain, all inside `master_kategori_senjata.dart`'s **inline kategori form dialog** (labels `0xFF374151`, input decoration `0xFFE5E7EB` + `0xFFF9FAFB` fill) — these are form-input territory, explicitly deferred to **Phase 3**.

### 4.3 `dart analyze` — 0 errors, no new warnings

Remaining findings are pre-existing `unnecessary_cast` info/warnings in untouched API-parsing code (e.g. `user_page.dart:65`, `polda.dart:68`) — confirmed outside all edited regions.

### 4.4 `GlassSurface` usage confirmed in every file

`grep -c "GlassSurface"` → 1 per data page, 2 in `pangaturan.dart`.

## 5. Left for Later Phases (noted, not part of Phase 2)

- **Phase 3**: 8 form input widgets (`form_input_*.dart`) — labels `0xFF374151`, borders `0xFFE5E7EB`, dropdown text `Colors.black87`.
- **Phase 3b**: inline form dialogs, incl. `master_kategori_senjata.dart` `_dialogInputDecoration` + `_showKategoriForm` labels (4 remaining hardcoded matches above).
- **Phase 4**: 9 add/edit pages — `Card(color: Colors.white)` → `GlassSurface`.
- `dashboard.dart` command-center overlays — intentionally excluded (HUD style over map).
