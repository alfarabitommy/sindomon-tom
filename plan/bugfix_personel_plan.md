# Bugfix: Personel Dropdown Assertion + Missing Polda JOIN

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix two QA bugs: (1) Polres dropdown assertion crash when changing Polda, and (2) missing `nama_polda` in the personil GET response causing raw `polda_id` display.

**Architecture:** Two independent fixes — one in Flutter frontend (`form_input_personel.dart`), one in PHP backend (`Sdm.php`). The frontend fix removes a conditional guard that hides the sentinel dropdown item when `daftarPolres` is empty. The backend fix adds a missing `LEFT JOIN tbl_polda` following the established pattern from `Master::polres_get()`.

**Tech Stack:** Flutter 3.29.3 (Dart), CodeIgniter 3 (PHP), MySQL

---

## Context

During QA testing of the Personel CRUD module, two bugs were discovered:

**Bug 1 (Frontend):** When selecting a Polda in the Personel form, the app crashes with:
```
Assertion failed: items.where((DropdownMenuItem<T> item) => item.value == value).length == 1.
There should be exactly one item with [DropdownButton]'s value: 0.
```

**Bug 2 (Backend):** The Personel DataTable displays the raw integer `polda_id` instead of the Polda name, because the backend `personil_get` method never JOINs `tbl_polda`.

---

## 1. Frontend Fix Plan

### Root Cause

In `lib/widget/form_input_personel.dart` lines 396-410, the Polres dropdown's sentinel item ("Tidak Ada / Mako Polda", value `0`) is conditionally shown only when `daftarPolres.isNotEmpty`:

```dart
items: [
  if (daftarPolres.isNotEmpty)     // ← BUG
    const DropdownMenuItem<int>(
      value: _polresNone,          // = 0
      child: Text("Tidak Ada / Mako Polda"),
    ),
  ...daftarPolres.map((polres) {
    return DropdownMenuItem<int>(
      value: int.tryParse(polres["id"].toString()) ?? 0,
      child: Text(polres["nama_polres"]),
    );
  }),
],
```

When the user changes Polda (lines 369-381), `onChanged` atomically sets `selectedPolresId = _polresNone` (0) and rebuilds `daftarPolres` from the new polda's nested polres. If the new polda has no polres, `daftarPolres` is empty and the `if` guard hides the sentinel. Flutter's `DropdownButton` then asserts because `items.where((item) => item.value == 0).length == 0` — zero items match value 0, when exactly one is required.

Note: Flutter 3.29.3's assert short-circuits on `items.isEmpty`, so a purely empty list (pre-async-load) does NOT crash. The crash fires specifically when `daftarPolres` is non-empty but doesn't contain value 0, or when the list rebuilds from non-empty to empty in the same frame while `selectedPolresId` remains 0.

### Fix A: Remove the Conditional Guard (Primary Fix)

**File:** `lib/widget/form_input_personel.dart`

**Change lines 396-404 — remove the `if (daftarPolres.isNotEmpty)` guard:**

**Before:**
```dart
items: [
  // Sentinel item included only when there are real
  // options — a sentinel-only list with a mismatched
  // edit value would trip DropdownButton's assert.
  if (daftarPolres.isNotEmpty)
    const DropdownMenuItem<int>(
      value: _polresNone,
      child: Text("Tidak Ada / Mako Polda"),
    ),
  ...daftarPolres.map((polres) {
    return DropdownMenuItem<int>(
      value: int.tryParse(polres["id"].toString()) ?? 0,
      child: Text(polres["nama_polres"]),
    );
  }),
],
```

**After:**
```dart
items: [
  // Sentinel always present — selectedPolresId resets to
  // _polresNone (0) on Polda change, ensuring value always
  // finds a match. Flutter's items.isEmpty short-circuit
  // handles the pre-async-load window safely.
  const DropdownMenuItem<int>(
    value: _polresNone,
    child: Text("Tidak Ada / Mako Polda"),
  ),
  ...daftarPolres.map((polres) {
    return DropdownMenuItem<int>(
      value: int.tryParse(polres["id"].toString()) ?? -1,
      child: Text(polres["nama_polres"]),
    );
  }),
],
```

### Fix B: Change `?? 0` fallback to `?? -1` (Collision Prevention)

The real polres items use `int.tryParse(...) ?? 0`. If any polres has an unparseable `id`, it maps to value `0`, colliding with the sentinel's `0` and creating two items with the same value (also causes the same assertion). Changing the fallback to `-1` eliminates this collision:

**Line 407:**
```dart
// Before:
value: int.tryParse(polres["id"].toString()) ?? 0,
// After:
value: int.tryParse(polres["id"].toString()) ?? -1,
```

### Audit of Other Dropdowns

Three other dropdowns were audited for the same class of assertion risk:

| Dropdown | Value source | Items source | Conditional guard? | Risk |
|----------|-------------|-------------|-------------------|------|
| **Polda** (lines 362-368) | `selectedPoldaId` nullable | `daftarPolda` async | None | **Safe** — `items.isEmpty` short-circuits during pre-load. Risk only if FK references deleted master record. |
| **Polres** (lines 396-410) | `selectedPolresId` reset to 0 on Polda change | `daftarPolres` rebuilt | `if (daftarPolres.isNotEmpty)` | **BUG** — this is the fix target. |
| **Pangkat** (lines 429-434) | `selectedPangkatId` nullable | `daftarPangkat` async | None | **Safe** — same as Polda. |
| **Jabatan** (lines 453-458) | `selectedJabatanId` nullable | `daftarJabatan` async | None | **Safe** — same as Polda. |

No other dropdowns have conditional guards. They rely on `items.isEmpty` short-circuiting during the async pre-load window, which is correct behavior in Flutter 3.29.3.

---

## 2. Backend Fix Plan

### Root Cause

In `/home/tommy/dev/sindomon-api-tom/application/controllers/Sdm.php`, the `personil_get` method builds its SELECT/JOIN chain with 3 JOINs — `tbl_pangkat`, `tbl_jabatan`, `tbl_polres` — but **never JOINs `tbl_polda`**. The SELECT includes `p.polda_id` (raw integer) but no `nama_polda`:

```php
$this->db->select("
    p.personil_id,
    p.nrp,
    p.nama_lengkap,
    p.status_aktif,
    p.polda_id,       // ← raw integer, no name from polda table
    p.polres_id,
    pkt.nama_pangkat,
    jbt.nama_jabatan,
    prs.nama_polres
")
->from('tbl_personil p')
->join('tbl_pangkat pkt', 'p.pangkat_id = pkt.pangkat_id', 'left')
->join('tbl_jabatan jbt', 'p.jabatan_id = jbt.jabatan_id', 'left')
->join('tbl_polres prs', 'p.polres_id = prs.polres_id', 'left');
// MISSING: ->join('tbl_polda pda', ...)
```

The Flutter frontend (`personel.dart`) tries `e["nama_polda"]?.toString()` first, but since the backend never sends it, the code falls back to the raw `e["polda_id"]?.toString()`.

### Fix: Add `tbl_polda` LEFT JOIN

**File:** `/home/tommy/dev/sindomon-api-tom/application/controllers/Sdm.php`

**Method:** `personil_get()` — the SELECT/JOIN block (approximately lines 162-171)

**Change 1 — Add `pda.nama_polda` to SELECT:**

Insert `pda.nama_polda,` after `p.polres_id,` and before `pkt.nama_pangkat,`:

```php
$this->db->select("
    p.personil_id,
    p.nrp,
    p.nama_lengkap,
    p.status_aktif,
    p.polda_id,
    p.polres_id,
    pda.nama_polda,
    pkt.nama_pangkat,
    jbt.nama_jabatan,
    prs.nama_polres
")
```

**Change 2 — Add `tbl_polda` LEFT JOIN:**

Insert after the `tbl_polres` join and before the dynamic filters block:

```php
->join('tbl_polda pda', 'p.polda_id = pda.id AND pda.is_active = 1', 'left')
```

**Complete corrected chain:**
```php
$this->db->select("
    p.personil_id,
    p.nrp,
    p.nama_lengkap,
    p.status_aktif,
    p.polda_id,
    p.polres_id,
    pda.nama_polda,
    pkt.nama_pangkat,
    jbt.nama_jabatan,
    prs.nama_polres
")
->from('tbl_personil p')
->join('tbl_pangkat pkt', 'p.pangkat_id = pkt.pangkat_id', 'left')
->join('tbl_jabatan jbt', 'p.jabatan_id = jbt.jabatan_id', 'left')
->join('tbl_polres prs', 'p.polres_id = prs.polres_id', 'left')
->join('tbl_polda pda', 'p.polda_id = pda.id AND pda.is_active = 1', 'left');
```

### Pattern Reference

This follows the exact established pattern from `Master::polres_get()` (`/home/tommy/dev/sindomon-api-tom/application/controllers/Master.php:264-306`):

```php
// Same idiom used in Master::polres_get():
$this->db->join('tbl_polda p', 'r.polda_id = p.id AND p.is_active = 1', 'left');
```

**Why `is_active = 1` in the ON clause?** A soft-deleted Polda should not leak its name into the response, but the personil row itself must still appear. Putting the guard in the ON clause yields `nama_polda = NULL` for soft-deleted parents rather than filtering the personil row out entirely. The Flutter frontend already handles this defensively:

```dart
Text(
  e["nama_polda"]?.toString() ??
      e["polda_id"]?.toString() ??
      "-",
),
```

**Why `pda.id` not `pda.polda_id`?** The `tbl_polda` primary key is `id` (INT), not `polda_id`. This differs from `tbl_polres` (PK is `polres_id`) and `tbl_pangkat` (PK is `pangkat_id`). The join condition correctly uses `p.polda_id = pda.id`.

---

## Verification Checklist

1. **Frontend:** `flutter analyze` — zero errors on `form_input_personel.dart`
2. **Frontend:** Create mode → select Polda → Polres dropdown always shows "Tidak Ada / Mako Polda" option (no crash)
3. **Frontend:** Change Polda to one with no Polres → "Tidak Ada / Mako Polda" is the only option (no crash)
4. **Frontend:** Edit mode → null polres pre-fills to "Tidak Ada / Mako Polda", real polres pre-fills correctly
5. **Backend:** `GET /api/v1/sdm/personil` → response includes `nama_polda` for each record
6. **Backend:** Personel DataTable shows Polda name string (not raw integer)
7. **Backend:** Personel under a soft-deleted Polda still appears, with Polda name falling back to raw `polda_id`
