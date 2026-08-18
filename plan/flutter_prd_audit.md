# Flutter PRD Audit — SINDOMON Frontend User Flow & UI Feature Document

> **Status:** Ground-Truth Extraction from source code  
> **Source:** `lib/pages/`, `lib/widget/`, `lib/models/`, `lib/config/`, `lib/theme/`, `lib/utils/`  
> **Date:** 2025-01-20  
> **Auditor:** Reasonix (Senior PM & Flutter UI/UX Expert)

---

## 1. Screen Inventory (User Journey)

### 1.1 Entry Point

| # | Screen | Route | File | Status |
|---|--------|-------|------|--------|
| 1 | **Login Page** | `/` (home) | `lib/pages/login_page.dart` | ✅ Fully Working |

- Blur-glass login card (`BackdropFilter` sigma 15px) with logo, username/NRP + password fields, amber "Masuk ke Sistem" button.
- Theme toggle in top-right corner of the card.
- On success: saves 6 SharedPreferences keys and pushes `DashboardPage` (removing all previous routes).
- On HTTP 403: shows "Perangkat Anda belum terverifikasi" AlertDialog (device binding block).
- Error validation: empty username → "Username wajib diisi", empty password → "Password wajib diisi". Both empty → "Kredensial tidak valid".

---

### 1.2 Fully Working CRUD Screens

Each of these screens follows the **identical pattern**: load user info from SharedPreferences → fetch paginated list from API → render `GlassSurface` > `DataTable` with `ActionButtons` (edit/delete) → `AppPagination` footer.

| # | Screen | Route | API Endpoint | File | Notes |
|---|--------|-------|-------------|------|-------|
| 2 | **Dashboard** | `dashboard` | `GET /api/v1/dashboard/nasional` + `GET /api/v1/polda` | `lib/pages/dashboard.dart` | Dual-mode: placeholder for Role 1/2; full-screen FlutterMap Command Center for Role 3 |
| 3 | **Personel** | `personel` | `GET/POST/PUT/DELETE /api/v1/sdm/personil` | `lib/pages/personel.dart` | Columns: NRP, Nama Lengkap, Pangkat, Jabatan, Polda, Polres, Status Aktif, Aksi |
| 4 | **Senjata Api** | `senjata` | `GET/POST/DELETE /api/v1/logistik/senjata` | `lib/pages/senjata.dart` | Columns: Foto Unit (CachedNetworkImage thumbnail), No Seri, Kategori, Tahun, Aksi |
| 5 | **Satwa K9 & Turangga** | `satwa` | `GET/POST/DELETE /api/v1/logistik/satwa` | `lib/pages/satwa.dart` | Columns: Foto, No Registrasi, Jenis, Nama Satwa, Nama Handler, Kualifikasi, Jadwal Vaksin (with urgency badge), Aksi |
| 6 | **Polda (Master Wilayah)** | `polda` | `GET/POST/PUT/DELETE /api/v1/master/polda` | `lib/pages/polda.dart` | Columns: ID, Nama Polda, Latitude, Longitude, Created At, Aksi |
| 7 | **Polres (Master Polres)** | `polres` | `GET/POST/PUT/DELETE /api/v1/master/polres` | `lib/pages/polres.dart` | Columns: ID, Polda ID (with name fallback), Nama Polres, Created At, Aksi |
| 8 | **Pengguna** | `pengguna` | `GET/POST/PUT/DELETE /api/v1/user` | `lib/pages/user_page.dart` | Columns: Nama, Role (resolved label), Polda, Status (Aktif/Tidak Aktif), Aksi |
| 9 | **Amunisi** | `ammo_stock` | `GET/POST/PUT/DELETE /api/v1/logistik/amunisi` | `lib/pages/amunisi.dart` | Columns: Kode Batch, Kaliber, Jumlah Butir, Tgl Masuk, Tgl Kedaluwarsa, Status (H-90 ALERT / AMAN badge), Aksi |
| 10 | **Sarpras & Altmatsus** | `sarpras` | `GET/POST/DELETE /api/v1/logistik/sarpras` | `lib/pages/sarpras.dart` | Columns: Foto, Kode Barang, Nama Barang, Kategori, Kondisi, Aksi |
| 11 | **Master Kategori Senjata** | `kategori_senjata` | `GET/POST/PUT/DELETE /api/v1/master/kategori-senjata` | `lib/pages/master_kategori_senjata.dart` | Columns: Tipe Laras (badge), Kaliber, Aksi. **Add/Edit uses in-page AlertDialog**, not a separate navigated page. Includes stale-response guard. |
| 12 | **Profil & Pengaturan** | `pengaturan` | `GET /api/v1/profile` | `lib/pages/pangaturan.dart` | Read-only profile cards (Username, Level Akses, Polda) + device binding status card (placeholder "Perangkat Terverifikasi") |

---

### 1.3 Placeholder / Hardcoded / Stub Screens

| # | Screen | Route | File | Status |
|---|--------|-------|------|--------|
| 13 | **Inventaris** | `inventaris` | `lib/pages/inventaris.dart` | 🔴 **Hardcoded stub** — static list of 5 "APC Anoa-2 6x6" entries, local asset image, no API calls, ActionButtons are no-ops |
| 14 | **Add Inventaris Form** | (pushed) | `lib/pages/add_inventaris_page.dart` + `lib/widget/form_inputan_inventaris.dart` | 🔴 **Hardcoded stub** — form renders with `onPressed: () {}` (no-op submit), hardcoded dropdown [Rantis, Water Canon], no API integration |
| 15 | **Bagan Organisasi (Org-Tree)** | `org_tree` | `lib/pages/placeholder_page.dart` | 🔴 Placeholder — construction icon + "Fitur dalam pengembangan" |
| 16 | **Pemantauan Proses Hukum** | `process_law` | `lib/pages/placeholder_page.dart` | 🔴 Placeholder |
| 17 | **Kotak Masuk (Inbox)** | `dms_inbox` | `lib/pages/placeholder_page.dart` | 🔴 Placeholder |
| 18 | **Kotak Keluar (Outbox)** | `dms_outbox` | `lib/pages/placeholder_page.dart` | 🔴 Placeholder |
| 19 | **Log Sitkamtibmas** | `sitkamtibmas` | `lib/pages/placeholder_page.dart` | 🔴 Placeholder |
| 20 | **Direktori Panggilan (VoIP)** | `voip_directory` | `lib/pages/placeholder_page.dart` | 🔴 Placeholder |
| 21 | **Ruang Konferensi** | `conference` | `lib/pages/placeholder_page.dart` | 🔴 Placeholder |
| 22 | **Perpustakaan Digital** | `digital_library` | `lib/pages/placeholder_page.dart` | 🔴 Placeholder |
| 23 | **Pengaduan Masyarakat** | `public_complaint` | `lib/pages/placeholder_page.dart` | 🔴 Placeholder |
| 24 | **Status Patroli GPS** | `patrol_gps` | `lib/pages/placeholder_page.dart` | 🔴 Placeholder |
| 25 | **Binding Perangkat** | `binding_device` | `lib/pages/placeholder_page.dart` | 🔴 Placeholder |

> **Note:** PlaceholderPage renders with `showHeaderFooter: false`, so it displays only the construction icon + title with no AppHeader, AppFooter, or breadcrumb chrome.

---

### 1.4 Form/Add Pages (navigated from list pages)

| # | Add/Edit Screen | Widget | API Method | Image Upload | Status |
|---|----------------|--------|-----------|-------------|--------|
| F1 | Add/Edit Personel | `FormTambahPersonel` | POST/PUT JSON | No | ✅ |
| F2 | Add/Edit Senjata | `FormTambahSenjata` | POST multipart (always POST) | Yes — Camera/Gallery → WebP compress | ✅ |
| F3 | Add/Edit Satwa | `FormInputanSatwa` | POST multipart (always POST) | Yes — Camera/Gallery → WebP compress | ✅ |
| F4 | Add/Edit Polda | `FormTambahPolda` | POST/PUT JSON | No | ✅ |
| F5 | Add/Edit Polres | `FormTambahPolres` | POST/PUT JSON | No | ✅ |
| F6 | Add/Edit User | `FormTambahUser` | POST/PUT JSON | No | ✅ |
| F7 | Add/Edit Amunisi | `FormTambahAmunisi` | POST/PUT JSON | No | ✅ |
| F8 | Add/Edit Sarpras | `FormTambahSarpras` | POST multipart (always POST) | Yes — Camera/Gallery → WebP compress | ✅ |
| F9 | Add/Edit Kategori Senjata | Inline AlertDialog (`_showKategoriForm`) | POST/PUT JSON | N/A | ✅ |
| F10 | Add Inventaris | `FormTambahInventaris` | None (no-op) | Image picker but no upload | 🔴 Stub |

---

## 2. UI-Level RBAC (Role-Based Access Control)

### 2.1 Role Definitions

| Role ID | Label | SharedPreferences Key |
|---------|-------|----------------------|
| `"1"` | Super Admin | `roleid_login` |
| `"2"` | Operator Polda | `roleid_login` |
| `"3"` | Command Center | `roleid_login` |

### 2.2 Sidebar Menu Visibility

The sidebar (`AppSidebar._resolveMenu()`) independently loads `roleid_login` from SharedPreferences and resolves the menu list via `roleMenus` map in `menu_config.dart`.

#### Role 1 — Super Admin
```
├── Dashboard
├── Manajemen Keamanan & Akun (group)
│   ├── Daftar Pengguna → UserPage
│   └── Binding Perangkat → PlaceholderPage
└── Master Data Sistem (group)
    ├── Master Wilayah → PoldaPage
    ├── Master Polres → PolresPage
    ├── Master SDM & Organisasi → PlaceholderPage
    └── Master Logistik → MasterKategoriSenjataPage
```

#### Role 2 — Operator Polda
```
├── Dashboard
├── Manajemen SDM (group)
│   ├── Bagan Organisasi (Org-Tree) → PlaceholderPage
│   ├── Direktori Personel → PersonelPage
│   └── Pemantauan Proses Hukum → PlaceholderPage
├── Logistik & Aset (group)
│   ├── Inventaris Senjata → SenjataPage
│   ├── Stok Amunisi → AmunisiPage
│   ├── Sarpras & Altmatsus → SarprasPage
│   └── Satwa K9 & Turangga → SatwaPage
├── Administrasi (DMS) (group)
│   ├── Kotak Masuk (Inbox) → PlaceholderPage
│   └── Kotak Keluar (Outbox) → PlaceholderPage
├── Operasional & Kamtibmas (group)
│   └── Log Sitkamtibmas → PlaceholderPage
├── Komunikasi Taktis (group)
│   ├── Direktori Panggilan (VoIP) → PlaceholderPage
│   └── Ruang Konferensi → PlaceholderPage
├── Hub Informasi Terpadu (group)
│   ├── Perpustakaan Digital → PlaceholderPage
│   └── Pengaduan Masyarakat → PlaceholderPage
└── Mobile (group)
    └── Status Patroli GPS → PlaceholderPage
```

#### Role 3 — Command Center
```
└── Command Center Nasional → DashboardPage (map mode)
```

> The `commonTopItems` (just Dashboard) are exported as fallback for unrecognized roles.

### 2.3 Form-Level RBAC (Dropdown Locks & Conditionals)

| Form | Field | Lock Logic | File |
|------|-------|-----------|------|
| **Personel** (`FormTambahPersonel`) | Polda dropdown | Locked for Role `"2"` (Operator Polda). Reads `polda_login` from SharedPreferences, force-sets `selectedPoldaId`. `onChanged: null` greys out the field. Shows helper text "Disesuaikan dengan Polda Anda" and lock icon. Also repopulates dependent Polres list from locked Polda's `polres[]`. | `lib/widget/form_input_personel.dart:162-190` |
| **Senjata** (`FormTambahSenjata`) | Polda dropdown | `onChanged: null` (always disabled). Auto-filled from `polda_login` on create mode. No role-gating — applies to all roles. | `lib/widget/form_input_senjata.dart:373` |
| **Amunisi** (`FormTambahAmunisi`) | Polda dropdown | Same pattern as Senjata: `onChanged: null`, auto-filled from `polda_login`. | `lib/widget/form_input_amunisi.dart:350` |
| **User** (`FormTambahUser`) | Polda dropdown | Conditionally shown ONLY when `selectedRoleId == "2"`. Required for Operator Polda creation. Hidden entirely for Super Admin and Command Center roles. | `lib/widget/form_input_user.dart:439` |

### 2.4 Dashboard Content Gating

```dart
// lib/pages/dashboard.dart:158
child: _roleId == "3" ? _buildCommandCenterContent() : _buildPlaceholder()
```

- **Role 3:** Full-screen FlutterMap with HUD markers, drill-down dialogs, national summary.
- **Role 1 & 2:** Placeholder card ("Dashboard — Fitur dalam pengembangan").

Also, the Polda API call is gated:
```dart
// lib/pages/dashboard.dart:45
if (_roleId != "3") { ... return; }
```

---

## 3. Form Behaviors & Client Validations

### 3.1 Form: Personel (`FormTambahPersonel`)

| Field | Widget | Mandatory | Auto-fill / Notes |
|-------|--------|-----------|-------------------|
| NRP | `TextFormField` | ✅ * | — |
| Nama Lengkap | `TextFormField` | ✅ * | — |
| Polda | `DropdownButtonFormField<int>` (API: `GET /api/v1/polda`) | ✅ * | Locked for Role 2 → `polda_login` |
| Polres | `DropdownButtonFormField<int>` (dependent: filtered from selected Polda's `polres[]`) | ❌ | Sentinel value `0` = "Tidak Ada / Mako Polda", sent as `null` |
| Pangkat | `DropdownButtonFormField<int>` (API: `GET /api/v1/pangkat`) | ✅ * | — |
| Jabatan | `DropdownButtonFormField<int>` (API: `GET /api/v1/jabatan`) | ✅ * | — |

**Validation message:** "Semua data wajib diisi"  
**Edit mode:** Pre-fills from `personilData` map; PUT to `/api/v1/sdm/personil/{uuid}`  
**422 handling:** Stays on form, shows server validation message (e.g., duplicate NRP)  
**Layout:** Responsive `Wrap` — two columns above 700px, single column below

### 3.2 Form: Senjata (`FormTambahSenjata`)

| Field | Widget | Mandatory | Notes |
|-------|--------|-----------|-------|
| Polda | `DropdownButtonFormField<int>` | ✅ * | Locked (`onChanged: null`), auto-filled from `polda_login` |
| No Seri | `TextFormField` | ✅ * | — |
| Kategori Senjata | `DropdownButtonFormField<int>` (API: `GET /api/v1/master/kategori-senjata`) | ✅ * | Displayed as `"tipe_laras - kaliber"` |
| Tahun Pengadaan | `TextFormField` (keyboard: number) | ✅ * | — |
| Foto Senjata | Image picker (Camera/Gallery) → WebP compression → preview | ✅ * (create only) | Edit mode: "Foto lama tetap dipakai jika tidak diganti" |
| Status Kelayakan | — | Hardcoded `"Baik"` in request body | Sent automatically, no UI field |

**Image pipeline:** `image_picker` → `flutter_image_compress` (WebP, 1280px min, quality 80) → `http.MultipartRequest`  
**Submit:** Always POST (even for edit — PHP can't parse multipart PUT). ID in URL path.  
**Validation:** "Lengkapi semua data bertanda *" / "Foto senjata wajib diisi"

### 3.3 Form: Satwa (`FormInputanSatwa`)

| Field | Widget | Mandatory | Notes |
|-------|--------|-----------|-------|
| Nomor Registrasi | `TextFormField` | ✅ * | — |
| Jenis Satwa | `DropdownButtonFormField<String>` (hardcoded: `['K9', 'Turangga']`) | ✅ * | — |
| Nama Satwa | `TextFormField` | ✅ * | — |
| Nama Handler | `TextFormField` (keyboard: text) | ✅ * | — |
| Kualifikasi | `DropdownButtonFormField<String>` (hardcoded: `['Narkotika', 'Handak', 'Dalmas', 'Kriminal Umum', 'Patroli', 'Pelacak']`) | ✅ * | — |
| Jadwal Vaksin | `DatePicker` (via InputDecorator) | ✅ * | — |
| Foto Satwa | Image picker → WebP compress | ✅ * (create only) | Same pipeline as Senjata |

### 3.4 Form: User (`FormTambahUser`)

| Field | Widget | Mandatory | Notes |
|-------|--------|-----------|-------|
| Username | `TextFormField` | ✅ * | — |
| Password | `TextFormField` (obscured) | ✅ * (create only) | Edit label: "kosongkan jika tidak berubah" |
| Role | `DropdownButtonFormField<String>` (hardcoded: `"1"` Super Admin, `"2"` Operator Polda, `"3"` Command Center) | ✅ * | Changing away from "2" clears Polda selection |
| Status | `Switch` (Aktif/Tidak Aktif) | ❌ (defaults true) | Sends `"aktif"` or `"tidak_aktif"` |
| Polda | `DropdownButtonFormField<String>` (API: `GET /api/v1/polda`) | ⚠️ Conditional | Only shown when `selectedRoleId == "2"`. Required for Operator Polda. Hidden for Super Admin/Command Center. |

**Additional validation:** "Polda wajib diisi untuk Operator Polda"

### 3.5 Form: Polda (`FormTambahPolda`)

| Field | Widget | Mandatory |
|-------|--------|-----------|
| Nama Polda | `TextFormField` | ✅ * |
| Latitude | `TextFormField` | ✅ * |
| Longitude | `TextFormField` | ✅ * |

**Validation:** "Semua data wajib diisi"

### 3.6 Form: Polres (`FormTambahPolres`)

| Field | Widget | Mandatory |
|-------|--------|-----------|
| Nama Polda | `DropdownButtonFormField<int>` (API: `GET /api/v1/polda`) | ✅ * |
| Nama Polres | `TextFormField` | ✅ * |

### 3.7 Form: Amunisi (`FormTambahAmunisi`)

| Field | Widget | Mandatory | Notes |
|-------|--------|-----------|-------|
| Polda | `DropdownButtonFormField<int>` | ✅ * | Locked (`onChanged: null`), auto-filled |
| Kode Batch | `TextFormField` | ✅ * | — |
| Kategori Senjata | `DropdownButtonFormField<int>` | ✅ * | Same API as Senjata kategori |
| Jumlah Butir | `TextFormField` (keyboard: number) | ✅ * | — |
| Tanggal Masuk | `DatePicker` | ✅ * | Max: today + 20 years |
| Tanggal Kedaluwarsa | `DatePicker` | ✅ * | Must be after Tanggal Masuk. Picking earlier Tanggal Masuk clears Kedaluwarsa. |

**Additional validation:** "Tanggal Kedaluwarsa harus setelah Tanggal Masuk"

### 3.8 Form: Sarpras (`FormTambahSarpras`)

| Field | Widget | Mandatory | Notes |
|-------|--------|-----------|-------|
| Kode Barang | `TextFormField` | ✅ * | — |
| Nama Barang | `TextFormField` | ✅ * | — |
| Kategori | `DropdownButtonFormField<String>` (hardcoded: `['Kendaraan', 'Perlengkapan Kantor', 'Perlengkapan Dalmas', 'Alat Komunikasi', 'Kendaraan Taktis']`) | ✅ * | — |
| Kondisi | `DropdownButtonFormField<String>` (hardcoded: `['Baik', 'Rusak Ringan', 'Rusak Berat']`) | ✅ * | — |
| Tahun Pengadaan | Year picker (`showDatePicker` in year mode) | ✅ * | Range: 1990–now |
| Foto Sarpras | Image picker → WebP compress | ✅ * (create only) | Same pipeline |

### 3.9 Form: Kategori Senjata (Inline Dialog)

| Field | Widget | Mandatory | Notes |
|-------|--------|-----------|-------|
| Tipe Laras | `DropdownButtonFormField<String>` (hardcoded: `['Panjang', 'Pendek']`) | ✅ * | Rendered as colored badge in table (blue=Panjang, purple=Pendek) |
| Kaliber | `TextFormField` | ✅ * | Placeholder: "Contoh: 9mm" |

**Validation:** "Lengkapi semua data bertanda *" via SnackBar. Uses `StatefulBuilder` inside `AlertDialog`.

### 3.10 Form: Inventaris (STUB)

| Field | Widget | Mandatory | Notes |
|-------|--------|-----------|-------|
| Nama Asset | `TextFormField` | * (not validated) | — |
| Kategori | `DropdownButtonFormField<String>` (hardcoded: `['Rantis', 'Water Canon']`) | * (not validated) | hint says "Pilih Pangkat" (copy-paste bug) |
| Kondisi | `TextFormField` | * (not validated) | hint: "Contoh : baik" |
| Foto Satwa | Image picker (gallery only) | * (not validated) | Label says "Foto Satwa" (copy-paste bug) |
| Submit | `onPressed: () {}` | 🔴 No-op | Button says "Submit" |

### 3.11 Common Form Patterns

- **Input decoration** (`_inputDecoration`): filled with `scheme.surfaceContainerHighest`, rounded 8px border, blue focus border (`#1D4ED8`), red error border (`#EF4444`), dense with 16px horizontal + 14px vertical padding.
- **HUD Loading**: All submit operations wrap in `HudLoading.show(context, label: "MENYIMPAN...")` / `HudLoading.hide(context)`.
- **SnackBar feedback**: Success = green, Error = red, Warning = orange.
- **Pop with result**: All forms pop with `Navigator.pop(context, true)` on success so the list page can refresh.
- **Not-mounted guard**: Every async callback checks `if (!mounted) return;` before setState.

---

## 4. Special UI/UX Features

### 4.1 HUD Loading Spinner ("Arc Reactor" Style)

**File:** `lib/widget/hud_loading_spinner.dart`

A custom-painted sci-fi loading indicator with three animated layers:

1. **Outer dashed ring** (24 dashes, 55% sweep each, StrokeCap.round) rotating clockwise (0 → 2π over 2000ms).
2. **Inner solid arc** (270° sweep, 90° gap at bottom) rotating counter-clockwise.
3. **Glowing cyan core** — 4 concentric circles with opacity falloff (0.08 → 0.15 → 0.30 → 1.0).

All rendered in `Colors.cyanAccent` with no `MaskFilter` (Impeller-safe). Optional `label` parameter renders below in cyan, letter-spaced HUD typography (e.g., "MEMUAT DATA NASIONAL...").

The `HudLoading` helper class (`lib/utils/hud_loading.dart`) wraps this in a full-screen, non-dismissible dialog route (`barrierDismissible: false`, `PopScope(canPop: false)`) with a dark barrier (`Colors.black54`).

### 4.2 Dashboard Map (FlutterMap) — Role 3 Only

**File:** `lib/pages/dashboard.dart`

- **Tile layer:** ArcGIS World Imagery satellite tiles (`server.arcgisonline.com`).
- **Initial view:** Center at `(-2.5, 118.0)` (Indonesia), zoom 4.3, constrained to LatLngBounds `[-11, 95]` to `[6, 141]`.
- **HUD Markers** (`_HudMarker`): Custom cyan/amber hexagonal markers per Polda. Feature:
  - Pulsing ring animation (scale 1.0 → 1.4 over 1600ms, opacity fade)
  - Polda name label with `_HudMarqueeText` (auto-scrolls if text overflows marker width)
  - On tap: launches `_HudDrilldownDialog` calling `GET /api/v1/dashboard/drilldown?polda_id=X`
- **Drilldown Dialog** (`_HudDrilldownDialog`): Dark indigo HUD-styled popup with:
  - Marquee title bar with cyan close button
  - Tactical readout rows: Personel, Senjata, Sarpras, Satwa K9, Vakansi
  - Stale-load protection: `FutureBuilder` discards results when `poldaId` changes
  - Loading state: embedded `HudLoadingSpinner`
  - Error state: retry button
- **National-level overlay** (top-left): Shield icon + "SINDOMON - NATIONAL COMMAND CENTER" + current datetime.
- **Executive avatar** (top-right): Floating profile PopupMenuButton with Pengaturan/Logout.
- **Dark overlay:** `IgnorePointer` with `Colors.black.withValues(alpha: 0.20)` over the map.

### 4.3 Marquee Text (`_HudMarqueeText`)

**File:** `lib/pages/dashboard.dart` (private widget, lines 1076–1239)

Zero-dependency auto-scrolling text for long labels (primarily Polda names in HUD markers and drill-down titles):

- Renders statically when text fits container.
- When overflow detected (via `TextPainter` width measurement): waits 1500ms, then infinitely scrolls two side-by-side copies using `AnimationController` + `Transform.translate`.
- Seamless wrap: controller goes 0 → 1, second copy lands exactly where first started.
- Speed: scaled by text width (`totalWidth / 30` pixels/sec, clamped 1500–12000ms).

### 4.4 Smart Alerts & Badges

| Feature | Screen | Trigger | Visual |
|---------|--------|---------|--------|
| **H-90 Alert** | Amunisi list | `is_h90_alert == true` (from API) | Red badge with ⚠️ icon + "H-90 ALERT" text (`#B91C1C` on `#FEE2E2`). Otherwise green "AMAN" badge (`#166534` on `#DCFCE7`). |
| **Vaccine Urgency** | Satwa list | `jadwal_vaksin` < 30 days from today | Red vaccine syringe icon (`Icons.vaccines`) with tooltip "Vaksinasi kurang dari 30 hari atau sudah lewat". |
| **Tipe Laras Badge** | Master Kategori Senjata | Value from API | Blue badge (`#EFF6FF` / `#1D4ED8`) for "Panjang", purple badge (`#FAF5FF` / `#7E22CE`) for "Pendek". |
| **Delete Confirmations** | All list pages | Delete action | `AlertDialog` with entity name. Personel and Polda/Polres show the entity name in the confirmation message; others show generic "Apakah Anda yakin ingin menghapus data ini?". |

### 4.5 Dark/Light Theme Toggle

**Files:** `lib/theme/theme_controller.dart`, `lib/theme/app_theme.dart`, `lib/theme/sidebar_colors.dart`

- **Persistence:** `ThemeMode.name` serialized to SharedPreferences key `"theme_mode"`.
- **Toggle location:** Bottom control cluster of sidebar (light/dark mode icon with rotation animation) + top-right corner of login card.
- **Two themes:**
  - **Light — "Clean Corporate":** White surfaces, slate text, indigo primary (`#1E1B4B`), gold secondary (`#F6B300`). Sidebar: white background, dark indigo selected item.
  - **Dark — "J.A.R.V.I.S Cyberpunk":** Void indigo surfaces (`#12142A`), cyan primary (`#00E5FF`), gold secondary. Sidebar: deep void indigo (`#0F0B2E`), gold selected item.
- **Font:** `GoogleFonts.barlowSemiCondensedTextTheme()` applied to both themes.
- **Transparent scaffold:** Both themes set `scaffoldBackgroundColor: Colors.transparent` so the `AppBackground` (gradient + cyber grid) renders through.

### 4.6 Collapsible Sidebar

**File:** `lib/widget/app_sidebar.dart`

- **Two states:** Expanded (240px) with icons + labels + group `ExpansionTile`s; Collapsed (80px) with icons only.
- **Animation:** `AnimatedContainer` 300ms `easeOutCubic` width transition. Text fades in only after sidebar is 50%+ expanded (via `Interval(0.5, 1.0)` curve).
- **Offstage Strategy:** Both expanded and collapsed renderings live permanently in the tree. Toggle only flips `Offstage` flags — no widget is ever unmounted, preventing `mouse_tracker.dart:203:12` assertions.
- **Collapsed group behavior:** Tapping a collapsed group icon expands the sidebar (no navigation); the `ExpansionTile` preserves its own open/closed state across toggles.
- **Collapse toggle:** Bottom control cluster with double-arrow icons (AnimatedSwitcher).

### 4.7 Common UI Components

| Widget | Location | Description |
|--------|----------|-------------|
| `AppScaffold` | `lib/widget/app_scaffold.dart` | Authenticated page shell: sidebar (left) + header/content/footer (right). Loads username/role from SharedPreferences for header. `showHeaderFooter: false` for full-screen pages (Dashboard map, Placeholder). |
| `AppBackground` | `lib/widget/background.dart` | Full-bleed background with gradient + cyber grid pattern. |
| `AppHeader` | `lib/widget/app_header.dart` | Breadcrumb text, amber home icon, profile PopupMenuButton (Pengaturan → AccountSettingPage, Logout → clear session). Amber circle avatar. |
| `AppFooter` | `lib/widget/app_footer.dart` | Copyright + version string. |
| `AppSearchField` | `lib/widget/app_search_field.dart` | Styled search input with icon. Each page wires it with a 400ms debounce timer that resets to page 1 and re-fetches. |
| `AppPagination` | `lib/widget/app_pagination.dart` | Dynamic pagination strip. Windowed page numbers with ellipsis gaps. Amber active page indicator. "Menampilkan X hingga Y dari Z data" text. All props optional (defaults to static "1 of 50" for non-wired pages). |
| `ActionButtons` | `lib/widget/action_buttons.dart` | Edit (blue hover) + Delete (red hover) icon buttons with `MouseRegion` hover effects. |
| `GlassSurface` | `lib/widget/glass_surface.dart` | Frosted glass container for DataTable panels. |
| `LoginCard` | `lib/widget/login_card.dart` | Blur-glass login form container with logo + amber submit button + theme toggle. |
| `AppTextField` | `lib/widget/textfield.dart` | Custom text field with error state (red border). |
| `PlaceholderPage` | `lib/pages/placeholder_page.dart` | Generic under-construction page: construction icon + title + "Fitur dalam pengembangan" text. |

### 4.8 Debounced Search Pattern

Every list page implements the same pattern:

```dart
Timer? _debounce;
void _onSearchChanged(String value) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 400), () {
    _searchQuery = value;
    _currentPage = 1;
    getXxxApi();
  });
}
```

Master Kategori Senjata additionally guards against stale responses by snapshotting `_currentPage` and `_searchQuery` before the request and discarding the response if they've changed.

### 4.9 Image Handling

Three CRUD screens support image upload with a shared architecture:

1. **Pick:** `image_picker` → Camera or Gallery via `showModalBottomSheet`.
2. **Compress:** `flutter_image_compress` → WebP format, 1280px min dimensions, quality 80. Falls back to original bytes on platforms without compression support (Windows/Linux).
3. **Upload:** `http.MultipartRequest` with `Content-Type: multipart/form-data`. Always uses POST method (even for edit — PHP backend constraint). ID placed in URL path only.
4. **Preview:** `CachedNetworkImage` for existing photos (list page thumbnails + edit form preview). Image URL resolution: absolute URLs passed through; relative paths get `$apiBaseUrl` prefix with `/` insertion when needed.

---

## 5. Navigation & Routing Summary

- **No router package.** All navigation uses `Navigator.push(MaterialPageRoute(...))`.
- **No route-level guards.** Any page can be reached by direct navigation regardless of role.
- **Login → Dashboard:** `pushAndRemoveUntil` — clears entire stack.
- **List → Add/Edit:** `Navigator.push` with `await` and `.then((result) { if (result == true) refresh(); })`.
- **Logout:** Clears all SharedPreferences keys, then `pushAndRemoveUntil` to LoginPage.
- **Profile dropdown** (in AppHeader and Dashboard): Navigates to `AccountSettingPage` or triggers session clear.

---

## 6. API Communication Patterns

| Aspect | Detail |
|--------|--------|
| **Base URL** | `https://sindomon.cml-indonesia.com` (single constant in `lib/config/api_config.dart`) |
| **Auth header** | `authorization` (no "Bearer" prefix) — note lowercase in some calls, mixed case in others |
| **HTTP client** | Raw `http` package — no service class, no interceptors |
| **Response parsing** | Ad-hoc `jsonDecode` → manual casting. Most pages tolerate both `{ data: { items: [...], pagination: {...} } }` and legacy `{ data: [...] }` shapes. |
| **Error handling** | Inline try/catch with SnackBar messages. HTTP 422 treated as business validation (stays on form). |
| **Serialization** | No code-gen. `Polda` and `DashboardNasional`/`DashboardDrilldown` have hand-written `fromJson` factories with total (never-throw) defensive parsing. Personnel/Weapons/Users use raw `Map<String, dynamic>`. |

---

## 7. Key Architectural Observations

1. **No state management:** Every page is a `StatefulWidget` managing its own state. Session data re-read from SharedPreferences in every widget's `initState`.
2. **No DI / service locator:** No provider, riverpod, get_it, or similar. Widgets instantiate dependencies directly.
3. **No test infrastructure:** `flutter_test` declared but no `test/` directory exists.
4. **`data_table_2` declared but unused:** Standard `DataTable` is used throughout.
5. **Consistent design language:** Every authenticated page uses identical layout, spacing, typography, and amber CTA buttons (`#F6B300`).
6. **Multipart PUT workaround:** PHP backend cannot parse `multipart/form-data` on PUT, so Senjata/Satwa/Sarpras edit always sends POST. ID is placed in the URL path (`/api/v1/logistik/senjata/{id}`).

---

*End of Audit — Generated from source code ground truth.*
