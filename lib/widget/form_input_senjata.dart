import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../../utils/hud_loading.dart';
import '../../widget/hud_loading_spinner.dart';

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
  Uint8List? _imageBytes; // compressed WebP bytes (null on edit = keep existing photo)
  bool _isCompressing = false;
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

  /// Image pipeline: pick -> compress to WebP.
  Future<void> _showImageSourceSheet() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text("Kamera"),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text("Galeri"),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      final compressed = await _compressToWebP(bytes);

      if (!mounted) return;
      setState(() {
        _imageBytes = compressed;
      });
    } catch (e) {
      debugPrint("Gagal mengambil foto: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal mengambil foto (kamera/galeri tidak tersedia)"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// Compress to WebP. Falls back to original bytes when the platform
  /// does not support flutter_image_compress (e.g. Windows/Linux desktop).
  Future<Uint8List> _compressToWebP(Uint8List bytes) async {
    if (!mounted) return bytes;
    setState(() {
      _isCompressing = true;
    });
    try {
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 1280,
        minHeight: 1280,
        quality: 80,
        format: CompressFormat.webp,
      );
      if (result.isNotEmpty) return result;
    } catch (e) {
      debugPrint("WebP compression tidak tersedia, memakai gambar asli: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isCompressing = false;
        });
      }
    }
    return bytes;
  }

  Future<void> submitData() async {
    if (noSeri.text.trim().isEmpty ||
        tahunPengadaan.text.trim().isEmpty ||
        selectedPoldaId == null ||
        selectedKatId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lengkapi semua data bertanda *"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_isEdit && _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Foto senjata wajib diisi"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      HudLoading.show(context, label: "MENYIMPAN...");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";

      // BUG FIX: PHP cannot parse multipart/form-data on PUT — always send
      // POST. ID goes in the URL path for edit mode — never in the body.
      final Uri uri = _isEdit
          ? Uri.parse(
              "$apiBaseUrl/api/v1/logistik/senjata/${widget.initialData!["senjata_id"]}")
          : Uri.parse("$apiBaseUrl/api/v1/logistik/senjata");

      final request = http.MultipartRequest("POST", uri);
      request.headers["Authorization"] = token;
      request.fields["polda_id"] = selectedPoldaId.toString();
      request.fields["nomor_seri"] = noSeri.text.trim();
      request.fields["kategori_id"] = selectedKatId.toString();
      request.fields["tahun_pengadaan"] = tahunPengadaan.text.trim();
      request.fields["status_kelayakan"] = "Baik";

      // Only attach the file when a (new) image was picked.
      if (_imageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            "foto",
            _imageBytes!,
            filename: "senjata_${DateTime.now().millisecondsSinceEpoch}.webp",
          ),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      debugPrint(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        HudLoading.hide(context);
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
      } else {
        HudLoading.hide(context);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal menyimpan data"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      HudLoading.hide(context);
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEdit ? "EDIT DATA SENJATA" : "TAMBAH DATA SENJATA",
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
                        value: daftarPolda.isEmpty ? null : selectedPoldaId,
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
                      label: "No Seri *",
                      child: TextFormField(
                        controller: noSeri,
                        decoration: _inputDecoration(scheme).copyWith(hintText: "Masukkan No Seri"),
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

                    formField(
                      label: "Tahun Pengadaan *",
                      child: TextFormField(
                        controller: tahunPengadaan,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(scheme).copyWith(hintText: "2024"),
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
                    border: Border.all(color: scheme.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isCompressing
                      ? Center(child: HudLoadingSpinner(size: 30))
                      : _imageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                _imageBytes!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : _isEdit
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.image,
                                        size: 80,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "Foto lama tetap dipakai jika tidak diganti",
                                        style: TextStyle(color: scheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                )
                              : Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 80,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                ),

                const SizedBox(height: 10),

                OutlinedButton.icon(
                  onPressed: _isCompressing ? null : _showImageSourceSheet,
                  icon: const Icon(Icons.photo_camera),
                  label: Text("Kamera / Galeri"),
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
