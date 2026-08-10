import 'package:flutter/material.dart';
import '../widget/form_input_personel.dart';
import '../widget/app_scaffold.dart';

class AddPersonelPage extends StatefulWidget {
  final String? personilId; // null = create, non-null = edit
  final Map<String, dynamic>? personilData; // pre-fill data

  const AddPersonelPage({super.key, this.personilId, this.personilData});

  @override
  State<AddPersonelPage> createState() => _AddPersonelPageState();
}

class _AddPersonelPageState extends State<AddPersonelPage> {

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
  currentRoute: "personel",
  breadcrumb: widget.personilId != null ? "Dashboard / Edit Personel" : "Dashboard / Tambah Personel",
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
            "Pengaturan Personel",
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
                  child: FormTambahPersonel(
                    personilId: widget.personilId,
                    personilData: widget.personilData,
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
