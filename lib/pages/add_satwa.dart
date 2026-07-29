import 'package:flutter/material.dart';
import '../widget/background.dart';
import '../widget/app_sidebar.dart';
import '../widget/form_inputan_satwa.dart';
import '../widget/app_header.dart';
import '../widget/app_footer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddSatwaPage extends StatefulWidget {
  const AddSatwaPage({super.key});

  @override
  State<AddSatwaPage> createState() => _AddSatwaPageState();
}

class _AddSatwaPageState extends State<AddSatwaPage> {
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
              const AppSidebar(currentRoute: "satwa"),

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
                        breadcrumb: "Dashboard / Tambah Satwa",
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
                            "Pengaturan Satwa",
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
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
                              constraints: const BoxConstraints(maxWidth: 1000),
                              child: Card(
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(25),
                                  child: FormTambahSatwa(),
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
