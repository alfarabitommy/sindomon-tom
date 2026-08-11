import 'dart:async';

import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../pages/add_user.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widget/app_pagination.dart';
import '../widget/app_search_field.dart';
import '../widget/action_buttons.dart';
import '../widget/app_scaffold.dart';
import '../widget/glass_surface.dart';
import '../utils/session_util.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;

  /// ========================
  /// SEARCH & PAGINATION STATE
  /// ========================
  String _searchQuery = "";
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _perPage = 10;

  Future<void> getUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      Uri uri = Uri.parse("$apiBaseUrl/api/v1/user");
      final Map<String, String> params = {
        "page": _currentPage.toString(),
        "limit": _perPage.toString(),
      };
      if (_searchQuery.isNotEmpty) {
        params["search"] = _searchQuery;
      }
      uri = uri.replace(queryParameters: params);

      final response = await http.get(
        uri,
        headers: {"Authorization": token.toString()},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json["data"];
        // New backend shape: { data: { items: [...], pagination: {...} } }.
        // Tolerates the legacy flat-list shape as a fallback.
        final List rawList = data is Map
            ? (data["items"] is List ? data["items"] as List : [])
            : (data is List ? data : []);
        final Map<String, dynamic> pagination = data is Map &&
                data["pagination"] is Map
            ? data["pagination"] as Map<String, dynamic>
            : <String, dynamic>{};
        final List<Map<String, dynamic>> parsed =
            rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();

        setState(() {
          users = parsed;
          _currentPage =
              (pagination["current_page"] as num?)?.toInt() ?? _currentPage;
          _totalPages =
              (pagination["last_page"] as num?)?.toInt() ??
              (pagination["total_pages"] as num?)?.toInt() ??
              1;
          _totalItems =
              (pagination["total"] as num?)?.toInt() ?? parsed.length;
          _perPage =
              (pagination["per_page"] as num?)?.toInt() ??
              (pagination["limit"] as num?)?.toInt() ??
              _perPage;
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

  Future<void> deleteUser(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.delete(
        Uri.parse("$apiBaseUrl/api/v1/user/$id"),
        headers: {
          "Authorization": token.toString(),
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(result["message"] ?? "Pengguna berhasil dihapus"),
            backgroundColor: Colors.green,
          ),
        );
        getUsers(); // refresh list
      } else {
        final result = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(result["message"] ?? "Gagal menghapus pengguna"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Terjadi kesalahan jaringan"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    getUsers();
  }

  /// Debounced search: waits 400ms of idle typing before hitting the API,
  /// and always resets to page 1 so results start from the beginning.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchQuery = value;
      _currentPage = 1;
      getUsers();
    });
  }

  void _onPageChanged(int page) {
    if (page < 1 || page > _totalPages || page == _currentPage) return;
    _currentPage = page;
    getUsers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
  currentRoute: "pengguna",
  breadcrumb: "Dashboard / Pengguna",
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 25),

      /// ============================
      /// TITLE
      /// ============================
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Manajemen Pengguna",
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),

          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddUserPage(),
                ),
              ).then((result) {
                if (result == true) {
                  getUsers();
                }
              });
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
      AppSearchField(
        hintText: "Cari Pengguna...",
        controller: _searchController,
        onChanged: _onSearchChanged,
      ),

      const SizedBox(height: 25),

      /// TABLE DATA
      Expanded(
        child: GlassSurface(
          borderRadius: BorderRadius.circular(12),
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
                              headingRowColor: WidgetStateProperty.all(
                                isDark
                                    ? scheme.surfaceContainerHighest
                                    : const Color(0xFFF9FAFB),
                              ),
                              headingTextStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurfaceVariant,
                              ),
                              dataTextStyle: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: scheme.onSurface,
                              ),
                              dividerThickness: 0.5,
                              border: TableBorder(
                                horizontalInside: BorderSide(
                                  color: scheme.outlineVariant,
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
                                                roleLabelFromId(
                                                  e["roles_id"]
                                                      ?.toString(),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                e["nama_polda"]
                                                        ?.toString() ??
                                                    ' - ',
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                e["is_active"]
                                                            ?.toString() ==
                                                        "1"
                                                    ? "Aktif"
                                                    : "Tidak Aktif",
                                              ),
                                            ),
                                            DataCell(
                                              ActionButtons(
                                                onEdit: () {
                                                  final id = int.tryParse(
                                                      "${e["id"]}");
                                                  if (id == null ||
                                                      id <= 0) {
                                                    return;
                                                  }

                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          AddUserPage(
                                                        userId: id,
                                                        userData: e,
                                                      ),
                                                    ),
                                                  ).then((result) {
                                                    if (result ==
                                                        true) {
                                                      getUsers();
                                                    }
                                                  });
                                                },
                                                onDelete: () async {
                                                  final userId = int
                                                          .tryParse(
                                                              "${e["id"]}") ??
                                                      0;
                                                  if (userId == 0) {
                                                    return;
                                                  }

                                                  final result =
                                                      await showDialog<
                                                          bool>(
                                                    context:
                                                        context,
                                                    builder: (_) =>
                                                        AlertDialog(
                                                      title: const Text(
                                                          "Hapus Pengguna"),
                                                      content: Text(
                                                        "Apakah Anda yakin ingin menghapus pengguna \"${e["username"]}\"?",
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed:
                                                              () => Navigator.pop(
                                                                context,
                                                                false,
                                                              ),
                                                          child:
                                                              const Text("Batal"),
                                                        ),
                                                        ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                Colors.red,
                                                            foregroundColor:
                                                                Colors.white,
                                                          ),
                                                          onPressed:
                                                              () => Navigator.pop(
                                                                context,
                                                                true,
                                                              ),
                                                          child:
                                                              const Text("Hapus"),
                                                        ),
                                                      ],
                                                    ),
                                                  );

                                                  if (result ==
                                                      true) {
                                                    deleteUser(
                                                        userId);
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
              AppPagination(
                currentPage: _currentPage,
                totalPages: _totalPages,
                totalItems: _totalItems,
                perPage: _perPage,
                onPageChanged: _onPageChanged,
              ),
            ],
          ),
        ),
      ),

      const SizedBox(height: 20),

    ],
  ),
);
  }

}
