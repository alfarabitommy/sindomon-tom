import 'package:flutter/material.dart';
import '../widget/form_input_sarpras.dart';
import '../widget/app_scaffold.dart';
import '../widget/glass_surface.dart';

class AddSarprasPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const AddSarprasPage({super.key, this.initialData});

  @override
  State<AddSarprasPage> createState() => _AddSarprasPageState();
}

class _AddSarprasPageState extends State<AddSarprasPage> {

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppScaffold(
  currentRoute: "sarpras",
  breadcrumb: widget.initialData != null ? "Dashboard / Edit Sarpras & Altmatsus" : "Dashboard / Tambah Sarpras & Altmatsus",
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 25),

      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Pengaturan Sarpras & Altmatsus",
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),

          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text("Kembali"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 18,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 25),

      Expanded(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: GlassSurface(
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(25),
                child: FormTambahSarpras(
                  initialData: widget.initialData,
                ),
              ),
            ),
          ),
        ),
      ),

      const SizedBox(height: 20),

    ],
  ),
);
  }
}
