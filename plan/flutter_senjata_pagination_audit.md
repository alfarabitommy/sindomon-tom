# Weapon Inventory Page — Search & Pagination Audit

**File:** `lib/pages/senjata.dart`  
**Date:** 2025-01-16  
**Status:** Search partially wired; pagination completely absent.

---

## 1. Current State — What Exists vs. What's Missing

### 1.1 Search (Partial — debounce + query exist, but page-reset missing)

| Aspect | Present? | Detail |
|--------|----------|--------|
| `_searchQuery` | ✅ | Line 31: `String _searchQuery = "";` |
| `_debounce` Timer | ✅ | Line 32: `Timer? _debounce;` |
| `_searchController` | ✅ | Line 33: `final TextEditingController _searchController = ...` |
| `_onSearchChanged(value)` | ✅ | Lines 87–93: 400 ms debounce, sets `_searchQuery`, calls `getSenjataApi()` |
| AppSearchField wiring | ✅ | Lines 281–285: `controller`, `onChanged` both passed |
| **Resets page to 1 on search** | ❌ | No `_currentPage = 1` before fetching (variable doesn't exist yet) |
| Search in API call | ⚠️ | `getSenjataApi()` appends `search` query param, but ONLY `search` — no `page`/`limit` |

### 1.2 Pagination (Completely absent)

| Aspect | Present? | Detail |
|--------|----------|--------|
| `_currentPage` | ❌ | Needs declaration: `int _currentPage = 1;` |
| `_totalPages` | ❌ | Needs declaration: `int _totalPages = 1;` |
| `_totalItems` | ❌ | Needs declaration: `int _totalItems = 0;` |
| `_perPage` | ❌ | Needs declaration: `int _perPage = 10;` |
| `_onPageChanged(int page)` | ❌ | Needs method: validate bounds → set `_currentPage` → call `getSenjataApi()` |
| AppPagination wiring | ❌ | Line 470: `const AppPagination()` — hardcoded defaults only |

---

## 2. API Layer Analysis

### 2.1 Current fetch: `getSenjataApi()` (lines 44–78)

```dart
Uri uri = Uri.parse("$apiBaseUrl/api/v1/logistik/senjata");
if (_searchQuery.isNotEmpty) {
  uri = uri.replace(queryParameters: {"search": _searchQuery});
}
```

**Problems:**
- Does NOT send `page` or `limit` query parameters.
- Replaces ALL query parameters with only `search` (should use `uri.replace(queryParameters: {...all params})`).

### 2.2 Current response parsing (lines 60–64)

```dart
final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
final List<dynamic> rawData = jsonResponse["data"] ?? [];
senjataapi = rawData.cast<Map<String, dynamic>>();
```

**Expects a flat JSON array:** `{ "data": [ ... ] }`  
**Cannot handle the paginated envelope:** `{ "data": { "items": [ ... ], "pagination": { ... } } }`

---

## 3. Reference: The "Personel" Pattern (Canonical Implementation)

`lib/pages/personel.dart` is the gold standard — it already has full search + pagination working. Here's exactly how it does it:

### 3.1 State variables (lines 34–40)

```dart
String _searchQuery = "";
Timer? _debounce;
final TextEditingController _searchController = TextEditingController();
int _currentPage = 1;
int _totalPages = 1;
int _totalItems = 0;
int _perPage = 10;
```

### 3.2 API request (lines 56–64)

```dart
Uri uri = Uri.parse("$apiBaseUrl/api/v1/sdm/personil");
final Map<String, String> params = {
  "page": _currentPage.toString(),
  "limit": _perPage.toString(),
};
if (_searchQuery.isNotEmpty) {
  params["search"] = _searchQuery;
}
uri = uri.replace(queryParameters: params);
```

### 3.3 Response parsing — tolerant dual-shape (lines 72–104)

```dart
final data = json["data"];
// Tolerates BOTH: { data: { items: [...], pagination: {...} } }
//           AND legacy: { data: [ ... ] }
final List rawList = data is Map
    ? (data["items"] is List ? data["items"] : [])
    : (data is List ? data : []);
final Map<String, dynamic> pagination = data is Map &&
        data["pagination"] is Map
    ? data["pagination"] as Map<String, dynamic>
    : <String, dynamic>{};

// Then extracts pagination fields with safe fallbacks:
_currentPage = (pagination["current_page"] as num?)?.toInt() ?? _currentPage;
_totalPages  = (pagination["last_page"]   as num?)?.toInt() ??
               (pagination["total_pages"] as num?)?.toInt() ?? 1;
_totalItems  = (pagination["total"]       as num?)?.toInt() ?? parsedItems.length;
_perPage     = (pagination["per_page"]    as num?)?.toInt() ??
               (pagination["limit"]       as num?)?.toInt() ?? _perPage;
```

### 3.4 Search handler (lines 177–184)

```dart
void _onSearchChanged(String value) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 400), () {
    _searchQuery = value;
    _currentPage = 1;        // ← CRITICAL: reset to page 1 on new search
    getPersonelApi();
  });
}
```

### 3.5 Page-change handler (lines 186–190)

```dart
void _onPageChanged(int page) {
  if (page < 1 || page > _totalPages || page == _currentPage) return;
  _currentPage = page;
  getPersonelApi();
}
```

### 3.6 AppPagination widget wiring (lines 613–617)

```dart
AppPagination(
  currentPage: _currentPage,
  totalPages: _totalPages,
  totalItems: _totalItems,
  perPage: _perPage,
  onPageChanged: _onPageChanged,
)
```

Note: **not** `const` — it's a runtime widget with live props.

---

## 4. What Needs to Change in `senjata.dart`

Below is a surgical change list. Every item is a direct analog of the Personel pattern.

### 4.1 Add 4 state variables

After line 33 (`_searchController`), add:

```dart
int _currentPage = 1;
int _totalPages = 1;
int _totalItems = 0;
int _perPage = 10;
```

### 4.2 Rewrite `getSenjataApi()` lines 49–65

Replace the URI-building block (lines 49–52) and the response-parsing block (lines 59–65) to:

```dart
// Build URI with page + limit + optional search
final Map<String, String> params = {
  "page": _currentPage.toString(),
  "limit": _perPage.toString(),
};
if (_searchQuery.isNotEmpty) {
  params["search"] = _searchQuery;
}
final uri = Uri.parse("$apiBaseUrl/api/v1/logistik/senjata")
    .replace(queryParameters: params);

// ... http.get ...

if (response.statusCode == 200) {
  final json = jsonDecode(response.body);
  final data = json["data"];
  final List rawList = data is Map
      ? (data["items"] is List ? data["items"] : [])
      : (data is List ? data : []);
  final Map<String, dynamic> pagination = data is Map &&
          data["pagination"] is Map
      ? data["pagination"] as Map<String, dynamic>
      : <String, dynamic>{};

  if (!mounted) return;
  setState(() {
    senjataapi = rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    _currentPage = (pagination["current_page"] as num?)?.toInt() ?? _currentPage;
    _totalPages  = (pagination["last_page"]   as num?)?.toInt() ??
                   (pagination["total_pages"] as num?)?.toInt() ?? 1;
    _totalItems  = (pagination["total"]       as num?)?.toInt() ?? senjataapi.length;
    _perPage     = (pagination["per_page"]    as num?)?.toInt() ??
                   (pagination["limit"]       as num?)?.toInt() ?? _perPage;
    isLoading = false;
  });
}
```

### 4.3 Fix `_onSearchChanged` — add page reset

Line 90, add `_currentPage = 1;` before `getSenjataApi()`:

```dart
void _onSearchChanged(String value) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 400), () {
    _searchQuery = value;
    _currentPage = 1;   // ← NEW
    getSenjataApi();
  });
}
```

### 4.4 Add `_onPageChanged` method

Add after `_onSearchChanged`:

```dart
void _onPageChanged(int page) {
  if (page < 1 || page > _totalPages || page == _currentPage) return;
  _currentPage = page;
  getSenjataApi();
}
```

### 4.5 Wire AppPagination with live props

Line 470: change from:

```dart
const AppPagination(),
```

to:

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

## 5. API Contract Assumptions

Based on the Personel pattern, the backend's paginated `/api/v1/logistik/senjata` endpoint is expected to:

### Request
```
GET /api/v1/logistik/senjata?page=1&limit=10&search=keyword
```

| Param    | Type   | Notes |
|----------|--------|-------|
| `page`   | int    | 1-based page number |
| `limit`  | int    | Items per page (10) |
| `search` | string | Optional, appended only when non-empty |

### Response (expected shape)
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

The parsing code tolerates both this nested shape AND a legacy flat `"data": [ ... ]` array as a fallback.

---

## 6. Sibling Pages in the Same State

These pages also use `const AppPagination()` without wiring and will need the same treatment:

| Page | File |
|------|------|
| K9 Inventory | `lib/pages/satwa.dart` (line 621) |
| General Inventory | `lib/pages/inventaris.dart` (line 260) |

---

## 7. Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Backend doesn't yet support `page`/`limit` for senjata endpoint | **HIGH** | Verify with the backend team BEFORE merging; the legacy flat-array fallback in parsing ensures existing behavior doesn't break |
| Search alone worked before; adding page params could change API behavior | **MEDIUM** | The `page=1&limit=10` params are always sent — if the backend ignores them and returns full list, `_totalPages` will be `1` and pagination controls will be a no-op. This is safe. |
| `_currentPage` not reset on search in current code | **LOW** | Fix becomes part of this change set |

---

## 8. Verification Checklist (post-implementation)

- [ ] Search typing debounces at 400 ms then fetches.
- [ ] Search always resets to page 1.
- [ ] Pagination buttons navigate correctly (`<`, `>`, page numbers).
- [ ] Pagination shows correct "Menampilkan X hingga Y dari Z data" text.
- [ ] Delete + refresh preserves current page position.
- [ ] Add new senjata + navigate back refreshes list.
- [ ] If backend returns flat array (no pagination), the page still renders all data.
- [ ] No regressions: image thumbnails, kategori formatting, edit/delete flows all work.

---

*Audit performed against commit on branch: `dev` (current workspace). Reference implementation: `lib/pages/personel.dart`.*
