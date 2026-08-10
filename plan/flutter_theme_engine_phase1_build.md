# Phase 1 Build Summary — Theme Engine Foundation

**Date:** 2025-07-14
**Mode:** CODE/EXECUTE — Phase 1 of the theme engine injection (per `plan/flutter_theme_engine_audit.md`)
**Goal:** Global Light/Dark Mode foundation: code-generated background (replacing static wallpapers) + theme token layer ready for the J.A.R.V.I.S Cyberpunk (dark) / Clean Corporate (light) aesthetics.

---

## 1. What Was Delivered

| # | Action | File | Purpose |
|---|--------|------|---------|
| 1 | CREATE | `lib/theme/app_theme.dart` | `ThemeData` for light + dark (global `MaterialApp` themes) |
| 2 | CREATE | `lib/theme/theme_controller.dart` | Global `ValueNotifier<ThemeMode>` + `SharedPreferences` persistence |
| 3 | CREATE | `lib/theme/sidebar_colors.dart` | Theme-aware color tokens for the sidebar |
| 4 | CREATE | `lib/widget/cyber_grid_painter.dart` | `CustomPainter` drawing the subtle HUD grid (dark mode) |
| 5 | OVERWRITE | `lib/widget/background.dart` | Theme-aware, code-generated background — `imagePath` removed |
| 6 | FIX | `lib/pages/login_page.dart` | Drop `imagePath` argument (compile fix) |
| 7 | FIX | `lib/widget/app_scaffold.dart` | Remove `imagePath` field/param/call-site (compile fix) |

---

## 2. File-by-File Detail

### 2.1 `lib/theme/app_theme.dart`

`abstract final class AppThemeData` — static-only holder (Dart 3).

**Brand tokens:**
- `brandIndigo = Color(0xFF1E1B4B)`
- `brandGold = Color(0xFFF6B300)`
- `jarvisCyan = Color(0xFF00E5FF)`

**`AppThemeData.light` — "Clean Corporate":**
- M3 `ColorScheme.light`: primary = indigo, secondary = gold, surface = white, onSurface = slate-800.
- `scaffoldBackgroundColor: Colors.transparent` ← critical so `AppBackground` shows through.

**`AppThemeData.dark` — "J.A.R.V.I.S Cyberpunk":**
- M3 `ColorScheme.dark`: primary = cyan `0xFF00E5FF`, secondary = gold, surface = void indigo `0xFF12142A`.
- `scaffoldBackgroundColor: Colors.transparent`.

**Shared `_build()`** configures: `dividerTheme` (subtle black/white @ 8%), `popupMenuTheme` (surface-colored, 12px radius), `tooltipTheme` (dark slate tooltips).

**Design decision:** No state-management package added — zero new `pubspec.yaml` dependencies.

### 2.2 `lib/theme/theme_controller.dart`

```dart
const String kThemeModeKey = "theme_mode";

class ThemeController {
  ThemeController() : themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

  final ValueNotifier<ThemeMode> themeNotifier;

  Future<void> initTheme() async;   // loads "theme_mode" from SharedPreferences
  Future<void> toggleTheme() async; // flips light↔dark + persists (setString)
  void dispose();                    // releases the notifier
}
```

- **`initTheme()`** parses the saved string via `ThemeMode.values.asNameMap()`; silently ignores unknown/missing values.
- **`toggleTheme()`** sets `themeNotifier.value` first (UI updates instantly), then persists. Values stored: `"light"` | `"dark"`.
- Key `"theme_mode"` does not collide with any of the 6 existing session keys (`token`, `username_login`, `roleid_login`, `polda_login`, `uuid_login`, `expired_login`).
- **Not yet consumed** — wiring into `main.dart` is the next step.

### 2.3 `lib/theme/sidebar_colors.dart`

```dart
class SidebarColors {
  final Color background, textPrimary, textSecondary, iconColor,
             selectedBg, selectedText, hoverColor, shadowColor;

  factory SidebarColors.fromBrightness(Brightness brightness) { ... }
}
```

| Token | Dark (Void) | Light (Crisp) |
|-------|-------------|---------------|
| background | `0xFF0F0B2E` deep void indigo | `Colors.white` |
| textPrimary | `Colors.white` | `0xFF1E293B` slate-800 |
| textSecondary | `Colors.white54` | `0xFF64748B` slate-500 |
| iconColor | `Colors.white70` | `0xFF475569` slate-600 |
| selectedBg | `0xFFF6B300` gold | `0xFF1E1B4B` indigo |
| selectedText | `0xFF0F0B2E` | `Colors.white` |
| hoverColor | `Colors.white10` | `Color(0x0A000000)` black @ 4% |
| shadowColor | `Colors.black38` | `Colors.black12` |

**Not yet consumed** — `app_sidebar.dart` still uses hardcoded colors (next step).

### 2.4 `lib/widget/cyber_grid_painter.dart`

`CyberGridPainter extends CustomPainter`:
- **Square grid**, 48px spacing (default), cyan `0xFF00E5FF`.
- Minor lines at `alpha 0.05`, every 4th (major) line at `alpha 0.10`, strokeWidth 1.0/1.2 — subtle tactical-readout effect.
- Uses `Color.withValues(alpha:)` (Flutter ≥ 3.27 — consistent with existing codebase usage).
- Pure `Canvas.drawLine` loops — no shaders, no `saveLayer`, no `Path` allocation per frame.
- `shouldRepaint` compares all 4 fields (`spacing`, `color`, `minorOpacity`, `majorOpacity`) — repaints only on real changes.

### 2.5 `lib/widget/background.dart` (overwritten)

`AppBackground` — **`imagePath` removed entirely; constructor is now `const AppBackground({super.key, required this.child})`.**

```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
return Container(
  decoration: BoxDecoration(gradient: isDark ? _darkGradient : _lightGradient),
  child: isDark
      ? CustomPaint(painter: const CyberGridPainter(), child: child)
      : child,
);
```

| Mode | Gradient | Layers |
|------|----------|--------|
| Dark | `RadialGradient` top-left, radius 1.6: `0xFF1B1240` (void purple) → `0xFF0F0B2E` (indigo) → `0xFF070A1F` (near-black navy) | gradient → `CustomPaint` grid → child |
| Light | `LinearGradient` top→bottom: `0xFFF8FAFC` (slate-50) → `0xFFE2E8F0` (slate-200) | gradient → child (clean, no grid) |

- Reacts automatically to the global `ThemeMode` — zero wiring at call sites.
- **~2.7 MB of image assets now unused** (`mabes-wp.png` 1.35 MB + `wp-putih-mabes.png` 1.4 MB) — cleanup pending.

---

## 3. Compile Fixes (callers of the old API)

| File | Change |
|------|--------|
| `lib/pages/login_page.dart` | Removed `imagePath: 'assets/images/mabes-wp.png'` from `AppBackground(...)` |
| `lib/widget/app_scaffold.dart` | Removed the `imagePath` field, the constructor default `'assets/images/wp-putih-mabes.png'`, and the call-site argument |

No other file referenced `AppBackground` or `imagePath` (verified by grep).

---

## 4. Data Flow (target state after wiring)

```
main.dart (StatefulWidget — NEXT STEP)
 └─ ThemeController
     ├─ initTheme() ← SharedPreferences "theme_mode"
     └─ themeNotifier: ValueNotifier<ThemeMode>
          └─ ValueListenableBuilder<ThemeMode>
               └─ MaterialApp(
                    theme: AppThemeData.light,
                    darkTheme: AppThemeData.dark,
                    themeMode: notifier.value,
                    home: LoginPage,
                  )
                     │ rebuild on notifier change
                     ▼
AppBackground ──reads brightness──▶ gradient + CyberGridPainter (dark) / gradient (light)
AppSidebar ────reads brightness──▶ SidebarColors.fromBrightness()  [NEXT STEP]
Sidebar toggle ──calls──▶ themeController.toggleTheme()
```

---

## 5. Design Decisions & Rationale

1. **`ValueNotifier<ThemeMode>` over Provider/Riverpod/Bloc** — the app has zero state-management infrastructure; a single boolean toggle doesn't justify a new dependency. Pure SDK, testable, minimal boilerplate.
2. **Transparent `scaffoldBackgroundColor` in BOTH themes** — required so the `AppBackground` gradient/grid is actually visible behind every `Scaffold`.
3. **Background reads brightness itself** — `Theme.of(context).brightness` makes the background (and later sidebar) reactive with zero explicit plumbing; the root rebuild cascades automatically.
4. **Grid painted behind content, not over it** — `CustomPaint` wraps `child`, so scrolling content never triggers grid repaints (background layer only repaints on theme toggle).
5. **Dark primary = cyan, secondary stays gold `0xFFF6B300`** — preserves the app's existing amber accent identity while introducing the J.A.R.V.I.S glow; existing `Colors.amber` usages in pages stay visually coherent.
6. **`Colors.transparent` + `withValues(alpha:)`** — matched to the codebase's Flutter version (≥ 3.27, proven by existing usage in `app_sidebar.dart`).

---

## 6. Verification Status

- ⚠️ **`flutter analyze` NOT run** — the `flutter`/`dart` SDK is not installed in this environment (`command -v flutter` → not found). Run it on your machine before committing.
- ✅ Manual verification performed:
  - Grep: zero dangling `imagePath` / `mabes-wp` / `wp-putih` references outside doc comments.
  - All 7 files re-read end-to-end: balanced syntax, correct imports (`material.dart`, `shared_preferences`, `cyber_grid_painter.dart`), const-correct `ColorScheme` constructors.

---

## 7. Not Yet Done (Next Steps — Phases 2+)

| Priority | Task | Files |
|----------|------|-------|
| P0 | Wire `ThemeController` into the root: `MyApp` → `StatefulWidget`, `ValueListenableBuilder<ThemeMode>`, `theme:`/`darkTheme:`/`themeMode:` | `lib/main.dart` |
| P0 | Make sidebar theme-reactive: replace ~15 hardcoded colors with `SidebarColors.fromBrightness(...)` + add the theme toggle button (bottom of sidebar, above the spacer) | `lib/widget/app_sidebar.dart` |
| P1 | Theme-aware header + footer (white card → dark surface, text colors) | `lib/widget/app_header.dart`, `lib/widget/app_footer.dart` |
| P1 | Delete unused wallpapers + update asset manifest (~2.7 MB savings) | `assets/images/mabes-wp.png`, `assets/images/wp-putih-mabes.png`, `pubspec.yaml` |
| P2 | Migrate page-level hardcoded colors to `Theme.of(context).colorScheme` (largest surface; amber/gold, status colors stay but surfaces/text become tokenized) | `lib/pages/*.dart` (~15 pages) |
