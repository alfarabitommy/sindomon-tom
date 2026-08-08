import 'dart:async';

import 'package:flutter/material.dart';
import '../widget/background.dart';
import '../widget/app_sidebar.dart';
import '../config/api_config.dart';
import '../pages/add_personel_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widget/app_footer.dart';
import '../widget/app_pagination.dart';
import '../widget/app_header.dart';
import '../widget/app_search_field.dart';
import '../widget/action_buttons.dart';

class PersonelPage extends StatefulWidget {
  const PersonelPage({super.key});

  @override
  State<PersonelPage> createState() => _PersonelPageState();
}

class _PersonelPageState extends State<PersonelPage> {
  List<Map<String, dynamic>> datapersonel = [];
  String errorMessage = "";
  bool isLoading = true;
  String unLogin = "";
  String roleLabel = "Operator";

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

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      unLogin = prefs.getString("username_login") ?? "";
      roleLabel = AppSidebar.roleLabelFromId(prefs.getString("roleid_login"));
    });
  }

  Future<void> getPersonelApi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      Uri uri = Uri.parse("$apiBaseUrl/api/v1/sdm/personil");
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
            ? (data["items"] is List ? data["items"] : [])
            : (data is List ? data : []);
        final Map<String, dynamic> pagination = data is Map &&
                data["pagination"] is Map
            ? data["pagination"] as Map<String, dynamic>
            : <String, dynamic>{};
        final parsedItems =
            rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();

        debugPrint(
          "Personel fetched: ${parsedItems.length} items (page $_currentPage)",
        );

        if (!mounted) return;
        setState(() {
          datapersonel = parsedItems;
          _currentPage =
              (pagination["current_page"] as num?)?.toInt() ?? _currentPage;
          _totalPages =
              (pagination["last_page"] as num?)?.toInt() ??
              (pagination["total_pages"] as num?)?.toInt() ??
              1;
          _totalItems =
              (pagination["total"] as num?)?.toInt() ?? parsedItems.length;
          _perPage =
              (pagination["per_page"] as num?)?.toInt() ??
              (pagination["limit"] as num?)?.toInt() ??
              _perPage;
          errorMessage = "";
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          errorMessage = "Gagal memuat data (HTTP ${response.statusCode})";
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = "Terjadi kesalahan saat memuat data Personel";
        isLoading = false;
      });
      debugPrint(e.toString());
    }
  }

  // RESTful path-param DELETE with string UUID (polres pattern)
  Future<void> deletePersonel(String personilId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.delete(
        Uri.parse("$apiBaseUrl/api/v1/sdm/personil/$personilId"),
        headers: {"Authorization": token.toString()},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result["message"] ?? "Personel berhasil dihapus"),
            backgroundColor: Colors.green,
          ),
        );
        getPersonelApi(); // refresh list
      } else {
        final result = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result["message"] ?? "Gagal menghapus Personel"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error delete personel: $e");
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
    loadUser();
    getPersonelApi();
  }

  /// Debounced search: waits 400ms of idle typing before hitting the API,
  /// and always resets to page 1 so results start from the beginning.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchQuery = value;
      _currentPage = 1;
      getPersonelApi();
    });
  }

  void _onPageChanged(int page) {
    if (page < 1 || page > _totalPages || page == _currentPage) return;
    _currentPage = page;
    getPersonelApi();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        imagePath: 'assets/images/wp-putih-mabes.png',
        child: SafeArea(
          child: Row(
            children: [
              const AppSidebar(currentRoute: "personel"),

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
                        breadcrumb: "Dashboard / Personel",
                        username: unLogin,
                        role: roleLabel,
                      ),

                      /// STATE HANDLING (polres pattern)
                      if (isLoading)
                        const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.amber,
                            ),
                          ),
                        )
                      else if (errorMessage.isNotEmpty)
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  child: Text(
                                    errorMessage,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: getPersonelApi,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text("Coba Lagi"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (datapersonel.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.table_rows_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  "Tidak ada data Personel untuk ditampilkan",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        const SizedBox(height: 25),

                        /// ============================
                        /// TITLE
                        /// ============================
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Manajemen Personel",
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
                                    builder: (_) => const AddPersonelPage(),
                                  ),
                                ).then((result) {
                                  if (result == true) {
                                    getPersonelApi();
                                  }
                                });
                              },
                              icon: const Icon(Icons.add),
                              label: const Text("Tambah Personel"),
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
                          hintText: "Cari Personel...",
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                        ),

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
                                                headingTextStyle:
                                                    const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Color(0xFF6B7280),
                                                    ),
                                                dataTextStyle:
                                                    const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w400,
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
                                                    label: Text("NRP"),
                                                  ),
                                                  DataColumn(
                                                    label: Text(
                                                      "NAMA LENGKAP",
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: Text("PANGKAT"),
                                                  ),
                                                  DataColumn(
                                                    label: Text("JABATAN"),
                                                  ),
                                                  DataColumn(
                                                    label: Text("POLDA"),
                                                  ),
                                                  DataColumn(
                                                    label: Text("POLRES"),
                                                  ),
                                                  DataColumn(
                                                    label: Text(
                                                      "STATUS AKTIF",
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: Text("AKSI"),
                                                  ),
                                                ],
                                                rows:
                                                    datapersonel
                                                        .map(
                                                          (e) => DataRow(
                                                            cells: [
                                                              DataCell(
                                                                Text(
                                                                  "${e["nrp"]}",
                                                                ),
                                                              ),
                                                              DataCell(
                                                                Text(
                                                                  "${e["nama_lengkap"]}",
                                                                ),
                                                              ),
                                                              DataCell(
                                                                Text(
                                                                  e["nama_pangkat"]
                                                                          ?.toString() ??
                                                                      e["pangkat_id"]
                                                                          ?.toString() ??
                                                                      "-",
                                                                ),
                                                              ),
                                                              DataCell(
                                                                Text(
                                                                  e["nama_jabatan"]
                                                                          ?.toString() ??
                                                                      e["jabatan_id"]
                                                                          ?.toString() ??
                                                                      "-",
                                                                ),
                                                              ),
                                                              // POLDA: prefer the denormalized name returned by /api/v1/sdm/personil;
                                                              // fall back to the raw FK so the cell never renders blank when the
                                                              // backend omits nama_polda (defensive — same pattern as Pangkat/Jabatan/Polres).
                                                              DataCell(
                                                                Text(
                                                                  e["nama_polda"]
                                                                          ?.toString() ??
                                                                      e["polda_id"]
                                                                          ?.toString() ??
                                                                      "-",
                                                                ),
                                                              ),
                                                              DataCell(
                                                                Text(
                                                                  e["nama_polres"]
                                                                          ?.toString() ??
                                                                      e["polres_id"]
                                                                          ?.toString() ??
                                                                      "Tidak Ada / Mako Polda",
                                                                ),
                                                              ),
                                                              DataCell(
                                                                Text(
                                                                  e["status_aktif"]
                                                                          ?.toString() ??
                                                                      "-",
                                                                ),
                                                              ),
                                                              DataCell(
                                                                ActionButtons(
                                                                  onEdit: () {
                                                                    Navigator.push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                        builder:
                                                                            (_) =>
                                                                                AddPersonelPage(
                                                                                  personilId: e[
                                                                                          "personil_id"]
                                                                                      .toString(),
                                                                                  personilData: {
                                                                                    "nrp":
                                                                                        "${e["nrp"]}",
                                                                                    "nama_lengkap":
                                                                                        "${e["nama_lengkap"]}",
                                                                                    "polda_id":
                                                                                        e["polda_id"],
                                                                                    "polres_id":
                                                                                        e["polres_id"],
                                                                                    "pangkat_id":
                                                                                        e["pangkat_id"],
                                                                                    "jabatan_id":
                                                                                        e["jabatan_id"],
                                                                                  },
                                                                                ),
                                                                      ),
                                                                    ).then((
                                                                      result,
                                                                    ) {
                                                                      if (result ==
                                                                          true) {
                                                                        getPersonelApi();
                                                                      }
                                                                    });
                                                                  },
                                                                  onDelete: () async {
                                                                    final result = await showDialog<
                                                                        bool>(
                                                                      context:
                                                                          context,
                                                                      builder:
                                                                          (
                                                                            _,
                                                                          ) =>
                                                                              AlertDialog(
                                                                                title:
                                                                                    const Text(
                                                                                      "Hapus Personel",
                                                                                    ),
                                                                                content:
                                                                                    Text(
                                                                                      "Apakah Anda yakin ingin menghapus Personel \"${e["nama_lengkap"]}\"?",
                                                                                    ),
                                                                                actions: [
                                                                                  TextButton(
                                                                                    onPressed:
                                                                                        () => Navigator.pop(
                                                                                          context,
                                                                                          false,
                                                                                        ),
                                                                                    child:
                                                                                        const Text(
                                                                                          "Batal",
                                                                                        ),
                                                                                  ),
                                                                                  ElevatedButton(
                                                                                    style:
                                                                                        ElevatedButton.styleFrom(
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
                                                                                        const Text(
                                                                                          "Hapus",
                                                                                        ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                    );
                                                                    if (result ==
                                                                        true) {
                                                                      deletePersonel(
                                                                        e["personil_id"]
                                                                            .toString(),
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
                        const AppFooter(),
                      ],
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
