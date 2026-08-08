# PolresPage — Search & Pagination Build Report

**Date:** 2025-01-17  
**Status:** ✅ IMPLEMENTED & VERIFIED  
**Verification:** `flutter analyze lib/pages/polres.dart` → **No issues found** (Flutter 3.29.3, SDK copied to `/tmp/flutter-sdk`; run with `HOME=/tmp/flutter-home` because the source SDK dir is read-only)

---

## 1. Changes Applied to `lib/pages/polres.dart`

### 1.1 Import (line 1)

```dart
import 'dart:async';   // ← NEW — required for Timer
```

### 1.2 New state variables (`_PolresPageState`, lines 31–40)

```dart
/// ========================
/// SEARCH & PAGINATION STATE
/// ========================
String _searchQuery = "";
Timer? _debounce;
final TextEditingController _searchController = TextEditingController();
int _currentPage = 1;
int _totalPages = 1;
int _totalItems = 0;
int _perPage = 10;
```

### 1.3 `getPolresApi()` — refactored (lines 51–118)

**Base URI verified:** `$apiBaseUrl/api/v1/master/polres` — unchanged. The audit confirmed **no `polda_id` filter exists** on this page, so nothing needed preserving.

**Query parameters appended safely** (via `Uri.replace(queryParameters:)` — URL-encodes automatically, never string-concatenates):

```dart
Uri uri = Uri.parse("$apiBaseUrl/api/v1/master/polres");
final Map<String, String> params = {
  "page": _currentPage.toString(),
  "limit": _perPage.toString(),
};
if (_searchQuery.isNotEmpty) {
  params["search"] = _searchQuery;
}
uri = uri.replace(queryParameters: params);
```

**New nested JSON parsing** with graceful fallbacks (mirrors `polda.dart`):

```dart
final data = json["data"];
// New backend shape: { data: { items: [...], pagination: {...} } }.
// Tolerates the legacy flat-list shape as a fallback.
final List rawList = data is Map
    ? (data["items"] is List ? data["items"] : [])
    : (data is List ? data : []);
final Map<String, dynamic> pagination = data is Map &&
        data["pagination"] is Map
    ? data["pagination"] as Map<String, dynamic>
    : <String, dynamic>{};
final parsed =
    rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
```

**Pagination metadata updated in state** (with tolerant key fallbacks):

| State var | Primary key | Fallback keys | Default |
|-----------|-------------|---------------|---------|
| `_currentPage` | `current_page` | — | keep current |
| `_totalPages` | `last_page` | `total_pages` | 1 |
| `_totalItems` | `total` | — | `parsed.length` |
| `_perPage` | `per_page` | `limit` | 10 |

Also added `debugPrint("Polres fetched: ${parsed.length} items (page $_currentPage)")` for runtime diagnostics.

### 1.4 New handlers (lines 127–149)

**Debounced search — 400 ms idle wait, always resets to page 1:**

```dart
void _onSearchChanged(String value) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 400), () {
    _searchQuery = value;
    _currentPage = 1;
    getPolresApi();
  });
}
```

**Page change — bounds-checked:**

```dart
void _onPageChanged(int page) {
  if (page < 1 || page > _totalPages || page == _currentPage) return;
  _currentPage = page;
  getPolresApi();
}
```

**Lifecycle cleanup:**

```dart
@override
void dispose() {
  _debounce?.cancel();
  _searchController.dispose();
  super.dispose();
}
```

### 1.5 Widget wiring in `build()`

**Search field (previously bare `AppSearchField(hintText: ...)`):**

```dart
AppSearchField(
  hintText: "Cari Polres...",
  controller: _searchController,
  onChanged: _onSearchChanged,
),
```

**Pagination footer (previously `const AppPagination()` — static):**

```dart
AppPagination(
  currentPage: _currentPage,
  totalPages: _totalPages,
  totalItems: _totalItems,
  perPage: _perPage,
  onPageChanged: _onPageChanged,
),
```

`const` was removed since props are now runtime values.

---

## 2. What Was NOT Changed (scope discipline)

| Aspect | Status |
|--------|--------|
| `initState()` | unchanged — still calls `loadUser()` + `getPolresApi()` |
| `deletePolres()` | unchanged — still refreshes via `getPolresApi()` (current page) |
| Add/Edit `.then()` refresh | unchanged — re-fetches current page |
| `DataTable` rows/columns | unchanged — list always holds current page's items |
| `List<Map<String, dynamic>>` type | preserved (no model class introduced) |
| `AppSearchField` / `AppPagination` widgets | **NOT modified** — they already supported the props |
| Error/empty/loading states | unchanged |

---

## 3. Verification Evidence

| Check | Result |
|-------|--------|
| `flutter analyze lib/pages/polres.dart` | ✅ **No issues found** (ran 36.5s) |
| Initial analyzer run | ⚠️ 1 warning (`unnecessary_cast` line 78) → **fixed** by removing redundant `as List` (Dart promotes after `is List`) |
| `dart:async` import | ✅ present |
| Timer lifecycle | ✅ cancelled in `dispose()` |
| Controller lifecycle | ✅ disposed in `dispose()` |
| Query params | ✅ `page`, `limit`, `search` via `Uri.replace(queryParameters:)` |
| Legacy flat-list fallback | ✅ preserved |

---

## 4. Resulting Request Shape

```
GET $apiBaseUrl/api/v1/master/polres?page=1&limit=10
GET $apiBaseUrl/api/v1/master/polres?page=1&limit=10&search=kota%20bandung
```

Response shapes accepted:

```json
// new (paginated)
{ "data": { "items": [...], "pagination": { "current_page": 1, "last_page": 5, "total": 47, "per_page": 10 } } }

// legacy (flat) — still works
{ "data": [ ... ] }
```

---

## 5. Follow-up (out of scope for this task)

The same treatment is still needed for `personel.dart` (audit showed search/pagination status unknown) and five pages that have debounced search but static pagination: `amunisi.dart`, `sarpras.dart`, `satwa.dart`, `senjata.dart`, `master_kategori_senjata.dart`.
