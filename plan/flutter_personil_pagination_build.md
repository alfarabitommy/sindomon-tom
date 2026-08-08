# PersonelPage — Search & Pagination Build Confirmation

**Date:** 2025-07-16  
**File changed:** `lib/pages/personel.dart`  
**Reference pattern:** `lib/pages/polres.dart` (already-wired sibling)

---

## 1. Changes Applied — Confirmed ✅

### 1.1 Import (line 1)
```dart
import 'dart:async';   // added for Timer
```

### 1.2 Search & Pagination State (lines 31–40)
Added after the existing state block:
```dart
String _searchQuery = "";
Timer? _debounce;
final TextEditingController _searchController = TextEditingController();
int _currentPage = 1;
int _totalPages = 1;
int _totalItems = 0;
int _perPage = 10;
```

### 1.3 `getPersonelApi()` — URI builder (lines 56–64)
Bare `Uri.parse` replaced with query-parameter builder:
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

### 1.4 `getPersonelApi()` — Nested JSON parsing (lines 71–106)
Flat-array parse (`List<Map<String, dynamic>>.from(json["data"])`) replaced with the dual-shape `polres.dart` pattern:
- `data is Map` → reads `data["items"]`; `data is List` → legacy flat-array fallback.
- `data["pagination"]` extracted as `Map<String, dynamic>` with empty-map fallback.
- Pagination metadata updated in `setState`: `_currentPage`, `_totalPages` (from `last_page` or `total_pages`), `_totalItems` (from `total`), `_perPage` (from `per_page` or `limit`) — each with sensible fallbacks.
- **Added hardening (beyond polres.dart):** `if (!mounted) return;` guards on all three `setState` paths (success / HTTP error / catch), preventing `setState() called after dispose()` when an in-flight request resolves after navigation away.

### 1.5 `_onSearchChanged(String value)` (lines 174–181)
```dart
void _onSearchChanged(String value) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 400), () {
    _searchQuery = value;
    _currentPage = 1;
    getPersonelApi();
  });
}
```

### 1.6 `_onPageChanged(int page)` (lines 183–187)
```dart
void _onPageChanged(int page) {
  if (page < 1 || page > _totalPages || page == _currentPage) return;
  _currentPage = page;
  getPersonelApi();
}
```

### 1.7 `dispose()` (lines 189–194)
```dart
@override
void dispose() {
  _debounce?.cancel();
  _searchController.dispose();
  super.dispose();
}
```

### 1.8 `AppSearchField` wiring (lines 344–348)
```dart
AppSearchField(
  hintText: "Cari Personel...",
  controller: _searchController,
  onChanged: _onSearchChanged,
),
```

### 1.9 `AppPagination` wiring (lines 609–615)
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

## 2. Behavior After This Change

| Scenario | Behavior |
|---|---|
| Initial load | `GET /api/v1/sdm/personil?page=1&limit=10` |
| Typing in search | 400ms debounce → `?page=1&limit=10&search=<query>`; resets to page 1 |
| Empty search box | `search` param omitted from URL |
| Page click / arrows | `_onPageChanged` bounds-checked → `?page=N&limit=10` |
| Delete / add refresh | Re-fetches current page + active search query |
| Legacy backend shape | Flat array still parsed; pagination falls back to page-1 defaults |

---

## 3. Verification

- **`flutter analyze`** — ❌ NOT RUN: `flutter` CLI is not installed in this environment. Manual structural verification performed instead (file re-read at every integration point; edits anchored to exact unique strings).
- **Line-by-line inspection** — ✅ All 8 integration points confirmed present at the line numbers above.
- **Sub-agent review** — ✅ Ran; verdict *"OK to ship"* — faithful mirror of `polres.dart`; nested-shape parsing with legacy fallback, debounce lifecycle, delete-refresh/empty/error states all preserved.

---

## 4. Known Follow-ups (not in scope, shared with `polres.dart`)

1. **Stale-response race:** a slow search response resolving after a newer page-change response can overwrite newer data. Fix once across all pages with a request-sequence token.
2. **Empty last page after delete:** deleting the final item on the last page leaves an empty page; consider clamping `_currentPage` back one page.
3. **String-number pagination keys:** `(pagination["current_page"] as num?)` throws on string numbers; `int.tryParse`-tolerant access would harden all pages.
4. **`personil_id` null-safety:** `e["personil_id"].toString()` yields `"null"` if the key is absent (pre-existing, unchanged by this refactor).
5. **Unit tests:** no test/ infra exists for parsing; a nested-vs-legacy shape parsing test is cheap insurance.

---

## 5. Files

| File | Status |
|---|---|
| `lib/pages/personel.dart` | **Modified** (refactor complete) |
| `plan/flutter_personil_pagination_audit.md` | Prior audit artifact (unchanged) |
| `plan/flutter_personil_pagination_build.md` | This artifact |
