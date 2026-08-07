# Flutter Polda Pagination & Search Audit

**Audit date:** 2026-01-18  
**File audited:** `lib/pages/polda.dart`  
**Supporting files reviewed:** `lib/widget/app_pagination.dart`, `lib/widget/app_search_field.dart`, `lib/models/polda_model.dart`, `lib/pages/sarpras.dart` (reference implementation)

---

## 1. Current Implementation — Evidence

### 1.1 State variables (`_PoldaPageState`)

```dart
// lib/pages/polda.dart, lines 23–28
List<Polda> polda = [];
String errorMessage = "";
bool isLoading = true;
String unLogin = "";
String roleLabel = "Operator";
```

**Missing:**
- ❌ No `int _currentPage = 1;`
- ❌ No `int _totalPages = 1;`
- ❌ No `int _totalItems = 0;`
- ❌ No `Timer? _debounce;`
- ❌ No `String _searchQuery = "";`
- ❌ No `TextEditingController _searchController;`
- ❌ No `dart:async` import (required for `Timer`)
- ❌ No `dispose()` override (required for cancelling timer and disposing controller)

### 1.2 Search field wiring (`build()` method, line 276)

```dart
AppSearchField(hintText: "Cari Polda..."),
```

**Observations:**
- `onChanged` is **not** wired — the widget accepts an `onChanged` callback but it's never passed.
- `controller` is **not** passed — the widget accepts a `TextEditingController` but it's never provided.
- The search field is a **dead UI element** — typing text does nothing; no API call is triggered.

**Contrast with `sarpras.dart` (reference):**
```dart
// lib/pages/sarpras.dart, lines 285–289
AppSearchField(
  hintText: "Cari Sarpras...",
  controller: _searchController,
  onChanged: _onSearchChanged,
),
```

### 1.3 Pagination widget (`build()` method, line 481)

```dart
const AppPagination(),
```

**Observations:**
- Instantiated as a `const` — no props are passed at all.
- The `AppPagination` class (`lib/widget/app_pagination.dart`) is a **`StatelessWidget`** that:
  - Shows the hardcoded text `"Menampilkan 1 hingga 10 dari 50 data"` (line 19)
  - Renders hardcoded page buttons `"1"`, `"2"`, `"3"` with page 1 always active (lines 26–32)
  - Accepts **zero parameters** — no `currentPage`, `totalPages`, `totalItems`, or `onPageChanged` callback
- This widget is used identically in 11 page files (polda, personel, senjata, sarpras, satwa, amunisi, polres, inventaris, user_page, master_kategori_senjata, report) — all with `const AppPagination()`

### 1.4 API call (`getPoldaApi()`, lines 39–77)

```dart
Future<void> getPoldaApi() async {
  // ...
  final response = await http.get(
    Uri.parse("$apiBaseUrl/api/v1/polda"),
    headers: {"Authorization": token.toString()},
  );
  // ...
}
```

**Observations:**
- The URL is static — **no query parameters** are appended.
- No `?page=$_currentPage` parameter.
- No `?search=$_searchQuery` parameter.
- Fetches the **entire dataset** from the server (no server-side pagination).
- The response JSON is parsed as a flat list: `json["data"]` → `List<Polda>`.
- No pagination metadata (`total`, `last_page`, `per_page`, `current_page`) is read from the response.
- After delete, `getPoldaApi()` is called to refresh, which re-fetches everything.

---

## 2. Gap Analysis

| Feature | Current State | Target State |
|---------|---------------|-------------|
| Debounced search | ❌ Not implemented | ✅ `Timer? _debounce`, 400ms delay, calls API with `?search=` |
| Page state variables | ❌ None | ✅ `_currentPage`, `_totalPages`, `_totalItems`, `_perPage` |
| Dynamic pagination UI | ❌ Hardcoded `const AppPagination()` | ✅ Widget accepts `currentPage`, `totalPages`, `totalItems`, `onPageChanged` |
| API query params | ❌ Static URL | ✅ `?page=$_currentPage&search=$_searchQuery` |
| Response metadata | ❌ Not parsed | ✅ Read `total`, `last_page`, `per_page` from response |
| `dart:async` import | ❌ Missing | ✅ Required for `Timer` |
| `dispose()` override | ❌ Missing | ✅ Cancel timer, dispose controller |
| `initState()` wiring | ❌ Only calls `loadUser()` + `getPoldaApi()` | ✅ Same, but search controller initialized |

---

## 3. Reference Pattern (from `sarpras.dart`)

The `sarpras.dart` page already implements the **debounced search** pattern correctly:

```dart
// State variables
String _searchQuery = "";
Timer? _debounce;
final TextEditingController _searchController = TextEditingController();

// Debounce handler
void _onSearchChanged(String value) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 400), () {
    _searchQuery = value;
    getSarprasApi();
  });
}

// API call with query params
Future<void> getSarprasApi() async {
  Uri uri = Uri.parse("$apiBaseUrl/api/v1/logistik/sarpras");
  if (_searchQuery.isNotEmpty) {
    uri = uri.replace(queryParameters: {"search": _searchQuery});
  }
  // ...
}

// Cleanup
@override
void dispose() {
  _debounce?.cancel();
  _searchController.dispose();
  super.dispose();
}
```

**However**, `sarpras.dart` also lacks pagination (`_currentPage`, `_totalPages`) — it only has search. The debounce pattern is also present in `satwa.dart`, `senjata.dart`, `amunisi.dart`, and `master_kategori_senjata.dart`, all following the same pattern.

**No page in the entire codebase** has implemented dynamic pagination state yet. `AppPagination` is hardcoded everywhere.

---

## 4. Refactor Plan

### Phase A: Polda Page (`lib/pages/polda.dart`)

#### Step A1 — Add imports
- Add `import 'dart:async';` at the top of the file.

#### Step A2 — Add new state variables
Add to `_PoldaPageState`:
```dart
String _searchQuery = "";
Timer? _debounce;
final TextEditingController _searchController = TextEditingController();
int _currentPage = 1;
int _totalPages = 1;
int _totalItems = 0;
int _perPage = 10;
```

#### Step A3 — Add `_onSearchChanged` debounce handler
```dart
void _onSearchChanged(String value) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 400), () {
    _searchQuery = value;
    _currentPage = 1; // reset to first page on new search
    getPoldaApi();
  });
}
```

#### Step A4 — Add `_onPageChanged` handler
```dart
void _onPageChanged(int page) {
  if (page < 1 || page > _totalPages) return;
  _currentPage = page;
  getPoldaApi();
}
```

#### Step A5 — Refactor `getPoldaApi()` to use query parameters
```dart
Future<void> getPoldaApi() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    Uri uri = Uri.parse("$apiBaseUrl/api/v1/polda");
    final Map<String, String> params = {
      "page": _currentPage.toString(),
      "per_page": _perPage.toString(),
    };
    if (_searchQuery.isNotEmpty) {
      params["search"] = _searchQuery;
    }
    uri = uri.replace(queryParameters: params);

    final response = await http.get(
      uri,
      headers: {"Authorization": token.toString()},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final rawList = json["data"] as List;
      final parsed = rawList
          .map((e) => Polda.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        polda = parsed;
        _currentPage = json["current_page"] ?? 1;
        _totalPages = json["last_page"] ?? 1;
        _totalItems = json["total"] ?? 0;
        _perPage = json["per_page"] ?? 10;
        errorMessage = "";
        isLoading = false;
      });
    } else {
      // ... error handling unchanged
    }
  } catch (e) {
    // ... unchanged
  }
}
```

#### Step A6 — Add `dispose()` override
```dart
@override
void dispose() {
  _debounce?.cancel();
  _searchController.dispose();
  super.dispose();
}
```

#### Step A7 — Wire the search field
Replace:
```dart
AppSearchField(hintText: "Cari Polda..."),
```
With:
```dart
AppSearchField(
  hintText: "Cari Polda...",
  controller: _searchController,
  onChanged: _onSearchChanged,
),
```

#### Step A8 — Wire the pagination widget
Replace:
```dart
const AppPagination(),
```
With:
```dart
AppPagination(
  currentPage: _currentPage,
  totalPages: _totalPages,
  totalItems: _totalItems,
  perPage: _perPage,
  onPageChanged: _onPageChanged,
),
```

### Phase B: AppPagination Widget (`lib/widget/app_pagination.dart`)

Convert from `StatelessWidget` to accept dynamic props:

```dart
class AppPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int perPage;
  final ValueChanged<int> onPageChanged;

  const AppPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.perPage,
    required this.onPageChanged,
  });
  // ...
}
```

**Display text** should derive dynamically:
```dart
final int start = (currentPage - 1) * perPage + 1;
final int end = (currentPage * perPage).clamp(1, totalItems);
"Menampilkan $start hingga $end dari $totalItems data"
```

**Page buttons** should be generated from `totalPages` with Previous/Next arrows that call `onPageChanged`.

---

## 5. Backend API Contract Assumptions

The plan assumes the `GET /api/v1/polda` endpoint supports these query parameters:

| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `page` | int | `?page=1` | Current page number (1-based) |
| `per_page` | int | `?per_page=10` | Items per page |
| `search` | string | `?search=jawa` | Full-text search filter |

And returns pagination metadata in the JSON response:
```json
{
  "data": [...],
  "current_page": 1,
  "last_page": 5,
  "per_page": 10,
  "total": 50
}
```

> ⚠️ **Risk:** If the backend does NOT support these parameters, the plan needs adjustment. The API might return unpaginated data regardless of query params, or use different field names (e.g., `meta.pagination.total`). A quick backend check or API test is recommended before proceeding.

---

## 6. Scope of Impact

Changing `AppPagination` from a no-arg `const` to a required-args widget will **break 11 call sites** across the codebase. Options:

1. **Make new props optional with defaults** — backward-compatible; the hardcoded values become defaults. Other pages can be migrated incrementally.
2. **Make new props required** — forces all pages to be updated at once (riskier, but ensures consistency).
3. **Create a separate `AppPagination.live(...)` named constructor** — keeps the old hardcoded version for non-migrated pages.

**Recommendation:** Option 1 (optional props with current defaults). This allows `polda.dart` to work immediately without breaking the other 10 pages. Each page can be migrated later.
