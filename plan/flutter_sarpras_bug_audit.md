# Flutter Sarpras & Altmatsus — Bug Audit

**Date:** 2025-08-06  
**Auditor:** Reasonix (Senior Flutter Auditor)  
**Mode:** DEBUG  
**Scope:** Broken image in DataTable + `ClientException: Failed to fetch` on item ID URL

---

## Root Cause Analysis

### Symptom 1: Image broken in DataTable
### Symptom 2: `ClientException: Failed to fetch` on specific item

**Both symptoms share the same root cause: a malformed image URL produced by `_resolveImageUrl()`.**

`CachedNetworkImage` attempts to load the malformed URL → DNS resolution fails → `package:http` throws a `ClientException: Failed to fetch` internally → `CachedNetworkImage` falls back to `errorWidget` (the broken-image icon). The user sees the broken icon in the DataTable and the exception in the debug console on rows that have a `foto_url`.

---

## Bug #1: Missing slash in `_resolveImageUrl()` (HIGH)

**File:** `lib/pages/sarpras.dart` — lines 160–165

```dart
String _resolveImageUrl(dynamic raw) {
    final url = raw?.toString() ?? "";
    if (url.isEmpty) return "";
    if (url.startsWith("http")) return url;
    return "$apiBaseUrl$url";   // ⚠️ BUG: no '/' between base and path!
}
```

### What goes wrong

| `foto_url` from API | Result of `_resolveImageUrl()` | Valid? |
|---------------------|-------------------------------|--------|
| `https://cdn.example.com/abc.webp` | `https://cdn.example.com/abc.webp` | ✅ (passes `startsWith("http")`) |
| `/storage/sarpras/abc.webp` | `https://sindomon.cml-indonesia.com/storage/sarpras/abc.webp` | ✅ (leading `/` compensated) |
| `storage/sarpras/abc.webp` | `https://sindomon.cml-indonesia.comstorage/sarpras/abc.webp` | ❌ **MALFORMED** — no slash! |

When the backend returns a relative path **without** a leading `/` (which is very common for Laravel/PHP backends storing files in a local storage path), the concatenation produces an invalid hostname (`sindomon.cml-indonesia.comstorage`), DNS resolution fails, and `http.Client` throws:

```
ClientException: Failed to fetch
```

`CachedNetworkImage` catches this and renders the `errorWidget` (broken-image icon), but the exception still appears in the debug console.

### Evidence: The senjata page got this right

**File:** `lib/pages/senjata.dart` — lines 105–113

```dart
String _fotoUrl(Map<String, dynamic> e) {
    final raw = e["foto_fisik"] ?? e["foto_url"];
    final url = raw?.toString() ?? "";
    if (url.isEmpty) return "";
    if (url.startsWith("http://") || url.startsWith("https://")) return url;
    final parsed = url.startsWith("/") ? "$apiBaseUrl$url" : "$apiBaseUrl/$url";
    //                                                         ^^^^^^^^^^^^^^^^
    //                                    CORRECTLY handles the no-leading-slash case
    debugPrint("DEBUG IMAGE URL: $url");
    return parsed;
}
```

The senjata implementation already has the fix pattern — Sarpras was a regression.

---

## Bug #2: `startsWith("http")` is too loose (LOW)

**File:** `lib/pages/sarpras.dart` — line 163

```dart
if (url.startsWith("http")) return url;
```

A `foto_url` value like `"httpstuff"` (unlikely but edge-case) would falsely match and be returned as-is instead of getting the base URL prepended. The senjata page uses the correct check:

```dart
if (url.startsWith("http://") || url.startsWith("https://")) return url;
```

---

## Bug #3: Only checks `foto_url` — missing fallback for `foto_fisik` (MEDIUM)

**File:** `lib/pages/sarpras.dart` — line 395

```dart
_buildThumbnail(e["foto_url"]),
```

The senjata page (and the existing backend convention) has BOTH keys:

```dart
final raw = e["foto_fisik"] ?? e["foto_url"];  // senjata.dart:106
```

The multipart field name we used for upload is `"foto"` (defined in `form_input_sarpras.dart:216`). The backend's response key could be any of:
- `foto` — same as the multipart field name
- `foto_url` — our assumption
- `foto_fisik` — the convention from the senjata module

If the backend returns the image under `foto` or `foto_fisik` but not `foto_url`, `e["foto_url"]` resolves to `null` → `_resolveImageUrl(null)` returns `""` → `_buildThumbnail` shows the placeholder icon. **No ClientException occurs** (empty URL is guarded), but the **image never renders** even when a valid photo was uploaded.

---

## Bug #4: `sarpras_id` key unverified (MEDIUM — integration risk)

**File:** `lib/pages/sarpras.dart` — line 503 & `lib/widget/form_input_sarpras.dart` — line 192

Both the delete logic and the edit URI use `sarpras_id`:

```dart
// sarpras.dart:503 — delete
e["sarpras_id"]?.toString() ?? ""

// form_input_sarpras.dart:192 — edit URI
"$apiBaseUrl/api/v1/logistik/sarpras/${widget.initialData!['sarpras_id']}"
```

The codebase convention for logistik entities:
| Module | ID Key |
|--------|--------|
| senjata | `senjata_id` ✅ |
| amunisi | `batch_id` ⚠️ (inconsistent — NOT `amunisi_id`) |
| sarpras | `sarpras_id` ❓ (assumed, unverified) |

If the backend uses `id`, `barang_id`, or `sarpras_id` as the primary key, our code may fail:
- **Delete:** Guarded by `if (sarprasId.isNotEmpty)`, so it silently skips if the key is null (no crash, but delete doesn't work).
- **Edit:** `widget.initialData!['sarpras_id']` evaluates to `null` → the URI becomes `.../sarpras/null` → backend returns 404 → caught by `statusCode` check → shows "Gagal menyimpan data" SnackBar. Not a ClientException, but a silent failure from the user's perspective.

---

## Summary

| # | Bug | Severity | Impact |
|---|-----|----------|--------|
| 1 | `_resolveImageUrl` missing `/` between base URL and relative path | **HIGH** | Explains BOTH reported symptoms: broken image + `ClientException` |
| 2 | `startsWith("http")` too loose vs `startsWith("http://")` | LOW | Edge-case; senjata has the correct pattern |
| 3 | No fallback for `foto_fisik` / `foto` keys | MEDIUM | Image won't render if backend returns under a different key |
| 4 | `sarpras_id` key assumption unverified | MEDIUM | Delete silently skipped; edit shows generic failure SnackBar |

### Recommended fix for Bug #1 (the root cause)

Replace `_resolveImageUrl` with the senjata-proven pattern:

```dart
String _resolveImageUrl(dynamic raw) {
    final url = raw?.toString() ?? "";
    if (url.isEmpty) return "";
    if (url.startsWith("http://") || url.startsWith("https://")) return url;
    final parsed = url.startsWith("/") ? "$apiBaseUrl$url" : "$apiBaseUrl/$url";
    return parsed;
}
```

And add the fallback for the image field key:

```dart
// Line ~395 — in the DataTable DataCell:
final rawFoto = e["foto_fisik"] ?? e["foto_url"] ?? e["foto"];
_buildThumbnail(rawFoto),
```
