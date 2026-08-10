# Flutter Sidebar — MouseTracker Bypass Build Report

**Date:** 2025-07-14
**Status:** ✅ EXECUTED — Option C applied, `ListTile` → `GestureDetector` in collapsed group items

---

## 1. Change Summary

**File:** `lib/widget/app_sidebar.dart`
**Method:** `_buildCollapsedGroupItem` (was lines ~329–370)

### Removed
- `ListTile` (with its internal `InkResponse` → `MouseRegion` → `MouseTracker` annotation)
- `hoverColor: Colors.white10` (4th occurrence — count now 3, only the safe ones remain)
- `AnimatedOpacity`-wrapped title (no text fits the 80px rail anyway)
- `contentPadding` math (was: 20px each side to center the 40px leading slot)
- `Future.delayed(Duration.zero, ...)` microtask + `mounted` check — **no longer needed**

### Added
- Raw `GestureDetector` — detects taps via the pointer-event pipeline
  (`Listener`/`RenderPointerListener`), **zero `MouseTracker` involvement**
- `Center` → `SizedBox(height: 48)` → `Center` → `Icon` — identical tap-target
  footprint (48px) and perfectly centered icon in the 80px rail
- Synchronous `setState` in `onTap` — safe, because there is no `MouseRegion`
  to leak when the widget is swapped for the `ExpansionTile` on expand

### Kept
- `key: ValueKey('collapsed_${group.label}')` — clean reconciliation
- `_buildGroupItem` untouched (its `ExpansionTile` is only created when the
  rail is already expanded — never disposed mid-hover)
- `_buildLeafItem`, `_buildChildItem`, hamburger toggle untouched

---

## 2. Verification

- ✅ Full file `() [] {}` balanced (interpolation-aware validator)
- ✅ `GestureDetector` + synchronous `setState` present in `_buildCollapsedGroupItem`
- ✅ `Future.delayed` completely removed from the file
- ✅ `hoverColor:` count = 3 (hamburger 122, leaf 256, child 396 — all non-swapped, safe)
- ✅ `ListTile(` count = 2 (leaf + child — the crashed one is gone)
- ✅ Both `ValueKey`s (`collapsed_*`, `expanded_*`) retained
- ✅ `SizedBox(height: 48)` tap-target footprint present
- ⚠️ On-device smoke test: collapse → tap each group icon → rail expands +
  group opens, no assertion, no freeze

---

## 3. Full Updated File — `lib/widget/app_sidebar.dart`

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
  /// Defaults to expanded (240px) on first load.
  bool _isExpanded = true;

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
          // ── Toggle button (hamburger) — rigidly locked geometry ──
          // The SizedBox sandwich pins the icon's Y-position regardless of
          // sidebar width, icon shape swap, or content shrinkage below.
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: Align(
              alignment: Alignment.center,
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
          ),
          const SizedBox(height: 12),

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
      // Distinguishes the ExpansionTile from the collapsed icon tile during
      // the widget swap, so Flutter reconciles (not destroys) the subtree.
      key: ValueKey('expanded_${group.label}'),
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
  /// Uses a raw GestureDetector (not a ListTile/InkWell) so there is no
  /// MouseRegion to leak when the widget is swapped for an ExpansionTile
  /// on expand — avoids the known mouse_tracker.dart:203:12 crash.
  Widget _buildCollapsedGroupItem(MenuGroup group) {
    return Padding(
      key: ValueKey('collapsed_${group.label}'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isExpanded = true;
            _expandedGroups.add(group.label);
          });
        },
        child: Center(
          // 48px minimum height matches ListTile's tap-target size so the
          // layout footprint in the menu list is identical.
          child: SizedBox(
            height: 48,
            child: Center(
              child: Icon(group.icon, color: Colors.white70),
            ),
          ),
        ),
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
