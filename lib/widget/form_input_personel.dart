import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class FormTambahPersonel extends StatefulWidget {
  final String? personilId; // null = create mode, non-null = edit mode
  final Map<String, dynamic>? personilData; // pre-fill data for edit

  const FormTambahPersonel({super.key, this.personilId, this.personilData});

  @override
  State<FormTambahPersonel> createState() => _FormTambahPersonelState();
}

class _FormTambahPersonelState extends State<FormTambahPersonel> {
  // Sentinel for "Tidak Ada / Mako Polda" — 0 is never a valid polres FK.
  // Mapped to null in the request body.
  static const int _polresNone = 0;

  late bool isEditMode;
  bool loading = false;

  final namaLengkap = TextEditingController();
  final nrp = TextEditingController();

  int? selectedPoldaId;
  int? selectedPolresId;
  int? selectedPangkatId;
  int? selectedJabatanId;
  List<Map<String, dynamic>> daftarPolda = [];
  List<Map<String, dynamic>> daftarPolres = [];
  List<Map<String, dynamic>> daftarPangkat = [];
  List<Map<String, dynamic>> daftarJabatan = [];

  // Role context loaded from SharedPreferences.
  // Role "2" (Operator Polda) is locked to their own Polda; roles
  // "1" (Super Admin) and "3" (Command Center) are unrestricted.
  // _userPoldaId: raw string from "polda_login" prefs key
  // _poldaLocked: derived flag — true only when role == "2" AND polda is parseable
  String? _userPoldaId;
  bool _poldaLocked = false;

  int? _toInt(dynamic v) {
    if (v == null) return null;
    return v is int ? v : int.tryParse(v.toString());
  }

  Future<void> getPolda() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/v1/polda'),
        headers: {"Authorization": token.toString()},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);

        setState(() {
          daftarPolda = List<Map<String, dynamic>>.from(body['data']);

          // Re-apply Operator lock after Polda list loads.
          // _loadUserContext() may already have pinned selectedPoldaId,
          // but we need the full daftarPolda list to populate daftarPolres
          // (the dependent Polres dropdown). This is intentionally
          // idempotent — whichever async completes last wins, and both
          // set the same value.
          if (_poldaLocked && _userPoldaId != null) {
            final lockedId = int.tryParse(_userPoldaId!);
            if (lockedId != null) {
              selectedPoldaId = lockedId;
              final match = daftarPolda.where(
                (p) => int.tryParse(p["id"].toString()) == lockedId,
              ).toList();
              if (match.isNotEmpty) {
                daftarPolres = List<Map<String, dynamic>>.from(
                  match.first["polres"] ?? [],
                );
              }
            }
            return; // locked — skip the edit-mode branch below
          }

          // Edit mode (non-locked): match pre-selected polda from
          // initState and populate its polres list.
          if (isEditMode && selectedPoldaId != null) {
            final match = daftarPolda.where(
              (p) => int.tryParse(p["id"].toString()) == selectedPoldaId,
            ).toList();
            if (match.isNotEmpty) {
              daftarPolres = List<Map<String, dynamic>>.from(
                match.first["polres"] ?? [],
              );
            }
          }
        });
      } else {
        debugPrint(response.body);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> getPangkat() async {
    final ppp = await SharedPreferences.getInstance();
    final kkk = ppp.getString("token");

    try {
      final resp = await http.get(
        Uri.parse('$apiBaseUrl/api/v1/pangkat'),
        headers: {"Authorization": kkk.toString()},
      );

      if (resp.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(resp.body);

        setState(() {
          daftarPangkat = List<Map<String, dynamic>>.from(body['data']);
        });
      } else {
        debugPrint(resp.body);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> getJabatan() async {
    final pppp = await SharedPreferences.getInstance();
    final kkkk = pppp.getString("token");

    try {
      final res = await http.get(
        Uri.parse('$apiBaseUrl/api/v1/jabatan'),
        headers: {"Authorization": kkkk.toString()},
      );

      if (res.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(res.body);

        setState(() {
          daftarJabatan = List<Map<String, dynamic>>.from(body['data']);
        });
      } else {
        debugPrint(res.body);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  /// Reads the logged-in user's role and Polda from SharedPreferences.
  /// For Operator Polda (role "2"), derives the [_poldaLocked] flag and
  /// force-sets [selectedPoldaId] to the operator's own Polda.
  ///
  /// Called from [initState]. Runs concurrently with [getPolda]; both
  /// completion paths re-apply the lock so the last writer always wins.
  Future<void> _loadUserContext() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString("roleid_login");
    final polda = prefs.getString("polda_login");

    if (!mounted) return;

    final userPoldaInt = (polda != null && polda.isNotEmpty)
        ? int.tryParse(polda)
        : null;

    setState(() {
      _userPoldaId = polda;

      // Lock only for Operator Polda (role "2") with a usable polda_id.
      // If polda_login is missing or unparseable, leave the dropdown
      // interactive — a locked-but-empty dropdown would block submission.
      _poldaLocked = role == "2" && userPoldaInt != null;

      if (_poldaLocked) {
        // Operator Polda: force their own Polda. This overrides the
        // edit-mode prefill from personilData["polda_id"] (requirement:
        // the backend always uses the JWT polda_id, so the UI must match).
        selectedPoldaId = userPoldaInt;
        selectedPolresId = _polresNone; // repopulated once daftarPolda loads
      }
    });
  }

  Future<void> submitPersonel() async {
    // Field validation before submit (polres_id is optional now)
    if (nrp.text.trim().isEmpty ||
        namaLengkap.text.trim().isEmpty ||
        selectedPoldaId == null ||
        selectedPangkatId == null ||
        selectedJabatanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Semua data wajib diisi"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final Map<String, dynamic> body = {
        "nrp": nrp.text.trim(),
        "nama_lengkap": namaLengkap.text.trim(),
        "polda_id": selectedPoldaId,
        // "Tidak Ada / Mako Polda" (sentinel 0) is sent as null
        "polres_id": (selectedPolresId == null || selectedPolresId == _polresNone)
            ? null
            : selectedPolresId,
        "pangkat_id": selectedPangkatId,
        "jabatan_id": selectedJabatanId,
      };

      final http.Response response;

      if (isEditMode) {
        // PUT /api/v1/sdm/personil/:uuid
        response = await http.put(
          Uri.parse("$apiBaseUrl/api/v1/sdm/personil/${widget.personilId}"),
          headers: {
            "Authorization": token.toString(),
            "Content-Type": "application/json",
          },
          body: jsonEncode(body),
        );
      } else {
        // POST /api/v1/sdm/personil — create new
        response = await http.post(
          Uri.parse("$apiBaseUrl/api/v1/sdm/personil"),
          headers: {
            "Authorization": token.toString(),
            "Content-Type": "application/json",
          },
          body: jsonEncode(body),
        );
      }

      if (!mounted) return;

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result["message"] ??
                  (isEditMode
                      ? "Data Personel berhasil diperbarui"
                      : "Data Personel berhasil disimpan"),
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Pop back to list; list page refreshes via .then() callback
        Navigator.pop(context, true);
      } else if (response.statusCode == 422) {
        // Business validation failure — e.g. NRP already registered.
        // Stay on the form so the user can fix the field.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result["message"] ?? "Validasi data gagal"),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result["message"] ?? "Gagal menyimpan data"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error simpan personel: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Terjadi kesalahan jaringan"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    isEditMode = widget.personilId != null && widget.personilData != null;

    if (isEditMode && widget.personilData != null) {
      final data = widget.personilData!;
      nrp.text = data["nrp"]?.toString() ?? "";
      namaLengkap.text = data["nama_lengkap"]?.toString() ?? "";
      // Pre-set dropdown values synchronously; dropdowns load async and
      // resolve correctly once the fetch setState rebuilds (polres pattern).
      selectedPoldaId = _toInt(data["polda_id"]);
      selectedPolresId = _toInt(data["polres_id"]) ?? _polresNone;
      selectedPangkatId = _toInt(data["pangkat_id"]);
      selectedJabatanId = _toInt(data["jabatan_id"]);
    }

    getPolda();
    getPangkat();
    getJabatan();
    _loadUserContext();
  }

  @override
  void dispose() {
    nrp.dispose();
    namaLengkap.dispose();
    super.dispose();
  }

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
        final bool twoColumn = constraints.maxWidth > 700;

        final double itemWidth =
            twoColumn ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditMode ? "EDIT PERSONEL" : "TAMBAH PERSONEL BARU",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
            ),

            const SizedBox(height: 25),

            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                SizedBox(
                  width: itemWidth,
                  child: formField(
                    label: "NRP *",
                    child: TextFormField(
                      controller: nrp,
                      decoration: _inputDecoration,
                    ),
                  ),
                ),

                SizedBox(
                  width: itemWidth,
                  child: formField(
                    label: "Nama Lengkap *",
                    child: TextFormField(
                      controller: namaLengkap,
                      decoration: _inputDecoration,
                    ),
                  ),
                ),

                SizedBox(
                  width: itemWidth,
                  child: formField(
                    label: "Polda *",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<int>(
                          value: selectedPoldaId,
                          // onChanged: null is Flutter's built-in disabled
                          // state — the field greys out and ignores taps.
                          // Operator Polda cannot change their assigned Polda.
                          onChanged: _poldaLocked
                              ? null
                              : (value) {
                                  setState(() {
                                    selectedPoldaId = value;
                                    selectedPolresId = _polresNone;

                                    final selectedPolda = daftarPolda.firstWhere(
                                      (item) =>
                                          int.tryParse(item["id"].toString()) ==
                                          value,
                                    );

                                    daftarPolres =
                                        List<Map<String, dynamic>>.from(
                                      selectedPolda["polres"] ?? [],
                                    );
                                  });
                                },
                          decoration: _poldaLocked
                              ? _inputDecoration.copyWith(
                                  helperText:
                                      "Disesuaikan dengan Polda Anda",
                                  helperStyle: const TextStyle(
                                    color: Color(0xFF1D4ED8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              : _inputDecoration,
                          hint: const Text("Pilih Polda"),
                          items: daftarPolda.map((polda) {
                            return DropdownMenuItem<int>(
                              value:
                                  int.tryParse(polda["id"].toString()) ?? 0,
                              child: Text(polda["nama_polda"]),
                            );
                          }).toList(),
                        ),
                        // Lock indicator — only visible for Operator Polda
                        if (_poldaLocked) ...[
                          const SizedBox(height: 6),
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_outline,
                                  size: 14, color: Color(0xFF6B7280)),
                              SizedBox(width: 4),
                              Text(
                                "Terkunci pada Polda Anda",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                SizedBox(
                  width: itemWidth,
                  child: formField(
                    // No longer required — "Tidak Ada / Mako Polda" option exists
                    label: "Polres",
                    child: DropdownButtonFormField<int>(
                      value: selectedPolresId,
                      decoration: _inputDecoration,
                      hint: const Text("Pilih Polres"),
                      items: [
                        // Sentinel always present — selectedPolresId resets
                        // to _polresNone (0) on Polda change, so the value
                        // must always find a matching item. Flutter's
                        // items.isEmpty short-circuit handles the
                        // pre-async-load window safely.
                        const DropdownMenuItem<int>(
                          value: _polresNone,
                          child: Text("Tidak Ada / Mako Polda"),
                        ),
                        ...daftarPolres.map((polres) {
                          return DropdownMenuItem<int>(
                            value: int.tryParse(polres["polres_id"].toString()) ?? -1,
                            child: Text(polres["nama_polres"]),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedPolresId = value;
                        });
                      },
                    ),
                  ),
                ),

                SizedBox(
                  width: itemWidth,
                  child: formField(
                    label: "Pangkat *",
                    child: DropdownButtonFormField<int>(
                      value: selectedPangkatId,
                      decoration: _inputDecoration,
                      hint: const Text("Pilih Pangkat"),
                      items:
                          daftarPangkat.map((pkt) {
                            return DropdownMenuItem<int>(
                              value: int.tryParse(pkt["pangkat_id"].toString()) ?? 0,
                              child: Text(pkt["nama_pangkat"]),
                            );
                          }).toList(),
                      onChanged: (v) {
                        setState(() {
                          selectedPangkatId = v;
                        });
                      },
                    ),
                  ),
                ),

                SizedBox(
                  width: itemWidth,
                  child: formField(
                    label: "Jabatan *",
                    child: DropdownButtonFormField<int>(
                      value: selectedJabatanId,
                      decoration: _inputDecoration,
                      hint: const Text("Pilih Jabatan"),
                      items:
                          daftarJabatan.map((jbt) {
                            return DropdownMenuItem<int>(
                              value: int.tryParse(jbt["jabatan_id"].toString()) ?? 0,
                              child: Text(jbt["nama_jabatan"]),
                            );
                          }).toList(),
                      onChanged: (v) {
                        setState(() {
                          selectedJabatanId = v;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : submitPersonel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffF6B300),
                  foregroundColor: const Color(0xFF23251D),
                  shape: const StadiumBorder(),
                ),
                child:
                    loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF23251D),
                            ),
                          )
                        : Text(
                            isEditMode ? "Update Personel" : "Simpan Data",
                            style: const TextStyle(fontSize: 18),
                          ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Lengkapi semua data bertanda *",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        );
      },
    );
  }
}
