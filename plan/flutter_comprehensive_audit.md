# Flutter Comprehensive Audit — Senjata Table Fetch Failure

**Date:** 2026-08-05
**Auditor:** Senior Flutter Auditor (DEBUG MODE)
**Error:** `ClientException: Failed to fetch` in `getSenjataApi()`

---

## 1. Fetch API Status

### Exact HTTP Call

**Method:** `http.get()`
**URL (resolved):**
```
https://sindomon.cml-indonesia.com/api/v1/logistik/senjata
```

**Source (line 48–57):**
```dart
final uri = Uri.parse("$apiBaseUrl/api/v1/logistik/senjata").replace(
  queryParameters: {
    if (_searchQuery.isNotEmpty) "search": _searchQuery,
  },
);

final response = await http.get(
  uri,
  headers: {"Authorization": token},
);
```

- `apiBaseUrl` = `"https://sindomon.cml-indonesia.com"` (from `lib/config/api_config.dart:5`)
- `_searchQuery` initializes to `""` → `queryParameters` map resolves to `{}` → **no trailing `?`, no stray query params**
- `token` = `prefs.getString("token") ?? ""` (line 46) — falls back to empty string if not stored

### Header Audit

| Request | Header Value | Notes |
|---------|-------------|-------|
| GET (line 56) | `{"Authorization": token}` | `token` is `String` — works, but NO `"Bearer "` prefix |
| DELETE (line 131) | `{"Authorization": token.toString()}` | `token` CAN be `null` here (no `?? ""` on line 126); `.toString()` on null → literal `"null"` |

### API Reachability (host machine)

```bash
# New API (current)
$ curl -w "%{http_code}" https://sindomon.cml-indonesia.com/api/v1/logistik/senjata
401                           # reachable, TLSv1.3, valid cert

# Old API (before refactor)
$ curl -w "%{http_code}" https://sindomon.yoknusantara.com/api/v1/senjata
200                           # reachable
```

**Both servers are reachable from the host machine. `cml-indonesia.com` returns 401 (needs auth), `yoknusantara.com` returns 200.**

### URL History (git diff)

| Version | Domain | Path |
|---------|--------|------|
| Initial (da18822) | `sindomon.yoknusantara.com` | `/api/v1/senjata` |
| After refactor (306ccb7) | `$apiBaseUrl` / `cml-indonesia.com` | `/api/v1/senjata` |
| Current (HEAD) | `$apiBaseUrl` / `cml-indonesia.com` | `/api/v1/logistik/senjata` |

**BOTH domain AND path changed during the refactor.** The `/logistik/` path segment was added in a commit after 306ccb7.

---

## 2. State Management Status

### List Population Flow

```
initState()
  ├── loadUser()       — sets unLogin, roleLabel
  └── getSenjataApi()  — fetches → sets senjataapi (line 63)
                           on success: rawData.cast<Map<String, dynamic>>()
                           on catch:  senjataapi STAYS [] (initial value)
```

### Lifecycle Hooks

| Trigger | Action | Status |
|---------|--------|--------|
| `initState()` | `getSenjataApi()` | ✅ correct |
| After add (line 204) | `if (result == true) getSenjataApi()` | ✅ correct |
| After edit (line 367) | `if (result == true) getSenjataApi()` | ✅ correct |
| After delete (line 145) | `getSenjataApi()` | ✅ correct |
| Search input (line 91) | `_onSearchChanged` → debounce 400ms → `getSenjataApi()` | ✅ correct |

### Issues Found

- **None.** No `senjataapi.clear()`, no `setState(() => senjataapi = [])`, no premature data clearing.
- `catch` block (line 71–78): silently logs error via `debugPrint(e.toString())` and sets `isLoading = false` — list remains `[]`. This is why the table shows **completely empty**: GET fails, exception is caught, `senjataapi` stays as initial `[]`.

### Minor Inconsistencies

- GET header: `{"Authorization": token}` (line 56)
- DELETE header: `{"Authorization": token.toString()}` (line 131)
- DELETE `token` can be `null` (line 126: `prefs.getString("token")` without `?? ""`) — `null.toString()` → `"null"` string sent as auth
- GET `token` defaults to `""` (line 46: `prefs.getString("token") ?? ""`)

---

## 3. Hypothesis: Root Cause of `ClientException: Failed to fetch`

### Critical Context

`ClientException: Failed to fetch` is a **network-level error** from the Dart `http` package (`IOClient.send()`). It wraps `SocketException`, `TlsException`, or `HttpException`. It is **NOT** an HTTP status code response (4xx/5xx are returned as normal `Response` objects).

### Hypotheses (ranked by probability)

#### H1 (Most Likely): DNS Resolution Failure on Emulator/Device

The domain `sindomon.cml-indonesia.com` resolves fine on the host machine (curl works), but the **Android emulator or physical device may not be able to resolve it**. The emulator uses its own DNS (often `10.0.2.3` as the host gateway). If the DNS server used by the emulator cannot resolve `cml-indonesia.com`, every request throws `SocketException: Failed host lookup` → `ClientException`.

**Why after refactor:** The old domain `yoknusantara.com` was in the initial code and presumably resolved correctly. The new domain `cml-indonesia.com` was introduced in commit 306ccb7.

**Verification:**
```dart
// Add this before http.get() in getSenjataApi():
debugPrint("DEBUG URL: $uri");
debugPrint("DEBUG TOKEN LENGTH: ${token.length}");

// Or test on the emulator/device:
// Run: adb shell ping -c 1 sindomon.cml-indonesia.com
```

#### H2 (Likely): Missing "Bearer" Prefix in Authorization Header

Both GET (line 56) and DELETE (line 131) send the token as `{"Authorization": token}` without the `"Bearer "` prefix. If the token stored in SharedPreferences is the raw JWT (e.g., `eyJhbGciOi...`), the server at `cml-indonesia.com` expects `Authorization: Bearer eyJhbGciOi...`. Without the prefix, the server may:
- Return 401 (normal HTTP response — would NOT cause `ClientException`)
- OR: the WAF/API gateway at `cml-indonesia.com` may **drop the connection entirely** for malformed auth headers, causing `ClientException`

**Why after refactor:** The old server (`yoknusantara.com`) may have been more lenient, accepting tokens without the "Bearer" prefix.

**Verification:**
```dart
// In getSenjataApi(), log the raw token:
debugPrint("DEBUG TOKEN: '${token}'");
debugPrint("DEBUG TOKEN starts with Bearer: ${token.startsWith('Bearer')}");
```

**Fix (if confirmed):**
```dart
headers: {"Authorization": "Bearer $token"},
```

#### H3 (Possible): TLS Compatibility — Server Requires TLSv1.3

The `cml-indonesia.com` server negotiated TLSv1.3 with curl. Older Android versions (API < 26) or Android emulators may not support TLSv1.3 and might fail the handshake → `TlsException` → `ClientException`.

**Why after refactor:** The old domain `yoknusantara.com` may have supported TLSv1.2 which works on all Android versions.

**Verification:**
```bash
# Check what TLS versions the server supports:
openssl s_client -connect sindomon.cml-indonesia.com:443 -tls1_2 </dev/null 2>&1 | grep -E "CONNECTED|error|Cipher"
openssl s_client -connect sindomon.cml-indonesia.com:443 -tls1_3 </dev/null 2>&1 | grep -E "CONNECTED|error|Cipher"
```

#### H4 (Possible): Android Release Build Missing INTERNET Permission

The **main** `AndroidManifest.xml` (`android/app/src/main/`) does **NOT** declare `<uses-permission android:name="android.permission.INTERNET"/>`. The INTERNET permission only exists in `debug/` and `profile/` manifests.

- **Debug mode:** ✅ Has INTERNET permission (debug manifest)
- **Release mode:** ❌ Missing INTERNET permission — ALL network requests would fail

If the user accidentally built/ran a release variant, this would cause `ClientException`.

**Fix (if confirmed):** Add `<uses-permission android:name="android.permission.INTERNET"/>` to `android/app/src/main/AndroidManifest.xml`.

#### H5 (Less Likely): `deleteSenjata` DELETE-with-body Corrupting Connection Pool

`deleteSenjata` (line 128–135) sends an `http.delete()` with a JSON body `{"senjata_id": id}` to the EXACT same URL as GET. Some HTTP proxies, CDNs, and WAFs reject DELETE requests with bodies (RFC 7231 doesn't forbid it, but many implementations do). If the server responds abnormally (e.g., closes the connection mid-stream), the `http` package's underlying `HttpClient` may enter a bad state, causing the subsequent `getSenjataApi()` call to fail.

**Why after refactor:** `deleteSenjata` was added during this refactor. Before, there was no delete functionality.

**Note:** This would only manifest AFTER a delete operation. The initial load in `initState()` would still work. If the table is empty on FIRST load (before any delete), this hypothesis is ruled out.

#### H6 (Edge Case): Flutter Web — CORS Blocking

If running as **Flutter Web**, the `http` package delegates to the browser's `fetch()` API. The error message `Failed to fetch` is the **exact browser CORS error message**. If `cml-indonesia.com` doesn't send `Access-Control-Allow-Origin` headers matching the web app's origin, the browser blocks the request entirely — no response, just `TypeError: Failed to fetch`.

**Verification:** Check if running `flutter run -d chrome` or similar.

---

## 4. Diagnostic Action Plan

Execute these in order to narrow down the root cause:

### Step A — Add diagnostic logging (no refactor needed)

In `getSenjataApi()`, right before `http.get()`:

```dart
debugPrint("=== getSenjataApi DEBUG ===");
debugPrint("URL: $uri");
debugPrint("TOKEN: '${token}'");
debugPrint("TOKEN empty: ${token.isEmpty}");
debugPrint("TOKEN has Bearer: ${token.startsWith('Bearer')}");
debugPrint("Platform: ${Theme.of(context).platform}");
```

### Step B — Test from emulator/device directly

```bash
# From host, check if emulator can resolve:
adb shell ping -c 1 sindomon.cml-indonesia.com
adb shell curl -v https://sindomon.cml-indonesia.com/api/v1/logistik/senjata 2>&1
```

### Step C — Check TLS compatibility

```bash
# Test TLSv1.2 support (required for Android < 8)
openssl s_client -connect sindomon.cml-indonesia.com:443 -tls1_2 </dev/null 2>&1 | head -20
```

### Step D — Verify token format

Check `lib/pages/login_page.dart` to see exactly how the token is stored:
```bash
grep -n "setString.*token" lib/pages/login_page.dart
```
This reveals whether the token is stored as `"Bearer xxx"` or just `"xxx"`.

### Step E — Rule out delete side effect

If the table is empty on **first load** (before any user interaction), eliminate H5. The issue is in the initial GET, not a post-delete refresh.

---

## 5. Summary

| Check | Result |
|-------|--------|
| GET URL format | ✅ `https://sindomon.cml-indonesia.com/api/v1/logistik/senjata` — clean |
| Query parameters | ✅ No stray `?` when search is empty |
| State clearing | ✅ No incorrect `senjataapi = []` in code |
| API reachable from host | ✅ Returns 401 (auth needed, but accessible) |
| SSL certificate | ✅ Valid, TLSv1.3 |
| Android INTERNET permission (debug) | ✅ Present in debug manifest |
| Android INTERNET permission (release) | ❌ Missing in main manifest |
| Token Bearer prefix | ⚠️ Not verified — depends on login storage |
| Emulator DNS | ⚠️ Not tested — needs Step B |
| TLSv1.2 support | ⚠️ Not tested — needs Step C |

**Primary suspect:** Domain/DNS change (`yoknusantara.com` → `cml-indonesia.com`) combined with either emulator DNS failure (H1) or token auth format incompatibility (H2).

**Next action:** Run diagnostic Step A + Step D first. They are zero-risk logging additions that will immediately narrow the root cause.
