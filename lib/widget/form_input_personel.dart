import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FormTambahPersonel extends StatefulWidget {
  const FormTambahPersonel({super.key});

  @override
  State<FormTambahPersonel> createState() => _FormTambahPersonelState();
}

class _FormTambahPersonelState extends State<FormTambahPersonel> {
  final namaLengkap = TextEditingController();
  final nrp = TextEditingController();
  final polres = TextEditingController();
  final status = TextEditingController();
  int? selectedPoldaId;
  int? selectedPolresId;
  int? selectedPangkatId;
  int? selectedJabatanId;
  List<Map<String, dynamic>> daftarPolda = [];
  List<Map<String, dynamic>> daftarPolres = [];
  List<Map<String, dynamic>> daftarPangkat = [];
  List<Map<String, dynamic>> daftarJabatan = [];

  Future<void> getPolda() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    try {
      final response = await http.get(
        Uri.parse('https://sindomon.yoknusantara.com/api/v1/polda'),
        headers: {"Authorization": token.toString()},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);

        setState(() {
          daftarPolda = List<Map<String, dynamic>>.from(body['data']);
        });
      } else {
        debugPrint(response.body);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> getPangkat() async {
    final ppp = await SharedPreferences.getInstance();
    final kkk = ppp.getString("token");

    try {
      final resp = await http.get(
        Uri.parse('https://sindomon.yoknusantara.com/api/v1/pangkat'),
        headers: {"Authorization": kkk.toString()},
      );

      if (resp.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(resp.body);

        setState(() {
          daftarPangkat = List<Map<String, dynamic>>.from(body['data']);
        });
      } else {
        debugPrint(resp.body);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> getJabatan() async {
    final pppp = await SharedPreferences.getInstance();
    final kkkk = pppp.getString("token");

    try {
      final res = await http.get(
        Uri.parse('https://sindomon.yoknusantara.com/api/v1/jabatan'),
        headers: {"Authorization": kkkk.toString()},
      );

      if (res.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(res.body);

        setState(() {
          daftarJabatan = List<Map<String, dynamic>>.from(body['data']);
        });
      } else {
        debugPrint(res.body);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> submitPersonel() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.post(
      Uri.parse("https://sindomon.yoknusantara.com/api/v1/personel"),
      headers: {"Authorization": token.toString()},
      body: jsonEncode({
        "nrp": nrp.text,
        "nama_lengkap": namaLengkap.text,
        "polda_id": selectedPoldaId,
        "polres_id": selectedPolresId,
        "pangkat_id": selectedPangkatId,
        "jabatan_id": selectedJabatanId,
      }),
    );

    if (!mounted) return;

    final result = jsonDecode(response.body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      setState(() {
        selectedPoldaId = null;
        selectedPolresId = null;
        selectedPangkatId = null;
        selectedJabatanId = null;
      });
      nrp.clear();
      namaLengkap.clear();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result["message"])));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result["message"])));
    }
  }

  @override
  void initState() {
    super.initState();
    getPolda();
    getPangkat();
    getJabatan();
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
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool twoColumn = constraints.maxWidth > 700;

        final double itemWidth =
            twoColumn ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "TAMBAH PERSONEL BARU",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 25),

            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                SizedBox(
                  width: itemWidth,
                  child: formField(
                    label: "NRP *",
                    child: TextFormField(
                      controller: nrp,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),

                SizedBox(
                  width: itemWidth,
                  child: formField(
                    label: "Nama Lengkap *",
                    child: TextFormField(
                      controller: namaLengkap,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),

                SizedBox(
                  width: itemWidth,
                  child: formField(
                    label: "Polda *",
                    child: DropdownButtonFormField<int>(
                      value: selectedPoldaId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text("Pilih Polda"),
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
                          selectedPolresId = null;

                          final selectedPolda = daftarPolda.firstWhere(
                            (item) => int.parse(item["id"]) == value,
                          );

                          daftarPolres = List<Map<String, dynamic>>.from(
                            selectedPolda["polres"] ?? [],
                          );
                        });
                      },
                    ),
                  ),
                ),

                SizedBox(
                  width: itemWidth,
                  child: formField(
                    label: "Polres *",
                    child: DropdownButtonFormField<int>(
                      value: selectedPolresId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text("Pilih Polres"),
                      items:
                          daftarPolres.map((polres) {
                            return DropdownMenuItem<int>(
                              value: int.parse(polres["id"]),
                              child: Text(polres["nama_polres"]),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedPolresId = value;
                        });
                      },
                    ),
                  ),
                ),

                SizedBox(
                  width: itemWidth,
                  child: formField(
                    label: "Pangkat *",
                    child: DropdownButtonFormField<int>(
                      value: selectedPangkatId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text("Pilih Pangkat"),
                      items:
                          daftarPangkat.map((pkt) {
                            return DropdownMenuItem<int>(
                              value: int.parse(pkt["pangkat_id"]),
                              child: Text(pkt["nama_pangkat"]),
                            );
                          }).toList(),
                      onChanged: (v) {
                        setState(() {
                          selectedPangkatId = v;
                        });
                      },
                    ),
                  ),
                ),

                SizedBox(
                  width: itemWidth,
                  child: formField(
                    label: "Jabatan *",
                    child: DropdownButtonFormField<int>(
                      value: selectedJabatanId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text("Pilih Jabatan"),
                      items:
                          daftarJabatan.map((jbt) {
                            return DropdownMenuItem<int>(
                              value: int.parse(jbt["jabatan_id"]),
                              child: Text(jbt["nama_jabatan"]),
                            );
                          }).toList(),
                      onChanged: (v) {
                        setState(() {
                          selectedJabatanId = v;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: submitPersonel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  "Simpan Data",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Lengkapi semua data bertanda *",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        );
      },
    );
  }
}
