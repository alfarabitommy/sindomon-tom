# Dropdown Bugfix — Frontend Implementation Results

> **Plan:** `plan/flutter_dropdown_bugfix_plan.md` (Task 1 — Frontend)
> **Date:** 2026-08-04
> **Status:** ✅ Implemented & Verified

---

## 1. Execution Summary

**File modified:** `lib/widget/form_input_personel.dart`

Applied the one-line JSON key correction in the Polres dropdown `items` mapping. The Polres records are parsed from the nested `polres` array of `GET /api/v1/polda`, which returns records with their native `tbl_polres` column names — the primary key is `polres_id`, not `id`.

**Root cause fixed:** Every `polres["id"]` evaluated to `null`, so `?? -1` assigned the value `-1` to **every** `DropdownMenuItem`. Flutter's `DropdownButton` then asserted — *"There should be exactly one item with [DropdownButton]'s value: -1"* — because multiple items shared the same value, crashing with a red screen.

**Before (line 408):**
```dart
value: int.tryParse(polres["id"].toString()) ?? -1,
```

**After (line 408):**
```dart
value: int.tryParse(polres["polres_id"].toString()) ?? -1,
```

The `-1` fallback is intentionally retained as collision prevention — a real `polres_id` (an auto-increment PK) will never equal `-1`, so the sentinel remains safe.

---

## 2. Code Diff Proof

```diff
--- a/lib/widget/form_input_personel.dart
+++ b/lib/widget/form_input_personel.dart
@@ -405,10 +405,10 @@
                         ...daftarPolres.map((polres) {
                           return DropdownMenuItem<int>(
-                            value: int.tryParse(polres["id"].toString()) ?? -1,
+                            value: int.tryParse(polres["polres_id"].toString()) ?? -1,
                             child: Text(polres["nama_polres"]),
                           );
                         }),
```

**Verification of the fix logic:**

| Item | Before fix | After fix |
|------|-----------|-----------|
| `polres["id"]` | `null` (key does not exist) | — |
| `polres["polres_id"]` | — | `polres_id` int (e.g. `1`, `2`, `3`) |
| Resulting dropdown values | `-1` for **every** item → duplicate-value assertion crash | unique per Polres → no collision |

---

## 3. Verification Status

**`flutter analyze`:** ✅ PASSED — **0 errors, 0 warnings** on `form_input_personel.dart`

Full output summary:

```
Analyzing sindomon-tom...
4 issues found. (ran in 6.3s)
```

The 4 remaining `info`-level lints (`use_build_context_synchronously`) are **pre-existing** and located exclusively in `lib/widget/login_card.dart` — untouched by this change. This satisfies the project's static-analysis standard (CLAUDE.md: "no errors, info-level only") and the plan's verification checklist item #2 ("zero errors on `form_input_personel.dart`").

---

## Scope Note

This execution covers **Task 1 (Frontend)** of the dropdown bugfix plan only, per the mission scope. Tasks 2–4 (backend `GET /api/v1/pangkat` and `GET /api/v1/jabatan` endpoints + route registration in `Master.php` / `routes.php`) remain **outstanding** for the disabled Pangkat/Jabatan dropdowns.
