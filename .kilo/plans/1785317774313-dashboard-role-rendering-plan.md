# Dashboard Role-Based UI Rendering Plan

## Problem Summary
- All roles land on `DashboardPage` post-login, which unconditionally renders a full NCC map + KPIs.
- Role 3 (Eksekutif) should see the map. Roles 1/2 should see a chart placeholder (charts TBD).
- Role 3's only sidebar menu item "Command Center Nasional" routes to a `PlaceholderPage` stub — wasted click.

## Files Affected
1. `lib/config/menu_config.dart` — 2-line edit
2. `lib/pages/dashboard.dart` — refactor build body, add role state

---

## Step 1: Fix Role 3 Menu Routing (`menu_config.dart`)

**File:** `lib/config/menu_config.dart`  
**Lines:** 259-268, 288

### Changes:
1. **Line 264:** Change `routeName: "command_center"` → `routeName: "dashboard"`
2. **Line 265:** Change `pageBuilder: _cc` → `pageBuilder: _db`
3. **Line 288:** Delete `Widget _cc() => _ph("Command Center Nasional", "command_center");` (no longer referenced)

### Rationale:
- `_db()` factory returns `const DashboardPage()` — same factory used by Role 1/2 "Dashboard" menu.
- Changing `routeName` to `"dashboard"` ensures the sidebar highlights the item correctly (sidebar uses `currentRoute` comparison).
- Deleting `_cc()` is safe — verified via grep, no other references exist.

**Validation:** After edit, `_cc` should have zero references in the codebase.

---

## Step 2: Add Role State to `DashboardPage` (`dashboard.dart`)

**File:** `lib/pages/dashboard.dart`  
**Pattern:** Identical to `AppSidebar._loadRole()` (lines 35-42 of `app_sidebar.dart`)

### Additions:
```dart
// New field in _DashboardPageState:
String? _roleId;

// New method:
Future<void> _loadRole() async {
  final prefs = await SharedPreferences.getInstance();
  if (!mounted) return;
  setState(() => _roleId = prefs.getString("roleid_login"));
}
```

### Modify `initState()`:
```dart
@override
void initState() {
  super.initState();
  _loadRole();          // add this line
  getPoldaApi();
}
```

### Modify `getPoldaApi()`:
Wrap the API call so it only fires for Role 3:
```dart
Future<void> getPoldaApi() async {
  if (_roleId != "3") {    // guard
    setState(() => isLoading = false);
    return;
  }
  // ... existing fetch logic unchanged ...
}
```
**Ponytail:** This skips the API call for Roles 1/2. When charts are added later and need their own data, add a separate fetch method.

**Edge case:** `_loadRole()` and `getPoldaApi()` both call `setState`. The async order is `_loadRole()` → `getPoldaApi()` (called sequentially in `initState`). `getPoldaApi()` checks `_roleId` which may be null if `_loadRole()` hasn't resolved yet. This is safe because:
- If `_roleId` is null → guard passes (`null != "3"`) → sets `isLoading = false` immediately.
- When `_loadRole()` resolves later, it triggers `setState` again but `getPoldaApi` won't re-fire.
- When Role 3: `_loadRole()` resolves `_roleId = "3"` first, then `getPoldaApi` has already fired (was called in initState synchronously). **Potential race.** 

**Fix for the race:** Combine into single init flow:
```dart
@override
void initState() {
  super.initState();
  _init();  // single async entry point
}

Future<void> _init() async {
  final prefs = await SharedPreferences.getInstance();
  if (!mounted) return;
  setState(() => _roleId = prefs.getString("roleid_login"));
  await getPoldaApi();
}
```

This ensures `_roleId` is loaded before `getPoldaApi()` checks it.

---

## Step 3: Conditional Rendering in `build()` (`dashboard.dart`)

**Strategy:** Keep `Scaffold → AppBackground → SafeArea → Row → [AppSidebar, Expanded(...)]` wrapper untouched. Only the `Expanded` child changes.

### Extract existing map UI into `_buildCommandCenter()`:
Move lines 73-338 (the entire `Stack` with `FlutterMap`, overlays, KPIs, sits reports) into a private method. Zero logic changes — pure extraction.

### Add `_buildPlaceholder()`:
```dart
Widget _buildPlaceholder() {
  return Center(
    child: Card(
      margin: const EdgeInsets.all(32),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              "Area Grafik & Statistik",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Segera Hadir",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

### Modify `build()`:
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: AppBackground(
      imagePath: 'assets/images/wp-putih-mabes.png',
      child: SafeArea(
        child: Row(
          children: [
            const AppSidebar(currentRoute: "dashboard"),
            Expanded(
              child: _roleId == "3" ? _buildCommandCenter() : _buildPlaceholder(),
            ),
          ],
        ),
      ),
    ),
  );
}
```

**Loading state:** While `_roleId` is null (brief moment after initState), `_buildPlaceholder()` renders. This is acceptable — it is sub-second and matches the eventual Role 1/2 view. Alternatively, could show a `CircularProgressIndicator` for the null case. Recommendation: just show placeholder for null — no flicker benefit for the extra branch.

---

## Step 4: Remove Unused Import Warnings
- `_buildPlaceholder()` uses Material icons/colors only — no new imports needed.
- After extracting map into method, `getPoldaApi` and `provinsi` stay as state — they're only consumed by `_buildCommandCenter()`.
- No imports removed.

---

## Validation Checklist

| # | Check | Expected |
|---|-------|----------|
| 1 | Role 3 logs in | Dashboard shows NCC map with polda markers, KPIs, overlay |
| 2 | Role 3 clicks "Command Center Nasional" in sidebar | Routes to same DashboardPage (no push of placeholder page) |
| 3 | Role 3 sidebar item highlighted | `routeName: "dashboard"` matches `currentRoute: "dashboard"` |
| 4 | Role 1 logs in | Dashboard shows white card "Area Grafik & Statistik (Segera Hadir)" |
| 5 | Role 2 logs in | Same as Role 1 |
| 6 | Role 1 clicks "Dashboard" in sidebar | Routes to DashboardPage showing placeholder (no map flash) |
| 7 | Role 3: polda API still fires | Markers appear on map |
| 8 | Role 1/2: polda API skipped | No network call, no console errors |
| 9 | `_cc` deleted, zero references | grep `"_cc"` or `_cc(` returns nothing |
| 10 | Build succeeds | `flutter build apk --debug` or `flutter analyze` passes |

---

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| Race condition: `_roleId` null when `getPoldaApi()` checks it | Single `_init()` method loads role first, then calls API |
| Role 3 sidebar no longer shows "command_center" routeName — sidebar label unaffected | Sidebar label comes from `menuItem.label` ("Command Center Nasional"), not `routeName` |
| `DashboardPage` title text says "NATIONAL COMMAND CENTER" even for Role 1/2 | The title text is inside `_buildCommandCenter()` and won't render for Roles 1/2. No change needed. |

---

## What This Plan Does NOT Do
- Does NOT build actual charts/graphs for Roles 1/2 (placeholder only)
- Does NOT change the sidebar structure or AppSidebar code
- Does NOT add any new dependencies
- Does NOT refactor SharedPreferences into a service class (follows existing raw-prefs pattern)
