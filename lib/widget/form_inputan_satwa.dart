import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class FormTambahSatwa extends StatefulWidget {
  const FormTambahSatwa({super.key});

  @override
  State<FormTambahSatwa> createState() => _FormTambahSatwaState();
}

class _FormTambahSatwaState extends State<FormTambahSatwa> {
  final noRegistrasi = TextEditingController();
  final namaHandler = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;

  // ignore: non_constant_identifier_names
  String Jenis = "K9";
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TAMBAH DATA SATWA",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),

          const SizedBox(height: 25),

          /// No Seri
          const Text(
            "No Registrasi *",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF374151)),
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: noRegistrasi,
            decoration: _inputDecoration.copyWith(hintText: "Masukkan No Registrasi"),
          ),

          const SizedBox(height: 20),

          /// Kategori
          const Text(
            "Jenis Satwa *",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF374151)),
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            value: Jenis,
            decoration: _inputDecoration,
            items: const [
              DropdownMenuItem(value: "K9", child: Text("K9")),
              DropdownMenuItem(value: "K8", child: Text("K8")),
              DropdownMenuItem(
                value: "K7",
                child: Text("K7"),
              ),
              DropdownMenuItem(
                value: "K6",
                child: Text("K6"),
              ),
            ],
            onChanged: (value) {
              setState(() {
                Jenis = value!;
              });
            },
          ),

          const SizedBox(height: 20),

          /// Tahun Pengadaan
          const Text(
            "Nama Handler *",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF374151)),
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: namaHandler,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration.copyWith(hintText: "Contoh : Sanut Handler"),
          ),

          const SizedBox(height: 20),

          /// Status Kelayakan
          const Text(
            "Kualifikasi *",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF374151)),
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            value: kualifikasi,
            decoration: _inputDecoration,
            items: const [
              DropdownMenuItem(value: "Narkotika", child: Text("Narkotika")),
              DropdownMenuItem(
                value: "Handak",
                child: Text("Handak"),
              ),
            ],
            onChanged: (value) {
              setState(() {
                kualifikasi = value!;
              });
            },
          ),

          const SizedBox(height: 20),

          /// Upload Foto
          const Text(
            "Foto Satwa *",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF374151)),
          ),

          const SizedBox(height: 10),

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
                        width: double.infinity,
                        height: 180,
                      ),
                    )
                    : const Center(
                      child: Icon(Icons.image, size: 80, color: Colors.grey),
                    ),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: () {
              _showPicker();
            },
            icon: const Icon(Icons.photo_camera),
            label: const Text("Pilih Foto"),
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
              child: const Text("Submit", style: TextStyle(fontSize: 18)),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "* Semua data wajib diisi",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
