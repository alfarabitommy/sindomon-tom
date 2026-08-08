# Flutter Ammunition Stock — Search & Pagination Audit

**Date:** 2025-07-18  
**File audited:** `lib/pages/amunisi.dart`  
**Reference implementation:** `lib/pages/personel.dart` (fully paginated sibling)  
**Widgets audited:** `lib/widget/app_search_field.dart`, `lib/widget/app_pagination.dart`

---

## 1. Summary

`amunisi.dart` is **halfway wired** for search but completely **missing pagination**. The `AppSearchField` and debounce timer are already in place and functional. `AppPagination` is rendered as a hardcoded static widget. The API fetch does not send `page`/`limit` query parameters and the response parsing only handles the legacy flat-array shape — it cannot process the newer `{ items: [...], pagination: {...} }` envelope that the backend now returns.

---

## 2. State Variable Inventory

### ✅ Already present

| Variable | Line | Purpose |
|----------|------|---------|
| `_searchQuery` | 31 | Holds the current search term (empty = no filter) |
| `_debounce` | 32 | `Timer?` — cancels/re-triggers on each keystroke, fires after 400 ms idle |
| `_searchController` | 33 | `TextEditingController` — bound to `AppSearchField` |

### ❌ Missing (must be added)

| Variable | Default | Purpose |
|----------|---------|---------|
| `_currentPage` | `1` | Tracks the currently displayed page |
| `_totalPages` | `1` | Derived from `pagination.last_page` (or `total_pages`) in the API response |
| `_totalItems` | `0` | Derived from `pagination.total` — drives the "Menampilkan X hingga Y dari Z data" label |
| `_perPage` | `10` | Items per page sent to the backend (`limit` query param) |

**Insertion point:** Right after line 33 (`final TextEditingController _searchController = …`), matching the layout of every other paginated page (personel, senjata, polda, polres, user_page, master_kategori_senjata).

---

## 3. API Fetch — `getAmunisiApi()` (lines 44–78)

### 3.1 Current behavior

```dart
// Lines 49–52 — only "search" is appended
Uri uri = Uri.parse("$apiBaseUrl/api/v1/logistik/amunisi");
if (_searchQuery.isNotEmpty) {
  uri = uri.replace(queryParameters: {"search": _searchQuery});
}
```

**Problem:** No `page` or `limit` parameters are sent. The backend receives an unbounded request and returns **all** records (or a server-side default page, which the client cannot control).

### 3.2 Required change

Adopt the pattern from `personel.dart` lines 57–64:

```dart
Uri uri = Uri.parse("$apiBaseUrl/api/v1/logistik/amunisi");
final Map<String, String> params = {
  "page": _currentPage.toString(),
  "limit": _perPage.toString(),
};
if (_searchQuery.isNotEmpty) {
  params["search"] = _searchQuery;
}
uri = uri.replace(queryParameters: params);
```

### 3.3 Response parsing — current behavior (lines 59–65)

```dart
final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
final List<dynamic> rawData = jsonResponse["data"] ?? [];
setState(() {
  amunisiApi = rawData.cast<Map<String, dynamic>>();
  isLoading = false;
});
```

**Problem:** This assumes `jsonResponse["data"]` is a flat `List`. The backend now wraps results in:
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

The current code would cast `data` (a `Map`) to `List` → `rawData` becomes `[]` → the table renders empty.

### 3.4 Required change

Adopt the dual-shape tolerant parsing from `personel.dart` lines 72–107:

```dart
final json = jsonDecode(response.body);
final data = json["data"];

// Tolerate both shapes
final List rawList = data is Map
    ? (data["items"] is List ? data["items"] : [])
    : (data is List ? data : []);

final Map<String, dynamic> pagination = data is Map &&
        data["pagination"] is Map
    ? data["pagination"] as Map<String, dynamic>
    : <String, dynamic>{};

final parsedItems =
    rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();

setState(() {
  amunisiApi = parsedItems;
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

---

## 4. Search Wiring — `_onSearchChanged()` (lines 87–93)

### 4.1 Current behavior

```dart
void _onSearchChanged(String value) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 400), () {
    _searchQuery = value;
    getAmunisiApi();
  });
}
```

This is functionally correct for debounce, but **missing a page-1 reset**. When the user types a new search term, the pagination state is stale — the request should always start at page 1.

### 4.2 Required change (add one line)

```dart
void _onSearchChanged(String value) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 400), () {
    _searchQuery = value;
    _currentPage = 1;       // ← ADD THIS
    getAmunisiApi();
  });
}
```

Matches `personel.dart` line 181.

---

## 5. Pagination Handler — Missing Entirely

A new method must be added (same pattern as every other paginated page):

```dart
void _onPageChanged(int page) {
  if (page < 1 || page > _totalPages || page == _currentPage) return;
  _currentPage = page;
  getAmunisiApi();
}
```

**Insertion point:** After `_onSearchChanged` (around line 93), before `_formatKaliber`.

---

## 6. `AppPagination` Widget Wiring (line 514)

### 6.1 Current usage

```dart
const AppPagination(),
```

All props default to hardcoded values: `currentPage=1`, `totalPages=1`, `totalItems=50`, `perPage=10`, `onPageChanged=null`. The widget renders a static label "Menampilkan 1 hingga 10 dari 50 data" and the pagination buttons are never clickable.

### 6.2 Required change

```dart
AppPagination(
  currentPage: _currentPage,
  totalPages: _totalPages,
  totalItems: _totalItems,
  perPage: _perPage,
  onPageChanged: _onPageChanged,
),
```

Matches `personel.dart` lines 613–617 and every other paginated page.

---

## 7. `AppPagination` Widget — Already Ready

`lib/widget/app_pagination.dart` was already refactored to accept optional `currentPage`, `totalPages`, `totalItems`, `perPage`, and `onPageChanged` props. All have sensible defaults so `const AppPagination()` still compiles. The widget:

- Computes `start`/`end` display range from props (line 46–51)
- Builds a windowed page-number strip with ellipsis gaps (lines 28–42)
- Calls `onPageChanged` on prev/next/number taps when provided

**No changes needed** in this widget.

---

## 8. `AppSearchField` Widget — Already Ready

`lib/widget/app_search_field.dart` accepts optional `controller` and `onChanged` callbacks. `amunisi.dart` already passes both correctly (lines 259–261). **No changes needed.**

---

## 9. Integration Checklist (Implementation Plan)

| # | Change | File | Lines affected |
|---|--------|------|----------------|
| 1 | Add `_currentPage`, `_totalPages`, `_totalItems`, `_perPage` state vars | `amunisi.dart` | After line 33 |
| 2 | Rewrite `getAmunisiApi()` — send `page`+`limit` params, parse `items`/`pagination` envelope | `amunisi.dart` | Lines 49–65 |
| 3 | Add `_currentPage = 1` reset inside `_onSearchChanged` debounce callback | `amunisi.dart` | Line 90 |
| 4 | Add `_onPageChanged(int page)` method | `amunisi.dart` | After `_onSearchChanged` |
| 5 | Replace `const AppPagination()` with fully-wired dynamic props | `amunisi.dart` | Line 514 |

### Optional improvements (not required for core functionality)

| # | Change | Rationale |
|---|--------|-----------|
| A | Add a `!mounted` guard after `await` in `getAmunisiApi()` before `setState` | Prevents setState-on-disposed leak (present in personel.dart, missing here) |
| B | Add `requestedPage` race-condition guard (as in `master_kategori_senjata.dart` line 78) | Prevents stale responses from fast page-hopping from overwriting newer results |
| C | Add `errorMessage` state variable and display it in the UI | Currently errors are silently swallowed (only `debugPrint`) |

---

## 10. API Contract Assumptions

Based on sibling pages that already consume the paginated backend, the amunisi endpoint is expected to respond with:

```json
GET /api/v1/logistik/amunisi?page=1&limit=10&search=optional

{
  "data": {
    "items": [
      {
        "batch_id": "...",
        "kode_batch": "...",
        "kategori": { "tipe_laras": "...", "kaliber": "..." },
        "jumlah_butir": 1000,
        "tanggal_masuk": "2025-01-15",
        "tanggal_kedaluwarsa": "2026-01-15",
        "is_h90_alert": false
      }
    ],
    "pagination": {
      "current_page": 1,
      "last_page": 5,
      "per_page": 10,
      "total": 47
    }
  }
}
```

The dual-shape parsing (Section 3.4) gracefully tolerates the legacy flat-list response if the backend hasn't been updated yet.

---

## 11. Key Field Observations

| Field | Used in table | Used in delete | Notes |
|-------|---------------|----------------|-------|
| `batch_id` | No | Yes (line 489) | Used as the REST path param for DELETE |
| `kode_batch` | Yes (column 1) | No | Monospace-styled batch code |
| `kategori` | Yes (column 2) | No | Nested object → formatted via `_formatKaliber()` |
| `jumlah_butir` | Yes (column 3) | No | Formatted via `_formatJumlah()` with thousand-separator |
| `tanggal_masuk` | Yes (column 4) | No | — |
| `tanggal_kedaluwarsa` | Yes (column 5) | No | — |
| `is_h90_alert` | Yes (column 6) | No | Drives `_buildStatusBadge()` — red "H-90 ALERT" or green "AMAN" |

No fields used by the table or delete flow would change with pagination — the data shape per item is unchanged.

---

## 12. Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Breaking existing flat-array API if backend not yet updated | Low | The dual-shape parser tolerates both old and new response shapes |
| `setState` after widget disposed | Low | Add `if (!mounted) return;` guard (optional item A above) |
| Stale response from rapid page-hopping | Low | Optional race-condition guard (item B) — not critical for MVP |
| Search + pagination interaction (page out of range after filter) | Low | Server should return an empty page; `_totalPages` will reflect 1 → pagination strip self-corrects |
