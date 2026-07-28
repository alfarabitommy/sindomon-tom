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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TAMBAH DATA INVENTARIS",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 25),

          /// No Seri
          const Text(
            "Nama Asset *",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: namaassets,
            decoration: const InputDecoration(
              hintText: "Masukkan Nama Assets",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          /// Kategori
          const Text(
            "Kategori Assets *",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
 
          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            value: kategori,
            hint: const Text("Pilih Pangkat"),
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
          const Text(
            "Kondisi *",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: kondisi,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              hintText: "Contoh : baik",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          /// Upload Foto
          const Text(
            "Foto Satwa *",
            style: TextStyle(fontWeight: FontWeight.bold),
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
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
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
