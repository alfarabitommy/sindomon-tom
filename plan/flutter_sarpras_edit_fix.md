# Flutter Sarpras — Edit Form Fix Report

**Date:** 2025-08-06  
**Mode:** CODE/EXECUTE (direct execute)  
**Scope:** Fix `ClientException: Failed to fetch` on Sarpras Edit submit in `lib/widget/form_input_sarpras.dart`

---

## 1. Execution Summary

| # | File | Change |
|---|------|--------|
| 1 | `lib/widget/form_input_sarpras.dart` | `http.MultipartRequest` now **always uses `"POST"`** regardless of `_isEdit` (was `_isEdit ? "PUT" : "POST"`) |

**Root cause fixed:** PHP cannot parse `multipart/form-data` bodies on `PUT` requests (`$_FILES`/`$_POST` only populate for POST). The old code sent `PUT` + multipart when editing → backend couldn't parse the body → `ClientException: Failed to fetch`.

**Why no `_method` spoofing:** Per the backend team, CI3's `routes.php` explicitly maps `POST /sarpras/(:any)` to the update handler, so a plain POST to the item URL (`/api/v1/logistik/sarpras/{sarpras_id}`) is all that's needed.

**Add vs edit still distinguished correctly** by the URI (lines 190–193), which already embeds the ID in the URL path for edits — the HTTP method is the only thing that changed.

---

## 2. Code Diff Proof

### `lib/widget/form_input_sarpras.dart` — submitData(), lines 195–198

**Before (broken):**
```dart
final request = http.MultipartRequest(
    _isEdit ? "PUT" : "POST",
    uri,
);
```

**After (fixed):**
```dart
// PHP cannot parse multipart/form-data on PUT — always send POST.
// (CI3 routes.php maps POST /sarpras/(:any) to the update handler,
// so no Laravel _method spoofing is needed.)
final request = http.MultipartRequest("POST", uri);
```

### Context (unchanged — still correct)

```dart
final Uri uri = _isEdit
    ? Uri.parse(
        "$apiBaseUrl/api/v1/logistik/sarpras/${widget.initialData!['sarpras_id']}")
    : Uri.parse("$apiBaseUrl/api/v1/logistik/sarpras");
```

- **Add:** `POST /api/v1/logistik/sarpras`
- **Edit:** `POST /api/v1/logistik/sarpras/{id}` → routed by CI3 to the update handler
- File still attached only when a new image is picked (`if (_imageBytes != null)`, lines 208–218)
- ID never sent in the body — URL path only

---

## 3. Verification

- ✅ `MultipartRequest` method is now a literal `"POST"` — no conditional
- ✅ Edit URI keeps the `{sarpras_id}` in the URL path (unchanged)
- ✅ File-attachment guard (`_imageBytes != null`) untouched — no-image edits send fields only
- ✅ No `_method` field added (not needed for CI3 routing)
- ⚠️ `flutter analyze` not runnable here (no Flutter SDK) — quick check on dev machine recommended:
  ```bash
  flutter analyze
  ```
