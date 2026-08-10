import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/api_config.dart';
import '../../utils/hud_loading.dart';
import '../../widget/hud_loading_spinner.dart';

/// Form for Satwa K9 & Turangga (add/edit).
///
/// Image Architecture:
/// 1. Camera/Gallery capture via [ImagePicker]
/// 2. WebP compression via [FlutterImageCompress]
/// 3. Multipart upload via [http.MultipartRequest] — POST for BOTH modes.
class FormInputanSatwa extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const FormInputanSatwa({super.key, this.initialData});

  @override
  State<FormInputanSatwa> createState() => _FormInputanSatwaState();
}

class _FormInputanSatwaState extends State<FormInputanSatwa> {
  // ---------------------------------------------------------------------
  // Field state
  // ---------------------------------------------------------------------
  final nomorRegistrasi = TextEditingController();
  final namaSatwa = TextEditingController();
  final namaHandler = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes; // compressed WebP bytes (null on edit = keep existing photo)
  bool _isCompressing = false;

  static const List<String> _jenisItems = ['K9', 'Turangga'];

  static const List<String> _kualifikasiItems = [
    'Narkotika',
    'Handak',
    'Dalmas',
    'Kriminal Umum',
    'Patroli',
    'Pelacak',
  ];

  String? selectedJenisSatwa;
  String? selectedKualifikasi;
  DateTime? _jadwalVaksin;
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
                title: const Text("Kamera"),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Galeri"),
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
  // Jadwal vaksin (DatePicker)
  // ---------------------------------------------------------------------
  Future<void> _pickJadwalVaksin() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _jadwalVaksin ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: "Pilih Jadwal Vaksin",
    );
    if (picked == null) return;
    setState(() {
      _jadwalVaksin = picked;
    });
  }

  String _formatDate(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-"
      "${d.month.toString().padLeft(2, '0')}-"
      "${d.day.toString().padLeft(2, '0')}";

  /// Builds the edit-mode photo preview using the same fallback key chain
  /// as the list page (foto_url → foto_satwa → foto).
  Widget _buildPhotoPreview() {
    final rawFoto =
        widget.initialData!["foto_url"] ??
        widget.initialData!["foto_satwa"] ??
        widget.initialData!["foto"];
    final url = _resolveImageUrl(rawFoto);

    if (url.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image, size: 80, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              "Foto lama tetap dipakai jika tidak diganti",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade100,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 60,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Safe image URL concatenation for the edit-mode preview
  // ---------------------------------------------------------------------
  String _resolveImageUrl(dynamic raw) {
    final url = raw?.toString() ?? "";
    if (url.isEmpty) return "";
    if (url.startsWith("http://") || url.startsWith("https://")) return url;
    return url.startsWith("/") ? "$apiBaseUrl$url" : "$apiBaseUrl/$url";
  }

  // ---------------------------------------------------------------------
  // Multipart upload (add + edit)
  // ---------------------------------------------------------------------
  Future<void> submitData() async {
    if (nomorRegistrasi.text.trim().isEmpty ||
        selectedJenisSatwa == null ||
        namaSatwa.text.trim().isEmpty ||
        namaHandler.text.trim().isEmpty ||
        selectedKualifikasi == null ||
        _jadwalVaksin == null) {
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
          content: Text("Foto satwa wajib diisi"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      HudLoading.show(context, label: "MENYIMPAN...");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";

      // BUG FIX (Rule 4): ID goes in the URL path for edit mode — never in the body.
      final Uri uri = _isEdit
          ? Uri.parse(
              "$apiBaseUrl/api/v1/logistik/satwa/${widget.initialData!['satwa_id']}")
          : Uri.parse("$apiBaseUrl/api/v1/logistik/satwa");

      // BUG FIX (Rule 1): PHP cannot parse multipart/form-data on PUT —
      // ALWAYS send POST, for create AND edit.
      final request = http.MultipartRequest("POST", uri);

      request.headers["Authorization"] = token;
      request.fields["nomor_registrasi"] = nomorRegistrasi.text.trim();
      request.fields["jenis_satwa"] = selectedJenisSatwa!;
      request.fields["nama_satwa"] = namaSatwa.text.trim();
      request.fields["nama_handler"] = namaHandler.text.trim();
      request.fields["kualifikasi"] = selectedKualifikasi!;
      request.fields["jadwal_vaksin"] = _formatDate(_jadwalVaksin!);

      // Only attach the file when a (new) image was picked.
      if (_imageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            "foto",
            _imageBytes!,
            filename: "satwa_${DateTime.now().millisecondsSinceEpoch}.webp",
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
                  ? "Data satwa berhasil diperbarui"
                  : "Data satwa berhasil diregistrasi",
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

  // ---------------------------------------------------------------------
  // initState — BUG FIX (Rule 5): read dropdowns from FLAT top-level JSON keys.
  // ---------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _isEdit = widget.initialData != null;

    if (_isEdit) {
      final data = widget.initialData!;
      nomorRegistrasi.text =
          data["nomor_registrasi"]?.toString() ??
          data["no_registrasi"]?.toString() ??
          "";
      namaSatwa.text =
          data["nama_satwa"]?.toString() ?? data["nama"]?.toString() ?? "";
      namaHandler.text = data["nama_handler"]?.toString() ?? "";

      // Flat string key first; guarded Map fallback (no nested crash).
      final rawJenis = data["jenis_satwa"] ?? data["jenis"];
      if (rawJenis is String && _jenisItems.contains(rawJenis)) {
        selectedJenisSatwa = rawJenis;
      } else if (rawJenis is Map) {
        final v =
            (rawJenis["nama_jenis"] ?? rawJenis["jenis_satwa"] ?? rawJenis["jenis"])
                ?.toString();
        if (v != null && _jenisItems.contains(v)) {
          selectedJenisSatwa = v;
        }
      }

      final rawKualifikasi = data["kualifikasi"];
      if (rawKualifikasi is String &&
          _kualifikasiItems.contains(rawKualifikasi)) {
        selectedKualifikasi = rawKualifikasi;
      } else if (rawKualifikasi is Map) {
        final v =
            (rawKualifikasi["nama_kualifikasi"] ??
                    rawKualifikasi["kualifikasi"])
                ?.toString();
        if (v != null && _kualifikasiItems.contains(v)) {
          selectedKualifikasi = v;
        }
      }

      final vaksin = data["jadwal_vaksin"]?.toString() ?? "";
      if (vaksin.isNotEmpty) {
        _jadwalVaksin = DateTime.tryParse(vaksin);
      }
    }
  }

  @override
  void dispose() {
    nomorRegistrasi.dispose();
    namaSatwa.dispose();
    namaHandler.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------
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
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF374151),
          ),
        ),
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
            _isEdit ? "EDIT DATA SATWA" : "TAMBAH DATA SATWA",
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
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
                      label: "Nomor Registrasi *",
                      child: TextFormField(
                        controller: nomorRegistrasi,
                        decoration: _inputDecoration.copyWith(
                          hintText: "Masukkan Nomor Registrasi",
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    formField(
                      label: "Jenis Satwa *",
                      child: DropdownButtonFormField<String>(
                        value: _jenisItems.contains(selectedJenisSatwa)
                            ? selectedJenisSatwa
                            : null,
                        decoration: _inputDecoration.copyWith(
                          hintText: "Pilih Jenis Satwa",
                        ),
                        items: _jenisItems
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedJenisSatwa = value;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    formField(
                      label: "Nama Satwa *",
                      child: TextFormField(
                        controller: namaSatwa,
                        decoration: _inputDecoration.copyWith(
                          hintText: "Contoh : Rex",
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
                      label: "Nama Handler *",
                      child: TextFormField(
                        controller: namaHandler,
                        // BUG FIX: text input — nama handler is a NAME, not a number.
                        keyboardType: TextInputType.text,
                        decoration: _inputDecoration.copyWith(
                          hintText: "Contoh : Bripka Sanut",
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    formField(
                      label: "Kualifikasi *",
                      child: DropdownButtonFormField<String>(
                        value: _kualifikasiItems.contains(selectedKualifikasi)
                            ? selectedKualifikasi
                            : null,
                        decoration: _inputDecoration.copyWith(
                          hintText: "Pilih Kualifikasi",
                        ),
                        items: _kualifikasiItems
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedKualifikasi = value;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    formField(
                      label: "Jadwal Vaksin *",
                      child: InkWell(
                        onTap: _pickJadwalVaksin,
                        child: InputDecorator(
                          decoration: _inputDecoration.copyWith(
                            hintText: "Pilih Jadwal Vaksin",
                            suffixIcon: const Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          child: Text(
                            _jadwalVaksin == null
                                ? "Pilih Jadwal Vaksin"
                                : _formatDate(_jadwalVaksin!),
                            style: TextStyle(
                              color: _jadwalVaksin == null
                                  ? Colors.grey.shade400
                                  : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          formField(
            label: "Foto Satwa *",
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isCompressing
                      ? const Center(child: HudLoadingSpinner(size: 30))
                      : _imageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                _imageBytes!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : _isEdit
                              ? _buildPhotoPreview()
                              : const Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                                ),
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed:
                          _isCompressing ? null : _showImageSourceSheet,
                      icon: const Icon(Icons.photo_camera),
                      label: const Text("Kamera / Galeri"),
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
                style: const TextStyle(fontSize: 18),
              ),
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
