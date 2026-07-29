# Sidebar Routing & Linkage Audit Report

**Date:** 2026-07-29
**Scope:** `lib/config/menu_config.dart`, `lib/widget/app_sidebar.dart`, `lib/pages/`, `lib/pages/placeholder_page.dart`
**Roles:** 1=Super Admin, 2=Operator Polda, 3=Command Center

---

## 1. Executive Summary

| Metric | Value |
|--------|-------|
| Total menu items across all roles | 27 |
| Real functional pages (API-backed) | 5 |
| Mock pages (hardcoded data) | 3 |
| Stub/placeholder pages | 14 |
| Redirects to wrong page | 1 |
| Orphaned real pages (no menu entry) | 2 🔴 |
| Dead links (null taps) | 0 |
| Duplicate definitions | 1 |

**Critical Finding:** `polda.dart` and `polres.dart` are fully functional API-backed pages with delete, pagination, and CRUD — but have **zero menu entries** in any role. They are unreachable from the sidebar.

---

## 2. Complete Menu-to-Page Mapping

### 2.1 Role 1 — Super Admin (7 items)

| # | Menu Label | Group | routeName | pageBuilder | Destination File | Status |
|---|-----------|-------|-----------|-------------|-----------------|--------|
| 1 | Dashboard | (top) | `dashboard` | `_db` | `dashboard.dart` | ✅ REAL |
| 2 | Laporan | (top) | `report` | `_rp` | `report.dart` | ⚠️ MOCK |
| 3 | Daftar Pengguna | Manajemen Keamanan & Akun | `pengguna` | `_us` | `user_page.dart` | ⚠️ MOCK |
| 4 | Binding Perangkat | Manajemen Keamanan & Akun | `binding_device` | `_bd` | `placeholder_page.dart` | 🔧 STUB |
| 5 | **Master Wilayah** | Master Data Sistem | `dashboard` | `_db` | `dashboard.dart` | 🔴 **WRONG — redirects to Dashboard** |
| 6 | Master SDM & Organisasi | Master Data Sistem | `org_tree` | `_ot` | `placeholder_page.dart` | 🔧 STUB |
| 7 | Master Logistik | Master Data Sistem | `inventaris` | `_in` | `inventaris.dart` | ⚠️ MOCK |
| — | Pengaturan | (bottom bar) | `pengaturan` | `_st` / hardcoded | `pangaturan.dart` | ✅ REAL |

**Real: 2 | Mock: 3 | Stub: 2 | Wrong: 1**

---

### 2.2 Role 2 — Operator Polda (19 items)

| # | Menu Label | Group | routeName | pageBuilder | Destination File | Status |
|---|-----------|-------|-----------|-------------|-----------------|--------|
| 1 | Dashboard | (top) | `dashboard` | `_db` | `dashboard.dart` | ✅ REAL |
| 2 | Laporan | (top) | `report` | `_rp` | `report.dart` | ⚠️ MOCK |
| 3 | Bagan Organisasi (Org-Tree) | Manajemen SDM | `org_tree` | `_ot` | `placeholder_page.dart` | 🔧 STUB |
| 4 | Direktori Personel | Manajemen SDM | `personel` | `_pe` | `personel.dart` | ✅ REAL |
| 5 | Pemantauan Proses Hukum | Manajemen SDM | `process_law` | `_pl` | `placeholder_page.dart` | 🔧 STUB |
| 6 | Inventaris Senjata | Logistik & Aset | `senjata` | `_se` | `senjata.dart` | ✅ REAL |
| 7 | Stok Amunisi | Logistik & Aset | `ammo_stock` | `_as` | `placeholder_page.dart` | 🔧 STUB |
| 8 | Sarpras & Altmatsus | Logistik & Aset | `sarpras` | `_sp` | `placeholder_page.dart` | 🔧 STUB |
| 9 | Satwa K9 & Turangga | Logistik & Aset | `satwa` | `_sa` | `satwa.dart` | ⚠️ MOCK |
| 10 | Kotak Masuk (Inbox) | Administrasi (DMS) | `dms_inbox` | `_di` | `placeholder_page.dart` | 🔧 STUB |
| 11 | Kotak Keluar (Outbox) | Administrasi (DMS) | `dms_outbox` | `_do` | `placeholder_page.dart` | 🔧 STUB |
| 12 | Log Sitkamtibmas | Operasional & Kamtibmas | `sitkamtibmas` | `_sk` | `placeholder_page.dart` | 🔧 STUB |
| 13 | Direktori Panggilan (VoIP) | Komunikasi Taktis | `voip_directory` | `_vd` | `placeholder_page.dart` | 🔧 STUB |
| 14 | Ruang Konferensi | Komunikasi Taktis | `conference` | `_cf` | `placeholder_page.dart` | 🔧 STUB |
| 15 | Perpustakaan Digital | Hub Informasi Terpadu | `digital_library` | `_dl` | `placeholder_page.dart` | 🔧 STUB |
| 16 | Pengaduan Masyarakat | Hub Informasi Terpadu | `public_complaint` | `_pc` | `placeholder_page.dart` | 🔧 STUB |
| 17 | Status Patroli GPS | Mobile | `patrol_gps` | `_pg` | `placeholder_page.dart` | 🔧 STUB |
| — | Pengaturan | (bottom bar) | `pengaturan` | hardcoded | `pangaturan.dart` | ✅ REAL |

**Real: 3 | Mock: 3 | Stub: 13**

---

### 2.3 Role 3 — Command Center (2 items)

| # | Menu Label | Group | routeName | pageBuilder | Destination File | Status |
|---|-----------|-------|-----------|-------------|-----------------|--------|
| 1 | Command Center Nasional | (top) | `command_center` | `_cc` | `placeholder_page.dart` | 🔧 STUB |
| — | Pengaturan | (bottom bar) | `pengaturan` | hardcoded | `pangaturan.dart` | ✅ REAL |

**Real: 1 | Stub: 1**

---

## 3. Destination File Status Definitions

| Status | Description |
|--------|-------------|
| ✅ REAL | Fully functional page with live API integration |
| ⚠️ MOCK | Page exists, renders UI, but uses hardcoded static data (no API) |
| 🔧 STUB | `PlaceholderPage` — "Fitur dalam pengembangan" message only |
| 🔴 WRONG | Valid pageBuilder, but routes to wrong destination for its label |

---

## 4. Detailed Findings

### 4.1 🔴 CRITICAL: Orphaned Real Pages — polda.dart & polres.dart

**Files:**
- `lib/pages/polda.dart` — `PoldaPage` class, 354 lines
- `lib/pages/polres.dart` — `PolresPage` class, 346 lines

**Capabilities of these pages (from CRUD audit):**

| Page | GET API | POST API | DELETE API | Pagination | Search | ActionButtons |
|------|---------|----------|------------|------------|--------|---------------|
| `polda.dart` | ✅ `GET /polda` | ✅ (via `add_polda.dart`) | ✅ `DELETE /polda` | ✅ | ✅ | ✅ (delete functional) |
| `polres.dart` | ✅ `GET /polres` | ✅ (via `add_polres.dart`) | ✅ `DELETE /polres` | ✅ | ✅ | ✅ (delete functional) |

**Evidence of absence from menu_config.dart:**
- Zero imports of `polda.dart` or `polres.dart`
- Zero references to `PoldaPage` or `PolresPage`
- Zero `routeName` values of `"polda"` or `"polres"`
- Grep for `polda|polres` in `menu_config.dart` returns **no results**

**The only way to reach these pages today:** Unknown. Possibly hot-reload artifacts from before the sidebar refactor. These pages are dead ends with no navigation entry point.

**Recommended fix:** Add `LeafMenuItem` entries under Role 1's "Master Data Sistem" group:
- "Master Polda" → `PoldaPage` (or rename "Master Wilayah" to point here)
- "Master Polres" → `PolresPage`

---

### 4.2 🔴 WRONG REDIRECT: "Master Wilayah" → Dashboard

**Location:** `menu_config.dart`, Role 1, "Master Data Sistem" group, line 99–104

```dart
LeafMenuItem(
  label: "Master Wilayah",
  icon: Icons.map_rounded,
  routeName: "dashboard",       // ❌ Should be "polda" or "master_wilayah"
  pageBuilder: _db,             // ❌ Should be PoldaPage or a dedicated page
),
```

**Impact:** Clicking "Master Wilayah" takes the user to the Dashboard, not any regional/city management page. This is a label-to-destination mismatch.

**Likely intent:** This should route to `PoldaPage` (since Polda is the top-level regional entity in the app).

**Note:** Both `routeName: "dashboard"` and the Dashboard page itself already use `"dashboard"` as the route name — so the sidebar highlights *both* Dashboard and Master Wilayah when on the dashboard page.

---

### 4.3 🟡 DUPLICATE: Pengaturan Defined Twice

**Location 1:** `menu_config.dart` line 56–63 (`_commonBottomItems`)
```dart
const _commonBottomItems = [
  LeafMenuItem(
    label: "Pengaturan",
    icon: Icons.settings_rounded,
    routeName: "pengaturan",
    pageBuilder: _st,
  ),
];
```

**Location 2:** `app_sidebar.dart` lines 123–129 (hardcoded bottom slot)
```dart
_buildLeafItem(
  LeafMenuItem(
    label: "Pengaturan",
    icon: Icons.settings_rounded,
    routeName: "pengaturan",
    pageBuilder: _stubSettings,
  ),
),
```

**Resolution mechanism:** `_buildMenuItems()` at line 144 filters out items with `routeName == "pengaturan"`:
```dart
if (item.routeName == "pengaturan") continue;
```

**Risk:** Low, but fragile. If the filter string changes in one place but not the other, Pengaturan would appear twice. If someone removes `_commonBottomItems` without removing the hardcoded entry, nothing breaks — but the reverse is not true.

---

### 4.4 🟡 DUPLICATE: Two pageBuilder References for Pengaturan

| Reference | Function | Result |
|-----------|----------|--------|
| `menu_config.dart:_st` | `Widget _st() => const AccountSettingPage();` | ✅ Correct |
| `app_sidebar.dart:_stubSettings` | `Widget _stubSettings() => const AccountSettingPage();` | ✅ Correct |

Both point to `AccountSettingPage()` from `pangaturan.dart`. The `app_sidebar.dart` version imports `pangaturan.dart` directly (line 5), bypassing `menu_config.dart`'s centralized page factory. Low risk but unnecessary fragmentation.

---

### 4.5 🟡 MOCK Pages Appear as Real

Three pages render full DataTable UI but use hardcoded static lists:

| Page | Mock Data Source | Rows | Realistic? |
|------|-----------------|------|------------|
| `report.dart` | `listinventaris` (5 items) | APC Anoa-2 6x6 ×5 | ❌ Copied from inventaris |
| `satwa.dart` | `listsatwa` (5 items) | All identical dummy data | ❌ |
| `inventaris.dart` | `listinventaris` (5 items) | APC Anoa-2 6x6 ×5 | ❌ |

**Impact:** Users see what appears to be a functional data page, but data never changes, filters/search don't work, and ActionButtons are no-ops. This creates a misleading illusion of functionality.

---

### 4.6 🟢 Role 3 Skeleton

Role 3 (Command Center) has only 2 menu items:
1. Command Center Nasional (STUB)
2. Pengaturan (REAL)

This is acceptable for an early feature rollout but all substantive Command Center functionality is marked as "dalam pengembangan."

---

## 5. No Dead Links Found

All `LeafMenuItem` instances have valid `pageBuilder` callbacks. Zero `null` taps. The navigation chain `onTap → _navigateTo(item.pageBuilder())` resolves for every single item.

---

## 6. Role/Route Protection Assessment

| Concern | Status | Notes |
|---------|--------|-------|
| Role 2 can access Role 1 pages via direct URL? | N/A | No named routes; all nav is `Navigator.push` — can't deep-link |
| Role 3 can access Role 2 pages? | N/A | Same — no route-based navigation |
| Back-navigation leaks pages? | 🟡 | `Navigator.push` stack model allows back-button to re-enter pages after logout unless `pushAndRemoveUntil` is used |
| Sidebar re-renders on role change? | ✅ | `AppSidebar` reads `roleid_login` from SharedPreferences in `initState` |
| Filter-bypass via `_resolveMenu()` fallback? | ✅ | Returns `[]` for unknown role IDs |

**Overall:** No role-escalation bugs in the current sidebar system. The `pushAndRemoveUntil` in logout correctly clears the stack. However, since there's no route-based auth guard, if someone added named routes in the future, any role could potentially navigate to any page.

---

## 7. All Pages in `lib/pages/` — Full Inventory

| File | Class | In Menu? | Access Path | Status |
|------|-------|----------|-------------|--------|
| `dashboard.dart` | `DashboardPage` | ✅ Role 1,2 | Sidebar + "Master Wilayah" redirect | REAL |
| `report.dart` | `ReportPage` | ✅ Role 1,2 | Sidebar | MOCK |
| `personel.dart` | `PersonelPage` | ✅ Role 2 | Sidebar | REAL |
| `senjata.dart` | `SenjataPage` | ✅ Role 2 | Sidebar | REAL |
| `satwa.dart` | `SatwaPage` | ✅ Role 2 | Sidebar | MOCK |
| `inventaris.dart` | `InventarisPage` | ✅ Role 1 | Sidebar | MOCK |
| `user_page.dart` | `UserPage` | ✅ Role 1 | Sidebar | MOCK |
| **`polda.dart`** | `PoldaPage` | ❌ NONE | **ORPHANED — unreachable** | **REAL** 🔴 |
| **`polres.dart`** | `PolresPage` | ❌ NONE | **ORPHANED — unreachable** | **REAL** 🔴 |
| `pangaturan.dart` | `AccountSettingPage` | ✅ All roles | Sidebar bottom | REAL |
| `placeholder_page.dart` | `PlaceholderPage` | — | Internal use only | STUB |
| `login_page.dart` | `LoginPage` | — | Logout flow only | REAL |
| `add_personel_page.dart` | `AddPersonelPage` | — | "Tambah Personel" button | REAL |
| `add_senjata.dart` | `AddSenjataPage` | — | "Tambah Senjata" button | BROKEN* |
| `add_satwa.dart` | `AddSatwaPage` | — | "Tambah Satwa" button | STUB* |
| `add_inventaris_page.dart` | `AddInventarisPage` | — | "Tambah Inventaris" button | STUB* |
| `add_polda.dart` | `AddPoldaPage` | — | "Tambah Polda" button → parent orphaned | REAL |
| `add_polres.dart` | `AddPolresPage` | — | "Tambah Polres" button → parent orphaned | REAL |
| `add_user.dart` | `AddUserPage` | — | "Tambah Pengguna" button | STUB* |

> *See `crud_integrity_audit_report.md` for details on broken/stub form pages.

---

## 8. Severity Ranking

| # | Issue | Severity | Description |
|---|-------|----------|-------------|
| 1 | **polda.dart & polres.dart orphaned** | 🔴 Critical | Two fully functional API-backed CRUD pages have zero sidebar entries |
| 2 | **"Master Wilayah" → Dashboard** | 🟠 High | Label-to-page mismatch; user clicks "Master Wilayah," gets dashboard |
| 3 | **Pengaturan dual-definition** | 🟡 Medium | Same item defined in menu_config and hardcoded in sidebar |
| 4 | **Mock pages disguised as real** | 🟡 Medium | report, satwa, inventaris render DataTables but use static dummy data |
| 5 | **Pengaturan pageBuilder fragmentation** | 🟢 Low | `_st` in menu_config vs `_stubSettings` in sidebar — both identical |
| 6 | **Role 3 bare-bones** | 🟢 Low | Only 2 items; expected for early stage |

---

## 9. Remediation Plan

### Phase 1: Fix Orphaned Pages (Critical)

1. Add `PoldaPage` and `PolresPage` imports to `menu_config.dart`
2. Add pageBuilder functions: `_po()` → `const PoldaPage()`, `_pr()` → `const PolresPage()`
3. Fix "Master Wilayah" (Role 1) to route to `PoldaPage` instead of Dashboard
4. Add "Master Polres" as a new `LeafMenuItem` under Role 1's "Master Data Sistem" group

### Phase 2: Clean Redundancy

5. Remove `_stubSettings` from `app_sidebar.dart`; use menu_config's `_st` via `_commonBottomItems` removal of the filter hack
6. Remove the `if (item.routeName == "pengaturan") continue;` filter from `_buildMenuItems()`
7. Keep the hardcoded bottom Pengaturan slot OR consolidate into `_commonBottomItems` flow — pick one path

### Phase 3: Roadmap Alignment

8. Flag mock pages in UI with "Data Demo" badge until API is wired
9. Prioritize Stok Amunisi, Sarpras, DMS, VoIP, Conference placeholder pages by stakeholder demand
10. Add named routes + route guards when deep-linking is needed

---

## 10. Files Requiring Changes

| File | Change |
|------|--------|
| `lib/config/menu_config.dart` | Add `PoldaPage`/`PolresPage` imports + pageBuilders + menu items; fix "Master Wilayah" |
| `lib/widget/app_sidebar.dart` | Remove `_stubSettings` / `pangaturan.dart` import (optional — consolidate) |

**No changes needed to polda.dart, polres.dart, or any page file.** The pages themselves are fully functional — only the menu config needs updates.

---

**Audit prepared by:** Automated code scan
**Status:** Awaiting APPROVE before code changes
