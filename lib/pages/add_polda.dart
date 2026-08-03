import 'package:flutter/material.dart';
import '../widget/background.dart';
import '../widget/app_sidebar.dart';
import '../widget/form_input_polda.dart';
import '../widget/app_header.dart';
import '../widget/app_footer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddPoldaPage extends StatefulWidget {
  final int? poldaId; // null = create, non-null = edit
  final Map<String, dynamic>? poldaData; // pre-fill data

  const AddPoldaPage({super.key, this.poldaId, this.poldaData});

  @override
  State<AddPoldaPage> createState() => _AddPoldaPageState();
}

class _AddPoldaPageState extends State<AddPoldaPage> {
  String unLogin = "";
  String roleLabel = "Operator";

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      unLogin = prefs.getString("username_login") ?? "";
      roleLabel = AppSidebar.roleLabelFromId(prefs.getString("roleid_login"));
    });
  }

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        imagePath: 'assets/images/wp-putih-mabes.png',
        child: SafeArea(
          child: Row(
            children: [
              const AppSidebar(currentRoute: "polda"),

              /// ========================
              /// CONTENT
              /// ========================
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// ============================
                      /// HEADER
                      /// ============================
                      AppHeader(
                        breadcrumb:
                            widget.poldaId != null
                                ? "Dashboard / Edit Polda"
                                : "Dashboard / Tambah Polda",
                        username: unLogin,
                        role: roleLabel,
                      ),

                      const SizedBox(height: 25),

                      /// ============================
                      /// TITLE
                      /// ============================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Pengaturan Polda",
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
                                  side: BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 1.5,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(25),
                                  child: FormTambahPolda(
                                    poldaId: widget.poldaId,
                                    poldaData: widget.poldaData,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const AppFooter(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
