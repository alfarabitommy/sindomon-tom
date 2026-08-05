# Flutter DELETE Audit — Senjata Table

**Date:** 2026-08-05
**Flutter File:** `lib/pages/senjata.dart`
**Backend:** `application/controllers/Logistik.php` + `application/config/routes.php`

---

## 1. Request Format

Flutter (`deleteSenjata`, lines 123–152 of `senjata.dart`) sends:

```
METHOD:  DELETE
URL:     https://sindomon.cml-indonesia.com/api/v1/logistik/senjata
HEADERS: Authorization: <token>
         Content-Type: application/json
BODY:    {"senjata_id": "<id>"}
```

| Aspect | Value |
|--------|-------|
| ID location | **JSON body** (not URL path) |
| URL path | `/api/v1/logistik/senjata` — no `/<id>` segment |
| Auth | Bearer token in `Authorization` header |
| Response handling | 200 → snackbar + refresh; else → `debugPrint` only |

---

## 2. Hypothesis

### Root Cause: **Backend has no DELETE route. The request hits a 404 or is blocked entirely.**

Backend routes for the Senjata endpoint (`application/config/routes.php`, lines 84–88):

| HTTP method | Route |
|-------------|-------|
| `POST` | `api/v1/logistik/senjata` |
| `GET` | `api/v1/logistik/senjata` |
| `PUT` | `api/v1/logistik/senjata/(:any)` |
| `OPTIONS` | `api/v1/logistik/senjata` |
| `OPTIONS` | `api/v1/logistik/senjata/(:any)` |

**There is no `DELETE` route defined for `api/v1/logistik/senjata`.** The Logistik controller only has `senjata_post`, `senjata_get`, `senjata_put`, and `senjata_options` — no `senjata_delete`.

### Secondary issue: `DELETE` with JSON body

Some HTTP clients and proxies strip or reject `DELETE` request bodies. The HTTP/1.1 spec does not forbid it, but:
- Some web servers/frameworks may ignore the body on DELETE
- CodeIgniter 3 may or may not parse `php://input` for DELETE — depends on config
- The Flutter `http.delete` method accepts a `body` parameter but this is non-standard in practice

However, **the missing backend route is the primary blocker**. Fixing the body issue is irrelevant until a DELETE endpoint exists.

### Additional concern: Silently swallowed errors

In `deleteSenjata` (line 147), non-200 responses only call `debugPrint`. The user gets no feedback. The failure is invisible — explaining the "failing silently" symptom.

---

## 3. What Needs to Happen

1. **Add a DELETE route** in `application/config/routes.php`:
   ```
   $route['api/v1/logistik/senjata/(:any)']['DELETE'] = 'logistik/senjata_delete/$1';
   ```

2. **Add `senjata_delete($id)` method** in `application/controllers/Logistik.php` — accepts ID from URL path.

3. **Fix Flutter** to send `DELETE` to the URL with the ID in the path, not the body:
   ```dart
   Uri.parse("$apiBaseUrl/api/v1/logistik/senjata/$id")
   ```
   Remove the `body:` and `"Content-Type"` header from the `http.delete` call.

4. **Add user-facing error feedback** for non-200 responses (currently only `debugPrint`).
