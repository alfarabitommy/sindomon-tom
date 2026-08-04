# Flutter Personel CRUD — Implementation Results

**Date:** 2026-08-04
**Branch:** dev
**Scope:** Full refactoring of the Manajemen Personil SDM frontend to the new RESTful `/api/v1/sdm/personil` endpoints.

---

## 1. Execution Summary

Three Dart files were fully replaced, migrating from the legacy `/api/v1/personel` endpoints to the new RESTful `/api/v1/sdm/personil` API:

### `lib/widget/form_input_personel.dart` — Dual-mode Create/Edit Form

- Added optional `String? personilId` and `Map<String, dynamic>? personilData` constructor params (polres gold-standard pattern)
- `isEditMode = widget.personilId != null && widget.personilData != null` detection in `initState`
- **POST** to `/api/v1/sdm/personil` (create) vs **PUT** to `/api/v1/sdm/personil/${widget.personilId}` (edit) branching with `Content-Type: application/json`
- **Sentinel-0 "Tidak Ada / Mako Polda"** dropdown item mapping to `null` in the request body
- **Explicit 422 branch** — NRP business validation (e.g. duplicate NRP) surfaces the backend message in a red SnackBar while staying on the form
- Async cascade pre-fill: `getPolda()` populates `daftarPolres` from the matching polda after load in edit mode
- Pre-submit field validation ("Semua data wajib diisi"), `loading` state with disabled button + spinner
- Green SnackBar + `Navigator.pop(context, true)` on 200/201 (triggers list refresh via `.then()`)
- Removed dead code (unused `polres`/`status` controllers, duplicated `@override`), added `dispose()`
- Dropdown item parsing hardened with `int.tryParse(...) ?? 0` (no more `int.parse` runtime crashes)

### `lib/pages/add_personel_page.dart` — Edit-capable Page Wrapper

- Added `String? personilId` and `Map<String, dynamic>? personilData` constructor params
- Dynamic breadcrumb: `"Dashboard / Edit Personel"` when `personilId != null`, else `"Dashboard / Tambah Personel"`
- Params forwarded to `FormTambahPersonel(personilId:, personilData:)`

### `lib/pages/personel.dart` — Migrated List Page

- **GET** migrated to `/api/v1/sdm/personil`
- **DELETE** migrated to RESTful path-param `DELETE /api/v1/sdm/personil/$personilId` with **String UUID** (eliminates the `int.parse(e["id"])` crash on UUIDs)
- Full state branching: loading spinner (amber), error state with "Coba Lagi" retry, empty state, data table
- **8 columns**: NRP, NAMA LENGKAP, PANGKAT, JABATAN, POLDA, POLRES, STATUS AKTIF, AKSI — with defensive fallbacks to FK IDs when joined names are absent
- Edit button wired to `AddPersonelPage(personilId:, personilData:)` + `.then()` refresh
- Add button now refreshes list via `.then((result) { if (result == true) getPersonelApi(); })`
- Delete flow: typed `showDialog<bool>`, interpolated person name, red Hapus button, green/red SnackBars with `mounted` guard

---

## 2. Code Diff Highlights

### A. Sentinel-0 → Null Injection (submit method, `form_input_personel.dart`)

The "Tidak Ada / Mako Polda" option uses sentinel `0` (never a valid FK, since Flutter's `DropdownButtonFormField` cannot display `null` as a selectable item). The sentinel is transparently converted to `null` in the JSON request body:

```dart
// Sentinel declaration
static const int _polresNone = 0;

// Sentinel item (guarded — only shown when real options exist,
// preventing DropdownButton's value-must-match-items assert in edit mode)
items: [
  if (daftarPolres.isNotEmpty)
    const DropdownMenuItem<int>(
      value: _polresNone,
      child: Text("Tidak Ada / Mako Polda"),
    ),
  ...daftarPolres.map((polres) {
    return DropdownMenuItem<int>(
      value: int.tryParse(polres["id"].toString()) ?? 0,
      child: Text(polres["nama_polres"]),
    );
  }),
],

// Request body — sentinel 0 OR null is serialized as null
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
```

Also, edit-mode prefill maps a `null` polres back to the sentinel so the "Tidak Ada / Mako Polda" option displays as selected:

```dart
selectedPolresId = _toInt(data["polres_id"]) ?? _polresNone;
```

### B. UUID String Conversion in the Delete Flow (`personel.dart`)

Delete now passes the raw UUID string — no `int.parse` (which would crash on a 36-char UUID):

```dart
// Typed confirmation dialog with interpolated name + red Hapus button
final result = await showDialog<bool>(
  context: context,
  builder: (_) => AlertDialog(
    title: const Text("Hapus Personel"),
    content: Text(
      "Apakah Anda yakin ingin menghapus Personel \"${e["nama_lengkap"]}\"?",
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text("Batal"),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        onPressed: () => Navigator.pop(context, true),
        child: const Text("Hapus"),
      ),
    ],
  ),
);
if (result == true) {
  // String UUID — no more int.parse(e["id"])
  deletePersonel(e["personil_id"].toString());
}
```

RESTful path-param DELETE with green/red SnackBar feedback:

```dart
Future<void> deletePersonel(String personilId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.delete(
      Uri.parse("$apiBaseUrl/api/v1/sdm/personil/$personilId"),
      headers: {"Authorization": token.toString()},
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"] ?? "Personel berhasil dihapus"),
          backgroundColor: Colors.green,
        ),
      );
      getPersonelApi(); // refresh list
    } else {
      final result = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"] ?? "Gagal menghapus Personel"),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    debugPrint("Error delete personel: $e");
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Terjadi kesalahan jaringan"),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

---

## 3. Verification Status

`flutter analyze` — **PASSED** ✅

```
Analyzing sindomon-tom...

   info • Don't use 'BuildContext's across async gaps, guarded by an unrelated 'mounted' check • lib/widget/login_card.dart:159:11 • use_build_context_synchronously
   info • Don't use 'BuildContext's across async gaps, guarded by an unrelated 'mounted' check • lib/widget/login_card.dart:165:11 • use_build_context_synchronously
   info • Don't use 'BuildContext's across async gaps, guarded by an unrelated 'mounted' check • lib/widget/login_card.dart:182:30 • use_build_context_synchronously
   info • Don't use 'BuildContext's across async gaps, guarded by an unrelated 'mounted' check • lib/widget/login_card.dart:206:28 • use_build_context_synchronously

4 issues found.
```

- **0 errors** — no type errors, no compile errors
- **0 issues in the 3 refactored files** — all new code is clean
- The 4 remaining info-level warnings are **pre-existing** in `lib/widget/login_card.dart` (untouched by this refactor) and meet the project's CLAUDE.md standard ("no errors, info-level only")
- One info issue introduced during implementation (`unnecessary_to_list_in_spreads` at `form_input_personel.dart:410`) was **fixed inline** during the same session and re-verified

**Manual E2E test checklist (pending live API):**
1. Create with all fields → green SnackBar, pops to list, list refreshes
2. Create with Polres = "Tidak Ada / Mako Polda" → body sends `"polres_id": null`, succeeds
3. Create with duplicate NRP → 422 red SnackBar with backend message, form stays open
4. Edit → all fields + 4 dropdowns pre-filled (including "Tidak Ada" for null polres), PUT to `/api/v1/sdm/personil/<uuid>`
5. Delete → dialog shows name, red Hapus button, green SnackBar + refresh on success
