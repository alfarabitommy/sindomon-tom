import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/api_config.dart';
import '../pages/add_sarpras.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widget/app_pagination.dart';
import '../widget/app_search_field.dart';
import '../widget/action_buttons.dart';
import '../widget/app_scaffold.dart';
import '../widget/glass_surface.dart';
import '../widget/hud_loading_spinner.dart';
import '../utils/hud_loading.dart';

class SarprasPage extends StatefulWidget {
  const SarprasPage({super.key});

  @override
  State<SarprasPage> createState() => _SarprasPageState();
}

class _SarprasPageState extends State<SarprasPage> {
  List<Map<String, dynamic>> sarprasApi = [];
  bool isLoading = true;

  String _searchQuery = "";
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _perPage = 10;

  // BUG FIX: no trailing "?" appended when the search query is empty.
  Future<void> getSarprasApi() async {
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
        "$apiBaseUrl/api/v1/logistik/sarpras",
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
          sarprasApi = parsedItems;
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
    getSarprasApi();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchQuery = value;
      _currentPage = 1;
      getSarprasApi();
    });
  }

  void _onPageChanged(int page) {
    if (page < 1 || page > _totalPages || page == _currentPage) return;
    _currentPage = page;
    getSarprasApi();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // BUG FIX: ID goes in the URL path, never in the body.
  // SnackBar in catch block for network errors.
  Future<void> deleteSarpras(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      HudLoading.show(context, label: "MENGHAPUS...");

      final response = await http.delete(
        Uri.parse("$apiBaseUrl/api/v1/logistik/sarpras/$id"),
        headers: {
          "Authorization": token.toString(),
        },
      );

      if (response.statusCode == 200) {
        HudLoading.hide(context);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Data sarpras berhasil dihapus"),
            backgroundColor: Colors.red,
          ),
        );
        getSarprasApi();
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

  /// kategori may be a flat string or a nested object — handle both safely.
  String _formatKategori(dynamic kategori) {
    if (kategori == null) return "-";
    if (kategori is String) return kategori.isEmpty ? "-" : kategori;
    if (kategori is Map) {
      final nama = kategori["nama_kategori"] ?? kategori["kategori"] ?? "-";
      return nama.toString();
    }
    return kategori.toString();
  }

  /// Builds the absolute image URL; relative paths get the API base prefix.
  /// Uses the proven Senjata pattern — inserts '/' when the backend returns
  /// a relative path WITHOUT a leading slash (fixes ClientException/malformed
  /// domain from CachedNetworkImage).
  String _resolveImageUrl(dynamic raw) {
    final url = raw?.toString() ?? "";
    if (url.isEmpty) return "";
    if (url.startsWith("http://") || url.startsWith("https://")) return url;
    final parsed = url.startsWith("/") ? "$apiBaseUrl$url" : "$apiBaseUrl/$url";
    return parsed;
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
  currentRoute: "sarpras",
  breadcrumb: "Dashboard / Logistik / Sarpras & Altmatsus",
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 25),

      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Manajemen Sarpras & Altmatsus",
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),

          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddSarprasPage(),
                ),
              );
              if (result == true) {
                getSarprasApi();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text("Tambah Sarpras"),
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
        hintText: "Cari Sarpras...",
        controller: _searchController,
        onChanged: _onSearchChanged,
      ),

      const SizedBox(height: 25),

      Expanded(
        child: GlassSurface(
          borderRadius: BorderRadius.circular(12),
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
                                        WidgetStateProperty.all(
                                          isDark
                                              ? scheme
                                                  .surfaceContainerHighest
                                              : const Color(
                                                  0xFFF9FAFB,
                                                ),
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
                                      DataColumn(
                                        label: Text("FOTO"),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "KODE BARANG",
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "NAMA BARANG",
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "KATEGORI",
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "KONDISI",
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text("AKSI"),
                                      ),
                                    ],
                                    rows: sarprasApi
                                        .map(
                                          (e) => DataRow(
                                            cells: [
                                              DataCell(
                                                // Fallback for the image key: foto_fisik (Senjata
                                                // convention) → foto_url → foto (multipart field).
                                                _buildThumbnail(
                                                  e["foto_fisik"] ??
                                                      e["foto_url"] ??
                                                      e["foto"],
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  e[
                                                          "kode_barang"]
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
                                                  e[
                                                          "nama_barang"]
                                                      ?.toString() ??
                                                      "-",
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  _formatKategori(
                                                    e[
                                                        "kategori"],
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  e["kondisi"]
                                                          ?.toString() ??
                                                      "-",
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
                                                            AddSarprasPage(
                                                          initialData:
                                                              e,
                                                        ),
                                                      ),
                                                    );
                                                    if (result ==
                                                        true) {
                                                      getSarprasApi();
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
                                                              "Hapus Sarpras",
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
                                                      final sarprasId =
                                                          e[
                                                                  "sarpras_id"]
                                                              ?.toString() ??
                                                              "";
                                                      if (sarprasId
                                                          .isNotEmpty) {
                                                        deleteSarpras(
                                                          sarprasId,
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
