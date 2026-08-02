import 'package:flutter/material.dart';
import '../widget/background.dart';
import '../widget/app_sidebar.dart';
import '../config/api_config.dart';
import '../pages/add_user.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widget/app_footer.dart';
import '../widget/app_pagination.dart';
import '../widget/app_header.dart';
import '../widget/app_search_field.dart';
import '../widget/action_buttons.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  List<Map<String, dynamic>> users = [];
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

  Future<void> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse("$apiBaseUrl/api/v1/user"),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        setState(() {
          users = List<Map<String, dynamic>>.from(json["data"]);
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
    getUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        imagePath: 'assets/images/wp-putih-mabes.png',
        child: SafeArea(
          child: Row(
            children: [
              const AppSidebar(currentRoute: "pengguna"),

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
                        breadcrumb: "Dashboard / Pengguna",
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
                            "Manajemen Pengguna",
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
                                  builder: (_) => const AddUserPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text("Tambah Pengguna"),
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
                      AppSearchField(hintText: "Cari Pengguna..."),

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
                                                DataColumn(label: Text("NAMA")),
                                                DataColumn(label: Text("ROLE")),
                                                DataColumn(
                                                  label: Text("POLDA"),
                                                ),
                                                DataColumn(
                                                  label: Text("STATUS"),
                                                ),
                                                DataColumn(label: Text("AKSI")),
                                              ],
                                              rows:
                                                  users
                                                      .map(
                                                        (e) => DataRow(
                                                          cells: [
                                                            DataCell(
                                                              Text(
                                                                e["username"] ??
                                                                    ' - ',
                                                              ),
                                                            ),
                                                            DataCell(
                                                              Text(
                                                                "${e["roles_id"]}",
                                                              ),
                                                            ),
                                                            DataCell(
                                                              Text(
                                                                "${e["polda"] ?? ' - '}",
                                                              ),
                                                            ),
                                                            DataCell(
                                                              Text(
                                                                "${e["status"] ?? ' - '}",
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
