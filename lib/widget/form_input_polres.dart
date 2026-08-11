import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../../utils/hud_loading.dart';

class FormTambahPolres extends StatefulWidget {
  final int? polresId; // null = create mode, non-null = edit mode
  final Map<String, dynamic>? polresData; // pre-fill data for edit

  const FormTambahPolres({super.key, this.polresId, this.polresData});

  @override
  State<FormTambahPolres> createState() => _FormTambahPolresState();
}

class _FormTambahPolresState extends State<FormTambahPolres> {
  late bool isEditMode;
  int? selectedPoldaId;
  final namaPolres = TextEditingController();
  List<Map<String, dynamic>> daftarPolda = [];

  Future<void> getPolda() async {
    final sharep = await SharedPreferences.getInstance();
    final ptoken = sharep.getString("token");

    try {
      final respon = await http.get(
        Uri.parse('$apiBaseUrl/api/v1/polda'),
        headers: {"Authorization": ptoken.toString()},
      );

      if (respon.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(respon.body);
        setState(() {
          daftarPolda = List<Map<String, dynamic>>.from(body['data']);
        });
      } else {
        debugPrint(respon.body);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> simpanPolres() async {
    if (selectedPoldaId == null || namaPolres.text.isEmpty) {
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
        "polda_id": selectedPoldaId,
        "nama_polres": namaPolres.text,
      };

      final http.Response response;

      if (isEditMode) {
        // PUT /api/v1/master/polres/:id
        response = await http.put(
          Uri.parse("$apiBaseUrl/api/v1/master/polres/${widget.polresId}"),
          headers: {
            "Authorization": token.toString(),
            "Content-Type": "application/json",
          },
          body: jsonEncode(body),
        );
      } else {
        // POST /api/v1/master/polres — create new
        response = await http.post(
          Uri.parse("$apiBaseUrl/api/v1/master/polres"),
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
                      ? "Data Polres berhasil diperbarui"
                      : "Data Polres berhasil disimpan"),
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Pop back to Polres list; list page refreshes via .then() callback
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
      debugPrint("Error simpan polres: $e");
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

  @override
  void initState() {
    super.initState();
    isEditMode = widget.polresId != null && widget.polresData != null;

    if (isEditMode && widget.polresData != null) {
      final data = widget.polresData!;
      namaPolres.text = data["nama_polres"]?.toString() ?? "";
      // Pre-set dropdown value; daftarPolda loads async, dropdown will
      // resolve correctly once getPolda() completes and setState rebuilds.
      final poldaIdRaw = data["polda_id"];
      if (poldaIdRaw != null) {
        selectedPoldaId =
            poldaIdRaw is int
                ? poldaIdRaw
                : int.tryParse(poldaIdRaw.toString());
      }
    }

    getPolda(); // always fetch polda list for the dropdown
  }

  @override
  void dispose() {
    namaPolres.dispose();
    super.dispose();
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
          isEditMode ? "EDIT POLRES" : "TAMBAH POLRES BARU",
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

        DropdownButtonFormField<int>(
          initialValue: selectedPoldaId,
          decoration: _inputDecoration(scheme).copyWith(hintText: "Pilih Polda"),
          items:
              daftarPolda.map((polda) {
                return DropdownMenuItem<int>(
                  value: int.tryParse(polda["id"].toString()) ?? 0,
                  child: Text(polda["nama_polda"]),
                );
              }).toList(),
          onChanged: (value) {
            setState(() {
              selectedPoldaId = value;
            });
          },
        ),

        const SizedBox(height: 20),

        Text(
          "Nama Polres*",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: scheme.onSurface,
          ),
        ),

        const SizedBox(height: 8),

        TextFormField(controller: namaPolres, decoration: _inputDecoration(scheme)),

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
            onPressed: simpanPolres,
            child: Text(
              isEditMode ? "Update Polres" : "Simpan Data",
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
