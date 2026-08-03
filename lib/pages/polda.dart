import 'package:flutter/material.dart';
import '../widget/background.dart';
import '../widget/app_sidebar.dart';
import '../config/api_config.dart';
import '../pages/add_polda.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widget/app_footer.dart';
import '../widget/app_pagination.dart';
import '../widget/app_header.dart';
import '../widget/app_search_field.dart';
import '../widget/action_buttons.dart';
import '../models/polda_model.dart';

class PoldaPage extends StatefulWidget {
  const PoldaPage({super.key});

  @override
  State<PoldaPage> createState() => _PoldaPageState();
}

class _PoldaPageState extends State<PoldaPage> {
  List<Polda> polda = [];
  String errorMessage = "";
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

      final response = await http.get(
        Uri.parse("$apiBaseUrl/api/v1/polda"),
        headers: {"Authorization": token.toString()},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final rawList = json["data"] as List;
        final parsed =
            rawList
                .map((e) => Polda.fromJson(e as Map<String, dynamic>))
                .toList();

        debugPrint("Polda fetched: ${parsed.length} total for CRUD table");

        setState(() {
          polda = parsed;
          errorMessage = "";
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Gagal memuat data (HTTP ${response.statusCode})";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Terjadi kesalahan saat memuat data Polda";
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
        Uri.parse("$apiBaseUrl/api/v1/master/polda/$id"),
        headers: {"Authorization": token.toString()},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result["message"] ?? "Polda berhasil dihapus"),
            backgroundColor: Colors.green,
          ),
        );
        getPoldaApi(); // refresh list
      } else {
        final result = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result["message"] ?? "Gagal menghapus Polda"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error delete polda: $e");
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

                      /// STATE HANDLING
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
                                  onPressed: getPoldaApi,
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
                      else if (polda.isEmpty)
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
                                  "Tidak ada data Polda untuk ditampilkan",
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
                                ).then((result) {
                                  if (result == true) {
                                    getPoldaApi();
                                  }
                                });
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
                                                headingTextStyle:
                                                    const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
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
                                                  DataColumn(
                                                    label: Text("AKSI"),
                                                  ),
                                                ],
                                                rows:
                                                    polda
                                                        .map(
                                                          (p) => DataRow(
                                                            cells: [
                                                              DataCell(
                                                                Text(
                                                                  p.id.toString(),
                                                                ),
                                                              ),
                                                              DataCell(
                                                                Text(
                                                                  p.namaPolda,
                                                                ),
                                                              ),
                                                              DataCell(
                                                                Text(
                                                                  p.latitude,
                                                                ),
                                                              ),
                                                              DataCell(
                                                                Text(
                                                                  p.longitude,
                                                                ),
                                                              ),
                                                              DataCell(
                                                                Text(
                                                                  p.createdAt ??
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
                                                                            (
                                                                              _,
                                                                            ) => AddPoldaPage(
                                                                              poldaId:
                                                                                  p.id,
                                                                              poldaData: {
                                                                                "nama_polda":
                                                                                    p.namaPolda,
                                                                                "latitude":
                                                                                    p.latitude,
                                                                                "longitude":
                                                                                    p.longitude,
                                                                              },
                                                                            ),
                                                                      ),
                                                                    ).then((
                                                                      result,
                                                                    ) {
                                                                      if (result ==
                                                                          true) {
                                                                        getPoldaApi();
                                                                      }
                                                                    });
                                                                  },
                                                                  onDelete: () async {
                                                                    final result = await showDialog<
                                                                      bool
                                                                    >(
                                                                      context:
                                                                          context,
                                                                      builder:
                                                                          (
                                                                            _,
                                                                          ) => AlertDialog(
                                                                            title: const Text(
                                                                              "Hapus Polda",
                                                                            ),
                                                                            content: Text(
                                                                              "Apakah Anda yakin ingin menghapus Polda \"${p.namaPolda}\"?",
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
                                                                        p.id,
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
