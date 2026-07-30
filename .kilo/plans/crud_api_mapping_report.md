# SINDOMON — CRUD & API Mapping Audit Report

**Date:** 2026-07-30  
**Scope:** Flutter frontend (`lib/pages/`, `lib/widget/`) vs `Detailed API Documentation v1.0.pdf` vs `Detailed ERD v1.0.pdf`  
**API Base:** `https://sindomon.yoknusantara.com/api/v1/`

---

## 1. EXECUTIVE SUMMARY

| Entity | Read | Create | Update | Delete | Overall |
|---|---|---|---|---|---|
| **Polda** | ✅ API | ✅ API | ❌ Missing | ✅ API (⚠️ path mismatch) | ⚠️ Partial |
| **Polres** | ✅ API | ✅ API | ❌ Missing | ✅ API (⚠️ path mismatch) | ⚠️ Partial |
| **Personel** | ✅ API | ✅ API | ❌ Missing | ✅ API (⚠️ path mismatch) | ⚠️ Partial |
| **Senjata** | ✅ API | ⚠️ No feedback | ❌ Missing | ✅ API (⚠️ path mismatch) | ⚠️ Partial |
| **Satwa** | ⚠️ Mocked (no `http` import) | ❌ Missing (`onPressed: () {}`) | ❌ Missing | ❌ Missing | ❌ Broken |
| **Inventaris** | ⚠️ Mocked (no `http` import) | ❌ Missing (`onPressed: () {}`) | ❌ Missing | ❌ Missing | ❌ Broken |
| **User** | ⚠️ No auth header | ❌ Missing (`onPressed: () {}`) | ❌ Missing | ❌ Missing | ❌ Broken |
| **Dashboard** | ✅ API (map) / ⚠️ Mocked (KPIs) | N/A | N/A | N/A | ⚠️ Mocked |
| **Report** | ⚠️ Mocked (duplicate inventaris) | ❌ Missing | ❌ Missing | ❌ Missing | ❌ Broken |
| **Login** | ✅ API | N/A | N/A | N/A | ✅ Complete |

**Critical findings:**
- **Zero entities have Update working.** Every `onEdit` callback is `() {}`.
- **Satwa, Inventaris, Report** are 100% hardcoded — no `http` or `dart:convert` imports.
- **User list** calls API without auth token (will 401/403).
- **API path mismatch** between Flutter and docs for all entities.
- **Pagination** is static text, non-functional. **Search** fields are wireframed but dead.

---

## 2. ENTITY-BY-ENTITY GAP ANALYSIS

### 2.1 POLDA

**Frontend files:** `lib/pages/polda.dart`, `lib/pages/add_polda.dart`, `lib/widget/form_input_polda.dart`

| Operation | Frontend Status | API Doc Status | Gap |
|---|---|---|---|
| **Read (List)** | ✅ `GET /api/v1/polda` with auth header | Doc: `GET /api/v1/master/wilayah` (nested, returns Polda+Polres) | **Path mismatch.** Flutter calls `/polda`, doc specifies `/master/wilayah`. Also: Flutter ignores the nested `polres_jajaran` structure. |
| **Create** | ✅ `POST /api/v1/polda` → `{nama_polda, latitude, longitude}` with SnackBar feedback | Doc: `POST /api/v1/master/polda` | **Path mismatch.** Payload matches doc. |
| **Update** | ❌ `onEdit: () {}` — empty callback (`polda.dart:273`) | Doc: **NOT documented.** No `PUT /api/v1/master/polda/{id}` exists. | **API endpoint missing.** Must create `PUT /api/v1/master/polda/{polda_id}`. |
| **Delete** | ⚠️ `DELETE /api/v1/polda` with JSON body `{polda_id}` — not RESTful | Doc: `DELETE /api/v1/master/polda/{polda_id}` (path param) | **Method mismatch.** Flutter sends ID in JSON body; doc uses path parameter. |

---

### 2.2 POLRES

**Frontend files:** `lib/pages/polres.dart`, `lib/pages/add_polres.dart`, `lib/widget/form_input_polres.dart`

| Operation | Frontend Status | API Doc Status | Gap |
|---|---|---|---|
| **Read (List)** | ✅ `GET /api/v1/polres` with auth header | Doc: `GET /api/v1/master/wilayah` (nested inside `polres_jajaran`) | **Path mismatch.** Dedicated `/polres` list endpoint not in doc; data comes via `/master/wilayah` nested. |
| **Create** | ✅ `POST /api/v1/polres` → `{polda_id, nama_polres}` with SnackBar | Doc: `POST /api/v1/master/polres` | **Path mismatch.** Payload matches doc. Polda dropdown populated from `/api/v1/polda`. |
| **Update** | ❌ `onEdit: () {}` — empty (`polres.dart:265`) | Doc: `PUT /api/v1/master/polres/{polres_id}` ✅ | **Backend ready, frontend missing.** Edit form widget + PUT call needed. |
| **Delete** | ⚠️ `DELETE /api/v1/polres` with JSON body `{polres_id}` | Doc: `DELETE /api/v1/master/polres/{polres_id}` (path param) | **Method mismatch.** Use path param, not JSON body. |

---

### 2.3 PERSONEL

**Frontend files:** `lib/pages/personel.dart`, `lib/pages/add_personel_page.dart`, `lib/widget/form_input_personel.dart`

| Operation | Frontend Status | API Doc Status | Gap |
|---|---|---|---|
| **Read (List)** | ✅ `GET /api/v1/personel` with auth header | Doc: `GET /api/v1/sdm/personil` with query params `?search=&polres_id=&status=&page=&limit=` | **Path mismatch, no query params.** Pagination, search, and filtering not wired. |
| **Create** | ✅ `POST /api/v1/personel` → `{nrp, nama_lengkap, polda_id, polres_id, pangkat_id, jabatan_id}` with SnackBar | Doc: `POST /api/v1/sdm/personil` | **Path mismatch.** Payload matches except: missing `status_aktif`. Doc says `polda_id` must NOT be sent (extracted from JWT). Flutter sends it explicitly. |
| **Update** | ❌ `onEdit: () {}` — empty (`personel.dart:266`) | Doc: `PUT /api/v1/sdm/personil/{personil_id}` ✅ | **Backend ready, frontend missing.** |
| **Delete** | ⚠️ `DELETE /api/v1/personel` with JSON body `{personel_id}` | Doc: **NOT documented.** No DELETE endpoint for personil. | **API endpoint missing.** Must create `DELETE /api/v1/sdm/personil/{personil_id}`. |

---

### 2.4 SENJATA

**Frontend files:** `lib/pages/senjata.dart`, `lib/pages/add_senjata.dart`, `lib/widget/form_input_senjata.dart`

| Operation | Frontend Status | API Doc Status | Gap |
|---|---|---|---|
| **Read (List)** | ✅ `GET /api/v1/senjata` with auth header | Doc: **NOT documented.** No GET endpoint for senjata listing. | **API endpoint missing.** Must create `GET /api/v1/logistik/senjata`. |
| **Create** | ⚠️ `POST /api/v1/senjata` → `{polda_id, no_seri, kategori, tahun, foto}` — but **no SnackBar feedback**, only `debugPrint`. Payload keys don't match doc: `no_seri` → `nomor_seri`, `kategori` → `kategori_id`, `tahun` → `tahun_pengadaan`, `foto` → `foto_fisik`. | Doc: `POST /api/v1/logistik/senjata` → `{nomor_seri, kategori_id, tahun_pengadaan, status_kelayakan, foto_fisik}` | **Path mismatch. Payload key mismatch. Missing `status_kelayakan`. No user feedback.** |
| **Update** | ❌ `onEdit: () {}` — empty (`senjata.dart:281`) | Doc: **NOT documented.** | **API endpoint missing.** |
| **Delete** | ⚠️ `DELETE /api/v1/senjata` with JSON body `{senjata_id}` | Doc: **NOT documented.** | **API endpoint missing.** |

---

### 2.5 SATWA

**Frontend files:** `lib/pages/satwa.dart`, `lib/pages/add_satwa.dart`, `lib/widget/form_inputan_satwa.dart`

| Operation | Frontend Status | API Doc Status | Gap |
|---|---|---|---|
| **Read (List)** | ❌ Hardcoded `listsatwa` — 5 identical entries. **No `http` import.** | Doc: **NOT documented.** No GET endpoint for satwa. | **API endpoint missing. Frontend entirely mock.** |
| **Create** | ❌ `onPressed: () {}` — empty. **No `http` or `dart:convert` imports.** Form fields exist but cannot submit. | Doc: `POST /api/v1/logistik/satwa` ✅ → `{nomor_registrasi, jenis_satwa, nama_satwa, nama_handler, kualifikasi, jadwal_vaksin, foto_fisik}` | **Backend ready, frontend has no API call.** Also: dropdown has wrong values (K9/K8/K7/K6 instead of K9/Turangga). Missing `nama_satwa` field. Missing `jadwal_vaksin` date picker. |
| **Update** | ❌ `onEdit: () {}` | Doc: **NOT documented.** | **API endpoint missing.** |
| **Delete** | ❌ `onDelete: () {}` | Doc: **NOT documented.** | **API endpoint missing.** |

---

### 2.6 INVENTARIS (Sarpras)

**Frontend files:** `lib/pages/inventaris.dart`, `lib/pages/add_inventaris_page.dart`, `lib/widget/form_inputan_inventaris.dart`

| Operation | Frontend Status | API Doc Status | Gap |
|---|---|---|---|
| **Read (List)** | ❌ Hardcoded `listinventaris` — 5 identical entries. **No `http` import.** | Doc: **NOT documented.** No GET endpoint for sarpras. | **API endpoint missing. Frontend entirely mock.** |
| **Create** | ❌ `onPressed: () {}` — empty. **No `http` or `dart:convert` imports.** | Doc: **NOT documented.** No POST for sarpras. ERD mentions `tbl_sarpras` with `jenis_aset`, `nama_aset`, `kondisi`, `foto_url`. | **API endpoint missing. Frontend has no API call.** |
| **Update** | ❌ `onEdit: () {}` | Doc: **NOT documented.** | **API endpoint missing.** |
| **Delete** | ❌ `onDelete: () {}` | Doc: **NOT documented.** | **API endpoint missing.** |

---

### 2.7 USER (Pengguna)

**Frontend files:** `lib/pages/user_page.dart`, `lib/pages/add_user.dart`, `lib/widget/form_input_user.dart`

| Operation | Frontend Status | API Doc Status | Gap |
|---|---|---|---|
| **Read (List)** | ⚠️ `GET /api/v1/user` **WITHOUT auth header** (`user_page.dart:38-39`) | Doc: **NOT documented.** Only auth endpoints exist (`POST /auth/login`, `POST /auth/verify-2fa`, `GET /auth/profile`). | **API endpoint missing. Missing auth header = guaranteed 401/403.** |
| **Create** | ❌ `onPressed: () {}` — empty (`form_input_user.dart:316`). **No `http` import.** Hardcoded Polda dropdown (3 names). Hardcoded role dropdown. | Doc: **NOT documented.** | **API endpoint missing. Frontend has no submit logic.** |
| **Update** | ❌ `onEdit: () {}` | Doc: **NOT documented.** | **API endpoint missing.** |
| **Delete** | ❌ `onDelete: () {}` | Doc: **NOT documented.** | **API endpoint missing.** |

---

### 2.8 DASHBOARD

| Component | Status | Gap |
|---|---|---|
| **Map Polda markers** | ✅ `GET /api/v1/polda` with auth (only for role_id=3) | Correctly wired. |
| **KPI Stats** | ❌ All hardcoded: `"153,500"`, `"97%"`, `"218"`, `"300"`, `"140"` (`dashboard.dart:263-306`) | Needs `GET /api/v1/dashboard/kpi` or equivalent. Not in API doc. |
| **Marker click detail** | ❌ Hardcoded: `2.450` personel, `1.200` inventaris, etc. (`dashboard.dart:150-155`) | Needs drill-down API. Not in API doc. |

---

### 2.9 REPORT

**Frontend file:** `lib/pages/report.dart`

| Operation | Status | Gap |
|---|---|---|
| **Read** | ❌ Duplicate of Inventaris mock data. 5 identical "APC Anoa-2 6x6" entries. **No `http` import.** | Entire page is a copy-paste placeholder. |
| **All CRUD** | ❌ All missing | No API documentation for reports either. |

---

## 3. API PATH MISMATCH SUMMARY

| Flutter Calls | Doc Specifies |
|---|---|
| `GET /api/v1/polda` | `GET /api/v1/master/wilayah` (or `/master/polda` for single) |
| `POST /api/v1/polda` | `POST /api/v1/master/polda` |
| `DELETE /api/v1/polda` (body JSON) | `DELETE /api/v1/master/polda/{polda_id}` (path param) |
| `GET /api/v1/polres` | nested in `GET /api/v1/master/wilayah` |
| `POST /api/v1/polres` | `POST /api/v1/master/polres` |
| `DELETE /api/v1/polres` (body JSON) | `DELETE /api/v1/master/polres/{polres_id}` (path param) |
| `GET /api/v1/personel` | `GET /api/v1/sdm/personil` |
| `POST /api/v1/personel` | `POST /api/v1/sdm/personil` |
| `DELETE /api/v1/personel` (body JSON) | Not documented |
| `GET /api/v1/senjata` | Not documented |
| `POST /api/v1/senjata` | `POST /api/v1/logistik/senjata` |
| `DELETE /api/v1/senjata` (body JSON) | Not documented |
| `GET /api/v1/user` (no auth) | Not documented |
| `GET /api/v1/pangkat` | Not explicitly documented |
| `GET /api/v1/jabatan` | Not explicitly documented |
| `GET /api/v1/kategori_senjata` | Not explicitly documented |

**Decision needed:** Does the live backend serve the flat paths (`/polda`, `/polres`, `/personel`) or the scoped paths (`/master/*`, `/sdm/*`, `/logistik/*`)? The docs describe scoped paths. If backend follows docs, every Flutter API call will 404. If backend already serves the flat paths the Flutter expects, the docs are outdated.

---

## 4. DELETE METHOD MISMATCH

All Flutter delete calls send JSON bodies with the entity ID:
```dart
http.delete(url, body: jsonEncode({"polda_id": id}))
```

The API documentation specifies **path parameters** for all deletes:
```
DELETE /api/v1/master/polda/{polda_id}
DELETE /api/v1/master/polres/{polres_id}
```

Some delete endpoints are **not documented at all** (personel, senjata, user).

---

## 5. MISSING API ENDPOINTS (per documentation)

These endpoints are needed by the frontend but **not in the API documentation**:

| Needed | Priority | Notes |
|---|---|---|
| `GET /api/v1/logistik/senjata` | HIGH | Senjata list page is live but uses wrong path |
| `PUT /api/v1/logistik/senjata/{id}` | HIGH | Edit senjata |
| `DELETE /api/v1/logistik/senjata/{id}` | HIGH | Delete senjata |
| `GET /api/v1/logistik/satwa` | CRITICAL | Satwa is 100% mock |
| `PUT /api/v1/logistik/satwa/{id}` | MEDIUM | Edit satwa |
| `DELETE /api/v1/logistik/satwa/{id}` | MEDIUM | Delete satwa |
| `GET /api/v1/logistik/sarpras` | CRITICAL | Inventaris is 100% mock |
| `POST /api/v1/logistik/sarpras` | CRITICAL | Inventaris create |
| `PUT /api/v1/logistik/sarpras/{id}` | MEDIUM | Inventaris edit |
| `DELETE /api/v1/logistik/sarpras/{id}` | MEDIUM | Inventaris delete |
| `GET /api/v1/user` | CRITICAL | User list + needs auth |
| `POST /api/v1/user` | CRITICAL | User create |
| `PUT /api/v1/user/{id}` | HIGH | User edit |
| `DELETE /api/v1/user/{id}` | MEDIUM | User delete |
| `PUT /api/v1/master/polda/{id}` | HIGH | Polda edit |
| `DELETE /api/v1/sdm/personil/{id}` | HIGH | Personel delete |
| `GET /api/v1/dashboard/kpi` | MEDIUM | Dashboard KPI stats |

---

## 6. PAYLOAD KEY MISMATCHES

| Entity | Flutter sends | Doc expects |
|---|---|---|
| Senjata | `no_seri`, `kategori`, `tahun`, `foto` | `nomor_seri`, `kategori_id`, `tahun_pengadaan`, `foto_fisik`, `status_kelayakan` (missing) |
| Personel | `polda_id` (explicitly sent) | Doc says: "polda_id tidak boleh dikirim dari klien. Backend akan mengisinya otomatis dari JWT." |

---

## 7. COMMON CROSS-CUTTING GAPS

| Gap | Affected Entities | Fix |
|---|---|---|
| **Edit (Update)** | ALL (Polda, Polres, Personel, Senjata, Satwa, Inventaris, User) | Create edit form pages/widgets + PUT/PATCH calls |
| **Pagination** | ALL | `AppPagination` is static text. Wire to API meta (`current_page`, `total_pages`, `total_data`) |
| **Search** | ALL | `AppSearchField` has no backend integration |
| **Image handling** | Satwa, Inventaris | Image picker exists but no upload/submit logic |
| **Form validation** | Satwa, Inventaris, User | No pre-submit validation |
| **Error handling** | Senjata create | No SnackBar — only `debugPrint` |
| **Role-based access** | Polda, Polres (POST) | Doc states "Hanya Super Admin" — frontend doesn't check role before showing Add button |

---

## 8. IMPLEMENTATION PRIORITY ORDER

### Phase 1 — Unblock the Broken (Satwa, Inventaris, User)
1. Create backend `GET/POST /api/v1/logistik/satwa` + `GET/POST /api/v1/logistik/sarpras` + `GET/POST /api/v1/user`
2. Wire Flutter `satwa.dart`, `inventaris.dart`, `user_page.dart` to real API calls
3. Wire create forms with actual `http.post` calls

### Phase 2 — Standardize the Partial (Polda, Polres, Personel, Senjata)
4. Resolve API path decision: flat vs scoped. Align Flutter to match backend reality.
5. Convert all delete calls from JSON body to path parameters
6. Fix Senjata payload keys + add user feedback
7. Fix User list missing auth header

### Phase 3 — Add Update (ALL entities)
8. Build edit form widgets for Polda, Polres, Personel, Senjata
9. Build edit form widgets for Satwa, Inventaris, User
10. Wire all `onEdit` callbacks with prefilled forms + PUT calls

### Phase 4 — Delete Endpoints
11. Create missing DELETE endpoints (personel, senjata, user)
12. Wire delete for Satwa, Inventaris, User

### Phase 5 — Polish
13. Wire pagination to API meta
14. Wire search fields
15. Wire dashboard KPIs to real API

---

## 9. OPEN QUESTIONS FOR USER

1. **API Path Decision:** Does the live production backend use flat paths (`/api/v1/polda`) or scoped paths (`/api/v1/master/polda`)? The docs say scoped, the Flutter code uses flat. Which is the source of truth?

2. **User CRUD:** The API doc only covers auth (login, 2FA, profile). Should we follow the ERD structure (`tbl_users`, `tbl_roles`) and design the user CRUD endpoints ourselves?

3. **Inventaris vs Sarpras:** The doc mentions `tbl_sarpras` and `tbl_altmatsus` in ERD. The Flutter page is named "Inventaris." Which entity name should we standardize on?

4. **Report page:** Is the `/report` page meant to be a separate entity or an aggregated view? It currently duplicates inventaris mock data.

5. **Edit forms UX:** Should edit reuse the same form widget as create (with pre-filled fields + PUT instead of POST), or should each entity have a dedicated edit page?

---

*End of report. Awaiting APPROVE command before any code changes.*
