# Flutter Enum Scoping Hotfix — Build Report

**Date:** 2025-07-16  
**Issue:** `Enums can't be declared inside classes` at `lib/widget/app_header.dart:20` — `enum _ProfileAction` was accidentally declared inside the `AppHeader` class body, causing a compile error plus `Undefined name '_ProfileAction'` at the two usage sites (`_onProfileActionSelected` signature, `PopupMenuButton<_ProfileAction>`).

---

## 1. Fixed — `lib/widget/app_header.dart`

**Before (broken):**

```dart
import '../utils/session_util.dart';

class AppHeader extends StatelessWidget {
  final String breadcrumb;
  final String username;
  final String role;

  const AppHeader({ ... });

  /// Actions available from the profile dropdown (replaces the old
  /// sidebar entries for Pengaturan / Laporan / Logout).
  enum _ProfileAction { laporan, pengaturan, logout }   // ❌ inside class — compile error

  void _onProfileActionSelected(BuildContext context, _ProfileAction action) { ... }
  ...
}
```

**After (fixed):**

```dart
import '../utils/session_util.dart';

/// Actions available from the profile dropdown (replaces the old
/// sidebar entries for Pengaturan / Laporan / Logout).
enum _ProfileAction { laporan, pengaturan, logout }     // ✅ top-level, after imports

class AppHeader extends StatelessWidget {
  final String breadcrumb;
  final String username;
  final String role;

  const AppHeader({ ... });

  void _onProfileActionSelected(BuildContext context, _ProfileAction action) { ... }
  ...
}
```

**Changes made:**
1. Cut `enum _ProfileAction { laporan, pengaturan, logout }` (with its doc comment) out of the `AppHeader` class body.
2. Inserted it at **top-level, immediately after the import statements** (line 8).
3. Verified all references still resolve: `_ProfileAction` is used at `_onProfileActionSelected(BuildContext, _ProfileAction)` (line 22) and `PopupMenuButton<_ProfileAction>` (line 87) — both now resolve to the top-level declaration (library-private `_` name, same file → visible).

---

## 2. Verified — `lib/pages/dashboard.dart` (no change needed)

`enum _ExecAction { pengaturan, logout }` is already correctly placed at **top-level** (line 17), between the imports and `class DashboardPage`:

```dart
import 'package:shared_preferences/shared_preferences.dart';

/// Actions available from the executive floating profile avatar.
enum _ExecAction { pengaturan, logout }    // ✅ top-level

class DashboardPage extends StatefulWidget { ... }
```

Confirmed via read: the enum sits at column 0 outside any class; its usages (`PopupMenuButton<_ExecAction>` at line 286, `switch (action)` at line 294) resolve correctly.

---

## 3. Project-wide enum audit

Grep of `lib/` for all enum declarations found exactly two, both at top-level (column 0, no indentation):

| File | Line | Enum | Status |
|------|------|------|--------|
| `lib/widget/app_header.dart` | 8 | `enum _ProfileAction { laporan, pengaturan, logout }` | ✅ fixed this hotfix |
| `lib/pages/dashboard.dart` | 17 | `enum _ExecAction { pengaturan, logout }` | ✅ already correct |

No other `enum` declarations exist anywhere in `lib/`, so no other class-nested enums can trigger the same error.

---

## 4. Verification status

| Check | Result |
|-------|--------|
| Enum removed from `AppHeader` class body | ✅ |
| Enum placed top-level after imports | ✅ (`app_header.dart:8`) |
| All `_ProfileAction` references resolve | ✅ (same-file library-private identifier; no import change needed) |
| `_ExecAction` location verified | ✅ (`dashboard.dart:17`, top-level) |
| `flutter analyze` | Not runnable — no Flutter SDK installed on this machine (same limitation as the previous build; run in Flutter-enabled environment/CI) |

## 5. Files touched

| File | Action |
|------|--------|
| `lib/widget/app_header.dart` | edited — moved `_ProfileAction` enum from class body to top-level |
| `lib/pages/dashboard.dart` | verified only — no change required |
