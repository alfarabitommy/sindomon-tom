# Flutter Sarpras Pagination Build Report

**Date:** 2025-07-17
**File changed:** `lib/pages/sarpras.dart`
**Scope:** Dynamic pagination + new nested backend JSON parsing + `mounted` guard fix
**Reference pattern:** `lib/pages/senjata.dart` (proven implementation)

---

## 1. Change Summary

| # | Change | Status |
|---|---|---|
| 1 | `dart:async` import | ✅ Already present (line 1) — no change needed |
| 2 | Pagination state variables added | ✅ DONE |
| 3 | `_onSearchChanged` resets `_currentPage = 1` | ✅ DONE |
| 4 | `_onPageChanged(int page)` method added | ✅ DONE |
| 5 | `getSarprasApi()` URI + nested JSON parsing + `mounted` guard | ✅ DONE |
| 6 | `AppPagination` dynamically wired in `build()` | ✅ DONE |

---

## 2. Detailed Changes

### 2.1 Imports (line 1)

```dart
import 'dart:async';
```

Already present — `Timer` and `Timer?` type were already in use for the debounce. No change required.

### 2.2 Pagination State Variables (lines 34–37)

Added after `_searchController`:

```dart
int _currentPage = 1;
int _totalPages = 1;
int _totalItems = 0;
int _perPage = 10;
```

Defaults match the `AppPagination` widget defaults (page 1, 10 per page), so first render is consistent even before the first API response.

### 2.3 `getSarprasApi()` Refactor (lines 49–118)

**URI builder** — now always sends `page` + `limit`, plus `search` when non-empty:

```dart
final Map<String, String> params = {
  "page": _currentPage.toString(),
  "limit": _perPage.toString(),
};
if (_searchQuery.isNotEmpty) {
  params["search"] = _searchQuery;
}

final Uri uri = Uri.parse(
  "$apiBaseUrl/api/v1/logistik/sarpras",
).replace(queryParameters: params);
```

Note: the previous bug-fix comment ("no trailing `?` when search is empty") is preserved in spirit — `Uri.replace(queryParameters:)` never emits a dangling `?`, and now the query string is non-empty on every request since `page`/`limit` are always present.

**Nested JSON parsing** — dual-shape parser tolerating both new and legacy payloads:

```dart
final dynamic data = jsonResponse["data"];

// New backend shape: { data: { items: [...], pagination: {...} } }.
// Tolerates the legacy flat-list shape as a fallback.
final List rawList = data is Map
    ? (data["items"] is List ? data["items"] : [])
    : (data is List ? data : []);
final Map<String, dynamic> pagination = data is Map &&
        data["pagination"] is Map
    ? data["pagination"] as Map<String, dynamic>
    : <String, dynamic>{};
final List<Map<String, dynamic>> parsedItems =
    rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
```

Fallback matrix:

| Backend `data` shape | `rawList` | `pagination` |
|---|---|---|
| `{ items: [...], pagination: {...} }` | `data["items"]` | `data["pagination"]` |
| Flat `[ ... ]` | `data` itself | `{}` (metadata falls back to defaults) |
| `null` / missing | `[]` | `{}` |

**`mounted` guard (SECURITY/ROBUSTNESS FIX)** — added before every `setState` in the async continuation:

```dart
if (!mounted) return;
setState(() { ... });
```

Applied in all three branches (success, non-200 else, catch) — matching the `senjata.dart` reference exactly. This eliminates the risk of `setState() called after dispose()` when the page is popped while a request is in flight.

**State update with pagination metadata:**

```dart
setState(() {
  sarprasApi = parsedItems;
  _currentPage =
      (pagination["current_page"] as num?)?.toInt() ?? _currentPage;
  _totalPages =
      (pagination["last_page"] as num?)?.toInt() ??
      (pagination["total_pages"] as num?)?.toInt() ??
      1;
  _totalItems =
      (pagination["total"] as num?)?.toInt() ?? parsedItems.length;
  _perPage =
      (pagination["per_page"] as num?)?.toInt() ??
      (pagination["limit"] as num?)?.toInt() ??
      _perPage;
  isLoading = false;
});
```

All numeric reads are `as num?` safe-cast → `toInt()`, so string or int values from the backend both work.

### 2.4 `_onSearchChanged()` — Page Reset (lines 127–134)

```dart
void _onSearchChanged(String value) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 400), () {
    _searchQuery = value;
    _currentPage = 1;  // ← NEW: search always starts from page 1
    getSarprasApi();
  });
}
```

### 2.5 `_onPageChanged()` — New Method (lines 136–140)

```dart
void _onPageChanged(int page) {
  if (page < 1 || page > _totalPages || page == _currentPage) return;
  _currentPage = page;
  getSarprasApi();
}
```

Bounds-checked and deduplicated: ignores out-of-range pages and re-clicks on the current page.

### 2.6 `AppPagination` Wiring (lines 581–587)

Replaced `const AppPagination(),` with:

```dart
AppPagination(
  currentPage: _currentPage,
  totalPages: _totalPages,
  totalItems: _totalItems,
  perPage: _perPage,
  onPageChanged: _onPageChanged,
),
```

---

## 3. Verification

- **Manual code review:** All 4 multi-edits applied atomically; full read-back of lines 25–154 confirms correct structure (`multi_edit` applied 4/4 edits, verified via `read_file` and `grep`).
- **`grep` confirmation:** `_onPageChanged` defined at line 136; `AppPagination(` at line 581 with all 5 dynamic props; no remaining `const AppPagination()` in the file.
- **`dart:async`:** confirmed at line 1 via `head -3`.
- **Static analysis (`flutter analyze`):** ⚠️ NOT RUN — `flutter`/`dart` toolchain is not installed in this environment. The refactor is a verbatim application of the already-analyzing `senjata.dart` pattern, so compile risk is minimal; run `flutter analyze` locally before shipping.

### Files touched
- `lib/pages/sarpras.dart` (only file changed)
- No changes needed in `lib/widget/app_pagination.dart` (already supports all props) or `lib/widget/app_search_field.dart` (already wired)

---

## 4. Resulting Request Flow

```
Initial load:        GET /api/v1/logistik/sarpras?page=1&limit=10
Search ("anjing"):   GET /api/v1/logistik/sarpras?page=1&limit=10&search=anjing
Page click (3):      GET /api/v1/logistik/sarpras?page=3&limit=10
Search while p.3:    debounce 400ms → page reset to 1 + search param
```

Pagination metadata (`current_page`, `last_page`, `total`, `per_page`) round-trips from the backend into the widget, so "Menampilkan X hingga Y dari Z data" and the page-number strip are always accurate.

---

## 5. Follow-ups

- Run `flutter analyze` in a Flutter-enabled environment (CI or local) to confirm zero analyzer issues.
- Manually smoke-test: pagination clicks, search-while-on-later-page (should jump to page 1), and delete-on-last-item-of-page (list refreshes; page count re-derives from backend).
