# Frontend Consumption Guideline — SINDOMON Flutter Client

## 0. Scope & Method

Audited files: `lib/config/api_config.dart`, `lib/widget/login_card.dart`, `lib/utils/session_util.dart`, `lib/pages/{personel,senjata,satwa,amunisi,sarpras,polda,polres,user_page,inventaris,dashboard,master_kategori_senjata,pangaturan}.dart`, `lib/widget/form_input_*.dart`, `lib/models/{polda,dashboard}_model.dart`, `lib/utils/hud_loading.dart`, `lib/widget/app_pagination.dart`, `lib/main.dart`.

The client uses `package:http ^1.2.2` + `package:shared_preferences ^2.5.3`. **There is no HTTP service class, no interceptor, and no request/response model layer** (except two model classes for the dashboard). Every request is constructed inline with raw `http.*` calls.

---

## 1. API Request Architecture

### 1.1 Base URL

Single constant, string-interpolated everywhere (`lib/config/api_config.dart:5`):

```dart
const String apiBaseUrl = "https://sindomon.cml-indonesia.com";
```

Every endpoint is built as `Uri.parse("$apiBaseUrl/api/v1/<resource>")`. Relative image URLs returned by the API are also prefixed with `apiBaseUrl` at render time (`_resolveImageUrl()` in `senjata.dart:143-148`, `satwa.dart:190-195`, `form_inputan_satwa.dart:217-222`).

### 1.2 Timeouts

**None.** No `.timeout()` call exists anywhere in the codebase. All requests use the `package:http` default behavior (no timeout — a hung connection can block indefinitely).

### 1.3 Headers — exact injection matrix

| Request type | Headers actually sent |
|---|---|
| Login (`POST /api/v1/auth/login`) | `Content-Type: application/json` only (`login_card.dart:130`) |
| Authenticated GET / DELETE | `Authorization: <token>` only — **raw JWT, no `Bearer` prefix** (e.g. `personel.dart:57`) |
| JSON POST / PUT (forms) | `Authorization` + `Content-Type: application/json` |
| Multipart POST (file uploads) | `Authorization` only; `Content-Type` is set automatically by `MultipartRequest` |
| **`Accept` header** | **Never sent anywhere** |

Header-case inconsistency worth noting for docs: list pages send `Authorization` (capital A), while `dashboard.dart:57,106,136` sends `authorization` (lowercase). HTTP headers are case-insensitive, so both work, but the codebase is not uniform.

### 1.4 Token retrieval per request

There is no session singleton. **Every call site re-opens SharedPreferences inline:**

```dart
final prefs = await SharedPreferences.getInstance();
final token = prefs.getString("token");
```

Two retrieval variants exist:
- `token ?? ""` — sends an empty string if the token is missing (`senjata.dart:40`, `satwa.dart:41`, `amunisi.dart:40`, `sarpras.dart`, `master_kategori_senjata.dart:52`, multipart forms).
- `token.toString()` — sends the **literal string `"null"`** if the token is missing (`personel.dart`, `polda.dart`, `polres.dart`, `user_page.dart`, JSON forms). A deleted `token` key therefore produces the header `Authorization: null` on those pages.

---

## 2. JWT & Session Management

### 2.1 Login flow (`lib/widget/login_card.dart:128-165`)

- Request: `POST /api/v1/auth/login`, JSON body `{"username": <raw input>, "password": <raw input>}` — values are **not trimmed** before sending.
- On `200`, the code parses the envelope defensively (exact code, lines 138-149):

```dart
final data = jsonDecode(response.body);
final payload = data["data"] as Map<String, dynamic>? ?? {};
final userData = payload["user"] as Map<String, dynamic>? ?? {};

String token      = payload["jwt_token"]?.toString() ?? "";
String usernameLogin = userData["username"]?.toString() ?? "";
String poldaLogin    = userData["polda_id"]?.toString() ?? "";
String roleID        = userData["roles_id"]?.toString() ?? "";
String uuid          = userData["uuid"]?.toString() ?? "";
String expired       = userData["expired"]?.toString() ?? "";
```

> ⚠️ The current code expects `data` and `data.user` as **JSON objects** (with `?? {}` null guards), not `data.user[0]` as an array.

### 2.2 Persisted keys (SharedPreferences)

| Key | Written at login | Read by |
|---|---|---|
| `token` | ✅ | Every authenticated call |
| `username_login` | ✅ | `AppHeader`, `pangaturan.dart` |
| `roleid_login` | ✅ | `AppSidebar`, `dashboard.dart`, personel form (role lock), `pangaturan.dart` |
| `polda_login` | ✅ | Personel/senjata/amunisi forms (operator lock), `pangaturan.dart` |
| `uuid_login` | ✅ | **Never read** |
| `expired_login` | ✅ | **Never read** |

### 2.3 Token expiry reaction

**There is no token expiry handling.** Specifically:
- No startup auth check — `main.dart` always boots to `LoginPage`.
- `expired_login` is stored but never parsed or compared.
- **No HTTP 401 handling exists anywhere** (`401` has zero matches in `lib/`). See §4.1 — the premise that 401 triggers a "Force Logout" does **not** hold in this codebase.
- No token refresh logic.

### 2.4 Manual logout

`clearSessionAndLogout()` in `lib/utils/session_util.dart:18-27` → `prefs.clear()` (clears **all** SharedPreferences, including `theme_mode`) → `Navigator.pushAndRemoveUntil(LoginPage, (route) => false)`. Triggered only from the profile menus (`app_header.dart:30`, `dashboard.dart:295`).

---

## 3. Response Parsing & Safety

### 3.1 The envelope is never validated

No code checks the top-level `status` key of `{ status, message, data }` (zero reads of `json["status"]` for API responses). `message` is consumed only in mutation/delete responses as SnackBar text. GET responses ignore `message` entirely.

### 3.2 Paginated list parsing (10 list pages — identical block)

Exact pattern from `personel.dart:60-93` (duplicated in polda, polres, user_page, senjata, satwa, amunisi, sarpras, master_kategori_senjata):

```dart
final json = jsonDecode(response.body);
final data = json["data"];
// New backend shape: { data: { items: [...], pagination: {...} } }.
// Tolerates the legacy flat-list shape as a fallback.
final List rawList = data is Map
    ? (data["items"] is List ? data["items"] : [])
    : (data is List ? data : []);
final Map<String, dynamic> pagination = data is Map && data["pagination"] is Map
    ? data["pagination"] as Map<String, dynamic>
    : <String, dynamic>{};
final parsedItems = rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
```

Safeguards against empty/missing `data`:

| Payload edge case | Behavior |
|---|---|
| `data` missing / null | `rawList = []`, empty `pagination` map → empty table, page defaults |
| `data: {}` (empty object) | `data["items"]` not a List → `rawList = []` |
| `data: []` (empty array, legacy shape) | `rawList = []` |
| `pagination` missing | `totalPages = 1`, `totalItems = parsedItems.length`, `perPage` keeps current value (10) |
| Item is not a JSON object | `e as Map` throws → caught by outer try/catch → page-level error state |
| Body is not a JSON object / malformed | `jsonDecode` cast to `Map<String, dynamic>` throws → caught by try/catch |

`master_kategori_senjata.dart:67-80` adds one extra guard: a snapshot of `_currentPage`/`_searchQuery` is taken before the request and stale responses (page/search changed mid-flight) are silently discarded.

### 3.3 Other parsing styles (documented per-call-site)

- **Dropdown fetches** (`GET /api/v1/polda`, `/pangkat`, `/jabatan`, `/master/kategori-senjata` in forms): `List<Map<String, dynamic>>.from(body['data'])` — throws if `data` is not a List; caught and only `debugPrint`ed (silent failure, dropdown stays empty). `form_input_user.dart:123` adds `?? []`.
- **Dashboard `/nasional` + `/drilldown`** (`dashboard_model.dart`): strongly typed via **total (never-throwing) factory functions** — `_asMap`, `_toInt`, `_toStr`, `_toBool`, `_mapList`. Any null/wrong-type input yields a default instance (0 / '' / false / empty list); the `!` operator is documented as banned in that file.
- **Dashboard `GET /api/v1/polda`** (`dashboard.dart:62`): direct cast `json["data"] as List` → `Polda.fromJson(...)` — throws on non-List (caught, loading stops).
- **Profile** (`pangaturan.dart:46`): `json["data"] as Map<String, dynamic>? ?? {}`.

---

## 4. Error Handling & UX Mapping

### 4.1 ⚠️ HTTP 401 → Force Logout: **NOT IMPLEMENTED**

This is the single most important finding for your documentation. **There is no 401 branch anywhere in the codebase.** If the backend returns 401 (expired/invalid token), the frontend:

- On list GETs: falls into the generic non-200 `else` → inline error panel `"Gagal memuat data (HTTP 401)"` (personel/polda/polres/master_kategori) or silent spinner-stop with an empty table (senjata/satwa/amunisi/sarpras/user_page).
- On mutations: generic red SnackBar.
- The user is **never** redirected to login, and the token is **never** cleared, by any server response.

### 4.2 HTTP 422 → inline form errors: **only one implementation, and it is not field-level**

422 is handled in exactly one place: `form_input_personel.dart:268-278` (personel create/edit only):

```dart
} else if (response.statusCode == 422) {
  HudLoading.hide(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(result["message"] ?? "Validasi data gagal"),
      backgroundColor: Colors.red,
    ),
  );
}
```

Behavior: red SnackBar showing the backend's top-level `message` string, **stays on the form** (no `Navigator.pop`). No form maps a 422 `errors` object onto individual fields; no other entity (polda, polres, user, senjata, satwa, amunisi, sarpras, kategori) distinguishes 422 at all.

### 4.3 Full status-code → UI mapping table (as actually coded)

| Status | Where | UI reaction |
|---|---|---|
| **200** | All GETs | Render data. Forms: green SnackBar with backend `message` (fallback to hardcoded text), then `Navigator.pop(context, true)` |
| **201** | Create forms (personel, polda, polres, user, amunisi, senjata, satwa, sarpras, kategori) | Treated identically to 200 |
| **204** | — | **Never checked** — DELETE success is asserted as `== 200`; a 204 would fall into the failure branch |
| **403** | `login_card.dart:166-184` only | **`AlertDialog`** "Akses Diblokir" — "Perangkat Anda belum terverifikasi. Sesi login diblokir. Silahkan hubungi Super Admin Mabes." with "Tutup" button. Nowhere else |
| **409** | `master_kategori_senjata.dart:436-447` only (delete) | Orange SnackBar: "Kategori tidak dapat dihapus karena masih digunakan oleh data Senjata atau Amunisi" |
| **422** | `form_input_personel.dart:268` only | Red SnackBar with backend `message`, stay on form (see §4.2) |
| **401 / 500 / any other** | All call sites | Generic non-200 branch — see §4.1 |

### 4.4 UI components and their color conventions

- **SnackBars** — `ScaffoldMessenger.of(context).showSnackBar(...)`:
  - `Colors.green` — success (except deletes on senjata/satwa/amunisi/sarpras pages, which use **`Colors.red` for a *successful* delete** — a known inconsistency, e.g. `senjata.dart:222-227`).
  - `Colors.red` — generic failures; also login-card errors use `Color(0xFFEF4444)` with floating behavior, rounded corners, and an `error_outline` icon.
  - `Colors.orange` — delete failure (senjata/satwa/sarpras/amunisi), network errors on multipart forms, 409 conflict, client-side "Lengkapi semua data bertanda *" validation.
- **AlertDialogs** — 403 login block; delete confirmations (`showDialog<bool>` "Apakah Anda yakin ingin menghapus …?" with red "Hapus" button on personel/user, plain on senjata).
- **Blocking HUD** — `HudLoading.show(context, label:)` (labels `"MENGOTENTIKASI..."`, `"MENYIMPAN..."`, `"MENGHAPUS..."`) is a full-screen, non-dismissible dialog shown before mutations and paired with `HudLoading.hide()` on every exit path. Exceptions: `form_input_amunisi.dart` submits **without** any HUD; `user_page.dart` deletes without HUD.
- **Inline page error state** — only personel/polda/polres/master_kategori list pages: `Icons.error_outline` + message + amber "Coba Lagi" retry button. The logistik pages (senjata/satwa/amunisi/sarpras) and user page fail **silently** (spinner stops, empty table).
- **Dashboard drilldown** — non-200 `throw Exception("drilldown HTTP <code>")` → `FutureBuilder` renders a HUD-styled error panel (`dashboard.dart:138-139, 861-866`).

### 4.5 Error-body decoding hazards (document these for the backend team)

- Many mutation `else` branches call `jsonDecode(response.body)` **unconditionally** — if the backend returns an HTML error page or an empty body with a non-2xx status, the decode throws and the user sees a generic "Terjadi kesalahan jaringan" (network) message that misrepresents a server-side error.
- `master_kategori_senjata.dart:474-482` is the only call site with a safe error-body parser (`_parseErrorMessage`, try/catch around `jsonDecode`).

---

## 5. Data Contracts: Pagination

### 5.1 Request side

Query parameters sent on every list GET (`Uri.replace(queryParameters: params)`):

| Param | Value | Notes |
|---|---|---|
| `page` | `String` of `_currentPage` (1-based, starts at 1) | always sent |
| `limit` | `String` of `_perPage` (default `"10"`) | always sent |
| `search` | raw search text | **only appended when non-empty**; 400 ms debounce; every search resets `page` to 1 |

### 5.2 Response side — two accepted shapes

```jsonc
// Preferred ("new backend shape", per in-code comments):
{ "status": ..., "message": ..., "data": {
    "items": [ ... ],
    "pagination": { "current_page": 1, "last_page": 3, "total": 25, "per_page": 10 }
}}
// Legacy fallback:
{ "data": [ ... ] }
```

### 5.3 Pagination key parsing (exact precedence, `personel.dart:82-93` and peers)

| UI field | Parse order | Default |
|---|---|---|
| current page | `pagination["current_page"]` | unchanged `_currentPage` |
| total pages | `pagination["last_page"]` **then** `pagination["total_pages"]` | `1` |
| total items | `pagination["total"]` | `parsedItems.length` |
| per page | `pagination["per_page"]` **then** `pagination["limit"]` | keeps current `_perPage` (10) |

All values are tolerant: `(value as num?)?.toInt()` — accepts int or double; a string value would silently fall to the default. The `AppPagination` widget is fully wired to these values (prev/next/numbered buttons trigger refetch). Note the widget computes its "Menampilkan X hingga Y dari Z data" label from `totalItems`/`perPage`, so a missing `total` yields a display capped at the current page's item count.

---

## 6. Data Contracts: File Uploads

### 6.1 Which forms upload files

Only three: **senjata**, **satwa**, **sarpras** (`form_input_senjata.dart`, `form_inputan_satwa.dart`, `form_input_sarpras.dart`). `form_inputan_inventaris.dart` picks an image but its Submit button is `onPressed: () {}` — no upload is wired. **No base64 encoding exists anywhere.**

### 6.2 Client-side pipeline (identical in all three)

1. `ImagePicker().pickImage(source: camera|gallery, imageQuality: 85)`.
2. `file.readAsBytes()` → `FlutterImageCompress.compressWithList(bytes, minWidth: 1280, minHeight: 1280, quality: 80, format: CompressFormat.webp)` — falls back to original bytes if compression throws/returns empty (desktop platforms).
3. Multipart transmission.

### 6.3 Wire format (exact)

```dart
final request = http.MultipartRequest("POST", uri);
request.headers["Authorization"] = token;
request.fields["<field>"] = "<value>";           // plain text fields
request.files.add(http.MultipartFile.fromBytes(
  "foto",                                        // file part name is ALWAYS "foto"
  _imageBytes!,
  filename: "<entity>_<epochMilliseconds>.webp",
));
final streamed = await request.send();
final response = await http.Response.fromStream(streamed);
```

Key contract facts for the backend:
- **Method is always `POST`** — including edit mode. In-code rationale (e.g. `form_input_sarpras.dart:200-202`): *"PHP cannot parse multipart/form-data on PUT — always send POST"* (CI3 routes map `POST /sarpras/(:any)` to update). There is no `_method` spoofing; **the record ID travels in the URL path**: `POST /api/v1/logistik/senjata/{senjata_id}` for edit, `POST /api/v1/logistik/senjata` for create.
- Text fields per entity: senjata → `polda_id, nomor_seri, kategori_id, tahun_pengadaan, status_kelayakan` (hardcoded `"Baik"`); satwa → `nomor_registrasi, jenis_satwa, nama_satwa, nama_handler, kualifikasi, jadwal_vaksin` (date as `yyyy-MM-dd`); sarpras → `kode_barang, nama_barang, kategori, kondisi, tahun_pengadaan` (year as string).
- **Edit without a newly picked image omits the file part entirely** — the backend must keep the existing photo when `foto` is absent.
- Success asserted as `200 || 201`; the success SnackBar text is **hardcoded client-side** (the multipart forms do not read backend `message`).
- Image display on list pages: `foto_fisik ?? foto_url` (senjata) / `foto_url ?? foto_satwa ?? foto` (satwa), resolved to absolute via `apiBaseUrl` prefix and rendered with `CachedNetworkImage`.

---

## 7. Complete Endpoint Inventory (as consumed by the client)

| Method | Path | Payload | Used by |
|---|---|---|---|
| POST | `/api/v1/auth/login` | JSON `{username, password}` | login |
| GET | `/api/v1/user` | qs: `page, limit, search?` | user list |
| POST / PUT | `/api/v1/user` / `/api/v1/user/{id}` | JSON `{username, roles_id, status, polda_id?, password?}` | user form |
| DELETE | `/api/v1/user/{id}` | — | user list |
| GET | `/api/v1/sdm/personil` | qs: `page, limit, search?` | personel list |
| POST / PUT | `/api/v1/sdm/personil` / `/api/v1/sdm/personil/{uuid}` | JSON `{nrp, nama_lengkap, polda_id, polres_id?, pangkat_id, jabatan_id}` | personel form |
| DELETE | `/api/v1/sdm/personil/{uuid}` | — | personel list |
| GET | `/api/v1/polda` | — (flat list, no pagination) | dropdowns (personel/senjata/amunisi/polres/user forms) + dashboard role-3 |
| GET | `/api/v1/master/polda` | qs: `page, limit, search?` | polda list |
| POST / PUT | `/api/v1/master/polda` / `/api/v1/master/polda/{id}` | JSON `{nama_polda, latitude, longitude}` | polda form |
| DELETE | `/api/v1/master/polda/{id}` | — | polda list |
| GET | `/api/v1/master/polres` | qs: `page, limit, search?` | polres list |
| POST / PUT | `/api/v1/master/polres` / `/api/v1/master/polres/{id}` | JSON `{polda_id, nama_polres}` | polres form |
| DELETE | `/api/v1/master/polres/{id}` | — | polres list |
| GET | `/api/v1/master/kategori-senjata` | qs: `page, limit, search?` (also flat for dropdowns) | kategori page + senjata/amunisi forms |
| POST / PUT | `/api/v1/master/kategori-senjata` / `/{id}` | JSON `{tipe_laras, kaliber}` | kategori page |
| DELETE | `/api/v1/master/kategori-senjata/{id}` | — | kategori page (409-aware) |
| GET | `/api/v1/logistik/senjata` | qs: `page, limit, search?` | senjata list |
| POST | `/api/v1/logistik/senjata` or `/api/v1/logistik/senjata/{id}` | **multipart** (fields + `foto`) | senjata form (create AND edit) |
| DELETE | `/api/v1/logistik/senjata/{id}` | — | senjata list |
| GET | `/api/v1/logistik/satwa` | qs: `page, limit, search?` | satwa list |
| POST | `/api/v1/logistik/satwa` or `/api/v1/logistik/satwa/{id}` | **multipart** | satwa form |
| DELETE | `/api/v1/logistik/satwa/{id}` | — | satwa list |
| GET | `/api/v1/logistik/sarpras` | qs: `page, limit, search?` | sarpras list |
| POST | `/api/v1/logistik/sarpras` or `/api/v1/logistik/sarpras/{id}` | **multipart** | sarpras form |
| DELETE | `/api/v1/logistik/sarpras/{id}` | — | sarpras list |
| GET | `/api/v1/logistik/amunisi` | qs: `page, limit, search?` | amunisi list |
| POST / PUT | `/api/v1/logistik/amunisi` / `/api/v1/logistik/amunisi/{batch_id}` | JSON `{polda_id, kode_batch, kategori_id, jumlah_butir, tanggal_masuk, tanggal_kedaluwarsa}` | amunisi form |
| DELETE | `/api/v1/logistik/amunisi/{id}` | — | amunisi list |
| GET | `/api/v1/dashboard/nasional` | — | command-center dashboard |
| GET | `/api/v1/dashboard/drilldown?polda_id={id}` | — | map marker drilldown |
| GET | `/api/v1/profile` | — | pengaturan page |
| GET | `/api/v1/pangkat`, `/api/v1/jabatan` | — (flat `data` lists) | personel form dropdowns |

**Not API-backed:** `inventaris.dart` (hardcoded local list), the device-binding card on `pangaturan.dart` (static "Perangkat Terverifikasi"), and `report`-style content (no `report.dart` exists in `lib/pages/`).

---

## 8. Contract Requirements Implied for the Backend

Extracted constraints the backend must honor so the current frontend keeps working:

1. **Every authenticated response must accept the header `Authorization: <jwt>`** with no `Bearer` prefix — this exact format is sent by all 30+ call sites.
2. **DELETE success must return HTTP 200** (frontend checks `== 200`, never 204).
3. Create operations may return **200 or 201**; forms accept both.
4. List endpoints must keep tolerating either `data: {items, pagination}` or legacy `data: [...]` — the frontend auto-detects, but the pagination block defaults silently if keys are missing (see §5.3 precedence, including the `last_page` → `total_pages` fallback order).
5. Multipart endpoints must accept **POST with the ID in the URL path** for updates, file part named `foto`, and an omitted `foto` meaning "keep existing".
6. Error responses should return JSON with a top-level `message`; several call sites `jsonDecode` error bodies unconditionally and will mislabel non-JSON errors as network failures.
7. `data` values for login (`jwt_token`, `user.username/roles_id/polda_id/uuid/expired`) are read with null-fallback — but **if `data` is absent, login still "succeeds" with an empty token** and navigates to the dashboard (`login_card.dart:141-165` has no token-presence validation).
8. **No status-code security net exists client-side**: 401 is not intercepted (no forced logout), and 403/409/422 handling is limited to the single call sites listed in §4.3. If your API documentation promises "401 → automatic force logout" or "422 → inline form errors", that behavior does not exist in the current frontend and the documentation should reflect the actual behavior above (or the frontend must be changed).
