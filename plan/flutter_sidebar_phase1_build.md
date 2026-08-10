# Flutter Sidebar — Phase 1 Build Report

**Date:** 2025-07-14  
**Status:** ✅ EXECUTED — Phase 1 (scaffold wrapper + animated glassmorphism sidebar)

---

## 1. What Was Delivered

| Deliverable | File | Status |
|---|---|---|
| `AppScaffold` layout wrapper (Stack: background / content / overlay sidebar) | `lib/widget/app_scaffold.dart` | ✅ NEW |
| Hover-to-expand glassmorphism sidebar (80px ↔ 240px) | `lib/widget/app_sidebar.dart` | ✅ REFACTORED |
| Build report with complete code | `plan/flutter_sidebar_phase1_build.md` | ✅ THIS FILE |

**Deliberately NOT touched (Phase 2):** the 22 page files still use their existing `Row` layout with `AppSidebar(currentRoute: ...)`. The `AppSidebar` public API is unchanged, so all pages keep compiling and working — in the legacy `Row` layout the rail expands *in place* (pushing content) until pages migrate to `AppScaffold`, which enables the floating overlay behavior.

---

## 2. `lib/widget/app_scaffold.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'background.dart';
import 'app_sidebar.dart';
import 'app_header.dart';
import 'app_footer.dart';

/// Shared authenticated-page scaffold: full-bleed background, collapsible
/// glassmorphism sidebar (80px collapsed / 240px hover-expanded overlay),
/// and the standard header/content/footer column.
///
/// Layout is a [Stack]:
///   - bottom layer: [AppBackground] (wallpaper image)
///   - middle layer: page content (`child`), reserving a 80px gutter on the
///     left for the collapsed sidebar
///   - top layer: [AppSidebar], positioned on the left so its expanded state
///     floats OVER the content instead of pushing it (glassmorphism blur
///     keeps the content legible underneath).
class AppScaffold extends StatefulWidget {
  final String currentRoute;
  final Widget child;
  final String imagePath;

  /// Breadcrumb shown in the [AppHeader], e.g. "Dashboard / Personel".
  final String? breadcrumb;

  const AppScaffold({
    super.key,
    required this.currentRoute,
    required this.child,
    this.imagePath = 'assets/images/wp-putih-mabes.png',
    this.breadcrumb,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

/// Width reserved for the collapsed sidebar (icons only).
const double _collapsedSidebarWidth = 80.0;

class _AppScaffoldState extends State<AppScaffold> {
  String _username = "";
  String _roleLabel = "Operator";

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  /// Mirrors the per-page logic: read the session from SharedPreferences
  /// and feed it to the [AppHeader].
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _username = prefs.getString("username_login") ?? "";
      _roleLabel = AppSidebar.roleLabelFromId(prefs.getString("roleid_login"));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        imagePath: widget.imagePath,
        child: SafeArea(
          child: Stack(
            children: [
              // ── Middle layer: page content (80px gutter on the left) ──
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: _collapsedSidebarWidth + 30,
                    top: 30,
                    right: 30,
                    bottom: 30,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppHeader(
                        breadcrumb: widget.breadcrumb ?? "",
                        username: _username,
                        role: _roleLabel,
                      ),
                      Expanded(child: widget.child),
                      const AppFooter(),
                    ],
                  ),
                ),
              ),
              // ── Top layer: collapsible overlay sidebar ──
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: AppSidebar(currentRoute: widget.currentRoute),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Design decisions

- **`Stack` z-order:** content (middle) renders *before* the sidebar (top) in paint order, so `BackdropFilter` inside the sidebar blurs the actual page content behind it — the core of the glassmorphism effect.
- **Content gutter:** `left: 80 + 30 = 110` — the 80px collapsed rail never covers content; when expanded to 240px, the rail floats over the first 160px of content.
- **Header data:** `AppScaffold` loads `username_login` / `roleid_login` from `SharedPreferences` itself (same logic pages used for `AppHeader`), so pages can drop their own `loadUser()` boilerplate in Phase 2.
- **`breadcrumb` optional:** falls back to `""` so the wrapper is safe to adopt incrementally.

---

## 3. `lib/widget/app_sidebar.dart` (REFACTORED)

```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/menu_config.dart';

/// Collapsed width: icons only (Navigation Rail style).
const double _collapsedWidth = 80.0;

/// Expanded width: icons + labels.
const double _expandedWidth = 240.0;

/// How long the width animation takes.
const Duration _widthAnimationDuration = Duration(milliseconds: 300);

/// Fade duration for text/logo labels.
const Duration _textFadeDuration = Duration(milliseconds: 200);

/// Text starts fading in only once the sidebar is mostly expanded, so labels
/// never render mid-animation while the rail is still too narrow (avoids
/// wrapping/overflow glitches during the 300ms width transition).
const Curve _textFadeCurve = Interval(0.5, 1.0, curve: Curves.easeOutCubic);

class AppSidebar extends StatefulWidget {
  final String currentRoute;

  const AppSidebar({super.key, required this.currentRoute});

  /// Harus sinkron dengan keys [roleMenus] di menu_config.dart.
  /// Setiap case di sini memerlukan definisi menu yang sesuai.
  static String roleLabelFromId(String? roleId) {
    switch (roleId) {
      case "1": return "Super Admin";
      case "2": return "Operator Polda";
      case "3": return "Command Center";
      default: return "Operator";
    }
  }

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  String? _roleId;
  bool _loaded = false;

  /// Hover-driven expansion: true while the mouse is over the rail.
  bool _isExpanded = false;

  /// Hoisted ExpansionTile state so group expansion survives the
  /// collapsed (icon-only ListTile) ↔ expanded (ExpansionTile) widget swap.
  final Set<String> _expandedGroups = {};

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _roleId = prefs.getString("roleid_login");
      _loaded = true;
    });
  }

  void _navigateTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _setHovered(bool value) {
    if (_isExpanded != value) {
      setState(() => _isExpanded = value);
    }
  }

  List<dynamic> _resolveMenu() {
    if (_roleId == null) return [];
    if (!roleMenus.containsKey(_roleId)) {
      debugPrint(
        '[AppSidebar] WARNING: Tidak ada menu untuk role "$_roleId", memakai menu default',
      );
      return commonTopItems.toList();
    }
    return roleMenus[_roleId]!.expand((e) => e).toList();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: AnimatedContainer(
        duration: _widthAnimationDuration,
        curve: Curves.easeOutCubic,
        width: _isExpanded ? _expandedWidth : _collapsedWidth,
        decoration: BoxDecoration(
          // Glassmorphism: translucent indigo over the blurred backdrop.
          color: const Color(0xff1E1B4B).withValues(alpha: 0.85),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(5, 0),
            ),
          ],
        ),
        child: ClipRRect(
          // Clip the blur to the rounded right edge of the rail.
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Column(
              children: [
                const SizedBox(height: 35),
                AnimatedOpacity(
                  duration: _textFadeDuration,
                  curve: _textFadeCurve,
                  opacity: _isExpanded ? 1.0 : 0.0,
                  child: Image.asset(
                    "assets/images/polri-logo.png",
                    height: 65,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 15),
                AnimatedOpacity(
                  duration: _textFadeDuration,
                  curve: _textFadeCurve,
                  opacity: _isExpanded ? 1.0 : 0.0,
                  child: const Text(
                    "SINDOMON",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                AnimatedOpacity(
                  duration: _textFadeDuration,
                  curve: _textFadeCurve,
                  opacity: _isExpanded ? 1.0 : 0.0,
                  child: Text(
                    "Sistem Informasi Manajemen",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: _loaded
                      ? ListView(
                          padding: EdgeInsets.symmetric(
                            horizontal: _isExpanded ? 12 : 0,
                          ),
                          children: _buildMenuItems(),
                        )
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.amber),
                        ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMenuItems() {
    final items = _resolveMenu();
    final List<Widget> widgets = [];

    for (final item in items) {
      if (item is LeafMenuItem) {
        widgets.add(_buildLeafItem(item));
      } else if (item is MenuGroup) {
        // In collapsed mode an ExpansionTile would overflow the 80px rail
        // (leading icon + trailing arrow > available width), so groups are
        // rendered as a centered icon-only tile instead.
        widgets.add(
          _isExpanded ? _buildGroupItem(item) : _buildCollapsedGroupItem(item),
        );
      }
    }

    return widgets;
  }

  Widget _buildLeafItem(LeafMenuItem item) {
    final selected = widget.currentRoute == item.routeName;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? Colors.amber : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: ListTile(
          leading: Icon(
            item.icon,
            color: selected ? Colors.black : Colors.white70,
          ),
          title: AnimatedOpacity(
            duration: _textFadeDuration,
            curve: _textFadeCurve,
            opacity: _isExpanded ? 1.0 : 0.0,
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.black : Colors.white,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          // Hide the trailing arrow when collapsed: it would consume a 40px
          // trailing slot and overflow the 80px rail.
          trailing: selected && _isExpanded
              ? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black)
              : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          hoverColor: Colors.white10,
          // 20px each side centers the 40px leading slot (and its icon) in
          // the 80px collapsed rail; 16px matches the pre-refactor look when
          // expanded.
          contentPadding: EdgeInsets.symmetric(
            horizontal: _isExpanded ? 16 : 20,
          ),
          onTap: () => _navigateTo(item.pageBuilder()),
        ),
      ),
    );
  }

  Widget _buildGroupItem(MenuGroup group) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(group.icon, color: Colors.white70),
          title: AnimatedOpacity(
            duration: _textFadeDuration,
            curve: _textFadeCurve,
            opacity: _isExpanded ? 1.0 : 0.0,
            child: Text(
              group.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          // Expansion state is hoisted so it survives the collapsed ↔
          // expanded widget swap (initiallyExpanded re-applies on rebuild).
          initiallyExpanded: _expandedGroups.contains(group.label),
          onExpansionChanged: (expanded) {
            setState(() {
              if (expanded) {
                _expandedGroups.add(group.label);
              } else {
                _expandedGroups.remove(group.label);
              }
            });
          },
          collapsedIconColor: Colors.white70,
          iconColor: Colors.amber,
          childrenPadding: const EdgeInsets.only(left: 24, bottom: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.white.withValues(alpha: 0.04),
          collapsedBackgroundColor: Colors.transparent,
          children: group.children
              .map((child) => _buildChildItem(child))
              .toList(),
        ),
      ),
    );
  }

  /// Collapsed-mode (80px) rendering of a group: icon only, centered.
  /// The title stays in the tree at opacity 0 so the ListTile reserves the
  /// standard 40px leading slot, which centers the icon in the 80px rail
  /// (mirrors [_buildLeafItem]'s collapsed layout exactly).
  /// Tapping auto-expands the rail AND opens the group.
  Widget _buildCollapsedGroupItem(MenuGroup group) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(group.icon, color: Colors.white70),
        title: AnimatedOpacity(
          duration: _textFadeDuration,
          curve: _textFadeCurve,
          opacity: _isExpanded ? 1.0 : 0.0,
          child: Text(
            group.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        hoverColor: Colors.white10,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        onTap: () {
          setState(() {
            _isExpanded = true;
            _expandedGroups.add(group.label);
          });
        },
      ),
    );
  }

  Widget _buildChildItem(LeafMenuItem item) {
    final selected = widget.currentRoute == item.routeName;
    return ListTile(
      leading: Icon(
        item.icon,
        color: selected ? Colors.amber : Colors.white70,
        size: 20,
      ),
      title: AnimatedOpacity(
        duration: _textFadeDuration,
        curve: _textFadeCurve,
        opacity: _isExpanded ? 1.0 : 0.0,
        child: Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? Colors.amber : Colors.white,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      hoverColor: Colors.white10,
      onTap: () => _navigateTo(item.pageBuilder()),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      visualDensity: VisualDensity.compact,
    );
  }
}
```

---

## 4. Animation & Layout Mechanics

### 4.1 Hover → expand

```
MouseRegion (onEnter/onExit) → setState(_isExpanded)
  → AnimatedContainer(width: 80 ↔ 240, 300ms, Curves.easeOutCubic)
```

### 4.2 Glassmorphism

```
AnimatedContainer (translucent indigo 0.85 + rounded right corners + shadow)
  └─ ClipRRect (radius 25 right)      ← clips the blur to the rounded edge
       └─ BackdropFilter (blur σ=12)  ← blurs whatever is painted behind
            └─ Column (logo / title / menu)
```

### 4.3 Text reveal (anti-glitch)

All labels use `AnimatedOpacity(duration: 200ms, curve: Interval(0.5, 1.0))`.
The `Interval` delays the fade start until the rail is ~70% expanded
(~200px), so labels never render while the rail is still too narrow to fit
them. `maxLines: 1` + `TextOverflow.ellipsis` on menu labels additionally
prevents line-wrap jumps mid-animation. During collapse the same interval
keeps text readable while the rail is still wide.

### 4.4 Icon centering at 80px (math)

- Collapsed rail: 80px wide, `ListView` horizontal padding → 0
- `ListTile` `contentPadding` → 20px each side ⇒ inner width 40px
- `ListTile` reserves a 40px leading slot ⇒ icon centered exactly at x=40
  (rail center). The title (opacity 0) stays in the tree precisely so the
  leading slot is reserved.
- Trailing arrow hidden when collapsed (a 40px trailing slot would overflow
  the 40px inner width).

### 4.5 Groups in collapsed mode

`ExpansionTile` cannot fit in 80px (leading 40 + trailing arrow 40 = 80 >
inner 40). Phase 1 solution:

- Collapsed: group renders as an icon-only `ListTile`; tapping it
  auto-expands the rail AND opens the group.
- Group expansion state is **hoisted** into `_expandedGroups` (`Set<String>`,
  keyed by `group.label`) and re-applied via `initiallyExpanded` +
  `onExpansionChanged`, so groups stay open across the collapsed ↔ expanded
  widget swap.

---

## 5. Verification

- **`flutter analyze`:** ⚠️ NOT RUN — Flutter SDK is not installed in this
  environment (`command -v flutter` → empty). Static review performed instead.
- **Static review (manual, line-by-line):**
  - Public API unchanged (`AppSidebar(currentRoute:)`, `roleLabelFromId`) —
    all 22 page call sites keep compiling (verified via grep).
  - All symbols used exist in the project's Flutter version: `withValues(alpha:)`
    is already used in `app_sidebar.dart` (pre-existing), `BackdropFilter` +
    `ImageFilter.blur(sigmaX: 12, sigmaY: 12)` is the exact pattern already
    used in `lib/pages/dashboard.dart:326-327` and `lib/widget/login_card.dart:239-240`.
  - `Interval`, `Curves.easeOutCubic`, `AnimatedOpacity.curve`,
    `AnimatedContainer.curve` — all standard Material/animation API.
  - Layout math checked for overflow in both states (see 4.4).
- **Smoke test:** deferred — no `test/` directory exists and no Flutter SDK
  locally; recommend running `flutter analyze` + a quick manual run on the
  dev machine before merging.

---

## 6. Next Steps (Phase 2)

1. **Migrate the 22 pages** from the manual `Row` pattern to
   `AppScaffold(currentRoute: ..., breadcrumb: ..., child: ...)` — this
   activates the floating overlay behavior (content stops being pushed when
   the rail expands).
2. Remove per-page `loadUser()` / `AppHeader` / `AppFooter` boilerplate
   (now owned by `AppScaffold`).
3. Optionally lift `_isExpanded` into `AppScaffold` if a global "pin" toggle
   is ever needed.
4. Verify on-device: hover enter/exit, glass blur over light content,
   selected-item amber highlight in both states, group auto-open.
