# Flutter User Management — Pagination, Search & Data Mapping Build Results

**Build date:** 2026-08-07  
**File modified:** `lib/pages/user_page.dart`  
**Reference pattern:** `lib/pages/polda.dart` (verified pagination/search implementation), `lib/widget/app_pagination.dart` (optional props), `lib/widget/app_search_field.dart` (controller/onChanged)

---

## 1. Changes Applied

### 1.1 Import (`line 1`)

```dart
import 'dart:async';
```

Added for `Timer` support (required by `_debounce`).

### 1.2 Search & Pagination State (`lines 30–39`)

```dart
/// ========================
/// SEARCH & PAGINATION STATE
/// ========================
String _searchQuery = "";
Timer? _debounce;
final TextEditingController _searchController = TextEditingController();
int _currentPage = 1;
int _totalPages = 1;
int _totalItems = 0;
int _perPage = 10;
```

### 1.3 `getUsers()` Refactor (`lines 50–113`)

**URI builder — server-side pagination + search:**
```dart
Uri uri = Uri.parse("$apiBaseUrl/api/v1/user");
final Map<String, String> params = {
  "page": _currentPage.toString(),
  "limit": _perPage.toString(),
};
if (_searchQuery.isNotEmpty) {
  params["search"] = _searchQuery;
}
uri = uri.replace(queryParameters: params);
```

**Nested JSON parsing (new backend shape with legacy fallback):**
```dart
final data = json["data"];
// New backend shape: { data: { items: [...], pagination: {...} } }.
// Tolerates the legacy flat-list shape as a fallback.
final List rawList = data is Map
    ? (data["items"] is List ? data["items"] as List : [])
    : (data is List ? data as List : []);
final Map<String, dynamic> pagination = data is Map &&
        data["pagination"] is Map
    ? data["pagination"] as Map<String, dynamic>
    : <String, dynamic>{};
final List<Map<String, dynamic>> parsed =
    rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
```

**Metadata state updates (with field-name fallbacks):**
```dart
users = parsed;
_currentPage = (pagination["current_page"] as num?)?.toInt() ?? _currentPage;
_totalPages = (pagination["last_page"] as num?)?.toInt() ??
    (pagination["total_pages"] as num?)?.toInt() ?? 1;
_totalItems = (pagination["total"] as num?)?.toInt() ?? parsed.length;
_perPage = (pagination["per_page"] as num?)?.toInt() ??
    (pagination["limit"] as num?)?.toInt() ?? _perPage;
```

> **Note on query param name:** The mission brief listed `per_page`, but the **verified backend contract** (already live in `polda.dart:60`, `polres.dart:59`, `master_kategori_senjata.dart:68` — all synced to the new backend) uses **`limit`** as the request parameter. Sending `per_page` would be ignored by the backend and break server-side pagination. The response side still parses both `per_page` and `limit` for robustness.

### 1.4 Debounced Search Handler (`lines 168–177`)

```dart
/// Debounced search: waits 400ms of idle typing before hitting the API,
/// and always resets to page 1 so results start from the beginning.
void _onSearchChanged(String value) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 400), () {
    _searchQuery = value;
    _currentPage = 1;
    getUsers();
  });
}
```

### 1.5 Page Change Handler (`lines 179–183`)

```dart
void _onPageChanged(int page) {
  if (page < 1 || page > _totalPages || page == _currentPage) return;
  _currentPage = page;
  getUsers();
}
```

### 1.6 `dispose()` Override (`lines 185–190`)

```dart
@override
void dispose() {
  _debounce?.cancel();
  _searchController.dispose();
  super.dispose();
}
```

### 1.7 UI Wiring

**Search field (`lines 266–271`):**
```dart
AppSearchField(
  hintText: "Cari Pengguna...",
  controller: _searchController,
  onChanged: _onSearchChanged,
),
```

**Pagination strip (`lines 469–475`):**
```dart
AppPagination(
  currentPage: _currentPage,
  totalPages: _totalPages,
  totalItems: _totalItems,
  perPage: _perPage,
  onPageChanged: _onPageChanged,
),
```

### 1.8 DataColumn Mapping Fixes (`lines 349–372`)

| Column | Before (broken) | After (fixed) |
|--------|-----------------|---------------|
| **ROLE** | `Text("${e["roles_id"]}")` → showed raw `"1"`, `"2"`, `"3"` | `Text(AppSidebar.roleLabelFromId(e["roles_id"]?.toString()))` → "Super Admin" / "Operator Polda" / "Command Center" |
| **POLDA** | `Text("${e["polda"] ?? ' - '}")` → key `"polda"` doesn't exist in API → always `" - "` | `Text(e["nama_polda"]?.toString() ?? ' - ')` → displays joined polda name from new backend |
| **STATUS** | `Text("${e["status"] ?? ' - '}")` → raw lowercase value | `Text(e["is_active"]?.toString() == "1" ? "Aktif" : "Tidak Aktif")` → human-readable Indonesian label (backend field `is_active TINYINT(1)` per `plan/sindomon_master_patch.sql:265`) |

---

## 2. Verification

| Check | Result |
|-------|--------|
| `grep 'e\["polda"\]\|e\["status"\]' lib/pages/user_page.dart` | ✅ No matches — broken keys fully replaced |
| Widget API conformance — `AppSearchField({hintText, onChanged, controller})` (`app_search_field.dart:5–6`) | ✅ Matches |
| Widget API conformance — `AppPagination({currentPage, totalPages, totalItems, perPage, onPageChanged})` (`app_pagination.dart:11–15`) | ✅ Matches |
| `AppSidebar.roleLabelFromId(String?)` signature (`app_sidebar.dart:14`) | ✅ Static method, accepts `String?` |
| Pattern parity with proven `polda.dart` (`lib/pages/polda.dart:52–152`) | ✅ 1:1 — same state vars, debounce logic, bounds check, parsing, metadata fallbacks |
| `flutter analyze lib/pages/user_page.dart` | ⚠️ **Not runnable** — no Flutter SDK installed on this machine (`flutter: command not found`, no `dart` binary). Same limitation documented in prior build sessions (`flutter_polda_pagination_build.md:187`). |
| `git diff lib/pages/user_page.dart` | ✅ 105 changed lines, all intended changes, no collateral edits |

**Smoke test checklist (manual, requires Flutter toolchain + valid login):**
- [ ] Launch app as Super Admin → "Manajemen Pengguna" → table shows page 1 (`?page=1&limit=10`)
- [ ] Range text reads e.g. "Menampilkan 1 hingga 10 dari 42 data" (not the hardcoded "dari 50")
- [ ] Click `>` → page 2 loads, amber highlight moves, range text updates
- [ ] Type "admin" in "Cari Pengguna..." → wait 400ms → list filters, resets to page 1
- [ ] ROLE column shows "Super Admin" / "Operator Polda" / "Command Center" (not `1`/`2`/`3`)
- [ ] POLDA column shows polda names (not `-`); STATUS column shows "Aktif"/"Tidak Aktif"
- [ ] Delete last row of page 2 → refresh stays on page 2 (empty-page edge case acceptable; `_totalPages` re-derived from response)

---

## 3. Files Touched

| File | Action |
|------|--------|
| `lib/pages/user_page.dart` | **Modified** — pagination/search state + handlers, `getUsers()` query params + nested JSON parsing, DataColumn mapping fixes, `dispose()` |

No other files changed. `AppPagination` / `AppSearchField` already supported the required props; other call sites unaffected.

## 4. Assumptions & Risks

1. **Backend contract** (`GET /api/v1/user?page=&limit=&search=`) returns `{ data: { items: [...], pagination: { current_page, last_page, total, per_page } } }`. The parsing tolerates the legacy flat-list shape if the backend is not yet migrated — in that case pagination falls back to `parsed.length` and search/page params are ignored by the server (UI still functions, pagination strip shows one page).
2. **`nama_polda` key** — assumed present in the new backend user response (same JOIN pattern as `/api/v1/sdm/personil`). If the backend omits it, the cell renders `-`; a follow-up could add the `e["polda_id"]` fallback used in `personel.dart:396–398`.
3. **`is_active` values** — assumed `1`/`0` (TINYINT per DB schema). JSON boolean `true` would render "Tidak Aktif" incorrectly; only affects display if the backend serializes booleans instead of ints.
