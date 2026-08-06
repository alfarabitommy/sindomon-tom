# Flutter Satwa K9 & Turangga — Audit & Build Plan

**Date:** 2025-07-15
**Auditor:** Senior Flutter Auditor (DEBUG MODE)
**Status:** Files exist but are **stub/shell only** — hardcoded data, no API integration. Ready to be rebuilt against the Sarpras "gold standard" pattern.

---

## 1. File Status

| File | Exists? | Current State | Target State |
|------|---------|---------------|--------------|
| `lib/pages/satwa.dart` | ✅ YES | Stub: hardcoded `listsatwa` array (5 identical dummy rows), no API fetch, no search debounce, no delete dialog/API, no edit navigation, no `CachedNetworkImage`, no loading state. Uses `Image.asset("assets/images/satwa.jpg")` for all rows. | Full API-backed list page matching `sarpras.dart` pattern |
| `lib/pages/add_satwa.dart` | ✅ YES | Stub: renders `FormTambahSatwa()` but does NOT accept `initialData` for edit mode, does NOT handle `Navigator.pop(true)` result to trigger list refresh. No loading/error state. | Edit-capable page matching `add_sarpras.dart` pattern |
| `lib/widget/form_inputan_satwa.dart` | ✅ YES (note: filename is `form_inputan_satwa.dart`, not `form_input_satwa.dart`) | Stub: has `noRegistrasi`, `namaHandler`, `Jenis` dropdown, `kualifikasi` dropdown, and image picker — but **no API submission logic**, no `initialData` parameter (no edit), **missing fields** (`jadwal_vaksin`, `status_vaksin`), no multipart support, no validation, no `flutter_image_compress`. Submit button's `onPressed` is empty `() {}`. `namaHandler` field has `keyboardType: TextInputType.number` — that's wrong for a name. | Full form matching `form_input_sarpras.dart` pattern |
| `lib/config/menu_config.dart` | ✅ YES | Satwa is **properly routed**: `_sa() → const SatwaPage()` under "Logistik & Aset" group for **role 2 (Operator Polda)**. Route name: `"satwa"`, icon: `Icons.pets_rounded`. **NOT a PlaceholderPage.** Role 1 (Super Admin) does NOT have Satwa in its menu — is this intentional? | No changes needed for menu routing |

### Field Gap Analysis

| Field | In list page (satwa.dart) | In form (form_inputan_satwa.dart) |
|-------|--------------------------|-----------------------------------|
| `foto_satwa` / `foto_url` | Column present, hardcoded asset | Image picker present (no upload logic) |
| `no_registrasi` | Column present | ✅ Text field present |
| `jenis` | Column present | ✅ Dropdown present (K9, K8, K7, K6) |
| `nama` | Column present | ❌ Label says "Nama Handler" but field name is `namaHandler` |
| `kualifikasi` | Column present | ✅ Dropdown present (Narkotika, Handak) |
| `jadwal_vaksin` | Column present | ❌ **MISSING — no date picker** |
| `status_vaksin` | Column present | ❌ **MISSING — no dropdown/field** |

---

## 2. Architecture & Bug Prevention Plan

The following 6 rules are **MANDATORY** for the build phase. They are derived from bugs found and fixed in the Sarpras module (`lib/widget/form_input_sarpras.dart`, `lib/pages/sarpras.dart`), which serves as the reference implementation.

---

### ⚠️ Rule 1: The PHP PUT Multipart Bug

**Problem:** PHP's native `$_FILES` + `$_POST` parser cannot parse `multipart/form-data` bodies on HTTP `PUT` requests. The previous forms (senjata, amunisi, personel) work around this by base64-encoding images in JSON — but that's bad for large files.

**Mandatory Fix:** The form MUST use `http.MultipartRequest("POST", uri)` for **BOTH** create and edit modes.

**Reference pattern** — `form_input_sarpras.dart` lines 190-198:
```dart
final Uri uri = _isEdit
    ? Uri.parse("$apiBaseUrl/api/v1/logistik/satwa/${widget.initialData!['satwa_id']}")
    : Uri.parse("$apiBaseUrl/api/v1/logistik/satwa");

// PHP cannot parse multipart/form-data on PUT — always send POST.
final request = http.MultipartRequest("POST", uri);
```

🔴 **DO NOT** use `http.put(...)` with `Content-Type: application/json` for this module.
🔴 **DO NOT** use `http.post(...)` with `jsonEncode(...)` for the create path either — use multipart.

---

### ⚠️ Rule 2: The Missing Slash Image Bug

**Problem:** The backend sometimes returns `foto_url` as `"uploads/satwa/abc.webp"` (no leading `/`) and sometimes as `"/uploads/satwa/abc.webp"` (with leading `/`). When concatenating `$apiBaseUrl + foto_url` without checking, we get malformed URLs like `https://sindomon.cml-indonesia.comuploads/satwa/abc.webp`.

**Mandatory Fix:** Always use the safe concatenation method:

```dart
String _resolveImageUrl(dynamic raw) {
  final url = raw?.toString() ?? "";
  if (url.isEmpty) return "";
  if (url.startsWith("http://") || url.startsWith("https://")) return url;
  return url.startsWith("/") ? "$apiBaseUrl$url" : "$apiBaseUrl/$url";
}
```

**Reference:** `sarpras.dart` lines 163-169 (`_resolveImageUrl`).

---

### ⚠️ Rule 3: Trailing Question Mark Bug

**Problem:** When the search string is empty, some old pages append `?` to the URL (e.g., `GET /api/v1/logistik/satwa?`), which the PHP backend may reject.

**Mandatory Fix:** Only append query parameters when the search string is non-empty:

```dart
Uri uri = Uri.parse("$apiBaseUrl/api/v1/logistik/satwa");
if (_searchQuery.isNotEmpty) {
  uri = uri.replace(queryParameters: {"search": _searchQuery});
}
```

🔴 **DO NOT** use string interpolation like `"$apiBaseUrl/api/v1/logistik/satwa?search=$_searchQuery"`.

**Reference:** `sarpras.dart` lines 50-53.

---

### ⚠️ Rule 4: ID in URL Bug

**Problem:** Some old forms send the entity ID in the JSON body for DELETE/EDIT requests. The backend expects the ID in the **URL path**.

**Mandatory Fix — DELETE:**
```dart
await http.delete(Uri.parse("$apiBaseUrl/api/v1/logistik/satwa/$id"));
```

**Mandatory Fix — EDIT (multipart POST):**
```dart
final Uri uri = Uri.parse("$apiBaseUrl/api/v1/logistik/satwa/${widget.initialData!['satwa_id']}");
```

🔴 **DO NOT** send `satwa_id` in `request.fields` or `jsonEncode(body)`.

**Reference:** `sarpras.dart` line 111 (delete), `form_input_sarpras.dart` lines 190-192 (edit URL).

---

### ⚠️ Rule 5: JSON Nested Bug

**Problem:** Some old forms assume dropdown initial values come from nested objects like `data["kategori"]["nama_kategori"]`, which crashes when the backend returns flat strings like `data["kualifikasi"] = "Narkotika"`.

**Mandatory Fix:** During `initState`, read initial values from **flat top-level JSON keys first**, with a guarded fallback for nested Maps:

```dart
if (_isEdit) {
  final data = widget.initialData!;
  final raw = data["kualifikasi"];
  if (raw is String) {
    selectedKualifikasi = raw;
  } else if (raw is Map) {
    selectedKualifikasi = (raw["nama"] ?? raw["kualifikasi"])?.toString();
  }
}
```

**Reference:** `form_input_sarpras.dart` lines 268-281.

---

### ⚠️ Rule 6: Lazy Loading (CachedNetworkImage)

**Problem:** `Image.network` in a `DataTable` fetches images synchronously every time the widget rebuilds — no caching, no placeholder, no error handling for each individual image. This causes flickering and excessive network usage.

**Mandatory Fix:** Use `CachedNetworkImage` for ALL thumbnail rendering in the DataTable:

```dart
import 'package:cached_network_image/cached_network_image.dart';

CachedNetworkImage(
  imageUrl: _resolveImageUrl(e["foto_satwa"] ?? e["foto_url"]),
  width: 60,
  height: 60,
  fit: BoxFit.cover,
  placeholder: (context, url) => Container(
    width: 60, height: 60, color: Colors.grey.shade100,
    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
  ),
  errorWidget: (context, url, error) => Container(
    width: 60, height: 60, color: Colors.grey.shade100,
    child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
  ),
);
```

**Dependency:** `cached_network_image: ^3.4.1` is already declared in `pubspec.yaml` line 39. ✅

**Reference:** `sarpras.dart` lines 191+ (uses this exact pattern).

---

## 3. Build Phase Checklist (for reference)

When we move from PLAN to BUILD, the following changes are needed:

### `lib/pages/satwa.dart` (list page)
- [ ] Replace hardcoded `listsatwa` with API fetch (`getSatwaApi()`)
- [ ] Add `_searchQuery`, `_debounce`, `_searchController` (match sarpras pattern)
- [ ] Add `deleteSatwa(String id)` with confirmation dialog + SnackBar
- [ ] Wire `ActionButtons` onEdit → `Navigator.push` with `initialData`; onDelete → dialog → API
- [ ] Handle `Navigator.pop(true)` result from add/edit page to refresh list
- [ ] Replace `Image.asset` → `CachedNetworkImage` with `_resolveImageUrl()`
- [ ] Add `isLoading` state with progress indicator
- [ ] Add `AppSearchField` with `onChanged` + controller

### `lib/pages/add_satwa.dart` (add/edit page)
- [ ] Accept `final Map<String, dynamic>? initialData` parameter
- [ ] Pass `initialData` to `FormTambahSatwa`
- [ ] Handle `Navigator.pop(true)` from form to signal list refresh
- [ ] Dynamic title/breadcrumb based on edit vs create

### `lib/widget/form_inputan_satwa.dart` (form)
- [ ] Add `final Map<String, dynamic>? initialData` parameter
- [ ] Add missing fields: `jadwal_vaksin` (date picker), `status_vaksin` (dropdown)
- [ ] Implement `submitData()` using `http.MultipartRequest("POST", uri)` (Rule 1)
- [ ] Add `flutter_image_compress` compression pipeline for images
- [ ] Fix `namaHandler` field: remove `TextInputType.number`, label should be "Nama Satwa" not "Nama Handler"
- [ ] Add validation (required fields, image required for create)
- [ ] Read dropdown initial values from flat JSON keys (Rule 5)
- [ ] ID in URL path for edit, not in body (Rule 4)
- [ ] Field mapping to match backend API contract (confirm exact field names with backend team)

### Optional: Menu Config
- [ ] Consider adding "Satwa K9 & Turangga" to Role 1 (Super Admin) menu if Super Admins need visibility

---

## 4. API Contract Assumptions (to verify with backend)

Based on the existing stub and sarpras patterns, the expected API endpoints are:

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `GET` | `/api/v1/logistik/satwa?search=...` | List all satwa (optional search) |
| `POST` | `/api/v1/logistik/satwa` | Create new satwa (multipart) |
| `POST` | `/api/v1/logistik/satwa/{id}` | Update satwa (multipart — Rule 1) |
| `DELETE` | `/api/v1/logistik/satwa/{id}` | Delete satwa (Rule 4) |

Expected field names (to confirm):
- `satwa_id` (primary key)
- `no_registrasi`
- `jenis` (K9, K8, K7, K6 — or "K9" / "Turangga"?)
- `nama`
- `kualifikasi` (Narkotika, Handak, etc.)
- `jadwal_vaksin` (date string)
- `status_vaksin` (enum string)
- `foto_satwa` or `foto_url` (image path)

⚠️ **The field name for the image upload multipart key also needs confirmation** — sarpras uses `"foto"`.

---

*End of audit. Ready for build phase on your signal.*
