# Satwa Page — Dynamic Pagination Build Report

**Date:** 2025-07-12  
**File modified:** `lib/pages/satwa.dart`  
**Diff size:** +58 / −2 lines  
**Reference pattern:** `lib/pages/sarpras.dart` (identical implementation)

---

## 1. Changes Applied

### 1.1 Imports

`dart:async` — **already present** (line 1), no change needed. All required imports (`dart:convert`, `package:http`, `shared_preferences`, `app_pagination.dart`, `app_search_field.dart`) were already in place.

### 1.2 Pagination state variables (lines 34–37)

Added after `_searchController`:

```dart
int _currentPage = 1;
int _totalPages = 1;
int _totalItems = 0;
int _perPage = 10;
```

### 1.3 `getSatwaApi()` — query parameters (lines 55–64)

URI builder now sends `page`, `limit`, and conditionally `search`:

```dart
final Map<String, String> params = {
  "page": _currentPage.toString(),
  "limit": _perPage.toString(),
};
if (_searchQuery.isNotEmpty) {
  params["search"] = _searchQuery;
}

Uri uri = Uri.parse("$apiBaseUrl/api/v1/logistik/satwa");
uri = uri.replace(queryParameters: params);
```

### 1.4 `getSatwaApi()` — nested JSON parsing (lines 71–103)

Replaced the flat-list assumption with the envelope-aware parser. The success branch now:

1. Extracts `data` as `dynamic`.
2. Resolves the item list: `data["items"]` when `data` is a `Map`, else the raw `List` (legacy flat-shape fallback), else `[]`.
3. Resolves `pagination` map only when `data["pagination"]` is a `Map`, else `{}`.
4. Casts each item with `Map<String, dynamic>.from(e as Map)` — same hardening as `sarpras.dart`.
5. In `setState`, updates:
   - `_currentPage` ← `pagination["current_page"]` (fallback: keep current)
   - `_totalPages` ← `pagination["last_page"]` → `pagination["total_pages"]` → `1`
   - `_totalItems` ← `pagination["total"]` (fallback: `parsedItems.length`)
   - `_perPage` ← `pagination["per_page"]` → `pagination["limit"]` → keep current

The `if (!mounted) return;` guard was already present at every `setState` site (success/error/catch) and remains intact.

### 1.5 `_onSearchChanged` — page reset (line 131)

Inside the 400ms debounce timer callback, added `_currentPage = 1;` before `getSatwaApi()`, so a new search always starts at page 1 (prevents `page=3&search=foo` empty-result scenarios).

### 1.6 `_onPageChanged` — new method (lines 136–140)

```dart
void _onPageChanged(int page) {
  if (page < 1 || page > _totalPages || page == _currentPage) return;
  _currentPage = page;
  getSatwaApi();
}
```

Bounds-checked; no-op for invalid or redundant taps; refetches on valid page change.

### 1.7 `build()` — `AppPagination` wiring (lines 663–669)

```dart
AppPagination(
  currentPage: _currentPage,
  totalPages: _totalPages,
  totalItems: _totalItems,
  perPage: _perPage,
  onPageChanged: _onPageChanged,
),
```

Replaced the static `const AppPagination()`. `AppSearchField` required no changes (already wired to `_onSearchChanged` via `onChanged` and `_searchController`).

---

## 2. Verification

| Check | Result |
|-------|--------|
| `dart:async` import | ✅ Present (pre-existing, line 1) |
| Pagination variables declared | ✅ Lines 34–37 |
| `page`/`limit` sent on every fetch | ✅ Lines 55–58 |
| `search` still sent when non-empty | ✅ Lines 59–61 |
| Nested `{ items, pagination }` parsing | ✅ Lines 71–85 |
| Legacy flat-list fallback | ✅ `data is List ? data : []` |
| Pagination metadata state update | ✅ Lines 90–101 |
| `_currentPage = 1` on search | ✅ Line 131 |
| `_onPageChanged` bounds guard | ✅ Lines 137–138 |
| `AppPagination` props wired | ✅ Lines 663–669 |
| `if (!mounted) return;` guards | ✅ Pre-existing, untouched (success/error/catch) |

**Tooling note:** `flutter analyze` could not run in this environment (no Flutter/Dart SDK installed — `flutter: command not found`). Verification was performed via:
- Full read-back of every changed section (lines 31–103, 127–147, 660–672).
- `git diff` review confirming +58/−2, isolated to the intended regions.
- Exact parity with the proven `sarpras.dart` / `amunisi.dart` implementation, which compiles cleanly in CI on every push to `dev` (GitHub Actions Windows build).

---

## 3. Behavior After This Change

1. **Initial load:** `getSatwaApi()` fetches `page=1&limit=10`; table shows 10 rows; pagination strip displays real totals (`Menampilkan 1 hingga 10 dari N data`).
2. **Search:** typing debounces 400ms, resets to page 1, sends `page=1&limit=10&search=...`.
3. **Page navigation:** clicking `<`/`>`/page numbers triggers `_onPageChanged` → bounds check → refetch with new `page`.
4. **Legacy safety:** if the backend ever returns the old flat `data` array, the parser falls back gracefully and pagination defaults to a single page with `total = items.length`.

## 4. Follow-ups (not required for this task)

- Other pages still using static pagination: `inventaris.dart` (line 260) and `report.dart` (line 234) remain on `const AppPagination()` — candidate for the same treatment.
- A subsequent `flutter analyze` run in a Flutter-enabled environment is recommended before merge.
