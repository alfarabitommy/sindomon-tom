# Flutter Polda URL Hotfix — Build Report

**Build date:** 2026-01-18  
**File changed:** `lib/pages/polda.dart` (1 line)  
**Issue:** Search + pagination failing with CORS `Failed to fetch` — the GET list endpoint was missing the `master/` path segment.

---

## 1. Root Cause

`getPoldaApi()` was calling:

```
GET https://sindomon.cml-indonesia.com/api/v1/polda
```

but the backend serves the Polda CRUD resource under the `master` namespace:

```
GET  https://sindomon.cml-indonesia.com/api/v1/master/polda   ← list (correct)
DELETE https://sindomon.cml-indonesia.com/api/v1/master/polda/{id}  ← already correct
```

The mismatch caused the request to fail (CORS `Failed to fetch`), so the table never loaded — which made search and pagination appear broken even though the debounce/pagination logic itself was correct.

**Corroborating evidence inside the same file:** `deletePolda()` at line 160 already used `$apiBaseUrl/api/v1/master/polda/$id` — the list endpoint was the only one with the wrong path.

## 2. Exact Change

**File:** `lib/pages/polda.dart`, `getPoldaApi()`

```diff
-      Uri uri = Uri.parse("$apiBaseUrl/api/v1/polda");
+      Uri uri = Uri.parse("$apiBaseUrl/api/v1/master/polda");
```

**Line number after fix:** line 57.

No other code was touched — the debounce timer (400 ms), `_onSearchChanged`, `_onPageChanged`, the `?page=&limit=&search=` query building via `uri.replace(queryParameters: params)`, and the `data.items` / `data.pagination` response parsing are all unchanged.

## 3. Verification

| Check | Result |
|-------|--------|
| Old URL removed | ✅ `grep "api/v1/polda\"" lib` → no remaining occurrences of the wrong path |
| Delete endpoint consistency | ✅ `master/polda/$id` (pre-existing, unchanged) now matches the list namespace |
| Diff scope | ✅ `git diff` shows only the single line changed |
| `flutter analyze` | ⚠️ Could not run — no Flutter/Dart SDK in this sandbox (`flutter: command not found`). One-line string literal change; run `flutter analyze` locally to confirm. |

## 4. ⚠️ Other call sites with the same old path (NOT changed — out of scope)

`grep "api/v1/polda\"" lib` found the legacy path still used in two other files:

| File | Line | Usage |
|------|------|-------|
| `lib/pages/dashboard.dart` | 43 | Command Center map — fetches Polda markers (`GET /api/v1/polda`) |
| `lib/widget/form_input_user.dart` | 113 | User form — Polda dropdown options (`GET /api/v1/polda`) |

If the backend moved the Polda list under `master/`, these two calls will hit the same `Failed to fetch` issue. They were left untouched per the strict scope of this hotfix — confirm the backend route before patching them the same way.

## 5. Expected Result After Fix

- Page load → `GET /api/v1/master/polda?page=1&limit=10` returns 200 with `{ data: { items: [...], pagination: {...} } }`.
- Search typing (debounced 400 ms) → appends `&search=<query>` and resets to page 1.
- Page navigation → `?page=N` re-fetches and the `AppPagination` strip updates from the `pagination` object.
