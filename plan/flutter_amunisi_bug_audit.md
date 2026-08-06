# Flutter Amunisi Bug Audit — Trailing `?` in URL

## 1. URL Construction Logic

**File:** `lib/pages/amunisi.dart`, lines 49–53 (method `getAmunisiApi()`)

```dart
final uri = Uri.parse("$apiBaseUrl/api/v1/logistik/amunisi").replace(
  queryParameters: {
    if (_searchQuery.isNotEmpty) "search": _searchQuery,
  },
);
```

**Identical pattern also found in:** `lib/pages/senjata.dart`, line 48–52.

### Execution flow on first load

1. `initState()` (line 82) calls `getAmunisiApi()`.
2. At that point, `_searchQuery` is `""` (empty string — initialized on line 31).
3. The collection-if `if (_searchQuery.isNotEmpty)` evaluates to **`false`**.
4. Result: `queryParameters:` receives an **empty map `{}`**.
5. The `Uri` produced by `.replace(queryParameters: {})` becomes:

   ```
   https://sindomon.cml-indonesia.com/api/v1/logistik/amunisi?
   ```
   *(Note the trailing question mark.)*

---

## 2. Trailing Question Mark Analysis

### Root cause

**`Uri.replace(queryParameters: {})` with an empty map causes Dart to set the internal `_query` field to an empty string `""` instead of keeping it `null`.**

Per Dart's `Uri` serialization rules:

| `query` value | `toString()` output |
|---|---|
| `null` (no query) | `.../amunisi` |
| `""` (empty string) | `.../amunisi?` |
| `"search=foo"` | `.../amunisi?search=foo` |

When `.replace(queryParameters: {})` is called on a URI that originally had no query, it replaces the (absent) query with an empty map. Dart internally stores this as `query = ""` rather than `query = null`. During `Uri.toString()` (which `http.get` uses to serialize), an empty-but-not-null query string still gets its `?` separator prepended.

### Why this causes a CORS preflight failure

The browser (Chrome) sees the URL `.../amunisi?` and sends a CORS `OPTIONS` preflight request to that **exact** URL (including the trailing `?`). The server `sindomon.cml-indonesia.com` does not recognize the route `.../amunisi?` as matching `.../amunisi` (some backends treat the `?` as part of the path matching, returning 404). The `OPTIONS` returns 404, so the browser blocks the subsequent `GET` — resulting in the `Failed to fetch` error.

### Affected pages

| File | Line(s) | Trigger condition |
|---|---|---|
| `lib/pages/amunisi.dart` | 49–53 | `_searchQuery` is empty (page load, empty search) |
| `lib/pages/senjata.dart` | 48–52 | `_searchQuery` is empty (page load, empty search) |

### Fix strategy (not applied — audit only)

The idiomatic fix is to **avoid calling `.replace()` when there are no query parameters to set**:

```dart
// Option A: conditional replace (simplest & safest)
Uri uri = Uri.parse("$apiBaseUrl/api/v1/logistik/amunisi");
if (_searchQuery.isNotEmpty) {
  uri = uri.replace(queryParameters: {"search": _searchQuery});
}
```

Option A is the recommended fix. It ensures `.replace()` is only called when there is actually a query parameter to add, preventing the empty-map → trailing `?` bug.
