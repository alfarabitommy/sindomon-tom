# Satwa Page — Real-Time Search & Dynamic Pagination Audit

**Audit date:** 2025-07-12  
**File:** `lib/pages/satwa.dart`  
**Reference implementation:** `lib/pages/amunisi.dart` (and 7 other pages with identical wiring)

---

## 1. State Variables Inventory

### ✅ Present (search)

| Variable | Line | Notes |
|----------|------|-------|
| `_searchQuery` | 31 | `String`, initialized to `""` |
| `_debounce` | 32 | `Timer?`, nullable |
| `_searchController` | 33 | `TextEditingController` |

### ❌ Missing (pagination)

Every other wired page (`amunisi`, `sarpras`, `senjata`, `personel`, `polda`, `polres`, `user_page`, `master_kategori_senjata`) declares these four variables immediately after `_searchController`. Satwa has none of them:

| Variable | Default | Purpose |
|----------|---------|---------|
| `int _currentPage = 1` | `1` | Current page number sent to API |
| `int _totalPages = 1` | `1` | Last page from API (key: `last_page` / `total_pages`) |
| `int _totalItems = 0` | `0` | Total record count from API (key: `total`) |
| `int _perPage = 10` | `10` | Page size sent as `limit`, read back as `per_page` |

**Verdict:** Search state is complete. Pagination state is entirely absent.

---

## 2. API Fetch Method: `getSatwaApi()` (lines 46–83)

### 2.1 Query parameters

**Current behavior:** Only `search` is appended, and only when non-empty:

```dart
Uri uri = Uri.parse("$apiBaseUrl/api/v1/logistik/satwa");
if (_searchQuery.isNotEmpty) {
  uri = uri.replace(queryParameters: {"search": _searchQuery});
}
```

**What's missing:** `page` and `limit` are never sent. The reference pattern from `amunisi.dart` (lines 53–63) is:

```dart
final Map<String, String> params = {
  "page": _currentPage.toString(),
  "limit": _perPage.toString(),
};
if (_searchQuery.isNotEmpty) {
  params["search"] = _searchQuery;
}
final Uri uri = Uri.parse("$apiBaseUrl/api/v1/logistik/amunisi")
    .replace(queryParameters: params);
```

### 2.2 JSON parsing — nested pagination shape

**Current behavior (lines 62–63):** Flat-list only — assumes `data` is a direct array:

```dart
final List<dynamic> rawData = jsonResponse["data"] ?? [];
// ...
satwaApi = rawData.cast<Map<String, dynamic>>();
```

**What's missing:** The backend now returns a nested envelope:

```json
{
  "data": {
    "items": [ ... ],
    "pagination": {
      "current_page": 1,
      "last_page": 5,
      "total": 48,
      "per_page": 10
    }
  }
}
```

The reference parsing from `amunisi.dart` (lines 72–101) handles both shapes:

```dart
final dynamic data = jsonResponse["data"];
final List rawList = data is Map
    ? (data["items"] is List ? data["items"] : [])
    : (data is List ? data : []);
final Map<String, dynamic> pagination = data is Map &&
        data["pagination"] is Map
    ? data["pagination"] as Map<String, dynamic>
    : <String, dynamic>{};
final List<Map<String, dynamic>> parsedItems =
    rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();

// Then in setState:
_currentPage = (pagination["current_page"] as num?)?.toInt() ?? _currentPage;
_totalPages = (pagination["last_page"] as num?)?.toInt() ??
              (pagination["total_pages"] as num?)?.toInt() ?? 1;
_totalItems = (pagination["total"] as num?)?.toInt() ?? parsedItems.length;
_perPage = (pagination["per_page"] as num?)?.toInt() ??
           (pagination["limit"] as num?)?.toInt() ?? _perPage;
```

Key resilience notes:
- `items` fallback: if `data` is still a flat list (legacy), `rawList` is that list.
- `last_page` fallback: tries `last_page` first, then `total_pages`, defaults to `1`.
- `per_page` fallback: tries `per_page`, then `limit`, defaults to existing `_perPage`.
- `total` fallback: defaults to `parsedItems.length` if absent.

### 2.3 Mounted guard

**✅ Present.** All three `setState` sites (success line 64, error line 70, catch line 76) are guarded with `if (!mounted) return;`. This is correct and matches the reference pages.

---

## 3. Search Handler: `_onSearchChanged` (lines 92–98)

**Current behavior:**

```dart
void _onSearchChanged(String value) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 400), () {
    _searchQuery = value;
    getSatwaApi();       // ← page is NOT reset
  });
}
```

**What's missing:** It does **not** reset `_currentPage` to `1`. Every wired page includes `_currentPage = 1;` before `getSatwaApi()` inside the debounce callback (e.g., `amunisi.dart` line 130):

```dart
_debounce = Timer(const Duration(milliseconds: 400), () {
  _searchQuery = value;
  _currentPage = 1;       // ← MISSING in satwa
  getSatwaApi();
});
```

**Impact:** Without this reset, typing a search term while on page 3 would send `page=3&search=foo`, likely returning an empty or wrong page.

---

## 4. Pagination Handler: `_onPageChanged` — **Entirely absent**

No `_onPageChanged` method exists in `satwa.dart`. The reference from `amunisi.dart` (lines 135–139):

```dart
void _onPageChanged(int page) {
  if (page < 1 || page > _totalPages || page == _currentPage) return;
  _currentPage = page;
  getAmunisiApi();
}
```

---

## 5. Build Method: `AppPagination` Wiring (line 621)

**Current:** `const AppPagination()` — zero props, renders the hardcoded default ("Menampilkan 1 hingga 10 dari 50 data", page 1 highlighted, buttons non-functional).

**Reference wiring** (from `amunisi.dart` lines 560–565):

```dart
AppPagination(
  currentPage: _currentPage,
  totalPages: _totalPages,
  totalItems: _totalItems,
  perPage: _perPage,
  onPageChanged: _onPageChanged,
),
```

The `AppPagination` widget (`lib/widget/app_pagination.dart`) is already designed to accept these props and become fully interactive. All 5 props have sensible defaults, so `const AppPagination()` keeps compiling — but is effectively dead UI.

---

## 6. `loadUser()` Mounted Guard

**✅ Present** (line 37). `if (!mounted) return;` guards the `setState` in `loadUser()`. This is actually *better* than the reference `amunisi.dart` which omits it. No action needed here.

---

## 7. Summary: Integration Checklist

To wire real-time search + dynamic pagination, the following changes are needed, in order:

| # | Change | Location | Lines affected |
|---|--------|----------|----------------|
| 1 | Add 4 pagination state variables | After `_searchController` (line 33) | New lines 34–37 |
| 2 | Add `page` + `limit` query params | `getSatwaApi()` URI construction (lines 51–54) | Replace lines 51–54 |
| 3 | Replace flat-list JSON parsing with nested `items`/`pagination` shape | `getSatwaApi()` success branch (lines 62–68) | Replace lines 62–68 |
| 4 | Add `_currentPage = 1;` to `_onSearchChanged` | Inside debounce callback (line 95) | Insert after line 95 |
| 5 | Add `_onPageChanged(int page)` method | After `_onSearchChanged` (after line 98) | New method |
| 6 | Wire `AppPagination` props | Build method (line 621) | Replace `const AppPagination()` |

### Files that need zero changes

- `lib/widget/app_pagination.dart` — already supports all needed props.
- `lib/widget/app_search_field.dart` — already wired correctly with `onChanged` + `controller`.
- `lib/config/api_config.dart` — base URL unchanged.

### Risk assessment

- **Low risk.** The pattern is battle-tested across 8 other pages. The `AppPagination` widget defaults mean that even if props are temporarily wrong, the UI degrades gracefully to the current static display.
- **Backend dependency:** The `items`/`pagination` nested shape must be confirmed against the actual `/api/v1/logistik/satwa` response. If the endpoint still returns a flat array, the reference fallback logic handles it (the `data is Map ? ... : (data is List ? data : [])` guard).
