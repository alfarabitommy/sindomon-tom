# Flutter Settings Cleanup — Audit Report

**Date:** 2025-07-16  
**Scope:** Removing the rogue "Tambah Akun" form from the Settings page, and verifying the Executive Dashboard floating avatar has no "Laporan" option.

---

## 1. `lib/pages/pangaturan.dart` — AccountSettingPage audit

### 1.1 Current UI structure (top to bottom)

```
Scaffold → AppBackground → SafeArea → Row
 ├─ AppSidebar (currentRoute: "pengaturan")
 └─ Expanded → SingleChildScrollView → Column
      ├─ Glassmorphism header bar (lines 56–214)
      │    ├─ Amber home icon
      │    ├─ Breadcrumb: "Dashboard / Tambah Pengguna"    ← MISLEADING (this isn't a user-creation page)
      │    ├─ Search TextField (non-functional, hintText: "Cari Menu...")
      │    ├─ Notification bell IconButton (non-functional, no-op)
      │    └─ CircleAvatar + username / role label
      ├─ SizedBox(h:25)
      ├─ Title row (lines 221–249)
      │    ├─ Text: "Pengaturan Pengguna"                   ← MISLEADING title
      │    └─ ElevatedButton: "Kembali" → Navigator.pop
      ├─ SizedBox(h:25)
      ├─ ROGUE FORM (lines 253–270) ← THE PROBLEM
      │    └─ Center → SizedBox(w:470) → Card → Padding → FormTambahUser()
      └─ AppFooter
```

### 1.2 The rogue form — `FormTambahUser` (imported from `lib/widget/form_input_user.dart`)

**How it's called (pangaturan.dart:266):**
```dart
child: const FormTambahUser(),   // no userId, no initialData → CREATE mode
```

**What `FormTambahUser` does:**

| Aspect | Detail |
|--------|--------|
| Modes | Supports both CREATE (no userId) and EDIT (with userId + initialData). In account settings it's always CREATE mode. |
| Fields | Username (TextFormField), Password (TextFormField, obscured), Role (Dropdown: Super Admin / Operator Polda / Command Center), Status (Switch: Aktif / Tidak Aktif), Polda (Dropdown, conditional for role "2") |
| Validation | Username required; Password required for create mode; Polda required when role = "2" |
| Pre-fetch | `GET /api/v1/polda` to populate the Polda dropdown (line 113 in form_input_user.dart) |
| **API endpoint (create)** | **`POST https://sindomon.cml-indonesia.com/api/v1/user`** (line 207) |
| **API endpoint (edit)** | `PUT https://sindomon.cml-indonesia.com/api/v1/user/:id` (line 197 — never reached from account settings) |
| Request body | `{ username, roles_id, status, polda_id?, password }` |
| Auth header | `Authorization: <token>` (no "Bearer" prefix, matching app convention) |
| On success | Green SnackBar + `Navigator.pop(context, true)` — pops back to previous route |
| Submit button | Amber `ElevatedButton` with "Simpan Akun" (line 531) |
| Title text | "TAMBAH AKUN BARU" (line 268) |

**State class (`_AccountSettingPageState`):** only tracks `unLogin` (username) and `roleLabel` from SharedPreferences — no API call fetches the current user's profile data. It's essentially a skeleton that renders the form.

### 1.3 Exactly what to remove from `pangaturan.dart`

| # | Lines | What | Why |
|---|-------|------|-----|
| 1 | Line 4 | `import '../widget/form_input_user.dart';` | Unused after form removal |
| 2 | Line 7 | `import 'dart:ui';` | Only used by BackdropFilter in the header — if header is kept, keep the import. (The header is cosmetic; dart:ui stays.) |
| 3 | Lines 253–270 | The entire `Center → SizedBox → Card → Padding → FormTambahUser()` block | This is the rogue "Tambah Akun" form |
| 4 | Line 109 | Breadcrumb text `"Dashboard / Tambah Pengguna"` → change to `"Dashboard / Profil Saya"` | Misleading — this page should be a profile view, not a user creation form |
| 5 | Line 225 | Title text `"Pengaturan Pengguna"` → change to `"Profil & Pengaturan"` | Cleaner, accurate label |

**Optional cosmetic cleanup (lines 122–144):** the search `TextField` ("Cari Menu...") at lines 122–143 is a non-functional placeholder — can stay or go. Same for the notification bell `IconButton` at lines 148–160.

### 1.4 Note: `FormTambahUser` is ALSO used on the "Daftar Pengguna" page

The widget `FormTambahUser` is also imported by `lib/pages/add_user.dart` (the legitimate "Add User" page, reachable from the Daftar Pengguna data table for Super Admin). Removing the import from `pangaturan.dart` does **not** affect that usage — the widget file itself remains untouched.

### 1.5 Post-amputation: what the Settings page should become

After removing the form, the page collapses to:
- Header bar (keep — shows breadcrumb + user identity)
- Title "Profil & Pengaturan" + "Kembali" button
- **(new content area)** — Read-only profile cards displaying:
  - Nama Pengguna (from `unLogin` prefs)
  - Role (from `roleLabel`)
  - Polda / Wilayah (from `polda_login` prefs)
  - Status Binding Perangkat (placeholder or API call)
  - Toggle 2FA (placeholder)
- Footer

The shared prefs keys available are: `username_login`, `roleid_login`, `polda_login`, `uuid_login`, `expired_login`. The current state class already reads `username_login` and `roleid_login` — adding `polda_login` would be a small extension.

---

## 2. `lib/pages/dashboard.dart` — Executive Floating Avatar audit

### 2.1 `_ExecAction` enum (line 17)

```dart
/// Actions available from the executive floating profile avatar.
enum _ExecAction { pengaturan, logout }
```

**Verdict: CLEAN. No "laporan" value exists.**

### 2.2 PopupMenuButton itemBuilder (lines 308–324)

```dart
itemBuilder: (context) => const [
  PopupMenuItem(
    value: _ExecAction.pengaturan,
    child: _ExecMenuItem(icon: Icons.settings_rounded, label: 'Pengaturan'),
  ),
  PopupMenuDivider(),
  PopupMenuItem(
    value: _ExecAction.logout,
    child: _ExecMenuItem(icon: Icons.logout_rounded, label: 'Logout'),
  ),
],
```

**Verdict: CLEAN. Only "Pengaturan" and "Logout" — no "Laporan" entry.**

### 2.3 `onSelected` switch (lines 293–306)

```dart
onSelected: (action) {
  switch (action) {
    case _ExecAction.pengaturan:  // → AccountSettingPage
    case _ExecAction.logout:      // → clearSessionAndLogout
  }
},
```

**Verdict: CLEAN. Two cases, neither is "laporan".**

### 2.4 Conclusion for dashboard.dart

**There is no "Laporan" option in the Executive Dashboard floating avatar.** The enum, the menu items, and the switch handler are all correctly restricted to `{ pengaturan, logout }`. No code changes are needed in this file.

### 2.5 Where "Laporan" DOES currently live (for context)

The Header dropdown (`lib/widget/app_header.dart:8`):
```dart
enum _ProfileAction { laporan, pengaturan, logout }
```

This is correct — "Laporan" belongs in the Admin/Operator header dropdown (roles 1 & 2), not the Executive floating avatar (role 3). The design spec from the planning phase explicitly segregated them: **Header dropdown** (roles 1 & 2) = Laporan + Pengaturan + Logout; **Executive floating avatar** (role 3) = Pengaturan + Logout only.

---

## 3. Summary of required changes

### File: `lib/pages/pangaturan.dart`

| Action | Lines | Detail |
|--------|-------|--------|
| **REMOVE** import | Line 4 | `import '../widget/form_input_user.dart';` |
| **REMOVE** form block | Lines 253–270 | Entire `Center → SizedBox → Card → Padding → FormTambahUser()` |
| **CHANGE** breadcrumb | Line 109 | `"Dashboard / Tambah Pengguna"` → `"Dashboard / Profil Saya"` |
| **CHANGE** title | Line 225 | `"Pengaturan Pengguna"` → `"Profil & Pengaturan"` |

### File: `lib/pages/dashboard.dart`

| Action | Lines | Detail |
|--------|-------|--------|
| **NONE** | — | Executive floating avatar is already clean — no "Laporan" exists in `_ExecAction`, `itemBuilder`, or `onSelected` |

---

## 4. Risk assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Removing `FormTambahUser` import breaks `add_user.dart` | None | `add_user.dart` has its own import of `form_input_user.dart` — removing from `pangaturan.dart` only affects this file |
| Removing `dart:ui` breaks the header's `BackdropFilter` | Medium | **Keep** `dart:ui` import — it IS still used by the header bar (lines 66–67). Only remove `form_input_user.dart` import. |
| Page becomes too sparse after form removal | Low | Add read-only profile cards with existing `SharedPreferences` data (username, role, polda_id, expired) as the new content |
| No API call fetches user profile | Low | The current user's data is already in SharedPreferences from login — can display directly without an API call |
