# Flutter Glassmorphism — Architectural Audit & Dark Mode Rescue Plan

> **Status:** DEBUG / PLAN MODE — no code written yet.
> **Problem:** Hardcoded `Colors.white` containers, `Colors.black`/`0xFF23251D` text, and light-gray DataTable styling create unreadable "Flashbang" UI in Dark Mode — opaque white boxes blindingly covering the cyber circuit background.

---

## 1. Problem Catalog

### 1.1 Hardcoded Color Categories

| Pattern | Files Affected | Dark-Mode Effect |
|---------|---------------|------------------|
| Container `color: Colors.white` + shadow | 14 files (all data tables, form cards, profile cards) | Opaque white "flashbang" covering the circuit |
| Text `color: Color(0xFF23251D)` / `Colors.black` / `Colors.black87` | 17 files (titles, labels, form fields) | Invisible or very-low-contrast text on dark surfaces |
| Text `color: Color(0xFF374151)` | 8 form files (field labels) | Low-contrast gray on dark |
| DataTable `headingRowColor: Colors.grey.shade50` + `border: Color(0xFFE5E7EB)` | ~10 data pages | Washed-out light-gray header rows, invisible borders |
| `AppTextField` borders `Color(0xFFBFC1B7)`, text `Color(0xFF23251D)` | 1 shared widget (used in login + forms) | Invisible text, borders blend into dark background |
| `AppSearchField` `Colors.grey.shade400` | 1 shared widget | Low contrast |
| `AppPagination` `Colors.grey.shade200/300/600` | 1 shared widget | Invisible elements |

### 1.2 Affected Files — By Role

#### Login (1 file)
| File | Issue |
|------|-------|
| `lib/widget/login_card.dart` | Glass container uses `Colors.white.withValues(alpha: 0.15)` — semi-white on light background looks fine, but the text (`0xFF23251D`), labels, and `AppTextField` borders are all hardcoded dark. The login background gradient is `slate-50 → slate-200` — login card on dark gradient with white-tinted glass still reads OK since the card is already semi-transparent. The real problem: **text colors never flip to white** and **`AppTextField` input text is invisible**. |

#### Data Tables (10 files)
| File | Container `Colors.white` | Title `Colors.black` | HeadingRow `grey.shade50` |
|------|-------------------------|----------------------|--------------------------|
| `lib/pages/user_page.dart` | L249 | L199 | L276 |
| `lib/pages/personel.dart` | L332 | L282 | L359 |
| `lib/pages/polda.dart` | L329 | L279 | L356 |
| `lib/pages/polres.dart` | L326 | L276 | L353 |
| `lib/pages/senjata.dart` | L314 | L265 | L343 |
| `lib/pages/satwa.dart` | L332 | L283 | L365 |
| `lib/pages/sarpras.dart` | L321 | L274 | (no headingRow for sarpras) |
| `lib/pages/amunisi.dart` | L294 | L247 | (explicit? check) |
| `lib/pages/inventaris.dart` | L112 | L70 | L139 |
| `lib/pages/master_kategori_senjata.dart` | L540 | L501 | (bg/fg greys) |

**Common DataTable pattern across all 10:**
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white,                                    // ← flashbang
    borderRadius: BorderRadius.circular(12),
    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), ...)],
  ),
  child: DataTable(
    headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),  // ← washed out
    headingTextStyle: TextStyle(..., color: Color(0xFF6B7280)),
    dataTextStyle: TextStyle(..., color: Color(0xFF374151)),
    border: TableBorder(
      horizontalInside: BorderSide(color: Color(0xFFE5E7EB), ...),  // ← invisible
    ),
  ),
)
```

#### Add / Edit Form Pages (10 files)
| File | Card / Container `Colors.white` |
|------|-------------------------------|
| `lib/pages/add_user.dart` | L73 |
| `lib/pages/add_personel_page.dart` | L73 |
| `lib/pages/add_polda.dart` | L73 |
| `lib/pages/add_polres.dart` | L73 |
| `lib/pages/add_senjata.dart` | L72 |
| `lib/pages/add_satwa.dart` | L73 |
| `lib/pages/add_sarpras.dart` | L66 |
| `lib/pages/add_amunisi.dart` | L66 |
| `lib/pages/add_inventaris_page.dart` | L70 |

**Common add-page pattern:**
```dart
Card(
  elevation: 0,
  color: Colors.white,                                       // ← flashbang
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: BorderSide(color: Colors.grey.shade200, width: 1.5), // ← too light in dark
  ),
  child: Padding(... child: FormTambahXxx(...)),
)
```

#### Profile / Settings (1 file)
| File | Container `Colors.white` | Text `Colors.black87` |
|------|-------------------------|----------------------|
| `lib/pages/pangaturan.dart` | L75, L127 | L113, L160, L101 |

#### Form Input Widgets (8 files)
| File | Hardcoded label `0xFF374151` | Hardcoded border `0xFFE5E7EB` | Hardcoded text `0xFF23251D`/`Colors.black87` |
|------|----------------------------|-----------------------------|-----------|
| `lib/widget/form_input_user.dart` | L66 | L36/40 | — |
| `lib/widget/form_input_personel.dart` | L364 | L338/342 | L585 |
| `lib/widget/form_input_polda.dart` | L175/190/205 | L132/136 | L219 |
| `lib/widget/form_input_polres.dart` | L211/241 | L168/172 | L257 |
| `lib/widget/form_input_senjata.dart` | L328 | L302/306 | L495 |
| `lib/widget/form_input_amunisi.dart` | L272 | L246/250 | L427 |
| `lib/widget/form_input_sarpras.dart` | L345 | L314/318 | L569 |
| `lib/widget/form_inputan_inventaris.dart` | L97/112/137/153 | L59/63 | L200 |
| `lib/widget/form_inputan_satwa.dart` | L427 | L396/400 | L650 |

#### Shared Widgets (3 files)
| File | Hardcoded colors |
|------|-----------------|
| `lib/widget/textfield.dart` (AppTextField) | Input text `0xFF23251D`, borders `0xFFBFC1B7`, hint `0xFF4D4F46` |
| `lib/widget/app_search_field.dart` | Hint/icon/border `Colors.grey.shade400` |
| `lib/widget/app_pagination.dart` | Border `grey.shade200`, text `0xFF6B7280`, dots `grey.shade300/600` |

---

## 2. Target Design: "Promax Glassmorphism"

### 2.1 Light Mode (unchanged aesthetic)
- Containers: solid `ColorScheme.surface` (white `#FFFFFF`)
- Shadows: `BoxShadow(color: Colors.black12, blurRadius: 10, offset: 0,4)`
- Borders: **none** (clean corporate)
- Text: `ColorScheme.onSurface` (near-black `#1E293B`), `ColorScheme.onSurfaceVariant`

This is already correct in many places (the ThemeData defines these). The only change needed: **stop hardcoding colors** and read from the theme.

### 2.2 Dark Mode (new "glass" aesthetic)
- Containers: `ColorScheme.surface.withValues(alpha: 0.75)` — semi-transparent dark surface (`#12142A` at 75% alpha) letting the cyber circuit show through
- Shadows: **none** (shadows on transparent surfaces create a muddy "dirty glass" look)
- Borders: `Border.all(color: Colors.white.withValues(alpha: 0.10), width: 1.0)` — thin edge glass reflection
- Text: `ColorScheme.onSurface` (light `#E2E8F0`), `ColorScheme.onSurfaceVariant` — already defined

This is what `AppHeader` already does correctly (lines 40–53 of `app_header.dart`) — it was updated in a prior theme-engine pass. The rest of the app wasn't.

### 2.3 The `GlassSurface` Widget (Reusable Strategy)

Rather than sprinkling `if (isDark)` checks across 40+ files, we create a **single reusable surface widget** that encapsulates the glassmorphism logic:

**File:** `lib/widget/glass_surface.dart` (NEW)

```dart
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

  final Widget child;
  final BorderRadiusGeometry? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final radius = borderRadius ?? BorderRadius.circular(12);

    return Container(
      width: width,
      height: height,
      constraints: constraints,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surface.withValues(alpha: 0.75)
            : scheme.surface,
        borderRadius: radius,
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.10), width: 1.0)
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );
  }
}
```

**Usage pattern — replaces every hardcoded white container:**

Before:
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), ...)],
  ),
  child: Column(...),
)
```

After:
```dart
GlassSurface(child: Column(...))
```

This is **zero-boilerplate per call site** — the widget reads brightness from context automatically.

---

## 3. Systematic Fix Plan

### 3.1 The `GlassSurface` Widget (NEW) → `lib/widget/glass_surface.dart`

Create with the exact spec above. Import it everywhere needed.

### 3.2 DataTable Theming (10 files)

**Three-pronged approach:**

**A. Container → replace with `GlassSurface`**
Remove the `Container(decoration: BoxDecoration(color: Colors.white, ...))` wrapper; wrap child content with `GlassSurface(borderRadius: BorderRadius.circular(12))`.

**B. DataTable color properties → read from theme via `Theme.of(context)`**

Before (hardcoded):
```dart
headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
dataTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF374151)),
border: const TableBorder(
  horizontalInside: BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
),
```

After (theme-aware — computed ONCE in `build` and stored in locals):
```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
final scheme = Theme.of(context).colorScheme;
...
headingRowColor: WidgetStateProperty.all(
  isDark ? scheme.surfaceContainerHighest : const Color(0xFFF9FAFB)
),
headingTextStyle: TextStyle(
  fontSize: 12, fontWeight: FontWeight.w700,
  color: scheme.onSurfaceVariant,
),
dataTextStyle: TextStyle(
  fontSize: 14, fontWeight: FontWeight.w400,
  color: scheme.onSurface,
),
border: TableBorder(
  horizontalInside: BorderSide(
    color: scheme.outlineVariant,
    width: 0.5,
  ),
),
```

Color mapping:
| Old hardcoded | New theme color |
|--------------|-----------------|
| `Colors.grey.shade50` (heading bg) | `scheme.surfaceContainerHighest` (def: `#F1F5F9` light / `#1A1E38` dark — already correct) |
| `Color(0xFF6B7280)` (heading text) | `scheme.onSurfaceVariant` |
| `Color(0xFF374151)` (data text) | `scheme.onSurface` |
| `Color(0xFFE5E7EB)` (border) | `scheme.outlineVariant` (def: `#E2E8F0` light / `#1E2238` dark) |

### 3.3 Page Titles

Before: `const Text(..., style: TextStyle(..., color: Colors.black))`
After: `Text(..., style: TextStyle(..., color: Theme.of(context).colorScheme.onSurface))`

This pattern repeats in every data page and form page. Since titles are always inside the `AppScaffold` (which already has a `BuildContext`), `Theme.of(context)` is available. However, many titles are declared as `const` — they must become non-const (runtime `color:` parameter).

### 3.4 Add/Edit Form Cards

Replace:
```dart
Card(
  elevation: 0,
  color: Colors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: BorderSide(color: Colors.grey.shade200, width: 1.5),
  ),
  child: Padding(...),
)
```

With:
```dart
GlassSurface(
  borderRadius: BorderRadius.circular(16),
  padding: const EdgeInsets.all(25),
  child: FormTambahXxx(...),
)
```

The `Card` widget is dropped entirely — `GlassSurface` provides the decoration.

### 3.5 Form Input Labels & Borders

Every form input widget has a `_buildLabel` helper returning `Text(label, style: const TextStyle(..., color: Color(0xFF374151)))`. Replace `Color(0xFF374151)` with `Theme.of(context).colorScheme.onSurface`.

Input decoration borders: `OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE5E7EB)))` → `BorderSide(color: Theme.of(context).colorScheme.outlineVariant)`.

**Critical:** The `AppTextField` widget used on the login page is the worst offender — its input text is `Color(0xFF23251D)` (hardcoded dark). Fix: read `Theme.of(context).colorScheme.onSurface` for the text style.

### 3.6 `AppTextField` Fix (`lib/widget/textfield.dart`)

```dart
// Before:
style: const TextStyle(color: Color(0xFF23251D)),
enabledBorder: ... BorderSide(color: const Color(0xFFBFC1B7)),

// After:
final scheme = Theme.of(context).colorScheme;
...
style: TextStyle(color: scheme.onSurface),
enabledBorder: ... BorderSide(color: scheme.outline),
```

### 3.7 `AppSearchField` Fix (`lib/widget/app_search_field.dart`)

`Colors.grey.shade400` → `Theme.of(context).colorScheme.onSurfaceVariant` for hint/icon/border.

### 3.8 `AppPagination` Fix (`lib/widget/app_pagination.dart`)

Border `Colors.grey.shade200` → `scheme.outlineVariant`. Text `Color(0xFF6B7280)` → `scheme.onSurfaceVariant`. Dot colors → `scheme.onSurfaceVariant` and `scheme.surface`.

### 3.9 Profile Cards (`lib/pages/pangaturan.dart`)

Replace `Container(decoration: BoxDecoration(color: Colors.white, ...))` with `GlassSurface(borderRadius: BorderRadius.circular(15), padding: const EdgeInsets.all(20))`. Replace `Colors.black87` text with `scheme.onSurface`.

### 3.10 Login Card (`lib/widget/login_card.dart`)

The login card is already semi-transparent (glass-like) but uses hardcoded white tints. Fixes:
- Card background: `Colors.white.withValues(alpha: 0.15)` → `Theme.of(context).colorScheme.surface.withValues(alpha: 0.15)` (dark surface at 15% opacity yields a dark translucent card)
- Card border: `Colors.white.withValues(alpha: 0.4)` → same dark-aware approach: use `scheme.outline.withValues(alpha: 0.4)`... Actually, the login card is special — it renders over the `AppBackground` gradient which changes with theme. The glass effect should be neutral: in light mode, white-tinted glass over light gradient looks correct. In dark mode, dark-tinted glass over dark gradient. Using `scheme.surface.withValues(alpha: 0.15)` accomplishes both automatically.
- Title text `Color(0xFF23251D)` → `scheme.onSurface`
- Label texts → `scheme.onSurface`
- `AppTextField` → fixed globally via its own theme-awareness (section 3.6)
- ElevatedButton foreground `Colors.black` → keep? Gold `0xFFF6B300` button with black text is readable in both modes. Keep.

---

## 4. Execution Strategy (File-by-File)

### Phase 1: Create the Utility
| File | Action |
|------|--------|
| `lib/widget/glass_surface.dart` | **CREATE** — the reusable `GlassSurface` widget |

### Phase 2: Fix Shared Widgets (cascading fixes — these affect all pages)
| File | Changes |
|------|---------|
| `lib/widget/textfield.dart` | Text style + borders → read from `Theme.of(context).colorScheme` |
| `lib/widget/app_search_field.dart` | Hint/icon/border → `scheme.onSurfaceVariant` |
| `lib/widget/app_pagination.dart` | Border/text/dots → `scheme` colors |

### Phase 3: Fix Form Inputs (8 files) — systematic `0xFF374151` → `scheme.onSurface` + `0xFFE5E7EB` → `scheme.outlineVariant`
| File |
|------|
| `lib/widget/form_input_user.dart` |
| `lib/widget/form_input_personel.dart` |
| `lib/widget/form_input_polda.dart` |
| `lib/widget/form_input_polres.dart` |
| `lib/widget/form_input_senjata.dart` |
| `lib/widget/form_input_amunisi.dart` |
| `lib/widget/form_input_sarpras.dart` |
| `lib/widget/form_inputan_inventaris.dart` |
| `lib/widget/form_inputan_satwa.dart` |

### Phase 4: Fix Add Pages (9 files) — replace `Card(color: Colors.white, ...)` with `GlassSurface`
| File |
|------|
| `lib/pages/add_user.dart` |
| `lib/pages/add_personel_page.dart` |
| `lib/pages/add_polda.dart` |
| `lib/pages/add_polres.dart` |
| `lib/pages/add_senjata.dart` |
| `lib/pages/add_satwa.dart` |
| `lib/pages/add_sarpras.dart` |
| `lib/pages/add_amunisi.dart` |
| `lib/pages/add_inventaris_page.dart` |

### Phase 5: Fix Data Table Pages (10 files) — `Colors.white` container → `GlassSurface` + DataTable theme colors
| File |
|------|
| `lib/pages/user_page.dart` |
| `lib/pages/personel.dart` |
| `lib/pages/polda.dart` |
| `lib/pages/polres.dart` |
| `lib/pages/senjata.dart` |
| `lib/pages/satwa.dart` |
| `lib/pages/sarpras.dart` |
| `lib/pages/amunisi.dart` |
| `lib/pages/inventaris.dart` |
| `lib/pages/master_kategori_senjata.dart` |

### Phase 6: Fix Profile & Login
| File | Changes |
|------|---------|
| `lib/pages/pangaturan.dart` | Info cards → `GlassSurface`, text → `scheme` |
| `lib/widget/login_card.dart` | Glass tint → `scheme.surface`, text → `scheme.onSurface` |

---

## 5. Color Mapping Reference Table

### 5.1 Hardcoded → Theme Mapping

| Old Hardcoded Value | Theme Replacement | Light Mode Resolves To | Dark Mode Resolves To |
|---------------------|-------------------|----------------------|----------------------|
| `Colors.white` (container bg) | `GlassSurface` (auto) | `#FFFFFF` | `#12142A` @ 75% alpha |
| `Colors.black` / `Color(0xFF23251D)` / `Colors.black87` (text) | `scheme.onSurface` | `#1E293B` (slate-800) | `#E2E8F0` (slate-200) |
| `Color(0xFF374151)` (labels) | `scheme.onSurface` or `onSurfaceVariant` | `#1E293B` / `#64748B` | `#E2E8F0` / `#94A3B8` |
| `Color(0xFF6B7280)` (heading text) | `scheme.onSurfaceVariant` | `#64748B` (slate-500) | `#94A3B8` (slate-400) |
| `Color(0xFFE5E7EB)` (borders) | `scheme.outlineVariant` | `#E2E8F0` (slate-200) | `#1E2238` |
| `Color(0xFFBFC1B7)` (AppTextField) | `scheme.outline` | `#CBD5E1` (slate-300) | `#2A2E4A` |
| `Colors.grey.shade50` (heading bg) | `scheme.surfaceContainerHighest` | `#F1F5F9` (slate-100) | `#1A1E38` |
| `Colors.grey.shade200` (pagination border) | `scheme.outlineVariant` | `#E2E8F0` | `#1E2238` |
| `Colors.grey.shade300/400/600` (pagination dots) | `scheme.onSurfaceVariant` | `#64748B` | `#94A3B8` |
| `Colors.black.withValues(alpha: 0.05)` (shadow) | `GlassSurface` (auto) | Applied | Not applied |
| `Colors.grey.shade200` (Card border) | `GlassSurface` (auto) | Not applied | Applied (thin white10) |

### 5.2 Theme ColorScheme — Reference Values

These are defined in `lib/theme/app_theme.dart`:

| Key | Light | Dark |
|-----|-------|------|
| `surface` | `#FFFFFF` | `#12142A` |
| `onSurface` | `#1E293B` (slate-800) | `#E2E8F0` (slate-200) |
| `onSurfaceVariant` | (computed) ≈ `#64748B` | (computed) ≈ `#94A3B8` |
| `outline` | `#CBD5E1` (slate-300) | `#2A2E4A` |
| `outlineVariant` | `#E2E8F0` (slate-200) | `#1E2238` |
| `surfaceContainerHighest` | `#F1F5F9` (slate-100) | `#1A1E38` |

---

## 6. Edge Cases & Risk Assessment

| Risk | Mitigation |
|------|-----------|
| `const` keyword prevents runtime theme access | Convert constrained widgets to non-const where they need `Theme.of(context)`. This is safe — Flutter rebuilds efficiently. |
| DataTable `headingRowColor` needs `WidgetStateProperty.all` | This is already the pattern; just change the color value. |
| `AppTextField` used in Login page where the background is a full-bled gradient (no `GlassSurface` parent) | The text color should be `scheme.onSurface` — dark on light gradient, light on dark gradient. Already correct with `Theme.of(context)`. |
| Some data pages use `Card` theme shape; switching to `GlassSurface` loses the `Card` elevation semantics | The `GlassSurface` boxShadow provides equivalent visual separation in light mode. In dark mode, the border provides edge definition. No function lost. |
| `popupMenuTheme` in `app_theme.dart` already defines `surfaceTintColor` — heading row dropdowns may double-theme | This is fine. The surfaceTintColor makes popups match the surface color. |
| Some pages have `Container(color: Colors.grey.shade100)` for non-table elements | These should also use `scheme.surfaceContainerHighest` instead of hardcoded grey.shade100. |

---

## 7. Files Summary

| Phase | Files | New | Modified |
|-------|-------|-----|----------|
| 1 — Utility | 1 | `glass_surface.dart` | — |
| 2 — Shared Widgets | 3 | — | `textfield.dart`, `app_search_field.dart`, `app_pagination.dart` |
| 3 — Form Inputs | 8 | — | all `form_input_*.dart` |
| 4 — Add Pages | 9 | — | all `add_*.dart` |
| 5 — Data Table Pages | 10 | — | all data page `*.dart` |
| 6 — Profile + Login | 2 | — | `pangaturan.dart`, `login_card.dart` |
| **Total** | **33** | **1 new** | **32 modified** |

---

## 8. Verification Checklist (for execution phase)

- [ ] `dart analyze` passes with zero errors.
- [ ] `GlassSurface` widget created and imported in all modified files.
- [ ] Light mode: all containers render as solid white with subtle shadow (no visual change from current).
- [ ] Dark mode: all containers render as semi-transparent dark surfaces with thin white10 border — the cyber circuit is visible through every panel.
- [ ] Dark mode: all text (titles, labels, table data, input text, search hints) is readable white/slate — no invisible black text remains.
- [ ] Dark mode: DataTable heading rows use `surfaceContainerHighest` (dark indigo `#1A1E38`) — distinct from the glass background.
- [ ] Dark mode: DataTable borders use `outlineVariant` (`#1E2238`) — visible but subtle.
- [ ] Login page: card is dark-tinted glass, text is light, AppTextField input is visible.
- [ ] Profile page (pangaturan): info cards are glass-surfaced, text readable.
- [ ] All add/edit form cards are glass-surfaced with readable labels.
- [ ] No `Colors.white` containers remain in dark mode (verify via visual inspection or grep audit).
- [ ] No hardcoded `Color(0xFF23251D)` / `Color(0xFF374151)` / `Color(0xFF6B7280)` remain in widget build methods.
