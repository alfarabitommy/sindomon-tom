import 'package:flutter/material.dart';
import '../widget/background.dart';
import '../widget/app_sidebar.dart';
import '../pages/add_polda.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widget/app_footer.dart';
import '../widget/app_pagination.dart';
import '../widget/app_header.dart';
import '../widget/app_search_field.dart';
import '../widget/action_buttons.dart';

class PoldaPage extends StatefulWidget {
  const PoldaPage({super.key});

  @override
  State<PoldaPage> createState() => _PoldaPageState();
}

class _PoldaPageState extends State<PoldaPage> {
  List<Map<String, dynamic>> polda = [];
  bool isLoading = true;
  String unLogin = "";
  String roleLabel = "Operator";

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      unLogin = prefs.getString("username_login") ?? "";
      roleLabel = AppSidebar.roleLabelFromId(prefs.getString("roleid_login"));
    });
  }

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
          polda = List<Map<String, dynamic>>.from(json["data"]);
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
    getPoldaApi();
  }

  Future<void> deletePolda(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.delete(
        Uri.parse("https://sindomon.yoknusantara.com/api/v1/polda"),
        headers: {
          "Authorization": token.toString(),
          "Content-Type": "application/json",
        },
        body: jsonEncode({"polda_id": id}),
      );

      if (response.statusCode == 200) {
        debugPrint(response.body);
        getPoldaApi();
      } else {
        debugPrint("Error : ${response.body}");
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        imagePath: 'assets/images/wp-putih-mabes.png',
        child: SafeArea(
          child: Row(
            children: [
              const AppSidebar(currentRoute: "polda"),

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
                        breadcrumb: "Dashboard / Polda",
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
                            "Manajemen Polda",
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
                                  builder: (_) => const AddPoldaPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text("Tambah Polda"),
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
                      AppSearchField(hintText: "Cari Polda..."),

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
                                                DataColumn(label: Text("ID")),
                                                DataColumn(
                                                  label: Text("NAMA POLDA"),
                                                ),
                                                DataColumn(
                                                  label: Text("LATITUDE"),
                                                ),
                                                DataColumn(
                                                  label: Text("LONGITUDE"),
                                                ),
                                                DataColumn(
                                                  label: Text("CREATED AT"),
                                                ),
                                                DataColumn(label: Text("AKSI")),
                                              ],
                                              rows:
                                                  polda
                                                      .map(
                                                        (e) => DataRow(
                                                          cells: [
                                                            DataCell(
                                                              Text(e["id"]),
                                                            ),
                                                            DataCell(
                                                              Text(
                                                                e["nama_polda"],
                                                              ),
                                                            ),
                                                            DataCell(
                                                              Text(
                                                                "${e["latitude"]}",
                                                              ),
                                                            ),
                                                            DataCell(
                                                              Text(
                                                                "${e["longitude"]}",
                                                              ),
                                                            ),
                                                            DataCell(
                                                              Text(
                                                                "${e["created_at"]}",
                                                              ),
                                                            ),
                                                            DataCell(
                                                              ActionButtons(
                                                                onEdit: () {},
                                                                onDelete: () async {
                                                                  final result = await showDialog(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (
                                                                          _,
                                                                        ) => AlertDialog(
                                                                          title: const Text(
                                                                            "Hapus Polda",
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
                                                                    deletePolda(
                                                                      int.parse(
                                                                        e["id"],
                                                                      ),
                                                                    );
                                                                  }
                                                                },
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
