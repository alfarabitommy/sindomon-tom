import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class FormTambahInventaris extends StatefulWidget {
  const FormTambahInventaris({super.key});

  @override
  State<FormTambahInventaris> createState() => _FormTambahInventarisState();
}

class _FormTambahInventarisState extends State<FormTambahInventaris> {
  final namaassets = TextEditingController();
  final kondisi = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;

  String? kategori;
  String kualifikasi = "Narkotika";

  Future<void> _showPicker() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text("Galeri"),
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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TAMBAH DATA INVENTARIS",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: scheme.onSurface),
          ),

          const SizedBox(height: 25),

          /// No Seri
          Text(
            "Nama Asset *",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: scheme.onSurface),
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: namaassets,
            decoration: _inputDecoration(scheme).copyWith(hintText: "Masukkan Nama Assets"),
          ),

          const SizedBox(height: 20),

          /// Kategori
          Text(
            "Kategori Assets *",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: scheme.onSurface),
          ),
 
          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            value: kategori,
            decoration: _inputDecoration(scheme),
            hint: Text("Pilih Pangkat"),
            items: const [
              DropdownMenuItem(value: "rantis", child: Text("Rantis")),
              DropdownMenuItem(value: "water_canon", child: Text("Water Canon")),
            ],
            onChanged: (value) {
              setState(() {
                kategori = value!;
              });
            },
          ),

          const SizedBox(height: 20),

          /// Tahun Pengadaan
          Text(
            "Kondisi *",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: scheme.onSurface),
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: kondisi,
            keyboardType: TextInputType.text,
            decoration: _inputDecoration(scheme).copyWith(hintText: "Contoh : baik"),
          ),

          const SizedBox(height: 20),

          /// Upload Foto
          Text(
            "Foto Satwa *",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: scheme.onSurface),
          ),

          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                _imageBytes != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _imageBytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 180,
                      ),
                    )
                    : Center(
                      child: Icon(Icons.image, size: 80, color: scheme.onSurfaceVariant),
                    ),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: () {
              _showPicker();
            },
            icon: const Icon(Icons.photo_camera),
            label: Text("Pilih Foto"),
          ),

          const SizedBox(height: 30),

          /// Tombol Submit
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffF6B300),
                foregroundColor: const Color(0xFF23251D),
                shape: const StadiumBorder(),
              ),
              onPressed: () {},
              child: Text("Submit", style: TextStyle(fontSize: 18)),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            "* Semua data wajib diisi",
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
