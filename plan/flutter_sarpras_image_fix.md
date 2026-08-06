# Flutter Sarpras — Image URL Fix Report

**Date:** 2025-08-06  
**Mode:** CODE/EXECUTE (direct execute)  
**Scope:** Fix `ClientException: Failed to fetch` + broken DataTable images in `lib/pages/sarpras.dart`

---

## 1. Execution Summary

| # | File | Change |
|---|------|--------|
| 1 | `lib/pages/sarpras.dart` | `_resolveImageUrl()` replaced ENTIRELY with the proven Senjata pattern (slash insertion between `apiBaseUrl` and relative path) |
| 2 | `lib/pages/sarpras.dart` | DataTable image cell updated: `_buildThumbnail(e["foto_url"])` → fallback chain `e["foto_fisik"] ?? e["foto_url"] ?? e["foto"]` |

**Root cause fixed:** A missing `/` during URL concatenation produced malformed domains (e.g. `https://sindomon.cml-indonesia.comstorage/...`), which made `CachedNetworkImage` throw `ClientException: Failed to fetch` internally and render the broken-image `errorWidget`.

---

## 2. Code Diff Proof

### Fix #1 — `_resolveImageUrl()` (lines 159–169)

```dart
/// Builds the absolute image URL; relative paths get the API base prefix.
/// Uses the proven Senjata pattern — inserts '/' when the backend returns
/// a relative path WITHOUT a leading slash (fixes ClientException/malformed
/// domain from CachedNetworkImage).
String _resolveImageUrl(dynamic raw) {
    final url = raw?.toString() ?? "";
    if (url.isEmpty) return "";
    if (url.startsWith("http://") || url.startsWith("https://")) return url;
    final parsed = url.startsWith("/") ? "$apiBaseUrl$url" : "$apiBaseUrl/$url";
    return parsed;
}
```

**Before (buggy):**
```dart
if (url.startsWith("http")) return url;   // too loose
return "$apiBaseUrl$url";                 // NO '/' insertion
```

**Behavior after fix:**

| `foto_url` from API | Result | Valid? |
|---------------------|--------|--------|
| `https://cdn.example.com/abc.webp` | `https://cdn.example.com/abc.webp` | ✅ |
| `/storage/sarpras/abc.webp` | `https://sindomon.cml-indonesia.com/storage/sarpras/abc.webp` | ✅ |
| `storage/sarpras/abc.webp` | `https://sindomon.cml-indonesia.com/storage/sarpras/abc.webp` | ✅ **(was malformed)** |

### Fix #2 — Image key fallback (lines 397–405)

```dart
DataCell(
    // Fallback for the image key: foto_fisik (Senjata
    // convention) → foto_url → foto (multipart field).
    _buildThumbnail(
        e["foto_fisik"] ??
            e["foto_url"] ??
            e["foto"],
    ),
),
```

**Before:** `_buildThumbnail(e["foto_url"])` — single key, no fallback.

The fallback covers all three possible backend response keys:
1. `foto_fisik` — the Senjata module convention
2. `foto_url` — original assumption
3. `foto` — the multipart field name used during upload (`form_input_sarpras.dart`)

---

## 3. Verification

- ✅ `_resolveImageUrl` now mirrors `_fotoUrl` from `lib/pages/senjata.dart:105-113` (the proven, working implementation)
- ✅ `CachedNetworkImage` call site (`_buildThumbnail`) now receives the resolved absolute URL via the fallback chain
- ✅ No other callers of `_resolveImageUrl` exist in the file — single call site updated
- ⚠️ `flutter analyze` could not be run in this environment (no Flutter SDK) — run on dev machine:
  ```bash
  flutter analyze
  ```

## 4. Remaining Watch Items (from previous audit)

| Item | Status |
|------|--------|
| `sarpras_id` key for edit/delete URLs | ⚠️ Still assumed — verify against real API response (backend may use `id` / `barang_id`) |
