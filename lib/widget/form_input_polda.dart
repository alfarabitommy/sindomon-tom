import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../../utils/hud_loading.dart';

class FormTambahPolda extends StatefulWidget {
  final int? poldaId; // null = create mode, non-null = edit mode
  final Map<String, dynamic>? poldaData; // pre-fill data for edit

  const FormTambahPolda({super.key, this.poldaId, this.poldaData});

  @override
  State<FormTambahPolda> createState() => _FormTambahPoldaState();
}

class _FormTambahPoldaState extends State<FormTambahPolda> {
  late bool isEditMode;
  final namaPolda = TextEditingController();
  final lat = TextEditingController();
  final long = TextEditingController();

  @override
  void initState() {
    super.initState();
    isEditMode = widget.poldaId != null && widget.poldaData != null;

    if (isEditMode && widget.poldaData != null) {
      final data = widget.poldaData!;
      namaPolda.text = data["nama_polda"]?.toString() ?? "";
      lat.text = data["latitude"]?.toString() ?? "";
      long.text = data["longitude"]?.toString() ?? "";
    }
  }

  Future<void> simpanPolda() async {
    if (namaPolda.text.isEmpty || lat.text.isEmpty || long.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Semua data wajib diisi"),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    try {
      HudLoading.show(context, label: "MENYIMPAN...");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final Map<String, dynamic> body = {
        "nama_polda": namaPolda.text,
        "latitude": lat.text,
        "longitude": long.text,
      };

      final http.Response response;

      if (isEditMode) {
        // PUT /api/v1/master/polda/:id
        response = await http.put(
          Uri.parse("$apiBaseUrl/api/v1/master/polda/${widget.poldaId}"),
          headers: {
            "Authorization": token.toString(),
            "Content-Type": "application/json",
          },
          body: jsonEncode(body),
        );
      } else {
        // POST /api/v1/polda — create new
        response = await http.post(
          Uri.parse("$apiBaseUrl/api/v1/master/polda"),
          headers: {
            "Authorization": token.toString(),
            "Content-Type": "application/json",
          },
          body: jsonEncode(body),
        );
      }

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        HudLoading.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result["message"] ??
                  (isEditMode
                      ? "Data Polda berhasil diperbarui"
                      : "Data Polda berhasil disimpan"),
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Pop back to Polda list; list page refreshes via .then() callback
        Navigator.pop(context, true); // true = data changed, triggers refresh
      } else {
        if (!mounted) return;
        HudLoading.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result["message"] ?? "Gagal menyimpan data"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      HudLoading.hide(context);
      debugPrint("Error simpan polda: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Terjadi kesalahan jaringan"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static InputDecoration _inputDecoration(ColorScheme scheme) =>
      InputDecoration(
    filled: true,
    fillColor: scheme.surfaceContainerHighest,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: scheme.outlineVariant),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: scheme.outlineVariant, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFF1D4ED8), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFFEF4444), width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFFEF4444), width: 1.5),
    ),
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEditMode ? "EDIT POLDA" : "TAMBAH POLDA BARU",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: scheme.onSurface,
          ),
        ),

        const SizedBox(height: 25),

        Text(
          "Nama Polda *",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: scheme.onSurface,
          ),
        ),

        const SizedBox(height: 8),

        TextFormField(controller: namaPolda, decoration: _inputDecoration(scheme)),

        const SizedBox(height: 20),

        Text(
          "Latitude*",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: scheme.onSurface,
          ),
        ),

        const SizedBox(height: 8),

        TextFormField(controller: lat, decoration: _inputDecoration(scheme)),

        const SizedBox(height: 20),

        Text(
          "Longitude *",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: scheme.onSurface,
          ),
        ),

        TextFormField(controller: long, decoration: _inputDecoration(scheme)),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffF6B300),
              foregroundColor: const Color(0xFF23251D),
              shape: const StadiumBorder(),
            ),
            onPressed: simpanPolda,
            child: Text(
              isEditMode ? "Update Polda" : "Simpan Data",
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),

        const SizedBox(height: 20),

        Text(
          "Silahkan lengkapi semua data bertanda *",
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
