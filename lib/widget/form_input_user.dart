import 'package:flutter/material.dart';

class FormTambahUser extends StatefulWidget {
  const FormTambahUser({super.key});

  @override
  State<FormTambahUser> createState() => _FormTambahUserState();
}

class _FormTambahUserState extends State<FormTambahUser> {
  bool aktif = true;
  String role = "Operator Polda";
  String? polda = "Polda Jawa Barat";
  final username = TextEditingController();
  final password = TextEditingController();

  static const InputDecoration _inputDecoration = InputDecoration(
    filled: true,
    fillColor: Color(0xFFF9FAFB),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFFE5E7EB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFFE5E7EB), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFF1D4ED8), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFFEF4444), width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFFEF4444), width: 1.5),
    ),
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  Widget formField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF374151))),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 700;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "TAMBAH AKUN BARU",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
              ),

              const SizedBox(height: 25),

              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: formField(
                        label: "Username *",
                        child: TextFormField(
                          controller: username,
                          decoration: _inputDecoration,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: formField(
                        label: "Password *",
                        child: TextFormField(
                          controller: password,
                          obscureText: true,
                          decoration: _inputDecoration,
                        ),
                      ),
                    ),
                  ],
                )
              else ...[
                formField(
                  label: "Username *",
                  child: TextFormField(
                    controller: username,
                    decoration: _inputDecoration,
                  ),
                ),
                const SizedBox(height: 20),
                formField(
                  label: "Password *",
                  child: TextFormField(
                    controller: password,
                    obscureText: true,
                    decoration: _inputDecoration,
                  ),
                ),
              ],

              const SizedBox(height: 20),

              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: formField(
                        label: "Role *",
                        child: DropdownButtonFormField<String>(
                          value: role,
                          decoration: _inputDecoration,
                          items: const [
                            DropdownMenuItem(
                              value: "Super Admin",
                              child: Text("Super Admin"),
                            ),
                            DropdownMenuItem(
                              value: "Operator Polda",
                              child: Text("Operator Polda"),
                            ),
                            DropdownMenuItem(
                              value: "Operator Polres",
                              child: Text("Operator Polres"),
                            ),
                          ],
                          onChanged: (v) {
                            setState(() {
                              role = v!;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: formField(
                        label: "Status",
                        child: Row(
                          children: [
                            Switch(
                              value: aktif,
                              onChanged: (v) {
                                setState(() {
                                  aktif = v;
                                });
                              },
                            ),
                            Text(aktif ? "Aktif" : "Tidak Aktif"),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              else ...[
                formField(
                  label: "Role *",
                  child: DropdownButtonFormField<String>(
                    value: role,
                    decoration: _inputDecoration,
                    items: const [
                      DropdownMenuItem(
                        value: "Super Admin",
                        child: Text("Super Admin"),
                      ),
                      DropdownMenuItem(
                        value: "Operator Polda",
                        child: Text("Operator Polda"),
                      ),
                      DropdownMenuItem(
                        value: "Operator Polres",
                        child: Text("Operator Polres"),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() {
                        role = v!;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),
                formField(
                  label: "Status",
                  child: Row(
                    children: [
                      Switch(
                        value: aktif,
                        onChanged: (v) {
                          setState(() {
                            aktif = v;
                          });
                        },
                      ),
                      Text(aktif ? "Aktif" : "Tidak Aktif"),
                    ],
                  ),
                ),
              ],

              if (role == "Operator Polda") ...[
                const SizedBox(height: 20),

                if (isDesktop)
                  Row(
                    children: [
                      Expanded(
                        child: formField(
                          label: "Polda *",
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<String>(
                                value: polda,
                                decoration: _inputDecoration,
                                items: const [
                                  DropdownMenuItem(
                                    value: "Polda Jawa Barat",
                                    child: Text("Polda Jawa Barat"),
                                  ),
                                  DropdownMenuItem(
                                    value: "Polda Metro Jaya",
                                    child: Text("Polda Metro Jaya"),
                                  ),
                                  DropdownMenuItem(
                                    value: "Polda Jawa Tengah",
                                    child: Text("Polda Jawa Tengah"),
                                  ),
                                ],
                                onChanged: (v) {
                                  setState(() {
                                    polda = v;
                                  });
                                },
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Wajib diisi jika Operator Polda",
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Expanded(child: SizedBox()),
                    ],
                  )
                else
                  formField(
                    label: "Polda *",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: polda,
                          decoration: _inputDecoration,
                          items: const [
                            DropdownMenuItem(
                              value: "Polda Jawa Barat",
                              child: Text("Polda Jawa Barat"),
                            ),
                            DropdownMenuItem(
                              value: "Polda Metro Jaya",
                              child: Text("Polda Metro Jaya"),
                            ),
                            DropdownMenuItem(
                              value: "Polda Jawa Tengah",
                              child: Text("Polda Jawa Tengah"),
                            ),
                          ],
                          onChanged: (v) {
                            setState(() {
                              polda = v;
                            });
                          },
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Wajib diisi jika Operator Polda",
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
              ],

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffF6B300),
                    foregroundColor: const Color(0xFF23251D),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () {},
                  child: const Text(
                    "Simpan Akun",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Lengkapi semua data bertanda *",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }
}
