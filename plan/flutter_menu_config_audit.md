# Menu Config Routing Fix — Refactoring Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix menu label and routing inconsistencies in `lib/config/menu_config.dart` so that `role1Menu` "Master Logistik" correctly points to KategoriSenjataPage (Screen 2.6) and `role2Menu` "Sarpras & Altmatsus" correctly points to InventarisPage (Screen 5.5).

**Architecture:** Single-file refactor of `lib/config/menu_config.dart`. Three targeted edits: remove the misplaced "Master Logistik" item from `role1Menu`, rename "Master Kategori Senjata" to "Master Logistik" in `role1Menu`, and wire the `role2Menu` "Sarpras & Altmatsus" item to the real InventarisPage instead of the placeholder.

**Tech Stack:** Flutter / Dart (no new dependencies).

---

## Current Menu State (Audit Findings)

### `role1Menu` → "Master Data Sistem" (lines 92-127)

| Line | Label | `routeName` | `pageBuilder` | Status |
|------|-------|-------------|---------------|--------|
| 96-101 | Master Wilayah | `polda` | `_po` → PoldaPage | ✅ Correct |
| 102-107 | Master Polres | `polres` | `_pr` → PolresPage | ✅ Correct |
| 108-113 | Master SDM & Organisasi | `org_tree` | `_ot` → placeholder | ✅ Correct |
| 114-119 | **Master Logistik** | `inventaris` | `_in` → **InventarisPage** | ❌ WRONG — this points to Sarpras/Inventaris, not Kategori Senjata |
| 120-125 | **Master Kategori Senjata** | `kategori_senjata` | `_ks` → **KategoriSenjataPage** | ❌ WRONG label — should be named "Master Logistik" per spec |

**Problem:** Two items claim the "Logistik" namespace. The old one (line 114) hijacks the spec-correct label but points to wrong page. The new one (line 120) points to the correct page (KategoriSenjataPage) but has the wrong label.

### `role2Menu` → "Logistik & Aset" (lines 158-187)

| Line | Label | `routeName` | `pageBuilder` | Status |
|------|-------|-------------|---------------|--------|
| 162-167 | Inventaris Senjata | `senjata` | `_se` → SenjataPage | ✅ Correct |
| 168-173 | Stok Amunisi | `ammo_stock` | `_as` → placeholder | ✅ Correct |
| 174-179 | **Sarpras & Altmatsus** | `sarpras` | `_sp` → **placeholder** | ❌ WRONG — should point to InventarisPage, not placeholder |
| 180-185 | Satwa K9 & Turangga | `satwa` | `_sa` → SatwaPage | ✅ Correct |

**Problem:** "Sarpras & Altmatsus" exists with the correct label and icon, but `pageBuilder: _sp` is a placeholder stub. It should be `_in` → InventarisPage.

---

## Refactoring Plan

All changes are in one file: `lib/config/menu_config.dart`. Three edits, no new files.

### Edit 1: Remove the old "Master Logistik" from `role1Menu`

**Location:** Lines 114-119

Remove this entire LeafMenuItem block:

```dart
        LeafMenuItem(
          label: "Master Logistik",
          icon: Icons.warehouse_rounded,
          routeName: "inventaris",
          pageBuilder: _in,
        ),
```

### Edit 2: Rename "Master Kategori Senjata" → "Master Logistik" in `role1Menu`

**Location:** Lines 120-125

Change the label and icon on the existing item that points to `_ks`:

**Before:**
```dart
        LeafMenuItem(
          label: "Master Kategori Senjata",
          icon: Icons.category_rounded,
          routeName: "kategori_senjata",
          pageBuilder: _ks,
        ),
```

**After:**
```dart
        LeafMenuItem(
          label: "Master Logistik",
          icon: Icons.warehouse_rounded,
          routeName: "kategori_senjata",
          pageBuilder: _ks,
        ),
```

### Edit 3: Wire `role2Menu` "Sarpras & Altmatsus" to InventarisPage

**Location:** Lines 174-179

Change `pageBuilder: _sp` to `pageBuilder: _in`:

**Before:**
```dart
        LeafMenuItem(
          label: "Sarpras & Altmatsus",
          icon: Icons.precision_manufacturing_rounded,
          routeName: "sarpras",
          pageBuilder: _sp,
        ),
```

**After:**
```dart
        LeafMenuItem(
          label: "Sarpras & Altmatsus",
          icon: Icons.precision_manufacturing_rounded,
          routeName: "sarpras",
          pageBuilder: _in,
        ),
```

### Final `role1Menu` "Master Data Sistem" after refactor

```dart
    MenuGroup(
      label: "Master Data Sistem",
      icon: Icons.storage_rounded,
      children: [
        LeafMenuItem(
          label: "Master Wilayah",
          icon: Icons.map_rounded,
          routeName: "polda",
          pageBuilder: _po,
        ),
        LeafMenuItem(
          label: "Master Polres",
          icon: Icons.flag_rounded,
          routeName: "polres",
          pageBuilder: _pr,
        ),
        LeafMenuItem(
          label: "Master SDM & Organisasi",
          icon: Icons.account_tree_rounded,
          routeName: "org_tree",
          pageBuilder: _ot,
        ),
        LeafMenuItem(
          label: "Master Logistik",
          icon: Icons.warehouse_rounded,
          routeName: "kategori_senjata",
          pageBuilder: _ks,
        ),
      ],
    ),
```

---

## Task Breakdown

### Task 1: Fix menu routing in `lib/config/menu_config.dart`

**Files:**
- Modify: `lib/config/menu_config.dart` (3 edits as above)

- [ ] **Step 1: Remove the old "Master Logistik" from `role1Menu`**
  Delete lines 114-119 (the LeafMenuItem with `label: "Master Logistik"`, `routeName: "inventaris"`, `pageBuilder: _in`)

- [ ] **Step 2: Rename "Master Kategori Senjata" to "Master Logistik" in `role1Menu`**
  Change `label: "Master Kategori Senjata"` to `label: "Master Logistik"` and `icon: Icons.category_rounded` to `icon: Icons.warehouse_rounded` on the item with `pageBuilder: _ks`

- [ ] **Step 3: Wire "Sarpras & Altmatsus" in `role2Menu` to InventarisPage**
  Change `pageBuilder: _sp` to `pageBuilder: _in` on the "Sarpras & Altmatsus" item (line 178)

- [ ] **Step 4: Verify with `flutter analyze`**
  ```bash
  flutter analyze
  ```
  Expected: 4 pre-existing info issues (login_card.dart), zero new issues

- [ ] **Step 5: Commit**
  ```bash
  git add lib/config/menu_config.dart
  git commit -m "fix(menu): route Master Logistik to Kategori Senjata, Sarpras to Inventaris

  - role1Menu: remove duplicate 'Master Logistik' that pointed to InventarisPage
  - role1Menu: rename 'Master Kategori Senjata' → 'Master Logistik' (→ KategoriSenjataPage)
  - role2Menu: wire 'Sarpras & Altmatsus' to InventarisPage instead of placeholder

  Co-Authored-By: Claude <noreply@anthropic.com>"
  ```

---

## Verification Plan

### Automated
```bash
flutter analyze  # Must show same 4 pre-existing info issues, zero new issues
```

### Manual QA (run `flutter run`)

1. **Login as Super Admin (role 1)** → sidebar "Master Data Sistem" → verify:
   - "Master Logistik" appears (not "Master Kategori Senjata")
   - Clicking it navigates to KategoriSenjataPage (Screen 2.6) with badges and kaliber table
   - The old duplicate "Master Logistik" is gone from the menu

2. **Login as Operator Polda (role 2)** → sidebar "Logistik & Aset" → verify:
   - "Sarpras & Altmatsus" appears
   - Clicking it navigates to InventarisPage (Screen 5.5), not the placeholder "Fitur dalam pengembangan"

3. **Login as Command Center (role 3)** → verify no changes (still only "Command Center Nasional")

## Summary of Changes

| What | Where | Why |
|------|-------|-----|
| Remove old "Master Logistik" | `role1Menu` lines 114-119 | Wrongly pointed to InventarisPage |
| Rename "Master Kategori Senjata" → "Master Logistik" | `role1Menu` lines 120-125 | Spec says Screen 2.6 is "Master Logistik" |
| `_sp` → `_in` on "Sarpras & Altmatsus" | `role2Menu` line 178 | Should navigate to real InventarisPage, not placeholder |
