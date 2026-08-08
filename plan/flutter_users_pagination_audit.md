# Flutter User Management — Pagination, Search & Data Mapping Audit

**Audit date:** 2026-08-07  
**File audited:** `lib/pages/user_page.dart`  
**Supporting files reviewed:** `lib/widget/app_search_field.dart`, `lib/widget/app_pagination.dart`, `lib/widget/form_input_user.dart`, `lib/widget/app_sidebar.dart`, `plan/flutter_polda_pagination_audit.md` (reference pattern)

---

## 1. Current Implementation — Evidence

### 1.1 State variables (`_UserPageState`, lines 23–26)

```dart
List<Map<String, dynamic>> users = [];
bool isLoading = true;
String unLogin = "";
String roleLabel = "Operator";
```

**Missing (confirmed absent):**

| Variable | Purpose | Status |
|----------|---------|--------|
| `int _currentPage = 1` | Current page number | ❌ Missing |
| `int _totalPages = 1` | Total pages from API | ❌ Missing |
| `int _totalItems = 0` | Total record count from API | ❌ Missing |
| `int _perPage = 10` | Items per page sent to API | ❌ Missing |
| `String _searchQuery = ""` | Debounced search term | ❌ Missing |
| `Timer? _debounce` | Debounce timer handle | ❌ Missing |
| `TextEditingController _searchController` | Search field controller | ❌ Missing |
| `dart:async` import | Required for `Timer` | ❌ Missing (line 6 only has `dart:convert`) |
| `dispose()` override | Cleanup for timer + controller | ❌ Missing |

### 1.2 API call (`getUsers()`, lines 37–65)

```dart
Future<void> getUsers() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final response = await http.get(
      Uri.parse("$apiBaseUrl/api/v1/user"),       // ← static URL
      headers: {"Authorization": token.toString()},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      setState(() {
        users = List<Map<String, dynamic>>.from(json["data"]);  // ← only reads "data"
        isLoading = false;
      });
    }
    // ...
  }
}
```

**Observations:**
- ❌ **No query parameters** — the URL is `$apiBaseUrl/api/v1/user` with no `?page=`, `?per_page=`, or `?search=` appended.
- ❌ **No pagination metadata parsed** — only `json["data"]` is read. Fields like `current_page`, `last_page`, `total`, `per_page` are ignored even if the API returns them.
- ✅ Auth token is correctly sent (was fixed in a prior refactor).
- ❌ After delete (line 90), `getUsers()` re-fetches the **entire** unfiltered dataset.

### 1.3 Search field wiring (`build()`, line 195)

```dart
AppSearchField(hintText: "Cari Pengguna..."),
```

**Observations:**
- ❌ No `controller` prop — the `AppSearchField` widget (`lib/widget/app_search_field.dart:5–6`) accepts `TextEditingController? controller` but it's never passed.
- ❌ No `onChanged` prop — the widget accepts `ValueChanged<String>? onChanged` but it's never passed.
- **Result:** The search field is a **dead UI element**. Typing text does nothing; no API call is triggered; no filtering occurs.

**Contrast with `sarpras.dart` (reference implementation):**
```dart
AppSearchField(
  hintText: "Cari Sarpras...",
  controller: _searchController,
  onChanged: _onSearchChanged,
),
```

### 1.4 Pagination widget (`build()`, line 384)

```dart
const AppPagination(),
```

**Observations:**
- ❌ Instantiated as `const` — **no props** are passed.
- The `AppPagination` widget (`lib/widget/app_pagination.dart`) **does support** optional props (`currentPage`, `totalPages`, `totalItems`, `perPage`, `onPageChanged`) with sensible defaults — but none are wired.
- **Result:** The pagination strip always shows `"Menampilkan 1 hingga 10 dari 50 data"` with page 1 active, regardless of how many users actually exist.

### 1.5 `initState()` — no search controller init (line 114–118)

```dart
@override
void initState() {
  super.initState();
  loadUser();
  getUsers();
}
```

No `_searchController` is initialized (it doesn't exist). No `dispose()` override exists to clean up a timer or controller.

---

## 2. Data Mapping Failures — Why ROLE, POLDA, and STATUS Show Dashes ("-")

### 2.1 Root Cause Analysis

The DataTable columns (lines 262–375) map row data as follows:

| Column | Code (line) | Key Used | API Returns | Result |
|--------|-------------|----------|-------------|--------|
| **ROLE** | `"${e["roles_id"]}"` (275) | `roles_id` | Integer ID: `1`, `2`, or `3` | Shows raw number (`"1"`, `"2"`, `"3"`) — not a dash, but **not human-readable** |
| **POLDA** | `"${e["polda"] ?? ' - '}"` (280) | `polda` | `polda_id` (integer) | **Always shows " - "** because the key `"polda"` does not exist in the API response |
| **STATUS** | `"${e["status"] ?? ' - '}"` (285) | `status` | `"aktif"` or `"tidak_aktif"` | Shows raw API value — works but is **not translated/capitalized** |

### 2.2 Detailed Evidence for Each Column

#### ROLE (line 273–277)
```dart
DataCell(
  Text("${e["roles_id"]}"),  // e.g., "1", "2", "3"
),
```

The API returns `roles_id` as an integer (or integer-as-string). The form_input_user.dart edit mode confirms this (line 85–87):
```dart
final rawRole = data["roles_id"];   // integer or string
selectedRoleId = rawRole.toString(); // "1", "2", "3"
```

**Why it shows raw numbers:** There is no mapping from role ID to display label. A `switch` or lookup is needed:
```
"1" → "Super Admin"
"2" → "Operator Polda"
"3" → "Command Center"
```

`AppSidebar.roleLabelFromId()` (line 14–21) already implements this exact mapping and could be reused.

#### POLDA (line 278–281)
```dart
DataCell(
  Text("${e["polda"] ?? ' - '}"),  // key "polda" — DOES NOT EXIST in API response
),
```

The API response contains `polda_id` (an integer foreign key), **not** `polda` (a string name). Evidence from `form_input_user.dart` (line 92):
```dart
selectedPoldaId = data["polda_id"]?.toString();
```

The user API endpoint likely does **not** return a joined `nama_polda` field. Other pages (e.g., `personel.dart:393-398`, `polres.dart:430-432`) use a defensive fallback pattern:
```dart
e["nama_polda"] ?? e["polda_id"]
```

But even this just shows the ID, not the name. A proper fix would require either:
1. A backend change to join `nama_polda` in the user list response, or
2. A client-side lookup against a pre-fetched polda list (matching `polda_id` → `nama_polda`)

#### STATUS (line 283–286)
```dart
DataCell(
  Text("${e["status"] ?? ' - '}"),  // key is correct, but value is raw
),
```

The API returns status as `"aktif"` or `"tidak_aktif"` (lowercase, with underscore). Evidence from `form_input_user.dart` (lines 95–97, 172):
```dart
final rawStatus = data["status"]?.toString().toLowerCase() ?? "";
aktif = rawStatus == "aktif" || rawStatus == "1" || rawStatus == "active";

// On submit:
"status": aktif ? "aktif" : "tidak_aktif",
```

The key `"status"` is correct — the value **does** exist in the response. It shows the raw value (e.g., `"aktif"`) which is technically readable but not properly formatted. A mapping would improve UX:
- `"aktif"` → `"Aktif"` (or a green badge)
- `"tidak_aktif"` → `"Tidak Aktif"` (or a red badge)

### 2.3 Summary Table of Data Mapping Issues

| Issue | Severity | Root Cause | Fix Strategy |
|-------|----------|------------|-------------|
| ROLE shows raw ID | Medium | No label mapping for `roles_id` | Add `switch`/lookup using `AppSidebar.roleLabelFromId()` |
| POLDA always shows "-" | **High** | Wrong key: code uses `"polda"`, API returns `"polda_id"` | Change key to `"polda_id"`; optionally resolve to `nama_polda` via pre-fetched list or backend join |
| STATUS shows raw value | Low | No formatting applied to `"aktif"`/`"tidak_aktif"` | Add `.replaceAll("_", " ")` + capitalize, or a lookup map |

---

## 3. Integration Points for Pagination State Variables

### 3.1 New State Variables to Add

```dart
// Pagination state
int _currentPage = 1;
int _totalPages = 1;
int _totalItems = 0;
int _perPage = 10;

// Search state
String _searchQuery = "";
Timer? _debounce;
final TextEditingController _searchController = TextEditingController();
```

### 3.2 New Methods to Add

```dart
// Debounced search handler (pattern from sarpras.dart)
void _onSearchChanged(String value) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 400), () {
    _searchQuery = value;
    _currentPage = 1; // reset to page 1 on new search
    getUsers();
  });
}

// Page change handler
void _onPageChanged(int page) {
  if (page < 1 || page > _totalPages) return;
  _currentPage = page;
  getUsers();
}
```

### 3.3 New `dispose()` Override

```dart
@override
void dispose() {
  _debounce?.cancel();
  _searchController.dispose();
  super.dispose();
}
```

### 3.4 Required Import

Add to line 6:
```dart
import 'dart:async';  // for Timer
```

### 3.5 `getUsers()` Refactor — Query Parameters + Metadata

The method at lines 37–65 must be updated to:

1. **Append query parameters** to the URL:
   ```dart
   Uri uri = Uri.parse("$apiBaseUrl/api/v1/user");
   final Map<String, String> params = {
     "page": _currentPage.toString(),
     "per_page": _perPage.toString(),
   };
   if (_searchQuery.isNotEmpty) {
     params["search"] = _searchQuery;
   }
   uri = uri.replace(queryParameters: params);
   ```

2. **Parse pagination metadata** from the response:
   ```dart
   setState(() {
     users = List<Map<String, dynamic>>.from(json["data"]);
     _currentPage = json["current_page"] ?? 1;
     _totalPages = json["last_page"] ?? 1;
     _totalItems = json["total"] ?? 0;
     _perPage = json["per_page"] ?? 10;
     isLoading = false;
   });
   ```

### 3.6 UI Wiring Points in `build()` (lines 195 and 384)

**Search field** (line 195) — REPLACE:
```dart
AppSearchField(hintText: "Cari Pengguna..."),
```
WITH:
```dart
AppSearchField(
  hintText: "Cari Pengguna...",
  controller: _searchController,
  onChanged: _onSearchChanged,
),
```

**Pagination** (line 384) — REPLACE:
```dart
const AppPagination(),
```
WITH:
```dart
AppPagination(
  currentPage: _currentPage,
  totalPages: _totalPages,
  totalItems: _totalItems,
  perPage: _perPage,
  onPageChanged: _onPageChanged,
),
```

### 3.7 Data Mapping Fix Points in `build()` (lines 273–286)

**ROLE** (line 275) — REPLACE:
```dart
Text("${e["roles_id"]}"),
```
WITH:
```dart
Text(AppSidebar.roleLabelFromId(e["roles_id"]?.toString())),
```

**POLDA** (line 280) — REPLACE key:
```dart
Text("${e["polda"] ?? ' - '}"),     // OLD — wrong key
```
WITH:
```dart
Text("${e["polda_id"] ?? ' - '}"),   // NEW — correct key (shows ID)
```
Or better, resolve to name if a polda lookup map is available:
```dart
Text(_poldaNameMap[e["polda_id"]?.toString()] ?? e["polda_id"]?.toString() ?? ' - '),
```

**STATUS** (line 285) — REPLACE:
```dart
Text("${e["status"] ?? ' - '}"),
```
WITH:
```dart
Text(e["status"]?.toString() == "aktif" ? "Aktif" : "Tidak Aktif"),
```

---

## 4. Complete Integration Checklist

### Phase A — Pagination & Search State

| # | Change | Location | Risk |
|---|--------|----------|------|
| A1 | Add `import 'dart:async';` | Line 6 | None |
| A2 | Add 7 new state variables (`_currentPage` through `_searchController`) | After line 26 | None |
| A3 | Add `_onSearchChanged(String)` debounce method | After `getUsers()` | Low |
| A4 | Add `_onPageChanged(int)` handler | After `_onSearchChanged` | Low |
| A5 | Add `dispose()` override | After `initState()` | Low |
| A6 | Refactor `getUsers()` to append `?page=&per_page=&search=` and parse metadata | Lines 37–65 | **Medium** — depends on backend API contract |
| A7 | Wire `AppSearchField` with `controller` + `onChanged` | Line 195 | None |
| A8 | Wire `AppPagination` with all 5 props | Line 384 | None |

### Phase B — Data Mapping Fixes

| # | Change | Location | Risk |
|---|--------|----------|------|
| B1 | Map `roles_id` → label via `AppSidebar.roleLabelFromId()` | Line 275 | None |
| B2 | Fix POLDA key from `"polda"` to `"polda_id"` | Line 280 | None |
| B3 | Format STATUS from raw to capitalized | Line 285 | None |

---

## 5. Backend API Contract Assumptions

The plan assumes `GET /api/v1/user` supports these query parameters:

| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `page` | int | `?page=1` | Current page number (1-based) |
| `per_page` | int | `?per_page=10` | Items per page |
| `search` | string | `?search=admin` | Full-text search across username/role |

And returns pagination metadata:
```json
{
  "data": [...],
  "current_page": 1,
  "last_page": 5,
  "per_page": 10,
  "total": 50
}
```

> ⚠️ **Risk:** This is the same contract assumed by `flutter_polda_pagination_audit.md`. If the backend uses different field names (e.g., `meta.pagination.total`) or does not support these parameters, the plan must be adjusted. A quick API test (e.g., `curl "$apiBaseUrl/api/v1/user?page=1&per_page=2"`) is recommended before implementing.

---

## 6. Reference Implementations in the Codebase

| Pattern | File | Lines |
|---------|------|-------|
| Debounced search + API query params | `lib/pages/sarpras.dart` | 50–80, 285–289 |
| Debounced search (same pattern) | `lib/pages/satwa.dart` | grep `_onSearchChanged` |
| `AppSidebar.roleLabelFromId()` mapping | `lib/widget/app_sidebar.dart` | 14–21 |
| Polda name defensive fallback | `lib/pages/personel.dart` | 393–398 |
| Full pagination audit (same gaps) | `plan/flutter_polda_pagination_audit.md` | entire document |

---

## 7. Scope of Impact

- **`lib/pages/user_page.dart`** — primary file to modify (~50 lines changed/added)
- **No other files** need changes — `AppPagination` already supports optional props with defaults, and `AppSearchField` already accepts `controller` + `onChanged`
- **No breakage** to other pages — the `const AppPagination()` call sites elsewhere continue to compile with defaults
- The `form_input_user.dart` and `add_user.dart` files do **not** need changes for this work (they are for create/edit flows, not list display)
