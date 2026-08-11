# Flutter Pages Async Gap Audit — 7 Data Table Page Files

> **Audit date:** 2025-06-19  
> **Lint rule:** `use_build_context_synchronously`  
> **Severity:** info (25 occurrences across 7 files)  
> **Status:** DEBUG / PLAN MODE — no code written yet

---

## 1. Warning Summary

| # | File | Lines | Count |
|---|------|-------|-------|
| 1 | `pages/master_kategori_senjata.dart` | ~366, 373, 387, 417, 425, 435, 447 | **7** |
| 2 | `pages/personel.dart` | ~120, 128, 139 | **3** |
| 3 | `pages/polda.dart` | ~147, 155, 166 | **3** |
| 4 | `pages/polres.dart` | ~144, 152, 163 | **3** |
| 5 | `pages/sarpras.dart` | ~144, 154, 164 | **3** |
| 6 | `pages/satwa.dart` | ~143, 153, 163 | **3** |
| 7 | `pages/senjata.dart` | ~209, 219, 229 | **3** |
| **Total** | | | **25** |

---

## 2. Root Cause: Two distinct async-gap violations per method

Every file contains one or more async methods (typically `deleteXxx()` and, for master_kategori_senjata, `_saveKategori()`), and every method has **exactly two** structural bugs:

### Bug A — `HudLoading.show()` after `SharedPreferences` await, no guard

```dart
    final prefs = await SharedPreferences.getInstance();   // ← async gap
    final token = prefs.getString("token");

    HudLoading.show(context, label: "MENGHAPUS...");       // ← ❌ FLAGGED
    //    ^^^^^^^ context used across the async gap — no mount check before it
```

`HudLoading.show(context, ...)` passes `context` as an argument. Since the preceding `await SharedPreferences.getInstance()` created an async gap and no `if (!mounted) return;` intervenes, the linter flags it.

### Bug B — `HudLoading.hide()` before `if (!mounted) return;`

```dart
    if (response.statusCode == 200) {
        HudLoading.hide(context);      // ← ❌ FLAGGED — context BEFORE guard
        if (!mounted) return;          // guard comes one line too late
        ScaffoldMessenger.of(context).showSnackBar(...);
    } else {
        HudLoading.hide(context);      // ← ❌ FLAGGED — same bug
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(...);
    }
```

This is identical to the form-file bug from the previous audit: `HudLoading.hide(context)` consumes `context` on the line immediately before the guard that should protect it.

### 2.1 Why `master_kategori_senjata.dart` has 7 (not 3)

This file has **two** async methods with the same pattern:
- `_saveKategori()` — 1 show + 2 hides = **3 flags** (lines 366, 373, 387)
- `deleteKategori()` — 1 show + 3 hides (success, 409, else) = **4 flags** (lines 417, 425, 435, 447)

---

## 3. Fix Plan — Two mechanical operations per file

### Fix for Bug A (every file): Insert mount guard before `HudLoading.show()`

**Before:**
```dart
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      HudLoading.show(context, label: "MENGHAPUS...");
```

**After:**
```dart
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (!mounted) return;
      HudLoading.show(context, label: "MENGHAPUS...");
```

### Fix for Bug B (every file): Swap `HudLoading.hide()` with `if (!mounted) return;`

**Before:**
```dart
        HudLoading.hide(context);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
```

**After:**
```dart
        if (!mounted) return;
        HudLoading.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
```

---

## 4. Per-File Change Detail

### 4.1 `pages/master_kategori_senjata.dart` — 7 fixes

**Method A: `_saveKategori()` (lines 343–406)**

Fix 1 — line 366 (Bug A: `HudLoading.show`):
```dart
// BEFORE (line 366)
      HudLoading.show(context, label: "MENYIMPAN...");

// AFTER
      if (!mounted) return;
      HudLoading.show(context, label: "MENYIMPAN...");
```

Fix 2 — lines 373–374 (Bug B: swap):
```dart
// BEFORE
        HudLoading.hide(context);
        if (!mounted) return;

// AFTER
        if (!mounted) return;
        HudLoading.hide(context);
```

Fix 3 — lines 387–388 (Bug B: swap — same transformation).

---

**Method B: `deleteKategori()` (lines 412–469)**

Fix 4 — line 417 (Bug A: `HudLoading.show`):
```dart
// BEFORE
      HudLoading.show(context, label: "MENGHAPUS...");

// AFTER
      if (!mounted) return;
      HudLoading.show(context, label: "MENGHAPUS...");
```

Fix 5 — lines 425–426 (Bug B: swap)
Fix 6 — lines 435–436 (Bug B: swap)
Fix 7 — lines 447–448 (Bug B: swap)

---

### 4.2 `pages/personel.dart` — 3 fixes

**Method: `deletePersonel()` (lines 115–160)**

| Fix | Line(s) | Bug | Operation |
|-----|---------|-----|-----------|
| 1 | 120 | A | Insert `if (!mounted) return;` before `HudLoading.show` |
| 2 | 128–129 | B | Swap `HudLoading.hide` ↔ `if (!mounted) return;` |
| 3 | 139–140 | B | Swap same |

---

### 4.3 `pages/polda.dart` — 3 fixes

**Method: `deletePolda()` (lines 142–187)**

| Fix | Line(s) | Bug | Operation |
|-----|---------|-----|-----------|
| 1 | 147 | A | Insert `if (!mounted) return;` before `HudLoading.show` |
| 2 | 155–156 | B | Swap `HudLoading.hide` ↔ `if (!mounted) return;` |
| 3 | 166–167 | B | Swap same |

---

### 4.4 `pages/polres.dart` — 3 fixes

**Method: `deletePolres()` (lines 139–184)**

| Fix | Line(s) | Bug | Operation |
|-----|---------|-----|-----------|
| 1 | 144 | A | Insert `if (!mounted) return;` before `HudLoading.show` |
| 2 | 152–153 | B | Swap `HudLoading.hide` ↔ `if (!mounted) return;` |
| 3 | 163–164 | B | Swap same |

---

### 4.5 `pages/sarpras.dart` — 3 fixes

**Method: `deleteSarpras()` (lines 139–185)**

| Fix | Line(s) | Bug | Operation |
|-----|---------|-----|-----------|
| 1 | 144 | A | Insert `if (!mounted) return;` before `HudLoading.show` |
| 2 | 154–155 | B | Swap `HudLoading.hide` ↔ `if (!mounted) return;` |
| 3 | 164–165 | B | Swap same |

---

### 4.6 `pages/satwa.dart` — 3 fixes

**Method: `deleteSatwa()` (lines 138–184)**

| Fix | Line(s) | Bug | Operation |
|-----|---------|-----|-----------|
| 1 | 143 | A | Insert `if (!mounted) return;` before `HudLoading.show` |
| 2 | 153–154 | B | Swap `HudLoading.hide` ↔ `if (!mounted) return;` |
| 3 | 163–164 | B | Swap same |

---

### 4.7 `pages/senjata.dart` — 3 fixes

**Method: `deleteSenjata()` (lines 204–243)**

| Fix | Line(s) | Bug | Operation |
|-----|---------|-----|-----------|
| 1 | 209 | A | Insert `if (!mounted) return;` before `HudLoading.show` |
| 2 | 219–220 | B | Swap `HudLoading.hide` ↔ `if (!mounted) return;` |
| 3 | 229–230 | B | Swap same |

---

## 5. Total Change Set Summary

| File | Bug A (insert) | Bug B (swap) | Total changes |
|------|---------------|--------------|---------------|
| `master_kategori_senjata.dart` | 2 inserts | 5 swaps | 7 |
| `personel.dart` | 1 insert | 2 swaps | 3 |
| `polda.dart` | 1 insert | 2 swaps | 3 |
| `polres.dart` | 1 insert | 2 swaps | 3 |
| `sarpras.dart` | 1 insert | 2 swaps | 3 |
| `satwa.dart` | 1 insert | 2 swaps | 3 |
| `senjata.dart` | 1 insert | 2 swaps | 3 |
| **Total** | **8 inserts** | **17 swaps** | **25** |

All Bug A fixes use the exact same inserted line: `if (!mounted) return;`.

All Bug B fixes use the exact same swap pattern (identical to the form-file fix from the previous audit).

---

## 6. Catch Blocks — Bonus Finding

Every file's catch block has the same latent issue:

```dart
    } catch (e) {
      HudLoading.hide(context);       // ← not in user's report but same bug
      debugPrint("Error delete: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(...);
    }
```

(senjata.dart's catch block is even worse — it has no mount guard at all)

These are **out of scope** for this audit but noted for completeness.

---

## 7. Verification Plan

```bash
flutter analyze lib/pages/
```

Expected: all 25 `use_build_context_synchronously` warnings across these 7 files cleared.

Manual smoke test: perform one delete operation per entity type → verify HUD shows ("MENGHAPUS..."), then dismisses, snackbar appears ("berhasil dihapus"), and the data table refreshes.
