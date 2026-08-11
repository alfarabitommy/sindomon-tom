import 'dart:async';

import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../pages/add_senjata.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widget/app_pagination.dart';
import '../widget/app_search_field.dart';
import '../widget/action_buttons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widget/app_scaffold.dart';
import '../widget/glass_surface.dart';
import '../widget/hud_loading_spinner.dart';
import '../utils/hud_loading.dart';

class SenjataPage extends StatefulWidget {
  const SenjataPage({super.key});

  @override
  State<SenjataPage> createState() => _SenjataPageState();
}

class _SenjataPageState extends State<SenjataPage> {
  List<Map<String, dynamic>> senjataapi = [];
  bool isLoading = true;

  String _searchQuery = "";
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _perPage = 10;

  Future<void> getSenjataApi() async {
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
        "$apiBaseUrl/api/v1/logistik/senjata",
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
          senjataapi = parsedItems;
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
    getSenjataApi();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchQuery = value;
      _currentPage = 1;
      getSenjataApi();
    });
  }

  void _onPageChanged(int page) {
    if (page < 1 || page > _totalPages || page == _currentPage) return;
    _currentPage = page;
    getSenjataApi();
  }

  String _formatKategori(dynamic kategori) {
    if (kategori is Map<String, dynamic>) {
      final laras = kategori["tipe_laras"] ?? "";
      final kaliber = kategori["kaliber"] ?? "";
      if (laras.isNotEmpty && kaliber.isNotEmpty) return "$laras - $kaliber";
      if (laras.isNotEmpty) return laras;
      if (kaliber.isNotEmpty) return kaliber;
    }
    return "-";
  }

  /// Builds the absolute image URL; relative paths get the API base prefix.
  /// Inserts '/' when the backend returns a relative path WITHOUT a leading
  /// slash (fixes ClientException/malformed domain from CachedNetworkImage).
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
        width: 80,
        height: 50,
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
        width: 80,
        height: 50,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 80,
          height: 50,
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
          width: 80,
          height: 50,
          color: Colors.grey.shade100,
          child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> deleteSenjata(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (!mounted) return;
      HudLoading.show(context, label: "MENGHAPUS...");

      final response = await http.delete(
        Uri.parse("$apiBaseUrl/api/v1/logistik/senjata/$id"),
        headers: {
          "Authorization": token.toString(),
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        HudLoading.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Data senjata berhasil dihapus"),
            backgroundColor: Colors.red,
          ),
        );
        getSenjataApi();
      } else {
        if (!mounted) return;
        HudLoading.hide(context);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
  currentRoute: "senjata",
  breadcrumb: "Dashboard / Inventaris / Senjata Api",
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
            "Manajemen Senjata Api",
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
                  builder: (_) => const AddSenjataPage(),
                ),
              );
              if (result == true) {
                getSenjataApi();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text("Tambah Senjata"),
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
        hintText: "Cari Senjata...",
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
                child: isLoading
                    ? const Center(child: HudLoadingSpinner(size: 50))
                    : SingleChildScrollView(
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
                                DataColumn(
                                  label: Text("FOTO UNIT"),
                                ),
                                DataColumn(
                                  label: Text("NO SERI"),
                                ),
                                DataColumn(
                                  label: Text("KATEGORI"),
                                ),
                                DataColumn(
                                  label: Text("TAHUN"),
                                ),
                                DataColumn(label: Text("AKSI")),
                              ],
                              rows:
                                  senjataapi
                                      .map(
                                        (e) => DataRow(
                                          cells: [
                                            DataCell(
                                              _buildThumbnail(
                                                e["foto_fisik"] ??
                                                    e["foto_url"],
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                e["nomor_seri"] ??
                                                    "",
                                                style: const TextStyle(
                                                  fontFamily:
                                                      "monospace",
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                _formatKategori(
                                                  e["kategori"],
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                "${e["tahun_pengadaan"] ?? "-"}",
                                              ),
                                            ),
                                            DataCell(
                                              ActionButtons(
                                                onEdit: () async {
                                                  final result = await Navigator.push<bool>(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => AddSenjataPage(
                                                        initialData: e,
                                                      ),
                                                    ),
                                                  );
                                                  if (result == true) {
                                                    getSenjataApi();
                                                  }
                                                },
                                                onDelete: () async {
                                                  final result = await showDialog(
                                                    context:
                                                        context,
                                                    builder:
                                                        (
                                                          _,
                                                        ) => AlertDialog(
                                                          title: const Text(
                                                            "Hapus Senjata",
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
                                                    final senjataId =
                                                        e["senjata_id"]
                                                                ?.toString() ??
                                                            "";
                                                    if (senjataId
                                                        .isNotEmpty) {
                                                      deleteSenjata(
                                                        senjataId,
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
