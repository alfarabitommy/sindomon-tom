import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/menu_config.dart';
import '../utils/session_util.dart' as session;
import '../widget/hud_loading_spinner.dart';

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
  ///
  /// Toggling this only flips [Offstage] flags — the widget tree is never
  /// unmounted, so MouseRegion lifecycles stay perfectly intact (this is the
  /// bulletproof fix for the mouse_tracker.dart:203:12 assertion).
  bool _isExpanded = true;

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
                // Both icons live permanently in the tree; Offstage toggles
                // visibility so the IconButton's internal Tooltip/InkResponse
                // (and their MouseRegions) are never rebuilt or disposed.
                icon: Stack(
                  alignment: Alignment.center,
                  children: [
                    Offstage(
                      offstage: _isExpanded,
                      child: const Icon(Icons.menu, color: Colors.white70),
                    ),
                    Offstage(
                      offstage: !_isExpanded,
                      child: const Icon(Icons.menu_open, color: Colors.white70),
                    ),
                  ],
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
                    child: HudLoadingSpinner(size: 40),
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
        // Strategy B (Offstage Preservation): BOTH renderings live in the
        // tree permanently. Offstage(offstage: true) skips layout, paint and
        // hit-testing but keeps the Element (and its MouseRegions) alive, so
        // the collapsed ↔ expanded toggle never disposes a widget under the
        // mouse — immune to the mouse_tracker.dart:203:12 assertion.
        widgets.add(
          Stack(
            children: [
              Offstage(
                offstage: !_isExpanded,
                child: _buildGroupItem(item),
              ),
              Offstage(
                offstage: _isExpanded,
                child: _buildCollapsedGroupItem(item),
              ),
            ],
          ),
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
          // trailing slot and overflow the 80px rail. Offstage (not null)
          // keeps the ListTile's child structure stable — no widget is ever
          // conditionally created or disposed.
          trailing: Offstage(
            offstage: !(selected && _isExpanded),
            child: const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.black,
            ),
          ),
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
      // No key needed: this subtree is permanently mounted (Strategy B).
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
          // The ExpansionTile is permanently mounted (Strategy B), so it
          // manages its own expansion state internally — no hoisting needed.
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
  /// Sits permanently beside [_buildGroupItem] in a Stack; the rail toggle
  /// only flips the Offstage flags, so no widget is ever unmounted here.
  /// Uses a raw GestureDetector (no ListTile/InkWell): the icon is its own
  /// hit-target and the group's ExpansionTile keeps its own open/closed
  /// state while offstage.
  Widget _buildCollapsedGroupItem(MenuGroup group) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: () {
          // Only expand the rail; the ExpansionTile (permanently mounted)
          // preserves its own group open/closed state across toggles.
          setState(() => _isExpanded = true);
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
