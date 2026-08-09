# Flutter UI Cleanup Audit — Sidebar / Header / Executive Dashboard

**Date:** 2025-07-16  
**Scope:** Removing "Laporan", "Pengaturan", and "Logout" from the Sidebar; migrating them into a Profile Dropdown (Header, for Admin/Operator) and a Floating Avatar (Executive Dashboard, for Command Center).

---

## 1. Sidebar — `lib/widget/app_sidebar.dart`

### 1.1 Structural overview

```
Column
 ├─ Logo + "SINDOMON" title
 ├─ Expanded → ListView (_buildMenuItems)        ← scrollable role menu
 ├─ Divider
 ├─ "Pengaturan" (_buildLeafItem)                ← hardcoded, pinned bottom
 ├─ "Logout"   (_buildLogoutItem)                ← hardcoded, pinned bottom
 └─ SizedBox(height: 20)
```

### 1.2 Where the three targets live

| Item          | Location                                    | Rendering method          | Notes |
|---------------|---------------------------------------------|---------------------------|-------|
| **Laporan**   | `lib/config/menu_config.dart` lines 53–58   | `_buildLeafItem()` inside `_buildMenuItems()` ListView | Part of `commonTopItems`. Shared by role `"1"` (Super Admin) and role `"2"` (Operator Polda). Role `"3"` (Command Center) does NOT have it — its `role3Menu` only contains "Command Center Nasional" → Dashboard. |
| **Pengaturan**| `app_sidebar.dart` lines 131–138            | `_buildLeafItem()` called directly in `build()` | Hardcoded outside the scrollable area, below the `Divider`. Navigates to `AccountSettingPage` (aliased by `_stubSettings` at line 262). |
| **Logout**    | `app_sidebar.dart` line 139                 | `_buildLogoutItem()` called directly in `build()` | Hardcoded below "Pengaturan". Calls `_logout()` (lines 46–59), which clears all 6 SharedPreferences keys and navigates to `LoginPage`. |

### 1.3 Key code blocks to remove

**"Pengaturan" (lines 131–138):**
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

**"Logout" (line 139):**
```dart
_buildLogoutItem(),
```

**"Laporan" — requires editing `menu_config.dart`**, removing lines 53–58 from `commonTopItems`:
```dart
LeafMenuItem(
  label: "Laporan",
  icon: Icons.description_rounded,
  routeName: "report",
  pageBuilder: _rp,
),
```

### 1.4 Side-effects of removing "Laporan" from `commonTopItems`

- `commonTopItems` will only contain one item: "Dashboard".
- Roles `"1"` and `"2"` will lose the "Laporan" menu entry.
- Role `"3"` is unaffected (it never used `commonTopItems`).
- The `_rp` factory and `ReportPage` import in `menu_config.dart` (line 3) can be removed if "Laporan" is no longer reachable from anywhere else. **However**, if the Report page is still accessible via the new Profile Dropdown, the import and factory must stay.
- If the fallback path in `_resolveMenu()` (line 72: `return commonTopItems.toList()`) is ever hit for an unknown role, that user will now only see "Dashboard" — which is acceptable.

### 1.5 Side-effects of removing "Pengaturan" and "Logout"

- `_logout()` method (lines 46–59) must move somewhere else (Header/Profile Dropdown).
- `_stubSettings` factory (line 262) and the `import '../pages/pangaturan.dart'` (line 5) can be removed from `app_sidebar.dart`.
- The `Divider` at line 130 can optionally be removed or kept for aesthetics.
- The `_navigateTo()` method (line 62) is used by all leaf/group items — it remains needed for the role menu items.

---

## 2. Header — `lib/widget/app_header.dart`

### 2.1 Current structure

```
Container (height: 65, white bg, rounded)
 └─ Row
      ├─ Amber home icon (left)
      ├─ Breadcrumb text (Expanded)
      ├─ Spacer
      ├─ CircleAvatar (amber, person icon, radius 18)
      ├─ SizedBox(8)
      └─ Column
           ├─ username (bold, 13px)
           └─ role (grey, 11px)
```

### 2.2 What exists today

- **No dropdown/popup menu.** The right side is purely decorative — a static `CircleAvatar` + text labels.
- The widget is a **`StatelessWidget`**. It receives `breadcrumb`, `username`, and `role` as constructor parameters.
- The avatar is hardcoded amber with a generic `Icons.person` icon — no user photo or initials.
- There is no `onTap` handler anywhere in the header.

### 2.3 What needs to change

To support a Profile Dropdown, `AppHeader` must:

1. **Convert from `StatelessWidget` to `StatefulWidget`** (or accept callback parameters).
2. **Wrap the avatar + name area in a `GestureDetector` or `PopupMenuButton`** that opens a dropdown with three items:
   - **Laporan** (navigates to `ReportPage`)
   - **Pengaturan** (navigates to `AccountSettingPage`)
   - **Logout** (clears prefs, navigates to `LoginPage`)
3. **Accept navigation callbacks** or use `Navigator.of(context)` directly. Since `AppHeader` is used inside pages that already have a `Navigator`, it can use `Navigator.push()` and `Navigator.pushAndRemoveUntil()` from context.
4. **Receive any extra data** needed for logout (the `_logout` logic currently lives in `AppSidebar` and accesses `SharedPreferences` directly — this can be replicated or extracted into a shared utility).

### 2.4 Usage across pages

A quick survey shows `AppHeader` is used in pages like `report.dart` (line 5 import), and likely others. Each page passes `username` and `role` loaded from `SharedPreferences`. The dropdown would work consistently across all pages since it uses the same `Navigator` context.

---

## 3. Executive Dashboard — `lib/pages/dashboard.dart`

### 3.1 Layout architecture (role `"3"` only)

The Command Center view (`_buildCommandCenterContent()`) is a full-screen **`Stack`** with these `Positioned` children:

```
Stack
 ├─ Positioned.fill → FlutterMap (satellite tiles + Polda markers)
 ├─ Positioned.fill → dark overlay (IgnorePointer, 0.20 alpha black)
 ├─ Positioned(top: 20, left: 20)  → Logo + "SINDOMON - NATIONAL COMMAND CENTER" title
 ├─ Positioned(top: 20, right: 20) → KPI panel (glassmorphism, 240px wide)
 ├─ Positioned(left: 20, bottom: 20) → Sitkamtibmas reports (250×120)
 └─ Positioned(bottom: 20, left: 300) → KPI cards row ("Active Fleet", "K9 Standby")
```

### 3.2 The KPI panel at top-right (what the user calls `panel_aggregat_nasional`)

Lines 277–349:
```dart
Positioned(
  top: 20,
  right: 20,
  child: Container(
    width: 240,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.20),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.cyanAccent),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Total Personel" — formatted number
        // "Defense Equipment" — readiness %
        // "Vacant Position" — formatted number
      ],
    ),
  ),
),
```

This panel occupies **top: 20, right: 20** with **width: 240**. It has a semi-transparent black background with a cyan accent border.

### 3.3 Injection plan — Floating Profile Avatar

There are two viable approaches to add a floating avatar without breaking the existing layout:

#### Option A: Place above the KPI panel (recommended)

Add a new `Positioned` widget at `top: 20, right: 20` (same origin) that renders the avatar, and shift the KPI panel **down** by changing its `top` from `20` to e.g. `70` (or wrapping both in a Column inside a single Positioned).

```dart
// New: floating avatar button
Positioned(
  top: 20,
  right: 20,
  child: FloatingActionButton.small(  // or an IconButton in a glassmorphism circle
    onPressed: () => _showProfileMenu(),
    child: const Icon(Icons.person),
  ),
),
// Existing KPI panel — shift top down
Positioned(
  top: 70,  // was 20
  right: 20,
  child: Container( ... ),
),
```

**Pros:** Minimal code change; avatar is visually separate from the KPI panel.  
**Cons:** KPI panel moves down ~50px, reducing map visibility slightly.

#### Option B: Nest avatar inside the KPI panel

Add the avatar as the first child of the KPI panel's `Column`, right-aligned:

```dart
child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // New: avatar row at top of panel
    Align(
      alignment: Alignment.topRight,
      child: GestureDetector(
        onTap: () => _showProfileMenu(),
        child: const CircleAvatar(radius: 18, ...),
      ),
    ),
    const SizedBox(height: 8),
    // ... existing KPI text rows
  ],
),
```

**Pros:** No layout shift; avatar is visually grouped with the KPI data.  
**Cons:** Avatar lives inside the glassmorphism panel — may look cramped or confuse the data hierarchy.

### 3.4 What the profile menu should contain for Executive (role `"3"`)

Since Command Center has no "Laporan" or "Pengaturan" in its sidebar menu (only "Command Center Nasional" → Dashboard), the floating avatar dropdown should offer:

- **Pengaturan** → `AccountSettingPage`
- **Logout** → clear prefs + navigate to `LoginPage`

("Laporan" is probably not relevant for the Command Center role, but could be included if stakeholders want it.)

### 3.5 Logout considerations for the Executive view

The `_logout` method currently lives in `AppSidebar` (a `StatefulWidget`). Since the Command Center dashboard does use `AppSidebar` (line 152: `const AppSidebar(currentRoute: "dashboard")`), removing the sidebar's logout item means we must replicate the logout logic in `_DashboardPageState`. The method is straightforward — clear 6 prefs keys, then `Navigator.pushAndRemoveUntil(LoginPage)`.

---

## 4. Summary of changes needed

| Component            | File                              | Change                                                           |
|----------------------|-----------------------------------|------------------------------------------------------------------|
| `commonTopItems`     | `lib/config/menu_config.dart`     | Remove "Laporan" `LeafMenuItem` (lines 53–58)                    |
| `AppSidebar.build()` | `lib/widget/app_sidebar.dart`     | Remove "Pengaturan" `_buildLeafItem` (lines 131–138)             |
| `AppSidebar.build()` | `lib/widget/app_sidebar.dart`     | Remove `_buildLogoutItem()` call (line 139)                      |
| `AppSidebar`         | `lib/widget/app_sidebar.dart`     | Remove `_logout()` method (move logic to shared util or Header)  |
| `AppSidebar`         | `lib/widget/app_sidebar.dart`     | Remove `_stubSettings` + `pangaturan.dart` import                |
| `AppHeader`          | `lib/widget/app_header.dart`      | Convert to StatefulWidget; add PopupMenuButton with Laporan / Pengaturan / Logout |
| `DashboardPage`      | `lib/pages/dashboard.dart`        | Add floating avatar (Option A or B) for role `"3"`; wire logout  |

### 4.1 Files that import the removed items

- `menu_config.dart` imports `report.dart` (line 3) — keep if Laporan stays reachable via Header dropdown; remove otherwise.
- `app_sidebar.dart` imports `pangaturan.dart` (line 5) — remove after moving "Pengaturan" out.
- Any page that uses `AppHeader` will automatically get the new dropdown — no per-page changes needed.

---

## 5. Risk assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| `_logout()` logic duplicated in Header + Dashboard | Low | Extract to `lib/utils/session.dart` as `clearSessionAndLogout(context)` |
| `AppHeader` used in many pages; converting to StatefulWidget may break callers | Low | Constructor signature stays the same; only internal state for dropdown added |
| Executive dashboard loses Logout access if floating avatar is missed | Medium | Must add the avatar in the same PR; test with role `"3"` explicitly |
| "Laporan" page becomes orphaned if not wired into new dropdown | Medium | Ensure both Admin and Operator dropdowns include the Laporan entry |
| `commonTopItems` reduced to single item | None | Still valid as fallback |
