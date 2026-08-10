# Flutter Theme Engine — Architectural Audit

**Status:** DEBUG / PLAN MODE
**Date:** 2025-07-14
**Scope:** Replace static wallpaper with code-generated background + implement global Light/Dark toggle with J.A.R.V.I.S Cyberpunk (Dark) and Clean Corporate (Light) aesthetics.

---

## 1. Root — `lib/main.dart`

### 1.1 Current State

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "SINDOMON",
      home: const LoginPage(),
    );
  }
}
```

- **`MyApp` is a `StatelessWidget`.** There is no `theme`, no `darkTheme`, no `themeMode`, and no state management.
- The `MaterialApp` uses **all Flutter defaults**: light theme only, no dark mode override.
- The root widget is **never rebuilt** after startup — even if we injected a `ThemeMode`, there is no mechanism to notify `MaterialApp` of a change.
- No provider/riverpod/bloc is declared in `pubspec.yaml`. The only state-like dependency is `shared_preferences` (used manually, ad-hoc, on every page).

### 1.2 Architectural Gap

| Gap | Severity | Detail |
|-----|----------|--------|
| No `ThemeData` | Critical | Every widget uses hardcoded `Color(...)` literals. `Theme.of(context)` is never called. |
| No `themeMode` | Critical | `MaterialApp` defaults to `ThemeMode.system` internally, but without a `darkTheme` it silently falls back to the light `ThemeData` for dark system preference too. |
| No state holder | Critical | A `StatelessWidget` root cannot react to a theme toggle. |
| No persistence for theme | Medium | `SharedPreferences` is already in the project for auth, but has no theme-preference key. |

### 1.3 Recommended Strategy

**Inject a `ValueNotifier<ThemeMode>` at the root and convert `MyApp` to a `StatefulWidget`:**

```
MyApp (StatefulWidget)
 └─ ValueNotifier<ThemeMode> _themeNotifier
     ├─ reads initial value from SharedPreferences ("theme_mode")
     └─ wrapped in ValueListenableBuilder<ThemeMode>
          └─ MaterialApp(
               theme: AppThemeData.light,
               darkTheme: AppThemeData.dark,
               themeMode: _themeNotifier.value,
               ...
             )
```

**Why `ValueNotifier` and not Provider/Riverpod/Bloc?**
The project has **zero state management infrastructure**. Adding Provider would require a `pubspec.yaml` change, a `MultiProvider` wrapper, and `context.watch<>` boilerplate on every page — a disproportionate cost for a single boolean toggle. A `ValueNotifier<ThemeMode>` is:

- Pure Flutter SDK (zero new dependencies).
- Scoped: we expose it via a simple `InheritedNotifier` or pass it down to the sidebar where the toggle lives.
- Testable: a single `.value =` assignment triggers `ValueListenableBuilder` rebuild at the root and any subtree listening.

**Persistence plan:**

```dart
// Key: "theme_mode" → values: "light" | "dark" | "system"
// Read on startup in initState()
// Write on every toggle via SharedPreferences.setString()
```

**New file:** `lib/config/theme_config.dart` — holds `AppThemeData.light` and `AppThemeData.dark` as static `ThemeData` objects.

---

## 2. Background — `lib/widget/background.dart` + `app_scaffold.dart`

### 2.1 Current State

**`background.dart`** — 20 lines:

```dart
class AppBackground extends StatelessWidget {
  final Widget child;
  final String imagePath;

  const AppBackground({super.key, required this.child, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(imagePath, fit: BoxFit.cover),
        ),
        child,
      ],
    );
  }
}
```

- Pure `Image.asset` — two static PNGs: `mabes-wp.png` (dark, login) and `wp-putih-mabes.png` (light, authenticated pages).
- No animation, no reactivity, no gradient fallback.
- **Callers:** `LoginPage` passes `mabes-wp.png`; `AppScaffold` defaults to `wp-putih-mabes.png`.

**`app_scaffold.dart`** — the authenticated scaffold:

```dart
Scaffold(
  body: AppBackground(
    imagePath: widget.imagePath,  // defaults to 'assets/images/wp-putih-mabes.png'
    child: SafeArea(
      child: Row(
        children: [
          AppSidebar(currentRoute: widget.currentRoute),
          Expanded(child: ...),  // AppHeader + child + AppFooter
        ],
      ),
    ),
  ),
)
```

### 2.2 Architectural Gap

| Gap | Detail |
|-----|--------|
| Static binary choice | Two wallpapers, hardcoded per-caller. No dynamic swap based on theme. |
| No theme awareness | `AppBackground` is a `StatelessWidget` that receives no `BuildContext`-based brightness check. |
| Heavy assets | `wp-putih-mabes.png` is 1.4 MB, `mabes-wp.png` is 1.35 MB. Code-generated backgrounds render at 0 bytes of asset payload. |
| No performance tuning | `Image.asset` loads from disk on every cold start; no `const` constructor possible for the `Image` widget. |

### 2.3 Recommended Strategy — **Option A: Code-Generated Background**

**Replace `AppBackground` entirely** with a `StatefulWidget` that reads `Theme.of(context).brightness` and conditionally paints:

#### Dark Mode — "J.A.R.V.I.S Cyberpunk"

```
Container(
  decoration: BoxDecoration(
    gradient: RadialGradient(
      center: Alignment.topLeft,
      radius: 1.8,
      colors: [
        Color(0xFF0D0221),  // deep void purple
        Color(0xFF150A2E),  // dark indigo
        Color(0xFF0A0E27),  // near-black navy
      ],
    ),
  ),
  child: CustomPaint(
    painter: CyberGridPainter(),  // subtle hex/rect grid
    child: child,
  ),
)
```

**`CyberGridPainter` (CustomPainter):**
- Draws a low-opacity (`0.04–0.08`) hex or square grid.
- Uses `Path` + `Canvas.drawLine` for performance (no shader nodes, no saveLayer).
- Grid spacing: ~40–60 logical pixels.
- Optional: subtle `LinearGradient` scanline overlay for CRT effect (single `Container` overlay with `BoxDecoration` gradient at `0.03` opacity).
- **No `RepaintBoundary` needed** — the grid is static with respect to theme; only repainted on toggle.

#### Light Mode — "Clean Corporate"

```
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFF8FAFC),  // slate-50
        Color(0xFFE2E8F0),  // slate-200
      ],
    ),
  ),
  child: child,  // No grid — clean minimal look
)
```

**Proposed file structure:**

```
lib/widget/background.dart          ← rewrite (dynamic, theme-aware)
lib/widget/cyber_grid_painter.dart  ← new (CustomPainter for dark grid)
```

**Migration of callers:**

| Caller | Before | After |
|--------|--------|-------|
| `LoginPage` | `AppBackground(imagePath: 'assets/images/mabes-wp.png', ...)` | `AppBackground(child: ...)` — no `imagePath` param |
| `AppScaffold` | `AppBackground(imagePath: widget.imagePath, ...)` | `AppBackground(child: ...)` — drop the `imagePath` field |

**Backward compat:** Remove `imagePath` from `AppScaffold` constructor and from all 15+ pages that instantiate it. The field is never overridden from the default `wp-putih-mabes.png` in any page (confirmed via grep — no page passes a custom `imagePath` to `AppScaffold`).

The two PNG assets (`mabes-wp.png`, `wp-putih-mabes.png`) can be **removed from `pubspec.yaml` assets** and the files deleted — saving ~2.7 MB.

---

## 3. Sidebar — `lib/widget/app_sidebar.dart`

### 3.1 Current State

The sidebar is hardcoded for a dark indigo aesthetic:

| Element | Hardcoded Color | Should Become |
|---------|----------------|---------------|
| Background | `Color(0xff1E1B4B).withValues(alpha: 0.9)` | Theme-reactive |
| Logo text "SINDOMON" | `Colors.white` | Theme-reactive |
| Subtitle text | `Colors.white.withValues(alpha: 0.6)` | Theme-reactive |
| Menu icons | `Colors.white70` | Theme-reactive |
| Selected item bg | `Colors.amber` | `Theme.of(context).colorScheme.primary` |
| Selected item text | `Colors.black` | `Theme.of(context).colorScheme.onPrimary` |
| Hover color | `Colors.white10` | Theme-reactive |
| Toggle icon | `Colors.white70` | Theme-reactive |
| Shadow | `Colors.black26` | Adjust for light mode |

All 404 lines of `app_sidebar.dart` contain **zero calls to `Theme.of(context)`**.

### 3.2 Recommended Strategy

**Make the sidebar theme-reactive** by replacing every hardcoded color with references to a **`SidebarColors` helper** that resolves from `Theme.of(context).brightness`:

```dart
// lib/theme/sidebar_colors.dart
class SidebarColors {
  final Color background;
  final Color textPrimary;
  final Color textSecondary;
  final Color iconColor;
  final Color selectedBg;
  final Color selectedText;
  final Color hoverColor;
  final Color shadowColor;

  const SidebarColors({ ... });

  factory SidebarColors.fromBrightness(Brightness brightness) {
    return brightness == Brightness.dark
        ? SidebarColors(
            background: Color(0xFF0F0B2E),      // deep void indigo
            textPrimary: Colors.white,
            textSecondary: Colors.white54,
            iconColor: Colors.white70,
            selectedBg: Color(0xFFF6B300),       // amber
            selectedText: Color(0xFF0F0B2E),     // dark text on amber
            hoverColor: Colors.white10,
            shadowColor: Colors.black38,
          )
        : SidebarColors(
            background: Color(0xFFFFFFFF),       // crisp white
            textPrimary: Color(0xFF1E293B),      // slate-800
            textSecondary: Color(0xFF64748B),    // slate-500
            iconColor: Color(0xFF475569),        // slate-600
            selectedBg: Color(0xFF1E1B4B),       // indigo (inverse)
            selectedText: Colors.white,
            hoverColor: Color(0x0A000000),       // black 4%
            shadowColor: Colors.black12,
          );
  }
}
```

All color references in `app_sidebar.dart` are replaced with `_colors.background`, `_colors.iconColor`, etc., computed once in `build()`.

### 3.3 Theme Toggle Placement

**Location:** Bottom of the sidebar `Column`, **above the logout button area** (there is currently no logout button in the sidebar — logout is handled via the header profile dropdown).

Recommended injection:

```
Column(
  children: [
    hamburger toggle,
    logo,
    title,
    Expanded(menu ListView),
    // ── NEW: Theme Toggle ──
    Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: _ThemeToggleButton(themeNotifier: ...),
    ),
    SizedBox(height: 20),  // existing bottom spacer
  ],
)
```

**Toggle widget design:**

```dart
class _ThemeToggleButton extends StatelessWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      icon: AnimatedSwitcher(
        duration: Duration(milliseconds: 400),
        child: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          key: ValueKey(isDark),
          color: isDark ? Colors.amber : Color(0xFF1E1B4B),
        ),
      ),
      tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
      onPressed: () {
        final next = isDark ? ThemeMode.light : ThemeMode.dark;
        themeNotifier.value = next;
        SharedPreferences.getInstance().then(
          (prefs) => prefs.setString('theme_mode', next.name),
        );
      },
    );
  }
}
```

**Passing the notifier:** `AppSidebar` receives `ValueNotifier<ThemeMode>` via constructor parameter. `AppScaffold` receives it from above and forwards it.

---

## 4. Header & Footer — `app_header.dart` + `app_footer.dart`

### 4.1 Current State

**`AppHeader`:**
- Background: `Colors.white` (hardcoded)
- Text: `Colors.black87`, `Colors.grey.shade500`
- Amber accent: `Colors.amber`
- Shadow: `Colors.black.withValues(alpha: 0.06)`

**`AppFooter`:**
- Text: `Color(0xFF6B7280)` (slate-500, hardcoded)

Both are hardcoded for light mode only.

### 4.2 Recommended Strategy

Replace hardcoded colors with `Theme.of(context)` lookups:

| Element | Light Mode | Dark Mode |
|---------|-----------|-----------|
| Header background | `Colors.white` | `Color(0xFF1E1E2E)` (dark surface) |
| Header text | `Colors.black87` | `Colors.white` |
| Header shadow | `Colors.black.withValues(alpha: 0.06)` | `Colors.black.withValues(alpha: 0.30)` |
| Footer text | `Color(0xFF6B7280)` | `Color(0xFF94A3B8)` (slate-400) |

These can be defined in `AppThemeData` via `ColorScheme` or via a `ThemeExtensions` approach.

---

## 5. All Pages — `lib/pages/*.dart`

### 5.1 Audit Summary

Every page (personel, senjata, polda, polres, satwa, sarpras, amunisi, user_page, inventaris, master_kategori_senjata, pangaturan, report, login_page, dashboard) uses **hardcoded colors** extensively. Key patterns:

- `Colors.amber` — primary action color (~50+ occurrences)
- `Colors.white` / `Colors.white70` / `Colors.white38` — text on dark backgrounds
- `Colors.black` / `Colors.black87` — text on light backgrounds
- `Colors.green` / `Colors.red` / `Colors.orange` — status badges
- `Color(0xffF6B300)` — submit button color (gold/amber)
- `Colors.grey.shadeX` — various grays

This is the **largest migration surface**. However, the audit is scoped to **infrastructure** — the global theme toggle and background replacement. Page-level color migration can be phased:

- **Phase 1 (this audit):** Root theme engine + background replacement + sidebar adaptation + header/footer.
- **Phase 2 (follow-up):** Page-by-page color token migration using `Theme.of(context).colorScheme`.

### 5.2 Quick Wins for Phase 1

The `AppScaffold` change alone affects all authenticated pages, so the background and sidebar will look correct immediately. For Phase 1, pages with hardcoded `Colors.white` text on the current dark sidebar will render legibly in both modes because:
- Light mode: white text on light backgrounds may be low contrast, but the pages currently render on the `AppBackground` which will be light.
- The critical fix is ensuring `DataTable` rows, form inputs, and cards use theme-aware colors — but this is deferred to Phase 2 to keep the current PR focused.

---

## 6. Proposed File Manifest

| Action | File | Description |
|--------|------|-------------|
| **NEW** | `lib/theme/app_theme.dart` | `AppThemeData.light` and `AppThemeData.dark` static `ThemeData` factories |
| **NEW** | `lib/theme/theme_controller.dart` | `ThemeController` — `ValueNotifier<ThemeMode>` + `SharedPreferences` persistence helper |
| **NEW** | `lib/theme/sidebar_colors.dart` | `SidebarColors` factory from `Brightness` |
| **NEW** | `lib/widget/cyber_grid_painter.dart` | `CyberGridPainter extends CustomPainter` for dark mode grid |
| **REWRITE** | `lib/widget/background.dart` | Dynamic theme-aware background replacing `Image.asset` |
| **MODIFY** | `lib/main.dart` | `MyApp` → `StatefulWidget` + `ValueListenableBuilder<ThemeMode>` + `ThemeController` injection |
| **MODIFY** | `lib/widget/app_scaffold.dart` | Remove `imagePath` param; pass `themeNotifier` to `AppSidebar` |
| **MODIFY** | `lib/widget/app_sidebar.dart` | Replace hardcoded colors with `SidebarColors`; add theme toggle button |
| **MODIFY** | `lib/widget/app_header.dart` | Replace hardcoded colors with theme-aware lookups |
| **MODIFY** | `lib/widget/app_footer.dart` | Replace hardcoded text color with theme-aware lookup |
| **MODIFY** | `lib/pages/login_page.dart` | Remove `imagePath` from `AppBackground` call |
| **DELETE** | `assets/images/mabes-wp.png` | No longer needed (~1.35 MB freed) |
| **DELETE** | `assets/images/wp-putih-mabes.png` | No longer needed (~1.4 MB freed) |
| **MODIFY** | `pubspec.yaml` | Remove deleted image assets from assets list |

---

## 7. Data Flow Diagram

```
┌─────────────────────────────────────────────────┐
│                     main.dart                    │
│  MyApp (StatefulWidget)                         │
│   ├─ _themeNotifier: ValueNotifier<ThemeMode>   │
│   ├─ initState() → SharedPreferences("theme")   │
│   └─ build() → ValueListenableBuilder           │
│        └─ MaterialApp(                          │
│             theme: AppThemeData.light,           │
│             darkTheme: AppThemeData.dark,        │
│             themeMode: notifier.value,           │
│             home: LoginPage,                     │
│           )                                      │
└─────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│                LoginPage / AppScaffold           │
│  Reads Theme.of(context).brightness indirectly  │
│  via AppBackground → paints gradient/grid       │
└─────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│                  AppSidebar                      │
│  Receives: ValueNotifier<ThemeMode>             │
│  Reads: Theme.of(context).brightness            │
│  → SidebarColors.fromBrightness(brightness)     │
│  → Renders theme-reactive sidebar               │
│  → Bottom toggle button calls:                  │
│      _themeNotifier.value = nextMode            │
│      → MaterialApp rebuilds with new ThemeMode  │
│      → All Theme.of(context) consumers update   │
└─────────────────────────────────────────────────┘
```

---

## 8. Risk Assessment

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Pages with hardcoded `Colors.white` text become invisible on light background | High | Phase 1 focuses on infrastructure; Phase 2 migrates page tokens. Acceptable interim: most content is inside DataTables/cards which have their own backgrounds. |
| `SharedPreferences` theme key conflicts with existing keys | Low | Use key `"theme_mode"` — none of the 6 existing keys (`token`, `username_login`, `roleid_login`, `polda_login`, `uuid_login`, `expired_login`) collide. |
| `ValueNotifier` doesn't survive hot restart | None | It doesn't need to — the `initState` re-reads from `SharedPreferences`. |
| `CustomPaint` grid impacts scroll performance | Low | The grid is on the background layer, behind all scrolling content. It repaints only on theme toggle. `shouldRepaint` returns `oldDelegate.hashCode != hashCode`. |

---

## 9. Execution Order (Recommended)

1. **Create `lib/theme/` directory** with `app_theme.dart`, `theme_controller.dart`, `sidebar_colors.dart`.
2. **Create `cyber_grid_painter.dart`** with the `CustomPainter`.
3. **Rewrite `background.dart`** — dynamic, theme-aware, gradient + conditional grid.
4. **Modify `main.dart`** — `StatefulWidget` + `ValueNotifier` + `MaterialApp` with both themes.
5. **Modify `app_scaffold.dart`** — drop `imagePath`, pass `themeNotifier`.
6. **Modify `app_sidebar.dart`** — `SidebarColors`, theme toggle button.
7. **Modify `app_header.dart` + `app_footer.dart`** — theme-aware colors.
8. **Modify `login_page.dart`** — drop `imagePath`.
9. **Clean up** — remove old PNGs, update `pubspec.yaml`.
10. **Verify** — `flutter analyze` passes, manual light/dark toggle cycle.
