# Flutter Senjata Refactor Audit — Base64/JSON → Multipart + WebP

**Date:** 2026-01-26  
**Auditor:** Senior Flutter Auditor (DEBUG/PASSIVE MODE — no code changed)  
**Goal:** Refactor the Senjata form & list UI to match the Multipart + WebP architecture already shipped for Sarpras & Satwa.

---

## 1. Files Affected

| File | Role | Needs Change? |
|------|------|---------------|
| `lib/widget/form_input_senjata.dart` | Add/Edit form widget | **YES — full write** |
| `lib/pages/senjata.dart` | List/DataTable page | **YES — thumbnail upgrade** |
| `lib/pages/add_senjata.dart` | Page wrapper (no form logic) | No — passes `initialData` through unchanged |
| `pubspec.yaml` | Dependencies | No — `flutter_image_compress: ^2.3.0` and `cached_network_image: ^3.4.1` are already declared |

---

## 2. Form Audit: `lib/widget/form_input_senjata.dart`

### 2.1 Current Submission Flow (the problem)

#### Image Capture (lines 92–123)

```dart
Future<void> _showPicker() async {
  // ... only gallery, no camera option
  final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
  if (file != null) {
    final bytes = await file.readAsBytes();
    setState(() { _imageBytes = bytes; });  // raw bytes, NO compression
  }
}
```

- **Only gallery** — no camera option (Sarpras/Satwa have `Kamera + Galeri` bottom sheet).
- **No compression** — raw bytes from `readAsBytes()`. No `flutter_image_compress` call.
- **No `_isCompressing`** flag — no spinner feedback during upload.

#### Submit (lines 125–184)

```dart
Future<void> submitData() async {
  String? base64Image;
  if (_imageBytes != null) {
    base64Image = base64Encode(_imageBytes!);   // ← BASE64 in JSON body
  }

  final data = {
    "polda_id": selectedPoldaId,
    "nomor_seri": noSeri.text,
    "kategori_id": selectedKatId,
    "tahun_pengadaan": tahunPengadaan.text,
    "status_kelayakan": "Baik",
    "foto_fisik": base64Image,                   // ← sent as JSON string
  };

  if (_isEdit) {
    response = await http.put(                   // ← PUT for edit
      Uri.parse("$apiBaseUrl/api/v1/logistik/senjata/${widget.initialData!["senjata_id"]}"),
      headers: {
        "Authorization": token.toString(),
        "Content-Type": "application/json",      // ← JSON content type
      },
      body: jsonEncode(editData),
    );
  } else {
    response = await http.post(                  // ← POST for create
      Uri.parse("$apiBaseUrl/api/v1/logistik/senjata"),
      headers: {
        "Authorization": token.toString(),
        "Content-Type": "application/json",
      },
      body: jsonEncode(data),
    );
  }
}
```

**Problems:**
1. Base64 in JSON body — huge payloads, no streaming, memory pressure.
2. `http.put()` for edit with `Content-Type: application/json` — PHP can't parse multipart on PUT anyway, but even for JSON the backend may not handle base64 images well in edit.
3. No WebP compression — even the base64 string is uncompressed PNG/JPEG bytes.
4. No validation that photo is required on create (Sarpras/Satwa enforce `foto wajib diisi` for new records).
5. `senjata_id` is put into the body for edit (though it's also in the URL).

### 2.2 Required Changes (blueprint from Sarpras/Satwa)

The reference implementation lives in two files:
- **`lib/widget/form_input_sarpras.dart`** — complete Multipart + WebP pattern
- **`lib/widget/form_inputan_satwa.dart`** — identical architecture with edit-mode photo preview

#### A. Imports to add
```dart
import 'package:flutter_image_compress/flutter_image_compress.dart';
```
Remove: `import 'dart:convert';` (base64Encode no longer needed)

#### B. New state variable
```dart
bool _isCompressing = false;  // spinner during WebP compression
```

#### C. Replace `_showPicker()` with `_showImageSourceSheet()` + `_pickImage()` + `_compressToWebP()`

Pattern (exact copy from Sarpras lines 56–139):

```dart
Future<void> _showImageSourceSheet() async {
  // bottom sheet with Kamera + Galeri options
  // each calls _pickImage(source)
}

Future<void> _pickImage(ImageSource source) async {
  final XFile? file = await _picker.pickImage(source: source, imageQuality: 85);
  if (file == null) return;
  final bytes = await file.readAsBytes();
  final compressed = await _compressToWebP(bytes);
  setState(() { _imageBytes = compressed; });
}

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
    setState(() { _isCompressing = false; });
  }
  return bytes; // fallback to original
}
```

#### D. Replace `submitData()` with MultipartRequest

Key rules (from Sarpras lines 195–218, Satwa lines 258–279):

1. **ALWAYS use POST** — even for edit. PHP cannot parse `multipart/form-data` on PUT.
   ```dart
   final request = http.MultipartRequest("POST", uri);
   ```

2. **ID goes in the URL path** for edit, NEVER in the body:
   ```dart
   final Uri uri = _isEdit
       ? Uri.parse("$apiBaseUrl/api/v1/logistik/senjata/${widget.initialData!['senjata_id']}")
       : Uri.parse("$apiBaseUrl/api/v1/logistik/senjata");
   ```

3. **All text fields go into `request.fields`**:
   ```dart
   request.fields["polda_id"] = selectedPoldaId.toString();
   request.fields["nomor_seri"] = noSeri.text.trim();
   request.fields["kategori_id"] = selectedKatId.toString();
   request.fields["tahun_pengadaan"] = tahunPengadaan.text.trim();
   request.fields["status_kelayakan"] = "Baik";
   ```

4. **File field name:** `"foto"` (matching the backend's multipart field name — Sarpras and Satwa both use `"foto"`, not `"foto_fisik"`):
   ```dart
   if (_imageBytes != null) {
     request.files.add(http.MultipartFile.fromBytes(
       "foto",
       _imageBytes!,
       filename: "senjata_${DateTime.now().millisecondsSinceEpoch}.webp",
     ));
   }
   ```

5. **Send via `request.send()` → `Response.fromStream()`**:
   ```dart
   final streamed = await request.send();
   final response = await http.Response.fromStream(streamed);
   ```

6. **Add validation**: photo required on create (`!_isEdit && _imageBytes == null` → SnackBar + return).

#### E. UI changes in `build()`

- **Photo section**: Show `CircularProgressIndicator` when `_isCompressing` is true (Sarpras line 503).
- **Button label**: Change from `"Pilih Foto"` to `"Kamera / Galeri"` + wire to `_showImageSourceSheet`.
- **Edit mode**: Show a placeholder message "Foto lama tetap dipakai jika tidak diganti" when no new image is picked (Sarpras lines 512–529). Optionally show the existing photo via `CachedNetworkImage` (like Satwa's `_buildPhotoPreview()`).

---

## 3. List Page Audit: `lib/pages/senjata.dart`

### 3.1 Current Image Rendering (lines 105–113, 319–335)

#### URL resolution — `_fotoUrl()` (line 105)

```dart
String _fotoUrl(Map<String, dynamic> e) {
  final raw = e["foto_fisik"] ?? e["foto_url"];
  final url = raw?.toString() ?? "";
  if (url.isEmpty) return "";
  if (url.startsWith("http://") || url.startsWith("https://")) return url;
  final parsed = url.startsWith("/") ? "$apiBaseUrl$url" : "$apiBaseUrl/$url";
  return parsed;
}
```

**Assessment:** The URL resolution logic is **correct** — it matches the pattern in Sarpras (`_resolveImageUrl`, line 163) and Satwa (`_resolveImageUrl`, line 155). The key difference is the signature: Senjata's `_fotoUrl` takes a `Map<String, dynamic>` while Sarpras/Satwa's `_resolveImageUrl` takes `dynamic raw`. This is fine for now — the logic is identical.

**Note:** After switching to Multipart upload, the backend will return a URL in `foto_url` (or possibly `foto_fisik`). The current fallback chain `foto_fisik ?? foto_url` covers both the old (base64 in `foto_fisik`) and new (URL in `foto_url`) cases. No change needed here.

#### Image widget — `Image.network()` (line 319)

```dart
DataCell(
  ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.network(
      _fotoUrl(e),
      width: 80, height: 50,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.image_not_supported, size: 40),
    ),
  ),
),
```

**Problem:** Uses `Image.network` — no caching, no lazy loading, no placeholder while loading. Sarpras and Satwa both use `CachedNetworkImage` with a proper `_buildThumbnail()` helper.

### 3.2 Required Changes

#### A. Add import
```dart
import 'package:cached_network_image/cached_network_image.dart';
```

#### B. Extract `_buildThumbnail()` helper (copy pattern from Sarpras lines 171–215)

```dart
Widget _buildThumbnail(dynamic rawUrl) {
  final url = _resolveImageUrl(rawUrl);
  if (url.isEmpty) {
    return Container(
      width: 80, height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
    );
  }
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: CachedNetworkImage(
      imageUrl: url,
      width: 80, height: 50,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        width: 80, height: 50,
        color: Colors.grey.shade100,
        child: const Center(
          child: SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: 80, height: 50,
        color: Colors.grey.shade100,
        child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
      ),
    ),
  );
}
```

#### C. Refactor `_fotoUrl` → `_resolveImageUrl`

Change the signature to match the Sarpras/Satwa convention:
```dart
String _resolveImageUrl(dynamic raw) {
  final url = raw?.toString() ?? "";
  if (url.isEmpty) return "";
  if (url.startsWith("http://") || url.startsWith("https://")) return url;
  return url.startsWith("/") ? "$apiBaseUrl$url" : "$apiBaseUrl/$url";
}
```

Then call it from the DataTable as:
```dart
_buildThumbnail(e["foto_fisik"] ?? e["foto_url"])
```

This keeps the same fallback key chain.

---

## 4. Summary Blueprint

### Phase 1: Form (`form_input_senjata.dart`) — ~1:1 copy from Sarpras

| Step | What | Sarpras reference lines |
|------|------|--------------------------|
| 1 | Add `flutter_image_compress` import, remove `dart:convert` | Line 4 |
| 2 | Add `bool _isCompressing = false` | Line 32 |
| 3 | Replace `_showPicker()` with `_showImageSourceSheet()` + `_pickImage()` + `_compressToWebP()` | Lines 56–139 |
| 4 | Replace `submitData()` with `MultipartRequest("POST", ...)` — always POST | Lines 162–258 |
| 5 | ID in URL path for edit, never in body | Lines 190–193 |
| 6 | File field name: `"foto"`, filename: `senjata_<timestamp>.webp` | Lines 210–217 |
| 7 | Add photo-required validation for create | Lines 177–185 |
| 8 | Update photo UI: `_isCompressing` spinner, edit-mode placeholder text | Lines 495–550 |
| 9 | Change button text to "Kamera / Galeri" | Line 548 |

### Phase 2: List Page (`senjata.dart`) — ~1:1 copy from Sarpras/Satwa

| Step | What | Reference |
|------|------|-----------|
| 1 | Add `cached_network_image` import | |
| 2 | Rename `_fotoUrl(Map)` → `_resolveImageUrl(dynamic raw)` | Sarpras line 163 |
| 3 | Extract `_buildThumbnail(dynamic rawUrl)` using `CachedNetworkImage` | Sarpras lines 171–215 |
| 4 | Replace `Image.network(...)` DataCell with `_buildThumbnail(e["foto_fisik"] ?? e["foto_url"])` | |

---

## 5. Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Backend field name mismatch | Medium | Verify backend expects `"foto"` as the multipart file field name (same as Sarpras/Satwa). If it expects `"foto_fisik"`, change the `MultipartFile.fromBytes` field name. |
| Existing data has base64 in `foto_fisik` | Low | List page fallback `foto_fisik ?? foto_url` still handles this — base64 strings won't match `http://` or `https://` prefix, so they'll get `$apiBaseUrl/` prepended and fail to load. The `errorWidget` will show a broken-image icon. After migration, old records will show broken images until re-uploaded. |
| Desktop platform no WebP support | Low | `_compressToWebP()` already has a try/catch fallback to original bytes. |
| Edit with no new photo | Low | `_imageBytes` stays `null`, so no file is attached — backend keeps existing photo. |

---

## 6. Files NOT Touched

- `lib/pages/add_senjata.dart` — purely a layout wrapper; passes `initialData` through. No change needed.
- `lib/config/api_config.dart` — base URL unchanged.
- `pubspec.yaml` — both `flutter_image_compress` and `cached_network_image` already declared (lines 38–39).

---

## 7. Verification Checklist (post-refactor)

- [ ] Create Senjata: image picked → compressed to WebP → uploaded via POST multipart → returns 200/201
- [ ] Edit Senjata: no new image → POST multipart without file → backend keeps existing photo → returns 200
- [ ] Edit Senjata: new image picked → compressed → POST multipart with file → returns 200
- [ ] List page: `CachedNetworkImage` renders thumbnails with placeholder spinner
- [ ] List page: broken/missing images show `broken_image_outlined` icon
- [ ] List page: image URL resolved correctly (relative paths get `$apiBaseUrl` prefix with proper `/` insertion)
