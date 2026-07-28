import 'package:flutter/material.dart';
import '../widget/background.dart';
import '../pages/pangaturan.dart';
import '../pages/dashboard.dart';
import '../pages/report.dart';
import '../pages/user_page.dart';
import '../pages/satwa.dart';
import '../pages/senjata.dart';
import '../pages/inventaris.dart';
import '../pages/add_polres.dart';
import '../pages/personel.dart';
import '../pages/polda.dart';
import '../pages/login_page.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PolresPage extends StatefulWidget {
  const PolresPage({super.key});

  @override
  State<PolresPage> createState() => _PolresPageState();
}

class _PolresPageState extends State<PolresPage> {
  List<Map<String, dynamic>> polres = [];
  bool isLoading = true;
  String unLogin = "";

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      unLogin = prefs.getString("username_login") ?? "";
    });
  }

  Future<void> getPolresApi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      // print("ini token ${token}");
      final response = await http.get(
        Uri.parse("https://sindomon.yoknusantara.com/api/v1/polres"),
        headers: {"authorization": token.toString()},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        // print("ini json ${json}");
        setState(() {
          polres = List<Map<String, dynamic>>.from(json["data"]);
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
    loadUser();
    getPolresApi();
  }

  Future<void> deletePolres(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.delete(
        Uri.parse("https://sindomon.yoknusantara.com/api/v1/polres"),
        headers: {
          "Authorization": token.toString(),
          "Content-Type": "application/json",
        },
        body: jsonEncode({"polres_id": id}),
      );

      if (response.statusCode == 200) {
        debugPrint(response.body);
        getPolresApi();
      } else {
        debugPrint("Error : ${response.body}");
      }
    } catch (e) {
      debugPrint(e.toString());
    }
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
                          menu(Icons.people_alt_rounded, "Polda"),
                          menu(
                            Icons.people_alt_rounded,
                            "Polres",
                            selected: true,
                          ),
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
                                vertical: 18,
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
                                crossAxisAlignment: CrossAxisAlignment.center,
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

                                  // Breadcrumb
                                  const Expanded(
                                    flex: 3,
                                    child: Text(
                                      "Dashboard / Polres",
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

                                  // Search
                                  SizedBox(
                                    width: 250,
                                    height: 45,
                                    child: TextField(
                                      decoration: InputDecoration(
                                        hintText: "Cari Menu...",
                                        hintStyle: const TextStyle(
                                          color: Colors.black54,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.search,
                                          color: Colors.black54,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withValues(
                                          alpha: 0.15,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.white.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.white.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.amber,
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
                                        color: Colors.black87,
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

                                  // Jangan pakai Expanded di sini
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
                                          height: 1.2,
                                        ),
                                      ),
                                      Text(
                                        "Super Admin",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                          height: 1.2,
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
                            "Manajemen Polres",
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
                                  builder: (_) => const AddPolresPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text("Tambah Polres"),
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
                      TextField(
                        decoration: InputDecoration(
                          hintText: "Cari Polres...",
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      /// TABLE DATA
                      Expanded(
                        child: SizedBox(
                          width: double.infinity,
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: constraints.maxWidth,
                                        ),
                                        child: DataTable(
                                          headingTextStyle: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          columns: const [
                                            DataColumn(label: Text("ID")),
                                            DataColumn(label: Text("Polda ID")),
                                            DataColumn(
                                              label: Text("Nama Polres"),
                                            ),
                                            DataColumn(
                                              label: Text("Created At"),
                                            ),
                                            DataColumn(label: Text("AKSI")),
                                          ],
                                          rows:
                                              polres
                                                  .map(
                                                    (e) => DataRow(
                                                      cells: [
                                                        DataCell(Text(e["id"])),
                                                        DataCell(
                                                          Text(e["polda_id"]),
                                                        ),
                                                        DataCell(
                                                          Text(
                                                            "${e["nama_polres"]}",
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Text(
                                                            "${e["created_at"]}",
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Row(
                                                            children: [
                                                              IconButton(
                                                                icon:
                                                                    const Icon(
                                                                      Icons
                                                                          .edit,
                                                                    ),
                                                                onPressed:
                                                                    () {},
                                                              ),
                                                              IconButton(
                                                                icon: const Icon(
                                                                  Icons.delete,
                                                                  color:
                                                                      Colors
                                                                          .red,
                                                                ),
                                                                onPressed: () async {
                                                                  final result = await showDialog(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (
                                                                          _,
                                                                        ) => AlertDialog(
                                                                          title: const Text(
                                                                            "Hapus Polres",
                                                                          ),
                                                                          content: const Text(
                                                                            "Apakah Anda yakin ingin menghapus data ini?",
                                                                          ),
                                                                          actions: [
                                                                            TextButton(
                                                                              onPressed:
                                                                                  () => Navigator.pop(
                                                                                    context,
                                                                                    false,
                                                                                  ),
                                                                              child: const Text(
                                                                                "Batal",
                                                                              ),
                                                                            ),
                                                                            ElevatedButton(
                                                                              onPressed:
                                                                                  () => Navigator.pop(
                                                                                    context,
                                                                                    true,
                                                                                  ),
                                                                              child: const Text(
                                                                                "Hapus",
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                  );

                                                                  if (result ==
                                                                      true) {
                                                                    deletePolres(
                                                                      int.parse(
                                                                        e["id"],
                                                                      ),
                                                                    );
                                                                  }
                                                                },
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                  .toList(),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// ============================
                      /// FOOTER
                      /// ============================
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black26),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "© 2026 SINDOMON Management System. All rights reserved.",
                              style: TextStyle(
                                color: Colors.black26.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              "v1.0.0",
                              style: TextStyle(
                                color: Colors.amber.withValues(alpha: 0.8),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
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

              case "Polda":
                page = const PoldaPage();
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
