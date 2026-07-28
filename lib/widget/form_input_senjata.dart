import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FormTambahSenjata extends StatefulWidget {
  const FormTambahSenjata({super.key});

  @override
  State<FormTambahSenjata> createState() => _FormTambahSenjataState();
}

class _FormTambahSenjataState extends State<FormTambahSenjata> {
  final noSeri = TextEditingController();
  final tahunPengadaan = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  int? selectedPoldaId;
  int? selectedKatId;
  List<Map<String, dynamic>> daftarPolda = [];
  List<Map<String, dynamic>> daftarKategori = [];

  Future<void> getPolda() async {
    final pref = await SharedPreferences.getInstance();
    final tokenn = pref.getString("token");

    try {
      final responses = await http.get(
        Uri.parse('https://sindomon.yoknusantara.com/api/v1/polda'),
        headers: {"Authorization": tokenn.toString()},
      );

      if (responses.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(responses.body);

        setState(() {
          daftarPolda = List<Map<String, dynamic>>.from(body['data']);
        });
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
        Uri.parse('https://sindomon.yoknusantara.com/api/v1/kategori_senjata'),
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
      "no_seri": noSeri.text,
      "kategori": selectedKatId,
      "tahun": tahunPengadaan.text,
      "foto": base64Image,
    };

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.post(
      Uri.parse("https://sindomon.yoknusantara.com/api/v1/senjata"),
      headers: {"authorization": token.toString()},
      body: jsonEncode(data),
    );
    debugPrint(response.body);
  }

  @override
  void initState() {
    super.initState();
    getPolda();
    getKategori();
  }

  Widget formField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
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
          const Text(
            "TAMBAH DATA SENJATA",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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
                        value: selectedPoldaId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Pilih Polda",
                        ),
                        items:
                            daftarPolda.map((polda) {
                              return DropdownMenuItem<int>(
                                value: int.parse(polda["id"]),
                                child: Text(polda["nama_polda"]),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedPoldaId = value;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    formField(
                      label: "No Seri *",
                      child: TextFormField(
                        controller: noSeri,
                        decoration: const InputDecoration(
                          hintText: "Masukkan No Seri",
                          border: OutlineInputBorder(),
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
                      label: "Kategori Senjata *",
                      child: DropdownButtonFormField<int>(
                        value: selectedKatId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Pilih Kategori",
                        ),
                        items:
                            daftarKategori.map((cat) {
                              return DropdownMenuItem<int>(
                                value: int.parse(cat["id"]),
                                child: Text(cat["tipe_laras"]),
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
                        decoration: const InputDecoration(
                          hintText: "2024",
                          border: OutlineInputBorder(),
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
        ],
      ),
    );
  }
}
