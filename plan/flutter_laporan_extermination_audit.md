# Flutter Laporan Extermination Audit

**Date:** 2025-07-15  
**Status:** Audit complete — ready for execution  
**Severity:** Clean excision (no deep entanglement)

---

## Scope Summary

The "Laporan" feature is a **single dummy page** (`ReportPage`) with hardcoded data, no real API integration, and zero business logic. It is only reachable via the profile dropdown in `AppHeader`. It is **not** wired into the sidebar menu system (`menu_config.dart`) and has **no** role-specific gating — it appears for every role.

---

## 1. Dropdown UI — `lib/widget/app_header.dart`

### 1.1 Import (to remove)

| Line | Code |
|------|------|
| **3** | `import '../pages/report.dart';` |

After removing the page file, this import will break compilation. Must be deleted.

### 1.2 Enum value (to remove)

| Line | Code |
|------|------|
| **8** | `enum _ProfileAction { laporan, pengaturan, logout }` |

Change to:  
`enum _ProfileAction { pengaturan, logout }`

### 1.3 Switch case branch (to remove)

| Lines | Code |
|-------|------|
| **24–29** | ```dart
case _ProfileAction.laporan:
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ReportPage()),
  );
  break;
``` |

Delete this entire case block.

### 1.4 PopupMenuItem (to remove)

| Lines | Code |
|-------|------|
| **92–98** | ```dart
PopupMenuItem(
  value: _ProfileAction.laporan,
  child: _ProfileMenuItem(
    icon: Icons.description_rounded,
    label: 'Laporan',
  ),
),
``` |

Delete this entire `PopupMenuItem` entry (including its trailing comma if it disturbs the list syntax — the next item `_ProfileAction.pengaturan` becomes the first item after `itemBuilder: (context) => const [`).

### Result after cleanup

The dropdown will contain only two items:
- **Pengaturan** → `AccountSettingPage`
- **Logout** → `clearSessionAndLogout(context)`

---

## 2. Physical Dummy Page File — `lib/pages/report.dart`

### File path

```
lib/pages/report.dart
```

### Verdict: **DELETE ENTIRELY**

| Property | Detail |
|----------|--------|
| Lines | 253 |
| Class | `ReportPage` (`StatefulWidget`) |
| Data | Hardcoded `listinventaris` (5× APC Anoa-2 dummy rows) |
| API calls | **None** |
| Sidebar route | `currentRoute: "report"` (self-referential, no other code reads it) |
| AppHeader usage | `breadcrumb: "Dashboard / Report"` (self-contained) |

This file is a standalone island. No other file imports or references it besides `app_header.dart`. Safe to `rm`.

---

## 3. Routing & Import Cross-Reference

### 3.1 `lib/config/menu_config.dart`

**No references found.** "Laporan" does not appear as a sidebar menu item for any role. The string `"report"` does not appear in `menu_config.dart`. The only match for `report` in this file is `Icons.report_problem_rounded` (line 233), which is unrelated — it belongs to the "Pengaduan Masyarakat" placeholder.

### 3.2 `lib/main.dart`

**No references found.** No import of `report.dart`, no route definition, no `ReportPage` usage.

### 3.3 `test/`

**No test directory exists.**

### 3.4 `pubspec.yaml`

**No report-specific assets or dependencies.**

---

## 4. Complete Extermination Checklist

| # | File | Action | Lines affected |
|---|------|--------|----------------|
| 1 | `lib/pages/report.dart` | **Delete file** | 1–253 |
| 2 | `lib/widget/app_header.dart` | Remove import | 3 |
| 3 | `lib/widget/app_header.dart` | Remove `laporan` from enum | 8 |
| 4 | `lib/widget/app_header.dart` | Remove `case _ProfileAction.laporan:` block | 24–29 |
| 5 | `lib/widget/app_header.dart` | Remove `PopupMenuItem` for Laporan | 92–98 |

**Total files touched:** 2  
**Total lines removed:** ~260  
**Compilation risk:** None (zero cross-references beyond `app_header.dart`)

---

## 5. Post-Extermination Verification

After applying the changes, run:

```bash
flutter analyze
```

Expected: **no errors, no unused-import warnings.**  
If `flutter analyze` reports any issue, re-check the `PopupMenuItem` list syntax — ensure commas between remaining items are correct after removing the first item.
