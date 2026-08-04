# Bugfix Personel — Frontend Results

**Date:** 2026-08-04
**Branch:** dev
**Scope:** Frontend fix for the Polres dropdown assertion crash (Red Screen) when changing Polda in the Personel form.

---

## 1. Execution Summary

**File modified:** `lib/widget/form_input_personel.dart` (1 file)

Two targeted changes were applied to the Polres `DropdownButtonFormField<int>` `items` array:

1. **Removed the `if (daftarPolres.isNotEmpty)` guard** around the Sentinel `0` ("Tidak Ada / Mako Polda") `DropdownMenuItem`. The sentinel is now always rendered.

   **Why:** When the user changes Polda, `onChanged` sets `selectedPolresId = _polresNone` (0) and rebuilds `daftarPolres` from the new polda's nested polres. If the new polda has no polres, the guard hid the sentinel, leaving the dropdown with `value = 0` but no matching item — triggering the Flutter assertion `items.where((item) => item.value == value).length == 1` (the red screen).

2. **Changed the parse fallback for real polres items from `?? 0` to `?? -1`.**

   **Why:** A real polres with an unparseable `id` previously mapped to value `0`, colliding with the sentinel's `0` — producing two items with the same value (a second path to the same assertion). The sentinel `0` is now guaranteed unique.

No other dropdowns (Polda, Pangkat, Jabatan) required changes — the audit confirmed they have no conditional guards and rely on Flutter's `items.isEmpty` short-circuit during the async pre-load window, which is safe.

---

## 2. Code Diff Proof

**Before** (`items` array of the Polres `DropdownButtonFormField`):

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
  // Sentinel always present — selectedPolresId resets
  // to _polresNone (0) on Polda change, so the value
  // must always find a matching item. Flutter's
  // items.isEmpty short-circuit handles the
  // pre-async-load window safely.
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

**Diff summary:**

| Change | Location | Before | After |
|--------|----------|--------|-------|
| Sentinel guard removed | `items` array head | `if (daftarPolres.isNotEmpty) const DropdownMenuItem<int>(...)` | `const DropdownMenuItem<int>(...)` — always rendered |
| Fallback value changed | Real polres item `value` | `int.tryParse(polres["id"].toString()) ?? 0` | `int.tryParse(polres["id"].toString()) ?? -1` |

---

## 3. Verification Status

`flutter analyze` — **PASSED** ✅

```
Analyzing sindomon-tom...

   info • Don't use 'BuildContext's across async gaps, guarded by an unrelated 'mounted' check • lib/widget/login_card.dart:159:11 • use_build_context_synchronously
   info • Don't use 'BuildContext's across async gaps, guarded by an unrelated 'mounted' check • lib/widget/login_card.dart:165:11 • use_build_context_synchronously
   info • Don't use 'BuildContext's across async gaps, guarded by an unrelated 'mounted' check • lib/widget/login_card.dart:182:30 • use_build_context_synchronously
   info • Don't use 'BuildContext's across async gaps, guarded by an unrelated 'mounted' check • lib/widget/login_card.dart:206:28 • use_build_context_synchronously

4 issues found.
```

- **0 errors** — no type errors, no compile errors
- **0 issues in `form_input_personel.dart`** — the modified file is completely clean
- The 4 remaining info-level warnings are **pre-existing** in `lib/widget/login_card.dart` (untouched by this fix) and meet the project's CLAUDE.md standard ("no errors, info-level only")

**Manual QA checklist (pending live test):**
1. Create mode → select a Polda with polres → Polres dropdown shows "Tidak Ada / Mako Polda" + polres list (no crash)
2. Create mode → change Polda to one with no polres → "Tidak Ada / Mako Polda" is the only option (no crash)
3. Edit mode → personel with `polres_id = null` pre-fills to "Tidak Ada / Mako Polda" (no crash)
4. Edit mode → change Polda → polres dropdown repopulates without asserting
