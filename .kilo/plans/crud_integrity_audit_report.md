# CRUD Integrity Audit Report

**Date:** 2026-07-29
**Scope:** 8 data pages, 7 form pages, 7 form widgets, shared layout components
**Refactor Context:** Fixed Viewport layouts, centralized AppSidebar, dynamic AppHeader, AppFooter

---

## 1. Executive Summary

| Status | Count | Details |
|--------|-------|---------|
| ✅ Full CRUD (API-backed) | 3/8 | personel, polda, polres |
| ⚠️ Partial (missing pieces) | 2/8 | senjata (orphaned POST), user (no create/update/delete API) |
| ❌ Stub (mock data, no API) | 2/8 | satwa, inventaris |
| 🔒 Read-only (by design) | 1/8 | report |

**Critical Finding:** All 8 data pages have `onEdit: () {}` — zero edit/update functionality exists across the entire application. Delete is functional in only 4/8 modules. All 7 add_*.dart pages use a duplicated ~160-line hardcoded header instead of the centralized `AppHeader` component.

---

## 2. Module-Level CRUD Health Matrix

| Module | Data Page | Add Page | Form Widget | Create (POST) | Read (GET) | Update (PUT) | Delete (DELETE) | Tambah Route | Edit Button | Delete Button | API Backed |
|--------|-----------|----------|-------------|---------------|------------|--------------|-----------------|-------------|-------------|---------------|------------|
| **Personel** | `personel.dart` | `add_personel_page.dart` | `form_input_personel.dart` | ✅ POST `/personel` | ✅ GET `/personel` | ❌ `onEdit: (){}` | ✅ `/personel` | ✅ → `AddPersonelPage` | ❌ no-op | ✅ functional | ✅ |
| **Polda** | `polda.dart` | `add_polda.dart` | `form_input_polda.dart` | ✅ POST `/polda` | ✅ GET `/polda` | ❌ `onEdit: (){}` | ✅ `/polda` | ✅ → `AddPoldaPage` | ❌ no-op | ✅ functional | ✅ |
| **Polres** | `polres.dart` | `add_polres.dart` | `form_input_polres.dart` | ✅ POST `/polres` | ✅ GET `/polres` | ❌ `onEdit: (){}` | ✅ `/polres` | ✅ → `AddPolresPage` | ❌ no-op | ✅ functional | ✅ |
| **Senjata** | `senjata.dart` | `add_senjata.dart` | `form_input_senjata.dart` | ⚠️ POST code exists, **submit button missing** | ✅ GET `/senjata` | ❌ `onEdit: (){}` | ✅ `/senjata` | ✅ → `AddSenjataPage` | ❌ no-op | ✅ functional | ✅ |
| **User** | `user_page.dart` | `add_user.dart` | `form_input_user.dart` | ❌ `onPressed: (){}` | ⚠️ GET `/user` (no auth header) | ❌ `onEdit: (){}` | ❌ no-op | ✅ → `AddUserPage` | ❌ no-op | ❌ no-op | ⚠️ |
| **Satwa** | `satwa.dart` | `add_satwa.dart` | `form_inputan_satwa.dart` | ❌ `onPressed: (){}` | ❌ hardcoded mock | ❌ `onEdit: (){}` | ❌ no-op | ✅ → `AddSatwaPage` | ❌ no-op | ❌ no-op | ❌ |
| **Inventaris** | `inventaris.dart` | `add_inventaris_page.dart` | `form_inputan_inventaris.dart` | ❌ `onPressed: (){}` | ❌ hardcoded mock | ❌ `onEdit: (){}` | ❌ no-op | ✅ → `AddInventarisPage` | ❌ no-op | ❌ no-op | ❌ |
| **Report** | `report.dart` | — | — | — | ❌ hardcoded mock | ❌ `onEdit: (){}` | ❌ no-op | ❌ **no button** | ❌ no-op | ❌ no-op | ❌ |

---

## 3. Detailed Findings

### 3.1 CREATE Routing Audit

| Data Page | Tambah Button Label | Line | Navigator Target | Import Status | Route Valid? |
|-----------|-------------------|------|-----------------|---------------|--------------|
| `personel.dart` | "Tambah Personel" | L152 | `AddPersonelPage` | ✅ | ✅ |
| `senjata.dart` | "Tambah Senjata" | L152 | `AddSenjataPage` | ✅ | ✅ |
| `satwa.dart` | "Tambah Satwa" | L136 | `AddSatwaPage` | ✅ | ✅ |
| `inventaris.dart` | "Tambah Inventaris" | L121 | `AddInventarisPage` | ✅ | ✅ |
| `polda.dart` | "Tambah Polda" | L151 | `AddPoldaPage` | ✅ | ✅ |
| `polres.dart` | "Tambah Polres" | L151 | `AddPolresPage` | ✅ | ✅ |
| `user_page.dart` | "Tambah Pengguna" | L121 | `AddUserPage` | ✅ | ✅ |
| `report.dart` | **MISSING** | — | — | — | — |

**Verdict:** All 7 active Create routes are correct. Report page has no Tambah button (read-only by design — no issue).

---

### 3.2 Form Page Layout Audit (`add_*.dart`)

All 7 `add_*.dart` files share identical structure (287 lines each).

| Layout Component | Status | Details |
|-----------------|--------|---------|
| `AppSidebar` | ✅ Present | Line 43 in all 7 files, with correct `currentRoute` per entity |
| `AppHeader` | ❌ **Missing** | Not imported or used in any add_*.dart file |
| **Hardcoded Header** | ⚠️ Duplicated | Lines 57–215 in all 7 files — ~160 lines of identical glassmorphism header duplicated 7x |
| `AppFooter` | ✅ Present | Line 275 in all 7 files |
| `AppBackground` | ✅ Present | Consistent wrapper in all 7 files |

**Header duplication breakdown (per file, lines 57–215):**
- Glassmorphism Container (BackdropFilter, blur SigmaX/Y: 20)
- Home icon (Icons.home_rounded + amber circle)
- Breadcrumb: `"Dashboard / Tambah {Entity}"`
- Search TextField ("Cari Menu...")
- Notification IconButton (no-op)
- User CircleAvatar + username/role display

**Risk:** Any change to header design requires updating 7 identical copies. The `AppHeader` widget exists at `lib/widget/app_header.dart:3` but is only used in the 8 data pages, not the form pages.

---

### 3.3 UPDATE / DELETE Action Audit

#### 3.3.1 Edit (Update) — CRITICAL GAP

**Every single data page** has `onEdit: (){}` — a no-op callback:

```
personel.dart:265      ActionButtons(onEdit: (){}, onDelete: () async { ... })
senjata.dart:280       ActionButtons(onEdit: (){}, onDelete: () async { ... })
satwa.dart:290         ActionButtons(onEdit: (){}, onDelete: () {})
inventaris.dart:243    ActionButtons(onEdit: (){}, onDelete: () {})
polda.dart:272         ActionButtons(onEdit: (){}, onDelete: () async { ... })
polres.dart:264        ActionButtons(onEdit: (){}, onDelete: () async { ... })
user_page.dart:235     ActionButtons(onEdit: (){}, onDelete: () {})
report.dart:217        ActionButtons(onEdit: (){}, onDelete: () {})
```

**Zero update/edit functionality exists in the entire application.** No page navigates to an edit form, no PUT/PATCH requests exist, no edit dialog appears.

#### 3.3.2 Delete — Partial Coverage

| Module | Delete Button | Confirmation Dialog | API Call | Result |
|--------|--------------|-------------------|-----------|--------|
| Personel | ✅ `Icons.delete_outlined` | ✅ "Hapus Personel" | ✅ DELETE `/personel` | Functional |
| Polda | ✅ `Icons.delete_outlined` | ✅ "Hapus Polda" | ✅ DELETE `/polda` | Functional |
| Polres | ✅ `Icons.delete_outlined` | ✅ "Hapus Polres" | ✅ DELETE `/polres` | Functional |
| Senjata | ✅ `Icons.delete_outlined` | ✅ "Hapus Senjata" | ✅ DELETE `/senjata` | Functional |
| User | ✅ icon visible | ❌ no-op | ❌ none | **Stub** |
| Satwa | ✅ icon visible | ❌ no-op | ❌ none | **Stub** |
| Inventaris | ✅ icon visible | ❌ no-op | ❌ none | **Stub** |
| Report | ✅ icon visible | ❌ no-op | ❌ none | **Stub** (read-only) |

**Note:** `user_page.dart` `getUsers()` at L38 omits the `Authorization` header (all other API calls include `Bearer $token`). This means the user list fetch may fail silently against an authenticated API.

---

### 3.4 Form Widget API Audit

| Form Widget | HTTP Dependencies | Submit Button | onPressed | API Endpoint | Status |
|-------------|-------------------|---------------|-----------|-------------|--------|
| `form_input_personel.dart` | ✅ http, dart:convert | ✅ "Simpan Data" (L326) | ✅ `submitPersonel()` | POST `/personel` | **Functional** |
| `form_input_polda.dart` | ✅ http, dart:convert | ✅ "Simpan Data" (L129) | ✅ `simpanPolda()` | POST `/polda` | **Functional** |
| `form_input_polres.dart` | ✅ http, dart:convert | ✅ "Simpan Data" (L162) | ✅ `simpanPolres()` | POST `/polres` | **Functional** |
| `form_input_senjata.dart` | ✅ http, dart:convert | ❌ **MISSING** | ❌ Orphaned | POST `/senjata` | **Broken** |
| `form_input_user.dart` | ❌ none | ✅ "Simpan Akun" (L287) | ❌ `(){}` | None | **Stub** |
| `form_inputan_satwa.dart` | ❌ none | ✅ "Submit" (L211) | ❌ `(){}` | None | **Stub** |
| `form_inputan_inventaris.dart` | ❌ none | ✅ "Submit" (L175) | ❌ `(){}` | None | **Stub** |

**Specific issues:**

- **`form_input_senjata.dart`**: `submitData()` exists at L106–130 with full POST logic, JSON encoding, and token handling. But no submit button exists in the widget tree. The only button is "Pilih Foto" (OutlinedButton.icon at L290). Orphaned code.

- **`form_input_user.dart`**: Full form with `username`, `password`, `role` (dropdown: Super Admin/Operator Polda/Operator Polres), `aktif` (Switch), and conditional `polda` field. No HTTP imports. Submit is empty `(){}`.

- **`form_inputan_satwa.dart`** and **`form_inputan_inventaris.dart`**: Both have image picker for photos but no HTTP implementation. Form data is collected but discarded on submit. `form_inputan_inventaris.dart` has copypaste artifacts (label "Foto Satwa" at L130, unused `kualifikasi` field at L19).

---

### 3.5 Backend API Alignment

**Base URL:** `https://sindomon.yoknusantara.com/api/v1`

| Endpoint | Method | Implemented In | Auth Token |
|----------|--------|---------------|------------|
| `/auth/login` | POST | `login_card.dart` | — |
| `/polda` | GET | `dashboard.dart`, `polda.dart`, 3 form widgets | ✅ |
| `/polda` | POST | `form_input_polda.dart` | ✅ |
| `/polda` | DELETE | `polda.dart` | ✅ |
| `/polres` | GET | `polres.dart`, `form_input_polres.dart` | ✅ |
| `/polres` | POST | `form_input_polres.dart` | ✅ |
| `/polres` | DELETE | `polres.dart` | ✅ |
| `/personel` | GET | `personel.dart`, `form_input_personel.dart` | ✅ |
| `/personel` | POST | `form_input_personel.dart` | ✅ |
| `/personel` | DELETE | `personel.dart` | ✅ |
| `/senjata` | GET | `senjata.dart`, `form_input_senjata.dart` | ✅ |
| `/senjata` | POST (orphaned) | `form_input_senjata.dart` | ✅ |
| `/senjata` | DELETE | `senjata.dart` | ✅ |
| `/kategori_senjata` | GET | `form_input_senjata.dart` | ✅ |
| `/pangkat` | GET | `form_input_personel.dart` | ✅ |
| `/jabatan` | GET | `form_input_personel.dart` | ✅ |
| `/user` | GET | `user_page.dart` | ❌ **missing token** |

**RESTful compliance issues:**
1. DELETE operations send body `{"entity_id": id}` instead of using URL path parameter (`/entity/{id}`) — non-standard but functional
2. No PUT/PATCH endpoints exist anywhere — update is entirely unimplemented
3. `user_page.dart` GET request omits Authorization header (L38–50)
4. satwa, inventaris, user have no API endpoints wired up at all
5. report has no backend — static mock data copied from inventaris

---

## 4. Issue Severity Ranking

| # | Issue | Severity | Affected Modules | Impact |
|---|-------|----------|-----------------|--------|
| 1 | **No Edit/Update anywhere** | 🔴 Critical | All 8 modules | Users cannot modify existing records |
| 2 | **Senjata form: orphaned POST** | 🔴 Critical | Senjata | Create form collects data but can't submit |
| 3 | **User GET: no auth token** | 🟠 High | User | User list may fail silently; auth bypass vulnerability |
| 4 | **Satwa/Inventaris/User: stub forms** | 🟠 High | 3 modules | Form data collected, discarded on submit |
| 5 | **add_*.dart: 7x duplicated header** | 🟡 Medium | All form pages | ~1120 lines of duplicated code |
| 6 | **add_*.dart: missing AppHeader** | 🟡 Medium | All form pages | Not using centralized header component |
| 7 | **Inventaris: copypaste artifacts** | 🟢 Low | Inventaris | "Foto Satwa" label, unused `kualifikasi` field |
| 8 | **Report: static inventaris data** | 🟢 Low | Report | Report page shows inventaris mock data, not actual reports |

---

## 5. Remediation Roadmap

### Phase 1: Critical Fixes

1. **Add submit button to `form_input_senjata.dart`** — wire existing `submitData()` to a button in the widget tree
2. **Implement Edit/Update flow** — reuse `add_*.dart` pages with edit mode (pass record ID), wire `onEdit`, add PUT/PATCH API calls
3. **Fix `user_page.dart` auth header** — add `Authorization: Bearer $token` to GET `/user`

### Phase 2: Complete Stub Forms

4. **Implement `form_input_user.dart`** — add HTTP, POST to `/user`, implement submit
5. **Implement `form_inputan_satwa.dart`** — add HTTP, POST to `/satwa`, implement submit
6. **Implement `form_inputan_inventaris.dart`** — add HTTP, POST to `/inventaris`, implement submit, fix copypaste artifacts
7. **Add Delete to user/satwa/inventaris** — wire `onDelete` callbacks with API calls

### Phase 3: Layout Consistency

8. **Replace hardcoded headers in all 7 add_*.dart** with `<AppHeader breadcrumb="Dashboard / Tambah {Entity}" ... />`
9. **Import and use `app_header.dart`** in all add_*.dart files

### Phase 4: Polish

10. **Fix inventaris copypaste artifacts**
11. **Replace report.dart mock data** with actual report API or remove ActionButtons

---

## 6. Files Requiring Changes

| File | Phase | Changes Needed |
|------|-------|---------------|
| `lib/widget/form_input_senjata.dart` | 1 | Add submit button, wire `submitData()` |
| `lib/pages/personel.dart` | 1 | Implement `onEdit` → navigate edit |
| `lib/pages/polda.dart` | 1 | Implement `onEdit` → navigate edit |
| `lib/pages/polres.dart` | 1 | Implement `onEdit` → navigate edit |
| `lib/pages/senjata.dart` | 1 | Implement `onEdit` → navigate edit |
| `lib/pages/user_page.dart` | 1 | Fix auth header + implement `onEdit`/`onDelete` |
| `lib/pages/satwa.dart` | 1,2 | Implement `onEdit`/`onDelete` |
| `lib/pages/inventaris.dart` | 1,2 | Implement `onEdit`/`onDelete` |
| `lib/widget/form_input_user.dart` | 2 | Add HTTP, implement submit |
| `lib/widget/form_inputan_satwa.dart` | 2 | Add HTTP, implement submit |
| `lib/widget/form_inputan_inventaris.dart` | 2 | Add HTTP, implement submit, fix copypaste |
| `lib/pages/add_personel_page.dart` | 3 | Replace hardcoded header with AppHeader |
| `lib/pages/add_senjata.dart` | 3 | Replace hardcoded header with AppHeader |
| `lib/pages/add_satwa.dart` | 3 | Replace hardcoded header with AppHeader |
| `lib/pages/add_inventaris_page.dart` | 3 | Replace hardcoded header with AppHeader |
| `lib/pages/add_polda.dart` | 3 | Replace hardcoded header with AppHeader |
| `lib/pages/add_polres.dart` | 3 | Replace hardcoded header with AppHeader |
| `lib/pages/add_user.dart` | 3 | Replace hardcoded header with AppHeader |
| `lib/pages/report.dart` | 4 | Remove ActionButtons or wire real data |

---

**Audit prepared by:** Automated code scan
**Status:** Awaiting APPROVE before code changes
