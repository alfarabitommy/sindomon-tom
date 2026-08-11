import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/menu_config.dart';
import '../utils/session_util.dart' as session;
import '../theme/sidebar_colors.dart';
import '../theme/theme_controller.dart';
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
  final ThemeController themeController;

  const AppSidebar({
    super.key,
    required this.currentRoute,
    required this.themeController,
  });

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

  /// Theme toggle: J.A.R.V.I.S / Corporate switcher.
  Widget _buildThemeToggle() {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final colors = SidebarColors.fromBrightness(brightness);
    return IconButton(
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
    );
  }

  /// Collapse/expand toggle, relocated to the bottom control cluster.
  ///
  /// Both icons live permanently in the tree; Offstage toggles visibility so
  /// the IconButton's internal Tooltip/InkResponse (and their MouseRegions)
  /// are never rebuilt or disposed.
  Widget _buildCollapseToggle() {
    final colors = SidebarColors.fromBrightness(Theme.of(context).brightness);
    return IconButton(
      icon: Stack(
        alignment: Alignment.center,
        children: [
          Offstage(
            offstage: _isExpanded,
            child: Icon(
              Icons.keyboard_double_arrow_right,
              color: colors.iconColor,
            ),
          ),
          Offstage(
            offstage: !_isExpanded,
            child: Icon(
              Icons.keyboard_double_arrow_left,
              color: colors.iconColor,
            ),
          ),
        ],
      ),
      onPressed: _toggleExpanded,
      tooltip: _isExpanded ? 'Collapse sidebar' : 'Expand sidebar',
      style: IconButton.styleFrom(hoverColor: colors.hoverColor),
    );
  }

  /// Bottom control cluster: theme toggle + collapse toggle.
  ///
  /// Expanded: side-by-side [Row] with [MainAxisAlignment.spaceBetween].
  /// Collapsed: stacked [Column] centered in the 80px rail.
  Widget _buildBottomControls() {
    if (_isExpanded) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [_buildThemeToggle(), _buildCollapseToggle()],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [_buildThemeToggle(), _buildCollapseToggle()],
      ),
    );
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
    final brightness = Theme.of(context).brightness;
    final colors = SidebarColors.fromBrightness(brightness);

    return AnimatedContainer(
      duration: _widthAnimationDuration,
      curve: Curves.easeOutCubic,
      width: _isExpanded ? _expandedWidth : _collapsedWidth,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 20,
            offset: Offset(5, 0),
          ),
        ],
      ),
      child: Column(
        // Menu stack snaps to the top regardless of sidebar width.
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
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
            child: Text(
              "SINDOMON",
              style: TextStyle(
                color: colors.textPrimary,
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
                color: colors.textSecondary,
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

          // ── Bottom controls: theme toggle + collapse toggle ──
          Divider(
            color: colors.hoverColor,
            height: 1,
            indent: 20,
            endIndent: 20,
          ),
          const SizedBox(height: 4),
          _buildBottomControls(),
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
    final colors = SidebarColors.fromBrightness(Theme.of(context).brightness);
    final selected = widget.currentRoute == item.routeName;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? colors.selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: ListTile(
          leading: Icon(
            item.icon,
            color: selected ? colors.selectedText : colors.iconColor,
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
                color: selected ? colors.selectedText : colors.textPrimary,
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
            child: Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: colors.selectedText,
            ),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          hoverColor: colors.hoverColor,
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
    final colors = SidebarColors.fromBrightness(Theme.of(context).brightness);
    return Container(
      // No key needed: this subtree is permanently mounted (Strategy B).
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(group.icon, color: colors.iconColor),
          title: AnimatedOpacity(
            duration: _textFadeDuration,
            curve: _textFadeCurve,
            opacity: _isExpanded ? 1.0 : 0.0,
            child: Text(
              group.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          // The ExpansionTile is permanently mounted (Strategy B), so it
          // manages its own expansion state internally — no hoisting needed.
          collapsedIconColor: colors.iconColor,
          iconColor: colors.selectedBg,
          childrenPadding: const EdgeInsets.only(left: 24, bottom: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: colors.hoverColor,
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
    final colors = SidebarColors.fromBrightness(Theme.of(context).brightness);
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
              child: Icon(group.icon, color: colors.iconColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChildItem(LeafMenuItem item) {
    final colors = SidebarColors.fromBrightness(Theme.of(context).brightness);
    final selected = widget.currentRoute == item.routeName;
    return ListTile(
      leading: Icon(
        item.icon,
        color: selected ? colors.selectedBg : colors.iconColor,
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
            color: selected ? colors.selectedBg : colors.textPrimary,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      hoverColor: colors.hoverColor,
      onTap: () => _navigateTo(item.pageBuilder()),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      visualDensity: VisualDensity.compact,
    );
  }
}
