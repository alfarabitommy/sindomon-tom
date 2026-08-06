# Flutter Satwa K9 & Turangga — Build Report

**Date:** 2025-07-15
**Status:** ✅ BUILD COMPLETE — all 3 files created/refactored
**Verification:** Flutter SDK not available in this environment — verified by manual code review, cross-file reference grep, and adherence to the proven `sarpras.dart` / `form_input_sarpras.dart` reference patterns. Independent review subagent also ran; its lifecycle finding was applied (see "Post-review fixes" below).

---

## 1. Execution Summary

| File | Action | What was done |
|------|--------|---------------|
| `lib/widget/form_inputan_satwa.dart` | **REFACTORED** (class renamed `FormTambahSatwa` → `FormInputanSatwa`) | Full add/edit form: `initialData` param, edit-mode `initState` flat-JSON reads, 6 fields (nomor_registrasi, jenis_satwa [K9/Turangga], nama_satwa, nama_handler, kualifikasi [6 DB options], jadwal_vaksin DatePicker), Camera+Gallery picker, WebP compression, multipart POST submit |
| `lib/pages/satwa.dart` | **REWRITTEN** (stub → API-backed) | `getSatwaApi()` fetch, debounced search, ID-in-URL delete, `CachedNetworkImage` thumbnails, safe URL concatenation, red `Icons.vaccines` alert for vaccines due < 30 days / passed |
| `lib/pages/add_satwa.dart` | **REWRITTEN** (stub → wrapper) | `AddSatwaPage({initialData})` wraps `FormInputanSatwa`, dynamic breadcrumb, form pops `true` on success → list page refreshes |

### Form field details

| Field | Multipart key | Type | Notes |
|-------|--------------|------|-------|
| Nomor Registrasi | `nomor_registrasi` | `TextFormField` | — |
| Jenis Satwa | `jenis_satwa` | Dropdown | Exactly `['K9', 'Turangga']` |
| Nama Satwa | `nama_satwa` | `TextFormField` | — |
| Nama Handler | `nama_handler` | `TextFormField` | ✅ FIXED: `TextInputType.text` (was wrongly `number`) |
| Kualifikasi | `kualifikasi` | Dropdown | Exactly `['Narkotika', 'Handak', 'Dalmas', 'Kriminal Umum', 'Patroli', 'Pelacak']` (6 DB options) |
| Jadwal Vaksin | `jadwal_vaksin` | DatePicker | `yyyy-MM-dd`, via `showDatePicker` |
| Foto | `foto` (multipart file) | Picker | Camera OR Gallery → WebP compress (max 1280px, q80, fallback to original bytes on desktop) |

> **Note:** multipart file key is `foto` — the same proven key as the sibling `sarpras` module (same backend family `/api/v1/logistik/*`). List/thumbnail reads use fallback chain `foto_url → foto_satwa → foto`. If the backend expects a different file key, it's a one-line change at `form_inputan_satwa.dart` line 274.

### Table columns (list page)

`FOTO` | `NO REGISTRASI` | `JENIS` | `NAMA SATWA` | `NAMA HANDLER` | `KUALIFIKASI` | `JADWAL VAKSIN` (+red `Icons.vaccines` when urgent) | `AKSI`

Cell rendering is defensive — supports both new and legacy JSON keys (`nomor_registrasi`/`no_registrasi`, `jenis_satwa`/`jenis`, `nama_satwa`/`nama`).

---

## 2. Bug Prevention Proof

### ✅ Rule 1 — PHP PUT Multipart Bug: `MultipartRequest("POST")` for BOTH modes

`lib/widget/form_inputan_satwa.dart` (submit logic):

```dart
// BUG FIX (Rule 4): ID goes in the URL path for edit mode — never in the body.
final Uri uri = _isEdit
    ? Uri.parse(
        "$apiBaseUrl/api/v1/logistik/satwa/${widget.initialData!['satwa_id']}")
    : Uri.parse("$apiBaseUrl/api/v1/logistik/satwa");

// BUG FIX (Rule 1): PHP cannot parse multipart/form-data on PUT —
// ALWAYS send POST, for create AND edit.
final request = http.MultipartRequest("POST", uri);

request.headers["Authorization"] = token;
request.fields["nomor_registrasi"] = nomorRegistrasi.text.trim();
request.fields["jenis_satwa"] = selectedJenisSatwa!;
request.fields["nama_satwa"] = namaSatwa.text.trim();
request.fields["nama_handler"] = namaHandler.text.trim();
request.fields["kualifikasi"] = selectedKualifikasi!;
request.fields["jadwal_vaksin"] = _formatDate(_jadwalVaksin!);

// Only attach the file when a (new) image was picked.
if (_imageBytes != null) {
  request.files.add(
    http.MultipartFile.fromBytes(
      "foto",
      _imageBytes!,
      filename: "satwa_${DateTime.now().millisecondsSinceEpoch}.webp",
    ),
  );
}
```

- ✅ **No `http.put(...)` anywhere** — verified by grep: zero matches in the satwa module.
- ✅ **No `jsonEncode(...)` body** — multipart fields only.
- ✅ Create → `POST /api/v1/logistik/satwa`, Edit → `POST /api/v1/logistik/satwa/{satwa_id}` (both POST).

### ✅ Rule 2 — Missing Slash Image Bug: safe URL concatenator

`lib/pages/satwa.dart`:

```dart
/// BUG FIX (Rule 2): safely concatenate the image URL — inserts '/'
/// when the backend returns a relative path WITHOUT a leading slash
/// (fixes ClientException/malformed domain from CachedNetworkImage).
String _resolveImageUrl(dynamic raw) {
  final url = raw?.toString() ?? "";
  if (url.isEmpty) return "";
  if (url.startsWith("http://") || url.startsWith("https://")) return url;
  return url.startsWith("/") ? "$apiBaseUrl$url" : "$apiBaseUrl/$url";
}
```

Identical logic also in `lib/widget/form_inputan_satwa.dart` (`_resolveImageUrl`, used for the edit-mode photo preview). Handles all 3 backend shapes: absolute URL, `/leading-slash` relative, and `no-leading-slash` relative.

### ✅ Rule 3 — Trailing Question Mark Bug (list page)

```dart
Uri uri = Uri.parse("$apiBaseUrl/api/v1/logistik/satwa");
if (_searchQuery.isNotEmpty) {
  uri = uri.replace(queryParameters: {"search": _searchQuery});
}
```

No `?` is ever appended when the search string is empty.

### ✅ Rule 4 — ID in URL Bug

- **DELETE:** `lib/pages/satwa.dart` → `http.delete(Uri.parse("$apiBaseUrl/api/v1/logistik/satwa/$id"))` — ID in path only, no body.
- **EDIT:** form `uri` above → ID appended to path, **not** in `request.fields`.

### ✅ Rule 5 — JSON Nested Bug (flat top-level keys in `initState`)

```dart
// Flat string key first; guarded Map fallback (no nested crash).
final rawJenis = data["jenis_satwa"] ?? data["jenis"];
if (rawJenis is String && _jenisItems.contains(rawJenis)) {
  selectedJenisSatwa = rawJenis;
} else if (rawJenis is Map) { /* guarded nested fallback */ }
```

Same pattern for `kualifikasi`; `jadwal_vaksin` read via `DateTime.tryParse(data["jadwal_vaksin"])`.

### ✅ Rule 6 — Lazy Loading: `CachedNetworkImage` thumbnails

`lib/pages/satwa.dart` `_buildThumbnail()`: `CachedNetworkImage` with 60×60 `BoxFit.cover`, `placeholder` (grey box + spinner) and `errorWidget` (broken-image icon). Empty URL → static grey placeholder icon. Dependency already in `pubspec.yaml` (`cached_network_image: ^3.4.1`).

### ✅ Bonus — Vaccine alert icon

```dart
/// True when jadwal_vaksin is less than 30 days from today or already passed.
bool _isVaksinUrgent(dynamic raw) {
  final date = DateTime.tryParse(raw?.toString() ?? "");
  if (date == null) return false;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final jadwal = DateTime(date.year, date.month, date.day);

  return jadwal.difference(today).inDays < 30;
}
```

Rendered as red `Icons.vaccines` (size 18, with `Tooltip` "Vaksinasi kurang dari 30 hari atau sudah lewat") next to the date when due < 30 days **or already passed**. Date-only comparison avoids time-of-day off-by-one errors.

---

## 3. Post-review fixes

- **Lifecycle (`mounted`) guards added** after an independent review flagged `setState` after `await` without a mounted check:
  - `lib/pages/satwa.dart` → `loadUser()` + all `setState` branches of `getSatwaApi()`
  - `lib/pages/add_satwa.dart` → `loadUser()`
  - Prevents "setState() called after dispose()" when the user navigates away mid-fetch.

## 4. Caveats / Next Steps

1. **`flutter analyze` not run** — Flutter SDK absent in this environment. Run `flutter analyze` + `flutter pub get` on a machine with the SDK before merging.
2. **Backend contract verification needed** (as flagged in `plan/flutter_satwa_audit.md`):
   - Multipart file key `foto` (assumed from sarpras convention).
   - Field names `nomor_registrasi`, `jenis_satwa`, `nama_satwa`, `nama_handler`, `kualifikasi`, `jadwal_vaksin` (per build spec) — list page falls back to legacy keys `no_registrasi`/`jenis`/`nama` for display.
   - Endpoint `/api/v1/logistik/satwa` (GET/POST/DELETE + POST-with-ID for update).
3. **Menu config needs no change** — Satwa was already routed to `SatwaPage` for role 2 (`menu_config.dart` line 178).

*End of build report.*
