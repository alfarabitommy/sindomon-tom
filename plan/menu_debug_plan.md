# Menu Debug Plan — Role-Based Sidebar Audit

> **Status:** INVESTIGATION COMPLETE — Awaiting APPROVAL before refactoring
> **Date:** 2026-08-01
> **Audited by:** Senior Flutter Architect (Claude)

---

## 1. Menu System Audit

### a) Retrieval: How the Sidebar reads `"roleid_login"`

**File:** `lib/widget/app_sidebar.dart:35-42`

```dart
Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _roleId = prefs.getString("roleid_login");  // line 39
      _loaded = true;                              // line 40
    });
}
```

- Called from `initState()` (line 32).
- Async load with `_loaded` flag gating the `ListView` — shows a `CircularProgressIndicator` until `_loaded == true`.
- The sidebar loads the role **independently** from SharedPreferences — it does NOT receive `roleId` as a constructor parameter from the parent page. Each page that embeds `AppSidebar` only passes `currentRoute`.

**Verdict: ✅ Retrieval pattern is sound.** No race condition — the spinner gates rendering until the role is loaded.

---

### b) Data Type Matching

| Stage | File:Line | Code | Type |
|-------|-----------|------|------|
| **Parse** (login) | `login_card.dart:144` | `data["data"]["roles_id"]?.toString() ?? ""` | `String` |
| **Write** (login) | `login_card.dart:151` | `prefs.setString("roleid_login", roleID)` | `String` |
| **Read** (sidebar) | `app_sidebar.dart:39` | `prefs.getString("roleid_login")` | `String` |
| **Lookup** (sidebar) | `app_sidebar.dart:65` | `roleMenus.containsKey(_roleId)` | `roleMenus` keys are `"1"`, `"2"`, `"3"` |
| **Compare** (dashboard) | `dashboard.dart:31` | `if (_roleId != "3")` | `String` comparison |

**Verdict: ✅ No type mismatch.** The entire pipeline uses `String`. No `int == String` comparison that would silently fail.

---

### c) Menu Mapping: Which roles get which menus?

**File:** `lib/config/menu_config.dart:270-274`

```dart
const Map<String, List<List<dynamic>>> roleMenus = {
  "1": role1Menu,   // Super Admin
  "2": role2Menu,   // Operator Polda
  "3": role3Menu,   // Command Center
};
```

| Role ID | Role Label (from `roleLabelFromId`) | Menu Contents |
|---------|-------------------------------------|---------------|
| `"1"` | Super Admin | Dashboard, Laporan, + 2 expandable MenuGroups (6 sub-items) |
| `"2"` | Operator Polda | Dashboard, Laporan, + 7 expandable MenuGroups (14 sub-items) |
| `"3"` | Command Center | **Only 1 item:** "Command Center Nasional" (→ Dashboard) |
| **anything else** | **"Operator"** (from `default:` case) | **🚨 EMPTY — `[]` — no menu at all** |

**Critical finding:** The `roleLabelFromId` static method (`app_sidebar.dart:12-19`) has a `default: return "Operator"` case, proving that roles beyond 1/2/3 are expected to exist. But `roleMenus` has **zero entries** for those roles.

Additionally, `lib/widget/form_input_user.dart` uses role labels "Super Admin", "Operator Polda", **"Operator Polres"** — where "Operator Polres" has no corresponding numeric ID mapping or menu entry anywhere in the codebase.

---

## 2. Root Cause Analysis

### Primary Root Cause: **`roleMenus` map has no entry for the user's actual role ID**

The gate in `_resolveMenu()` (`app_sidebar.dart:64-67`):

```dart
List<dynamic> _resolveMenu() {
    if (_roleId == null || !roleMenus.containsKey(_roleId)) return [];
    return roleMenus[_roleId]!.expand((e) => e).toList();
}
```

…returns `[]` (empty list) whenever `_roleId` is anything other than `"1"`, `"2"`, or `"3"`.

**Three scenarios produce an empty menu:**

| Scenario | `_roleId` value | Why it happens |
|----------|----------------|----------------|
| **A. Unknown role** | `"4"` (or any value ≠ 1/2/3) | API returns a `roles_id` not mapped in `roleMenus`. The `roleLabelFromId` default case ("Operator") confirms this possibility. |
| **B. Null/missing field** | `""` (empty string) | `roles_id` is absent from the API response, or the JSON path `data["data"]["roles_id"]` is incorrect. |
| **C. JSON path crash** | crash before save | `data["data"]` is null — the `?.toString()` is on `["roles_id"]` only, so `null["roles_id"]` throws before reaching `?.toString()`. |

### What the user actually sees:

```
┌─────────────────────────┐
│   [POLRI LOGO]          │
│   SINDOMON              │
│   Sistem Informasi...   │
│                         │
│                         │  ← EMPTY SPACE (where menu items should be)
│                         │
│─────────────────────────│  ← Divider
│ ⚙ Pengaturan           │
│ 🚪 Logout               │
└─────────────────────────┘
```

The hardcoded "Pengaturan" and "Logout" items (lines 123-132 in `app_sidebar.dart`) always render because they bypass the `_resolveMenu()` logic entirely. Only the role-based items in the `Expanded` → `ListView` → `_buildMenuItems()` path are missing.

### Secondary observation: Role "3" has an intentionally minimal menu

If the user IS role "3", the menu technically works — showing only "Command Center Nasional". But with a single item pointing to the dashboard the user is already on, it could appear broken. This is by design (command center only needs the map view) but could cause confusion.

---

## 3. Refactor Plan

### Phase 1 — DIAGNOSIS (confirm root cause before fixing)

**File:** `lib/widget/app_sidebar.dart`, method `_resolveMenu()` (line 64)

Add diagnostic logging:

```dart
List<dynamic> _resolveMenu() {
    debugPrint('══════════════════════════════════════');
    debugPrint('[AppSidebar] _roleId = "$_roleId"');
    debugPrint('[AppSidebar] roleMenus keys = ${roleMenus.keys.toList()}');
    debugPrint('[AppSidebar] containsKey = ${roleMenus.containsKey(_roleId)}');
    debugPrint('══════════════════════════════════════');
    if (_roleId == null || !roleMenus.containsKey(_roleId)) return [];
    return roleMenus[_roleId]!.expand((e) => e).toList();
}
```

**Action:** Ask the user to log in with the affected role and report the console output. This tells us the exact `_roleId`.

---

### Phase 2 — FIX (based on diagnosis)

#### Case A: `_roleId` is `"4"` (or any valid non-1/2/3 value)

The role exists but `roleMenus` needs a new entry.

**File:** `lib/config/menu_config.dart`

Add the role and define its menu (adjust based on actual business requirements):

```dart
const role4Menu = [
  _commonTopItems,
  [
    // Define appropriate MenuGroups for this role...
  ],
];

const Map<String, List<List<dynamic>>> roleMenus = {
  "1": role1Menu,
  "2": role2Menu,
  "3": role3Menu,
  "4": role4Menu,   // ADDED
};
```

**File:** `lib/widget/app_sidebar.dart:12-19`

Add the new role to `roleLabelFromId`:
```dart
case "4": return "Operator Polres";  // or appropriate label
```

#### Case B: `_roleId` is `""` (empty string)

The API response parsing is failing. The JSON path `data["data"]["roles_id"]` may be wrong.

**File:** `lib/widget/login_card.dart`, line 144

Add defensive parsing and debug logging:

```dart
// REPLACE:
String roleID = data["data"]["roles_id"]?.toString() ?? "";

// WITH:
final dataPayload = data["data"];
final roleID = (dataPayload is Map ? dataPayload["roles_id"]?.toString() : null) ?? "";
debugPrint('[LoginCard] Parsed roleID from API = "$roleID"');
debugPrint('[LoginCard] dataPayload keys = ${dataPayload is Map ? dataPayload.keys.toList() : "NOT A MAP"}');
```

This reveals whether the field name is `roles_id`, `role_id`, or something else entirely.

#### Case C: Unknown/edge-case roles (DEFENSIVE FIX — recommended in all cases)

Add a fallback so that UNKNOWN roles still get a basic menu instead of an empty one.

**File:** `lib/widget/app_sidebar.dart`, method `_resolveMenu()`:

```dart
List<dynamic> _resolveMenu() {
    if (_roleId == null) return [];
    if (!roleMenus.containsKey(_roleId)) {
      debugPrint('[AppSidebar] WARNING: No menu for role "$_roleId", using fallback');
      return _commonTopItems.toList();  // At least Dashboard + Laporan
    }
    return roleMenus[_roleId]!.expand((e) => e).toList();
}
```

**Note:** This requires making `_commonTopItems` accessible from `app_sidebar.dart`. Either:
- Export it from `menu_config.dart` (add `const` already exists, just need to reference it), OR
- Define a `defaultMenu` constant in `menu_config.dart` that `_resolveMenu()` can reference.

---

### Phase 3 — ALIGNMENT (prevent future drift)

**File:** `lib/widget/app_sidebar.dart:12-19`

Ensure `roleLabelFromId` and `roleMenus` stay synchronized. Every case in the switch should have a corresponding key in `roleMenus`. Add a comment:

```dart
/// MUST stay in sync with [roleMenus] keys in menu_config.dart.
/// Every case here needs a corresponding menu definition.
static String roleLabelFromId(String? roleId) {
    switch (roleId) {
      case "1": return "Super Admin";
      case "2": return "Operator Polda";
      case "3": return "Command Center";
      case "4": return "Operator Polres";    // ADDED (if applicable)
      default: return "Operator";
    }
}
```

---

## 4. Verification Checklist

After applying the fix:

- [ ] **Login as role "1" (Super Admin):** Sidebar shows Dashboard, Laporan, Manajemen Keamanan & Akun, Master Data Sistem
- [ ] **Login as role "2" (Operator Polda):** Sidebar shows Dashboard, Laporan, + 7 expandable groups
- [ ] **Login as role "3" (Command Center):** Sidebar shows "Command Center Nasional"
- [ ] **Login as the previously-broken role:** Sidebar shows appropriate menu items (no longer empty)
- [ ] **Navigate** through every menu item — confirm correct page loads
- [ ] **Logout:** Confirm all 6 SharedPreferences keys are cleared, user returns to login
- [ ] **Console output:** `[AppSidebar]` debug logs show the correct `_roleId` and `containsKey = true`
- [ ] **Regression:** All existing pages (personel, senjata, polda, polres, etc.) still work correctly

---

## 5. Files Summary

| Priority | File | What to Change |
|----------|------|----------------|
| **1. DIAGNOSTIC** | `lib/widget/app_sidebar.dart:64-67` | Add `debugPrint` to `_resolveMenu()` |
| **2. FIX** | `lib/config/menu_config.dart:270-274` | Add missing role key to `roleMenus` |
| **3. DEFENSE** | `lib/widget/app_sidebar.dart:64-67` | Add fallback menu for unrecognized roles |
| **4. ALIGN** | `lib/widget/app_sidebar.dart:12-19` | Sync `roleLabelFromId` cases with `roleMenus` keys |
| **5. DEFENSE** | `lib/widget/login_card.dart:144` | Add defensive null-safety around `data["data"]` |

---

> **Next step:** Await your APPROVE command before any code changes are made.
