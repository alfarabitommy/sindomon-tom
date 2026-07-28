import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FormTambahPolda extends StatefulWidget {
  const FormTambahPolda({super.key});

  @override
  State<FormTambahPolda> createState() => _FormTambahPoldaState();
}

class _FormTambahPoldaState extends State<FormTambahPolda> {
  String? pangkat;
  final namaPolda = TextEditingController();
  final lat = TextEditingController();
  final long = TextEditingController();
  bool loading = false;


  Future<void> simpanPolda() async {
    if (namaPolda.text.isEmpty || lat.text.isEmpty || long.text.isEmpty) {
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
        Uri.parse("https://sindomon.yoknusantara.com/api/v1/polda"),
        headers: {"authorization": token.toString()},

        body: jsonEncode({
          "nama_polda": namaPolda.text,
          "latitude": lat.text,
          "longitude": long.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data Polda berhasil disimpan")),
        );

        namaPolda.clear();
        lat.clear();
        long.clear();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal: ${response.body}")));
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "TAMBAH POLDA BARU",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 25),

        const Text(
          "Nama Polda *",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: namaPolda,
          decoration: InputDecoration(border: OutlineInputBorder()),
        ),

        const SizedBox(height: 20),

        const Text("Latitude*", style: TextStyle(fontWeight: FontWeight.bold)),

        const SizedBox(height: 8),

        TextFormField(
          controller: lat,
          decoration: InputDecoration(border: OutlineInputBorder()),
        ),

        const SizedBox(height: 20),

        const Text(
          "Longitude *",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        TextFormField(
          controller: long,
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
            onPressed: () {simpanPolda();},
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
