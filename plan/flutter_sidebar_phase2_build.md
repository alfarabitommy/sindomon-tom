# Flutter Sidebar — Phase 2 Build Report (Mass Transplant)

**Date:** 2025-07-14
**Status:** ✅ EXECUTED — all 22 pages migrated to `AppScaffold`

---

## 1. What Was Delivered

| Deliverable | Status |
|---|---|
| `AppScaffold` upgraded with `showHeaderFooter` flag (full-screen map mode) | ✅ |
| `lib/pages/pangaturan.dart` — Archetype 1 hand-refactor (header/footer → `AppScaffold`) | ✅ |
| `lib/pages/dashboard.dart` — Archetype 2 hand-refactor (full-screen map, `showHeaderFooter: false`) | ✅ |
| `scripts/migrate_scaffold.py` — automated mass migration of the remaining 20 pages | ✅ RUN (20/20 PASS) |
| `roleLabelFromId` extracted to `lib/utils/session_util.dart` (shared by sidebar, scaffold, pages) | ✅ |
| This report | ✅ |

**Files changed (24):** 22 pages + `lib/widget/app_scaffold.dart` + `lib/utils/session_util.dart`
(+ `lib/widget/app_sidebar.dart` delegation shim, `scripts/migrate_scaffold.py` new).

---

## 2. `AppScaffold` Upgrade (`lib/widget/app_scaffold.dart`)

New parameter:

```dart
/// When `false`, the [AppHeader]/[AppFooter] chrome and the 30px page
/// padding are omitted and [child] fills the whole content area — used by
/// the Command Center full-screen map. The 80px collapsed-sidebar gutter
/// is always kept.
final bool showHeaderFooter;
```

`build()` now branches the middle layer:

```dart
Positioned.fill(
  child: Padding(
    padding: widget.showHeaderFooter
        ? EdgeInsets.only(
            left: _collapsedSidebarWidth + 30,  // 80px rail gutter + 30px page pad
            top: 30, right: 30, bottom: 30,
          )
        : const EdgeInsets.only(left: _collapsedSidebarWidth),  // full-bleed
    child: widget.showHeaderFooter
        ? Column(children: [AppHeader(...), Expanded(child: widget.child), const AppFooter()])
        : widget.child,   // no chrome — child owns the whole area
  ),
),
```

Also switched to the shared `roleLabelFromId()` from `session_util.dart` (no more
dependency on `AppSidebar` for label lookup).

### Complete file

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'background.dart';
import 'app_sidebar.dart';
import 'app_header.dart';
import 'app_footer.dart';
import '../utils/session_util.dart';

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

  /// When `false`, the [AppHeader]/[AppFooter] chrome and the 30px page
  /// padding are omitted and [child] fills the whole content area — used by
  /// the Command Center full-screen map. The 80px collapsed-sidebar gutter
  /// is always kept.
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
      _roleLabel = roleLabelFromId(prefs.getString("roleid_login"));
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
                  padding: widget.showHeaderFooter
                      ? EdgeInsets.only(
                          left: _collapsedSidebarWidth + 30,
                          top: 30,
                          right: 30,
                          bottom: 30,
                        )
                      : const EdgeInsets.only(left: _collapsedSidebarWidth),
                  child: widget.showHeaderFooter
                      ? Column(
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
                        )
                      : widget.child,
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

---

## 3. Archetype 1 — `lib/pages/pangaturan.dart` (complete)

What changed:
- Imports: dropped `background.dart`, `app_sidebar.dart`, `app_footer.dart`, `app_header.dart`;
  added `app_scaffold.dart` + `session_util.dart`.
- `roleLabel = roleLabelFromId(...)` (shared util) instead of `AppSidebar.roleLabelFromId`.
- `build()` returns `AppScaffold(currentRoute: 'pengaturan', breadcrumb: 'Dashboard / Profil Saya', child: ...)`.
- The `child` is only the Title Row + `Expanded(SingleChildScrollView(...))` with the profile
  cards; the header/footer and 30px padding are owned by `AppScaffold`. Spacing preserved:
  25px gap under the header, 25px under the title, 20px bottom scroll padding (was the
  pre-footer `SizedBox`).

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../widget/app_scaffold.dart';
import '../utils/session_util.dart';

class AccountSettingPage extends StatefulWidget {
  const AccountSettingPage({super.key});

  @override
  State<AccountSettingPage> createState() => _AccountSettingPageState();
}

class _AccountSettingPageState extends State<AccountSettingPage> {
  String unLogin = "";
  String roleLabel = "Operator";
  String polda = "";

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      unLogin = prefs.getString("username_login") ?? "";
      roleLabel = roleLabelFromId(prefs.getString("roleid_login"));
      polda = prefs.getString("polda_login") ?? "";
    });
  }

  /// Fetch real profile data (e.g. `nama_polda`) from the backend and
  /// refresh the UI. Falls back to the SharedPreferences value on failure.
  Future<void> fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.get(
        Uri.parse("$apiBaseUrl/api/v1/profile"),
        headers: {"Authorization": token.toString()},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json["data"] as Map<String, dynamic>? ?? {};
        final namaPolda = data["nama_polda"]?.toString() ?? "";

        if (!mounted) return;
        setState(() {
          if (namaPolda.isNotEmpty) polda = namaPolda;
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    loadUser();
    fetchProfile();
  }

  /// Read-only info card: icon + label + value.
  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.amber, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// Full-width device binding status card (placeholder state).
  Widget _bindingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Colors.green,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Status Binding Perangkat",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Perangkat Terverifikasi",
                style: TextStyle(fontSize: 13, color: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentRoute: 'pengaturan',
      breadcrumb: 'Dashboard / Profil Saya',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Gap below the AppHeader (rendered by AppScaffold).
          const SizedBox(height: 25),

          /// ============================
          /// TITLE
          /// ============================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Profil & Pengaturan",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF23251D),
                ),
              ),

              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text("Kembali"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF23251D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          /// ============================
          /// MIDDLE ZONE: SCROLLABLE CONTENT
          /// ============================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ============================
                  /// PROFIL (READ-ONLY)
                  /// ============================
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _infoCard(
                        icon: Icons.person_rounded,
                        label: "Nama Pengguna",
                        value: unLogin,
                      ),
                      _infoCard(
                        icon: Icons.admin_panel_settings_rounded,
                        label: "Level Akses",
                        value: roleLabel,
                      ),
                      _infoCard(
                        icon: Icons.map_rounded,
                        label: "Polda",
                        value: polda.isEmpty ? "-" : polda,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// ============================
                  /// KEAMANAN PERANGKAT
                  /// ============================
                  _bindingCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

```

---

## 4. Archetype 2 — `lib/pages/dashboard.dart` (complete)

What changed (only the chrome; the map/avatar/KPI stack is untouched):

```dart
@override
Widget build(BuildContext context) {
  return AppScaffold(
    currentRoute: 'dashboard',
    // Executive Command Center: full-screen map without the standard
    // header/footer chrome (the map owns its own overlays).
    showHeaderFooter: false,
    child: _roleId == "3" ? _buildCommandCenterContent() : _buildPlaceholder(),
  );
}
```

- `showHeaderFooter: false` gives Role 3 a full-bleed map (only the 80px collapsed-rail
  gutter is reserved; the expanded rail floats over the map with glassmorphism).
- The floating `_ExecAction` avatar (`ClipOval` + `BackdropFilter`, top-right) lives inside
  `_buildCommandCenterContent()`'s `Stack` — **unchanged, intact over the map**.
- Non-executive roles keep the bare "coming soon" placeholder (no header), exactly as before.
- Imports: dropped `background.dart` + `app_sidebar.dart`; added `app_scaffold.dart`.
  Kept `dart:ui` (avatar `ImageFilter`), `flutter_map`, models, `pangaturan` (nav target),
  `session_util` (`clearSessionAndLogout`), `http`, `shared_preferences`.

```dart
import 'package:flutter/material.dart';
import 'dart:ui';
import '../config/api_config.dart';
import '../models/dashboard_model.dart';
import '../models/polda_model.dart';
import '../pages/pangaturan.dart';
import '../utils/session_util.dart';
import '../widget/app_scaffold.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Actions available from the executive floating profile avatar.
enum _ExecAction { pengaturan, logout }

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Polda> provinsi = [];
  bool isLoading = true;
  String? _roleId;

  /// Real national dashboard payload from GET /api/v1/dashboard/nasional.
  DashboardNasional? _nasionalData;
  bool _isLoadingDashboard = true;

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _roleId = prefs.getString("roleid_login"));
    await getPoldaApi();
    await getDashboardSummary();
  }

  Future<void> getPoldaApi() async {
    if (_roleId != "3") {
      if (!mounted) return;
      setState(() => isLoading = false);
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      // print("ini token ${token}");
      final response = await http.get(
        Uri.parse("$apiBaseUrl/api/v1/polda"),
        headers: {"authorization": token.toString()},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final rawList = json["data"] as List;
        final parsed =
            rawList
                .map((e) => Polda.fromJson(e as Map<String, dynamic>))
                .toList();

        final validCount = parsed.where((p) => p.hasValidCoordinates).length;
        debugPrint(
          "Polda fetched: ${parsed.length} total, $validCount with valid coordinates",
        );

        if (validCount == 0 && parsed.isNotEmpty) {
          debugPrint(
            "WARNING: All ${parsed.length} Polda have (0,0) coordinates. "
            "API may not be returning latitude/longitude fields.",
          );
        }

        setState(() {
          provinsi = parsed;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      debugPrint(e.toString());
    }
  }

  /// Fetches the national dashboard payload (ringkasan + peta nodes +
  /// sitkamtibmas terkini) for the Command Center map.
  Future<void> getDashboardSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final response = await http.get(
        Uri.parse("$apiBaseUrl/api/v1/dashboard/nasional"),
        headers: {"authorization": token.toString()},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          _nasionalData = DashboardNasional.fromJson(json["data"]);
          _isLoadingDashboard = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoadingDashboard = false);
      }
    } catch (e) {
      debugPrint("getDashboardSummary error: $e");
      if (!mounted) return;
      setState(() => _isLoadingDashboard = false);
    }
  }

  /// Fetches per-polda drill-down aggregates for the marker popup.
  /// Throws on non-200 so the FutureBuilder surfaces the error state.
  Future<DashboardDrilldown> _fetchDrilldown(int poldaId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final response = await http.get(
      Uri.parse(
        "$apiBaseUrl/api/v1/dashboard/drilldown?polda_id=$poldaId",
      ),
      headers: {"authorization": token.toString()},
    );
    if (response.statusCode != 200) {
      throw Exception("drilldown HTTP ${response.statusCode}");
    }
    final json = jsonDecode(response.body);
    return DashboardDrilldown.fromJson(json["data"]);
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentRoute: 'dashboard',
      // Executive Command Center: full-screen map without the standard
      // header/footer chrome (the map owns its own overlays).
      showHeaderFooter: false,
      child: _roleId == "3" ? _buildCommandCenterContent() : _buildPlaceholder(),
    );
  }

  Widget _buildCommandCenterContent() {
    if (_isLoadingDashboard) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.cyanAccent),
      );
    }

    final petaNodes = _nasionalData?.peta ?? const <PetaNode>[];
    if (petaNodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map, size: 64, color: Colors.white38),
            const SizedBox(height: 16),
            const Text(
              "Tidak ada data Polda untuk ditampilkan",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              "Periksa koneksi atau hubungi administrator",
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        /// Background Map
        /// Background Map
        Positioned.fill(
          child: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(-2.5, 118.0),
              initialZoom: 4.3,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.sindomon.app',
              ),

              MarkerLayer(
                markers: petaNodes
                    .where((n) => n.hasValidCoordinates)
                    .map((n) {
                      return Marker(
                        point: n.latLng,
                        width: 50,
                        height: 50,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _showDrilldownDialog(n),
                          child: Tooltip(
                            message: n.namaPolda,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        ),

        /// Overlay gelap
        Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: Container(color: Colors.black.withValues(alpha: 0.20)),
          ),
        ),

        /// Logo + Judul
        Positioned(
          top: 20,
          left: 20,
          child: Row(
            children: [
              const Icon(Icons.shield, color: Colors.amber, size: 40),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "SINDOMON - NATIONAL COMMAND CENTER",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  Text(
                    DateTime.now().toString(),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ),

        /// Floating Profile Avatar (Executive)
        Positioned(
          top: 20,
          right: 20,
          child: PopupMenuButton<_ExecAction>(
            offset: const Offset(0, 52),
            tooltip: 'Menu Profil',
            color: const Color(0xff1E1B4B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (action) {
              switch (action) {
                case _ExecAction.pengaturan:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AccountSettingPage(),
                    ),
                  );
                  break;
                case _ExecAction.logout:
                  clearSessionAndLogout(context);
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _ExecAction.pengaturan,
                child: _ExecMenuItem(
                  icon: Icons.settings_rounded,
                  label: 'Pengaturan',
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: _ExecAction.logout,
                child: _ExecMenuItem(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                ),
              ),
            ],
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    border: Border.all(color: Colors.cyanAccent, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ),

        /// KPI Kanan Atas
        Positioned(
          top: 80,
          right: 20,
          child: Container(
            width: 240,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyanAccent),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Total Personel",
                  style: TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 5),

                Text(
                  _formatNumber(
                    _nasionalData?.ringkasan.totalPersonilAktif ?? 0,
                  ),
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                const Text(
                  "Defense Equipment",
                  style: TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 5),

                Text(
                  _defenseEquipmentLabel,
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                const Text(
                  "Vacant Position",
                  style: TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 5),

                Text(
                  _formatNumber(
                    _nasionalData?.ringkasan.selisihKekurangan ?? 0,
                  ),
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        /// Panel kiri bawah
        Positioned(
          left: 20,
          bottom: 20,
          child: Container(
            width: 250,
            height: 120,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Sitkamtibmas Reports",
                  style: TextStyle(color: Colors.white),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: ListView.builder(
                    itemCount:
                        _nasionalData?.sitkamtibmasTerkini.length ?? 0,
                    itemBuilder: (context, index) {
                      final report =
                          _nasionalData?.sitkamtibmasTerkini[index];
                      if (report == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          "• ${report.deskripsiKejadian} "
                          "[${report.levelKritis}]",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        /// KPI bawah tengah
        Positioned(
          bottom: 20,
          left: 300,
          child: Row(
            children: [
              _kpiCard("Active Fleet", "300"),

              const SizedBox(width: 20),

              _kpiCard(
                "K9 Standby",
                _formatNumber(_nasionalData?.ringkasan.totalSatwaK9 ?? 0),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Drill-down popup for a map node. Fetches `/dashboard/drilldown` on open
  /// and renders the real per-polda aggregates once the payload arrives.
  void _showDrilldownDialog(PetaNode node) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xff1E1B4B),
          title: Text(
            node.namaPolda,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: FutureBuilder<DashboardDrilldown>(
            future: _fetchDrilldown(node.poldaId),
            builder: (context, snapshot) {
              // While the drill-down request is in flight.
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 160,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.cyanAccent,
                    ),
                  ),
                );
              }

              final drilldown = snapshot.data;
              if (snapshot.hasError || drilldown == null) {
                return const SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      "Gagal memuat data wilayah.\n"
                      "Periksa koneksi atau hubungi administrator.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                );
              }

              return SizedBox(
                width: 260,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _drilldownRow(
                      "Personel",
                      _formatNumber(drilldown.personil.totalAktif),
                    ),
                    const SizedBox(height: 8),
                    _drilldownRow(
                      "Senjata",
                      _formatNumber(drilldown.logistik.senjata.total),
                    ),
                    const SizedBox(height: 8),
                    _drilldownRow(
                      "Sarpras",
                      _formatNumber(drilldown.logistik.sarpras.total),
                    ),
                    const SizedBox(height: 8),
                    _drilldownRow(
                      "Satwa K9",
                      _formatNumber(drilldown.logistik.satwaK9.total),
                    ),
                    const SizedBox(height: 8),
                    _drilldownRow(
                      "Vakansi",
                      _formatNumber(drilldown.vakansi.selisih),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "📍 ${drilldown.polda.latitude}, "
                      "${drilldown.polda.longitude}",
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                "Tutup",
                style: TextStyle(color: Colors.amber),
              ),
            ),
          ],
        );
      },
    );
  }

  /// One label/value row inside the drill-down dialog.
  Widget _drilldownRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Formats an int with thousands separators: 153500 → "153,500".
  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  /// Calculated readiness percentage (layak / total senjata). Falls back to
  /// "0%" when no weapon data is available yet.
  String get _defenseEquipmentLabel {
    final total = _nasionalData?.ringkasan.totalSenjata ?? 0;
    if (total <= 0) return "0%";
    final layak = _nasionalData?.ringkasan.totalSenjataLayak ?? 0;
    return "${((layak / total) * 100).toStringAsFixed(0)}%";
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(32),
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                "Area Grafik & Statistik",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Segera Hadir",
                style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpiCard(String title, String value) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dropdown row for the executive floating avatar menu (dark themed).
class _ExecMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ExecMenuItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.amber),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ],
    );
  }
}

```

---

## 5. The Mass Migration Script (`scripts/migrate_scaffold.py`)

### Usage

```bash
python3 scripts/migrate_scaffold.py                  # dry-run (default) — prints PASS/FAIL per file
python3 scripts/migrate_scaffold.py --apply          # write the changes
python3 scripts/migrate_scaffold.py --apply --files lib/pages/personel.dart   # single file
# afterwards:
dart format lib/pages lib/widget                    # normalize re-indented content
flutter analyze                                     # final gate
```

### Transform pipeline (per file)

1. **Imports** — drop `background.dart` / `app_sidebar.dart` / `app_footer.dart` /
   `app_header.dart`; add `app_scaffold.dart` (and `session_util.dart` when the file
   still calls `roleLabelFromId`).
2. **`roleLabelFromId` rewrite** — `AppSidebar.roleLabelFromId(` → `roleLabelFromId(`.
3. **Boilerplate cut** — regex matches the uniform head of the build method
   (`return Scaffold(` … `AppHeader(...,),`), then a **delimiter scanner** (string- and
   comment-aware, handles Dart `$`-interpolation with nested quotes) walks the real code
   to find:
   - the outer `children: [` of the content Column (bracket scan), and
   - the matching `);` of the `return Scaffold(` statement (paren scan).
   The content between AppHeader and AppFooter is kept verbatim (re-indented); the
   `AppFooter` widget is removed; the AppScaffold wrapper is emitted. Because the cut is
   computed by scanning, pages with extra nesting (the `else ...[ ... ]` spread lists in
   `personel.dart`, `polda.dart`, …) work without hardcoding closing-bracket counts.
4. **Post-checks** — no leftover `AppBackground/AppHeader/AppFooter/AppSidebar`
   references, `AppScaffold(` present, and full-file `() [] {}` balance after stripping
   strings/comments. Any failure leaves the file untouched and reports it.

### Variants handled

| Variant | Files | Behavior |
|---|---|---|
| Standard (header + footer) | 19 pages | `AppScaffold(currentRoute:, breadcrumb:, child: Column(...))` |
| Placeholder (no chrome) | `placeholder_page.dart` | `AppScaffold(currentRoute: routeName, showHeaderFooter: false, child: Center(...))` |
| Conditional breadcrumb | `add_amunisi`, `add_personel`, `add_polda`, `add_polres`, `add_sarpras`, `add_satwa`, `add_senjata`, `add_user` | `breadcrumb: widget.xId != null ? "Edit …" : "Tambah …"` extracted & normalized to one line |
| `roleLabelFromId` in DataTable | `user_page.dart` | rewritten to shared util + `session_util` import |

### Execution result

```
OK: 20   FAILED: 0   mode: APPLY
```

Every transformed file passed: balance check, leftover-reference check, import checks.

### Complete script

```python
#!/usr/bin/env python3
"""
Mass-transplant: strip the legacy `Row > AppSidebar` boilerplate from
standard pages and wrap their content in `AppScaffold`.

The transform is fully mechanical and verified per file:
  1. Drop the legacy widget imports (background / app_sidebar / app_footer /
     app_header) and add `app_scaffold.dart`.
  2. Rewrite `AppSidebar.roleLabelFromId(` -> `roleLabelFromId(` (now living
     in `utils/session_util.dart`) and ensure that import exists.
  3. Replace the `Scaffold > AppBackground > SafeArea > Row > [Sidebar,
     Expanded > Padding(30) > Column(start) > [AppHeader, ..., AppFooter]]`
     block with a single `AppScaffold(currentRoute:, breadcrumb:, child:)`
     call. Instead of assuming a fixed closing-bracket sequence, a small
     delimiter scanner walks the real code (skipping strings/comments) and
     cuts exactly at the matching `);` of the `return Scaffold(` statement,
     so pages with extra nesting (e.g. `else ...[ ... ]` lists) work too.
  4. Post-checks per file: no leftover references to the removed widgets,
     balanced () [] {}, and the new import present. Failures leave the file
     untouched and are reported.

Usage:
    python3 scripts/migrate_scaffold.py                  # dry-run (default)
    python3 scripts/migrate_scaffold.py --apply          # write changes
    python3 scripts/migrate_scaffold.py --apply --files lib/pages/personel.dart

After running with --apply:
    dart format lib/pages lib/widget   # normalize the re-indented content
    flutter analyze                    # final gate
"""

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PAGES = ROOT / "lib" / "pages"

# All sidebar pages still on the legacy layout. dashboard.dart, pangaturan.dart
# and login_page.dart are already handled (or not applicable) and excluded.
TARGETS = [
    "add_amunisi.dart",
    "add_inventaris_page.dart",
    "add_personel_page.dart",
    "add_polda.dart",
    "add_polres.dart",
    "add_sarpras.dart",
    "add_satwa.dart",
    "add_senjata.dart",
    "add_user.dart",
    "amunisi.dart",
    "inventaris.dart",
    "master_kategori_senjata.dart",
    "personel.dart",
    "placeholder_page.dart",
    "polda.dart",
    "polres.dart",
    "sarpras.dart",
    "satwa.dart",
    "senjata.dart",
    "user_page.dart",
]

REMOVE_IMPORTS = [
    "import '../widget/background.dart';",
    "import '../widget/app_sidebar.dart';",
    "import '../widget/app_footer.dart';",
    "import '../widget/app_header.dart';",
]

# Whitespace that may include `//` comment lines (the "/// CONTENT" banners).
_WS = r"\s*(?://[^\n]*\n\s*)*"

# Standard pages — matches the uniform HEAD of the build method, up to and
# including the closing `),` of the AppHeader block. Everything after is
# located with the delimiter scanner (nesting-agnostic).
_PAT_STANDARD = re.compile(
    r"return Scaffold\("
    + _WS
    + r"body: AppBackground\("
    + _WS
    + r"imagePath: 'assets/images/wp-putih-mabes\.png',"
    + _WS
    + r"child: SafeArea\("
    + _WS
    + r"child: Row\("
    + _WS
    + r"children: \["
    + _WS
    + r"(?:const\s+)?AppSidebar\(currentRoute: (?P<route>[^)]+)\),"
    + _WS
    + r"Expanded\("
    + _WS
    + r"child: Padding\("
    + _WS
    + r"padding: const EdgeInsets\.all\(30\),"
    + _WS
    + r"child: Column\("
    + _WS
    + r"crossAxisAlignment: CrossAxisAlignment\.start,"
    + _WS
    + r"children: (?P<list>\[)"
    + _WS
    + r"AppHeader\("
    + _WS
    + r"breadcrumb:\s*(?P<bc>.*?),\s*username:"
    + _WS
    + r"[^,\n]+,\s*role:"
    + _WS
    + r"[^,\n]+,\s*\),",
    re.DOTALL,
)

# Placeholder pages (no header/footer): content is Expanded > child widget.
_PAT_PLACEHOLDER = re.compile(
    r"return Scaffold\("
    + _WS
    + r"body: AppBackground\("
    + _WS
    + r"imagePath: 'assets/images/wp-putih-mabes\.png',"
    + _WS
    + r"child: SafeArea\("
    + _WS
    + r"child: Row\("
    + _WS
    + r"children: \["
    + _WS
    + r"AppSidebar\(currentRoute: (?P<route>[^)]+)\),"
    + _WS
    + r"Expanded\("
    + _WS
    + r"child:\s*",
    re.DOTALL,
)


def _skip_string(text: str, i: int) -> int:
    """Skip a '...' or \"...\" literal starting at i; returns index after it.
    Handles escapes, raw newlines, and Dart string interpolation `${...}`
    (including nested quoted strings inside the interpolation)."""
    quote = text[i]
    j = i + 1
    n = len(text)
    while j < n:
        c = text[j]
        if c == "\\":
            j += 2
            continue
        if c == quote:
            return j + 1
        if c == "$" and j + 1 < n and text[j + 1] == "{":
            # Interpolation: scan until the matching '}'.
            depth = 1
            j += 2
            while j < n and depth > 0:
                cc = text[j]
                if cc in "'\"":
                    j = _skip_string(text, j)
                    continue
                if cc == "{":
                    depth += 1
                elif cc == "}":
                    depth -= 1
                j += 1
            continue
        if c == "\n":  # unterminated (raw newline) — bail out
            return j
        j += 1
    return j


def _scan_matching(text: str, open_pos: int, open_ch: str) -> int:
    """Given the index of an opening '[' or '(', return the index of its
    matching closer, skipping string literals and comments."""
    close_ch = "]" if open_ch == "[" else ")"
    depth = 1
    i = open_pos + 1
    n = len(text)
    while i < n:
        c = text[i]
        if c in "'\"":
            i = _skip_string(text, i)
            continue
        if c == "/" and i + 1 < n and text[i + 1] == "/":
            j = text.find("\n", i)
            i = n if j == -1 else j
            continue
        if c == "/" and i + 1 < n and text[i + 1] == "*":
            j = text.find("*/", i + 2)
            i = n if j == -1 else j + 2
            continue
        if c == open_ch:
            depth += 1
        elif c == close_ch:
            depth -= 1
            if depth == 0:
                return i
        i += 1
    raise ValueError("unbalanced: no matching %r for position %d" % (close_ch, open_pos))


def _reindent(block: str, indent: int = 6) -> str:
    """Strip the common leading indentation and re-indent at `indent` spaces.
    Safe here because the pages contain no multi-line string literals."""
    lines = block.split("\n")
    indents = [len(l) - len(l.lstrip(" ")) for l in lines if l.strip()]
    base = min(indents) if indents else 0
    out = []
    for l in lines:
        if l.strip():
            out.append(" " * indent + l[base:])
        else:
            out.append("")
    return "\n".join(out)


def _strip_strings_comments(src: str) -> str:
    """Single-pass strip of strings and comments (order-safe: comments inside
    strings like 'https://' are never touched, and Dart `${...}` interpolation
    with nested quotes is handled by [_skip_string])."""
    out = []
    i = 0
    n = len(src)
    while i < n:
        c = src[i]
        if c == "/" and i + 1 < n and src[i + 1] == "/":
            j = src.find("\n", i)
            i = n if j == -1 else j
            continue
        if c == "/" and i + 1 < n and src[i + 1] == "*":
            j = src.find("*/", i + 2)
            i = n if j == -1 else j + 2
            continue
        if c in "'\"":
            i = _skip_string(src, i)
            out.append("''")
            continue
        out.append(c)
        i += 1
    return "".join(out)


def _balanced(src: str) -> bool:
    s = _strip_strings_comments(src)
    for a, b in [("(", ")"), ("[", "]"), ("{", "}")]:
        if s.count(a) != s.count(b):
            return False
    return True


def _transform(text: str) -> tuple[str | None, str | None]:
    """Return (new_text, error). error is set when the file does not match."""
    original = text

    # 1. Drop legacy imports.
    lines = [l for l in text.split("\n") if l.strip() not in REMOVE_IMPORTS]
    text = "\n".join(lines)

    # 2. Rewrite roleLabelFromId references to the shared util.
    had_label_ref = "AppSidebar.roleLabelFromId(" in text
    text = text.replace("AppSidebar.roleLabelFromId(", "roleLabelFromId(")

    # 3. Locate the `return Scaffold(` statement boundaries.
    sm = re.search(r"return Scaffold\(", text)
    if not sm:
        return original, "no `return Scaffold(` found"
    stmt_open = sm.end() - 1  # the '(' of Scaffold(
    try:
        stmt_close = _scan_matching(text, stmt_open, "(")  # the ')' of ');'
    except ValueError as e:
        return original, str(e)
    if text[stmt_close + 1 : stmt_close + 2] != ";":
        return original, "statement not terminated by ');'"

    # 4. Match the head variant and cut the boilerplate.
    m = _PAT_STANDARD.search(text)
    if m:
        route = m.group("route").strip()
        bc = " ".join(m.group("bc").split())
        list_open = m.start("list")  # outer Column children '['
        try:
            list_close = _scan_matching(text, list_open, "[")
        except ValueError as e:
            return original, str(e)
        if list_close > stmt_close:
            return original, "outer children list extends past Scaffold close"
        # Everything from after the AppHeader to the outer list close, minus
        # the AppFooter widget (inner `],` closers stay where they belong).
        content = text[m.end() : list_close]
        content = re.sub(
            r"\s*(?:const\s+)?AppFooter\(\),", "", content, count=1
        ).strip("\n")
        replacement = (
            "return AppScaffold(\n"
            f"  currentRoute: {route},\n"
            f"  breadcrumb: {bc},\n"
            "  child: Column(\n"
            "    crossAxisAlignment: CrossAxisAlignment.start,\n"
            "    children: [\n"
            f"{_reindent(content)}\n"
            "    ],\n"
            "  ),\n"
            ");"
        )
        cut_start = m.start()
    else:
        m = _PAT_PLACEHOLDER.search(text)
        if not m:
            return original, "no matching Scaffold boilerplate (standard or placeholder)"
        route = m.group("route").strip()
        # The child widget of Expanded ends right before Expanded's ')'.
        # rfind returns the 'E' of "Expanded(" — shift to the '(' itself.
        expanded_open = (
            text.rfind("Expanded(", m.start(), m.end()) + len("Expanded(") - 1
        )
        try:
            expanded_close = _scan_matching(text, expanded_open, "(")
        except ValueError as e:
            return original, str(e)
        widget = text[m.end() : expanded_close].strip()
        if widget.endswith(","):
            # Drop the trailing comma (Expanded's `,`) — the template adds one.
            widget = widget[:-1].rstrip()
        replacement = (
            "return AppScaffold(\n"
            f"  currentRoute: {route},\n"
            "  showHeaderFooter: false,\n"
            f"  child: {_reindent(widget)},\n"
            ");"
        )
        cut_start = m.start()

    text = text[:cut_start] + replacement + text[stmt_close + 2 :]

    # 5. Ensure imports.
    needed = []
    if "import '../widget/app_scaffold.dart';" not in text:
        needed.append("import '../widget/app_scaffold.dart';")
    if had_label_ref and "import '../utils/session_util.dart'" not in text:
        needed.append("import '../utils/session_util.dart';")
    if needed:
        import_lines = [i for i, l in enumerate(text.split("\n")) if l.startswith("import ")]
        last = import_lines[-1] if import_lines else 0
        lines = text.split("\n")
        lines[last + 1 : last + 1] = needed
        text = "\n".join(lines)

    # 6. Post-checks.
    leftovers = re.findall(r"\b(AppBackground|AppHeader|AppFooter|AppSidebar)\b", text)
    if leftovers:
        return original, f"leftover references: {sorted(set(leftovers))}"
    if "AppScaffold(" not in text:
        return original, "AppScaffold( call missing after transform"
    if not _balanced(text):
        return original, "unbalanced () [] {} after transform"

    return text, None


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--apply", action="store_true", help="write changes to disk")
    ap.add_argument(
        "--files",
        nargs="+",
        default=None,
        help="subset of files to process (paths or bare filenames)",
    )
    args = ap.parse_args()

    targets = args.files or TARGETS
    failed = []
    ok = []

    for name in targets:
        path = Path(name)
        if not path.is_absolute():
            path = PAGES / path.name
        if not path.exists():
            failed.append((name, "file not found"))
            continue

        text = path.read_text()
        new_text, error = _transform(text)
        if error:
            failed.append((name, error))
            continue

        if new_text != text:
            if args.apply:
                path.write_text(new_text)
                print(f"PASS  {path.name}  (rewritten)")
            else:
                print(f"PASS  {path.name}  (dry-run, would rewrite)")
            ok.append(name)
        else:
            print(f"SKIP  {path.name}  (no change needed)")
            ok.append(name)

    print("-" * 60)
    print(f"OK: {len(ok)}   FAILED: {len(failed)}   mode: {'APPLY' if args.apply else 'DRY-RUN'}")
    for name, reason in failed:
        print(f"FAIL  {name}: {reason}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())

```

---

## 6. Supporting Change — `roleLabelFromId` in `session_util.dart`

Extracted from `AppSidebar` (kept as a delegating shim for API compatibility):

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/login_page.dart';

/// Maps a persisted `roles_id` (String "1"/"2"/"3") to its display label.
/// Must stay in sync with the keys of `roleMenus` in menu_config.dart.
String roleLabelFromId(String? roleId) {
  switch (roleId) {
    case "1": return "Super Admin";
    case "2": return "Operator Polda";
    case "3": return "Command Center";
    default: return "Operator";
  }
}

/// Clears the persisted session (all SharedPreferences keys) and navigates
/// back to the [LoginPage], removing every route from the stack.
Future<void> clearSessionAndLogout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  if (!context.mounted) return;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => const LoginPage()),
    (route) => false,
  );
}

```

```dart
// in app_sidebar.dart — delegates, so callers keep working:
static String roleLabelFromId(String? roleId) => session.roleLabelFromId(roleId);
```

---

## 7. Verification

- ✅ Mechanical checks on all 20 script-transformed files (balance, imports, leftovers).
- ✅ `review` subagent pass over the full diff: **no blocking issues**; structure sound,
  no double padding, no `Expanded` misuse, placeholder/exec layouts preserved.
- ⚠️ `flutter analyze` / `dart format` NOT run — no Flutter/Dart SDK in this environment.
  Run both on a dev machine before merging (formatting is the only cosmetic gap — the
  migrated content blocks are re-indented but not yet `dart format`-clean).
- Note: pages keep their (now redundant) `loadUser()`/`unLogin`/`roleLabel` state — public
  fields, so no analyzer warnings; harmless. Cleanup is a follow-up, not part of this phase.

---

## 8. What's Next (Phase 3+)

1. `dart format lib/` + `flutter analyze` on a dev machine; smoke-test hover expand/glass.
2. Optional cleanup: remove per-page `loadUser()` dead code.
3. Optional: pin the rail open (persist `isExpanded`), keyboard shortcut, or `NavigationRail`
   semantics — not required by the specs.
