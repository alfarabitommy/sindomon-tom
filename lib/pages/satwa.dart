import 'package:flutter/material.dart';
import '../widget/background.dart';
import '../widget/app_sidebar.dart';
import '../pages/add_satwa.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widget/app_footer.dart';
import '../widget/app_pagination.dart';
import '../widget/app_header.dart';
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
  String roleLabel = "Operator";
  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      unLogin = prefs.getString("username_login") ?? "";
      roleLabel = AppSidebar.roleLabelFromId(prefs.getString("roleid_login"));
    });
  }

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        imagePath: 'assets/images/wp-putih-mabes.png',
        child: SafeArea(
          child: Row(
            children: [
              const AppSidebar(currentRoute: "satwa"),

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
                        role: roleLabel,
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

}
