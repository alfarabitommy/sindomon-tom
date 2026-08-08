# Flutter Sarpras Pagination Audit

**Date:** 2025-07-17
**Scope:** `lib/pages/sarpras.dart` (primary), `lib/pages/inventaris.dart` (bonus)
**Reference implementation:** `lib/pages/senjata.dart` (already wired)

---

## 1. Summary of Current State

| Capability | sarpras.dart | inventaris.dart | senjata.dart (ref) |
|---|---|---|---|
| Real API fetch | ✅ Yes | ❌ Hardcoded list | ✅ Yes |
| Search with debounce | ✅ Yes | ❌ Static widget | ✅ Yes |
| Search resets page to 1 | ❌ No (var missing) | ❌ N/A | ✅ Yes |
| Pagination state vars | ❌ None | ❌ None | ✅ All 4 |
| Dynamic AppPagination | ❌ `const` | ❌ `const` | ✅ Fully wired |
| Nested JSON parsing | ❌ Flat only | ❌ N/A | ✅ Both shapes |

---

## 2. Detailed Audit: `sarpras.dart`

### 2.1 State Variables (lines 26–33)

```dart
List<Map<String, dynamic>> sarprasApi = [];
bool isLoading = true;
String unLogin = "";
String roleLabel = "Operator";

String _searchQuery = "";
Timer? _debounce;
final TextEditingController _searchController = TextEditingController();
```

**What's present:**
- ✅ `_searchQuery` — stores the current search term
- ✅ `_debounce` — `Timer?` for 400ms debounce
- ✅ `_searchController` — `TextEditingController` wired to `AppSearchField`

**What's MISSING (all 4 pagination variables):**

| Variable | Type | Typical default | Reference |
|---|---|---|---|
| `_currentPage` | `int` | `1` | senjata.dart:34 |
| `_totalPages` | `int` | `1` | senjata.dart:35 |
| `_totalItems` | `int` | `0` | senjata.dart:36 |
| `_perPage` | `int` | `10` | senjata.dart:37 |

---

### 2.2 API Fetch Method: `getSarprasApi()` (lines 45–79)

```dart
Future<void> getSarprasApi() async {
  // ...
  Uri uri = Uri.parse("$apiBaseUrl/api/v1/logistik/sarpras");
  if (_searchQuery.isNotEmpty) {
    uri = uri.replace(queryParameters: {"search": _searchQuery});
  }
  // ...
  final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
  final List<dynamic> rawData = jsonResponse["data"] ?? [];
  setState(() {
    sarprasApi = rawData.cast<Map<String, dynamic>>();
    isLoading = false;
  });
}
```

**Issues found:**

1. **No `page` or `limit` query params** — The `uri` only carries `search` when non-empty. The backend will never know which page to return.

2. **Flat-array parsing only** — The response is parsed as:
   ```dart
   final List<dynamic> rawData = jsonResponse["data"] ?? [];
   sarprasApi = rawData.cast<Map<String, dynamic>>();
   ```
   This assumes `data` is always a flat `[...]`. The backend may already (or will soon) return the nested shape:
   ```json
   {
     "data": {
       "items": [ ... ],
       "pagination": {
         "current_page": 1,
         "last_page": 5,
         "total": 47,
         "per_page": 10
       }
     }
   }
   ```
   The existing code will silently get **0 items** because `jsonResponse["data"]` is a `Map`, which `?? []` won't help — `rawData` becomes a `Map`, and `rawData.cast<Map<String, dynamic>>()` will throw a runtime type error.

3. **No `mounted` guard before `setState`** — The senjata.dart reference guards with `if (!mounted) return;` before every `setState` in the async handler. Sarpras lacks this, risking `setState()` on a disposed widget.

---

### 2.3 Search Handler: `_onSearchChanged()` (lines 88–94)

```dart
void _onSearchChanged(String value) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 400), () {
    _searchQuery = value;
    getSarprasApi();
  });
}
```

**What's correct:**
- ✅ Debounce at 400ms matches the reference pattern
- ✅ Updates `_searchQuery` before calling fetch

**What's MISSING:**
- ❌ **No `_currentPage = 1` reset** — When the user starts a new search, the page should reset to page 1. The reference in senjata.dart:130 does: `_currentPage = 1;` immediately after `_searchQuery = value;`.

---

### 2.4 Pagination Change Handler: `_onPageChanged()` — MISSING ENTIRELY

The sarpras page has **no** `_onPageChanged` method. The reference implementation (senjata.dart:135–139):

```dart
void _onPageChanged(int page) {
  if (page < 1 || page > _totalPages || page == _currentPage) return;
  _currentPage = page;
  getSarprasApi();
}
```

This needs to be added verbatim (with the method renamed `getSarprasApi`).

---

### 2.5 AppPagination Widget Wiring (line 535)

```dart
const AppPagination(),
```

**Current:** Hardcoded `const` with all defaults (shows "Menampilkan 1 hingga 10 dari 50 data", page 1 active, no click handlers).

**Required:**
```dart
AppPagination(
  currentPage: _currentPage,
  totalPages: _totalPages,
  totalItems: _totalItems,
  perPage: _perPage,
  onPageChanged: _onPageChanged,
),
```

The `AppPagination` widget (`lib/widget/app_pagination.dart`) **already supports all these props** with sensible defaults, so no widget changes are needed.

---

### 2.6 Dispose (lines 97–101)

```dart
@override
void dispose() {
  _debounce?.cancel();
  _searchController.dispose();
  super.dispose();
}
```

✅ **No changes needed.** The dispose is correct.

---

## 3. Bonus: `inventaris.dart` — Still Entirely Static

The `inventaris.dart` page is a completely separate page (not in the sidebar) that has never been wired to any API:

- ❌ Uses a hardcoded `listinventaris` (5 duplicate entries of "APC Anoa-2 6x6")
- ❌ No `http` import, no API fetch method
- ❌ No search logic — `AppSearchField(hintText: "Cari Inventaris...")` with no `controller` or `onChanged`
- ❌ `const AppPagination()` — hardcoded
- ❌ Edit/delete buttons are no-ops (`onEdit: () {}, onDelete: () {}`)

**This page is out of scope for the current task** but is noted here because someone scanning for "pagination" might land here. It needs a full API wiring from scratch, not just pagination.

---

## 4. Integration Plan (for `sarpras.dart` only)

### 4.1 Add State Variables

After `_searchController` (line 33), add:

```dart
int _currentPage = 1;
int _totalPages = 1;
int _totalItems = 0;
int _perPage = 10;
```

### 4.2 Update `getSarprasApi()`

Replace the URI construction and JSON parsing with the senjata.dart pattern:

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

Replace the flat-array parsing with the dual-shape parser:

```dart
final dynamic data = jsonResponse["data"];

// Tolerates both { items: [...], pagination: {...} } and legacy flat [...]
final List rawList = data is Map
    ? (data["items"] is List ? data["items"] : [])
    : (data is List ? data : []);
final Map<String, dynamic> pagination = data is Map &&
        data["pagination"] is Map
    ? data["pagination"] as Map<String, dynamic>
    : <String, dynamic>{};
final List<Map<String, dynamic>> parsedItems =
    rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();

if (!mounted) return;
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

### 4.3 Update `_onSearchChanged()`

Add `_currentPage = 1;` after `_searchQuery = value;`:

```dart
void _onSearchChanged(String value) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 400), () {
    _searchQuery = value;
    _currentPage = 1;  // ← ADD THIS
    getSarprasApi();
  });
}
```

### 4.4 Add `_onPageChanged()`

```dart
void _onPageChanged(int page) {
  if (page < 1 || page > _totalPages || page == _currentPage) return;
  _currentPage = page;
  getSarprasApi();
}
```

### 4.5 Update `AppPagination` call site (line 535)

Replace `const AppPagination(),` with:

```dart
AppPagination(
  currentPage: _currentPage,
  totalPages: _totalPages,
  totalItems: _totalItems,
  perPage: _perPage,
  onPageChanged: _onPageChanged,
),
```

### 4.6 Add `mounted` guards

Add `if (!mounted) return;` before each `setState` in the async error/else branches of `getSarprasApi()` and before the `ScaffoldMessenger` usage in `deleteSarpras` (the delete method already has this).

---

## 5. Files That Need Changes

| File | Change |
|---|---|
| `lib/pages/sarpras.dart` | All 6 integration points above |
| `lib/widget/app_pagination.dart` | **No changes** — already supports dynamic props |
| `lib/widget/app_search_field.dart` | **No changes** — already supports `controller` + `onChanged` |

---

## 6. Backend API Contract Assumptions

The implementation assumes the backend endpoint:

```
GET /api/v1/logistik/sarpras?page=1&limit=10&search=term
```

Returns:

```json
{
  "data": {
    "items": [ ... ],
    "pagination": {
      "current_page": 1,
      "last_page": 5,
      "total": 47,
      "per_page": 10
    }
  }
}
```

If the backend currently returns a flat `"data": [ ... ]`, the dual-shape parser will still work (it falls back to the legacy flat-array code path). If the backend returns a flat array AND separate pagination in headers or a different JSON key, the fallback will show all items on one page with `_totalItems = parsedItems.length` — functional but not truly paginated.

---

## 7. Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| Backend not yet serving paginated sarpras | Low | Dual-shape parser falls back to flat array |
| `_perPage` mismatch with backend default | Low | `_perPage` is read from response if available |
| Race condition (rapid page changes) | Low | `_onPageChanged` guards against redundant calls |
| `setState` after dispose | Medium | Add `mounted` guards (currently missing) |
