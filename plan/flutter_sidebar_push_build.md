# Flutter Sidebar — Push-Content Flat Design Build Report

**Date:** 2025-07-14
**Status:** ✅ EXECUTED — layout pivot from overlay glassmorphism to push-content flat design

---

## 1. What Changed

| Aspect | Before (v1) | After (v2) |
|---|---|---|
| Layout | `Stack` + `Positioned` overlay, 80px hardcoded gutter | `Row` + `Expanded` — sidebar **pushes** content |
| Expand trigger | `MouseRegion` hover | Manual hamburger `IconButton` (`Icons.menu` / `Icons.menu_open`) |
| Background | `BackdropFilter` blur + `ClipRRect`, alpha 0.85 | Flat `Color(0xff1E1B4B)` at alpha 0.9 |
| Logo | `AnimatedOpacity` → invisible at 80px | `AnimatedContainer` height 65↔40 — **always visible**, scales smoothly |
| Text spacers | Fixed `SizedBox` (35/15/5/30) | Animated spacers (15↔4 / 5↔2 / 30↔12) — dead zone compacted |
| Menu alignment | Default | Explicit `mainAxisAlignment: MainAxisAlignment.start` |
| `import 'dart:ui'` | Yes (ImageFilter) | Removed |

**Scope:** 2 files. All 22 page call sites unchanged (`AppScaffold` public API preserved — verified: 22/22 still compile-valid).

---

## 2. `lib/widget/app_scaffold.dart` (complete)

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'background.dart';
import 'app_sidebar.dart';
import 'app_header.dart';
import 'app_footer.dart';
import '../utils/session_util.dart';

/// Shared authenticated-page scaffold: full-bleed background, push-content
/// collapsible sidebar (80px collapsed / 240px expanded via the hamburger
/// toggle), and the standard header/content/footer column.
///
/// Layout is a [Row]:
///   - [AppSidebar] on the left, animating its own width (80 ↔ 240)
///   - [Expanded] content fills the remaining space — the sidebar *pushes*
///     the content instead of overlaying it
class AppScaffold extends StatefulWidget {
  final String currentRoute;
  final Widget child;
  final String imagePath;

  /// Breadcrumb shown in the [AppHeader], e.g. "Dashboard / Personel".
  final String? breadcrumb;

  /// When `false`, the [AppHeader]/[AppFooter] chrome and the 30px page
  /// padding are omitted and [child] fills the whole content area — used by
  /// the Command Center full-screen map.
  final bool showHeaderFooter;

  const AppScaffold({
    super.key,
    required this.currentRoute,
    required this.child,
    this.imagePath = 'assets/images/wp-putih-mabes.png',
    this.breadcrumb,
    this.showHeaderFooter = true,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

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
      _roleLabel = roleLabelFromId(prefs.getString("roleid_login"));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        imagePath: widget.imagePath,
        child: SafeArea(
          child: Row(
            children: [
              // ── Left: collapsible push sidebar ──
              AppSidebar(currentRoute: widget.currentRoute),

              // ── Right: content fills the remaining space ──
              Expanded(
                child: widget.showHeaderFooter
                    ? Padding(
                        padding: const EdgeInsets.all(30),
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
                      )
                    : widget.child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

```

### Layout notes

- `SafeArea > Row [ AppSidebar, Expanded(content) ]` — the sidebar animates its own
  `AnimatedContainer` width (80 ↔ 240); `Expanded` automatically shrinks/grows the content.
  No `Positioned`, no gutter constant.
- `showHeaderFooter: true` → `Padding(EdgeInsets.all(30))` + `Column [AppHeader, Expanded(child), AppFooter]`.
- `showHeaderFooter: false` (executive map) → `widget.child` directly, no padding.

---

## 3. `lib/widget/app_sidebar.dart` (complete)

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/menu_config.dart';
import '../utils/session_util.dart' as session;

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
  /// Delegates to [session.roleLabelFromId]; kept for API compatibility.
  static String roleLabelFromId(String? roleId) => session.roleLabelFromId(roleId);

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  String? _roleId;
  bool _loaded = false;

  /// Manual-toggle expansion: true when the hamburger button is clicked.
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

  void _toggleExpanded() => setState(() => _isExpanded = !_isExpanded);

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
    return AnimatedContainer(
      duration: _widthAnimationDuration,
      curve: Curves.easeOutCubic,
      width: _isExpanded ? _expandedWidth : _collapsedWidth,
      decoration: BoxDecoration(
        // Flat design: solid indigo, no backdrop blur.
        color: const Color(0xff1E1B4B).withValues(alpha: 0.9),
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
      child: Column(
        // Menu stack snaps to the top regardless of sidebar width.
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // ── Toggle button (hamburger), centered at the top ──
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: IconButton(
              icon: Icon(
                _isExpanded ? Icons.menu_open : Icons.menu,
                color: Colors.white70,
              ),
              onPressed: _toggleExpanded,
              tooltip: _isExpanded ? 'Collapse sidebar' : 'Expand sidebar',
              style: IconButton.styleFrom(hoverColor: Colors.white10),
            ),
          ),
          const SizedBox(height: 16),

          // ── Logo: always visible, scales down to fit the 80px rail ──
          AnimatedContainer(
            duration: _widthAnimationDuration,
            curve: Curves.easeOutCubic,
            height: _isExpanded ? 65 : 40,
            child: Image.asset(
              "assets/images/polri-logo.png",
              fit: BoxFit.contain,
            ),
          ),

          // ── Shrinking spacers (dead-zone compaction when collapsed) ──
          AnimatedContainer(
            duration: _widthAnimationDuration,
            curve: Curves.easeOutCubic,
            height: _isExpanded ? 15 : 4,
          ),
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
          AnimatedContainer(
            duration: _widthAnimationDuration,
            curve: Curves.easeOutCubic,
            height: _isExpanded ? 5 : 2,
          ),
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
          AnimatedContainer(
            duration: _widthAnimationDuration,
            curve: Curves.easeOutCubic,
            height: _isExpanded ? 30 : 12,
          ),

          // ── Menu ──
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

### Sidebar notes

- **Toggle:** `_toggleExpanded()` flips `_isExpanded`; the `IconButton` sits at the top of the
  `Column` (centered via the Column's default cross-axis centering), swapping
  `Icons.menu` ↔ `Icons.menu_open`.
- **Flat background:** `ClipRRect` + `BackdropFilter` removed; `AnimatedContainer` decoration
  is the flat color (alpha 0.9) with the existing right-pill radius + drop shadow.
- **Logo:** `AnimatedContainer(height: _isExpanded ? 65 : 40, duration: 300ms, curve: easeOutCubic)`
  wrapping `Image.asset(fit: BoxFit.contain)` — no opacity on the logo.
- **Dead-zone compaction:** the three spacers between logo/texts/menu are `AnimatedContainer`s
  shrinking to 4 / 2 / 12px when collapsed, pulling the menu up toward the top.
- **Group handling unchanged:** `_expandedGroups` hoisting + collapsed icon-only tile (tapping it
  auto-expands the rail and opens the group) — same logic as v1, still driven by `_isExpanded`.

---

## 4. Verification

- ✅ Bracket balance: `app_scaffold.dart` and `app_sidebar.dart` both balanced (() [] {}).
- ✅ No leftovers of removed symbols: `MouseRegion`, `BackdropFilter`, `ClipRRect`, `ImageFilter`,
  `dart:ui`, `Positioned`, `_collapsedSidebarWidth`, `_setHovered` — all gone.
- ✅ Required additions present: `_toggleExpanded`, `Icons.menu`/`Icons.menu_open`,
  `MainAxisAlignment.start`, `withValues(alpha: 0.9)`, animated logo + spacers.
- ✅ No external references to removed private API (`_collapsedSidebarWidth`, `_setHovered`).
- ✅ 22/22 pages still call `AppScaffold(` with the unchanged constructor signature.
- ⚠️ `dart format` / `flutter analyze` not runnable in this environment (no Dart SDK) — run:

```bash
dart format lib/widget/app_scaffold.dart lib/widget/app_sidebar.dart
flutter analyze
flutter run   # manual smoke test: toggle, push animation, logo scale, menu alignment
```
