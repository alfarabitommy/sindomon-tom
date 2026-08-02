# API Migration Plan: `sindomon.yoknusantara.com` → `sindomon.cml-indonesia.com`

> **Status:** AWAITING APPROVAL  
> **Date:** 2026-08-01  
> **Target:** All Dart files under `lib/`

---

## 1. Current State Audit

### (a) Protocol

**Answer: `https://`**

Every single occurrence of the old URL in the codebase uses `https://sindomon.yoknusantara.com`. There are zero `http://` references. The app communicates with the backend exclusively over TLS.

### (b) Routing Structure

**Answer: Clean paths — no `index.php` in any endpoint.**

Every endpoint follows the pattern:

```
https://<host>/api/v1/<resource>
```

Concrete examples found in the codebase:

| Resource | Full URL |
|---|---|
| Auth (login) | `https://sindomon.yoknusantara.com/api/v1/auth/login` |
| Polda | `https://sindomon.yoknusantara.com/api/v1/polda` |
| Polres | `https://sindomon.yoknusantara.com/api/v1/polres` |
| Personel | `https://sindomon.yoknusantara.com/api/v1/personel` |
| Senjata | `https://sindomon.yoknusantara.com/api/v1/senjata` |
| Kategori Senjata | `https://sindomon.yoknusantara.com/api/v1/kategori_senjata` |
| Pangkat | `https://sindomon.yoknusantara.com/api/v1/pangkat` |
| Jabatan | `https://sindomon.yoknusantara.com/api/v1/jabatan` |
| User | `https://sindomon.yoknusantara.com/api/v1/user` |

There is **no `index.php`** segment anywhere in the URL paths.

### (c) Storage Pattern

**Answer: Dangerously hardcoded across 11 files — no centralized configuration.**

The base URL `https://sindomon.yoknusantara.com` is repeated verbatim **21 times** across **11 Dart files**. There is no `api_config.dart`, no `constants.dart` with a `baseUrl`, and no environment-variable injection. The `lib/config/` directory exists but only contains `menu_config.dart` (sidebar navigation), which has no URL definitions.

**Affected files (21 hardcoded occurrences):**

| # | File | Occurrences | HTTP Methods |
|---|---|---|---|
| 1 | `lib/widget/login_card.dart` | 1 | POST |
| 2 | `lib/pages/dashboard.dart` | 1 | GET |
| 3 | `lib/pages/personel.dart` | 2 | GET, DELETE |
| 4 | `lib/pages/senjata.dart` | 2 | GET, DELETE |
| 5 | `lib/pages/polda.dart` | 2 | GET, DELETE |
| 6 | `lib/pages/polres.dart` | 2 | GET, DELETE |
| 7 | `lib/pages/user_page.dart` | 1 | GET |
| 8 | `lib/widget/form_input_personel.dart` | 4 | GET (polda, pangkat, jabatan), POST |
| 9 | `lib/widget/form_input_polda.dart` | 1 | POST |
| 10 | `lib/widget/form_input_polres.dart` | 2 | GET (polda), POST |
| 11 | `lib/widget/form_input_senjata.dart` | 3 | GET (polda, kategori_senjata), POST |

**Files with NO hardcoded URLs** (placeholders or not yet wired to backend):
- `lib/widget/form_inputan_inventaris.dart`
- `lib/widget/form_inputan_satwa.dart`
- `lib/widget/form_input_user.dart`
- `lib/pages/satwa.dart`
- `lib/pages/inventaris.dart`

---

## 2. Refactor Plan

### Step 1 — Create centralized API config

Create a new file:

```
lib/config/api_config.dart
```

It will export a single constant:

```dart
const String apiBaseUrl = "https://sindomon.cml-indonesia.com";
```

This gives us a single source of truth. Any future URL changes require editing only this one file.

### Step 2 — Replace hardcoded URLs in all 11 files

For each file below, replace every occurrence of:

```
Uri.parse("https://sindomon.yoknusantara.com/api/v1/<endpoint>")
```

with:

```dart
Uri.parse("$apiBaseUrl/api/v1/<endpoint>")
```

(plus the corresponding `import 'package:sindomon/config/api_config.dart';` at the top.)

**Files to modify (in recommended order):**

| Order | File | Endpoints affected |
|---|---|---|
| 1 | `lib/config/api_config.dart` | **NEW FILE** — defines `apiBaseUrl` |
| 2 | `lib/widget/login_card.dart` | `auth/login` |
| 3 | `lib/pages/dashboard.dart` | `polda` |
| 4 | `lib/pages/personel.dart` | `personel` |
| 5 | `lib/pages/senjata.dart` | `senjata` |
| 6 | `lib/pages/polda.dart` | `polda` |
| 7 | `lib/pages/polres.dart` | `polres` |
| 8 | `lib/pages/user_page.dart` | `user` |
| 9 | `lib/widget/form_input_personel.dart` | `polda`, `pangkat`, `jabatan`, `personel` |
| 10 | `lib/widget/form_input_polda.dart` | `polda` |
| 11 | `lib/widget/form_input_polres.dart` | `polda`, `polres` |
| 12 | `lib/widget/form_input_senjata.dart` | `polda`, `kategori_senjata`, `senjata` |

Total: **1 new file + 11 file modifications**, touching **21 string replacements**.

### Step 3 — Verify

After all replacements, run:

```bash
grep -rn "sindomon.yoknusantara.com" lib/
```

Expected output: **zero matches**.

---

## 3. Backend Alert

### `.htaccess` configuration IS required on the new cPanel server

**Reasoning:**

The app currently hits clean URLs like:

```
https://sindomon.yoknusantara.com/api/v1/auth/login
```

There is **no `index.php`** segment in any path. This means the current production server already has URL rewriting in place — almost certainly an `.htaccess` file that strips `index.php` from the request URI (standard CodeIgniter 3 / Laravel-style rewrite).

**What you must do on the new server (`sindomon.cml-indonesia.com`):**

1. **Verify the backend framework.** The clean-URL pattern strongly suggests CodeIgniter 3 or a similar PHP framework. Confirm this with your backend team.

2. **Copy or recreate the `.htaccess`** from the old server's `public_html` (or equivalent web root). The typical CI3 rewrite looks like:

   ```apache
   RewriteEngine On
   RewriteCond %{REQUEST_FILENAME} !-f
   RewriteCond %{REQUEST_FILENAME} !-d
   RewriteRule ^(.*)$ index.php/$1 [L]
   ```

3. **Ensure `mod_rewrite` is enabled** on the new cPanel account.

4. **Test the new URL directly** before switching the Flutter app:

   ```bash
   curl -X POST https://sindomon.cml-indonesia.com/api/v1/auth/login \
     -H "Content-Type: application/json" \
     -d '{"username":"test","password":"test"}'
   ```

   If this returns a 404 or a redirect loop, the `.htaccess` is not configured correctly.

5. **CORS headers** — verify the new server includes the same `Access-Control-Allow-Origin` headers as the old one, otherwise the Flutter web build (if any) will break.

---

**⏳ AWAITING YOUR REVIEW.** Reply with **"APPROVE"** to begin the refactor, or add specific instructions.
