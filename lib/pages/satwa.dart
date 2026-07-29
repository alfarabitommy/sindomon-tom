import 'package:flutter/material.dart';
import '../widget/background.dart';
import '../pages/pangaturan.dart';
import '../pages/dashboard.dart';
import '../pages/report.dart';
import '../pages/user_page.dart';
import '../pages/senjata.dart';
import '../pages/personel.dart';
import '../pages/inventaris.dart';
import '../pages/add_satwa.dart';
import '../pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widget/app_header.dart';
import '../widget/app_footer.dart';
import '../widget/app_pagination.dart';
import '../widget/app_search_field.dart';
import '../widget/action_buttons.dart';

class SatwaPage extends StatefulWidget {
  const SatwaPage({super.key});

  @override
  State<SatwaPage> createState() => _SatwaPageState();
}

class _SatwaPageState extends State<SatwaPage> {
  final List<Map<String, dynamic>> listsatwa = [
    {
      "foto_satwa": "",
      "no_registrasi": "1111234567",
      "jenis": "K9",
      "nama": "Sanut Handler",
      "kualifikasi": "Narkotika",
      "jadwal_vaksin": "2025-12-10",
      "status_vaksin": "Sudah",
    },
    {
      "foto_satwa": "",
      "no_registrasi": "1111234567",
      "jenis": "K9",
      "nama": "Sanut Handler",
      "kualifikasi": "Narkotika",
      "jadwal_vaksin": "2025-12-10",
      "status_vaksin": "Sudah",
    },
    {
      "foto_satwa": "",
      "no_registrasi": "1111234567",
      "jenis": "K9",
      "nama": "Sanut Handler",
      "kualifikasi": "Narkotika",
      "jadwal_vaksin": "2025-12-10",
      "status_vaksin": "Sudah",
    },
    {
      "foto_satwa": "",
      "no_registrasi": "1111234567",
      "jenis": "K9",
      "nama": "Sanut Handler",
      "kualifikasi": "Narkotika",
      "jadwal_vaksin": "2025-12-10",
      "status_vaksin": "Sudah",
    },
    {
      "foto_satwa": "",
      "no_registrasi": "1111234567",
      "jenis": "K9",
      "nama": "Sanut Handler",
      "kualifikasi": "Narkotika",
      "jadwal_vaksin": "2025-12-10",
      "status_vaksin": "Sudah",
    },
  ];

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
                          menu(Icons.pets_rounded, "Satwa", selected: true),
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
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppHeader(
                        breadcrumb: "Dashboard / Satwa",
                        username: unLogin,
                        role: "Super Admin",
                      ),
                      const SizedBox(height: 25),

                      /// ============================
                      /// TITLE
                      /// ============================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Manajemen Satwa",
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),

                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddSatwaPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text("Tambah Satwa"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              elevation: 5,
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

                      const SizedBox(height: 20),

                      /// SEARCH
                      AppSearchField(hintText: "Cari Satwa..."),

                      const SizedBox(height: 25),

                      /// TABLE DATA
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        return SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              minWidth: constraints.maxWidth,
                                            ),
                                            child: DataTable(
                                              headingRowColor:
                                                  WidgetStateProperty.all(
                                                    Colors.grey.shade50,
                                                  ),
                                              headingTextStyle: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF6B7280),
                                              ),
                                              dataTextStyle: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                                color: Color(0xFF374151),
                                              ),
                                              dividerThickness: 0.5,
                                              border: const TableBorder(
                                                horizontalInside: BorderSide(
                                                  color: Color(0xFFE5E7EB),
                                                  width: 0.5,
                                                ),
                                              ),
                                              dataRowMinHeight: 60,
                                              dataRowMaxHeight: 70,
                                              columns: const [
                                                DataColumn(
                                                  label: Text("FOTO SATWA"),
                                                ),
                                                DataColumn(
                                                  label: Text("NO REGISTRASI"),
                                                ),
                                                DataColumn(
                                                  label: Text("JENIS"),
                                                ),
                                                DataColumn(label: Text("NAMA")),
                                                DataColumn(
                                                  label: Text("KUALIFIKASI"),
                                                ),
                                                DataColumn(
                                                  label: Text("JADWAL VAKSIN"),
                                                ),
                                                DataColumn(
                                                  label: Text("STATUS VAKSIN"),
                                                ),
                                                DataColumn(label: Text("AKSI")),
                                              ],
                                              rows:
                                                  listsatwa
                                                      .map(
                                                        (e) => DataRow(
                                                          cells: [
                                                            DataCell(
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets.all(
                                                                      8.0,
                                                                    ),
                                                                child: ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        8,
                                                                      ),
                                                                  child: Image.asset(
                                                                    "assets/images/satwa.jpg",
                                                                    width: 80,
                                                                    height: 50,
                                                                    fit:
                                                                        BoxFit
                                                                            .cover,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            DataCell(
                                                              Text(
                                                                e["no_registrasi"],
                                                              ),
                                                            ),
                                                            DataCell(
                                                              Text(e["jenis"]),
                                                            ),
                                                            DataCell(
                                                              Text(
                                                                "${e["nama"]}",
                                                              ),
                                                            ),
                                                            DataCell(
                                                              Text(
                                                                "${e["kualifikasi"]}",
                                                              ),
                                                            ),
                                                            DataCell(
                                                              Text(
                                                                "${e["jadwal_vaksin"]}",
                                                              ),
                                                            ),
                                                            DataCell(
                                                              Text(
                                                                "${e["status_vaksin"]}",
                                                              ),
                                                            ),
                                                            DataCell(
                                                              ActionButtons(
                                                                onEdit: () {},
                                                                onDelete: () {},
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                      .toList(),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const AppPagination(),
                            ],
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
