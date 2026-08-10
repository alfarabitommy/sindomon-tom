import 'dart:async';
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
            options: MapOptions(
              initialCenter: LatLng(-2.5, 118.0),
              initialZoom: 4.3,
              minZoom: 4.0,
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(
                  LatLng(-11.0, 95.0),
                  LatLng(6.0, 141.0),
                ),
              ),
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
                    .map((n) => Marker(
                          point: n.latLng,
                          width: 80,
                          height: 80,
                          child: _HudMarker(
                            node: n,
                            onTap: () => _showDrilldownDialog(n),
                          ),
                        ))
                    .toList(),
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
  /// and renders the real per-polda aggregates inside a HUD-style glass panel.
  void _showDrilldownDialog(PetaNode node) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 120),
        child: _HudDrilldownPanel(
          node: node,
          fetchDrilldown: () => _fetchDrilldown(node.poldaId),
          formatNumber: _formatNumber,
        ),
      ),
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

/* ══════════════════════════════════════════════════════════════════════════
 *  HUD (Sci-Fi) widgets — pulsating radar markers + glass drilldown panel.
 *  Private to this file; uses only Flutter core (no new dependencies).
 * ══════════════════════════════════════════════════════════════════════════ */

/// Pulsating radar-blip marker for the Command Center map.
///
/// Renders two staggered expanding cyan rings (scale 1.0 → 2.5, fading out),
/// a static crosshair, and a glowing core dot. Tap invokes [onTap], which
/// opens the HUD drilldown panel.
class _HudMarker extends StatefulWidget {
  final PetaNode node;
  final VoidCallback onTap;

  const _HudMarker({required this.node, required this.onTap});

  @override
  State<_HudMarker> createState() => _HudMarkerState();
}

class _HudMarkerState extends State<_HudMarker>
    with SingleTickerProviderStateMixin {
  static const Duration _pulseDuration = Duration(milliseconds: 1500);

  late final AnimationController _ctrl;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;
  late final Animation<double> _pulseScale2;
  late final Animation<double> _pulseOpacity2;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: _pulseDuration, vsync: this)
      ..repeat();

    // Primary ring: expands and fades across the whole cycle.
    _pulseScale = Tween<double>(begin: 1.0, end: 2.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );

    // Staggered secondary ring: rests at scale 1.0 for the first 40% of the
    // cycle, then expands so the two rings never move in lockstep.
    _pulseScale2 = Tween<double>(begin: 1.0, end: 2.5).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    _pulseOpacity2 = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Tooltip(
        message: widget.node.namaPolda,
        child: SizedBox(
          width: 80,
          height: 80,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) => Stack(
              alignment: Alignment.center,
              children: [
                // Expanding pulse rings (back to front).
                Transform.scale(
                  scale: _pulseScale.value,
                  child: Opacity(
                    opacity: _pulseOpacity.value,
                    child: _pulseRing(),
                  ),
                ),
                Transform.scale(
                  scale: _pulseScale2.value,
                  child: Opacity(
                    opacity: _pulseOpacity2.value,
                    child: _pulseRing(),
                  ),
                ),
                // Static crosshair arms.
                ..._crosshairLines(),
                // Glowing core dot.
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.cyanAccent,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withValues(alpha: 0.9),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A single thin cyan ring shared by both pulse animations.
  Widget _pulseRing() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.cyanAccent, width: 1.5),
      ),
    );
  }

  /// Four short crosshair arms centered on the 80×80 marker box.
  List<Widget> _crosshairLines() {
    const armLength = 8.0;
    const armThickness = 1.0;
    const half = 40.0; // center of the 80×80 marker box
    final armColor = Colors.cyanAccent.withValues(alpha: 0.5);
    return [
      // Top arm.
      Positioned(
        top: half - armLength,
        left: half - armThickness / 2,
        child: Container(
          width: armThickness,
          height: armLength,
          color: armColor,
        ),
      ),
      // Bottom arm.
      Positioned(
        top: half,
        left: half - armThickness / 2,
        child: Container(
          width: armThickness,
          height: armLength,
          color: armColor,
        ),
      ),
      // Left arm.
      Positioned(
        top: half - armThickness / 2,
        left: half - armLength,
        child: Container(
          width: armLength,
          height: armThickness,
          color: armColor,
        ),
      ),
      // Right arm.
      Positioned(
        top: half - armThickness / 2,
        left: half,
        child: Container(
          width: armLength,
          height: armThickness,
          color: armColor,
        ),
      ),
    ];
  }
}

/// HUD glass panel shown when a map marker is tapped.
///
/// Starts the drilldown request in [initState] and renders one of three
/// states inside the same chrome: loading, error, or the tactical readout.
class _HudDrilldownPanel extends StatefulWidget {
  final PetaNode node;
  final Future<DashboardDrilldown> Function() fetchDrilldown;
  final String Function(int) formatNumber;

  const _HudDrilldownPanel({
    required this.node,
    required this.fetchDrilldown,
    required this.formatNumber,
  });

  @override
  State<_HudDrilldownPanel> createState() => _HudDrilldownPanelState();
}

class _HudDrilldownPanelState extends State<_HudDrilldownPanel> {
  late final Future<DashboardDrilldown> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.fetchDrilldown();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.60),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.cyanAccent.withValues(alpha: 0.55),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withValues(alpha: 0.12),
                blurRadius: 14,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HudTitleBar(
                title: widget.node.namaPolda,
                onClose: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 12),
              const _HudDivider(),
              const SizedBox(height: 4),
              FutureBuilder<DashboardDrilldown>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return _buildLoading();
                  }
                  final drilldown = snapshot.data;
                  if (snapshot.hasError || drilldown == null) {
                    return _buildError();
                  }
                  return _buildDataRows(drilldown);
                },
              ),
              const SizedBox(height: 8),
              const _HudDivider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.my_location,
                    size: 12,
                    color: Colors.white38,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "${widget.node.latitude}, ${widget.node.longitude}",
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// HUD-styled loading state.
  Widget _buildLoading() {
    return const SizedBox(
      height: 140,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.cyanAccent),
            SizedBox(height: 12),
            Text(
              "MEMUAT DATA...",
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// HUD-styled error state.
  Widget _buildError() {
    return SizedBox(
      height: 140,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.cyanAccent,
              size: 36,
            ),
            const SizedBox(height: 10),
            const Text(
              "GAGAL MEMUAT",
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Periksa koneksi atau hubungi administrator.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// Tactical readout rows for the loaded drilldown payload.
  Widget _buildDataRows(DashboardDrilldown drilldown) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HudDrilldownRow(
          label: "Personel",
          value: widget.formatNumber(drilldown.personil.totalAktif),
        ),
        const _HudDivider(),
        _HudDrilldownRow(
          label: "Senjata",
          value: widget.formatNumber(drilldown.logistik.senjata.total),
        ),
        const _HudDivider(),
        _HudDrilldownRow(
          label: "Sarpras",
          value: widget.formatNumber(drilldown.logistik.sarpras.total),
        ),
        const _HudDivider(),
        _HudDrilldownRow(
          label: "Satwa K9",
          value: widget.formatNumber(drilldown.logistik.satwaK9.total),
        ),
        const _HudDivider(),
        _HudDrilldownRow(
          label: "Vakansi",
          value: widget.formatNumber(drilldown.vakansi.selisih),
        ),
      ],
    );
  }
}

/// HUD title bar: uppercase Polda name + tech close button.
class _HudTitleBar extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _HudTitleBar({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.shield_outlined, size: 18, color: Colors.cyanAccent),
        const SizedBox(width: 8),
        Expanded(
          child: _HudMarqueeText(
            text: title.toUpperCase(),
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        IconButton(
          onPressed: onClose,
          tooltip: 'Tutup',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.close, color: Colors.cyanAccent, size: 20),
        ),
      ],
    );
  }
}

/// One label/value pair of the tactical readout.
class _HudDrilldownRow extends StatelessWidget {
  final String label;
  final String value;

  const _HudDrilldownRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Thin cyan tactical separator line.
class _HudDivider extends StatelessWidget {
  const _HudDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: Colors.cyanAccent.withValues(alpha: 0.25),
    );
  }
}

/// HUD auto-scrolling text (native marquee, zero external packages).
///
/// Renders [text] statically when it fits the available width. When the text
/// overflows, it waits [pauseBeforeScroll], then runs a seamless, infinitely
/// looping scroll using only core Flutter primitives: a [TextPainter] width
/// measurement, an [AnimationController] with a linear curve, and a
/// [Transform.translate] shifting two side-by-side copies of the text inside
/// a [ClipRect]. Because the second copy lands exactly where the first copy
/// started when the controller wraps from 1.0 back to 0.0, the loop has no
/// visible jump.
class _HudMarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  /// Idle time before the continuous scroll loop begins.
  final Duration pauseBeforeScroll;

  /// Horizontal gap between the two scrolling copies.
  final double gapBetweenCopies;

  /// Scroll speed in logical pixels per second.
  final double scrollSpeed;

  const _HudMarqueeText({
    required this.text,
    required this.style,
    this.pauseBeforeScroll = const Duration(milliseconds: 1500),
    this.gapBetweenCopies = 40,
    this.scrollSpeed = 30,
  });

  @override
  State<_HudMarqueeText> createState() => _HudMarqueeTextState();
}

class _HudMarqueeTextState extends State<_HudMarqueeText>
    with SingleTickerProviderStateMixin {
  /// Key attached to the rendered content so its laid-out width can be
  /// measured after the first frame.
  final GlobalKey _containerKey = GlobalKey();

  late final AnimationController _controller;
  Timer? _startTimer;

  double _textWidth = 0;
  double _lineHeight = 0;
  double _containerWidth = 0;
  bool _needsMarquee = false;
  bool _measured = false;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndStart());
  }

  @override
  void didUpdateWidget(_HudMarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
      // Text or style changed: cancel any pending scroll and re-measure.
      _startTimer?.cancel();
      _controller
        ..stop()
        ..value = 0;
      _measured = false;
      _containerWidth = 0;
      _needsMarquee = false;
      _retryCount = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndStart());
    }
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Measures the laid-out container width (via the render box) and the
  /// full unclipped text width (via [TextPainter]), then starts the marquee
  /// loop when the text overflows the container.
  void _measureAndStart() {
    if (!mounted) return;

    final renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      // First frame may not be laid out yet — retry on the next frame.
      if (_retryCount++ < 5) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndStart());
      }
      return;
    }

    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();

    if (!mounted) return;

    setState(() {
      _textWidth = textPainter.width;
      _lineHeight = textPainter.height;
      _containerWidth = renderBox.size.width;
      _needsMarquee = _textWidth > _containerWidth;
      _measured = true;
    });

    if (!_needsMarquee) return;

    // Scale the cycle duration with the travelled distance so longer names
    // keep a constant, deliberate HUD scroll speed.
    final totalWidth = _textWidth + widget.gapBetweenCopies;
    final durationMs =
        ((totalWidth / widget.scrollSpeed) * 1000).round().clamp(1500, 12000);
    _controller.duration = Duration(milliseconds: durationMs);

    _startTimer = Timer(widget.pauseBeforeScroll, () {
      if (mounted) _controller.repeat();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_measured || !_needsMarquee) {
      // Static path: text fits (or measurement is still pending).
      return Text(
        widget.text,
        key: _containerKey,
        maxLines: 1,
        softWrap: false,
        style: widget.style,
      );
    }

    // Marquee path: two copies, shifted by the linear controller value.
    // totalWidth is the distance travelled per cycle, so when the controller
    // wraps back to 0.0 the second copy occupies the first copy's exact
    // starting position — a seamless infinite loop.
    final totalWidth = _textWidth + widget.gapBetweenCopies;

    return SizedBox(
      key: _containerKey,
      height: _lineHeight,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return OverflowBox(
              alignment: Alignment.centerLeft,
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: Transform.translate(
                offset: Offset(-_controller.value * totalWidth, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.text,
                      maxLines: 1,
                      softWrap: false,
                      style: widget.style,
                    ),
                    SizedBox(width: widget.gapBetweenCopies),
                    Text(
                      widget.text,
                      maxLines: 1,
                      softWrap: false,
                      style: widget.style,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
