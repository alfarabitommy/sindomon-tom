import 'package:flutter/material.dart';
import '../widget/form_input_senjata.dart';
import '../widget/app_scaffold.dart';

class AddSenjataPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const AddSenjataPage({super.key, this.initialData});

  @override
  State<AddSenjataPage> createState() => _AddSenjataPageState();
}

class _AddSenjataPageState extends State<AddSenjataPage> {

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
  currentRoute: "senjata",
  breadcrumb: widget.initialData != null ? "Dashboard / Edit Senjata" : "Dashboard / Tambah Senjata",
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
          const Text(
            "Pengaturan Senjata",
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
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
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200, width: 1.5),
                ),
                  child: Padding(
                    padding: const EdgeInsets.all(25),
                    child: FormTambahSenjata(
                      initialData: widget.initialData,
                    ),
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
