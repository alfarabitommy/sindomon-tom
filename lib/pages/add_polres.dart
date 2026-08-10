import 'package:flutter/material.dart';
import '../widget/form_input_polres.dart';
import '../widget/app_scaffold.dart';
import '../widget/glass_surface.dart';

class AddPolresPage extends StatefulWidget {
  final int? polresId; // null = create, non-null = edit
  final Map<String, dynamic>? polresData; // pre-fill data

  const AddPolresPage({super.key, this.polresId, this.polresData});

  @override
  State<AddPolresPage> createState() => _AddPolresPageState();
}

class _AddPolresPageState extends State<AddPolresPage> {

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppScaffold(
  currentRoute: "polres",
  breadcrumb: widget.polresId != null ? "Dashboard / Edit Polres" : "Dashboard / Tambah Polres",
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
            "Pengaturan Polres",
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
                child: FormTambahPolres(
                  polresId: widget.polresId,
                  polresData: widget.polresData,
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
