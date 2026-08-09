# Flutter Header Anomaly Audit

**File:** `lib/pages/pangaturan.dart`  
**Audit date:** 2025-01-XX  
**Status:** READY FOR SURGERY

---

## 1. Rogue Header Location

The hardcoded, non-standard header block spans **lines 168–326**.

### Start anchor (line 168)
```dart
                      /// ============================
                      /// HEADER
                      /// ============================
                      Container(
```

### End anchor (line 326)
```dart
                      ),

                      const SizedBox(height: 25),
```

Everything between these anchors inclusive — the entire `Container` with its `BackdropFilter`, `ClipRRect`, and inner `Row` — must be deleted.

### Components inside the rogue block

| # | Widget | Details |
|---|--------|---------|
| 1 | `Container` (height: 75) | Outer shell with `border: Border.all(color: Colors.black26)` |
| 2 | `ClipRRect` + `BackdropFilter` | `sigmaX: 20, sigmaY: 20` glassmorphism blur |
| 3 | Home icon `Container` | `Icons.home_rounded`, amber background |
| 4 | `Expanded` + `Text` | Breadcrumb: `"Dashboard / Profil Saya"` |
| 5 | `SizedBox(width: 250)` + `TextField` | Search bar with `hintText: "Cari Menu..."`, prefix search icon |
| 6 | Notification `IconButton` | `Icons.notifications_none` (no `onPressed` handler) |
| 7 | `CircleAvatar` (radius: 20) | Amber background, `Icons.person` |
| 8 | `Column` with `Text` ×2 | `unLogin` (username) and `roleLabel` strings |

### Total estimated lines to delete: **~160 lines** (168–326)

---

## 2. AppBackground Safety Confirmation

`AppBackground` is **completely safe** and must remain untouched.

```
Scaffold
  └─ AppBackground(line 149)           ← SAFE — DO NOT DELETE
       └─ SafeArea
            └─ Row
                 ├─ AppSidebar          ← SAFE
                 └─ Expanded
                      └─ SingleChildScrollView
                           └─ Column
                                ├─ [ROGUE HEADER — DELETE]  (lines 168–326)
                                ├─ SizedBox(h: 25)
                                ├─ Title Row                 (lines 333–361)
                                ├─ SizedBox(h: 25)
                                ├─ Wrap (info cards)         (lines 368–388)
                                ├─ _bindingCard()            (line 395)
                                └─ AppFooter                 (line 399)
```

The header is nested inside `AppBackground` → `SafeArea` → `Row` → `Expanded` → `SingleChildScrollView` → `Column`. Removing it only affects its parent `Column`'s children list — `AppBackground` remains structurally untouched.

---

## 3. Import Analysis

### Current imports in `pangaturan.dart`
```dart
import 'package:flutter/material.dart';
import '../widget/background.dart';
import '../widget/app_sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widget/app_footer.dart';
import 'dart:ui';
```

### Missing import
- `import '../widget/app_header.dart';` — **NOT PRESENT**  
  Must be added before `AppHeader` can be used.

### Note: `dart:ui` import
- `dart:ui` is imported solely for `ImageFilter.blur()` used inside the rogue header's `BackdropFilter`.  
  After the header is removed, **`dart:ui` becomes unused** and should be deleted to keep the import list clean.

---

## 4. Replacement: One-Line Surgery

After deleting lines 168–326, insert a single line in the `Column`'s `children` list:

```dart
AppHeader(
  breadcrumb: "Dashboard / Profil Saya",
  username: unLogin,
  role: roleLabel,
),
```

### Variable mapping (already present in the page state)

| `AppHeader` prop | Local state variable | Source |
|-------------------|---------------------|--------|
| `breadcrumb` | `"Dashboard / Profil Saya"` (hardcoded string literal) | Same as existing `Text` widget |
| `username` | `unLogin` | `loadUser()` → `SharedPreferences` |
| `role` | `roleLabel` | `loadUser()` → `AppSidebar.roleLabelFromId()` |

All variables are already loaded in `initState()` → `loadUser()` — no new state or `initState` logic is needed.

---

## 5. Pre-Surgery Checklist

- [ ] Add `import '../widget/app_header.dart';`
- [ ] Delete lines 168–326 (the rogue header block)
- [ ] Insert `AppHeader(breadcrumb: "Dashboard / Profil Saya", username: unLogin, role: roleLabel),` at the same position
- [ ] Remove `import 'dart:ui';` (no longer used)
- [ ] Verify `AppBackground`, `AppSidebar`, `AppFooter` are all untouched
- [ ] Run `flutter analyze` after the edit
