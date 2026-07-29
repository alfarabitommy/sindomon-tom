import 'package:flutter/material.dart';
import '../widget/background.dart';
import '../widget/app_sidebar.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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

  @override
  void initState() {
    super.initState();
    getPoldaApi();
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
