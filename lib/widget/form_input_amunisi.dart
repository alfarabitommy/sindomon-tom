import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class FormTambahAmunisi extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const FormTambahAmunisi({super.key, this.initialData});

  @override
  State<FormTambahAmunisi> createState() => _FormTambahAmunisiState();
}

class _FormTambahAmunisiState extends State<FormTambahAmunisi> {
  final kodeBatch = TextEditingController();
  final jumlahButir = TextEditingController();
  final GlobalKey<FormFieldState<int>> _poldaFieldKey = GlobalKey<FormFieldState<int>>();
  int? selectedPoldaId;
  int? selectedKatId;
  DateTime? tanggalMasuk;
  DateTime? tanggalKedaluwarsa;
  List<Map<String, dynamic>> daftarPolda = [];
  List<Map<String, dynamic>> daftarKategori = [];
  late bool _isEdit;

  String _fmt(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  DateTime? _parseDate(dynamic raw) {
    final s = raw?.toString() ?? "";
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  Future<void> getPolda() async {
    final pref = await SharedPreferences.getInstance();
    final tokenn = pref.getString("token");

    try {
      final responses = await http.get(
        Uri.parse('$apiBaseUrl/api/v1/polda'),
        headers: {"Authorization": tokenn.toString()},
      );

      if (responses.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(responses.body);

        final poldaIdStr = pref.getString("polda_login");
        final poldaId = (poldaIdStr != null && poldaIdStr.isNotEmpty)
            ? int.tryParse(poldaIdStr)
            : null;

        setState(() {
          daftarPolda = List<Map<String, dynamic>>.from(body['data']);
          if (!_isEdit &&
              poldaId != null &&
              daftarPolda.any((p) => int.tryParse(p["id"].toString()) == poldaId)) {
            selectedPoldaId = poldaId;
          }
        });

        if (selectedPoldaId != null) {
          _poldaFieldKey.currentState?.didChange(selectedPoldaId!);
        }
      } else {
        debugPrint(responses.body);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> getKategori() async {
    final prefst = await SharedPreferences.getInstance();
    final tokenize = prefst.getString("token");

    try {
      final rrrr = await http.get(
        Uri.parse('$apiBaseUrl/api/v1/master/kategori-senjata'),
        headers: {"Authorization": tokenize.toString()},
      );

      if (rrrr.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(rrrr.body);

        setState(() {
          daftarKategori = List<Map<String, dynamic>>.from(body['data']);
        });
      } else {
        debugPrint(rrrr.body);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _pickTanggalMasuk() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: tanggalMasuk ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
    );
    if (picked == null) return;
    setState(() {
      tanggalMasuk = picked;
      if (tanggalKedaluwarsa != null &&
          !tanggalKedaluwarsa!.isAfter(picked)) {
        tanggalKedaluwarsa = null;
      }
    });
  }

  Future<void> _pickTanggalKedaluwarsa() async {
    final base = tanggalMasuk ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          tanggalKedaluwarsa ?? base.add(const Duration(days: 365)),
      firstDate: tanggalMasuk != null
          ? tanggalMasuk!.add(const Duration(days: 1))
          : DateTime.now(),
      lastDate: base.add(const Duration(days: 365 * 20)),
    );
    if (picked == null) return;
    setState(() {
      tanggalKedaluwarsa = picked;
    });
  }

  Future<void> submitData() async {
    if (tanggalMasuk == null || tanggalKedaluwarsa == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lengkapi semua data bertanda *"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!tanggalKedaluwarsa!.isAfter(tanggalMasuk!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tanggal Kedaluwarsa harus setelah Tanggal Masuk"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final data = {
      "polda_id": selectedPoldaId,
      "kode_batch": kodeBatch.text,
      "kategori_id": selectedKatId,
      "jumlah_butir": int.tryParse(jumlahButir.text),
      "tanggal_masuk": _fmt(tanggalMasuk!),
      "tanggal_kedaluwarsa": _fmt(tanggalKedaluwarsa!),
    };

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final http.Response response;

    if (_isEdit) {
      final editData = Map<String, dynamic>.from(data);
      response = await http.put(
        Uri.parse(
            "$apiBaseUrl/api/v1/logistik/amunisi/${widget.initialData!["batch_id"]}"),
        headers: {
          "Authorization": token.toString(),
          "Content-Type": "application/json",
        },
        body: jsonEncode(editData),
      );
    } else {
      response = await http.post(
        Uri.parse("$apiBaseUrl/api/v1/logistik/amunisi"),
        headers: {
          "Authorization": token.toString(),
          "Content-Type": "application/json",
        },
        body: jsonEncode(data),
      );
    }

    debugPrint(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? "Data amunisi berhasil diperbarui"
                : "Data amunisi berhasil diregistrasi",
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal menyimpan data"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _isEdit = widget.initialData != null;

    if (_isEdit) {
      final data = widget.initialData!;
      kodeBatch.text = data["kode_batch"]?.toString() ?? "";
      jumlahButir.text = data["jumlah_butir"]?.toString() ?? "";
      selectedPoldaId = int.tryParse(data["polda_id"]?.toString() ?? "");
      // Backend returns `kategori` as an eager-loaded nested object
      // (e.g. {"kategori_id": 5, "tipe_laras": "Pistol", "kaliber": "9mm"}).
      // Fall back to a flat top-level `kategori_id` for robustness.
      final rawKategori = data["kategori"];
      selectedKatId = (rawKategori is Map<String, dynamic>)
          ? int.tryParse(rawKategori["kategori_id"]?.toString() ?? "")
          : int.tryParse(data["kategori_id"]?.toString() ?? "");
      tanggalMasuk = _parseDate(data["tanggal_masuk"]);
      tanggalKedaluwarsa = _parseDate(data["tanggal_kedaluwarsa"]);
    }

    getPolda();
    getKategori();
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

  Widget formField({required String label, required Widget child}) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: scheme.onSurface)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _dateField({
    required String label,
    required String hint,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return formField(
      label: label,
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: _inputDecoration(scheme).copyWith(
            hintText: hint,
            suffixIcon: Icon(
              Icons.calendar_today,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ),
          child: Text(
            value == null ? hint : _fmt(value),
            style: TextStyle(
              color: value == null ? scheme.onSurfaceVariant : scheme.onSurface,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEdit ? "EDIT DATA AMUNISI" : "TAMBAH DATA AMUNISI",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: scheme.onSurface),
          ),

          const SizedBox(height: 25),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// KOLOM KIRI
              Expanded(
                child: Column(
                  children: [
                    formField(
                      label: "Polda *",
                      child: DropdownButtonFormField<int>(
                        key: _poldaFieldKey,
                        initialValue: daftarPolda.isEmpty ? null : selectedPoldaId,
                        decoration: _inputDecoration(scheme).copyWith(hintText: "Pilih Polda"),
                        items:
                            daftarPolda.map((polda) {
                              return DropdownMenuItem<int>(
                                value: int.parse(polda["id"].toString()),
                                child: Text(polda["nama_polda"]),
                              );
                            }).toList(),
                        onChanged: null,
                      ),
                    ),

                    const SizedBox(height: 20),

                    formField(
                      label: "Kode Batch *",
                      child: TextFormField(
                        controller: kodeBatch,
                        decoration: _inputDecoration(scheme).copyWith(hintText: "Contoh: PROD-001/2026"),
                      ),
                    ),

                    const SizedBox(height: 20),

                    formField(
                      label: "Jumlah Butir *",
                      child: TextFormField(
                        controller: jumlahButir,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(scheme).copyWith(hintText: "Masukkan Jumlah"),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              /// KOLOM KANAN
              Expanded(
                child: Column(
                  children: [
                    formField(
                      label: "Kategori Senjata *",
                      child: DropdownButtonFormField<int>(
                        initialValue: daftarKategori.isEmpty ? null : selectedKatId,
                        decoration: _inputDecoration(scheme).copyWith(hintText: "Pilih Kategori"),
                        items:
                            daftarKategori.map((cat) {
                              return DropdownMenuItem<int>(
                                value: int.parse(cat["kategori_id"].toString()),
                                child: Text("${cat["tipe_laras"]} - ${cat["kaliber"]}"),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedKatId = value;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    _dateField(
                      label: "Tanggal Masuk *",
                      hint: "Pilih Tanggal Masuk",
                      value: tanggalMasuk,
                      onTap: _pickTanggalMasuk,
                    ),

                    const SizedBox(height: 20),

                    _dateField(
                      label: "Tanggal Kedaluwarsa *",
                      hint: "Pilih Tanggal Kedaluwarsa",
                      value: tanggalKedaluwarsa,
                      onTap: _pickTanggalKedaluwarsa,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffF6B300),
                foregroundColor: const Color(0xFF23251D),
                shape: const StadiumBorder(),
              ),
              onPressed: submitData,
              child: Text(_isEdit ? "Update Data" : "Simpan Data", style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Lengkapi semua data bertanda *",
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
