# MasterKategoriSenjataPage — Search & Pagination Audit

**Generated:** $(date)
**File under audit:** `lib/pages/master_kategori_senjata.dart`
**Reference implementation:** `lib/pages/polda.dart` (already wired)

---

## 1. Search / Debounce — SURPRISINGLY ALREADY WIRED

Contrary to the initial hypothesis, the search mechanism is **already fully in place**:

| Concern | Status | Detail |
|---|---|---|
| `_searchQuery` field | ✅ Present | Line 40 |
| `_debounce` Timer | ✅ Present | Line 41 |
| `_searchController` | ✅ Present | Line 42 |
| `_onSearchChanged()` handler | ✅ Present | Lines 105–111 (400ms debounce, sets `_searchQuery`, calls `getKategoriApi()`) |
| `AppSearchField` receives `controller` | ✅ Wired | Line 489: `controller: _searchController` |
| `AppSearchField` receives `onChanged` | ✅ Wired | Line 490: `onChanged: _onSearchChanged` |
| `dispose()` cleans up both | ✅ Present | Lines 100–101 |
| `getKategoriApi()` appends `search` query param | ✅ Present | Lines 59–61: `uri.replace(queryParameters: {"search": _searchQuery})` |

**Verdict:** Search/debounce needs **zero changes**. The only gap is that search doesn't reset pagination to page 1 — but pagination doesn't exist yet, so this is moot.

---

## 2. Pagination State Variables — MISSING

The following four state variables are **absent** from `_MasterKategoriSenjataPageState`:

| Variable | Type | Default | Needed for |
|---|---|---|---|
| `_currentPage` | `int` | `1` | Tracking which page is loaded; sent as `page` query param |
| `_totalPages` | `int` | `1` | Disabling prev/next buttons at boundaries; sent to `AppPagination` |
| `_totalItems` | `int` | `0` | Display text "Menampilkan X hingga Y dari Z data" |
| `_perPage` | `int` | `10` | Sent as `limit` query param |

These should be declared immediately after `_searchController` on line 42.

---

## 3. API Query Parameters — MISSING `page` & `limit`

### Current code (lines 53–66):

```dart
Future<void> getKategoriApi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";

      Uri uri = Uri.parse("$apiBaseUrl/api/v1/master/kategori-senjata");
      if (_searchQuery.isNotEmpty) {
        uri = uri.replace(queryParameters: {"search": _searchQuery});
      }
      ...
```

### What's missing:

The `page` and `limit` parameters are never appended. The `polda.dart` reference (lines 58–65) builds a `Map<String, String> params` with all three keys and replaces `queryParameters` once:

```dart
final Map<String, String> params = {
    "page": _currentPage.toString(),
    "limit": _perPage.toString(),
};
if (_searchQuery.isNotEmpty) {
    params["search"] = _searchQuery;
}
uri = uri.replace(queryParameters: params);
```

### Integration point:

Replace the conditional `if (_searchQuery.isNotEmpty)` block in `getKategoriApi()` (lines 58–61) with the map-builder pattern above.

---

## 4. JSON Response Parsing — NEEDS NESTED STRUCTURE HANDLING

### Current code (lines 68–75):

```dart
if (response.statusCode == 200) {
    final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
    final List<dynamic> rawData = jsonResponse["data"] ?? [];
    setState(() {
        kategoriList = rawData.cast<Map<String, dynamic>>();
        errorMessage = "";
        isLoading = false;
    });
}
```

This assumes `jsonResponse["data"]` is a flat `List`. The new backend returns:

```json
{
  "data": {
    "items": [ ... ],
    "pagination": {
      "current_page": 1,
      "last_page": 3,
      "total": 25,
      "per_page": 10
    }
  }
}
```

### Reference pattern (polda.dart lines 74–104):

```dart
final List rawList = data is Map
    ? (data["items"] is List ? data["items"] as List : [])
    : (data is List ? data as List : []);
final Map<String, dynamic> pagination = data is Map &&
        data["pagination"] is Map
    ? data["pagination"] as Map<String, dynamic>
    : <String, dynamic>{};
```

Then extracts pagination fields with null-safe fallbacks:

```dart
_currentPage = (pagination["current_page"] as num?)?.toInt() ?? _currentPage;
_totalPages = (pagination["last_page"] as num?)?.toInt() ??
    (pagination["total_pages"] as num?)?.toInt() ?? 1;
_totalItems = (pagination["total"] as num?)?.toInt() ?? parsed.length;
_perPage = (pagination["per_page"] as num?)?.toInt() ??
    (pagination["limit"] as num?)?.toInt() ?? _perPage;
```

### Integration point:

Replace the two-line parsing block at lines 69–73 with the dual-path (`Map`/`List`) extraction and pagination-field extraction.

**Note:** `master_kategori_senjata.dart` uses raw `Map<String, dynamic>` (not a model class like `Polda`), so the list conversion stays as `rawList.cast<Map<String, dynamic>>()` — no model deserialization needed.

---

## 5. `_onSearchChanged` — NEEDS PAGE-1 RESET

### Current code (lines 105–111):

```dart
void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchQuery = value;
      getKategoriApi();
    });
}
```

### What's missing:

When the user types a new search, the page should reset to 1:

```dart
_searchQuery = value;
_currentPage = 1;  // <-- add this
getKategoriApi();
```

---

## 6. `_onPageChanged` Handler — MISSING ENTIRELY

There is no page-change handler. Reference from `polda.dart` (lines 141–145):

```dart
void _onPageChanged(int page) {
    if (page < 1 || page > _totalPages || page == _currentPage) return;
    _currentPage = page;
    getKategoriApi();
}
```

### Integration point:

Add this method anywhere after `_onSearchChanged` (e.g., after line 111).

---

## 7. `AppPagination` Widget Usage — STATIC

### Current code (line 713):

```dart
const AppPagination(),
```

This renders the hardcoded defaults: "Menampilkan 1 hingga 10 dari 50 data", page 1 active, no click handlers.

### What it should be:

```dart
AppPagination(
    currentPage: _currentPage,
    totalPages: _totalPages,
    totalItems: _totalItems,
    perPage: _perPage,
    onPageChanged: _onPageChanged,
),
```

**Note:** Drop the `const` keyword since the widget is no longer compile-time constant.

---

## 8. `_onSearchChanged` after CRUD operations

When a kategori is added, edited, or deleted, `getKategoriApi()` is called directly (lines 335, 378). These calls currently don't reset pagination, but since `_currentPage` will default to 1 and won't change unless the user paginates, this should be safe. **No change needed here**, but verify after wiring that a delete on page 2 correctly refetches and shows the (possibly now-empty) page.

---

## 9. Summary of Required Changes

| # | Location | Change | Risk |
|---|---|---|---|
| 1 | After line 42 | Add `_currentPage`, `_totalPages`, `_totalItems`, `_perPage` state vars | Low |
| 2 | Lines 58–61 | Replace conditional search-param block with map-builder including `page` + `limit` | Low |
| 3 | Lines 69–75 | Replace flat-list parsing with `Map`/`List` dual-path + pagination extraction | Medium (must handle legacy flat API) |
| 4 | Line 108 | Add `_currentPage = 1;` inside `_onSearchChanged` debounce callback | Low |
| 5 | After line 111 | Add `_onPageChanged(int page)` method | Low |
| 6 | Line 713 | Replace `const AppPagination()` with dynamic props | Low |

**Total: 6 targeted edits in ~6 locations.** No widget signature changes, no new imports, no breaking changes to the build tree.

---

## 10. Widget Contracts (for reference)

### `AppPagination` (already supports dynamic props)

```dart
// lib/widget/app_pagination.dart
const AppPagination({
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems = 50,
    this.perPage = 10,
    this.onPageChanged,
});
```

All defaults preserve backward compatibility — existing `const AppPagination()` calls continue to compile. The widget already handles zero-items ("Menampilkan 0 data"), boundary disable for prev/next, and windowed page-number display.

### `AppSearchField` (already supports controller + onChanged)

```dart
// lib/widget/app_search_field.dart
const AppSearchField({
    required this.hintText,
    this.onChanged,
    this.controller,
});
```

Both props are already wired — no change needed.
