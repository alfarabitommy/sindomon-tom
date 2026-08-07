# Flutter Polda Pagination & Search — Build Report

**Build date:** 2026-01-18  
**Files changed:**
- `lib/widget/app_pagination.dart` — refactored to a dynamic, backward-compatible widget
- `lib/pages/polda.dart` — debounced search + server-side pagination wired to new API shape

**Artifact companion:** `plan/flutter_polda_pagination_audit.md` (pre-change audit)

---

## 1. `AppPagination` Refactor (`lib/widget/app_pagination.dart`)

### 1.1 New API (all optional — backward compatible)

```dart
const AppPagination({
  super.key,
  this.currentPage = 1,
  this.totalPages = 1,
  this.totalItems = 50,
  this.perPage = 10,
  this.onPageChanged,
});
```

| Prop | Type | Default | Purpose |
|------|------|---------|---------|
| `currentPage` | `int` | `1` | Active page (drives amber highlight + range text) |
| `totalPages` | `int` | `1` | Number of page buttons rendered |
| `totalItems` | `int` | `50` | Total record count (drives "dari X data") |
| `perPage` | `int` | `10` | Page size (drives "X hingga Y") |
| `onPageChanged` | `ValueChanged<int>?` | `null` | Callback fired on Prev/Next/page-number taps |

### 1.2 Dynamic UI behavior

- **Range text** is computed, not hardcoded:
  ```dart
  final int start = totalItems == 0 ? 0 : (currentPage - 1) * perPage + 1;
  final int end = totalItems == 0
      ? 0
      : (currentPage * perPage < totalItems) ? currentPage * perPage : totalItems;
  // → "Menampilkan 1 hingga 10 dari 50 data" (start, end, totalItems)
  // → "Menampilkan 0 data" when the result set is empty
  ```
- **Page numbers** are generated from `totalPages` via `_visiblePages`:
  - ≤ 7 pages → all pages rendered `[1][2][3]…`
  - > 7 pages → windowed: first, last, current ± 1, gaps collapsed to `…` (e.g. `1 … 4 [5] 6 … 20`)
- **Tap targets**: every button is wrapped in `InkWell`. When `onPageChanged` is provided:
  - `<` → `onPageChanged(currentPage - 1)` (disabled on page 1)
  - `>` → `onPageChanged(currentPage + 1)` (disabled on last page)
  - page `N` → `onPageChanged(N)` (disabled for the active page)
  When `onPageChanged` is `null`, all buttons render statically (disabled), preserving pre-refactor behavior.

### 1.3 Backward-compatibility proof

| Check | Evidence |
|-------|----------|
| Still `const`-constructible | Constructor remains `const`; all fields `final`. |
| Zero-arg call sites compile | All 5 new params are optional named with defaults — `const AppPagination()` is still valid. |
| No call site was touched | `grep "AppPagination(" lib` shows 10 non-Polda call sites (amunisi, inventaris, master_kategori_senjata, personel, polres, report, sarpras, satwa, senjata, user_page) all still `const AppPagination()`. |
| Old visuals preserved under defaults | `totalItems = 50`, `perPage = 10`, `currentPage = 1` → text renders byte-identical `"Menampilkan 1 hingga 10 dari 50 data"`; `totalPages = 1` renders a single active `[1]` button. |
| Old interactivity preserved | `onPageChanged = null` → every `InkWell` gets `onTap: null` (disabled), same as the old plain `Container` buttons. |

---

## 2. `PoldaPage` Refactor (`lib/pages/polda.dart`)

### 2.1 New state (`_PoldaPageState`)

```dart
String _searchQuery = "";
Timer? _debounce;
final TextEditingController _searchController = TextEditingController();
int _currentPage = 1;
int _totalPages = 1;
int _totalItems = 0;
int _perPage = 10;
```

Plus `import 'dart:async';` for `Timer`.

### 2.2 Debounced search

```dart
void _onSearchChanged(String value) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 400), () {
    _searchQuery = value;
    _currentPage = 1;          // new search always restarts at page 1
    getPoldaApi();
  });
}
```

- Rapid typing cancels the pending timer; the API fires only after 400 ms of idle input.
- Wired into the UI: `AppSearchField(controller: _searchController, onChanged: _onSearchChanged)`.

### 2.3 Page navigation

```dart
void _onPageChanged(int page) {
  if (page < 1 || page > _totalPages || page == _currentPage) return;
  _currentPage = page;
  getPoldaApi();
}
```

Wired into the UI:
```dart
AppPagination(
  currentPage: _currentPage,
  totalPages: _totalPages,
  totalItems: _totalItems,
  perPage: _perPage,
  onPageChanged: _onPageChanged,
),
```

### 2.4 API call with query params + new response parsing

**Request** — `GET {apiBaseUrl}/api/v1/polda` now carries:
```
?page=1&limit=10          (always)
&search=jawa              (only when _searchQuery is non-empty)
```
Built via `uri.replace(queryParameters: params)` so encoding is handled by the SDK (no hand-built `?`/`&` strings).

**Response parsing** — new backend shape:
```json
{
  "data": {
    "items": [ { "id": 1, "nama_polda": "...", ... } ],
    "pagination": {
      "current_page": 1, "last_page": 5, "per_page": 10, "total": 50
    }
  }
}
```

```dart
final data = json["data"];
final List rawList = data is Map
    ? (data["items"] is List ? data["items"] as List : [])
    : (data is List ? data as List : []);
final Map<String, dynamic> pagination = data is Map && data["pagination"] is Map
    ? data["pagination"] as Map<String, dynamic>
    : <String, dynamic>{};
// ...
setState(() {
  polda = parsed;
  _currentPage = (pagination["current_page"] as num?)?.toInt() ?? _currentPage;
  _totalPages = (pagination["last_page"] as num?)?.toInt() ??
      (pagination["total_pages"] as num?)?.toInt() ?? 1;
  _totalItems = (pagination["total"] as num?)?.toInt() ?? parsed.length;
  _perPage = (pagination["per_page"] as num?)?.toInt() ??
      (pagination["limit"] as num?)?.toInt() ?? _perPage;
  ...
});
```

Defensive notes:
- `as num?` accepts int or double from JSON; `toInt()` normalizes.
- Field-name fallbacks: `last_page` → `total_pages`; `per_page` → `limit`.
- Legacy flat-list `data: [...]` responses still parse (items fallback), and a missing `pagination` object leaves pagination state untouched instead of crashing.

### 2.5 Cleanup

```dart
@override
void dispose() {
  _debounce?.cancel();
  _searchController.dispose();
  super.dispose();
}
```

---

## 3. Verification

| Item | Result |
|------|--------|
| Code changes applied | ✅ Both files modified; `git diff` reviewed line-by-line |
| `const AppPagination()` sites intact | ✅ 10/10 non-Polda call sites unchanged |
| `flutter analyze` | ⚠️ **Could not run** — no Flutter/Dart SDK in this sandbox (`flutter: command not found`). Manual review found no syntax/type errors: all symbols used, no stale references, valid ternary/collection-for/spread syntax. **Run `flutter analyze` locally or in CI before merging.** |
| Runtime smoke test | ⚠️ Not performed (no emulator/toolchain). First manual test: type in "Cari Polda..." → wait 400 ms → table refreshes; click `>` → page 2 loads; range text updates. |

---

## 4. What was NOT changed (intentional scope)

- The other 10 pages still render the static pagination strip — they can adopt the new props page-by-page later.
- `deletePolda()` and the Add/Edit flows are untouched; they already call `getPoldaApi()` to refresh, which now honors the current page/search — so deleting the last row of a page > 1 leaves an empty page until the user navigates (acceptable; `_totalPages` is re-derived from the response).
