import 'package:flutter/material.dart';
import '../widget/form_input_amunisi.dart';
import '../widget/app_scaffold.dart';
import '../widget/glass_surface.dart';

class AddAmunisiPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const AddAmunisiPage({super.key, this.initialData});

  @override
  State<AddAmunisiPage> createState() => _AddAmunisiPageState();
}

class _AddAmunisiPageState extends State<AddAmunisiPage> {

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppScaffold(
  currentRoute: "ammo_stock",
  breadcrumb: widget.initialData != null ? "Dashboard / Edit Amunisi" : "Dashboard / Tambah Amunisi",
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 25),

      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Pengaturan Stok Amunisi",
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
                child: FormTambahAmunisi(
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
