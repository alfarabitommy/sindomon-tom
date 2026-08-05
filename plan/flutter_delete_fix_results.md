# Flutter DELETE Fix — Results

**Date:** 2026-08-05
**File:** `lib/pages/senjata.dart`

---

## 1. Execution Summary

Refactored `deleteSenjata(String id)` to match the backend's standard REST contract:

1. **URL Fix** — ID moved from JSON body into URL path: `.../api/v1/logistik/senjata/$id`.
2. **Body Fix** — `body: jsonEncode({"senjata_id": id})` removed entirely.
3. **Header Fix** — `"Content-Type": "application/json"` removed (no body sent).
4. **UX Fix** — Added `else` branch for non-200 responses: orange failure SnackBar `"Gagal menghapus data"` with `!mounted` guard. Failure no longer fails silently.
5. **Validation** — `flutter analyze lib/pages/senjata.dart`: **No issues found**.

---

## 2. Code Diff Proof

**Before:**
```dart
final response = await http.delete(
  Uri.parse("$apiBaseUrl/api/v1/logistik/senjata"),
  headers: {
    "Authorization": token.toString(),
    "Content-Type": "application/json",
  },
  body: jsonEncode({"senjata_id": id}),
);

if (response.statusCode == 200) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Data senjata berhasil dihapus"),
      backgroundColor: Colors.red,
    ),
  );
  getSenjataApi();
} else {
  debugPrint("Error : ${response.body}");
}
```

**After:**
```dart
final response = await http.delete(
  Uri.parse("$apiBaseUrl/api/v1/logistik/senjata/$id"),
  headers: {
    "Authorization": token.toString(),
  },
);

if (response.statusCode == 200) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Data senjata berhasil dihapus"),
      backgroundColor: Colors.red,
    ),
  );
  getSenjataApi();
} else {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Gagal menghapus data"),
      backgroundColor: Colors.orange,
    ),
  );
  debugPrint("Error : ${response.body}");
}
```

---

## 3. Resulting Request

```
METHOD:  DELETE
URL:     https://sindomon.cml-indonesia.com/api/v1/logistik/senjata/<senjata_id>
HEADERS: Authorization: <token>
BODY:    (none)
```
