import 'package:flutter/material.dart';
import '../widget/form_inputan_satwa.dart';
import '../widget/app_scaffold.dart';
import '../widget/glass_surface.dart';

class AddSatwaPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const AddSatwaPage({super.key, this.initialData});

  @override
  State<AddSatwaPage> createState() => _AddSatwaPageState();
}

class _AddSatwaPageState extends State<AddSatwaPage> {

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppScaffold(
  currentRoute: "satwa",
  breadcrumb: widget.initialData != null ? "Dashboard / Edit Satwa K9 & Turangga" : "Dashboard / Tambah Satwa K9 & Turangga",
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
            "Pengaturan Satwa",
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
      /// (form pops with `true` on success → list page refreshes)
      /// ============================
      Expanded(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: GlassSurface(
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(25),
                child: FormInputanSatwa(
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
