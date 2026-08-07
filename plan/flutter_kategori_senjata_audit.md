# Flutter Kategori Senjata — Audit Report

**Date:** 2025-07-18  
**Auditor:** Reasonix (Flutter Auditor)  
**Mode:** DEBUG / PLAN (no code changes)

---

## 1. Routing Bug Discovery

### 1.1 The Buggy Menu Entry

**File:** `lib/config/menu_config.dart`, lines 114–119

```dart
LeafMenuItem(
  label: "Master Logistik",
  icon: Icons.warehouse_rounded,
  routeName: "inventaris",
  pageBuilder: _in,   // ← _in = const InventarisPage()
),
```

### 1.2 What It Actually Does

`_in` is defined on line 66:

```dart
Widget _in() => const InventarisPage();
```

`InventarisPage` (`lib/pages/inventaris.dart`, line 103) renders:

```
"Manajemen Inventaris"
```

It shows a DataTable of **APC Anoa-2 6x6** vehicles with hardcoded static data (not even from the API), with columns: FOTO, NAMA, KATEGORI, KONDISI. This is a "Sarpras & Altmatsus" inventory page — **not** a master-data management page for weapon categories.

### 1.3 What It Should Do

The menu label says **"Master Logistik"** and sits under the **"Master Data Sistem"** group (alongside Master Wilayah, Master Polres, Master SDM & Organisasi). Per the user's specification, this menu should open **"Master Kategori Senjata & Kaliber"** (Screen 2.6) — a CRUD management page for the `kategori-senjata` master table (managing `tipe_laras` and `kaliber` pairs, e.g. "Pistol - 9mm", "Senapan - 5.56mm").

### 1.4 Root Cause

The `pageBuilder` was wired to the wrong page during initial development. The `InventarisPage` is a completely different domain (vehicle inventory / Sarpras) and is not a master-data management page. It was likely used as a placeholder or copied from a mislabeled template.

---

## 2. File Status

### 2.1 Does the target page exist?

| File searched | Exists? |
|---|---|
| `lib/pages/*kategori*` | ❌ No |
| `lib/pages/*logistik*` | ❌ No |
| `lib/widget/*kategori*` | ❌ No |

**Verdict:** The "Master Kategori Senjata & Kaliber" page **does not exist** and must be built from scratch.

### 2.2 What DOES exist (related files)

| File | Purpose | Relevance |
|---|---|---|
| `lib/pages/senjata.dart` | "Inventaris Senjata" — manages individual weapon units (no seri, tahun, foto) | Uses kategori as a **dropdown** — it consumes category data, but doesn't manage it |
| `lib/pages/add_senjata.dart` | Thin wrapper → `FormTambahSenjata` | Not relevant |
| `lib/widget/form_input_senjata.dart` | Form for add/edit senjata | Contains `getKategori()` that calls `GET /api/v1/master/kategori-senjata` (line 76) and shows it in a dropdown (lines 384–401) |
| `lib/widget/form_input_amunisi.dart` | Form for add/edit amunisi | Also calls `GET /api/v1/master/kategori-senjata` (line 81) for its kategori dropdown |
| `lib/pages/inventaris.dart` | Manajemen Inventaris (APCs/vehicles) | **This is the wrong page currently linked** — has static hardcoded data, no API calls |
| `lib/pages/polda.dart` | Master Wilayah (Polda CRUD) | ✅ **Best reference pattern** — proper API fetch, DataTable, ActionButtons, add/edit/delete with modal dialogs |

### 2.3 API Endpoint Status

The backend already exposes the kategori-senjata endpoint:

```
GET  /api/v1/master/kategori-senjata    (used by form_input_senjata.dart:76, form_input_amunisi.dart:81)
```

Both form widgets consume it as a dropdown source. The response shape (from `form_input_senjata.dart` usage):

```json
{
  "data": [
    {
      "kategori_id": 5,
      "tipe_laras": "Pistol",
      "kaliber": "9mm"
    }
  ]
}
```

**However**, the existence of PUT/POST/DELETE endpoints for this resource is **unknown** — the form widgets only do `GET`. The backend likely supports full CRUD since it's presented as a master-data resource, but this needs verification.

### 2.4 Form pattern used by form_input_senjata (for reference)

The `FormTambahSenjata` widget (`lib/widget/form_input_senjata.dart`) is an **inline form widget** (not a modal dialog). It is instantiated inside a full-page scaffold (`add_senjata.dart`). The kategori dropdown is just one field of many in that form.

For the new "Master Kategori Senjata" page, a **modal/dialog-based form** pattern (like Polda uses) would be more appropriate, since category entries are small (just `tipe_laras` + `kaliber`) and don't need a full-page form.

---

## 3. What Needs to Be Built

### 3.1 New file: `lib/pages/master_kategori_senjata.dart`

A CRUD list page following the established pattern (model after `polda.dart`):

- **Title:** "Master Kategori Senjata & Kaliber"
- **Breadcrumb:** "Dashboard / Master Data / Kategori Senjata"
- **Sidebar route:** `kategori_senjata` (or reuse `inventaris` after fixing the menu config)
- **DataTable columns:** TIPE LARAS, KALIBER, AKSI
- **API:** `GET /api/v1/master/kategori-senjata`
- **Add button:** Opens a modal `AlertDialog` with two text fields (tipe_laras, kaliber)
- **Edit button:** Opens the same modal pre-filled
- **Delete button:** Confirmation dialog → `DELETE /api/v1/master/kategori-senjata/{id}`

### 3.2 Fix: `lib/config/menu_config.dart`

Change the "Master Logistik" entry (lines 115–119):

```dart
// BEFORE (buggy)
LeafMenuItem(
  label: "Master Logistik",
  icon: Icons.warehouse_rounded,
  routeName: "inventaris",
  pageBuilder: _in,
),

// AFTER (corrected)
LeafMenuItem(
  label: "Master Logistik",
  icon: Icons.warehouse_rounded,
  routeName: "kategori_senjata",
  pageBuilder: _ks,   // new builder → MasterKategoriSenjataPage
),
```

Also add the import and builder function:

```dart
import '../pages/master_kategori_senjata.dart';

Widget _ks() => const MasterKategoriSenjataPage();
```

### 3.3 Optional cleanup

The hardcoded `InventarisPage` (`lib/pages/inventaris.dart`) with static APC data is no longer needed as a standalone master-data target, but may still be reachable via other roles or navigation paths — verify before removing.

---

## 4. Summary

| Finding | Status |
|---|---|
| Menu "Master Logistik" → `InventarisPage` | 🔴 **BUG** — wrong page builder |
| `MasterKategoriSenjataPage` exists | 🔴 **MISSING** — must create from scratch |
| API `GET /api/v1/master/kategori-senjata` | 🟢 **EXISTS** — already consumed by form widgets |
| API POST/PUT/DELETE for kategori-senjata | 🟡 **UNKNOWN** — needs backend verification |
| Reference pattern (`polda.dart` CRUD) | 🟢 **AVAILABLE** — can be adapted |
| Modal/Dialog form pattern needed | 🟢 **ESTABLISHED** — Polda/Polres add pages use modal dialogs |

**Recommended next step:** Build `lib/pages/master_kategori_senjata.dart` using `polda.dart` as the template, then fix the `menu_config.dart` routing.
