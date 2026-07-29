# Sidebar Analysis & Refactoring Plan — SINDOMON

## 1. Current State Analysis

### 1.1 Duplication
The sidebar (Container + Column + ListView + `menu()` helper + `logout()` method) is **copy-pasted inline into 17 page files**. No shared `AppSidebar` widget exists. ~2,500 lines of duplicate code.

| # | File | Sidebar lines |
|---|------|--------------|
| 1 | `lib/pages/dashboard.dart` | ~150 lines (plus 90 lines of new-menu code) |
| 2 | `lib/pages/report.dart` | ~150 lines |
| 3 | `lib/pages/personel.dart` | ~150 lines |
| 4 | `lib/pages/senjata.dart` | ~150 lines |
| 5 | `lib/pages/satwa.dart` | ~150 lines |
| 6 | `lib/pages/inventaris.dart` | ~150 lines |
| 7 | `lib/pages/polda.dart` | ~150 lines |
| 8 | `lib/pages/polres.dart` | ~150 lines |
| 9 | `lib/pages/user_page.dart` | ~150 lines |
| 10 | `lib/pages/pangaturan.dart` | ~150 lines |
| 11-17 | `lib/pages/add_*.dart` (7 files) | ~150 lines each |

### 1.2 Inconsistencies Found

| Issue | Detail |
|-------|--------|
| **Logo** | `dashboard.dart` uses `Image.asset("assets/images/polri-logo.png")`. All 16 other pages use `CircleAvatar` + `Icons.security`. |
| **Subtitle** | Varies: "Management Dashboard" vs "Management System" vs "Management Report" vs "Management Inventaris" |
| **Label** | `senjata.dart` and `user_page.dart` label the item "Senjata Api"; others label it "Senjata" |
| **Navigation switch** | 5 pages (`satwa`, `inventaris`, `report`, `personel`, `pangaturan`) are missing "Polda"/"Polres" cases — clicking those menu items silently redirects to DashboardPage instead |
| **Role consumption** | Only `dashboard.dart` reads `roleid_login` from SharedPreferences. All 16 other pages ignore roles entirely and show the identical flat old menu |
| **AppHeader role** | Every page hardcodes `role: "Super Admin"` in AppHeader call instead of passing actual logged-in role |

### 1.3 Old Menu Structure (17-page copy-paste)

```
Dashboard         → Icons.dashboard_rounded
Laporan           → Icons.description_rounded
Wilayah           → Icons.map_rounded
Inventaris        → Icons.inventory_2_rounded
Organisasi        → Icons.groups_rounded
Satwa             → Icons.pets_rounded
Polda             → Icons.people_alt_rounded
Polres            → Icons.people_alt_rounded
Senjata/Api       → Icons.gavel_rounded
Kotak Masuk       → Icons.move_to_inbox_rounded
Kotak Keluar      → Icons.outbox_rounded
Personel          → Icons.badge_rounded
Stok Amunisi      → Icons.inventory_rounded
Perangkat         → Icons.memory_rounded
Pengguna          → Icons.people_alt_rounded
--- divider ---
Pengaturan        → Icons.settings_rounded  (bottom)
Logout            → Icons.logout_rounded    (bottom)
```

### 1.4 New Menu Structure (dashboard.dart only, role-based)

Roles: `"1"` = Super Admin, `"2"` = Operator Polda, `"3"` = Command Center Nasional.

All `onTap: null` — non-functional placeholders.

**Role 1 — Super Admin:**
- Manajemen Keamanan & Akun
  - Daftar Pengguna
  - Binding Perangkat
- Master Data Sistem
  - Master Wilayah
  - Master SDM & Organisasi
  - Master Logistik

**Role 2 — Operator Polda:**
- Manajemen SDM
  - Bagan Organisasi (Org-Tree)
  - Direktori Personel
  - Pemantauan Proses Hukum
- Logistik & Aset
  - Inventaris Senjata
  - Stok Amunisi
  - Sarpras & Altmatsus
  - Satwa K9 & Turangga
- Administrasi (DMS)
  - Kotak Masuk (Inbox)
  - Kotak Keluar (Outbox)
- Operasional & Kamtibmas
  - Log Sitkamtibmas
- Komunikasi Taktis
  - Direktori Panggilan (VoIP)
  - Ruang Konferensi
- Hub Informasi Terpadu
  - Perpustakaan Digital
  - Pengaduan Masyarakat
- Mobile
  - Status Patroli GPS

**Role 3 — Command Center Nasional:**
- Command Center Nasional

### 1.5 Technical Stack
- No state management (no Provider/Riverpod/Bloc/GetX)
- No navigation package (no go_router)
- No Flutter `Drawer` usage — sidebar is a `Container(width: 260)` inside a `Row`
- SharedPreferences for token/role storage
- `http` package for API calls
- `flutter_map` + `latlong2` for map (dashboard only)

---

## 2. Old → New Menu Mapping

| Old Flat Item | Existing Page | New Role | New Parent Group | New Child Label |
|---|---|---|---|---|
| Dashboard | `DashboardPage` | ALL | — (top-level) | Dashboard |
| Laporan | `ReportPage` | ALL | — (top-level) | Laporan |
| Wilayah | (none) | 1 | Master Data Sistem | Master Wilayah |
| Polda | `PoldaPage` | 1 | Master Data Sistem > Master Wilayah* | Polda |
| Polres | `PolresPage` | 1 | Master Data Sistem > Master Wilayah* | Polres |
| Organisasi | (none) | 1 | Master Data Sistem | Master SDM & Organisasi |
| Organisasi | (none) | 2 | Manajemen SDM | Bagan Organisasi (Org-Tree) |
| Personel | `PersonelPage` | 2 | Manajemen SDM | Direktori Personel |
| Inventaris | `InventarisPage` | 1 | Master Data Sistem | Master Logistik |
| Senjata / Senjata Api | `SenjataPage` | 2 | Logistik & Aset | Inventaris Senjata |
| Stok Amunisi | (stub) | 2 | Logistik & Aset | Stok Amunisi |
| Satwa | `SatwaPage` | 2 | Logistik & Aset | Satwa K9 & Turangga |
| Kotak Masuk | (stub) | 2 | Administrasi (DMS) | Kotak Masuk (Inbox) |
| Kotak Keluar | (stub) | 2 | Administrasi (DMS) | Kotak Keluar (Outbox) |
| Perangkat | (stub) | 1 | Manajemen Keamanan & Akun | Binding Perangkat |
| Pengguna | `UserPage` | 1 | Manajemen Keamanan & Akun | Daftar Pengguna |
| — | — | 2 | Manajemen SDM | Pemantauan Proses Hukum |
| — | — | 2 | Logistik & Aset | Sarpras & Altmatsus |
| — | — | 2 | Operasional & Kamtibmas | Log Sitkamtibmas |
| — | — | 2 | Komunikasi Taktis | Direktori Panggilan (VoIP) |
| — | — | 2 | Komunikasi Taktis | Ruang Konferensi |
| — | — | 2 | Hub Informasi Terpadu | Perpustakaan Digital |
| — | — | 2 | Hub Informasi Terpadu | Pengaduan Masyarakat |
| — | — | 2 | Mobile | Status Patroli GPS |
| — | — | 3 | — (top-level) | Command Center Nasional |
| Pengaturan | `AccountSettingPage` | ALL | — (bottom fixed) | Pengaturan |
| Logout | logout() | ALL | — (bottom fixed) | Logout |

> *Polda/Polres are sub-items within "Master Wilayah" for role 1. For role 2, they are not in the new spec.

---

## 3. Refactoring Strategy (Phased)

### Phase 1: Menu Data Layer — `lib/config/menu_config.dart`

Define menus as **data, not widgets**. A single source of truth:

```dart
class MenuItem {
  final String label;
  final IconData icon;
  final String? routeName;
  final Widget Function()? pageBuilder;
  final List<MenuItem>? children;
}

class MenuGroup {
  final String label;
  final IconData icon;
  final List<MenuItem> children;
}
```

### Phase 2: Centralized Widget — `lib/widget/app_sidebar.dart`

Single `AppSidebar` widget replacing all 17 inline copies:

```dart
class AppSidebar extends StatefulWidget {
  final String currentRoute;
  @override
  State<AppSidebar> createState() => _AppSidebarState();
}
```

**Responsibilities:**
- Reads `roleid_login` from SharedPreferences (self-contained loading)
- Builds the sidebar Container (260px, indigo bg, rounded corners)
- Renders: Logo (unified → PNG asset), title "SINDOMON", subtitle
- Renders role-appropriate menu from `menu_config.dart`
- Handles navigation directly via `Navigator.push`
- Handles logout (clears SharedPreferences, navigates to LoginPage)
- Highlights current page
- Fixed bottom: divider + Pengaturan + Logout

**Logo:** Unified to `Image.asset("assets/images/polri-logo.png")`.

**Subtitle:** Unified to `"Sistem Informasi Manajemen"`.

### Phase 3: Placeholder Pages

Create stub pages for new menu items without existing pages:

- `lib/pages/org_tree_page.dart`
- `lib/pages/process_law_page.dart`
- `lib/pages/sarpras_page.dart`
- `lib/pages/ammo_stock_page.dart`
- `lib/pages/dms_inbox_page.dart`
- `lib/pages/dms_outbox_page.dart`
- `lib/pages/sitkamtibmas_page.dart`
- `lib/pages/voip_directory_page.dart`
- `lib/pages/conference_page.dart`
- `lib/pages/digital_library_page.dart`
- `lib/pages/public_complaint_page.dart`
- `lib/pages/patrol_gps_page.dart`
- `lib/pages/command_center_page.dart`
- `lib/pages/binding_device_page.dart`

### Phase 4: Refactor All Existing Pages

For each page file: remove inline sidebar Container, `menu()` method, `logout()` method. Replace with `<AppSidebar currentRoute="xxx" />`.

**Page identity mapping:**

| Page | `currentRoute` |
|------|---------------|
| DashboardPage | `"dashboard"` |
| ReportPage | `"report"` |
| PersonelPage | `"personel"` |
| SenjataPage | `"senjata"` |
| SatwaPage | `"satwa"` |
| InventarisPage | `"inventaris"` |
| PoldaPage | `"polda"` |
| PolresPage | `"polres"` |
| UserPage | `"pengguna"` |
| AccountSettingPage | `"pengaturan"` |

Also fix AppHeader: pass actual `_roleId` instead of `"Super Admin"`.

### Phase 5: Cleanup & Verification

- Delete old "OLD MENU BELOW" divider from dashboard
- `flutter analyze` — fix compilation issues
- Role switching smoke test
- Navigation smoke test
- Highlight verification

---

## 4. Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| Breaking existing navigation | Phase 4 one page at a time; test each after refactoring |
| Missing page imports in AppSidebar | Centralized import list, verified at compile time |
| SharedPreferences load delay | Loading state in AppSidebar |
| Add pages have different structure | Use same `AppSidebar` with parent route as `currentRoute` |

---

## 5. File Change Summary

| Action | File | Lines |
|--------|------|-------|
| **CREATE** | `lib/config/menu_config.dart` | ~150 |
| **CREATE** | `lib/widget/app_sidebar.dart` | ~200 |
| **CREATE** | 14 placeholder pages | ~30 each |
| **MODIFY** | `lib/pages/dashboard.dart` | delete ~240, add ~10 |
| **MODIFY** | `lib/pages/report.dart` | delete ~150, add ~10 |
| **MODIFY** | `lib/pages/personel.dart` | delete ~150, add ~10 |
| **MODIFY** | `lib/pages/senjata.dart` | delete ~150, add ~10 |
| **MODIFY** | `lib/pages/satwa.dart` | delete ~150, add ~10 |
| **MODIFY** | `lib/pages/inventaris.dart` | delete ~150, add ~10 |
| **MODIFY** | `lib/pages/polda.dart` | delete ~150, add ~10 |
| **MODIFY** | `lib/pages/polres.dart` | delete ~150, add ~10 |
| **MODIFY** | `lib/pages/user_page.dart` | delete ~150, add ~10 |
| **MODIFY** | `lib/pages/pangaturan.dart` | delete ~150, add ~10 |
| **MODIFY** | `lib/pages/add_*.dart` (7 files) | delete ~150 each, add ~10 each |
| **MODIFY** | `lib/widget/app_header.dart` | accept dynamic role |

**Net:** ~23 files touched, ~3,000 lines deleted, ~600 lines added.

---

## 6. Open Questions / Punted Items

1. **API-driven menus**: Not in scope. Add when backend provides `/api/v1/menus/{role_id}` endpoint.
2. **Permission gating on data pages**: Not in scope. Add when backend enforces role-based API access.
3. **NavigationRail / responsive sidebar**: Not in scope. Add when mobile breakpoint needed.
4. **go_router migration**: Not in scope. Add when deep linking or named routes needed.

---

## 7. Execution Order

1. Create `lib/config/menu_config.dart` — data model + menu maps for 3 roles
2. Create `lib/widget/app_sidebar.dart` — centralized sidebar widget
3. Create all placeholder pages
4. Refactor `dashboard.dart` first (most complex)
5. Refactor remaining 9 content pages
6. Refactor 7 add pages
7. Fix `app_header.dart` — accept dynamic role
8. Run `flutter analyze`
9. Manual smoke test
