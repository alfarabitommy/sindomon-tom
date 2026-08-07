import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../config/api_config.dart';
import '../widget/background.dart';
import '../widget/app_sidebar.dart';
import '../widget/app_footer.dart';
import '../widget/app_pagination.dart';
import '../widget/app_header.dart';
import '../widget/app_search_field.dart';
import '../widget/action_buttons.dart';

/// Master data untuk kategori senjata & kaliber (Screen 2.6).
///
/// Endpoint: `GET/POST/PUT/DELETE $apiBaseUrl/api/v1/master/kategori-senjata`
/// Record shape (dipakai juga oleh form_input_senjata / form_input_amunisi):
/// `{ "kategori_id": 5, "tipe_laras": "Pistol", "kaliber": "9mm" }`
class MasterKategoriSenjataPage extends StatefulWidget {
  const MasterKategoriSenjataPage({super.key});

  @override
  State<MasterKategoriSenjataPage> createState() =>
      _MasterKategoriSenjataPageState();
}

class _MasterKategoriSenjataPageState extends State<MasterKategoriSenjataPage> {
  /// Opsi statis — tidak diambil dari API.
  static const List<String> _tipeLarasOptions = ['Panjang', 'Pendek'];

  List<Map<String, dynamic>> kategoriList = [];
  bool isLoading = true;
  String errorMessage = "";
  String unLogin = "";
  String roleLabel = "Operator";

  String _searchQuery = "";
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      unLogin = prefs.getString("username_login") ?? "";
      roleLabel = AppSidebar.roleLabelFromId(prefs.getString("roleid_login"));
    });
  }

  Future<void> getKategoriApi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";

      Uri uri = Uri.parse("$apiBaseUrl/api/v1/master/kategori-senjata");
      if (_searchQuery.isNotEmpty) {
        uri = uri.replace(queryParameters: {"search": _searchQuery});
      }

      final response = await http.get(
        uri,
        headers: {"Authorization": token},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> rawData = jsonResponse["data"] ?? [];
        setState(() {
          kategoriList = rawData.cast<Map<String, dynamic>>();
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
        errorMessage = "Terjadi kesalahan saat memuat data kategori senjata";
        isLoading = false;
      });
      debugPrint(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    loadUser();
    getKategoriApi();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchQuery = value;
      getKategoriApi();
    });
  }

  // =====================================================================
  // BADGE TIPE LARAS
  // 'Panjang' → biru, 'Pendek' → ungu, lainnya → abu-abu (fallback).
  // =====================================================================
  Widget _buildTipeLarasBadge(String tipe) {
    final normalized = tipe.trim().toLowerCase();
    final Color bg;
    final Color fg;

    if (normalized == "panjang") {
      bg = Colors.blue.shade50;
      fg = Colors.blue.shade700;
    } else if (normalized == "pendek") {
      bg = Colors.purple.shade50;
      fg = Colors.purple.shade700;
    } else {
      bg = Colors.grey.shade100;
      fg = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tipe,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  // =====================================================================
  // MODAL FORM (Tambah / Edit)
  // =====================================================================
  Future<void> _showKategoriForm({Map<String, dynamic>? existing}) async {
    final bool isEdit = existing != null;

    // Pre-fill saat edit; fallback aman bila API mengembalikan nilai lain.
    String? selectedTipe;
    if (isEdit) {
      final raw = (existing["tipe_laras"]?.toString() ?? "").trim();
      for (final o in _tipeLarasOptions) {
        if (o.toLowerCase() == raw.toLowerCase()) {
          selectedTipe = o;
          break;
        }
      }
    }
    final kaliberController = TextEditingController(
      text: isEdit ? (existing["kaliber"]?.toString() ?? "") : "",
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isEdit ? "Edit Kategori Senjata" : "Tambah Kategori Senjata",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 420,
          child: StatefulBuilder(
            builder: (context, setDialogState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tipe Laras *",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedTipe,
                  isExpanded: true,
                  decoration: _dialogInputDecoration.copyWith(
                    hintText: "Pilih Tipe Laras",
                  ),
                  items: _tipeLarasOptions
                      .map(
                        (o) => DropdownMenuItem<String>(
                          value: o,
                          child: Text(o),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedTipe = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  "Kaliber *",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: kaliberController,
                  decoration: _dialogInputDecoration.copyWith(
                    hintText: "Contoh: 9mm",
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final kaliber = kaliberController.text.trim();
              if (selectedTipe == null || kaliber.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text("Lengkapi semua data bertanda *"),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext, {
                "tipe_laras": selectedTipe,
                "kaliber": kaliber,
              });
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );

    if (result != null) {
      await _saveKategori(
        isEdit: isEdit,
        kategoriId: isEdit ? existing["kategori_id"]?.toString() : null,
        tipeLaras: result["tipe_laras"] as String,
        kaliber: result["kaliber"] as String,
      );
    }
  }

  static const InputDecoration _dialogInputDecoration = InputDecoration(
    filled: true,
    fillColor: Color(0xFFF9FAFB),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFFE5E7EB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFFE5E7EB), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFF1D4ED8), width: 1.5),
    ),
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  Future<void> _saveKategori({
    required bool isEdit,
    required String? kategoriId,
    required String tipeLaras,
    required String kaliber,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";

      final Uri uri = isEdit
          ? Uri.parse("$apiBaseUrl/api/v1/master/kategori-senjata/$kategoriId")
          : Uri.parse("$apiBaseUrl/api/v1/master/kategori-senjata");

      final Map<String, String> headers = {
        "Authorization": token,
        "Content-Type": "application/json",
      };
      final String body = jsonEncode({
        "tipe_laras": tipeLaras,
        "kaliber": kaliber,
      });

      final http.Response response = isEdit
          ? await http.put(uri, headers: headers, body: body)
          : await http.post(uri, headers: headers, body: body);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? "Kategori berhasil diperbarui"
                  : "Kategori berhasil ditambahkan",
            ),
            backgroundColor: Colors.green,
          ),
        );
        getKategoriApi();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_parseErrorMessage(response) ?? "Gagal menyimpan data"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal menyimpan data: jaringan bermasalah"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // =====================================================================
  // DELETE — menangkap 409 Conflict (data masih dipakai Senjata/Amunisi)
  // =====================================================================
  Future<void> deleteKategori(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.delete(
        Uri.parse("$apiBaseUrl/api/v1/master/kategori-senjata/$id"),
        headers: {"Authorization": token.toString()},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Kategori berhasil dihapus"),
            backgroundColor: Colors.green,
          ),
        );
        getKategoriApi();
      } else if (response.statusCode == 409) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Kategori tidak dapat dihapus karena masih digunakan oleh "
              "data Senjata atau Amunisi",
            ),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _parseErrorMessage(response) ?? "Gagal menghapus kategori",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error delete kategori: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Terjadi kesalahan jaringan"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Ekstrak `message` dari body JSON bila tersedia (pola backend).
  String? _parseErrorMessage(http.Response response) {
    try {
      final result = jsonDecode(response.body);
      if (result is Map && result["message"] != null) {
        return result["message"].toString();
      }
    } catch (_) {}
    return null;
  }

  // =====================================================================
  // BUILD
  // =====================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        imagePath: 'assets/images/wp-putih-mabes.png',
        child: SafeArea(
          child: Row(
            children: [
              const AppSidebar(currentRoute: "kategori_senjata"),

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
                        breadcrumb: "Dashboard / Master Data / Kategori Senjata",
                        username: unLogin,
                        role: roleLabel,
                      ),
                      const SizedBox(height: 25),

                      /// TITLE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Master Kategori Senjata & Kaliber",
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),

                          ElevatedButton.icon(
                            onPressed: () => _showKategoriForm(),
                            icon: const Icon(Icons.add),
                            label: const Text("Tambah Kategori"),
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
                        hintText: "Cari Kategori...",
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
                                child: isLoading
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.amber,
                                        ),
                                      )
                                    : errorMessage.isNotEmpty
                                        ? _buildErrorState()
                                        : SingleChildScrollView(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(20),
                                              child: LayoutBuilder(
                                                builder: (context, constraints) {
                                                  return SingleChildScrollView(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    child: ConstrainedBox(
                                                      constraints:
                                                          BoxConstraints(
                                                            minWidth: constraints
                                                                .maxWidth,
                                                          ),
                                                      child: DataTable(
                                                        headingRowColor:
                                                            WidgetStateProperty
                                                                .all(
                                                                  Colors.grey
                                                                      .shade50,
                                                                ),
                                                        headingTextStyle:
                                                            const TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: Color(
                                                                0xFF6B7280,
                                                              ),
                                                            ),
                                                        dataTextStyle:
                                                            const TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              color: Color(
                                                                0xFF374151,
                                                              ),
                                                            ),
                                                        dividerThickness: 0.5,
                                                        border:
                                                            const TableBorder(
                                                              horizontalInside:
                                                                  BorderSide(
                                                                    color: Color(
                                                                      0xFFE5E7EB,
                                                                    ),
                                                                    width: 0.5,
                                                                  ),
                                                            ),
                                                        dataRowMinHeight: 60,
                                                        dataRowMaxHeight: 70,
                                                        columns: const [
                                                          DataColumn(
                                                            label: Text(
                                                              "TIPE LARAS",
                                                            ),
                                                          ),
                                                          DataColumn(
                                                            label: Text(
                                                              "KALIBER",
                                                            ),
                                                          ),
                                                          DataColumn(
                                                            label: Text(
                                                              "AKSI",
                                                            ),
                                                          ),
                                                        ],
                                                        rows: kategoriList
                                                            .map(
                                                              (e) => DataRow(
                                                                cells: [
                                                                  DataCell(
                                                                    _buildTipeLarasBadge(
                                                                      e[
                                                                              "tipe_laras"]
                                                                              ?.toString() ??
                                                                          "-",
                                                                    ),
                                                                  ),
                                                                  DataCell(
                                                                    Text(
                                                                      e["kaliber"]
                                                                              ?.toString() ??
                                                                          "-",
                                                                      style: const TextStyle(
                                                                        fontFamily:
                                                                            "monospace",
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  DataCell(
                                                                    ActionButtons(
                                                                      onEdit: () =>
                                                                          _showKategoriForm(
                                                                        existing:
                                                                            e,
                                                                      ),
                                                                      onDelete: () async {
                                                                        final kategoriId =
                                                                            e["kategori_id"]
                                                                                ?.toString() ??
                                                                            "";
                                                                        if (kategoriId
                                                                            .isEmpty) {
                                                                          return;
                                                                        }
                                                                        final tipeLaras =
                                                                            e["tipe_laras"]
                                                                                    ?.toString() ??
                                                                                "";
                                                                        final kaliber =
                                                                            e["kaliber"]
                                                                                    ?.toString() ??
                                                                                "";
                                                                        final result =
                                                                            await showDialog<
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
                                                                                  "Hapus Kategori",
                                                                                ),
                                                                            content:
                                                                                Text(
                                                                                  "Apakah Anda yakin ingin menghapus kategori \"$tipeLaras - $kaliber\"?",
                                                                                ),
                                                                            actions:
                                                                                [
                                                                                  TextButton(
                                                                                    onPressed:
                                                                                        () =>
                                                                                            Navigator.pop(
                                                                                              context,
                                                                                              false,
                                                                                            ),
                                                                                    child:
                                                                                        const Text(
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
                                                                                        () =>
                                                                                            Navigator.pop(
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
                                                                          deleteKategori(
                                                                            kategoriId,
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                isLoading = true;
                errorMessage = "";
              });
              getKategoriApi();
            },
            icon: const Icon(Icons.refresh),
            label: const Text("Coba Lagi"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
