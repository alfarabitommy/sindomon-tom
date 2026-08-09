import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/menu_config.dart';

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
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Color(0xff1E1B4B),
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
        children: [
          const SizedBox(height: 35),
          Image.asset(
            "assets/images/polri-logo.png",
            height: 65,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 15),
          const Text(
            "SINDOMON",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "Sistem Informasi Manajemen",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: _loaded
                ? ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: _buildMenuItems(),
                  )
                : const Center(child: CircularProgressIndicator(color: Colors.amber)),
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
        widgets.add(_buildGroupItem(item));
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
          title: Text(
            item.label,
            style: TextStyle(
              color: selected ? Colors.black : Colors.white,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          trailing: selected
              ? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black)
              : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          hoverColor: Colors.white10,
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
          title: Text(
            group.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          collapsedIconColor: Colors.white70,
          iconColor: Colors.amber,
          childrenPadding: const EdgeInsets.only(left: 24, bottom: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: Colors.white.withValues(alpha: 0.04),
          collapsedBackgroundColor: Colors.transparent,
          children: group.children
              .map((child) => _buildChildItem(child))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildChildItem(LeafMenuItem item) {
    final selected = widget.currentRoute == item.routeName;
    return ListTile(
      leading: Icon(item.icon, color: selected ? Colors.amber : Colors.white70, size: 20),
      title: Text(
        item.label,
        style: TextStyle(
          color: selected ? Colors.amber : Colors.white,
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          fontSize: 13,
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
