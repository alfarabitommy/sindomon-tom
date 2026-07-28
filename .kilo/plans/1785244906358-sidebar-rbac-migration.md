# Plan: Sidebar RBAC Side-by-Side Migration (POC)

**Target:** `lib/pages/dashboard.dart` only. Other 16 files untouched.

## Decisions
- New menu items: **no-op on tap** (placeholder for future wiring)
- New menu styling: **match existing theme** (amber highlight, white text, white70 icons, purple `Color(0xff1E1B4B)`)
- Role source: `SharedPreferences.getString("roleid_login")` → `String?` types: `"1"` / `"2"` / `"3"`

## Steps

### 1. Read role on init
- Add `String? _roleId;` field to `_DashboardPageState`
- In `initState()`, call `_loadRole()` which does `SharedPreferences.getInstance()` then `getString("roleid_login")` → `setState(() => _roleId = value)`

### 2. Add three new helper methods in `_DashboardPageState`
All styled to match existing purple/amber theme.

**`Widget _buildExpansionTileGroup(String title, IconData icon, List<Widget> children)`**
- Root: `ExpansionTile` with dark styling
- `leading`: `Icon(icon, color: Colors.white70)`
- `title`: `Text(title, style: white/bold)`
- `collapsedIconColor: Colors.white70`
- `iconColor: Colors.amber`
- `childrenPadding: EdgeInsets.only(left: 24)`
- `backgroundColor: Colors.white.withValues(alpha: 0.05)` (subtle indent background when expanded)
- Children: list of `_buildNewMenuItem(...)` calls

**`Widget _buildNewMenuItem(String title, IconData icon)`**
- Root: `ListTile` with same padding/radius as existing `menu()`
- `leading`: `Icon(icon, color: Colors.white70, size: 20)`
- `title`: `Text(title, style: white/w500, fontSize: 13)`
- `shape`: `RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))`
- `hoverColor: Colors.white10`
- `onTap: null` (no-op — placeholder)
- No `selected` / trailing arrow

### 3. Inject new menu section into the ListView

Replace lines 152–177 (the `Expanded > ListView > children: [...]`) with:

```dart
Expanded(
  child: ListView(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    children: [
      // ===== NEW RBAC MENU =====
      if (_roleId != null) ..._buildNewMenuByRole(),

      // ===== DIVIDER =====
      const Divider(color: Colors.amber, thickness: 1.5),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          "--- OLD MENU BELOW (DO NOT USE) ---",
          style: TextStyle(color: Colors.amber, fontSize: 11, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      ),

      // ===== OLD MENU (untouched) =====
      menu(Icons.dashboard_rounded, "Dashboard", selected: true),
      menu(Icons.description_rounded, "Laporan"),
      menu(Icons.map_rounded, "Wilayah"),
      menu(Icons.inventory_2_rounded, "Inventaris"),
      menu(Icons.groups_rounded, "Organisasi"),
      menu(Icons.pets_rounded, "Satwa"),
      menu(Icons.people_alt_rounded, "Polda"),
      menu(Icons.people_alt_rounded, "Polres"),
      menu(Icons.gavel_rounded, "Senjata"),
      menu(Icons.move_to_inbox_rounded, "Kotak Masuk"),
      menu(Icons.outbox_rounded, "Kotak Keluar"),
      menu(Icons.badge_rounded, "Personel"),
      menu(Icons.inventory_rounded, "Stok Amunisi"),
      menu(Icons.memory_rounded, "Perangkat"),
      menu(Icons.people_alt_rounded, "Pengguna"),
    ],
  ),
),
```

### 4. Implement `_buildNewMenuByRole()`

Returns `List<Widget>`. Structure per role:

**Role "3" (Eksekutif)** — no groups, single leaf:
```dart
[_buildNewMenuItem("Command Center Nasional", Icons.monitor_heart_rounded)]
```

**Role "1" (Super Admin)** — two groups:
```dart
[
  _buildExpansionTileGroup("Manajemen Keamanan & Akun", Icons.admin_panel_settings, [
    _buildNewMenuItem("Daftar Pengguna", Icons.people_alt_rounded),
    _buildNewMenuItem("Binding Perangkat", Icons.phonelink_lock_rounded),
  ]),
  _buildExpansionTileGroup("Master Data Sistem", Icons.storage_rounded, [
    _buildNewMenuItem("Master Wilayah", Icons.map_rounded),
    _buildNewMenuItem("Master SDM & Organisasi", Icons.account_tree_rounded),
    _buildNewMenuItem("Master Logistik", Icons.warehouse_rounded),
  ]),
]
```

**Role "2" (Operator Polda)** — seven groups:
```dart
[
  _buildExpansionTileGroup("Manajemen SDM", Icons.group_rounded, [
    _buildNewMenuItem("Bagan Organisasi (Org-Tree)", Icons.account_tree_rounded),
    _buildNewMenuItem("Direktori Personel", Icons.badge_rounded),
    _buildNewMenuItem("Pemantauan Proses Hukum", Icons.gavel_rounded),
  ]),
  _buildExpansionTileGroup("Logistik & Aset", Icons.inventory_rounded, [
    _buildNewMenuItem("Inventaris Senjata", Icons.shield_rounded),
    _buildNewMenuItem("Stok Amunisi", Icons.ammunition_rounded),
    _buildNewMenuItem("Sarpras & Altmatsus", Icons.precision_manufacturing_rounded),
    _buildNewMenuItem("Satwa K9 & Turangga", Icons.pets_rounded),
  ]),
  _buildExpansionTileGroup("Administrasi (DMS)", Icons.description_rounded, [
    _buildNewMenuItem("Kotak Masuk (Inbox)", Icons.move_to_inbox_rounded),
    _buildNewMenuItem("Kotak Keluar (Outbox)", Icons.outbox_rounded),
  ]),
  _buildExpansionTileGroup("Operasional & Kamtibmas", Icons.local_police_rounded, [
    _buildNewMenuItem("Log Sitkamtibmas", Icons.article_rounded),
  ]),
  _buildExpansionTileGroup("Komunikasi Taktis", Icons.communication_rounded, [
    _buildNewMenuItem("Direktori Panggilan (VoIP)", Icons.call_rounded),
    _buildNewMenuItem("Ruang Konferensi", Icons.videocam_rounded),
  ]),
  _buildExpansionTileGroup("Hub Informasi Terpadu", Icons.hub_rounded, [
    _buildNewMenuItem("Perpustakaan Digital", Icons.library_books_rounded),
    _buildNewMenuItem("Pengaduan Masyarakat", Icons.report_problem_rounded),
  ]),
  _buildExpansionTileGroup("Mobile", Icons.phone_android_rounded, [
    _buildNewMenuItem("Status Patroli GPS", Icons.gps_fixed_rounded),
  ]),
]
```

### 5. Styling details

**`_buildExpansionTileGroup`:**
```dart
Widget _buildExpansionTileGroup(String title, IconData icon, List<Widget> children) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 2),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
    ),
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        collapsedIconColor: Colors.white70,
        iconColor: Colors.amber,
        childrenPadding: const EdgeInsets.only(left: 24, bottom: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: Colors.white.withValues(alpha: 0.04),
        collapsedBackgroundColor: Colors.transparent,
        children: children,
      ),
    ),
  );
}
```

**`_buildNewMenuItem`:**
```dart
Widget _buildNewMenuItem(String title, IconData icon) {
  return ListTile(
    leading: Icon(icon, color: Colors.white70, size: 20),
    title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    hoverColor: Colors.white10,
    onTap: null,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    visualDensity: VisualDensity.compact,
  );
}
```

### 6. Icon compatibility note
`Icons.ammunition_rounded` may not exist in all Material versions. If unavailable at build time, fall back to `Icons.handyman_rounded` or `Icons.build_rounded`. Plan B: use `Icons.inventory_rounded` (already imported).

## Files changed
- `lib/pages/dashboard.dart` (~80 lines added, 0 removed, ~10 modified)

## Validation
- `flutter analyze` — no errors
- Manual: run app, verify correct menu renders per role
- smoke: old menu items still navigate as before

## Skipped
- No refactor of other 16 sidebar-duplicated files
- No page wiring (all new items are no-op)
- Pengaturan/Logout relocation to AppBar (out of scope for this POC)
