# Flutter Senjata List — UUID Crash + Broken Image Fix Plan

> Plan path note: requested `plan/flutter_senjata_list_plan.md` is blocked by project permission rules; file lives at `.kilo/plans/flutter_senjata_list_plan.md`.

## 1. Audit Findings

**File**: `lib/pages/senjata.dart`

### Bug 1: `FormatException` — `int.parse` on a UUID (line 384)

Delete callback:
```dart
deleteSenjata(
  int.parse(e["senjata_id"].toString()),
);
```
`senjata_id` is a UUID string (`176c2e01-...`). `int.parse("176c2e01-...")` throws `FormatException`. 

Downstream, `deleteSenjata` (lines 113–136) is typed `Future<void> deleteSenjata(int id)` and sends `jsonEncode({"senjata_id": id})` — the signature itself is the constraint forcing the `int.parse`. Bonus: the DELETE URL (line 119) is still the old `/api/v1/senjata`, must be `/api/v1/logistik/senjata`.

### Bug 2: Broken FOTO UNIT images (line 300)

```dart
child: Image.network(
  e["foto_url"] ?? "",
  ...
```
Two problems:
1. **Wrong key**. The Add form POSTs `"foto_fisik"` (per backend audit) — the GET response almost certainly echoes the DB column `foto_fisik`, not `foto_url`. Reading `foto_url` yields null → empty URL.
2. **Unqualified relative URL**. If the backend returns a relative path (e.g. `uploads/senjata/xxx.jpg`), `Image.network` needs `$apiBaseUrl` prefix.

`errorBuilder` already present (renders `image_not_supported` icon) — keep it as the graceful fallback.

---

## 2. Fix Plan

### 2.1 Fix `deleteSenjata` — String UUID, correct endpoint

**File**: `lib/pages/senjata.dart`, lines 113–125:

**Before:**
```dart
Future<void> deleteSenjata(int id) async {
  ...
  final response = await http.delete(
    Uri.parse("$apiBaseUrl/api/v1/senjata"),
    ...
    body: jsonEncode({"senjata_id": id}),
  );
```

**After:**
```dart
Future<void> deleteSenjata(String id) async {
  ...
  final response = await http.delete(
    Uri.parse("$apiBaseUrl/api/v1/logistik/senjata"),
    ...
    body: jsonEncode({"senjata_id": id}),
  );
```

### 2.2 Fix the delete call site (lines 381–389)

**Before:**
```dart
if (result == true) {
  deleteSenjata(
    int.parse(e["senjata_id"].toString()),
  );
}
```

**After:**
```dart
if (result == true) {
  final senjataId = e["senjata_id"]?.toString() ?? "";
  if (senjataId.isNotEmpty) {
    deleteSenjata(senjataId);
  }
}
```

### 2.3 Add `_fotoUrl` helper

**File**: `lib/pages/senjata.dart` — add to `_SenjataPageState` (near `_formatKategori`):

```dart
String _fotoUrl(Map<String, dynamic> e) {
  final raw = e["foto_fisik"] ?? e["foto_url"];
  final url = raw?.toString() ?? "";
  if (url.isEmpty) return "";
  if (url.startsWith("http://") || url.startsWith("https://")) return url;
  // Relative path → qualify with base URL.
  return url.startsWith("/") ? "$apiBaseUrl$url" : "$apiBaseUrl/$url";
}
```

Key resolution order: `foto_fisik` (what we POST, what GET echoes) → `foto_url` (original contract fallback). Absolute URLs pass through unchanged; relative paths get `$apiBaseUrl` prefix.

### 2.4 Use helper in FOTO UNIT cell (line 300)

**Before:**
```dart
child: Image.network(
  e["foto_url"] ?? "",
  width: 80,
```

**After:**
```dart
child: Image.network(
  _fotoUrl(e),
  width: 80,
```

`errorBuilder` stays — covers null/invalid URLs with the `image_not_supported` icon instead of a crash.

---

## 3. Files Changed

| File | Lines | Change |
|---|---|---|
| `lib/pages/senjata.dart` | 113, 119, 124 | `deleteSenjata(int)` → `deleteSenjata(String)`; DELETE URL → `/api/v1/logistik/senjata`; body sends raw UUID string |
| `lib/pages/senjata.dart` | 381–389 | Drop `int.parse`; pass `e["senjata_id"].toString()`, guarded non-empty |
| `lib/pages/senjata.dart` | new helper + 300 | `_fotoUrl(e)` — reads `foto_fisik`→`foto_url`, qualifies relative URLs |

## 4. Validation Steps

1. Click delete on a row → confirm dialog → "Hapus" → no `FormatException`; DELETE hits `/api/v1/logistik/senjata` with string UUID.
2. FOTO UNIT column shows actual images (absolute or base-qualified URLs); rows without photos show the `image_not_supported` icon.
3. `flutter analyze lib/pages/senjata.dart` clean.

## 5. Notes / Out of Scope

- If the backend's image path prefix differs from `$apiBaseUrl` (e.g., a separate CDN/host), adjust the prefix inside `_fotoUrl` — one place to change.
- `onEdit` remains a no-op (edit mode not yet built) — unchanged.
