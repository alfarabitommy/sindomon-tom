# Phase 2 Build Summary — Theme Engine Wiring (End-to-End)

**Date:** 2025-07-14
**Mode:** CODE/EXECUTE — Phase 2 of the theme engine injection (consuming the Phase 1 foundation: `app_theme.dart`, `theme_controller.dart`, `sidebar_colors.dart`, `cyber_grid_painter.dart`, `background.dart`)
**Goal:** Wire the global Light/Dark toggle through the entire app — root → scaffold → sidebar → header/footer — with zero page-level edits.

---

## 1. What Was Delivered

| # | Action | File | Purpose |
|---|--------|------|---------|
| 1 | OVERWRITE | `lib/main.dart` | `StatefulWidget` root + `ThemeController` + `ValueListenableBuilder<ThemeMode>` |
| 2 | CREATE | `lib/theme/theme_scope.dart` | `InheritedWidget` exposing the controller ("look it up" mechanism) |
| 3 | OVERWRITE | `lib/widget/app_sidebar.dart` | Theme-reactive colors + theme toggle button |
| 4 | PATCH | `lib/widget/app_scaffold.dart` | Pass `ThemeScope.of(context)` to `AppSidebar` (2 small edits) |
| 5 | OVERWRITE | `lib/widget/app_header.dart` | Brightness-aware surface/text colors |
| 6 | OVERWRITE | `lib/widget/app_footer.dart` | Brightness-aware text color |

**Key outcome:** `AppScaffold`, `AppHeader`, `AppFooter`, and all ~15 pages needed **zero constructor changes** — grep-verified that these widgets are constructed only inside `app_scaffold.dart`.

---

## 2. File-by-File Detail

### 2.1 `lib/main.dart` (overwritten)

```dart
class MyApp extends StatefulWidget { ... }            // was StatelessWidget

class _MyAppState extends State<MyApp> {
  final ThemeController _themeController = ThemeController();

  @override
  void initState() {
    super.initState();
    _themeController.initTheme();   // async load of "theme_mode" from prefs
  }

  @override
  void dispose() {
    _themeController.dispose();     // release the ValueNotifier
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: _themeController,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: _themeController.themeNotifier,
        builder: (context, themeMode, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: "SINDOMON",
            theme: AppThemeData.light,
            darkTheme: AppThemeData.dark,
            themeMode: themeMode,
            home: const LoginPage(),
          );
        },
      ),
    );
  }
}
```

- `initTheme()` is intentionally not awaited — when the future resolves, the notifier fires and the `ValueListenableBuilder` swaps the theme automatically (no flicker window, no splash gate).
- `ThemeScope` sits **above** `MaterialApp`, so every route/popup below it can look up the controller.

### 2.2 `lib/theme/theme_scope.dart` (NEW)

```dart
class ThemeScope extends InheritedWidget {
  const ThemeScope({super.key, required this.controller, required super.child});
  final ThemeController controller;

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope not found above this context');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(ThemeScope oldWidget) =>
      controller != oldWidget.controller;
}
```

**Why this instead of prop drilling?** The mission hinted "main → routes → scaffold" but that would require adding a constructor parameter to all 15+ pages (personel, senjata, polda, polres, satwa, sarpras, amunisi, user_page, inventaris, master_kategori_senjata, pangaturan, dashboard, ...). The mission also allowed "look it up". This 30-line InheritedWidget achieves the same dependency injection with pure Flutter SDK — no provider package, no page edits, and an assert that fails loudly if the scope is missing.

### 2.3 `lib/widget/app_sidebar.dart` (overwritten)

**Constructor change:**
```dart
const AppSidebar({
  super.key,
  required this.currentRoute,
  required this.themeController,   // NEW
});
```

**Build-time extraction:**
```dart
final brightness = Theme.of(context).brightness;
final isDark = brightness == Brightness.dark;
final colors = SidebarColors.fromBrightness(brightness);
```

**Color token mapping applied:**

| Old hardcoded | New token |
|---------------|-----------|
| `Color(0xff1E1B4B).withValues(alpha: 0.9)` (bg) | `colors.background` |
| `Colors.black26` (shadow) | `colors.shadowColor` |
| `Colors.white70` (hamburger/menu icons) | `colors.iconColor` |
| `Colors.white` (title, group labels) | `colors.textPrimary` |
| `Colors.white.withValues(alpha: 0.6)` (subtitle) | `colors.textSecondary` |
| `Colors.amber` (selected bg, group chevron) | `colors.selectedBg` |
| `Colors.black` (selected text/arrow) | `colors.selectedText` |
| `Colors.white10` (hovers) | `colors.hoverColor` |
| `Colors.white.withValues(alpha: 0.04)` (expanded group bg) | `colors.hoverColor` |

**Theme toggle button** — injected in the `Column` **right above the bottom `SizedBox(height: 20)`**:

```dart
Divider(color: colors.hoverColor, height: 1, indent: 20, endIndent: 20),
const SizedBox(height: 4),
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  child: IconButton(
    onPressed: () => widget.themeController.toggleTheme(),
    tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
    icon: AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) =>
          RotationTransition(turns: animation, child: child),
      child: Icon(
        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        key: ValueKey(isDark),
        color: colors.iconColor,
      ),
    ),
    style: IconButton.styleFrom(hoverColor: colors.hoverColor),
  ),
),
```

- Works in both rail states (80px collapsed / 240px expanded — icon-only fits the rail).
- Rebuild on toggle is automatic: the notifier → `MaterialApp` rebuild → new `Theme` → every `Theme.of(context)` consumer (sidebar included) rebuilds.
- All existing structure preserved verbatim: hamburger Offstage strategy, group Strategy-B (dual Offstage rendering), width/text animations, `HudLoadingSpinner`, `_resolveMenu()`.

### 2.4 `lib/widget/app_scaffold.dart` (patched — 2 edits)

```dart
import '../theme/theme_scope.dart';          // NEW import

// ...
AppSidebar(
  currentRoute: widget.currentRoute,
  themeController: ThemeScope.of(context),   // NEW — lookup, no prop drilling
),
```

`AppScaffold`'s public constructor is **unchanged** — pages keep working untouched.

### 2.5 `lib/widget/app_header.dart` (overwritten)

| Element | Before | After |
|---------|--------|-------|
| Card bg | `Colors.white` | `scheme.surface` (void `0xFF12142A` dark / white light) |
| Breadcrumb | `Colors.black87` | `scheme.onSurface` |
| Username | (inherited) | `scheme.onSurface` (explicit) |
| Role label | `Colors.grey.shade500` | `scheme.onSurfaceVariant` |
| Dropdown arrow | `Colors.grey` | `scheme.onSurfaceVariant` |
| Shadow | black @ 6% | black @ **30%** dark / 6% light |
| Avatar ring | `grey.shade300` | `grey.shade700` dark / `grey.shade300` light |
| Popup item icon/text | `Colors.black87` | `onSurface` |

Amber brand accents (home icon, avatar) intentionally kept — they read well on both surfaces.

### 2.6 `lib/widget/app_footer.dart` (overwritten)

```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
final color = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
// slate-400 (readable on void) / slate-500 (original)
```

---

## 3. Full Data Flow (now live)

```
main.dart (_MyAppState)
 ├─ ThemeController (ValueNotifier<ThemeMode>, persisted via "theme_mode")
 │    ├─ initTheme()      ← SharedPreferences read at startup
 │    └─ toggleTheme()    ← write on every flip
 ├─ ThemeScope (InheritedWidget — controller lookup for descendants)
 └─ ValueListenableBuilder<ThemeMode>
      └─ MaterialApp(theme: light, darkTheme: dark, themeMode: value)
           └─ LoginPage / ...pages → AppScaffold
                ├─ AppBackground → reads brightness → gradient (+cyber grid)
                ├─ AppSidebar → reads brightness → SidebarColors
                │    └─ [🌙/☀️ toggle button] → controller.toggleTheme()
                ├─ AppHeader → reads brightness → surface/onSurface
                └─ AppFooter → reads brightness → slate text
```

**Rebuild cascade on toggle:** `toggleTheme()` → notifier fires → `ValueListenableBuilder` rebuilds `MaterialApp` with the new `themeMode` → new `ThemeData` propagates via the `Theme` inherited widget → every widget that called `Theme.of(context)` rebuilds with the new `Brightness` → background, sidebar, header, footer all re-paint simultaneously.

---

## 4. Design Decisions

1. **`ThemeScope` (InheritedWidget) over prop drilling** — keeps ~15 page files untouched; pure SDK, no dependency; assert-guarded lookup.
2. **Sidebar recomputes tokens per sub-builder** (`_buildLeafItem`, `_buildGroupItem`, etc. each call `SidebarColors.fromBrightness`) — cheap object allocation, keeps the sub-methods self-contained; the main `build()` extraction covers the outer shell + toggle.
3. **Toggle works in collapsed rail** — icon-only fits the 80px width; the divider uses `indent: 20` to stay inside both widths.
4. **Header keeps amber accents** — the brand gold/amber is the shared identity token across both themes (also `secondary` in both `ColorScheme`s), so hardcoded `Colors.amber` in pages stays visually coherent.
5. **No `AnimationController` needed for the toggle** — `AnimatedSwitcher` handles the icon crossfade/rotation internally.

---

## 5. Verification Status

- ⚠️ **`flutter analyze` NOT run** — the `flutter`/`dart` SDK is not installed in this environment (`command -v flutter` → not found). Run it on your machine before committing.
- ✅ Manual verification performed:
  - `grep` of `app_sidebar.dart` for `Colors.(white|black|amber|grey)|Color(0x` → **zero matches** (only theme-agnostic `Colors.transparent` remains).
  - `grep` for `ThemeScope|ThemeController|AppThemeData` across `lib/` → full wiring chain confirmed (`main.dart:39-48` creates/wraps, `app_scaffold.dart:73` looks up, `app_sidebar.dart:28` consumes).
  - `grep` for `AppSidebar(|AppHeader(|AppFooter(` → constructed **only** in `app_scaffold.dart` (constructor-compat safe).
  - Re-read of all 6 changed files end-to-end.

---

## 6. Not Yet Done (Next Steps)

| Priority | Task | Files |
|----------|------|-------|
| P1 | Delete unused wallpapers + update asset manifest (~2.7 MB savings) — the images are now dead code since `AppBackground` renders gradients | `assets/images/mabes-wp.png`, `assets/images/wp-putih-mabes.png`, `pubspec.yaml` |
| P1 | Login page visual pass — the login card (`login_card.dart`) still has hardcoded light-only styling (white blur card, black text) and will need a dark variant | `lib/widget/login_card.dart` |
| P2 | Page-level token migration — ~15 pages still use hardcoded `Colors.white`/`Colors.black`/`Colors.grey`/`Color(0xFF...)` for tables, cards, status badges, form inputs. Cards/DataTables on `scheme.surface` will look right immediately; pure-text-on-background spots need attention | `lib/pages/*.dart` (~15 files) |
| P2 | Status badge pass — green/red/orange chips are fine on both themes, but their text/label colors should become theme-aware | `lib/pages/*.dart` |
