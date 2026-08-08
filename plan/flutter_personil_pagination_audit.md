# PersonelPage — Search & Pagination Audit

**Date:** 2025-07-16  
**File:** `lib/pages/personel.dart`  
**Refactored siblings (already wired):** `polda.dart`, `polres.dart`, `user_page.dart`, `master_kategori_senjata.dart`  
**Search-only siblings:** `amunisi.dart`, `sarpras.dart`, `satwa.dart`, `senjata.dart`

---

## 1. Current State Summary

### 1.1 State Variables (lines 22–27)

```dart
List<Map<String, dynamic>> datapersonel = [];
String errorMessage = "";
bool isLoading = true;
String unLogin = "";
String roleLabel = "Operator";
```

**CONFIRMED MISSING — no search/pagination variables exist:**

| Variable | Type | Purpose | Present? |
|---|---|---|---|
| `_searchQuery` | `String` | Holds the debounced search term | ❌ |
| `_debounce` | `Timer?` | Cancellable debounce timer | ❌ |
| `_searchController` | `TextEditingController` | Bound to `AppSearchField` | ❌ |
| `_currentPage` | `int` | Active page number (1-based) | ❌ |
| `_totalPages` | `int` | Last page from API pagination | ❌ |
| `_totalItems` | `int` | Total record count across all pages | ❌ |
| `_perPage` | `int` | Page size sent to the API | ❌ |

---

### 1.2 API Call — `getPersonelApi()` (lines 38–68)

```dart
final response = await http.get(
  Uri.parse("$apiBaseUrl/api/v1/sdm/personil"),
  headers: {"Authorization": token.toString()},
);
```

**CONFIRMED: No query parameters.**  
The endpoint is called with a bare URI — no `?page=`, `?limit=`, or `?search=` appended.

**JSON parsing (line 51):**
```dart
datapersonel = List<Map<String, dynamic>>.from(json["data"]);
```

This assumes `json["data"]` is a **flat JSON array** of personel objects. The `polres.dart` refactored sibling (lines 73–84) already handles the **new nested shape** `{ items: [...], pagination: {...} }` with a legacy flat-array fallback:

```dart
// polres.dart lines 73–84 — the target pattern
final List rawList = data is Map
    ? (data["items"] is List ? data["items"] : [])
    : (data is List ? data : []);
final Map<String, dynamic> pagination = data is Map && data["pagination"] is Map
    ? data["pagination"] as Map<String, dynamic>
    : <String, dynamic>{};
final parsed = rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
```

---

### 1.3 AppSearchField Usage (line 268)

```dart
AppSearchField(hintText: "Cari Personel..."),
```

**CONFIRMED: No `controller` or `onChanged` props passed.**  
The widget class (`app_search_field.dart`) fully supports both:

```dart
class AppSearchField extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;    // ← available, not used
  final TextEditingController? controller;   // ← available, not used
```

---

### 1.4 AppPagination Usage (line 529)

```dart
const AppPagination(),
```

**CONFIRMED: Statically constructed with all defaults:**

| Prop | Default | Meaning |
|---|---|---|
| `currentPage` | `1` | Always shows page 1 |
| `totalPages` | `1` | No clickable page buttons |
| `totalItems` | `50` | Hardcoded "50 data" text |
| `perPage` | `10` | "1 hingga 10" text |
| `onPageChanged` | `null` | No callback — arrows disabled |

The widget class (`app_pagination.dart`) is **already fully dynamic** — it accepts all five props and conditionally enables prev/next arrows and page-number buttons when `onPageChanged` is non-null. No widget changes needed.

---

### 1.5 Dispose (none exists)

**CONFIRMED: No `dispose()` override.** Adding `_searchController` and `_debounce` will require adding:

```dart
@override
void dispose() {
  _debounce?.cancel();
  _searchController.dispose();
  super.dispose();
}
```

---

## 2. Integration Points — Where Changes Land

### 2.1 New State Variables (insert after line 27)

After `String roleLabel = "Operator";`, add the 7 variables matching the `polres.dart` pattern:

```dart
String _searchQuery = "";
Timer? _debounce;
final TextEditingController _searchController = TextEditingController();
int _currentPage = 1;
int _totalPages = 1;
int _totalItems = 0;
int _perPage = 10;
```

Also add `import 'dart:async';` at the top (for `Timer`).

### 2.2 `getPersonelApi()` — Rewrite URI + Parsing (lines 38–68)

Three changes inside the method:

1. **Build URI with query parameters** (replace the bare `Uri.parse`):
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

2. **Replace flat-array parsing** with the dual-shape pattern that tolerates both `{ items, pagination }` and legacy flat arrays.

3. **Populate pagination variables** in `setState` alongside `datapersonel`.

### 2.3 `_onSearchChanged` Handler (new method)

Debounced 400ms handler — identical to polres.dart lines 129–136:

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

### 2.4 `_onPageChanged` Handler (new method)

```dart
void _onPageChanged(int page) {
  if (page < 1 || page > _totalPages || page == _currentPage) return;
  _currentPage = page;
  getPersonelApi();
}
```

### 2.5 AppSearchField Wiring (line 268)

Change from:
```dart
AppSearchField(hintText: "Cari Personel..."),
```
to:
```dart
AppSearchField(
  hintText: "Cari Personel...",
  controller: _searchController,
  onChanged: _onSearchChanged,
),
```

### 2.6 AppPagination Wiring (line 529)

Change from:
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

### 2.7 Dispose (new override)

Add before the closing `}` of `_PersonelPageState`:

```dart
@override
void dispose() {
  _debounce?.cancel();
  _searchController.dispose();
  super.dispose();
}
```

### 2.8 `deletePersonel()` Refresh

After a successful delete (line 91: `getPersonelApi()`), the current behavior resets to whatever `_currentPage` is. If the last item on a page is deleted, the page may become empty. The `polres.dart` sibling does not handle this edge case either, so it is **out of scope** for this change. It can be addressed later as a cross-cutting improvement.

---

## 3. Expected API Response Shape

The backend is expected to return a **nested** structure under `data`:

```json
{
  "data": {
    "items": [
      { "personil_id": "...", "nrp": "...", "nama_lengkap": "...", ... },
      ...
    ],
    "pagination": {
      "current_page": 1,
      "last_page": 5,
      "total": 47,
      "per_page": 10
    }
  }
}
```

The parsing code should also fall back to the legacy flat-array shape (`"data": [...]`) so that either backend version works during the transition.

---

## 4. Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| Backend doesn't yet support `?page`/`?limit`/`?search` on `/api/v1/sdm/personil` | **HIGH** | Verify with backend team before deploying. The `polda`/`polres`/`user_page` endpoints already support these params, so the pattern is established. |
| Legacy flat-array response from backend | **LOW** | The dual-shape parser (polres pattern) handles both shapes. |
| `_searchController` lifecycle leak | **LOW** | `dispose()` is being added. |
| Search debounce not cancelled on rapid typing | **LOW** | `_debounce?.cancel()` at the top of `_onSearchChanged` prevents stacked timers. |
| Stale `setState` after async gap | **LOW** | The `polres.dart` pattern includes a `mounted` + stale-request guard (lines 78, 88–89). This is optional for personel but recommended for correctness. |

---

## 5. Summary

`personel.dart` is a **pre-refactor page** — it has the standard layout template but none of the search/pagination wiring that its siblings (`polda.dart`, `polres.dart`, `user_page.dart`) already have. The widget library (`AppSearchField`, `AppPagination`) is already fully dynamic and requires zero changes. All work is confined to `_PersonelPageState`:

- **7 new state variables**
- **1 new import** (`dart:async`)
- **3 method rewrites/insertions** (`getPersonelApi`, `_onSearchChanged`, `_onPageChanged`)
- **1 new `dispose` override**
- **2 widget prop wirings** (AppSearchField + AppPagination)

The `polres.dart` file is the canonical reference implementation for every change listed above.
