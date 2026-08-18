# Flutter Frontend Data Payload & Relational Mapping Audit

> **Audit Date:** 2025-07-17  
> **App:** SINDOMON (Police Resource Management)  
> **Base URL:** `https://sindomon.cml-indonesia.com`  
> **Auth:** Header `Authorization: <token>` (no "Bearer" prefix)  
> **Response Envelope:** `{ "data": ..., "message": "..." }`  
> **Paginated Shape:** `{ "data": { "items": [...], "pagination": { "current_page", "last_page", "total", "per_page" } } }` (legacy flat-list fallback tolerated)

---

## 1. ENTITY: Personel (SDM)

### 1.1 API Endpoints

| Method | URL | Purpose |
|--------|-----|---------|
| `GET` | `/api/v1/sdm/personil?page=&limit=&search=` | List (paginated + search) |
| `POST` | `/api/v1/sdm/personil` | Create |
| `PUT` | `/api/v1/sdm/personil/:personil_id` | Update |
| `DELETE` | `/api/v1/sdm/personil/:personil_id` | Delete |

### 1.2 POST/PUT Payload (JSON)

```json
{
  "nrp":             "string  — required",
  "nama_lengkap":    "string  — required",
  "polda_id":        "int     — required",
  "polres_id":       "int|null — optional (null = 'Tidak Ada / Mako Polda')",
  "pangkat_id":      "int     — required",
  "jabatan_id":       "int     — required"
}
```

- `polres_id` sentinel `0` in UI maps to `null` in the JSON body.
- Content-Type: `application/json` for both POST and PUT.

### 1.3 GET Response — Expected Keys (list table)

| Column Key | Type | Notes |
|------------|------|-------|
| `personil_id` | int/string | Primary key; used for edit/delete URL param |
| `nrp` | string | |
| `nama_lengkap` | string | |
| `polda_id` | int | FK — fallback when `nama_polda` absent |
| `nama_polda` | string | Denormalized join — preferred display |
| `polres_id` | int? | FK — fallback when `nama_polres` absent |
| `nama_polres` | string? | Denormalized join — preferred display; nil → "Tidak Ada / Mako Polda" |
| `pangkat_id` | int | FK — fallback when `nama_pangkat` absent |
| `nama_pangkat` | string | Denormalized join — preferred display |
| `jabatan_id` | int | FK — fallback when `nama_jabatan` absent |
| `nama_jabatan` | string | Denormalized join — preferred display |
| `status_aktif` | string | Displayed directly |

### 1.4 Dropdown Dependencies

```
Personel Form
├── Polda       ← GET /api/v1/polda   (returns list with NESTED "polres" array per polda)
│   └── Polres  ← filtered client-side from selected Polda's polres[].polres_id / nama_polres
├── Pangkat     ← GET /api/v1/pangkat   (returns [{pangkat_id, nama_pangkat}])
└── Jabatan     ← GET /api/v1/jabatan   (returns [{jabatan_id, nama_jabatan}])
```

**Key cascading logic:**
- Selecting a Polda triggers a client-side filter: `daftarPolres = selectedPolda["polres"]`  
- The Polda dropdown is **locked** (disabled) for role `"2"` (Operator Polda) — it is force-set to the operator's own Polda from `polda_login` in SharedPreferences.

### 1.5 Required vs Optional in UI

| Field | UI Label | Required |
|-------|----------|----------|
| `nrp` | "NRP *" | YES |
| `nama_lengkap` | "Nama Lengkap *" | YES |
| `polda_id` | "Polda *" | YES |
| `polres_id` | "Polres" | NO (has "Tidak Ada / Mako Polda" option) |
| `pangkat_id` | "Pangkat *" | YES |
| `jabatan_id` | "Jabatan *" | YES |

---

## 2. ENTITY: Senjata (Weapons)

### 2.1 API Endpoints

| Method | URL | Purpose |
|--------|-----|---------|
| `GET` | `/api/v1/logistik/senjata?page=&limit=&search=` | List |
| `POST` | `/api/v1/logistik/senjata` | Create (multipart) |
| `POST` | `/api/v1/logistik/senjata/:senjata_id` | Update (multipart — **NOT PUT**, PHP limitation) |
| `DELETE` | `/api/v1/logistik/senjata/:senjata_id` | Delete |

### 2.2 POST/PUT Payload (Multipart Form-Data)

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `polda_id` | int (string in form) | YES | Dropdown — disabled (pre-filled from session; onChanged: null) |
| `nomor_seri` | string | YES | |
| `kategori_id` | int (string in form) | YES | |
| `tahun_pengadaan` | string (year) | YES | Keyboard type: number |
| `status_kelayakan` | string | HARDCODED | Always `"Baik"` — no UI toggle |
| `foto` | multipart file (WebP) | YES (create) / optional (edit) | Compressed to WebP 80% quality, 1280×1280 min. Filename: `senjata_<timestamp>.webp` |

- **Critical:** ALWAYS uses `POST` method even for edits. The ID goes in the URL path (`/senjata/:id`), never in the body. This is a workaround for PHP's inability to parse `multipart/form-data` on PUT requests.

### 2.3 GET Response — Expected Keys

| Column Key | Type | Notes |
|------------|------|-------|
| `senjata_id` | int/string | PK; used for edit/delete URL |
| `nomor_seri` | string | Monospace display |
| `kategori` | nested object | `{ kategori_id, tipe_laras, kaliber }` — rendered as "tipe_laras - kaliber" |
| `kategori_id` | int | Flat fallback |
| `tahun_pengadaan` | string/int | |
| `polda_id` | int | |
| `foto_fisik` | string | Image URL (preferred key) |
| `foto_url` | string | Image URL (fallback key) |

Image URL resolution: if relative, prepend `apiBaseUrl` with proper `/` insertion.

### 2.4 Dropdown Dependencies

```
Senjata Form
├── Polda        ← GET /api/v1/polda   (disabled — auto-set from session polda_login)
└── Kategori     ← GET /api/v1/master/kategori-senjata   (returns [{kategori_id, tipe_laras, kaliber}])
```

No cascading relationship between these two dropdowns.

### 2.5 Required vs Optional in UI

| Field | UI Label | Required |
|-------|----------|----------|
| `polda_id` | "Polda *" | YES (locked/auto-filled) |
| `nomor_seri` | "No Seri *" | YES |
| `kategori_id` | "Kategori Senjata *" | YES |
| `tahun_pengadaan` | "Tahun Pengadaan *" | YES |
| `foto` | "Foto Senjata *" | YES on create, optional on edit |

---

## 3. ENTITY: Satwa (K9 & Turangga)

### 3.1 API Endpoints

| Method | URL | Purpose |
|--------|-----|---------|
| `GET` | `/api/v1/logistik/satwa?page=&limit=&search=` | List |
| `POST` | `/api/v1/logistik/satwa` | Create (multipart) |
| `POST` | `/api/v1/logistik/satwa/:satwa_id` | Update (multipart — NOT PUT) |
| `DELETE` | `/api/v1/logistik/satwa/:satwa_id` | Delete |

### 3.2 POST/PUT Payload (Multipart Form-Data)

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `nomor_registrasi` | string | YES | |
| `jenis_satwa` | string enum | YES | `"K9"` or `"Turangga"` |
| `nama_satwa` | string | YES | |
| `nama_handler` | string | YES | Text input (not a number — this was a bug fix) |
| `kualifikasi` | string enum | YES | Hardcoded list (see below) |
| `jadwal_vaksin` | string date | YES | Format: `YYYY-MM-DD` |
| `foto` | multipart file (WebP) | YES (create) / optional (edit) | Same compression as Senjata |

**Hardcoded `kualifikasi` options (client-side enum):**
`Narkotika`, `Handak`, `Dalmas`, `Kriminal Umum`, `Patroli`, `Pelacak`

### 3.3 GET Response — Expected Keys

| Column Key | Type | Notes |
|------------|------|-------|
| `satwa_id` | int/string | PK |
| `nomor_registrasi` / `no_registrasi` | string | Dual-key fallback |
| `jenis_satwa` / `jenis` | string | Dual-key fallback; may arrive as nested object |
| `nama_satwa` / `nama` | string | Dual-key fallback |
| `nama_handler` | string | |
| `kualifikasi` | string | May arrive as nested object |
| `jadwal_vaksin` | string date | Urgent flag: < 30 days from today → red vaccine icon |
| `foto_url` / `foto_satwa` / `foto` | string | Triple-key fallback for image URL |

Edit mode init handles both flat string values and nested `{nama_jenis, jenis_satwa}` Map objects for `jenis_satwa` and `kualifikasi` — the backend may return eager-loaded objects.

### 3.4 Dropdown Dependencies

**None.** Both `jenis_satwa` and `kualifikasi` are hardcoded `const` lists in the widget. No API calls populate them.

### 3.5 Required vs Optional in UI

| Field | UI Label | Required |
|-------|----------|----------|
| `nomor_registrasi` | "Nomor Registrasi *" | YES |
| `jenis_satwa` | "Jenis Satwa *" | YES |
| `nama_satwa` | "Nama Satwa *" | YES |
| `nama_handler` | "Nama Handler *" | YES |
| `kualifikasi` | "Kualifikasi *" | YES |
| `jadwal_vaksin` | "Jadwal Vaksin *" | YES |
| `foto` | "Foto Satwa *" | YES on create, optional on edit |

---

## 4. ENTITY: Amunisi (Ammunition)

### 4.1 API Endpoints

| Method | URL | Purpose |
|--------|-----|---------|
| `GET` | `/api/v1/logistik/amunisi?page=&limit=&search=` | List |
| `POST` | `/api/v1/logistik/amunisi` | Create (JSON) |
| `PUT` | `/api/v1/logistik/amunisi/:batch_id` | Update (JSON) |
| `DELETE` | `/api/v1/logistik/amunisi/:batch_id` | Delete |

### 4.2 POST/PUT Payload (JSON)

```json
{
  "polda_id":              "int    — sent as int, but validation missing in UI",
  "kode_batch":            "string — sent as-is (may be empty — no validation)",
  "kategori_id":           "int    — sent as int (no validation)",
  "jumlah_butir":          "int    — parsed via int.tryParse()",
  "tanggal_masuk":         "string — YYYY-MM-DD",
  "tanggal_kedaluwarsa":   "string — YYYY-MM-DD"
}
```

**⚠️ Validation gap:** The submit function only validates dates (`tanggal_masuk` and `tanggal_kedaluwarsa` are checked for null and order). `kode_batch`, `polda_id`, `kategori_id`, and `jumlah_butir` have NO client-side validation — empty values are sent through.

### 4.3 GET Response — Expected Keys

| Column Key | Type | Notes |
|------------|------|-------|
| `batch_id` | int/string | PK; used for edit/delete URL |
| `kode_batch` | string | Monospace display |
| `kategori` | nested object | `{ kategori_id, tipe_laras, kaliber }` — rendered as "tipe_laras - kaliber" |
| `kategori_id` | int | Flat fallback |
| `jumlah_butir` | int | Formatted with thousand separators |
| `tanggal_masuk` | string date | |
| `tanggal_kedaluwarsa` | string date | |
| `is_h90_alert` | bool (true/1) | Drives H-90 status badge |

### 4.4 Dropdown Dependencies

```
Amunisi Form
├── Polda        ← GET /api/v1/polda   (disabled — auto-set from session, onChanged: null)
└── Kategori     ← GET /api/v1/master/kategori-senjata   (same endpoint as Senjata)
```

### 4.5 Required vs Optional in UI

| Field | UI Label | Required (UI) | Actually Validated |
|-------|----------|---------------|---------------------|
| `polda_id` | "Polda *" | YES | NO |
| `kode_batch` | "Kode Batch *" | YES | NO |
| `kategori_id` | "Kategori Senjata *" | YES | NO |
| `jumlah_butir` | "Jumlah Butir *" | YES | NO |
| `tanggal_masuk` | "Tanggal Masuk *" | YES | YES |
| `tanggal_kedaluwarsa` | "Tanggal Kedaluwarsa *" | YES | YES |

---

## 5. ENTITY: Sarpras (Facilities & Equipment)

### 5.1 API Endpoints

| Method | URL | Purpose |
|--------|-----|---------|
| `GET` | `/api/v1/logistik/sarpras?page=&limit=&search=` | List |
| `POST` | `/api/v1/logistik/sarpras` | Create (multipart) |
| `POST` | `/api/v1/logistik/sarpras/:sarpras_id` | Update (multipart — NOT PUT) |
| `DELETE` | `/api/v1/logistik/sarpras/:sarpras_id` | Delete |

### 5.2 POST/PUT Payload (Multipart Form-Data)

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `kode_barang` | string | YES | |
| `nama_barang` | string | YES | |
| `kategori` | string enum | YES | Hardcoded list (see below) |
| `kondisi` | string enum | YES | Hardcoded list (see below) |
| `tahun_pengadaan` | string (year only) | YES | Only `.year` sent from a full DateTime picker |
| `foto` | multipart file (WebP) | YES (create) / optional (edit) | |

**Hardcoded `kategori` options:**
`Kendaraan`, `Perlengkapan Kantor`, `Perlengkapan Dalmas`, `Alat Komunikasi`, `Kendaraan Taktis`

**Hardcoded `kondisi` options:**
`Baik`, `Rusak Ringan`, `Rusak Berat`

### 5.3 GET Response — Expected Keys

| Column Key | Type | Notes |
|------------|------|-------|
| `sarpras_id` | int/string | PK |
| `kode_barang` | string | Monospace display |
| `nama_barang` | string | |
| `kategori` | string or nested Map | May be flat string or `{nama_kategori, kategori}` object |
| `kondisi` | string | |
| `tahun_pengadaan` | string/int | |
| `foto_fisik` / `foto_url` / `foto` | string | Triple-key fallback for image URL |

### 5.4 Dropdown Dependencies

**None.** Both `kategori` and `kondisi` are hardcoded `const` lists. No polda dependency.

### 5.5 Required vs Optional in UI

| Field | UI Label | Required |
|-------|----------|----------|
| `kode_barang` | "Kode Barang *" | YES |
| `nama_barang` | "Nama Barang *" | YES |
| `kategori` | "Kategori *" | YES |
| `kondisi` | "Kondisi *" | YES |
| `tahun_pengadaan` | "Tahun Pengadaan *" | YES |
| `foto` | "Foto Sarpras *" | YES on create, optional on edit |

---

## 6. ENTITY: Inventaris (Legacy / Superseded)

### 6.1 Status: MOCK DATA — NOT CONNECTED TO API

The `InventarisPage` (`lib/pages/inventaris.dart`) uses **hardcoded static data**:

```dart
final List<Map<String, dynamic>> listinventaris = [
  { "foto": "", "nama": "APC Anoa-2 6x6", "kategori": "Rantis", "kondisi": "Baik" },
  // ... 5 identical rows
];
```

The `FormTambahInventaris` widget (`lib/widget/form_inputan_inventaris.dart`) has:
- No `submitData()` logic — the submit button has `onPressed: () {}` (no-op)
- No HTTP imports
- No API calls
- Collects: `namaassets`, `kategori` (Rantis/Water Canon hardcoded), `kondisi` (free text), `foto` (uncompressed raw bytes)
- No edit mode support (no `initialData` parameter)

**Verdict:** Inventaris appears to have been superseded by the **Sarpras** module. The form and list page are dead code that should either be removed or fully implemented.

---

## 7. ENTITY: User (Pengguna)

### 7.1 API Endpoints

| Method | URL | Purpose |
|--------|-----|---------|
| `GET` | `/api/v1/user?page=&limit=&search=` | List |
| `POST` | `/api/v1/user` | Create (JSON) |
| `PUT` | `/api/v1/user/:id` | Update (JSON) |
| `DELETE` | `/api/v1/user/:id` | Delete |

### 7.2 POST/PUT Payload (JSON)

```json
{
  "username":   "string  — required",
  "roles_id":   "string  — '1' (Super Admin), '2' (Operator Polda), '3' (Command Center)",
  "status":     "string  — 'aktif' or 'tidak_aktif'",
  "polda_id":   "string|null — required for Operator Polda (roles_id='2'), null otherwise",
  "password":   "string  — required for create; optional for edit (only sent if non-empty)"
}
```

**Conditional logic:**
- `polda_id`: Only included (and validated as required) when `roles_id == "2"`. Set to `null` for Super Admin and Command Center.
- `password`: On create, always sent. On edit, **only sent if the field is non-empty** (allows changing password without forcing it). If blank on edit, the key is omitted from the body entirely.

### 7.3 GET Response — Expected Keys

| Column Key | Type | Notes |
|------------|------|-------|
| `id` | int | PK |
| `username` | string | Displayed as "NAMA" |
| `roles_id` | string/int | Mapped via `roleLabelFromId()` → "Super Admin" / "Operator Polda" / "Command Center" |
| `nama_polda` | string? | Preferred display in "POLDA" column |
| `polda_id` | string/int? | |
| `is_active` | string/int | `"1"` → "Aktif", else "Tidak Aktif" |

### 7.4 Dropdown Dependencies

```
User Form
├── Role         ← hardcoded: "1"=Super Admin, "2"=Operator Polda, "3"=Command Center
└── Polda        ← GET /api/v1/polda   (only visible/required when role == "2")
```

### 7.5 Required vs Optional in UI

| Field | UI Label | Required |
|-------|----------|----------|
| `username` | "Username *" | YES |
| `password` | "Password *" (create) / "Password (kosongkan jika tidak berubah)" (edit) | YES on create, NO on edit |
| `roles_id` | "Role *" | YES |
| `status` | "Status" (toggle switch) | Always sent (defaults to `true`/Aktif) |
| `polda_id` | "Polda *" | Conditional: only required when Role = Operator Polda |

---

## 8. ENTITY: Polda (Regional Headquarters)

### 8.1 API Endpoints

| Method | URL | Purpose |
|--------|-----|---------|
| `GET` | `/api/v1/master/polda?page=&limit=&search=` | List (CRUD table) |
| `GET` | `/api/v1/polda` | List (used by dropdowns — returns nested polres array) |
| `POST` | `/api/v1/master/polda` | Create (JSON) |
| `PUT` | `/api/v1/master/polda/:id` | Update (JSON) |
| `DELETE` | `/api/v1/master/polda/:id` | Delete |

**Important distinction:** `/api/v1/polda` and `/api/v1/master/polda` are DIFFERENT endpoints:
- `/api/v1/polda` — returns list with **nested `polres` array** per Polda (used for cascading dropdowns in Personel/Senjata/Amunisi forms)
- `/api/v1/master/polda` — returns paginated flat list (used for the Polda CRUD table)

### 8.2 POST/PUT Payload (JSON)

```json
{
  "nama_polda":  "string  — required",
  "latitude":    "string  — required (sent as string, not double)",
  "longitude":   "string  — required (sent as string, not double)"
}
```

All three fields are sent as strings. Latitude/longitude are NOT validated as numeric in the frontend.

### 8.3 GET Response — Expected Keys (from Polda model)

| Column Key | Type | Notes |
|------------|------|-------|
| `id` | int | PK |
| `nama_polda` | string | |
| `latitude` / `lat` | string | Raw precision-preserving string; dual-key fallback |
| `longitude` / `lng` / `lon` | string | Raw precision-preserving string; triple-key fallback |
| `created_at` | string? | Displayed in table |

The `Polda` model class is the **only proper model** in the entire codebase. All other entities use raw `Map<String, dynamic>`.

### 8.4 Dropdown Dependencies

**None.** Polda is a root-level entity.

### 8.5 Required vs Optional in UI

| Field | UI Label | Required |
|-------|----------|----------|
| `nama_polda` | "Nama Polda *" | YES |
| `latitude` | "Latitude *" | YES |
| `longitude` | "Longitude *" | YES |

---

## 9. ENTITY: Polres (District Police)

### 9.1 API Endpoints

| Method | URL | Purpose |
|--------|-----|---------|
| `GET` | `/api/v1/master/polres?page=&limit=&search=` | List |
| `POST` | `/api/v1/master/polres` | Create (JSON) |
| `PUT` | `/api/v1/master/polres/:id` | Update (JSON) |
| `DELETE` | `/api/v1/master/polres/:id` | Delete |

### 9.2 POST/PUT Payload (JSON)

```json
{
  "polda_id":     "int     — required",
  "nama_polres":  "string  — required"
}
```

### 9.3 GET Response — Expected Keys

| Column Key | Type | Notes |
|------------|------|-------|
| `polres_id` | int | PK; used for edit/delete URL |
| `polda_id` | int | FK — fallback when `nama_polda` absent |
| `nama_polda` | string? | Denormalized — preferred display |
| `nama_polres` | string | |
| `created_at` | string? | |

### 9.4 Dropdown Dependencies

```
Polres Form
└── Polda   ← GET /api/v1/polda   (same endpoint that returns nested polres)
```

### 9.5 Required vs Optional in UI

| Field | UI Label | Required |
|-------|----------|----------|
| `polda_id` | "Nama Polda *" | YES |
| `nama_polres` | "Nama Polres *" | YES |

---

## 10. ENTITY: Kategori Senjata (Weapon Categories)

### 10.1 API Endpoints

| Method | URL | Purpose |
|--------|-----|---------|
| `GET` | `/api/v1/master/kategori-senjata?page=&limit=&search=` | List |
| `POST` | `/api/v1/master/kategori-senjata` | Create (JSON) |
| `PUT` | `/api/v1/master/kategori-senjata/:kategori_id` | Update (JSON) |
| `DELETE` | `/api/v1/master/kategori-senjata/:kategori_id` | Delete |

### 10.2 POST/PUT Payload (JSON)

```json
{
  "tipe_laras":  "string  — 'Panjang' or 'Pendek' (hardcoded enum)",
  "kaliber":     "string  — e.g. '9mm', '5.56mm'"
}
```

CRUD is handled via an inline AlertDialog (not a separate page).

### 10.3 GET Response — Expected Keys

| Column Key | Type | Notes |
|------------|------|-------|
| `kategori_id` | int | PK |
| `tipe_laras` | string | "Panjang" / "Pendek" — rendered as color-coded badge |
| `kaliber` | string | |

### 10.4 Dropdown Dependencies

**None.** `tipe_laras` is a hardcoded const list: `['Panjang', 'Pendek']`.

---

## 11. AUTH: Login

### 11.1 Endpoint

`POST /api/v1/auth/login`

### 11.2 Request Payload

```json
{
  "username": "string",
  "password": "string"
}
```

### 11.3 Response Shape (critical nesting)

```json
{
  "data": {
    "jwt_token": "string",
    "user": {                          // ← NOTE: wrapped in "user" object, NOT an array
      "username":   "string",
      "roles_id":   "string",          // "1", "2", or "3"
      "polda_id":   "string?",
      "uuid":       "string",
      "expired":    "string"
    }
  }
}
```

**⚠️ The CLAUDE.md documentation says `data.user[0]` is an array — but the actual `login_card.dart` code (line 142) accesses `payload["user"]` as a `Map<String, dynamic>`, NOT an array.** The documentation is stale; the frontend expects a **nested object**, not an array.

Stored in SharedPreferences:
| Key | Source Path |
|-----|------------|
| `token` | `data.jwt_token` |
| `username_login` | `data.user.username` |
| `roleid_login` | `data.user.roles_id` |
| `polda_login` | `data.user.polda_id` |
| `uuid_login` | `data.user.uuid` |
| `expired_login` | `data.user.expired` |

---

## 12. DASHBOARD: Command Center (Role "3")

### 12.1 Endpoints

| Method | URL | Purpose |
|--------|-----|---------|
| `GET` | `/api/v1/polda` | Map markers (only fetched when role == "3") |
| `GET` | `/api/v1/dashboard/nasional` | National summary + peta nodes + sitkamtibmas |
| `GET` | `/api/v1/dashboard/drilldown?polda_id=X` | Per-Polda detail popup |

### 12.2 Expected Response Shapes

See `lib/models/dashboard_model.dart` for the full defensive parsing model — the only comprehensive model layer in the app.

Key structures:
- `DashboardNasional`: `{ ringkasan, peta[], sitkamtibmas_terkini[] }`
- `Ringkasan`: 11 integer aggregates
- `PetaNode`: `{ polda_id, nama_polda, latitude, longitude, total_personil, total_senjata, total_sarpras, total_k9 }`
- `DashboardDrilldown`: `{ polda, personil, vakansi, logistik, sitkamtibmas_terkini[] }`

---

## 13. PROFILE: Pengaturan

| Method | URL | Purpose |
|--------|-----|---------|
| `GET` | `/api/v1/profile` | Fetch profile (nama_polda) |

Returns: `{ data: { nama_polda: "string" } }`

---

## 14. DEPENDENCY LOOKUP ENDPOINTS (Reference Data)

These endpoints are called by forms to populate dropdowns:

| Endpoint | Used By | Returns |
|----------|---------|---------|
| `GET /api/v1/polda` | Personel, Senjata, Amunisi, Polres, User forms; Personel cascading Polres; Dashboard map | `[{ id, nama_polda, latitude, longitude, polres: [{ polres_id, nama_polres }] }]` |
| `GET /api/v1/pangkat` | Personel form | `[{ pangkat_id, nama_pangkat }]` |
| `GET /api/v1/jabatan` | Personel form | `[{ jabatan_id, nama_jabatan }]` |
| `GET /api/v1/master/kategori-senjata` | Senjata, Amunisi forms | `[{ kategori_id, tipe_laras, kaliber }]` |

---

## 15. IMAGE HANDLING PATTERN (Senjata, Satwa, Sarpras)

All three entities that accept photo uploads share an identical pipeline:

1. **Pick:** `image_picker` (camera or gallery), `imageQuality: 85`
2. **Compress:** `flutter_image_compress` → WebP, `quality: 80`, `minWidth: 1280`, `minHeight: 1280`
3. **Fallback:** If compression fails (desktop platforms), raw bytes are used
4. **Upload:** `http.MultipartRequest` with field name `"foto"`, filename `<entity>_<timestamp>.webp`
5. **Method:** Always `POST` (even for edits) — PHP cannot parse multipart on PUT
6. **Edit handling:** If no new image is picked, the `foto` field is omitted entirely (backend keeps the existing image)
7. **Display:** `CachedNetworkImage` with absolute URL resolution (`apiBaseUrl` + relative path, with proper `/` insertion)

---

## 16. CROSS-CUTTING CONCERNS & MISMATCHES

### 16.1 Inconsistent HTTP Methods for Updates

| Entity | Create | Update |
|--------|--------|--------|
| Personel | POST (JSON) | PUT (JSON) |
| Senjata | POST (multipart) | POST (multipart) ← NOT PUT |
| Satwa | POST (multipart) | POST (multipart) ← NOT PUT |
| Amunisi | POST (JSON) | PUT (JSON) |
| Sarpras | POST (multipart) | POST (multipart) ← NOT PUT |
| User | POST (JSON) | PUT (JSON) |
| Polda | POST (JSON) | PUT (JSON) |
| Polres | POST (JSON) | PUT (JSON) |
| Kategori Senjata | POST (JSON) | PUT (JSON) |

**Pattern:** Entities with file uploads use POST for everything. Entities without files use proper RESTful POST/PUT.

### 16.2 Missing Validations

| Issue | Entity | Severity |
|-------|--------|----------|
| `kode_batch`, `polda_id`, `kategori_id`, `jumlah_butir` not validated before submit | Amunisi | HIGH |
| `latitude`/`longitude` sent as strings, no format validation | Polda | MEDIUM |
| `status_kelayakan` hardcoded to "Baik" with no UI control | Senjata | MEDIUM |
| No search wiring on Inventaris page | Inventaris | LOW (dead code) |

### 16.3 Hardcoded Enum Values (Client-Side Only)

The backend has no API endpoint that returns these options — they are hardcoded in Dart:

| Entity | Field | Hardcoded Values |
|--------|-------|-----------------|
| Satwa | `jenis_satwa` | `K9`, `Turangga` |
| Satwa | `kualifikasi` | `Narkotika`, `Handak`, `Dalmas`, `Kriminal Umum`, `Patroli`, `Pelacak` |
| Sarpras | `kategori` | `Kendaraan`, `Perlengkapan Kantor`, `Perlengkapan Dalmas`, `Alat Komunikasi`, `Kendaraan Taktis` |
| Sarpras | `kondisi` | `Baik`, `Rusak Ringan`, `Rusak Berat` |
| Senjata | `status_kelayakan` | `Baik` (single value, no choice) |
| Kategori | `tipe_laras` | `Panjang`, `Pendek` |
| User | `roles_id` | `1`=Super Admin, `2`=Operator Polda, `3`=Command Center |
| User | `status` | `aktif`, `tidak_aktif` |

### 16.4 No Model Layer

Only `Polda` (`lib/models/polda_model.dart`) and the dashboard models (`lib/models/dashboard_model.dart`) have proper typed Dart classes. All other entities operate on raw `Map<String, dynamic>` throughout — GET parsing, form pre-filling, and POST/PUT body construction all use ad-hoc key-access patterns. This creates a **high risk of key-name drift** between frontend and backend.

### 16.5 Polres Cascading from Nested Polda Response

The Personel form's Polres dropdown depends on a **nested array** inside the Polda response:

```
GET /api/v1/polda → [{ id, nama_polda, polres: [{ polres_id, nama_polres }] }]
```

The Polres dropdown is populated client-side by extracting `selectedPolda["polres"]`. This means the Personel form does NOT call a separate `/api/v1/polres` endpoint — it relies entirely on the Polda endpoint's nested data.

The **key used** for Polres items is `polres["polres_id"]` and `polres["nama_polres"]` — this differs from the master Polres CRUD endpoint which returns `polres_id` at the top level.

### 16.6 ID Field Name Inconsistencies

| Entity | PK Field (URL param) | Used in |
|--------|---------------------|---------|
| Personel | `personil_id` | edit/delete URL |
| Senjata | `senjata_id` | edit/delete URL |
| Satwa | `satwa_id` | edit/delete URL |
| Amunisi | `batch_id` | edit/delete URL |
| Sarpras | `sarpras_id` | edit/delete URL |
| User | `id` | edit/delete URL |
| Polda | `id` | edit/delete URL |
| Polres | `polres_id` | edit/delete URL |
| Kategori | `kategori_id` | edit/delete URL |

Note: `batch_id` for Amunisi is the outlier — it's not called `amunisi_id`.

---

## 17. ERD IMPLICATIONS SUMMARY

### 17.1 Tables Required (minimum)

```
polda            (id, nama_polda, latitude, longitude, created_at)
polres           (polres_id, polda_id FK→polda.id, nama_polres, created_at)
pangkat          (pangkat_id, nama_pangkat)
jabatan          (jabatan_id, nama_jabatan)
personil         (personil_id, nrp, nama_lengkap, polda_id FK, polres_id FK?,
                  pangkat_id FK, jabatan_id FK, status_aktif)
kategori_senjata (kategori_id, tipe_laras, kaliber)
senjata          (senjata_id, polda_id FK, nomor_seri, kategori_id FK,
                  tahun_pengadaan, status_kelayakan, foto_fisik/foto_url)
satwa            (satwa_id, nomor_registrasi, jenis_satwa, nama_satwa,
                  nama_handler, kualifikasi, jadwal_vaksin, foto_url)
amunisi          (batch_id, polda_id FK, kode_batch, kategori_id FK,
                  jumlah_butir, tanggal_masuk, tanggal_kedaluwarsa,
                  is_h90_alert)
sarpras          (sarpras_id, kode_barang, nama_barang, kategori,
                  kondisi, tahun_pengadaan, foto_url)
users            (id, username, password, roles_id, polda_id FK?, status/is_active)
```

### 17.2 Relationship Diagram (Simplified)

```
polda ──1:N──→ polres
polda ──1:N──→ personil
polda ──1:N──→ senjata
polda ──1:N──→ amunisi
polda ──1:N──→ users (only for role "2")
polres ──1:N──→ personil (nullable)
pangkat ──1:N──→ personil
jabatan ──1:N──→ personil
kategori_senjata ──1:N──→ senjata
kategori_senjata ──1:N──→ amunisi
```

**Note:** Satwa and Sarpras have **no FK to polda** based on the current frontend — they are standalone entities with no regional scoping in the forms.

### 17.3 Fields With No Frontend Visibility

These backend columns would never be populated by the current Flutter forms:

- `personil.updated_at` — no timestamp sent
- `senjata.updated_at` — no timestamp sent
- Any `created_by` / `updated_by` audit fields — not in any form
- `senjata.polda_id` — the dropdown is disabled; always set from session, but the backend must resolve which Polda the weapon belongs to

### 17.4 Frontend-Only Fields (No Backend Column Expected)

- None. All form fields appear to map to backend columns. However, the `is_h90_alert` field on Amunisi is a **computed/derived** field (not sent by the frontend, only read).

---

*End of audit. Generated by automated code scan of all `lib/widget/form_input_*.dart`, `lib/pages/*.dart`, `lib/models/*.dart`, and `lib/config/api_config.dart`.*
