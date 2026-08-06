# Flutter Sarpras & Altmatsus — Build Report

**Date:** 2025-08-06  
**Mode:** CODE/EXECUTE (direct execute)  
**Scope:** New Sarpras UI module with Image Architecture (Multipart + WebP + Lazy Loading)

---

## 1. Execution Summary

| # | File | Action | Description |
|---|------|--------|-------------|
| 1 | `pubspec.yaml` | ✅ Updated | Added `flutter_image_compress: ^2.3.0` + `cached_network_image: ^3.4.1` |
| 2 | `lib/widget/form_input_sarpras.dart` | ✅ Created (NEW) | Sarpras form: fields + dropdowns + YearPicker + camera/gallery + WebP compress + Multipart upload |
| 3 | `lib/pages/sarpras.dart` | ✅ Created (NEW) | List page: DataTable with `CachedNetworkImage` thumbnails + search + delete |
| 4 | `lib/pages/add_sarpras.dart` | ✅ Created (NEW) | Wrapper page hosting `FormTambahSarpras` (add/edit) |
| 5 | `lib/config/menu_config.dart` | ✅ Updated | `_sp()` → `const SarprasPage()` (was `PlaceholderPage`) |

**Total: 3 new files created, 2 existing files updated.**

### Routing Change (menu_config.dart)

```dart
// BEFORE (line 281):
Widget _sp() => _ph("Sarpras & Altmatsus", "sarpras");  // PlaceholderPage

// AFTER (line 282):
Widget _sp() => const SarprasPage();
```

The `LeafMenuItem` at line 168-172 (`routeName: "sarpras"`, `pageBuilder: _sp`) needed **zero changes** — it already pointed at `_sp`, which now resolves to the real page. `PlaceholderPage` remains used by other stub routes.

---

## 2. Multipart Proof

`lib/widget/form_input_sarpras.dart` — `submitData()`:

```dart
final Uri uri = _isEdit
    ? Uri.parse(
        "$apiBaseUrl/api/v1/logistik/sarpras/${widget.initialData!['sarpras_id']}")
    : Uri.parse("$apiBaseUrl/api/v1/logistik/sarpras");

final request = http.MultipartRequest(
  _isEdit ? "PUT" : "POST",
  uri,
);

// BUG FIX: ID in URL only — never in the body.
request.headers["Authorization"] = token;
request.fields["kode_barang"] = kodeBarang.text.trim();
request.fields["nama_barang"] = namaBarang.text.trim();
request.fields["kategori"] = selectedKategori!;
request.fields["kondisi"] = selectedKondisi!;
request.fields["tahun_pengadaan"] = _tahunPengadaan!.year.toString();

// Only attach the file when a (new) image was picked.
if (_imageBytes != null) {
  request.files.add(
    http.MultipartFile.fromBytes(
      "foto",
      _imageBytes!,
      filename: "sarpras_${DateTime.now().millisecondsSinceEpoch}.webp",
    ),
  );
}

final streamed = await request.send();
final response = await http.Response.fromStream(streamed);
```

### WebP Compression Proof

```dart
final result = await FlutterImageCompress.compressWithList(
  bytes,
  minWidth: 1280,
  minHeight: 1280,
  quality: 80,
  format: CompressFormat.webp,
);
```

- **Fallback:** if `flutter_image_compress` is unsupported (Windows/Linux desktop → `MissingPluginException`), the raw bytes are used instead of crashing — with a `debugPrint` notice.
- **Edit mode:** if no new photo is picked, no file is attached → server keeps the existing `foto_url`.

### Lazy Loading Proof (`lib/pages/sarpras.dart`)

```dart
CachedNetworkImage(
  imageUrl: url,
  width: 60,
  height: 60,
  fit: BoxFit.cover,
  placeholder: (context, url) => /* spinner */,
  errorWidget: (context, url, error) => /* broken-image icon */,
)
```

---

## 3. Bug Fixes Applied

| Bug Fix | Location | Implementation |
|---------|----------|----------------|
| GET: no trailing `?` on empty search | `sarpras.dart` → `getSarprasApi()` | `Uri uri = Uri.parse(...)` base; only `uri.replace(queryParameters: {...})` when `_searchQuery.isNotEmpty` |
| DELETE: ID in URL, not body | `sarpras.dart` → `deleteSarpras(id)` | `http.delete(Uri.parse("$apiBaseUrl/api/v1/logistik/sarpras/$id"))`; no body; **SnackBar in `catch`** for network errors |
| PUT: ID in URL, not body | `form_input_sarpras.dart` → `submitData()` | URI = `.../logistik/sarpras/${widget.initialData!['sarpras_id']}`; ID never in `request.fields` |
| Dropdown: flat top-level JSON keys | `form_input_sarpras.dart` → `initState()` | `data["kategori"]` read as flat String first; guarded Map fallback; `data["kondisi"]`, `data["tahun_pengadaan"]` read flat |
| Dropdown: no assertion crash on stale value | `form_input_sarpras.dart` → `build()` | `value: _kategoriItems.contains(selectedKategori) ? selectedKategori : null` |

---

## 4. Form Schema

| Field | Widget | Options |
|-------|--------|---------|
| `kode_barang` | TextFormField | free text |
| `nama_barang` | TextFormField | free text |
| `kategori` | DropdownButtonFormField<String> | `Kendaraan`, `Perlengkapan Kantor`, `Perlengkapan Dalmas`, `Alat Komunikasi`, `Kendaraan Taktis` |
| `kondisi` | DropdownButtonFormField<String> | `Baik`, `Rusak Ringan`, `Rusak Berat` |
| `tahun_pengadaan` | showDatePicker (year mode) → sends `.year` | 1990 → now |
| `foto` | ImagePicker (Kamera + Galeri) → WebP bytes | Multipart file, required on add |

---

## 5. Notes / Follow-ups

- **Field name `foto`** for the multipart file is an assumption — confirm the backend's expected multipart field name (`foto` / `foto_url` / `gambar`) during integration testing.
- **`sarpras_id`** is the assumed primary-key key for edit/delete URLs — adjust if the API returns a different key (`id`, `barang_id`).
- **Relative `foto_url`** values are auto-prefixed with `apiBaseUrl`; absolute URLs pass through untouched.
- **`flutter pub get` could not be run** in this environment (no Flutter SDK installed) — run it on the dev machine, then `flutter analyze`:
  ```bash
  flutter pub get
  flutter analyze
  ```
