# Flutter Senjata Refactor — Build Report (Base64 → Multipart + WebP)

**Date:** 2026-01-26  
**Mode:** CODE/EXECUTE — refactor applied and verified  
**Branch state:** working tree only (no commit)

---

## 1. Summary of Changes

| File | Change | Status |
|------|--------|--------|
| `lib/widget/form_input_senjata.dart` | WebP compression pipeline + Multipart POST (create AND edit) | ✅ DONE |
| `lib/pages/senjata.dart` | `CachedNetworkImage` thumbnails + `_resolveImageUrl` standard | ✅ DONE |
| `lib/pages/add_senjata.dart` | No change needed (pure layout wrapper) | — |

---

## 2. Base64 / JSON Removal — Confirmed

The following constructs **no longer exist** in the Senjata form:

| Removed construct | Old location | Replaced by |
|-------------------|--------------|-------------|
| `base64Encode(_imageBytes!)` | `submitData()` | WebP bytes via `_compressToWebP()` → `request.files` |
| `jsonEncode(data)` / `jsonEncode(editData)` | `submitData()` create/edit branches | `request.fields[...]` assignments |
| `http.post(...)` with `Content-Type: application/json` | create branch | `http.MultipartRequest("POST", uri)` |
| `http.put(...)` with `Content-Type: application/json` | edit branch | `http.MultipartRequest("POST", uri)` — **always POST** (PHP cannot parse multipart on PUT) |
| `"foto_fisik": base64Image` JSON key | payload map | file field `"foto"` in `request.files` |
| `"senjata_id"` in request body | `editData["senjata_id"]` | ID in URL path only |
| `_showPicker()` (gallery only) | old picker | `_showImageSourceSheet()` (Kamera + Galeri) + `_pickImage()` |
| `Image.network(...)` | `senjata.dart` DataTable cell | `_buildThumbnail()` → `CachedNetworkImage` |
| `_fotoUrl(Map e)` + debug `debugPrint` | `senjata.dart` | `_resolveImageUrl(dynamic raw)` (standard pattern) |

**Verified by grep:** no `base64Encode`, `_fotoUrl`, `_showPicker`, `http.put`, or `Image.network` matches remain in either refactored file.

**Deviation note (intentional):** `import 'dart:convert'` was **kept** in the form — it is still required for `jsonDecode()` in `getPolda()` (line 41) and `getKategori()` (line 79) dropdown loaders. Only the Base64/JSON-encode usage was removed.

---

## 3. New `submitData()` — `lib/widget/form_input_senjata.dart`

```dart
Future<void> submitData() async {
  if (noSeri.text.trim().isEmpty ||
      tahunPengadaan.text.trim().isEmpty ||
      selectedPoldaId == null ||
      selectedKatId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Lengkapi semua data bertanda *"),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  if (!_isEdit && _imageBytes == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Foto senjata wajib diisi"),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("token") ?? "";

  // BUG FIX: PHP cannot parse multipart/form-data on PUT — always send
  // POST. ID goes in the URL path for edit mode — never in the body.
  final Uri uri = _isEdit
      ? Uri.parse(
          "$apiBaseUrl/api/v1/logistik/senjata/${widget.initialData!["senjata_id"]}")
      : Uri.parse("$apiBaseUrl/api/v1/logistik/senjata");

  final request = http.MultipartRequest("POST", uri);
  request.headers["Authorization"] = token;
  request.fields["polda_id"] = selectedPoldaId.toString();
  request.fields["nomor_seri"] = noSeri.text.trim();
  request.fields["kategori_id"] = selectedKatId.toString();
  request.fields["tahun_pengadaan"] = tahunPengadaan.text.trim();
  request.fields["status_kelayakan"] = "Baik";

  // Only attach the file when a (new) image was picked.
  if (_imageBytes != null) {
    request.files.add(
      http.MultipartFile.fromBytes(
        "foto",
        _imageBytes!,
        filename: "senjata_${DateTime.now().millisecondsSinceEpoch}.webp",
      ),
    );
  }

  try {
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    debugPrint(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? "Data senjata berhasil diperbarui"
                : "Data senjata berhasil diregistrasi",
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal menyimpan data"),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    debugPrint(e.toString());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Gagal menyimpan data: jaringan bermasalah"),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
```

### Key design decisions (mirroring `form_input_sarpras.dart` / `form_inputan_satwa.dart`)

1. **Always `POST`** — even for edit. The PHP backend cannot parse `multipart/form-data` on PUT; CI3 `routes.php` maps `POST /senjata/(:any)` to the update handler.
2. **ID in URL path only** for edit (`/api/v1/logistik/senjata/{senjata_id}`), never in the body.
3. **Text fields → `request.fields`** (strings, not JSON).
4. **File field name `"foto"`** — matches the backend multipart convention used by Sarpras and Satwa (not the old JSON key `foto_fisik`).
5. **Optional file attach** — on edit with no new photo, `_imageBytes == null` → no file → backend keeps the existing photo.
6. **Validation added** — required fields + "Foto senjata wajib diisi" on create.

---

## 4. Image Pipeline (new) — `lib/widget/form_input_senjata.dart`

```dart
/// Image pipeline: pick -> compress to WebP.
Future<void> _showImageSourceSheet() async {
  // Bottom sheet: Kamera (ImageSource.camera) + Galeri (ImageSource.gallery)
  // Each ListTile pops the sheet and calls _pickImage(source).
}

Future<void> _pickImage(ImageSource source) async {
  final XFile? file = await _picker.pickImage(source: source, imageQuality: 85);
  if (file == null) return;
  final bytes = await file.readAsBytes();
  final compressed = await _compressToWebP(bytes);
  if (!mounted) return;
  setState(() { _imageBytes = compressed; });
  // try/catch → SnackBar "Gagal mengambil foto (kamera/galeri tidak tersedia)"
}

/// Compress to WebP. Falls back to original bytes when the platform
/// does not support flutter_image_compress (e.g. Windows/Linux desktop).
Future<Uint8List> _compressToWebP(Uint8List bytes) async {
  setState(() { _isCompressing = true; });
  try {
    final result = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 1280,
      minHeight: 1280,
      quality: 80,
      format: CompressFormat.webp,
    );
    if (result.isNotEmpty) return result;
  } catch (e) {
    debugPrint("WebP compression tidak tersedia, memakai gambar asli: $e");
  } finally {
    if (mounted) setState(() { _isCompressing = false; });
  }
  return bytes;
}
```

UI updates in `build()`:
- Photo preview shows `CircularProgressIndicator` while `_isCompressing` is true.
- Edit mode with no new photo shows "Foto lama tetap dipakai jika tidak diganti".
- Button relabeled **"Kamera / Galeri"**, disabled while compressing.

---

## 5. List Page — `lib/pages/senjata.dart`

### New URL resolver (replaces `_fotoUrl`)

```dart
/// Builds the absolute image URL; relative paths get the API base prefix.
/// Inserts '/' when the backend returns a relative path WITHOUT a leading
/// slash (fixes ClientException/malformed domain from CachedNetworkImage).
String _resolveImageUrl(dynamic raw) {
  final url = raw?.toString() ?? "";
  if (url.isEmpty) return "";
  if (url.startsWith("http://") || url.startsWith("https://")) return url;
  return url.startsWith("/") ? "$apiBaseUrl$url" : "$apiBaseUrl/$url";
}
```

### New thumbnail helper (replaces `Image.network` DataCell)

```dart
Widget _buildThumbnail(dynamic rawUrl) {
  final url = _resolveImageUrl(rawUrl);

  if (url.isEmpty) {
    // grey box + Icons.image_not_supported_outlined (80x50)
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: CachedNetworkImage(
      imageUrl: url,
      width: 80, height: 50,
      fit: BoxFit.cover,
      placeholder: (context, url) => /* grey box + 18px spinner */,
      errorWidget: (context, url, error) => /* grey box + broken_image_outlined */,
    ),
  );
}
```

DataTable cell invocation:

```dart
DataCell(
  _buildThumbnail(e["foto_fisik"] ?? e["foto_url"]),
),
```

Fallback key chain preserved: `foto_fisik` (old base64/URL field) → `foto_url` (new multipart URL field).

---

## 6. Verification Status

| Check | Result |
|-------|--------|
| Grep: no `base64Encode` / `jsonEncode(editData)` / `http.put` / `_showPicker` / `_fotoUrl` / `Image.network` in refactored files | ✅ PASS |
| Grep: `MultipartRequest("POST", uri)` present in form | ✅ PASS |
| Grep: `request.files.add` with field `"foto"` + `.webp` filename | ✅ PASS |
| Grep: `CachedNetworkImage` imported + used in list page | ✅ PASS |
| Structural re-read of both files (method bodies, widget tree) | ✅ PASS |
| `flutter analyze` | ⚠️ NOT RUN — Flutter SDK not installed in this environment (`flutter`/`dart` not on PATH). Recommend running `flutter analyze` + `dart format lib/widget/form_input_senjata.dart lib/pages/senjata.dart` on a machine with the SDK before committing. |

---

## 7. Post-Merge Checklist (QA on device)

- [ ] Create Senjata → pick photo → compressed to WebP → POST multipart → 200/201 → list refreshes
- [ ] Edit Senjata, no new photo → POST without file → backend keeps existing photo
- [ ] Edit Senjata, new photo → POST with file → photo replaced
- [ ] List thumbnails lazy-load via `CachedNetworkImage` (spinner → image)
- [ ] Broken/missing photo → grey box with `broken_image_outlined`
- [ ] Relative image URLs (no leading slash) resolve correctly with `$apiBaseUrl/` prefix
