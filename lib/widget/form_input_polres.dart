import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FormTambahPolres extends StatefulWidget {
  const FormTambahPolres({super.key});

  @override
  State<FormTambahPolres> createState() => _FormTambahPolresState();
}

class _FormTambahPolresState extends State<FormTambahPolres> {
  // final poldaID = TextEditingController();
  int? selectedPoldaId;
  bool loading = false;
  final namaPolres = TextEditingController();
  List<Map<String, dynamic>> daftarPolda = [];

  Future<void> getPolda() async {
    final sharep = await SharedPreferences.getInstance();
    final ptoken = sharep.getString("token");

    try {
      final respon = await http.get(
        Uri.parse('https://sindomon.yoknusantara.com/api/v1/polda'),
        headers: {"Authorization": ptoken.toString()},
      );

      if (respon.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(respon.body);
        // print(respon.body);
        setState(() {
          daftarPolda = List<Map<String, dynamic>>.from(body['data']);
        });
      } else {
        debugPrint(respon.body);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> simpanPolres() async {
    if (selectedPoldaId == null || namaPolres.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Semua data wajib diisi")));

      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.post(
        Uri.parse("https://sindomon.yoknusantara.com/api/v1/polres"),
        headers: {"authorization": token.toString()},

        body: jsonEncode({
          "polda_id": selectedPoldaId,
          "nama_polres": namaPolres.text,
        }),
      );

      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data Polres berhasil disimpan")),
        );

        setState(() {
          selectedPoldaId = null;
        });
        namaPolres.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menyimpan: ${response.body}")),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getPolda();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "TAMBAH POLRES BARU",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 25),

        const Text(
          "Nama Polda *",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        DropdownButtonFormField<int>(
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

        const SizedBox(height: 20),

        const Text(
          "Nama Polres*",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: namaPolres,
          decoration: InputDecoration(border: OutlineInputBorder()),
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:  Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () { simpanPolres(); },
            child: const Text("Simpan Data", style: TextStyle(fontSize: 18)),
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          "Silahkan lengkapi semua data bertanda *",
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
