import 'package:flutter/material.dart';
import '../widget/background.dart';
import '../widget/form_input_senjata.dart';
import '../widget/app_footer.dart';
import '../pages/pangaturan.dart';
import '../pages/dashboard.dart';
import '../pages/report.dart';
import '../pages/user_page.dart';
import '../pages/satwa.dart';
import '../pages/senjata.dart';
import '../pages/personel.dart';
import '../pages/inventaris.dart';
import '../pages/login_page.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';

class AddSenjataPage extends StatefulWidget {
  const AddSenjataPage({super.key});

  @override
  State<AddSenjataPage> createState() => _AddSenjataPageState();
}

class _AddSenjataPageState extends State<AddSenjataPage> {
  String unLogin = "";

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      unLogin = prefs.getString("username_login") ?? "";
    });
  }

  @override
  void initState() {
    super.initState();
    loadUser();
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

                    /// Logo
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      child: const Icon(
                        Icons.security,
                        color: Colors.amber,
                        size: 38,
                      ),
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
                      "Management System",
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
                          menu(Icons.dashboard_rounded, "Dashboard"),
                          menu(Icons.description_rounded, "Laporan"),
                          menu(Icons.map_rounded, "Wilayah"),
                          menu(Icons.inventory_2_rounded, "Inventaris"),
                          menu(Icons.groups_rounded, "Organisasi"),
                          menu(Icons.pets_rounded, "Satwa"),
                          menu(Icons.gavel_rounded, "Senjata", selected: true),
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// ============================
                      /// HEADER
                      /// ============================
                      Container(
                        height: 75,
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.black26),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                color: Colors.white.withValues(alpha: 0.18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: const Icon(
                                      Icons.home_rounded,
                                      color: Colors.amber,
                                      size: 28,
                                    ),
                                  ),

                                  const SizedBox(width: 15),

                                  const Expanded(
                                    child: Text(
                                      "Dashboard / Tambah Senjata",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 20),

                                  SizedBox(
                                    width: 250,
                                    height: 45,
                                    child: TextField(
                                      decoration: InputDecoration(
                                        hintText: "Cari Menu...",
                                        prefixIcon: const Icon(Icons.search),
                                        filled: true,
                                        fillColor: Colors.white.withValues(
                                          alpha: 0.15,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 20),

                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.15,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      onPressed: () {},
                                      icon: const Icon(
                                        Icons.notifications_none,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 15),

                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                        width: 2,
                                      ),
                                    ),
                                    child: const CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.amber,
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        unLogin,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        "Super Admin",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      /// ============================
                      /// TITLE
                      /// ============================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Pengaturan Senjata",
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text("Kembali"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      /// ============================
                      /// FORM
                      /// ============================
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(25),
                              child: FormTambahSenjata(),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const AppFooter(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

              default:
                page = const DashboardPage();
            }

            Navigator.push(context, MaterialPageRoute(builder: (_) => page));
          },
        ),
      ),
    );
  }
}
