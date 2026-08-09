# Flutter UI Cleanup — Build Report

**Date:** 2025-07-16  
**Scope:** Removed "Pengaturan", "Laporan", and "Logout" from the Sidebar; migrated profile actions to a Header dropdown (Admin/Operator) and a Floating Glassmorphism Avatar (Executive Dashboard).

---

## 1. New file — `lib/utils/session_util.dart`

Global logout helper, shared by the Header dropdown and the Executive floating avatar.

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/login_page.dart';

/// Clears the persisted session (all SharedPreferences keys) and navigates
/// back to the [LoginPage], removing every route from the stack.
Future<void> clearSessionAndLogout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  if (!context.mounted) return;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => const LoginPage()),
    (route) => false,
  );
}
```

> **Note:** the mission snippet imported `../pages/login.dart`, but the actual file is `lib/pages/login_page.dart` (verified: `class LoginPage` at line 5). The correct path was used. `prefs.clear()` was kept as specified (the app stores only the 6 session keys, so clearing all is equivalent to the old per-key removal).

---

## 2. `lib/config/menu_config.dart` — remove "Laporan"

**Removed:**
- `import '../pages/report.dart';` (line 3)
- The `LeafMenuItem` for "Laporan" inside `commonTopItems` (was lines 53–58):

```dart
LeafMenuItem(
  label: "Laporan",
  icon: Icons.description_rounded,
  routeName: "report",
  pageBuilder: _rp,
),
```

- `Widget _rp() => const ReportPage();` (was line 62)

**Result:** `commonTopItems` now contains only "Dashboard". Roles `"1"` and `"2"` (which spread `commonTopItems`) no longer show "Laporan"; role `"3"` was never affected.

---

## 3. `lib/widget/app_sidebar.dart` — remove "Pengaturan" + "Logout"

**Removed:**
- `import '../pages/login_page.dart';` and `import '../pages/pangaturan.dart';`
- The `_logout()` method (6 prefs removals + `pushAndRemoveUntil`) — superseded by `clearSessionAndLogout` in `session_util.dart`
- From `build()`: the `Divider`, the hardcoded "Pengaturan" `_buildLeafItem` block, and the `_buildLogoutItem()` call
- The `_buildLogoutItem()` method
- `Widget _stubSettings() => const AccountSettingPage();` (file-level factory)

**Result:** `AppSidebar` now renders only the brand + role menu ListView. `_navigateTo`, `_resolveMenu`, `_buildLeafItem`, `_buildGroupItem`, `_buildChildItem` unchanged. Verified: zero remaining references to `_logout` / `Logout` / `Pengaturan` / `_stubSettings` / `LoginPage` / `AccountSetting` in the file.

---

## 4. `lib/widget/app_header.dart` — profile dropdown

Kept as **`StatelessWidget`** (constructor unchanged — 20 call sites across `lib/pages/` remain untouched) with a `PopupMenuButton`.

**Added imports:**
```dart
import '../pages/pangaturan.dart';   // AccountSettingPage
import '../pages/report.dart';       // ReportPage
import '../utils/session_util.dart'; // clearSessionAndLogout
```

**New members:**
- `enum _ProfileAction { laporan, pengaturan, logout }`
- `_onProfileActionSelected(context, action)` — switches: Laporan → `ReportPage`, Pengaturan → `AccountSettingPage`, Logout → `clearSessionAndLogout(context)`
- Private `_ProfileMenuItem` (icon + label row)

**Build change:** the former static `CircleAvatar` + username/role `Column` is now the `child` of:

```dart
PopupMenuButton<_ProfileAction>(
  offset: const Offset(0, 50),
  tooltip: 'Menu Profil',
  onSelected: (action) => _onProfileActionSelected(context, action),
  itemBuilder: ... // Laporan, Pengaturan, PopupMenuDivider, Logout
  child: ...       // avatar + name + arrow_drop_down affordance icon
)
```

> **Design decision:** the mission's dropdown spec listed "Pengaturan" and "Logout" (the mandatory minimum). The planning-phase spec moves **all three** sidebar items into the Header dropdown, and removing "Laporan" from the sidebar would otherwise orphan `ReportPage` (flagged as a Medium risk in `plan/flutter_ui_cleanup_audit.md`). Laporan is therefore included in the Header dropdown. Removing it later is a 3-line change.

---

## 5. `lib/pages/dashboard.dart` — Executive floating avatar

**Added imports:** `dart:ui` (ImageFilter), `../pages/pangaturan.dart`, `../utils/session_util.dart`.

**New top-level enum:** `enum _ExecAction { pengaturan, logout }` (role `"3"` never had Laporan).

**New `Positioned` in `_buildCommandCenterContent()` Stack** (inserted above the KPI panel):

```dart
/// Floating Profile Avatar (Executive)
Positioned(
  top: 20,
  right: 20,
  child: PopupMenuButton<_ExecAction>(
    offset: const Offset(0, 52),
    tooltip: 'Menu Profil',
    color: const Color(0xff1E1B4B),          // dark indigo menu, matches app theme
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    onSelected: (action) { ... pengaturan → AccountSettingPage / logout → clearSessionAndLogout },
    itemBuilder: ... // Pengaturan, PopupMenuDivider, Logout (dark _ExecMenuItem rows)
    child: ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),   // glassmorphism
        child: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            border: Border.all(color: Colors.cyanAccent, width: 1.5),
          ),
          child: const Icon(Icons.person_rounded, color: Colors.white, size: 26),
        ),
      ),
    ),
  ),
),
```

**Shifted:** the KPI panel (`panel_aggregat_nasional`) — `Positioned(top: 20, ...)` → `Positioned(top: 80, ...)`, so the avatar (48px + 20px top margin, ending at y≈68) does not overlap the panel.

**New helper:** private `_ExecMenuItem` (amber icon + white label row for the dark menu).

---

## 6. Verification status

| Check | Result |
|-------|--------|
| `flutter analyze` | **Not runnable** — no Flutter SDK installed on this machine (`flutter` not found on PATH or in common locations). |
| Manual re-read of all 5 touched files | ✅ Structurally valid (balanced braces, correct widget nesting, imports present) |
| Grep for dangling refs (`_stubSettings`, `_buildLogoutItem`, `_logout`, `routeName: "report"`, `routeName: "pengaturan"`, `pageBuilder: _rp`) across `lib/` | ✅ Zero matches |
| Import paths (`login_page.dart`, `pangaturan.dart`, `report.dart`, `session_util.dart`) | ✅ All resolve to real files |
| `AppHeader` call sites (20 pages) | ✅ Constructor signature unchanged — no caller edits needed |

**Recommendation:** run `flutter analyze` in a Flutter-enabled environment (CI or a dev machine) before merging.

---

## 7. Files touched

| File | Action |
|------|--------|
| `lib/utils/session_util.dart` | **created** — `clearSessionAndLogout(context)` |
| `lib/config/menu_config.dart` | edited — removed Laporan item + `_rp` + report import |
| `lib/widget/app_sidebar.dart` | edited — removed Pengaturan, Logout, `_logout()`, `_stubSettings`, imports, Divider |
| `lib/widget/app_header.dart` | edited — added profile dropdown (Laporan / Pengaturan / Logout) |
| `lib/pages/dashboard.dart` | edited — added floating glassmorphism avatar; KPI panel `top: 20 → 80` |
