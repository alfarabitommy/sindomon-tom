import 'package:flutter/material.dart';
import '../widget/background.dart';
import '../pages/pangaturan.dart';
import '../pages/user_page.dart';
import '../pages/report.dart';
import '../pages/satwa.dart';
import '../pages/senjata.dart';
import '../pages/personel.dart';
import '../pages/inventaris.dart';
import '../pages/polda.dart';
import '../pages/polres.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../pages/login_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Map<String, dynamic>> provinsi = [];
  bool isLoading = true;
  String? _roleId;

  Future<void> getPoldaApi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      // print("ini token ${token}");
      final response = await http.get(
        Uri.parse("https://sindomon.yoknusantara.com/api/v1/polda"),
        headers: {"authorization": token.toString()},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        // print("ini json ${json}");
        setState(() {
          provinsi = List<Map<String, dynamic>>.from(json["data"]);
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

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString("roleid_login");
    if (!mounted) return;
    setState(() => _roleId = role);
  }

  @override
  void initState() {
    super.initState();
    getPoldaApi();
    _loadRole();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove("token");
    await prefs.remove("username_login");
    await prefs.remove("polda_login");
    await prefs.remove("roleid_login");
    await prefs.remove("uuid_login");
    await prefs.remove("expired_login");

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        imagePath: 'assets/images/wp-putih-mabes.png',
        child: SafeArea(
          child: Row(
            children: [
              /// ========================
              /// SIDEBAR
              /// ========================
              Container(
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
                      "Management Dashboard",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 30),

                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          if (_roleId != null) ..._buildNewMenuByRole(),
                          const Divider(color: Colors.amber, thickness: 1.5),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              "--- OLD MENU BELOW (DO NOT USE) ---",
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          menu(
                            Icons.dashboard_rounded,
                            "Dashboard",
                            selected: true,
                          ),
                          menu(Icons.description_rounded, "Laporan"),
                          menu(Icons.map_rounded, "Wilayah"),
                          menu(Icons.inventory_2_rounded, "Inventaris"),
                          menu(Icons.groups_rounded, "Organisasi"),
                          menu(Icons.pets_rounded, "Satwa"),
                          menu(Icons.people_alt_rounded, "Polda"),
                          menu(Icons.people_alt_rounded, "Polres"),
                          menu(Icons.gavel_rounded, "Senjata"),
                          menu(Icons.move_to_inbox_rounded, "Kotak Masuk"),
                          menu(Icons.outbox_rounded, "Kotak Keluar"),
                          menu(Icons.badge_rounded, "Personel"),
                          menu(Icons.inventory_rounded, "Stok Amunisi"),
                          menu(Icons.memory_rounded, "Perangkat"),
                          menu(Icons.people_alt_rounded, "Pengguna"),
                        ],
                      ),
                    ),

                    const Divider(
                      color: Colors.white24,
                      indent: 20,
                      endIndent: 20,
                    ),

                    menu(Icons.settings_rounded, "Pengaturan"),
                    menu(Icons.logout_rounded, "Logout"),

                    const SizedBox(height: 20),
                  ],
                ),
              ),

              /// ========================
              /// CONTENT
              /// ========================
              Expanded(
                child: Stack(
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
                            markers:
                                provinsi.map((p) {
                                  return Marker(
                                    point: LatLng(
                                      double.tryParse(
                                            p["latitude"].toString(),
                                          ) ??
                                          0.0,
                                      double.tryParse(
                                            p["longitude"].toString(),
                                          ) ??
                                          0.0,
                                    ),

                                    width: 50,
                                    height: 50,

                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,

                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              backgroundColor: const Color(
                                                0xff1E1B4B,
                                              ),

                                              title: Text(
                                                p["nama_polda"] as String,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),

                                              content: const Text(
                                                "DATA WILAYAH\n\n"
                                                "👮 Personel : 2.450\n"
                                                "📦 Inventaris : 1.200\n"
                                                "🔫 Senjata : 500\n"
                                                "🐕 Satwa : 25\n\n"
                                                "STATUS : AKTIF",
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 15,
                                                ),
                                              ),

                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },

                                                  child: const Text(
                                                    "Tutup",
                                                    style: TextStyle(
                                                      color: Colors.amber,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },

                                      child: Tooltip(
                                        message: p["nama_polda"] as String,

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
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.20),
                        ),
                      ),
                    ),

                    /// Logo + Judul
                    Positioned(
                      top: 20,
                      left: 20,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shield,
                            color: Colors.amber,
                            size: 40,
                          ),
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

                    /// KPI Kanan Atas
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        width: 240,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.cyanAccent),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Total Personel",
                              style: TextStyle(color: Colors.white70),
                            ),

                            SizedBox(height: 5),

                            Text(
                              "153,500",
                              style: TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 15),

                            Text(
                              "Defense Equipment",
                              style: TextStyle(color: Colors.white70),
                            ),

                            SizedBox(height: 5),

                            Text(
                              "97%",
                              style: TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 15),

                            Text(
                              "Vacant Position",
                              style: TextStyle(color: Colors.white70),
                            ),

                            SizedBox(height: 5),

                            Text(
                              "218",
                              style: TextStyle(
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
                        child: ListView(
                          children: const [
                            Text(
                              "Sitkamtibmas Reports",
                              style: TextStyle(color: Colors.white),
                            ),

                            SizedBox(height: 10),

                            Text(
                              "• Laporan 1\n"
                              "• Laporan 2\n"
                              "• Laporan 3\n"
                              "• Laporan 4\n"
                              "• Laporan 5",
                              style: TextStyle(color: Colors.white70),
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

                          _kpiCard("K9 Standby", "140"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNewMenuByRole() {
    switch (_roleId) {
      case "3":
        return [
          _buildNewMenuItem(
            "Command Center Nasional",
            Icons.monitor_heart_rounded,
          ),
        ];
      case "1":
        return [
          _buildExpansionTileGroup(
            "Manajemen Keamanan & Akun",
            Icons.admin_panel_settings,
            [
              _buildNewMenuItem("Daftar Pengguna", Icons.people_alt_rounded),
              _buildNewMenuItem(
                "Binding Perangkat",
                Icons.phonelink_lock_rounded,
              ),
            ],
          ),
          _buildExpansionTileGroup(
            "Master Data Sistem",
            Icons.storage_rounded,
            [
              _buildNewMenuItem("Master Wilayah", Icons.map_rounded),
              _buildNewMenuItem(
                "Master SDM & Organisasi",
                Icons.account_tree_rounded,
              ),
              _buildNewMenuItem("Master Logistik", Icons.warehouse_rounded),
            ],
          ),
        ];
      case "2":
        return [
          _buildExpansionTileGroup("Manajemen SDM", Icons.group_rounded, [
            _buildNewMenuItem(
              "Bagan Organisasi (Org-Tree)",
              Icons.account_tree_rounded,
            ),
            _buildNewMenuItem("Direktori Personel", Icons.badge_rounded),
            _buildNewMenuItem("Pemantauan Proses Hukum", Icons.gavel_rounded),
          ]),
          _buildExpansionTileGroup("Logistik & Aset", Icons.inventory_rounded, [
            _buildNewMenuItem("Inventaris Senjata", Icons.shield_rounded),
            _buildNewMenuItem("Stok Amunisi", Icons.archive_rounded),
            _buildNewMenuItem(
              "Sarpras & Altmatsus",
              Icons.precision_manufacturing_rounded,
            ),
            _buildNewMenuItem("Satwa K9 & Turangga", Icons.pets_rounded),
          ]),
          _buildExpansionTileGroup(
            "Administrasi (DMS)",
            Icons.description_rounded,
            [
              _buildNewMenuItem(
                "Kotak Masuk (Inbox)",
                Icons.move_to_inbox_rounded,
              ),
              _buildNewMenuItem("Kotak Keluar (Outbox)", Icons.outbox_rounded),
            ],
          ),
          _buildExpansionTileGroup(
            "Operasional & Kamtibmas",
            Icons.local_police_rounded,
            [_buildNewMenuItem("Log Sitkamtibmas", Icons.article_rounded)],
          ),
          _buildExpansionTileGroup("Komunikasi Taktis", Icons.chat_rounded, [
            _buildNewMenuItem("Direktori Panggilan (VoIP)", Icons.call_rounded),
            _buildNewMenuItem("Ruang Konferensi", Icons.videocam_rounded),
          ]),
          _buildExpansionTileGroup(
            "Hub Informasi Terpadu",
            Icons.device_hub_rounded,
            [
              _buildNewMenuItem(
                "Perpustakaan Digital",
                Icons.library_books_rounded,
              ),
              _buildNewMenuItem(
                "Pengaduan Masyarakat",
                Icons.report_problem_rounded,
              ),
            ],
          ),
          _buildExpansionTileGroup("Mobile", Icons.phone_android_rounded, [
            _buildNewMenuItem("Status Patroli GPS", Icons.gps_fixed_rounded),
          ]),
        ];
      default:
        return [];
    }
  }

  Widget _buildExpansionTileGroup(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: Colors.white70),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          collapsedIconColor: Colors.white70,
          iconColor: Colors.amber,
          childrenPadding: const EdgeInsets.only(left: 24, bottom: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.white.withValues(alpha: 0.04),
          collapsedBackgroundColor: Colors.transparent,
          children: children,
        ),
      ),
    );
  }

  Widget _buildNewMenuItem(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 20),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      hoverColor: Colors.white10,
      onTap: null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget menu(IconData icon, String title, {bool selected = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? Colors.amber : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: ListTile(
          leading: Icon(icon, color: selected ? Colors.black : Colors.white70),
          title: Text(
            title,
            style: TextStyle(
              color: selected ? Colors.black : Colors.white,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          trailing:
              selected
                  ? const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.black,
                  )
                  : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          hoverColor: Colors.white10,
          onTap: () async {
            if (title == "Logout") {
              await logout();
              return;
            }

            Widget page;

            switch (title) {
              case "Dashboard":
                page = const DashboardPage();
                break;

              case "Pengaturan":
                page = const AccountSettingPage();
                break;

              case "Laporan":
                page = const ReportPage();
                break;

              case "Senjata":
                page = const SenjataPage();
                break;

              case "Satwa":
                page = const SatwaPage();
                break;

              case "Personel":
                page = const PersonelPage();
                break;

              case "Inventaris":
                page = const InventarisPage();
                break;

              case "Pengguna":
                page = const UserPage();
                break;

              case "Polda":
                page = const PoldaPage();
                break;

              case "Polres":
                page = const PolresPage();
                break;

              default:
                page = const DashboardPage();
            }

            Navigator.push(context, MaterialPageRoute(builder: (_) => page));
          },
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
