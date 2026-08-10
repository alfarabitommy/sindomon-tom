import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/api_config.dart';
import '../pages/add_satwa.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widget/app_pagination.dart';
import '../widget/app_search_field.dart';
import '../widget/action_buttons.dart';
import '../widget/app_scaffold.dart';
import '../widget/hud_loading_spinner.dart';
import '../utils/hud_loading.dart';

class SatwaPage extends StatefulWidget {
  const SatwaPage({super.key});

  @override
  State<SatwaPage> createState() => _SatwaPageState();
}

class _SatwaPageState extends State<SatwaPage> {
  List<Map<String, dynamic>> satwaApi = [];
  bool isLoading = true;

  String _searchQuery = "";
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _perPage = 10;

  // BUG FIX (Rule 3): no trailing "?" appended when the search query is empty.
  Future<void> getSatwaApi() async {
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

      Uri uri = Uri.parse("$apiBaseUrl/api/v1/logistik/satwa");
      uri = uri.replace(queryParameters: params);

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
          satwaApi = parsedItems;
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
    getSatwaApi();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchQuery = value;
      _currentPage = 1;
      getSatwaApi();
    });
  }

  void _onPageChanged(int page) {
    if (page < 1 || page > _totalPages || page == _currentPage) return;
    _currentPage = page;
    getSatwaApi();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // BUG FIX (Rule 4): ID goes in the URL path, never in the body.
  // SnackBar in catch block for network errors.
  Future<void> deleteSatwa(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      HudLoading.show(context, label: "MENGHAPUS...");

      final response = await http.delete(
        Uri.parse("$apiBaseUrl/api/v1/logistik/satwa/$id"),
        headers: {
          "Authorization": token.toString(),
        },
      );

      if (response.statusCode == 200) {
        HudLoading.hide(context);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Data satwa berhasil dihapus"),
            backgroundColor: Colors.red,
          ),
        );
        getSatwaApi();
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

  /// BUG FIX (Rule 2): safely concatenate the image URL — inserts '/'
  /// when the backend returns a relative path WITHOUT a leading slash
  /// (fixes ClientException/malformed domain from CachedNetworkImage).
  String _resolveImageUrl(dynamic raw) {
    final url = raw?.toString() ?? "";
    if (url.isEmpty) return "";
    if (url.startsWith("http://") || url.startsWith("https://")) return url;
    return url.startsWith("/") ? "$apiBaseUrl$url" : "$apiBaseUrl/$url";
  }

  Widget _buildThumbnail(dynamic rawUrl) {
    final url = _resolveImageUrl(rawUrl);

    if (url.isEmpty) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 60,
          height: 60,
          color: Colors.grey.shade100,
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 60,
          height: 60,
          color: Colors.grey.shade100,
          child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
        ),
      ),
    );
  }

  /// True when jadwal_vaksin is less than 30 days from today or already passed.
  bool _isVaksinUrgent(dynamic raw) {
    final date = DateTime.tryParse(raw?.toString() ?? "");
    if (date == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final jadwal = DateTime(date.year, date.month, date.day);

    return jadwal.difference(today).inDays < 30;
  }

  String _cellValue(Map<String, dynamic> e, List<String> keys) {
    for (final key in keys) {
      final v = e[key];
      if (v != null && v.toString().isNotEmpty) return v.toString();
    }
    return "-";
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
  currentRoute: "satwa",
  breadcrumb: "Dashboard / Logistik / Satwa K9 & Turangga",
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
          const Text(
            "Manajemen Satwa",
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
                  builder: (_) => const AddSatwaPage(),
                ),
              );
              if (result == true) {
                getSatwaApi();
              }
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
      AppSearchField(
        hintText: "Cari Satwa...",
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
                                  constraints: BoxConstraints(
                                    minWidth:
                                        constraints.maxWidth,
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
                                        label: Text("FOTO"),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "NO REGISTRASI",
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text("JENIS"),
                                      ),
                                      DataColumn(
                                        label: Text("NAMA SATWA"),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "NAMA HANDLER",
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "KUALIFIKASI",
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "JADWAL VAKSIN",
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text("AKSI"),
                                      ),
                                    ],
                                    rows: satwaApi
                                        .map(
                                          (e) => DataRow(
                                            cells: [
                                              DataCell(
                                                _buildThumbnail(
                                                  e[
                                                          "foto_url"] ??
                                                      e[
                                                          "foto_satwa"] ??
                                                      e["foto"],
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  _cellValue(
                                                    e,
                                                    [
                                                      "nomor_registrasi",
                                                      "no_registrasi",
                                                    ],
                                                  ),
                                                  style:
                                                      const TextStyle(
                                                        fontFamily:
                                                            "monospace",
                                                      ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  _cellValue(
                                                    e,
                                                    [
                                                      "jenis_satwa",
                                                      "jenis",
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  _cellValue(
                                                    e,
                                                    [
                                                      "nama_satwa",
                                                      "nama",
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  _cellValue(
                                                    e,
                                                    [
                                                      "nama_handler",
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  _cellValue(
                                                    e,
                                                    [
                                                      "kualifikasi",
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize
                                                          .min,
                                                  children: [
                                                    Text(
                                                      _cellValue(
                                                        e,
                                                        [
                                                          "jadwal_vaksin",
                                                        ],
                                                      ),
                                                    ),
                                                    if (_isVaksinUrgent(
                                                      e[
                                                          "jadwal_vaksin"],
                                                    ))
                                                      const Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                              left:
                                                                  6,
                                                            ),
                                                        child:
                                                            Tooltip(
                                                              message:
                                                                  "Vaksinasi kurang dari 30 hari atau sudah lewat",
                                                              child:
                                                                  Icon(
                                                                    Icons
                                                                        .vaccines,
                                                                    color:
                                                                        Colors
                                                                            .red,
                                                                    size:
                                                                        18,
                                                                  ),
                                                            ),
                                                      ),
                                                  ],
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
                                                            AddSatwaPage(
                                                          initialData:
                                                              e,
                                                        ),
                                                      ),
                                                    );
                                                    if (result ==
                                                        true) {
                                                      getSatwaApi();
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
                                                              "Hapus Satwa",
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
                                                      final satwaId =
                                                          e[
                                                                  "satwa_id"]
                                                              ?.toString() ??
                                                              "";
                                                      if (satwaId
                                                          .isNotEmpty) {
                                                        deleteSatwa(
                                                          satwaId,
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
}
