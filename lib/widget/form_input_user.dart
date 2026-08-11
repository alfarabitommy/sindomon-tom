import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../../utils/hud_loading.dart';

class FormTambahUser extends StatefulWidget {
  final int? userId; // null = create mode, non-null = edit mode
  final Map<String, dynamic>? initialData; // pre-fill data for edit

  const FormTambahUser({
    super.key,
    this.userId,
    this.initialData,
  });

  @override
  State<FormTambahUser> createState() => _FormTambahUserState();
}

class _FormTambahUserState extends State<FormTambahUser> {
  late bool aktif;
  late String? selectedRoleId; // "1", "2", or "3" — matches API role_id
  late String? selectedPoldaId; // polda id from API, null = no polda
  List<Map<String, dynamic>> daftarPolda = [];
  bool isEditMode = false;
  final username = TextEditingController();
  final password = TextEditingController();

  static InputDecoration _inputDecoration(ColorScheme scheme) =>
      InputDecoration(
    filled: true,
    fillColor: scheme.surfaceContainerHighest,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: scheme.outlineVariant),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: scheme.outlineVariant, width: 1),
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
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: scheme.onSurface)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    isEditMode = widget.userId != null && widget.initialData != null;

    if (isEditMode && widget.initialData != null) {
      final data = widget.initialData!;
      username.text = data["username"]?.toString() ?? "";
      // Password intentionally left blank — user enters new one only if changing
      password.text = "";

      // Map role_id (integer or string) to dropdown value
      final rawRole = data["roles_id"];
      if (rawRole != null) {
        selectedRoleId = rawRole.toString(); // "1", "2", "3"
      } else {
        selectedRoleId = "2"; // default Operator Polda
      }

      selectedPoldaId = data["polda_id"]?.toString();

      // Status: map API value to bool
      final rawStatus = data["status"]?.toString().toLowerCase() ?? "";
      aktif =
          rawStatus == "aktif" || rawStatus == "1" || rawStatus == "active";
    } else {
      // Create mode defaults
      selectedRoleId = "2";
      selectedPoldaId = null;
      aktif = true;
    }

    getPoldaList();
  }

  Future<void> getPoldaList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final response = await http.get(
        Uri.parse("$apiBaseUrl/api/v1/polda"),
        headers: {"Authorization": token.toString()},
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            daftarPolda = List<Map<String, dynamic>>.from(json["data"] ?? []);
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal memuat daftar polda: $e");
    }
  }

  Future<void> submitUser() async {
    // Validate required fields
    if (username.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Username wajib diisi"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!isEditMode && password.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password wajib diisi untuk akun baru"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedRoleId == "2" &&
        (selectedPoldaId == null || selectedPoldaId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Polda wajib diisi untuk Operator Polda"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      HudLoading.show(context, label: "MENYIMPAN...");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      // Build request body
      final Map<String, dynamic> body = {
        "username": username.text.trim(),
        "roles_id": selectedRoleId,
        "status": aktif ? "aktif" : "tidak_aktif",
      };

      // Only include polda_id for Operator Polda
      if (selectedRoleId == "2" && selectedPoldaId != null) {
        body["polda_id"] = selectedPoldaId;
      } else {
        body["polda_id"] = null; // Super Admin / Command Center
      }

      // Password: required for create, optional for edit (omit if blank)
      if (isEditMode) {
        if (password.text.trim().isNotEmpty) {
          body["password"] = password.text.trim();
        }
        // If password is blank in edit mode, don't send it at all
      } else {
        body["password"] = password.text.trim(); // required for create
      }

      final http.Response response;

      if (isEditMode) {
        // PUT /api/v1/user/:id
        response = await http.put(
          Uri.parse("$apiBaseUrl/api/v1/user/${widget.userId}"),
          headers: {
            "Authorization": token.toString(),
            "Content-Type": "application/json",
          },
          body: jsonEncode(body),
        );
      } else {
        // POST /api/v1/user
        response = await http.post(
          Uri.parse("$apiBaseUrl/api/v1/user"),
          headers: {
            "Authorization": token.toString(),
            "Content-Type": "application/json",
          },
          body: jsonEncode(body),
        );
      }

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        HudLoading.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result["message"] ??
                (isEditMode
                    ? "Pengguna berhasil diupdate"
                    : "Pengguna berhasil ditambahkan")),
            backgroundColor: Colors.green,
          ),
        );
        // Pop back to user list (the list page will refresh via .then() callback)
        Navigator.pop(context, true); // true = data changed, triggers refresh
      } else {
        if (!mounted) return;
        HudLoading.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result["message"] ?? "Gagal menyimpan data"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      HudLoading.hide(context);
      debugPrint("Error submit user: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Terjadi kesalahan jaringan"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 700;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditMode ? "EDIT AKUN" : "TAMBAH AKUN BARU",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface),
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
                          decoration: _inputDecoration(scheme),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: formField(
                        label: isEditMode
                            ? "Password (kosongkan jika tidak berubah)"
                            : "Password *",
                        child: TextFormField(
                          controller: password,
                          obscureText: true,
                          decoration: _inputDecoration(scheme),
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
                    decoration: _inputDecoration(scheme),
                  ),
                ),
                const SizedBox(height: 20),
                formField(
                  label: isEditMode
                      ? "Password (kosongkan jika tidak berubah)"
                      : "Password *",
                  child: TextFormField(
                    controller: password,
                    obscureText: true,
                    decoration: _inputDecoration(scheme),
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
                          initialValue: selectedRoleId,
                          decoration: _inputDecoration(scheme),
                          items: const [
                            DropdownMenuItem(
                              value: "1",
                              child: Text("Super Admin"),
                            ),
                            DropdownMenuItem(
                              value: "2",
                              child: Text("Operator Polda"),
                            ),
                            DropdownMenuItem(
                              value: "3",
                              child: Text("Command Center"),
                            ),
                          ],
                          onChanged: (v) {
                            setState(() {
                              selectedRoleId = v;
                              // Clear polda selection if role changes away from Operator Polda
                              if (v != "2") {
                                selectedPoldaId = null;
                              }
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
                    initialValue: selectedRoleId,
                    decoration: _inputDecoration(scheme),
                    items: const [
                      DropdownMenuItem(
                        value: "1",
                        child: Text("Super Admin"),
                      ),
                      DropdownMenuItem(
                        value: "2",
                        child: Text("Operator Polda"),
                      ),
                      DropdownMenuItem(
                        value: "3",
                        child: Text("Command Center"),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() {
                        selectedRoleId = v;
                        // Clear polda selection if role changes away from Operator Polda
                        if (v != "2") {
                          selectedPoldaId = null;
                        }
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

              if (selectedRoleId == "2") ...[
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
                                initialValue: selectedPoldaId,
                                decoration: _inputDecoration(scheme),
                                hint: const Text("Pilih Polda"),
                                items: daftarPolda.map((p) {
                                  return DropdownMenuItem<String>(
                                    value: p["id"]?.toString(),
                                    child: Text(
                                        p["nama_polda"]?.toString() ?? "-"),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  setState(() {
                                    selectedPoldaId = v;
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
                          initialValue: selectedPoldaId,
                          decoration: _inputDecoration(scheme),
                          hint: const Text("Pilih Polda"),
                          items: daftarPolda.map((p) {
                            return DropdownMenuItem<String>(
                              value: p["id"]?.toString(),
                              child:
                                  Text(p["nama_polda"]?.toString() ?? "-"),
                            );
                          }).toList(),
                          onChanged: (v) {
                            setState(() {
                              selectedPoldaId = v;
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
                  onPressed: submitUser,
                  child: Text(
                    isEditMode ? "Update Akun" : "Simpan Akun",
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "Lengkapi semua data bertanda *",
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        );
      },
    );
  }
}
