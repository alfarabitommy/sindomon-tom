import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../../utils/hud_loading.dart';
import '../../widget/hud_loading_spinner.dart';

/// Form for Sarpras & Altmatsus (add/edit).
///
/// Image Architecture:
/// 1. Camera/Gallery capture via [ImagePicker]
/// 2. WebP compression via [FlutterImageCompress]
/// 3. Multipart upload via [http.MultipartRequest]
class FormTambahSarpras extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const FormTambahSarpras({super.key, this.initialData});

  @override
  State<FormTambahSarpras> createState() => _FormTambahSarprasState();
}

class _FormTambahSarprasState extends State<FormTambahSarpras> {
  // ---------------------------------------------------------------------
  // Field state
  // ---------------------------------------------------------------------
  final kodeBarang = TextEditingController();
  final namaBarang = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes; // compressed WebP bytes (null on edit = keep existing photo)
  bool _isCompressing = false;

  static const List<String> _kategoriItems = [
    'Kendaraan',
    'Perlengkapan Kantor',
    'Perlengkapan Dalmas',
    'Alat Komunikasi',
    'Kendaraan Taktis',
  ];

  static const List<String> _kondisiItems = [
    'Baik',
    'Rusak Ringan',
    'Rusak Berat',
  ];

  String? selectedKategori;
  String? selectedKondisi;
  DateTime? _tahunPengadaan;
  late bool _isEdit;

  // ---------------------------------------------------------------------
  // Image pipeline: pick -> compress to WebP
  // ---------------------------------------------------------------------
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

  // ---------------------------------------------------------------------
  // Tahun pengadaan (YearPicker via showDatePicker in year mode)
  // ---------------------------------------------------------------------
  Future<void> _pickTahunPengadaan() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tahunPengadaan ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      helpText: "Pilih Tahun Pengadaan",
    );
    if (picked == null) return;
    setState(() {
      _tahunPengadaan = picked;
    });
  }

  // ---------------------------------------------------------------------
  // Multipart upload (add + edit)
  // ---------------------------------------------------------------------
  Future<void> submitData() async {
    if (kodeBarang.text.trim().isEmpty ||
        namaBarang.text.trim().isEmpty ||
        selectedKategori == null ||
        selectedKondisi == null ||
        _tahunPengadaan == null) {
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
          content: Text("Foto sarpras wajib diisi"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      HudLoading.show(context, label: "MENYIMPAN...");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";

      final Uri uri = _isEdit
          ? Uri.parse(
              "$apiBaseUrl/api/v1/logistik/sarpras/${widget.initialData!['sarpras_id']}")
          : Uri.parse("$apiBaseUrl/api/v1/logistik/sarpras");

      // PHP cannot parse multipart/form-data on PUT — always send POST.
      // (CI3 routes.php maps POST /sarpras/(:any) to the update handler,
      // so no Laravel _method spoofing is needed.)
      final request = http.MultipartRequest("POST", uri);

      // BUG FIX: ID in URL only — never in the body.
      request.headers["Authorization"] = token;
      request.fields["kode_barang"] = kodeBarang.text.trim();
      request.fields["nama_barang"] = namaBarang.text.trim();
      request.fields["kategori"] = selectedKategori!;
      request.fields["kondisi"] = selectedKondisi!;
      request.fields["tahun_pengadaan"] = _tahunPengadaan!.year.toString();

      // Only attach the file when a (new) image was picked.
      if (_imageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            "foto",
            _imageBytes!,
            filename:
                "sarpras_${DateTime.now().millisecondsSinceEpoch}.webp",
          ),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      debugPrint(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        HudLoading.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit
                  ? "Data sarpras berhasil diperbarui"
                  : "Data sarpras berhasil diregistrasi",
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        HudLoading.hide(context);
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

  // ---------------------------------------------------------------------
  // initState — BUG FIX: read dropdowns from FLAT top-level JSON keys.
  // ---------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _isEdit = widget.initialData != null;

    if (_isEdit) {
      final data = widget.initialData!;
      kodeBarang.text = data["kode_barang"]?.toString() ?? "";
      namaBarang.text = data["nama_barang"]?.toString() ?? "";

      // Flat string key first; guarded Map fallback (no nested crash).
      final rawKategori = data["kategori"];
      if (rawKategori is String) {
        selectedKategori = rawKategori;
      } else if (rawKategori is Map) {
        selectedKategori =
            (rawKategori["nama_kategori"] ?? rawKategori["kategori"])
                ?.toString();
      }

      selectedKondisi = data["kondisi"]?.toString();

      final tahun = int.tryParse(data["tahun_pengadaan"]?.toString() ?? "");
      if (tahun != null) {
        _tahunPengadaan = DateTime(tahun);
      }
    }
  }

  @override
  void dispose() {
    kodeBarang.dispose();
    namaBarang.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------
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
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: scheme.onSurface,
          ),
        ),
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
            _isEdit ? "EDIT DATA SARPRAS" : "TAMBAH DATA SARPRAS",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
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
                      label: "Kode Barang *",
                      child: TextFormField(
                        controller: kodeBarang,
                        decoration: _inputDecoration(scheme).copyWith(
                          hintText: "Contoh: SPR-001",
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    formField(
                      label: "Kategori *",
                      child: DropdownButtonFormField<String>(
                        value: _kategoriItems.contains(selectedKategori)
                            ? selectedKategori
                            : null,
                        decoration: _inputDecoration(scheme).copyWith(
                          hintText: "Pilih Kategori",
                        ),
                        items: _kategoriItems
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedKategori = value;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    formField(
                      label: "Tahun Pengadaan *",
                      child: InkWell(
                        onTap: _pickTahunPengadaan,
                        child: InputDecorator(
                          decoration: _inputDecoration(scheme).copyWith(
                            hintText: "Pilih Tahun Pengadaan",
                            suffixIcon: const Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          child: Text(
                            _tahunPengadaan == null
                                ? "Pilih Tahun Pengadaan"
                                : _tahunPengadaan!.year.toString(),
                            style: TextStyle(
                              color: _tahunPengadaan == null
                                  ? scheme.onSurfaceVariant
                                  : scheme.onSurface,
                              fontSize: 14,
                            ),
                          ),
                        ),
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
                      label: "Nama Barang *",
                      child: TextFormField(
                        controller: namaBarang,
                        decoration: _inputDecoration(scheme).copyWith(
                          hintText: "Masukkan Nama Barang",
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    formField(
                      label: "Kondisi *",
                      child: DropdownButtonFormField<String>(
                        value: _kondisiItems.contains(selectedKondisi)
                            ? selectedKondisi
                            : null,
                        decoration: _inputDecoration(scheme).copyWith(
                          hintText: "Pilih Kondisi",
                        ),
                        items: _kondisiItems
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedKondisi = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          formField(
            label: "Foto Sarpras *",
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
                          : (_isEdit
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
                                )),
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isCompressing ? null : _showImageSourceSheet,
                      icon: const Icon(Icons.photo_camera),
                      label: Text("Kamera / Galeri"),
                    ),
                  ],
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
              child: Text(
                _isEdit ? "Update Data" : "Simpan Data",
                style: TextStyle(fontSize: 18),
              ),
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
