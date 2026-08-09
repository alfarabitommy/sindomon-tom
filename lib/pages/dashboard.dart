import 'package:flutter/material.dart';
import 'dart:ui';
import '../widget/background.dart';
import '../widget/app_sidebar.dart';
import '../config/api_config.dart';
import '../models/dashboard_model.dart';
import '../models/polda_model.dart';
import '../pages/pangaturan.dart';
import '../utils/session_util.dart';
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
    return Scaffold(
      body: AppBackground(
        imagePath: 'assets/images/wp-putih-mabes.png',
        child: SafeArea(
          child: Row(
            children: [
              const AppSidebar(currentRoute: "dashboard"),
              Expanded(
                child:
                    _roleId == "3"
                        ? _buildCommandCenterContent()
                        : _buildPlaceholder(),
              ),
            ],
          ),
        ),
      ),
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
