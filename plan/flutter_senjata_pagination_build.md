# Weapon Inventory Page — Dynamic Pagination Build Report

**File changed:** `lib/pages/senjata.dart`  
**Date:** 2025-01-16  
**Status:** ✅ IMPLEMENTED — search + dynamic pagination wired to the new backend API

---

## 1. Changes Applied

### 1.1 `dart:async` import
Already present (line 1) — no change needed.

### 1.2 Pagination state variables added (after `_searchController`, lines 34–37)

```dart
int _currentPage = 1;
int _totalPages = 1;
int _totalItems = 0;
int _perPage = 10;
```

### 1.3 `getSenjataApi()` refactored (lines 48–117)

**URI builder** — now sends `page` + `limit` always, and `search` conditionally:

```dart
final Map<String, String> params = {
  "page": _currentPage.toString(),
  "limit": _perPage.toString(),
};
if (_searchQuery.isNotEmpty) {
  params["search"] = _searchQuery;
}

final Uri uri = Uri.parse(
  "$apiBaseUrl/api/v1/logistik/senjata",
).replace(queryParameters: params);
```

**Response parsing** — tolerant dual-shape (matches `personel.dart`):

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

**State update** — assigns parsed items + pagination metadata with safe fallbacks:

| Field | Source key | Fallback |
|-------|-----------|----------|
| `_currentPage` | `pagination["current_page"]` | keep current |
| `_totalPages` | `pagination["last_page"]` → `pagination["total_pages"]` | `1` |
| `_totalItems` | `pagination["total"]` | `parsedItems.length` |
| `_perPage` | `pagination["per_page"]` → `pagination["limit"]` | keep current |

All `setState` calls are now guarded with `if (!mounted) return;` (added in the success, non-200, and catch branches) — prevents the "setState called after dispose" race on async responses.

### 1.4 `_onSearchChanged` updated (lines 126–133)

Now resets to page 1 before fetching, so search results start from the beginning:

```dart
void _onSearchChanged(String value) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 400), () {
    _searchQuery = value;
    _currentPage = 1;      // ← NEW
    getSenjataApi();
  });
}
```

### 1.5 `_onPageChanged` added (lines 135–139)

```dart
void _onPageChanged(int page) {
  if (page < 1 || page > _totalPages || page == _currentPage) return;
  _currentPage = page;
  getSenjataApi();
}
```

### 1.6 `build()` — AppPagination wired (lines 516–522)

Replaced `const AppPagination()` with live-props instance:

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

## 2. Verification

### 2.1 Static analysis
`flutter analyze` could **not** be executed in this environment — the Flutter/Dart SDK is not installed (checked `which flutter`, `which dart`, common install paths — all absent). **Action required:** run `flutter analyze` on a machine with the SDK before merging.

### 2.2 Manual code review (performed)

| Check | Result |
|-------|--------|
| Pagination vars declared after `_searchController` | ✅ |
| URI includes `page`, `limit`, conditional `search` | ✅ |
| Nested `{ items, pagination }` parsing with flat-array fallback | ✅ |
| Pagination metadata update inside `setState` | ✅ |
| `_onSearchChanged` resets `_currentPage = 1` | ✅ |
| `_onPageChanged` bounds-check + fetch | ✅ |
| `AppPagination` receives all 5 live props | ✅ |
| No `const` on `AppPagination` (runtime props) | ✅ |
| `mounted` guards on all post-async `setState` calls | ✅ |
| Search field wiring (`controller`, `onChanged`) untouched | ✅ |
| Delete flow (`deleteSenjata`) → `getSenjataApi()` refresh preserved | ✅ |
| Edit/Add flow (`AddSenjataPage` result refresh) preserved | ✅ |
| Image thumbnail, `_formatKategori` untouched | ✅ |

Diff summary: `+62 / −14` lines in `lib/pages/senjata.dart` — `git diff` reviewed, all changes confined to the planned sections.

---

## 3. Resulting API Contract

```
GET /api/v1/logistik/senjata?page=1&limit=10&search=optional
```

```json
{
  "data": {
    "items": [ ... ],
    "pagination": {
      "current_page": 1,
      "last_page": 5,
      "per_page": 10,
      "total": 47
    }
  }
}
```

Legacy flat `"data": [ ... ]` responses are still tolerated (items render, pagination strip shows defaults).

---

## 4. Follow-ups

- [ ] Run `flutter analyze` locally (SDK not available in this environment).
- [ ] Manual smoke test: page navigation, search-resets-to-page-1, delete/refresh, add/refresh.
- [ ] If the backend does not yet support `page`/`limit` on this endpoint, confirm with the backend team — the client is safe either way (fallbacks keep it functional).

*Reference pattern: `lib/pages/personel.dart` (already-shipped pagination implementation).*  
*Prior audit: `plan/flutter_senjata_pagination_audit.md`.*
