# Flutter Sarpras & Altmatsus — Pre-Build Audit

**Date:** 2025-08-06  
**Auditor:** Reasonix (Senior Flutter Auditor)  
**Mode:** DEBUG (no code written)

---

## 1. File Status

| File | Status | Notes |
|------|--------|-------|
| `lib/pages/sarpras.dart` | ❌ Does not exist | Must be created — this will be the main list page (DataTable with search + pagination) |
| `lib/pages/add_sarpras.dart` | ❌ Does not exist | Must be created — add/edit form page wrapping the form widget |
| `lib/widget/form_input_sarpras.dart` | ❌ Does not exist | Must be created — reusable form widget with image upload fields |

### Current Routing (menu_config.dart:168-171, 281)

```dart
// In menu_config.dart:
LeafMenuItem(
  label: "Sarpras & Altmatsus",
  icon: Icons.precision_manufacturing_rounded,
  routeName: "sarpras",
  pageBuilder: _sp,   // ← points to PlaceholderPage!
),

// Line 281:
Widget _sp() => _ph("Sarpras & Altmatsus", "sarpras");
// _ph() returns PlaceholderPage(title: title, routeName: route);
```

**Verdict:** Sarpras currently renders a `PlaceholderPage` (construction icon + "Fitur dalam pengembangan"). The `pageBuilder: _sp` on line 171 must be changed to point to the new `SarprasPage()` once built. The `_sp()` function on line 281 must be rewritten to return the new page widget.

### Entities to follow the same pattern

Reference implementations (follow their structure):
- `lib/pages/senjata.dart` — list page pattern
- `lib/pages/add_senjata.dart` — add/edit page pattern
- `lib/widget/form_input_senjata.dart` — form widget pattern

---

## 2. Package Status

### Required for Image Architecture

| Package | Required For | Status | Version (if present) |
|---------|-------------|--------|----------------------|
| `image_picker` | Taking photos from camera / selecting from gallery | ✅ Present | `^1.2.0` |
| `flutter_image_compress` | Compressing images to WebP format before upload | ❌ Missing | — |
| `cached_network_image` | Lazy loading + caching of images in list/grid views | ❌ Missing | — |

### Action Required

Add the following to `pubspec.yaml` → `dependencies:`:

```yaml
flutter_image_compress: ^2.3.0
cached_network_image: ^3.4.1
```

Then run:

```bash
flutter pub get
```

---

## 3. Architecture Plan

### Image Pipeline (Multipart Upload + WebP Compression + Lazy Loading)

```
┌──────────────┐     ┌────────────────────┐     ┌──────────────────┐
│  Camera /    │────▶│ flutter_image_     │────▶│ POST Multipart   │
│  Gallery     │     │ compress (WebP)    │     │ /api/v1/sarpras  │
│  (image_pkr) │     │ quality: 75-85     │     │ (image field)    │
└──────────────┘     └────────────────────┘     └────────┬─────────┘
                                                         │
                                                         ▼
┌──────────────┐     ┌────────────────────┐     ┌──────────────────┐
│  DataTable   │◀────│ cached_network_    │◀────│ GET /api/v1/     │
│  List View   │     │ image (lazy load,  │     │ sarpras          │
│              │     │  placeholder,      │     │ (returns URLs)   │
│              │     │  error widgets)    │     │                  │
└──────────────┘     └────────────────────┘     └──────────────────┘
```

### Form Schema (expected)

The `form_input_sarpras.dart` will include:
- Text fields: `nama_barang`, `merek`, `model`, `nomor_seri`, `kondisi`, `lokasi`, `keterangan`
- Dropdown fields: `kategori_id` (loaded from API)
- Image picker: tap to open camera/gallery → compress to WebP → preview thumbnail
- Multipart upload on submit

### DataTable Columns (expected)

| Column | Source Field |
|--------|-------------|
| Gambar | `gambar` (URL → cached_network_image thumbnail) |
| Nama Barang | `nama_barang` |
| Merek | `merek` |
| Kategori | `kategori` (or `kategori_id` → resolved name) |
| Kondisi | `kondisi` |
| Lokasi | `lokasi` |
| Aksi | Edit / Delete buttons |

---

## 4. Previous Bugs Checklist (Mental Model)

These fixes MUST be applied when coding the Sarpras module. They are recurring bugs found and fixed in prior modules (Personel, Senjata, Amunisi).

### ✅ Fix 1: GET Request — No Trailing `?` on Empty Query

```dart
// ❌ BUG (causes 500/400 errors on some APIs):
final uri = Uri.parse("$baseUrl/sarpras?search=");    // trailing ? with empty value
final uri = Uri.parse("$baseUrl/sarpras?search=$q");  // even if q.isEmpty

// ✅ CORRECT:
final uri = q.isNotEmpty
    ? Uri.parse("$baseUrl/sarpras?search=${Uri.encodeComponent(q)}")
    : Uri.parse("$baseUrl/sarpras");                  // no query string when empty
```

**Reference:** `bugfix_personel_frontend_results.md`, `flutter_amunisi_audit.md`

### ✅ Fix 2: PUT/DELETE — ID in URL, NOT in Body

```dart
// ❌ BUG (ID sent in JSON body — not RESTful, may be ignored):
http.put(
  Uri.parse("$baseUrl/sarpras"),
  body: jsonEncode({"id": id, "nama_barang": "...", ...}),
);

// ✅ CORRECT (ID in URL path):
http.put(
  Uri.parse("$baseUrl/sarpras/$id"),
  body: jsonEncode({"nama_barang": "...", ...}),   // no ID in body
);
http.delete(Uri.parse("$baseUrl/sarpras/$id"));    // ID in URL
```

**Reference:** `flutter_delete_audit.md`, `flutter_amunisi_delete_audit.md`, `flutter_amunisi_put_audit.md`

### ✅ Fix 3: Dropdown — Read from Flat Top-Level JSON, Not Nested Objects

```dart
// ❌ BUG (tries to read nested object, but API returns flat structure):
final list = json["data"]["kategori"];  // kategori might be nested or absent

// ✅ CORRECT (read data array, then pick flat fields):
final dataList = List<Map<String, dynamic>>.from(json["data"]);
for (final item in dataList) {
  final id = item["id"].toString();         // flat field
  final nama = item["nama_kategori"] ?? ""; // flat field, not item["kategori"]["nama"]
}
```

**Reference:** `flutter_dropdown_audit.md`, `bugfix_dropdown_frontend_results.md`

---

## 5. Summary

| Aspect | Status |
|--------|--------|
| Sarpras UI files | **3 files to create** (sarpras.dart, add_sarpras.dart, form_input_sarpras.dart) |
| Menu routing | **1 line to change** (pageBuilder: _sp → SarprasPage()) + rewrite `_sp()` function |
| Required packages | **2 to add** (flutter_image_compress, cached_network_image) |
| Image architecture | **Ready** (image_picker already present; just add compress + cache packages) |
| 3 bug patterns | **Acknowledged** — will apply Fix 1 (no empty `?`), Fix 2 (ID in URL), Fix 3 (flat JSON) |
