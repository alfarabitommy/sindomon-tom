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
