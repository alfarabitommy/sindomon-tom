import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../config/api_config.dart';
import '../pages/add_amunisi.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widget/app_pagination.dart';
import '../widget/app_search_field.dart';
import '../widget/action_buttons.dart';
import '../widget/app_scaffold.dart';
import '../widget/hud_loading_spinner.dart';
import '../utils/hud_loading.dart';

class AmunisiPage extends StatefulWidget {
  const AmunisiPage({super.key});

  @override
  State<AmunisiPage> createState() => _AmunisiPageState();
}

class _AmunisiPageState extends State<AmunisiPage> {
  List<Map<String, dynamic>> amunisiApi = [];
  bool isLoading = true;

  String _searchQuery = "";
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _perPage = 10;

  Future<void> getAmunisiApi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";

      final Map<String, String> params = {
        "page": _currentPage.toString(),
        "limit": _perPage.toString(),
      };
      if (_searchQuery.isNotEmpty) {
        params["search"] = _searchQuery;
      }

      final Uri uri = Uri.parse(
        "$apiBaseUrl/api/v1/logistik/amunisi",
      ).replace(queryParameters: params);

      final response = await http.get(
        uri,
        headers: {"Authorization": token},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final dynamic data = jsonResponse["data"];

        // New backend shape: { data: { items: [...], pagination: {...} } }.
        // Tolerates the legacy flat-list shape as a fallback.
        final List rawList = data is Map
            ? (data["items"] is List ? data["items"] : [])
            : (data is List ? data : []);
        final Map<String, dynamic> pagination = data is Map &&
                data["pagination"] is Map
            ? data["pagination"] as Map<String, dynamic>
            : <String, dynamic>{};
        final List<Map<String, dynamic>> parsedItems =
            rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();

        if (!mounted) return;
        setState(() {
          amunisiApi = parsedItems;
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
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });

      debugPrint(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    getAmunisiApi();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchQuery = value;
      _currentPage = 1;
      getAmunisiApi();
    });
  }

  void _onPageChanged(int page) {
    if (page < 1 || page > _totalPages || page == _currentPage) return;
    _currentPage = page;
    getAmunisiApi();
  }

  String _formatKaliber(dynamic kategori) {
    if (kategori is Map<String, dynamic>) {
      final laras = kategori["tipe_laras"] ?? "";
      final kaliber = kategori["kaliber"] ?? "";
      if (laras.isNotEmpty && kaliber.isNotEmpty) return "$laras - $kaliber";
      if (kaliber.isNotEmpty) return kaliber;
      if (laras.isNotEmpty) return laras;
    }
    return "-";
  }

  bool _isH90(Map<String, dynamic> e) {
    return e["is_h90_alert"] == true || e["is_h90_alert"] == 1;
  }

  Widget _buildStatusBadge(bool isH90) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isH90 ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isH90) ...[
            const FaIcon(
              FontAwesomeIcons.triangleExclamation,
              size: 12,
              color: Color(0xFFB91C1C),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            isH90 ? "H-90 ALERT" : "AMAN",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isH90 ? const Color(0xFFB91C1C) : const Color(0xFF166534),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> deleteAmunisi(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      HudLoading.show(context, label: "MENGHAPUS...");

      final response = await http.delete(
        Uri.parse("$apiBaseUrl/api/v1/logistik/amunisi/$id"),
        headers: {
          "Authorization": token.toString(),
        },
      );

      if (response.statusCode == 200) {
        HudLoading.hide(context);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Data amunisi berhasil dihapus"),
            backgroundColor: Colors.red,
          ),
        );
        getAmunisiApi();
      } else {
        HudLoading.hide(context);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal menghapus data"),
            backgroundColor: Colors.orange,
          ),
        );
        debugPrint("Error : ${response.body}");
      }
    } catch (e) {
      HudLoading.hide(context);
      debugPrint(e.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal menghapus data: jaringan bermasalah"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
  currentRoute: "ammo_stock",
  breadcrumb: "Dashboard / Logistik / Stok Amunisi",
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 25),

      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Manajemen Stok Amunisi",
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddAmunisiPage(),
                ),
              );
              if (result == true) {
                getAmunisiApi();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text("Tambah Amunisi"),
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

      AppSearchField(
        hintText: "Cari Amunisi...",
        controller: _searchController,
        onChanged: _onSearchChanged,
      ),

      const SizedBox(height: 25),

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
                        child: HudLoadingSpinner(size: 50),
                      )
                    : SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                scrollDirection:
                                    Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints:
                                      BoxConstraints(
                                        minWidth:
                                            constraints
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
                                              FontWeight.w700,
                                          color: Color(
                                            0xFF6B7280,
                                          ),
                                        ),
                                    dataTextStyle:
                                        const TextStyle(
                                          fontSize: 14,
                                          fontWeight:
                                              FontWeight.w400,
                                          color: Color(
                                            0xFF374151,
                                          ),
                                        ),
                                    dividerThickness: 0.5,
                                    border: const TableBorder(
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
                                          "KODE BATCH",
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text("KALIBER"),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "JUMLAH BUTIR",
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text("TGL MASUK"),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "TGL KEDALUWARSA",
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text("STATUS"),
                                      ),
                                      DataColumn(
                                        label: Text("AKSI"),
                                      ),
                                    ],
                                    rows: amunisiApi
                                        .map(
                                          (e) => DataRow(
                                            cells: [
                                              DataCell(
                                                Text(
                                                  e[
                                                          "kode_batch"]
                                                      ?.toString() ??
                                                      "-",
                                                  style:
                                                      const TextStyle(
                                                        fontFamily:
                                                            "monospace",
                                                      ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  _formatKaliber(
                                                    e[
                                                        "kategori"],
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  _formatJumlah(
                                                    e[
                                                        "jumlah_butir"],
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  e[
                                                          "tanggal_masuk"]
                                                          ?.toString() ??
                                                      "-",
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  e[
                                                          "tanggal_kedaluwarsa"]
                                                          ?.toString() ??
                                                      "-",
                                                ),
                                              ),
                                              DataCell(
                                                _buildStatusBadge(
                                                  _isH90(e),
                                                ),
                                              ),
                                              DataCell(
                                                ActionButtons(
                                                  onEdit: () async {
                                                    final result =
                                                        await Navigator.push<
                                                            bool>(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            AddAmunisiPage(
                                                          initialData:
                                                              e,
                                                        ),
                                                      ),
                                                    );
                                                    if (result ==
                                                        true) {
                                                      getAmunisiApi();
                                                    }
                                                  },
                                                  onDelete: () async {
                                                    final result =
                                                        await showDialog(
                                                      context:
                                                          context,
                                                      builder:
                                                          (
                                                        _,
                                                      ) =>
                                                          AlertDialog(
                                                        title:
                                                            const Text(
                                                              "Hapus Amunisi",
                                                            ),
                                                        content:
                                                            const Text(
                                                              "Apakah Anda yakin ingin menghapus data ini?",
                                                            ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
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
                                                            onPressed: () =>
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
                                                      final amunisiId =
                                                          e[
                                                                  "batch_id"]
                                                              ?.toString() ??
                                                              "";
                                                      if (amunisiId
                                                          .isNotEmpty) {
                                                        deleteAmunisi(
                                                          amunisiId,
                                                        );
                                                      }
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

  String _formatJumlah(dynamic jumlah) {
    final j = int.tryParse(jumlah?.toString() ?? "");
    if (j == null) return "-";
    return j.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => "${m[1]}.",
    );
  }
}
