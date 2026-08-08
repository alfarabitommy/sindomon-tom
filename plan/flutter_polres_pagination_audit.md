# PolresPage — Search & Pagination Audit

**Date:** 2025-01-17  
**Auditor:** Reasonix (read-only investigation)  
**Reference implementation:** `lib/pages/polda.dart` (fully wired)

---

## 1. Current State Summary

### 1.1 State variables (`_PolresPageState`, lines 22–28)

| Variable | Type | Present? |
|----------|------|----------|
| `polres` | `List<Map<String, dynamic>>` | ✅ |
| `errorMessage` | `String` | ✅ |
| `isLoading` | `bool` | ✅ |
| `unLogin` | `String` | ✅ |
| `roleLabel` | `String` | ✅ |
| `_searchQuery` | `String` | ❌ **MISSING** |
| `_debounce` | `Timer?` | ❌ **MISSING** |
| `_searchController` | `TextEditingController` | ❌ **MISSING** |
| `_currentPage` | `int` | ❌ **MISSING** |
| `_totalPages` | `int` | ❌ **MISSING** |
| `_totalItems` | `int` | ❌ **MISSING** |
| `_perPage` | `int` | ❌ **MISSING** |

**Seven pagination/search variables must be added above `loadUser()`.**

### 1.2 Lifecycle methods

| Method | Present? | Notes |
|--------|----------|-------|
| `initState()` | ✅ | Calls `loadUser()` + `getPolresApi()` — no change needed |
| `dispose()` | ❌ **MISSING** | Must be added to cancel `_debounce` + dispose `_searchController` |
| `_onSearchChanged` | ❌ **MISSING** | Must be added (400 ms debounce, reset to page 1) |
| `_onPageChanged` | ❌ **MISSING** | Must be added (bounds check, then re-fetch) |

### 1.3 `getPolresApi()` (lines 38–68)

**Current behavior:**

```dart
final response = await http.get(
  Uri.parse("$apiBaseUrl/api/v1/master/polres"),   // ← bare URL, no query params
  headers: {"Authorization": token.toString()},
);
```

| Aspect | Current | Required |
|--------|---------|----------|
| Query parameters | **None** | `?page=1&limit=10&search=…` |
| Response parsing | Flat list: `json["data"]` as `List` | Paginated: `data["items"]` list + `data["pagination"]` map, with flat-list fallback |
| Pagination state set | N/A | Set `_currentPage`, `_totalPages`, `_totalItems`, `_perPage` from `pagination` map |
| Error handling | Bare try/catch | Adequate — no change |

### 1.4 Build method (lines 120–489)

**Search field (line 267):**

```dart
AppSearchField(hintText: "Cari Polres..."),
//                        ^^^^^^^^^^^^^^^^
// MISSING: controller: _searchController,
// MISSING: onChanged: _onSearchChanged,
```

The `AppSearchField` widget already accepts optional `controller` and `onChanged` params (see `lib/widget/app_search_field.dart:3-13`). They are simply not passed.

**Pagination footer (line 471):**

```dart
const AppPagination(),
//    ^^^^^^^^^^^^^^^
// MISSING: currentPage, totalPages, totalItems, perPage, onPageChanged
```

The `AppPagination` widget already accepts all these props with sensible defaults (`lib/widget/app_pagination.dart:10-24`). Using `const AppPagination()` renders the static fallback: *"Menampilkan 1 hingga 10 dari 50 data"* with page 1 active.

### 1.5 Add/Edit navigation (line 234–243)

```dart
Navigator.push(…).then((result) {
  if (result == true) {
    getPolresApi();  // ← refreshes the full list after add/edit
  }
});
```

After wiring pagination, the refresh here should reset to page 1 (or keep the current page — but that's a design decision). The simplest and safest approach: **reset to page 1** so newly-added items appear at the top.

### 1.6 Delete (line 97)

```dart
getPolresApi(); // refresh list
```

Same consideration as add/edit. After wiring pagination, consider whether to stay on the current page (may show an empty page if the last item was deleted) or go to page 1. The `polda.dart` reference simply re-fetches the current page.

---

## 2. Integration Reference: `polda.dart` (the gold standard)

### 2.1 State block (polda.dart lines 35–41)

```dart
String _searchQuery = "";
Timer? _debounce;
final TextEditingController _searchController = TextEditingController();
int _currentPage = 1;
int _totalPages = 1;
int _totalItems = 0;
int _perPage = 10;
```

### 2.2 API call with params (polda.dart lines 57–65)

```dart
Uri uri = Uri.parse("$apiBaseUrl/api/v1/master/polda");
final Map<String, String> params = {
  "page": _currentPage.toString(),
  "limit": _perPage.toString(),
};
if (_searchQuery.isNotEmpty) {
  params["search"] = _searchQuery;
}
uri = uri.replace(queryParameters: params);
```

### 2.3 Paginated response parsing (polda.dart lines 74–103)

```dart
final List rawList = data is Map
    ? (data["items"] is List ? data["items"] as List : [])
    : (data is List ? data as List : []);
final Map<String, dynamic> pagination = data is Map &&
        data["pagination"] is Map
    ? data["pagination"] as Map<String, dynamic>
    : <String, dynamic>{};

setState(() {
  polda = parsed;
  _currentPage = (pagination["current_page"] as num?)?.toInt() ?? _currentPage;
  _totalPages = (pagination["last_page"] as num?)?.toInt()
      ?? (pagination["total_pages"] as num?)?.toInt() ?? 1;
  _totalItems = (pagination["total"] as num?)?.toInt() ?? parsed.length;
  _perPage = (pagination["per_page"] as num?)?.toInt()
      ?? (pagination["limit"] as num?)?.toInt() ?? _perPage;
  errorMessage = "";
  isLoading = false;
});
```

**Key detail:** This parser tolerates three shapes:
1. `{ data: { items: [...], pagination: {...} } }` — new paginated API
2. `{ data: [...] }` — legacy flat list (fallback)
3. `data["pagination"]` keys: `current_page`, `last_page` (or `total_pages`), `total`, `per_page` (or `limit`)

### 2.4 Debounced search (polda.dart lines 132–138)

```dart
void _onSearchChanged(String value) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 400), () {
    _searchQuery = value;
    _currentPage = 1;
    getPoldaApi();
  });
}
```

### 2.5 Page change handler (polda.dart lines 141–145)

```dart
void _onPageChanged(int page) {
  if (page < 1 || page > _totalPages || page == _currentPage) return;
  _currentPage = page;
  getPoldaApi();
}
```

### 2.6 Dispose (polda.dart lines 147–152)

```dart
@override
void dispose() {
  _debounce?.cancel();
  _searchController.dispose();
  super.dispose();
}
```

### 2.7 Widget wiring (polda.dart lines 344–348, 553–557)

```dart
// Search field
AppSearchField(
  hintText: "Cari Polda...",
  controller: _searchController,
  onChanged: _onSearchChanged,
),

// Pagination
AppPagination(
  currentPage: _currentPage,
  totalPages: _totalPages,
  totalItems: _totalItems,
  perPage: _perPage,
  onPageChanged: _onPageChanged,
),
```

---

## 3. Integration Points Checklist

Ten discrete injection points, numbered for implementation order:

| # | File:line | What to inject | Injected code reference |
|---|-----------|----------------|-------------------------|
| 1 | `polres.dart:23` | Add `import 'dart:async';` for `Timer` | — |
| 2 | `polres.dart:24-26` | Add 7 state variables (`_searchQuery`, `_debounce`, `_searchController`, `_currentPage`, `_totalPages`, `_totalItems`, `_perPage`) | polda.dart:35-41 |
| 3 | `polres.dart:38-68` | Rewrite `getPolresApi()` to append query params (`page`, `limit`, `search`) and parse paginated response shape | polda.dart:57-107 |
| 4 | `polres.dart:72-74` | (No change needed) `initState()` already calls `getPolresApi()` | — |
| 5 | `polres.dart:74` | Add `_onSearchChanged` method after `initState` | polda.dart:132-138 |
| 6 | `polres.dart:74` | Add `_onPageChanged` method after `_onSearchChanged` | polda.dart:141-145 |
| 7 | `polres.dart:74` | Add `dispose()` override to clean up timer + controller | polda.dart:147-152 |
| 8 | `polres.dart:267` | Pass `controller:` and `onChanged:` to `AppSearchField` | polda.dart:344-348 |
| 9 | `polres.dart:471` | Replace `const AppPagination()` with dynamic props | polda.dart:553-557 |
| 10 | `polres.dart:77-117` | (Optional) In `deletePolres()`, after successful delete, consider resetting to page 1 if the current page becomes empty | — |

---

## 4. Risk & Compatibility Notes

1. **API shape tolerance:** We must parse the API response with the same dual-shape logic as `polda.dart` (lines 74-103). The endpoint at `GET /api/v1/master/polres` may return paginated or flat data depending on whether query params are sent. The robust parser handles both.

2. **`dart:async` import:** The file currently imports `dart:convert` (line 6) but not `dart:async`. `Timer` requires it.

3. **Existing `polres` list type:** Currently `List<Map<String, dynamic>>`. Polda uses a model class (`Polda.fromJson`). Polres uses raw maps — the parsing adaptation in `getPolresApi()` must map from the paginated `rawList` into `List<Map<String, dynamic>>` without a model class, i.e. keep the existing `List<Map<String, dynamic>>.from(rawList)`. No model class needed.

4. **`const` keyword:** Line 471 `const AppPagination()` will become `AppPagination(currentPage: …, …)` — the `const` must be removed since props are now runtime values.

5. **DataTable rows (lines 341-462):** No changes needed. The `polres` list is still iterated with `.map()`. Pagination happens server-side, so the list always contains only the current page's items.

6. **Add/edit refresh (line 240-243):** Currently calls `getPolresApi()` which will re-fetch with the current `_currentPage`. After adding a new item, the user should see it — consider explicitly setting `_currentPage = 1;` before `getPolresApi()` in the `.then()` callback, or leave it as-is (Polda's reference keeps the current page).

7. **`import` for Timer:** The `Timer` class requires `import 'dart:async';` — this is missing from the current import block.

---

## 5. Other Pages Needing the Same Treatment

Grep analysis confirms these pages have **search wired but NO pagination** (they use `const AppPagination()` statically):

| Page | File | Search | Pagination |
|------|------|--------|------------|
| Amunisi | `amunisi.dart` | ✅ debounced | ❌ static |
| Sarpras (inventaris) | `sarpras.dart` | ✅ debounced | ❌ static |
| Satwa K-9 | `satwa.dart` | ✅ debounced | ❌ static |
| Senjata | `senjata.dart` | ✅ debounced | ❌ static |
| Master Kategori | `master_kategori_senjata.dart` | ✅ debounced | ❌ static |
| **Polres** | **`polres.dart`** | ❌ **neither** | ❌ **static** |
| Personel | `personel.dart` | ❓ unknown | ❓ unknown |
| Polda | `polda.dart` | ✅ ✅ | ✅ ✅ (reference) |

**Polres is the worst of both worlds** — no search AND no pagination. This audit addresses both simultaneously, using `polda.dart` as the template.
