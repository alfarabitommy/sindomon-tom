# Flutter Amunisi Module — File Structure Audit

**Date:** 2026-08-05  
**Auditor:** Senior Flutter Auditor (DEBUG MODE)  
**Module:** Stok Amunisi (Table View + Add Form)

---

## 1. Existing Files

| Expected File | Exists? | Current State |
|---|---|---|
| `lib/pages/amunisi.dart` | **NO** | Does not exist |
| `lib/pages/add_amunisi.dart` | **NO** | Does not exist |
| `lib/widget/form_input_amunisi.dart` | **NO** | Does not exist |

### Current Placeholder

In `lib/config/menu_config.dart` (line 281–282), Amunisi is wired as a **placeholder**:

```dart
Widget _as() => _ph("Stok Amunisi", "ammo_stock");
```

This renders `PlaceholderPage` — a generic screen showing a construction icon (`Icons.construction_rounded`) and text "Fitur dalam pengembangan".

### Sidebar Navigation

Amunisi appears in **`role2Menu`** (Operator Polda, roleId `"2"`) under the **"Logistik & Aset"** group:

```dart
LeafMenuItem(
  label: "Stok Amunisi",
  icon: Icons.archive_rounded,
  routeName: "ammo_stock",
  pageBuilder: _as,   // ← currently placeholder
),
```

### No Related Files Anywhere

- Zero Amunisi-related `.dart` files in entire `lib/` tree
- No form widget, no model, no API endpoint reference

---

## 2. UI Starting Point

### Build from scratch? **Partially.**

Three new files must be created. However, the project has a **well-established pattern** that can be copy-paste-modified. The Senjata module is the canonical reference:

| New File | Canonical Template |
|---|---|
| `lib/pages/amunisi.dart` | `lib/pages/senjata.dart` (table view, 460 lines) |
| `lib/pages/add_amunisi.dart` | `lib/pages/add_senjata.dart` (add page wrapper, 146 lines) |
| `lib/widget/form_input_amunisi.dart` | `lib/widget/form_input_senjata.dart` (form widget, 398 lines) |

### Page Architecture (inherited pattern)

```
amunisi.dart          ← DataTable + search + delete + "Tambah Amunisi" button
  └─ Navigator.push → add_amunisi.dart
                          └─ wraps → form_input_amunisi.dart
                                         (POST/PUT form logic)
```

### What changes from Senjata template:

| Aspect | Senjata (template) | Amunisi (target) |
|---|---|---|
| API endpoint | `/api/v1/logistik/senjata` | TBD (likely `/api/v1/logistik/amunisi`) |
| Table columns | Foto, No Seri, Kategori, Tahun | TBD (fields from amunisi schema) |
| Form fields | Polda, No Seri, Kategori, Tahun, Foto | TBD (likely include kaliber, jumlah, tanggal_kadaluarsa, etc.) |
| Route name | `"senjata"` | `"ammo_stock"` |
| Breadcrumb | Dashboard / Inventaris / Senjata Api | Dashboard / Logistik / Stok Amunisi |

---

## 3. Component Readiness — DatePicker

| Question | Answer |
|---|---|
| Custom reusable DatePicker widget? | **No.** None found anywhere in `lib/` |
| `showDatePicker` usage in project? | **Zero.** Only single `DateTime.now()` in `dashboard.dart` |
| Recommendation | Use **native Flutter `showDatePicker`** — zero deps, standard Material look, fits existing UI style |

No custom widget needed. The native `showDatePicker` returns a `DateTime?` which can be formatted with `DateFormat` from the `intl` package (already a transitive dep via Flutter Material).

---

## 4. Files to Modify (besides new files)

### `lib/config/menu_config.dart`

- Replace `Widget _as() => _ph("Stok Amunisi", "ammo_stock");` with actual import:
  ```dart
  import '../pages/amunisi.dart';
  ```
- Point `pageBuilder` to `const AmunisiPage()`

### No sidebar changes needed

`app_sidebar.dart` is generic — it renders whatever `menu_config.dart` provides. No sidebar code changes required.

---

## 5. Summary

```
┌─────────────────────────────────────────────────┐
│ STATE: Empty placeholder (PlaceholderPage)       │
│                                                  │
│ TO BUILD:                                        │
│   ✅ lib/pages/amunisi.dart          (NEW)       │
│   ✅ lib/pages/add_amunisi.dart      (NEW)       │
│   ✅ lib/widget/form_input_amunisi.dart (NEW)    │
│   ✏️ lib/config/menu_config.dart    (EDIT 1 ln) │
│                                                  │
│ PATTERN: Clone Senjata module structure          │
│ DATEPICKER: Native showDatePicker (no custom)    │
│ ESTIMATED EFFORT: ~400 lines new code total      │
└─────────────────────────────────────────────────┘
```
