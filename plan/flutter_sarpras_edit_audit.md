# Flutter Sarpras — Edit Form `ClientException` Audit

**Date:** 2025-08-06  
**Auditor:** Reasonix (Senior Flutter Auditor)  
**Mode:** DEBUG  
**Scope:** `ClientException: Failed to fetch` on Edit submit — `multipart/form-data` visible in network tab

---

## Root Cause

### 🐛 `http.MultipartRequest` uses `"PUT"` for edits — PHP can't parse multipart on PUT

**File:** `lib/widget/form_input_sarpras.dart` — line 196

```dart
final request = http.MultipartRequest(
    _isEdit ? "PUT" : "POST",   // ⚠️ BUG: sends "PUT" for edits
    uri,
);
```

### Why this breaks

PHP's `$_FILES` and `$_POST` superglobals are **only populated for `POST` requests**. When a `PUT` request arrives with `Content-Type: multipart/form-data`, PHP does **not** parse the body — `$_FILES` is empty, the file isn't available, and the backend either:

1. Returns a **500 / 400** error (because no parsed body fields are available), or
2. The HTTP client-level connection hangs/fails because the server-side code crashes before sending a proper response, which the Dart `http` package reports as `ClientException: Failed to fetch`.

This is a **well-known PHP limitation** — not a Flutter bug. The standard Laravel workaround is to **send as POST with `_method: PUT`** (Laravel's method spoofing):

```dart
final request = http.MultipartRequest("POST", uri);
request.fields["_method"] = "PUT";   // Laravel routes this as a PUT
```

### Evidence: the `_method` spoofing pattern exists in the codebase

Let me check if other forms use this pattern... Actually, `form_input_amunisi.dart` and `form_input_senjata.dart` use `http.put()` (JSON body, NOT multipart), so they aren't affected by this PHP multipart limitation. The sarpras form is the **first form in the project that combines multipart uploads with edit (PUT) operations** — so this bug is unique to the sarpras module.

---

## Step 2: File Payload — SAFE ✅

**File:** `lib/widget/form_input_sarpras.dart` — lines 208–218

```dart
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
```

**Verdict: No bug here.** When the user does NOT pick a new image during edit:
- `_imageBytes` remains `null` (line 31: initialized as `null`, never set)
- The `if (_imageBytes != null)` guard **safely skips** appending any file
- No empty/broken file attachment is sent — the backend keeps the existing photo

The edit validation at lines 177–185 also only requires a photo on **add** (`!_isEdit`), correctly skipping the requirement for edits.

---

## Summary

| # | Finding | Severity | Status |
|---|---------|----------|--------|
| 1 | `_isEdit ? "PUT" : "POST"` — PHP can't parse multipart from PUT | **HIGH 🔴** | Root cause of the `ClientException` |
| 2 | File payload when no new image picked on edit | — | ✅ Safe — correctly skipped via `if (_imageBytes != null)` |

---

## Recommended Fix

Replace lines 195–198:

```dart
// BEFORE (broken):
final request = http.MultipartRequest(
    _isEdit ? "PUT" : "POST",
    uri,
);

// AFTER (PHP-compatible):
final request = http.MultipartRequest("POST", uri);
if (_isEdit) {
    request.fields["_method"] = "PUT";   // Laravel method spoofing
}
```

This sends a `POST` request (so PHP parses the multipart body correctly) while telling Laravel to route it as a `PUT` via the `_method` field.

**Alternative** (if the backend already inspects the URL and ignores the HTTP method for routing):

```dart
final request = http.MultipartRequest("POST", uri);
// No _method needed — the URL already identifies the resource.
```

The backend at `/api/v1/logistik/sarpras/{id}` already knows which item to update from the URL path; many APIs accept POST to this URL as an update. Check the backend's route definition to confirm.

---

## Affected code

| File | Line | Issue |
|------|------|-------|
| `lib/widget/form_input_sarpras.dart` | 196 | `_isEdit ? "PUT" : "POST"` — PHP incompatible with multipart PUT |
