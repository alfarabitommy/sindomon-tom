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

  Widget formField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
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
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
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
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                formField(
                  label: "Password *",
                  child: TextFormField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
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
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
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
