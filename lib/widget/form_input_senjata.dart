import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class FormTambahSenjata extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const FormTambahSenjata({super.key, this.initialData});

  @override
  State<FormTambahSenjata> createState() => _FormTambahSenjataState();
}

class _FormTambahSenjataState extends State<FormTambahSenjata> {
  final noSeri = TextEditingController();
  final tahunPengadaan = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final GlobalKey<FormFieldState<int>> _poldaFieldKey = GlobalKey<FormFieldState<int>>();
  Uint8List? _imageBytes;
  int? selectedPoldaId;
  int? selectedKatId;
  List<Map<String, dynamic>> daftarPolda = [];
  List<Map<String, dynamic>> daftarKategori = [];
  late bool _isEdit;

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

  Future<void> _showPicker() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Galeri"),
                onTap: () async {
                  Navigator.pop(context);

                  final XFile? file = await _picker.pickImage(
                    source: ImageSource.gallery,
                  );

                  if (file != null) {
                    final bytes = await file.readAsBytes();

                    setState(() {
                      _imageBytes = bytes;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> submitData() async {
    String? base64Image;

    if (_imageBytes != null) {
      base64Image = base64Encode(_imageBytes!);
    }

    final data = {
      "polda_id": selectedPoldaId,
      "nomor_seri": noSeri.text,
      "kategori_id": selectedKatId,
      "tahun_pengadaan": tahunPengadaan.text,
      "status_kelayakan": "Baik",
      "foto_fisik": base64Image,
    };

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final http.Response response;

    if (_isEdit) {
      final editData = Map<String, dynamic>.from(data);
      editData["senjata_id"] = widget.initialData!["senjata_id"];
      response = await http.put(
        Uri.parse("$apiBaseUrl/api/v1/logistik/senjata/${widget.initialData!["senjata_id"]}"),
        headers: {
          "Authorization": token.toString(),
          "Content-Type": "application/json",
        },
        body: jsonEncode(editData),
      );
    } else {
      response = await http.post(
        Uri.parse("$apiBaseUrl/api/v1/logistik/senjata"),
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
                ? "Data senjata berhasil diperbarui"
                : "Data senjata berhasil diregistrasi",
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  void initState() {
    super.initState();
    _isEdit = widget.initialData != null;

    if (_isEdit) {
      final data = widget.initialData!;
      noSeri.text = data["nomor_seri"]?.toString() ?? "";
      tahunPengadaan.text = data["tahun_pengadaan"]?.toString() ?? "";
      selectedPoldaId = int.tryParse(data["polda_id"]?.toString() ?? "");
      selectedKatId = int.tryParse(data["kategori_id"]?.toString() ?? "");
    }

    getPolda();
    getKategori();
  }

  static const InputDecoration _inputDecoration = InputDecoration(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF374151))),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEdit ? "EDIT DATA SENJATA" : "TAMBAH DATA SENJATA",
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
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
                        value: daftarPolda.isEmpty ? null : selectedPoldaId,
                        decoration: _inputDecoration.copyWith(hintText: "Pilih Polda"),
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
                      label: "No Seri *",
                      child: TextFormField(
                        controller: noSeri,
                        decoration: _inputDecoration.copyWith(hintText: "Masukkan No Seri"),
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
                        value: daftarKategori.isEmpty ? null : selectedKatId,
                        decoration: _inputDecoration.copyWith(hintText: "Pilih Kategori"),
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

                    formField(
                      label: "Tahun Pengadaan *",
                      child: TextFormField(
                        controller: tahunPengadaan,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration.copyWith(hintText: "2024"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          formField(
            label: "Foto Senjata *",
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      _imageBytes != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _imageBytes!,
                              fit: BoxFit.cover,
                            ),
                          )
                          : const Center(
                            child: Icon(
                              Icons.image,
                              size: 80,
                              color: Colors.grey,
                            ),
                          ),
                ),

                const SizedBox(height: 10),

                OutlinedButton.icon(
                  onPressed: _showPicker,
                  icon: const Icon(Icons.photo_camera),
                  label: const Text("Pilih Foto"),
                ),
              ],
            ),
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
              child: Text(_isEdit ? "Update Data" : "Simpan Data", style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Lengkapi semua data bertanda *",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
