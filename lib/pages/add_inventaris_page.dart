import 'package:flutter/material.dart';
import '../widget/form_inputan_inventaris.dart';
import '../widget/app_scaffold.dart';
import '../widget/glass_surface.dart';

class AddInventarisPage extends StatefulWidget {
  const AddInventarisPage({super.key});

  @override
  State<AddInventarisPage> createState() => _AddInventarisPageState();
}

class _AddInventarisPageState extends State<AddInventarisPage> {

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppScaffold(
  currentRoute: "inventaris",
  breadcrumb: "Dashboard / Tambah Inventaris",
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 25),

      /// ============================
      /// TITLE
      /// ============================
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Pengaturan Inventaris",
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

      /// ============================
      /// FORM
      /// ============================
      Expanded(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: GlassSurface(
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(25),
                child: const FormTambahInventaris(),
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
