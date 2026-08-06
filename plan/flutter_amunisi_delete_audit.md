# Flutter Amunisi Delete Audit

**File:** `lib/pages/amunisi.dart`  
**Method:** `deleteAmunisi(String id)` (lines 148–182)  
**Date:** 2025-06-27

---

## 1. Request Format

### URL

```
DELETE https://sindomon.cml-indonesia.com/api/v1/logistik/amunisi/{batch_id}
```

The `batch_id` is interpolated directly into the URL path — **ID is in the URL, not in the body**. This is RESTful and correct.

```dart
Uri.parse("$apiBaseUrl/api/v1/logistik/amunisi/$id")
```

### Headers

```json
{
  "Authorization": "<jwt_token>"
}
```

No `Content-Type` header is sent (unnecessary since there is no body).

### Body

**No body is sent.** The `http.delete()` call only receives `Uri` and `headers` — no `body` parameter is passed.

```dart
final response = await http.delete(
  Uri.parse("$apiBaseUrl/api/v1/logistik/amunisi/$id"),
  headers: {
    "Authorization": token.toString(),
  },
);
```

### ID field used

The delete picks up `batch_id` from the row data (line 482), **not** `id`:

```dart
final amunisiId = e["batch_id"]?.toString() ?? "";
```

### Verdict: ✅ Already RESTful

This module does **NOT** exhibit the anti-pattern of sending the ID in a JSON body. The pattern is identical to `senjata.dart` (`deleteSenjata`, lines 122–156) — both modules correctly place the resource ID in the URL path with no body payload.

---

## 2. UX Status

### Success path (HTTP 200)

| Aspect | Behavior |
|--------|----------|
| SnackBar | ✅ Shown: `"Data amunisi berhasil dihapus"` (red background) |
| List refresh | ✅ Calls `getAmunisiApi()` to reload the table |
| `mounted` guard | ✅ Checks `mounted` before accessing `context` |

### Failure path (HTTP ≠ 200)

| Aspect | Behavior |
|--------|----------|
| SnackBar | ✅ Shown: `"Gagal menghapus data"` (orange background) |
| Error logging | ✅ `debugPrint("Error : ${response.body}")` |
| `mounted` guard | ✅ Checks `mounted` before accessing `context` |

### Exception path (network error, timeout, etc.)

| Aspect | Behavior |
|--------|----------|
| SnackBar | ❌ **None** — only `debugPrint(e.toString())` is called |
| User feedback | ❌ **Silent failure** — user gets no indication something went wrong |
| Retry / recovery | ❌ None |

---

## 3. Action Plan

### What's already correct (no changes needed)

1. **ID in URL path** — already follows RESTful convention (`/amunisi/$id`).
2. **No body on DELETE** — no `body: jsonEncode(...)` anti-pattern present.
3. **Success + non-200 HTTP feedback** — SnackBars work correctly for HTTP responses.

### What should be fixed

| # | Issue | Severity | Fix |
|---|-------|----------|-----|
| 1 | **Catch block silently swallows exceptions** (lines 179–181) | Medium | Add a `ScaffoldMessenger` SnackBar inside the catch block so the user sees feedback when a network/timeout error occurs. Guard with `mounted` check. |

### Recommended catch-block fix (conceptual)

```dart
} catch (e) {
  debugPrint(e.toString());
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Gagal menghapus data: jaringan bermasalah"),
      backgroundColor: Colors.orange,
    ),
  );
}
```

---

## Summary

The `deleteAmunisi` method is **already RESTful-compliant** — ID in URL, no body payload. It does not suffer from the anti-pattern that may have existed in other modules before they were fixed. The only gap is the silent exception handling in the `catch` block, which leaves users with no feedback on network/timeout failures.
