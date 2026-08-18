# Flutter Frontend Feature Audit — SINDOMON

> **Audit Date:** 2025-07-17  
> **Base URL:** `https://sindomon.cml-indonesia.com`  
> **Framework:** Flutter 3.x (Desktop: Windows / Linux / macOS)  
> **Language:** Indonesian (UI), Dart (code)

---

## 1. User-Facing Screens (Pages)

### 1.1 Authentication

| Screen | Route Key | File | Status |
|--------|-----------|------|--------|
| **Login Page** | (entry) | `lib/pages/login_page.dart` | ✅ Working |
| **Account Settings (Pengaturan)** | (popup) | `lib/pages/pangaturan.dart` | ✅ Working |

**Login Page details:**
- Username + Password fields
- Error states with inline red borders
- SnackBar error for invalid credentials
- On success: stores JWT token, username, `roleid_login`, `polda_login`, `uuid_login`, `expired_login` in `SharedPreferences`
- Navigates to `DashboardPage` on success

**Account Settings (`pangaturan.dart`):**
- Accessible from AppHeader profile dropdown *and* Command Center executive avatar
- Displays: Username, Role label, Polda name (fetched from `/api/v1/profile`)
- Read-only info cards in glass-surface style
- Logout button (clears all SharedPreferences, navigates to LoginPage)

---

### 1.2 Data Management Pages (Entity CRUD)

Each page follows the identical layout pattern:
`AppScaffold` → title row with "Tambah X" button → `AppSearchField` → `GlassSurface`-wrapped `DataTable` → `ActionButtons` (edit/delete) → `AppPagination`

| Page | Title | Route Key | API Endpoint | Status |
|------|-------|-----------|--------------|--------|
| **Personel** | Manajemen Personel | `personel` | `GET/DELETE /api/v1/sdm/personil` | ✅ CRUD |
| **Senjata** | Manajemen Senjata Api | `senjata` | `GET/DELETE /api/v1/logistik/senjata` | ✅ CRUD |
| **Satwa** | Manajemen Satwa | `satwa` | `GET/DELETE /api/v1/logistik/satwa` | ✅ CRUD |
| **Amunisi** | Manajemen Stok Amunisi | `ammo_stock` | `GET/DELETE /api/v1/logistik/amunisi` | ✅ CRUD |
| **Sarpras** | Manajemen Sarpras & Altmatsus | `sarpras` | `GET/DELETE /api/v1/logistik/sarpras` | ✅ CRUD |
| **Inventaris** | Manajemen Inventaris | (unlinked) | ❌ Hardcoded static data | 🟡 Placeholder |
| **Polda** | Master Wilayah (Polda) | `polda` | `GET/POST/PUT/DELETE /api/v1/master/polda` | ✅ CRUD |
| **Polres** | Master Polres | `polres` | `GET/POST/PUT/DELETE /api/v1/master/polres` | ✅ CRUD |
| **User** | Daftar Pengguna | `pengguna` | `GET/POST/PUT/DELETE /api/v1/user` | ✅ CRUD |
| **Master Kategori Senjata** | Master Logistik (Kategori) | `kategori_senjata` | `GET/POST/PUT/DELETE /api/v1/master/kategori-senjata` | ✅ CRUD (inline dialog) |

---

### 1.3 Dashboard & Special Screens

| Screen | Route Key | File | Status |
|--------|-----------|------|--------|
| **Dashboard (Super Admin / Operator)** | `dashboard` | `lib/pages/dashboard.dart` | 🟡 Placeholder ("Segera Hadir") |
| **Command Center Nasional** | `dashboard` | `lib/pages/dashboard.dart` | ✅ Full-featured |

**Command Center (Role "3" only):**
- Full-screen `FlutterMap` with satellite imagery (ArcGIS World Imagery)
- Polda markers with HUD-style glowing indicators (cyan pulse rings)
- KPI overlay panels (glass-morphism, cyan accent):
  - **Total Personel** (national aggregate)
  - **Defense Equipment** (readiness percentage)
  - **Vacant Position** (selisih kekurangan)
  - **Active Fleet** (hardcoded "300")
  - **K9 Standby** (national aggregate)
- **Sitkamtibmas Reports** feed panel (left bottom) — scrolling list of recent incidents with criticality level
- **Drill-down dialog** on marker tap: fetches per-Polda aggregates (`/api/v1/dashboard/drilldown?polda_id=X`) including personel totals, weapon readiness, K9/satwa counts
- Floating executive avatar (top-right) with Settings/Logout popup
- Map constrained to Indonesian bounding box

---

### 1.4 Placeholder Pages (Stubs)

The following menu items render `PlaceholderPage` (construction icon + "Fitur dalam pengembangan" text):

| Menu Item | Route Key | Assigned Role |
|-----------|-----------|---------------|
| Binding Perangkat | `binding_device` | Role 1 |
| Bagan Organisasi (Org-Tree) | `org_tree` | Role 1, 2 |
| Pemantauan Proses Hukum | `process_law` | Role 2 |
| Kotak Masuk (Inbox) | `dms_inbox` | Role 2 |
| Kotak Keluar (Outbox) | `dms_outbox` | Role 2 |
| Log Sitkamtibmas | `sitkamtibmas` | Role 2 |
| Direktori Panggilan (VoIP) | `voip_directory` | Role 2 |
| Ruang Konferensi | `conference` | Role 2 |
| Perpustakaan Digital | `digital_library` | Role 2 |
| Pengaduan Masyarakat | `public_complaint` | Role 2 |
| Status Patroli GPS | `patrol_gps` | Role 2 |

---

## 2. Forms & Data Entry

### 2.1 Form: Personel (`lib/widget/form_input_personel.dart`)

**Page wrapper:** `lib/pages/add_personel_page.dart` (Create/Edit via `AddPersonelPage`)

| Field | Type | Required | Source |
|-------|------|----------|--------|
| NRP | Text input | ✅ | Manual |
| Nama Lengkap | Text input | ✅ | Manual |
| Polda | Dropdown | ✅ | `GET /api/v1/polda` |
| Polres | Dropdown (cascading) | ❌ (optional) | Derived from selected Polda's `polres` array |
| Pangkat | Dropdown | ✅ | `GET /api/v1/pangkat` |
| Jabatan | Dropdown | ✅ | `GET /api/v1/jabatan` |

**Role-based behavior:**
- **Operator Polda (role "2"):** Polda dropdown is **locked** to the user's own Polda (`polda_login` from SharedPreferences). Polres defaults to "Tidak Ada / Mako Polda".
- **Super Admin (role "1") / Command Center (role "3"):** All dropdowns are freely selectable.

**Edit mode:** Pre-fills all fields from `personilData`. NRP and Polda are preserved. API: `POST /api/v1/sdm/personil` (create) or `POST /api/v1/sdm/personil/{id}?_method=PUT` (edit).

---

### 2.2 Form: Senjata (`lib/widget/form_input_senjata.dart`)

**Page wrapper:** `lib/pages/add_senjata.dart` (Create/Edit)

| Field | Type | Required | Source |
|-------|------|----------|--------|
| Nomor Seri | Text input | ✅ | Manual |
| Tahun Pengadaan | Text input | ✅ | Manual |
| Polda | Dropdown | ✅ | `GET /api/v1/polda` |
| Kategori | Dropdown | ✅ | `GET /api/v1/master/kategori-senjata` |
| Foto Fisik | Image picker | ✅ (create only) | Camera / Gallery → WebP compress → Multipart upload |

**Image pipeline:** Camera or Gallery → `image_picker` → `flutter_image_compress` (WebP, 1280px, quality 80) → multipart POST. Falls back to original bytes if compress unavailable (Linux/Windows desktop). Edit mode: image is optional (existing photo is kept if not changed).

---

### 2.3 Form: Satwa K9 & Turangga (`lib/widget/form_inputan_satwa.dart`)

**Page wrapper:** `lib/pages/add_satwa.dart` (Create/Edit)

| Field | Type | Required | Source |
|-------|------|----------|--------|
| Nomor Registrasi | Text input | ✅ | Manual |
| Nama Satwa | Text input | ✅ | Manual |
| Nama Handler | Text input | ✅ | Manual |
| Jenis Satwa | Dropdown | ✅ | Static: `K9`, `Turangga` |
| Kualifikasi | Dropdown | ✅ | Static: `Narkotika`, `Handak`, `Dalmas`, `Kriminal Umum`, `Patroli`, `Pelacak` |
| Jadwal Vaksin | Date picker | ✅ | Native DatePicker |
| Foto | Image picker | ✅ (create) | Camera / Gallery → WebP → Multipart |

---

### 2.4 Form: Amunisi (`lib/widget/form_input_amunisi.dart`)

**Page wrapper:** `lib/pages/add_amunisi.dart` (Create/Edit)

| Field | Type | Required | Source |
|-------|------|----------|--------|
| Kode Batch | Text input | ✅ | Manual |
| Jumlah Butir | Text input | ✅ | Manual |
| Polda | Dropdown | ✅ | `GET /api/v1/polda` |
| Kategori (Kaliber) | Dropdown | ✅ | `GET /api/v1/master/kategori-senjata` |
| Tanggal Masuk | Date picker | ✅ | Native DatePicker |
| Tanggal Kedaluwarsa | Date picker | ✅ | Native DatePicker |

---

### 2.5 Form: Sarpras & Altmatsus (`lib/widget/form_input_sarpras.dart`)

**Page wrapper:** `lib/pages/add_sarpras.dart` (Create/Edit)

| Field | Type | Required | Source |
|-------|------|----------|--------|
| Kode Barang | Text input | ✅ | Manual |
| Nama Barang | Text input | ✅ | Manual |
| Kategori | Dropdown | ✅ | Static: `Kendaraan`, `Perlengkapan Kantor`, `Perlengkapan Dalmas`, `Alat Komunikasi`, `Kendaraan Taktis` |
| Kondisi | Dropdown | ✅ | Static: `Baik`, `Rusak Ringan`, `Rusak Berat` |
| Tahun Pengadaan | Year picker | ✅ | `showDatePicker` in year mode |
| Foto | Image picker | ✅ (create) | Camera / Gallery → WebP → Multipart |

---

### 2.6 Form: User (`lib/widget/form_input_user.dart`)

**Page wrapper:** `lib/pages/add_user.dart` (Create/Edit)

| Field | Type | Required | Source |
|-------|------|----------|--------|
| Username | Text input | ✅ | Manual |
| Password | Text input (obscured) | ✅ (create only) | Manual |
| Role | Dropdown | ✅ | Static: `Super Admin (1)`, `Operator Polda (2)`, `Command Center (3)` |
| Polda | Dropdown | ✅ (conditional) | `GET /api/v1/polda` — required only for Operator Polda role |
| Status Aktif | Toggle/Switch | ✅ | Boolean toggle |

---

### 2.7 Form: Polda (`lib/widget/form_input_polda.dart`)

| Field | Type | Required | Source |
|-------|------|----------|--------|
| Nama Polda | Text input | ✅ | Manual |
| Latitude | Text input | ✅ | Manual |
| Longitude | Text input | ✅ | Manual |

---

### 2.8 Form: Polres (`lib/widget/form_input_polres.dart`)

| Field | Type | Required | Source |
|-------|------|----------|--------|
| Nama Polres | Text input | ✅ | Manual |
| Polda | Dropdown | ✅ | `GET /api/v1/polda` |

---

### 2.9 Form: Inventaris (`lib/widget/form_inputan_inventaris.dart`)

| Field | Type | Required | Source |
|-------|------|----------|--------|
| Nama Aset | Text input | ❌ | Manual |
| Kategori | Dropdown | ❌ | (not fully wired) |
| Kondisi | Text input | ❌ | Manual |
| Foto | Image picker | ❌ | Gallery only (no camera, no WebP compress) |

**⚠️ Note:** The Inventaris page uses **hardcoded static data** (5x "APC Anoa-2 6x6" rows). Its form is not connected to any API — it is a UI prototype only.

---

### 2.10 Form: Master Kategori Senjata (Inline Dialog)

No separate form widget — uses an **inline `showDialog`** with two fields:

| Field | Type | Required |
|-------|------|----------|
| Tipe Laras | Dropdown | ✅ (Static: `Panjang`, `Pendek`) |
| Kaliber | Text input | ✅ |

---

## 3. User Actions (Data Table Operations)

### 3.1 Per-Entity Action Matrix

| Entity | Create | Read (Table) | Edit | Delete | Pagination | Search |
|--------|--------|-------------|------|--------|------------|--------|
| **Personel** | ✅ | ✅ | ✅ | ✅ (confirm dialog) | ✅ (server-side) | ✅ (debounced 400ms) |
| **Senjata** | ✅ | ✅ | ✅ | ✅ (confirm dialog) | ✅ | ✅ |
| **Satwa** | ✅ | ✅ | ✅ | ✅ (confirm dialog) | ✅ | ✅ |
| **Amunisi** | ✅ | ✅ | ✅ | ✅ (confirm dialog) | ✅ | ✅ |
| **Sarpras** | ✅ | ✅ | ✅ | ✅ (confirm dialog) | ✅ | ✅ |
| **Inventaris** | ❌ (mock form) | ✅ (static data) | ❌ | ❌ | ❌ | ❌ |
| **Polda** | ✅ | ✅ | ✅ | ✅ (confirm dialog) | ✅ | ✅ |
| **Polres** | ✅ | ✅ | ✅ | ✅ (confirm dialog) | ✅ | ✅ |
| **User** | ✅ | ✅ | ✅ | ✅ (confirm dialog) | ✅ | ✅ |
| **Kategori Senjata** | ✅ (inline dialog) | ✅ | ✅ (inline dialog) | ✅ (confirm dialog) | ✅ | ✅ |

### 3.2 Delete Flow
All delete operations follow the same pattern:
1. `AlertDialog` confirmation with entity name
2. `HudLoading.show()` overlay ("MENGHAPUS...")
3. `DELETE /api/v1/{resource}/{id}` RESTful path-param call
4. Success: Green SnackBar + auto-refresh list
5. Failure: Red/Orange SnackBar with error message
6. `HudLoading.hide()` in all code paths (including catch)

### 3.3 Edit Flow
1. Navigate to `Add*Page` with `initialData` / `personilData` map
2. Form pre-fills all fields from existing data
3. On submit: POST with `?_method=PUT` for Personel; POST/PUT for others depending on ID presence
4. On success: `Navigator.pop(context, true)` triggers list refresh

### 3.4 Action Buttons Component
`lib/widget/action_buttons.dart` — Two ghost icon buttons with hover effects:
- **Edit** (blue pencil icon) — hover: blue background tint
- **Delete** (red trash icon) — hover: red background tint
- Both gray/invisible when not hovered (minimalist design)

---

## 4. Role-Based UI

### 4.1 Three Roles

| Role ID | Label | Menu System |
|---------|-------|-------------|
| `"1"` | Super Admin | Dashboard + Laporan + User Management + Master Data (Polda/Polres/Org/Logistik) |
| `"2"` | Operator Polda | Dashboard + Laporan + 7 groups (SDM, Logistik, DMS, Operasional, Komunikasi, Hub Info, Mobile) |
| `"3"` | Command Center | Single item: "Command Center Nasional" → full-screen map dashboard |

### 4.2 Sidebar Role Resolution

`AppSidebar._resolveMenu()` loads `roleid_login` from SharedPreferences independently (not passed from parent). Falls back to `commonTopItems` (Dashboard only) for unrecognized roles. The sidebar loads asynchronously — shows `HudLoadingSpinner` while `_loaded` is false.

### 4.3 Role-Gated Features

| Feature | Gate | Mechanism |
|---------|------|-----------|
| **Command Center Map** | `_roleId == "3"` | Dashboard switches between full-screen map and placeholder card |
| **Polda API call in Dashboard** | `_roleId != "3"` → return early | Skips `getPoldaApi()` for non-CC roles |
| **Polda dropdown lock (Personel form)** | `role == "2"` → `_poldaLocked = true` | Operator Polda cannot change Polda selection; forced to their own Polda |
| **Sidebar menu items** | Entire menu trees differ per role | `roleMenus` map in `menu_config.dart` |

### 4.4 Menu Structure — Role "2" (Operator Polda) — Most Feature-Rich

| Menu Group | Items |
|------------|-------|
| Manajemen SDM | Org-Tree 🟡, Direktori Personel ✅, Pemantauan Proses Hukum 🟡 |
| Logistik & Aset | Inventaris Senjata ✅, Stok Amunisi ✅, Sarpras & Altmatsus ✅, Satwa K9 & Turangga ✅ |
| Administrasi (DMS) | Kotak Masuk 🟡, Kotak Keluar 🟡 |
| Operasional & Kamtibmas | Log Sitkamtibmas 🟡 |
| Komunikasi Taktis | Direktori Panggilan (VoIP) 🟡, Ruang Konferensi 🟡 |
| Hub Informasi Terpadu | Perpustakaan Digital 🟡, Pengaduan Masyarakat 🟡 |
| Mobile | Status Patroli GPS 🟡 |

✅ = Working CRUD page &nbsp; 🟡 = Placeholder stub

---

## 5. Special UI Features & Components

### 5.1 HUD Loading System

**`HudLoadingSpinner`** (`lib/widget/hud_loading_spinner.dart`):
- "Arc Reactor" / sci-fi style animated spinner
- Three layers: outer dashed ring (clockwise), inner solid cyan arc (counter-clockwise), glowing cyan core (concentric opacity-falloff circles)
- Configurable: `size`, `outerStrokeWidth`, `innerStrokeWidth`, `label`, `labelSize`, `animate` toggle
- No `MaskFilter` — uses pure opacity for Impeller compatibility
- Cyan-colored label text in monospace HUD typography

**`HudLoading`** overlay helper (`lib/utils/hud_loading.dart`):
- Full-screen non-dismissible modal overlay
- `show(context, label:)` → `hide(context)` pair
- Uses `useRootNavigator: true` for global overlay
- `PopScope(canPop: false)` prevents accidental dismissal
- Safe `hide()` — try/catch on `Navigator.pop` so it never crashes

**Usage:** Every delete operation shows "MENGHAPUS..." overlay. Every form submit shows "MENYIMPAN..." overlay. Every page load shows inline `HudLoadingSpinner` (not the modal overlay).

### 5.2 Glass Surface (`lib/widget/glass_surface.dart`)
- Reusable container with glass-morphism effect
- Used as the wrapper for all DataTables, info cards, and form containers
- Configurable `borderRadius`, `padding`, `width`

### 5.3 AppBackground (`lib/widget/background.dart`)
- Full-bleed background image stack
- Used on Login page and all authenticated pages via `AppScaffold`

### 5.4 Cyber Circuit Painter (`lib/widget/cyber_circuit_painter.dart`)
- 28KB custom painter file
- Likely used for sci-fi/cyberpunk decorative elements (HUD-style circuit lines)

### 5.5 Collapsible Sidebar
- Animated width: 240px (expanded) ↔ 80px (collapsed)
- Smooth `AnimatedContainer` transition (300ms easeOutCubic)
- Text/logo labels fade with `AnimatedOpacity` using `Interval(0.5, 1.0)` curve
- ExpansionTile groups preserved via Offstage Strategy B — both expanded and collapsed widgets stay mounted to avoid `mouse_tracker.dart` assertion errors
- Bottom control cluster: Theme toggle (J.A.R.V.I.S dark / Corporate light) + Collapse/Expand toggle
- `SINDOMON` logo (Korsabhara) always visible, scales down in collapsed mode

### 5.6 AppHeader Profile Dropdown
- Username + Role label + amber circle avatar
- `PopupMenuButton` with **Pengaturan** (settings) and **Logout** options
- Breadcrumb text ("Dashboard / Personel") with amber home icon

### 5.7 AppFooter
- Copyright notice + version text
- Present on all standard authenticated pages (hidden in Command Center full-screen mode)

### 5.8 AppSearchField
- Styled search text field with search icon
- Used on all data pages with 400ms debounced input → API call → page reset to 1

### 5.9 AppPagination
- Server-side pagination UI: Previous / Page numbers / Next
- Shows "Showing X-Y of Z items" summary
- Fully wired to `_onPageChanged` → API re-fetch on all data pages

### 5.10 Theme System
- **Two themes:** Light (Corporate) and Dark (J.A.R.V.I.S)
- `ThemeController` with `ValueNotifier<ThemeMode>`, persisted to SharedPreferences key `theme_mode`
- `ThemeScope` InheritedWidget for tree-wide access
- `SidebarColors` — brightness-aware color scheme for sidebar elements

### 5.11 Image Handling
- **Cached Network Images:** `cached_network_image` package for photo thumbnails in Senjata, Satwa, Sarpras tables
- **Image URL resolution:** Relative paths are prefixed with `apiBaseUrl`; leading slash handling prevents malformed domain errors
- **Thumbnail placeholders:** Grey containers with `image_not_supported` icon for missing images; `CircularProgressIndicator` during load; `broken_image` on error

### 5.12 Special Status Badges
- **Amunisi H-90 Alert:** If `is_h90_alert` flag is true → red badge "H-90 ALERT" with warning triangle icon; otherwise green "AMAN" badge
- **Satwa Vaksin Urgency:** If `jadwal_vaksin` is < 30 days from today → red vaccine syringe icon with tooltip "Vaksinasi kurang dari 30 hari atau sudah lewat"
- **Tipe Laras Badge (Kategori):** "Panjang" → amber chip; "Pendek" → blue chip

### 5.13 Command Center Map Overlays (Role 3 exclusive)
- HUD-style glowing marker with pulsing cyan ring animation
- Glass-morphism KPI panels with cyan accent borders
- `BackdropFilter` blur effects on executive avatar
- Dark tint overlay (20% opacity) over satellite map
- Drill-down dialog fetches real per-Polda data asynchronously

---

## 6. Routing & Navigation Summary

- **No router package** — all navigation uses `Navigator.push(MaterialPageRoute(...))`
- **No route-level role guards** — any page is reachable by direct navigation regardless of role
- **Entry point:** `MaterialApp(home: LoginPage)`
- **Logout:** `Navigator.pushAndRemoveUntil` → LoginPage (clears entire stack)
- **Form submission success:** `Navigator.pop(context, true)` → triggers list refresh on parent page
- **Sidebar menu:** navigates to pages via `_navigateTo(Widget page)` — creates new `MaterialPageRoute` each time (no route reuse)

---

## 7. Known Gaps & Observations

1. **Inventaris page** uses hardcoded static data — no API integration
2. **11 placeholder stubs** (`PlaceholderPage`) for menu items not yet implemented
3. **No token expiry handling** — no refresh logic; app starts at LoginPage every launch
4. **No route guards** — role-based access control is purely UI-level (sidebar items + dashboard content switch); direct navigation is unrestricted
5. **No `Laporan` page** is actually rendered — `commonTopItems` only contains Dashboard (the `Laporan` mentioned in CLAUDE.md may refer to the `report.dart` file which is absent from the current file listing)
6. **`data_table_2`** package is declared in pubspec but not used; standard `DataTable` is used instead
7. **Pagination** is fully wired to backend on all data pages — uses `{ items: [...], pagination: {...} }` response shape with legacy flat-list fallback
8. **Authorization header** uses token WITHOUT "Bearer" prefix (`"Authorization": token.toString()`)
9. **Image compression** via `flutter_image_compress` may not work on Windows/Linux desktop — falls back to uncompressed upload
10. **No unit tests** — `flutter_test` declared but no `test/` directory exists
