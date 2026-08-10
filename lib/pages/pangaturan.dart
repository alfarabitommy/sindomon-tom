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
