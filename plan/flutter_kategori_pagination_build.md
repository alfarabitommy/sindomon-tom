# MasterKategoriSenjataPage — Pagination Build Report

**Status:** ✅ Implemented
**File modified:** `lib/pages/master_kategori_senjata.dart` (+59 / −11 lines)
**Reference pattern:** `lib/pages/polda.dart` (already wired)
**Verification:** `git diff` inspected; brace-balance check passed (all `{}` `()` `[]` matched). `flutter analyze` **could not run** — Flutter SDK is not installed in this environment. A built-in code review subagent audited the diff and approved it after one hardening fix (see §6).

---

## 1. Pagination State Variables — ADDED

After `_searchController` (was line 42):

```dart
/// Pagination metadata — sinkron dengan `{ items: [...], pagination: {...} }`
/// dari backend yang sudah direfactor.
int _currentPage = 1;
int _totalPages = 1;
int _totalItems = 0;
int _perPage = 10;
```

## 2. `getKategoriApi()` — URI Builder with `page` + `limit`

The conditional `search`-only replacement was replaced with a single params-map build:

```dart
Uri uri = Uri.parse("$apiBaseUrl/api/v1/master/kategori-senjata");
final Map<String, String> params = {
  "page": _currentPage.toString(),
  "limit": _perPage.toString(),
};
if (_searchQuery.isNotEmpty) {
  params["search"] = _searchQuery;
}
uri = uri.replace(queryParameters: params);
```

Resulting request: `GET /api/v1/master/kategori-senjata?page=1&limit=10[&search=...]`

## 3. `getKategoriApi()` — Nested JSON Parsing

Old: `jsonResponse["data"] ?? []` treated `data` as a flat list only.

New — dual-path with graceful fallback (mirrors `polda.dart`):

```dart
final dynamic data = jsonResponse["data"];
final List<dynamic> rawList = data is Map
    ? (data["items"] is List ? data["items"] as List : [])
    : (data is List ? data as List : []);
final Map<String, dynamic> pagination = data is Map &&
        data["pagination"] is Map
    ? data["pagination"] as Map<String, dynamic>
    : <String, dynamic>{};
```

Pagination metadata extracted with null-safe fallbacks:

```dart
_currentPage = (pagination["current_page"] as num?)?.toInt() ?? _currentPage;
_totalPages = (pagination["last_page"] as num?)?.toInt() ??
    (pagination["total_pages"] as num?)?.toInt() ?? 1;
_totalItems = (pagination["total"] as num?)?.toInt() ?? kategoriList.length;
_perPage = (pagination["per_page"] as num?)?.toInt() ??
    (pagination["limit"] as num?)?.toInt() ?? _perPage;
```

## 4. `_onSearchChanged` — Page Reset

```dart
void _onSearchChanged(String value) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 400), () {
    _searchQuery = value;
    // Reset ke halaman 1 supaya hasil pencarian mulai dari awal.
    _currentPage = 1;
    getKategoriApi();
  });
}
```

## 5. `_onPageChanged` — NEW Handler

```dart
void _onPageChanged(int page) {
  if (page < 1 || page > _totalPages || page == _currentPage) return;
  _currentPage = page;
  getKategoriApi();
}
```

Boundary guards prevent out-of-range requests and redundant refetches (clicking the current page).

## 6. `build()` — Dynamic `AppPagination`

`const AppPagination()` replaced with:

```dart
AppPagination(
  currentPage: _currentPage,
  totalPages: _totalPages,
  totalItems: _totalItems,
  perPage: _perPage,
  onPageChanged: _onPageChanged,
),
```

`const` keyword removed (no longer compile-time constant). The pagination strip is now live: correct "Menampilkan X hingga Y dari Z data" text, clickable page numbers, and disabled prev/next at boundaries.

## 7. Review-Driven Hardening (beyond spec)

Two fixes came out of the built-in code review subagent:

**(a) Eager list conversion.** `rawList.cast<Map<String, dynamic>>()` is **lazy** — a malformed item would throw inside `build()` (outside the `try`/`catch`), producing a red-screen crash instead of the error state. Fixed with eager conversion inside the `try` block:

```dart
kategoriList = rawList
    .map((e) => Map<String, dynamic>.from(e as Map))
    .toList();
```

Any invalid payload now lands in the existing `catch (e)` → `errorMessage` → `_buildErrorState()` path.

**(b) Stale-response guard (race protection).** With live search + clickable pagination, responses can arrive out of order (fast page clicks, rapid typing). Without a guard, an old response could overwrite newer data — or a stale error could clobber a valid view. `getKategoriApi()` now snapshots the request before the HTTP call and drops any response whose page/query no longer matches the current state:

```dart
final int requestedPage = _currentPage;
final String requestedQuery = _searchQuery;

final response = await http.get(uri, headers: {"Authorization": token});

// Respons basi dibuang di semua jalur (200 maupun error) supaya tidak
// menimpa UI dengan data/error dari permintaan yang sudah usang.
if (!mounted || requestedPage != _currentPage ||
    requestedQuery != _searchQuery) {
  return;
}
```

The guard sits **above** the `statusCode` branch so it also drops stale non-200/error responses. It cannot strand `isLoading`: the only mutators of `_currentPage`/`_searchQuery` (`_onSearchChanged`, `_onPageChanged`) always fire a fresh `getKategoriApi()` which settles the spinner on every terminal path (200 / non-200 / catch).

## 8. Unchanged / Verified

| Concern | Status |
|---|---|
| `dart:async` import (Timer) | ✅ Already present (line 1), no change needed |
| `_debounce` / `_searchController` / `dispose()` cleanup | ✅ Already present |
| CRUD `getKategoriApi()` re-calls after add/edit/delete | ✅ Keep as-is; `_currentPage` already holds the correct page |
| Other files touched | Only `lib/pages/master_kategori_senjata.dart`. (`polres.dart` diff in working tree is pre-existing parallel work, untouched) |

## 9. Verification Status

| Check | Result |
|---|---|
| `git diff` review of full change | ✅ Matches mission spec exactly |
| Brace/paren balance (`{}` `()` `[]`) | ✅ 71/71, 346/346, 41/41 |
| `flutter analyze` | ⚠️ Not run — Flutter SDK unavailable in this environment |
| Built-in code review subagent | ✅ Approved; 1 hardening fix applied (§7) |

**Recommended follow-up on a machine with the Flutter SDK:**

```bash
flutter analyze lib/pages/master_kategori_senjata.dart
```

## 10. Runtime Behavior (expected)

1. **First load:** `?page=1&limit=10` → nested payload parsed → table shows items, strip shows "Menampilkan 1 hingga 10 dari N data".
2. **Type in search:** 400ms debounce → `_currentPage` resets to 1 → `&search=...` appended.
3. **Click page 2:** `_onPageChanged(2)` → guard passes → `?page=2&limit=10` (search preserved) → table + strip update.
4. **Click prev on page 1 / next on last page:** guard blocks, no request fired.
5. **Legacy flat-list API response:** still renders (fallback path), pagination defaults to page 1 / all items.
