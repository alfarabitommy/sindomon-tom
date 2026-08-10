# Flutter HUD Sweep — CRUD Audit

> **Status**: DEBUG / PLAN MODE — no code has been written.
> **Target**: 15 source files (8 pages + 7 forms).
> **Goal**: Complete the J.A.R.V.I.S Arc Reactor loading system integration by replacing every remaining `CircularProgressIndicator` with `HudLoadingSpinner` and wrapping every CRUD operation with the `HudLoading` overlay.

---

## Legend

| Term | Meaning |
|---|---|
| **CPI** | `CircularProgressIndicator` — the widget to be replaced |
| **Inline spinner** | `HudLoadingSpinner(size: …)` rendered directly in the widget tree |
| **HUD overlay** | `HudLoading.show(…)` / `HudLoading.hide(…)` — full-screen non-dismissible barrier |
| **`loading` flag** | A `bool` state variable that disables a submit button and shows an inline CPI |
| **Size 50** | Page-level data-table loading placeholder |
| **Size 30** | Form/dropdown/image-placeholder loading feedback |
| **Size 18** | Tiny CachedNetworkImage placeholder (edge case — see § Decision Points) |

---

## Part A: Inline Spinner Sweep (`CircularProgressIndicator` → `HudLoadingSpinner`)

### Required import for every file touched in Part A

```dart
import '../widget/hud_loading_spinner.dart';
```

(Adjust to `'../../widget/hud_loading_spinner.dart'` for files under `lib/widget/`.)

---

### A1 — Pages (size: 50 for page-level spinners)

#### A1.1 `lib/pages/personel.dart`

| # | Line | Context | Replacement |
|---|---|---|---|
| 1 | 196 | Page-level `isLoading` spinner — `Expanded > Center > CircularProgressIndicator(color: Colors.amber)` | `HudLoadingSpinner(size: 50)` |

**`isLoading` flag at line 24**: **KEEP**. This flag drives conditional rendering of the initial-load state. It is NOT a button-disabler; the overlay sweep (Part B) does not affect it.

**No CachedNetworkImage placeholders** in this file.

---

#### A1.2 `lib/pages/polda.dart`

| # | Line | Context | Replacement |
|---|---|---|---|
| 1 | 193 | Page-level `isLoading` spinner — same pattern as personel | `HudLoadingSpinner(size: 50)` |

**`isLoading` at line 25**: KEEP.

---

#### A1.3 `lib/pages/polres.dart`

| # | Line | Context | Replacement |
|---|---|---|---|
| 1 | 190 | Page-level `isLoading` spinner | `HudLoadingSpinner(size: 50)` |

**`isLoading` at line 24**: KEEP.

---

#### A1.4 `lib/pages/senjata.dart`

| # | Line | Context | Replacement |
|---|---|---|---|
| 1 | 180 | `CachedNetworkImage` placeholder — `SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))` inside `_buildThumbnail()` | ⚠️ **Decision needed** (see § Decision Points). Recommended: `HudLoadingSpinner(size: 24)` or keep as-is. |

**Page-level spinner**: **NONE** — `senjata.dart` has no `if (isLoading)` guard in `build()`. The `isLoading` flag (line 24) is set but never read during rendering. This is a **pre-existing bug**: the page shows an empty table while data loads. Recommend adding the standard `if (isLoading)` → `HudLoadingSpinner(size: 50)` block for UX consistency.

---

#### A1.5 `lib/pages/sarpras.dart`

| # | Line | Context | Replacement |
|---|---|---|---|
| 1 | 329 | Page-level `isLoading` spinner — inline `isLoading ? const Center(child: CircularProgressIndicator()) : …` | `HudLoadingSpinner(size: 50)` (keep the conditional ternary) |
| 2 | 235 | `CachedNetworkImage` placeholder — `SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))` inside `_buildThumbnail()` | ⚠️ Same decision as senjata — `HudLoadingSpinner(size: 24)` or keep |

**`isLoading` at line 24**: KEEP.

---

#### A1.6 `lib/pages/satwa.dart`

| # | Line | Context | Replacement |
|---|---|---|---|
| 1 | 340 | Page-level `isLoading` spinner — same inline ternary as sarpras | `HudLoadingSpinner(size: 50)` |
| 2 | 221 | `CachedNetworkImage` placeholder — `SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))` inside `_buildThumbnail()` | ⚠️ Same decision — `HudLoadingSpinner(size: 24)` or keep |

**`isLoading` at line 24**: KEEP.

---

#### A1.7 `lib/pages/master_kategori_senjata.dart`

| # | Line | Context | Replacement |
|---|---|---|---|
| 1 | 541 | Page-level `isLoading` spinner — `isLoading ? const Center(child: CircularProgressIndicator(color: Colors.amber)) : …` | `HudLoadingSpinner(size: 50)` |

**`isLoading` at line 32**: KEEP.

**No image placeholders** in this file.

---

#### A1.8 `lib/pages/amunisi.dart`

| # | Line | Context | Replacement |
|---|---|---|---|
| 1 | 302 | Page-level `isLoading` spinner — `isLoading ? const Center(child: CircularProgressIndicator()) : …` | `HudLoadingSpinner(size: 50)` |

**`isLoading` at line 24**: KEEP.

**No image placeholders** in this file.

---

### A2 — Forms & Dropdowns (size: 30)

#### A2.1 `lib/widget/form_input_personel.dart`

| # | Line | Context | Replacement |
|---|---|---|---|
| 1 | 596 | Inline button spinner — `loading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: …)) : Text(…)` | **REMOVED** — this ternary and the CPI are replaced by the HUD overlay in Part B. The button child becomes just `Text(isEditMode ? "Update Personel" : "Simpan Data", …)`. |

**`loading` flag at line 23**: **REMOVE** (Part B).

---

#### A2.2 `lib/widget/form_input_polda.dart`

| # | Line | Context | Replacement |
|---|---|---|---|
| 1 | 233 | Inline button spinner — identical pattern to form_input_personel | **REMOVED** — replaced by HUD overlay in Part B. |

**`loading` flag at line 22**: **REMOVE** (Part B).

---

#### A2.3 `lib/widget/form_input_polres.dart`

| # | Line | Context | Replacement |
|---|---|---|---|
| 1 | 271 | Inline button spinner — identical pattern | **REMOVED** — replaced by HUD overlay in Part B. |

**`loading` flag at line 20**: **REMOVE** (Part B).

---

#### A2.4 `lib/widget/form_input_sarpras.dart`

| # | Line | Context | Replacement |
|---|---|---|---|
| 1 | 503 | Image compression spinner — `_isCompressing ? const Center(child: CircularProgressIndicator())` inside the photo preview container (180px tall) | `_isCompressing ? const Center(child: HudLoadingSpinner(size: 30))` |

**No `loading`/`isSubmitting` flag exists** for the submit button. The submit button is never disabled during upload.

---

#### A2.5 `lib/widget/form_input_senjata.dart`

| # | Line | Context | Replacement |
|---|---|---|---|
| 1 | 434 | Image compression spinner — identical to sarpras (`_isCompressing ? const Center(child: CircularProgressIndicator())`) | `_isCompressing ? const Center(child: HudLoadingSpinner(size: 30))` |

**No `loading`/`isSubmitting` flag**.

---

#### A2.6 `lib/widget/form_input_user.dart`

| # | Line | Context | Replacement |
|---|---|---|---|
| 1 | 526 | Inline button spinner — `isSubmitting ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: …)) : Text(…)` | **REMOVED** — replaced by HUD overlay in Part B. |

**`isSubmitting` flag at line 26**: **REMOVE** (Part B).

---

#### A2.7 `lib/widget/form_inputan_satwa.dart`

| # | Line | Context | Replacement |
|---|---|---|---|
| 1 | 599 | Image compression spinner — `_isCompressing ? const Center(child: CircularProgressIndicator())` (same as sarpras/senjata) | `_isCompressing ? const Center(child: HudLoadingSpinner(size: 30))` |
| 2 | 196 | CachedNetworkImage placeholder inside `_buildPhotoPreview()` — `CircularProgressIndicator(strokeWidth: 2)` (no SizedBox wrapper) | ⚠️ Replace with `HudLoadingSpinner(size: 24)` — the parent container is the `CachedNetworkImage` placeholder which fills a 180px tall container. |

**No `loading`/`isSubmitting` flag**.

---

## Part B: CRUD Overlay Integration (`HudLoading.show` / `HudLoading.hide`)

### Required import for every file touched in Part B

```dart
import '../utils/hud_loading.dart';
```

(Adjust to `'../../utils/hud_loading.dart'` for files under `lib/widget/`.)

### Pattern for safe placement

Every `HudLoading.show()` must have a matching `HudLoading.hide()` on **all** exit paths (success, error, catch). The `hide()` call goes **before** any `Navigator.pop()` or `ScaffoldMessenger.showSnackBar()` so the overlay is already dismissed when the next route transition or UI feedback appears.

---

### B1 — Pages: Delete Operations

All eight list pages have a `delete*` method following one of two structural patterns. The `HudLoading` injection is identical in all cases.

#### Pattern 1 (with errorMessage): personel, polda, polres, master_kategori_senjata

**Files**: `personel.dart`, `polda.dart`, `polres.dart`, `master_kategori_senjata.dart`

```
Method signature: deletePersonel(String id) / deletePolda(int id) / deletePolres(int id) / deleteKategori(String id)
```

| Step | Insertion point | What to insert |
|---|---|---|
| 1 | **After** `final token = prefs.getString("token");` and **before** `final response = await http.delete(…)` | `HudLoading.show(context, label: "MENGHAPUS…");` |
| 2 | **Before** the success snackbar (after `if (response.statusCode == 200)`) | `HudLoading.hide(context);` |
| 3 | **Before** any error snackbar (after `} else {`) | `HudLoading.hide(context);` |
| 4 | **Before** the catch snackbar (after `} catch (e) {` and before `ScaffoldMessenger…`) | `HudLoading.hide(context);` |

**Concrete example — `personel.dart` `deletePersonel()` (lines 112–152):**

```dart
// … after token line 115, insert:
HudLoading.show(context, label: "MENGHAPUS…");

// Line 117: final response = await http.delete(…);

// Line 122: if (!mounted) return;

// Line 124: if (response.statusCode == 200) {
//   INSERT: HudLoading.hide(context);
//   final result = jsonDecode(response.body);
//   ScaffoldMessenger.of(context).showSnackBar(…);
//   getPersonelApi();
// } else {
//   INSERT: HudLoading.hide(context);
//   final result = jsonDecode(response.body);
//   ScaffoldMessenger.of(context).showSnackBar(…);
// }

// catch block:
// } catch (e) {
//   INSERT: HudLoading.hide(context);
//   debugPrint(…);
//   if (!mounted) return;
//   ScaffoldMessenger.of(context).showSnackBar(…);
// }
```

**⚠️ Critical**: Note that the `HudLoading.hide()` must go BEFORE `if (!mounted) return;` in the success block — otherwise a rapid unmount could leave the overlay orphaned. The safe pattern is:

```dart
if (response.statusCode == 200) {
  HudLoading.hide(context);        // ← always runs
  if (!mounted) return;            // ← then early-exit if needed
  // … snackbar + refresh
}
```

The same applies to all 8 delete methods. Currently some have `if (!mounted) return;` before the status check (personel, polda, polres) and some have it inside (sarpras, satwa, senjata, amunisi). The HUD hide must be placed to run before any early return.

---

#### Pattern 2 (no errorMessage): senjata, sarpras, satwa, amunisi

**Files**: `senjata.dart`, `sarpras.dart`, `satwa.dart`, `amunisi.dart`

Same injection points as Pattern 1. The only structural difference is that `mounted` checks are inside specific branches rather than at the top.

| File | Method | Lines | Label |
|---|---|---|---|
| `senjata.dart` | `deleteSenjata(String id)` | 201–235 | `"MENGHAPUS…"` |
| `sarpras.dart` | `deleteSarpras(String id)` | 136–177 | `"MENGHAPUS…"` |
| `satwa.dart` | `deleteSatwa(String id)` | 135–176 | `"MENGHAPUS…"` |
| `amunisi.dart` | `deleteAmunisi(String id)` | 179–219 | `"MENGHAPUS…"` |

---

### B2 — Pages: Save Operations (master_kategori_senjata only)

`master_kategori_senjata.dart` is the only page file that contains an inline save method (`_saveKategori()`, lines 338–397). The method is called from the dialog result handler `_showKategoriForm()` at line 310.

**`_saveKategori()` injection plan:**

| Step | Line | What |
|---|---|---|
| 1 | After line 343 (`final String body = …`) and before line 361 (`final http.Response response = …`) | `HudLoading.show(context, label: "MENYIMPAN…");` |
| 2 | Before success snackbar (after line 367 check) | `HudLoading.hide(context);` |
| 3 | Before error snackbar (after line 379 else) | `HudLoading.hide(context);` |
| 4 | Before catch snackbar (after line 387 catch) | `HudLoading.hide(context);` |

---

### B3 — Forms: Submit Operations (+ removal of `loading`/`isSubmitting` flags)

#### B3.1 `lib/widget/form_input_personel.dart` — `submitPersonel()` (lines 192–304)

**Current state:**
- `bool loading = false;` (line 23) — flag
- `setState(() { loading = true; });` (line 208) — enables inline spinner
- `finally { if (mounted) { setState(() { loading = false; }); } }` (lines 297–303)
- Button: `onPressed: loading ? null : submitPersonel` (line 585) — disabled during load
- Button child: `loading ? const SizedBox(…CircularProgressIndicator…) : Text(…)` (lines 592–604)

**Changes:**

| Step | What | Detail |
|---|---|---|
| 1 | Remove flag | Delete `bool loading = false;` at line 23 |
| 2 | Add HUD show | Replace `setState(() { loading = true; });` at line 208 with `HudLoading.show(context, label: "MENYIMPAN…");` |
| 3 | Add HUD hide in finally | Replace `finally { if (mounted) { setState(() { loading = false; }); } }` at lines 297–303 with `finally { HudLoading.hide(context); }` |
| 4 | Un-disable button | Change `onPressed: loading ? null : submitPersonel` (line 585) → `onPressed: submitPersonel` |
| 5 | Remove inline spinner | Change the `child:` ternary (lines 592–604) from `loading ? const SizedBox(…CPI…) : Text(…)` → `Text(isEditMode ? "Update Personel" : "Simpan Data", style: const TextStyle(fontSize: 18))` |

**Import to add**: `import '../../utils/hud_loading.dart';`

---

#### B3.2 `lib/widget/form_input_polda.dart` — `simpanPolda()` (lines 37–130)

Identical structure to form_input_personel.

| Step | Line | What |
|---|---|---|
| 1 | 22 | **Remove** `bool loading = false;` |
| 2 | 49–51 | **Replace** `setState(() { loading = true; });` → `HudLoading.show(context, label: "MENYIMPAN…");` |
| 3 | 123–129 | **Replace** `finally { if (mounted) { setState(() { loading = false; }); } }` → `finally { HudLoading.hide(context); }` |
| 4 | 227 | **Change** `onPressed: loading ? null : simpanPolda` → `onPressed: simpanPolda` |
| 5 | 229–237 | **Replace** ternary → `Text(isEditMode ? "Update Polda" : "Simpan Data", style: const TextStyle(fontSize: 18))` |

**Import**: `import '../../utils/hud_loading.dart';`

---

#### B3.3 `lib/widget/form_input_polres.dart` — `simpanPolres()` (lines 47–138)

Identical structure.

| Step | Line | What |
|---|---|---|
| 1 | 20 | **Remove** `bool loading = false;` |
| 2 | 58–60 | **Replace** `setState(() { loading = true; });` → `HudLoading.show(context, label: "MENYIMPAN…");` |
| 3 | 131–137 | **Replace** `finally` block → `finally { HudLoading.hide(context); }` |
| 4 | 265 | **Change** `onPressed: loading ? null : simpanPolres` → `onPressed: simpanPolres` |
| 5 | 267–275 | **Replace** ternary → `Text(isEditMode ? "Update Polres" : "Simpan Data", style: const TextStyle(fontSize: 18))` |

**Import**: `import '../../utils/hud_loading.dart';`

---

#### B3.4 `lib/widget/form_input_sarpras.dart` — `submitData()` (lines 162–258)

**Current state**: NO `loading` flag. The submit button is never disabled. No try/catch wraps the multipart upload.

| Step | Line / Location | What |
|---|---|---|
| 1 | Before line 220 (`final streamed = await request.send();`) | **Insert** `HudLoading.show(context, label: "MENYIMPAN…");` |
| 2 | Before line 228 (`ScaffoldMessenger.of(context).showSnackBar(…success…)`) after `if (response.statusCode == 200 \|\| response.statusCode == 201)` | **Insert** `HudLoading.hide(context);` |
| 3 | Before line 241 (`ScaffoldMessenger.of(context).showSnackBar(…error…)`) inside `else` block | **Insert** `HudLoading.hide(context);` |
| 4 | Before line 251 (`ScaffoldMessenger.of(context).showSnackBar(…catch…)`) inside `catch` block | **Insert** `HudLoading.hide(context);` |

**⚠️ Pre-existing bug**: The `request.send()` at line 220 and the `http.Response.fromStream()` at line 222 are inside a `try` block, but the multipart request setup (lines 198–218) is OUTSIDE the `try`. A malformed request will throw an uncaught exception. Recommend wrapping the full operation in try/catch. Also add `HudLoading.hide(context);` in the new, wider catch block.

**Import**: `import '../../utils/hud_loading.dart';`

---

#### B3.5 `lib/widget/form_input_senjata.dart` — `submitData()` (lines 180–271)

Identical pattern to sarpras — NO `loading` flag.

| Step | Location | What |
|---|---|---|
| 1 | Before `final streamed = await request.send();` at line 234 | **Insert** `HudLoading.show(context, label: "MENYIMPAN…");` |
| 2 | Before success snackbar at line 241 | **Insert** `HudLoading.hide(context);` |
| 3 | Before error snackbar at line 254 | **Insert** `HudLoading.hide(context);` |
| 4 | Before catch snackbar at line 264 | **Insert** `HudLoading.hide(context);` |

Same pre-existing lack of full try/catch as sarpras.

**Import**: `import '../../utils/hud_loading.dart';`

---

#### B3.6 `lib/widget/form_input_user.dart` — `submitUser()` (lines 129–255)

Same structure as form_input_personel but uses `isSubmitting` instead of `loading`.

| Step | Line | What |
|---|---|---|
| 1 | 26 | **Remove** `bool isSubmitting = false;` |
| 2 | 162 | **Replace** `setState(() => isSubmitting = true);` → `HudLoading.show(context, label: "MENYIMPAN…");` |
| 3 | 250–254 | **Replace** `finally { if (mounted) { setState(() => isSubmitting = false); } }` → `finally { HudLoading.hide(context); }` |
| 4 | 521 | **Change** `onPressed: isSubmitting ? null : submitUser` → `onPressed: submitUser` |
| 5 | 522–531 | **Replace** ternary → `Text(isEditMode ? "Update Akun" : "Simpan Akun", style: const TextStyle(fontSize: 18))` |

**Import**: `import '../../utils/hud_loading.dart';`

---

#### B3.7 `lib/widget/form_inputan_satwa.dart` — `submitData()` (lines 223–319)

Identical pattern to sarpras — NO `loading` flag.

| Step | Location | What |
|---|---|---|
| 1 | Before `final streamed = await request.send();` at line 282 | **Insert** `HudLoading.show(context, label: "MENYIMPAN…");` |
| 2 | Before success snackbar at line 289 | **Insert** `HudLoading.hide(context);` |
| 3 | Before error snackbar at line 303 | **Insert** `HudLoading.hide(context);` |
| 4 | Before catch snackbar at line 312 | **Insert** `HudLoading.hide(context);` |

Same pre-existing lack of full try/catch.

**Import**: `import '../../utils/hud_loading.dart';`

---

## Part C: Variable Removal Summary

These flags exist **only** to disable the submit button and show an inline button CPI. Both are superseded by the HUD overlay barrier.

| File | Flag name | Line | Action |
|---|---|---|---|
| `form_input_personel.dart` | `bool loading = false;` | 23 | **REMOVE** |
| `form_input_polda.dart` | `bool loading = false;` | 22 | **REMOVE** |
| `form_input_polres.dart` | `bool loading = false;` | 20 | **REMOVE** |
| `form_input_user.dart` | `bool isSubmitting = false;` | 26 | **REMOVE** |

**Page-level `bool isLoading` flags are NOT removed.** They drive the initial-data-fetch spinner (which is being upgraded from CPI → HudLoadingSpinner inline, not overlaid).

---

## Part D: Decision Points

### D1 — CachedNetworkImage placeholders (18px CPIs)

These are tiny spinners inside image thumbnail containers across 4 page files and 1 form file:

| File | Line | Container size |
|---|---|---|
| `senjata.dart` | 180 | 80×50 (thumbnail) |
| `sarpras.dart` | 235 | 60×60 (thumbnail) |
| `satwa.dart` | 221 | 60×60 (thumbnail) |
| `form_inputan_satwa.dart` | 196 | 180px-tall full-width photo preview |

**Options:**
1. **Replace with `HudLoadingSpinner(size: 24)`** — the arc reactor animation is legible at this size but looks crowded in a 50px thumbnail. Feels heavy for a placeholder.
2. **Keep as `CircularProgressIndicator(strokeWidth: 2)`** — these are NOT user-facing "loading states"; they're image-loading placeholders. The arc reactor aesthetic doesn't match the use case.
3. **Replace with `HudLoadingSpinner(size: 18, outerStrokeWidth: 1.5, innerStrokeWidth: 1.5)`** — scaled-down arc reactor. Might be illegible.

**Recommendation**: Option 2 — keep these as `CircularProgressIndicator` because they're inside `CachedNetworkImage` widgets and semantically distinct from CRUD loading states. If the user wants 100% CPI replacement, use option 1.

### D2 — `senjata.dart` missing page-level spinner

`senjata.dart` has `bool isLoading = true;` (line 24) but never renders a spinner in `build()`. The table renders immediately, showing empty rows while data loads. **Recommend**: add the standard `if (isLoading)` → `HudLoadingSpinner(size: 50)` guard in `build()` as part of this sweep.

### D3 — Lack of try/catch in multipart forms

`sarpras.dart`, `senjata.dart`, `satwa.dart`, and `amunisi.dart` forms have their `request.send()` inside a try block, but the multipart request preparation (field assignment, file attachment) is outside. A malformed field would throw uncaught. **Recommend**: expand the try/catch to cover the full operation so the HUD overlay is always hidden.

### D4 — `form_input_amunisi.dart` exclusion

This file was not in the user's scope but follows the same multipart-submit pattern as sarpras/senjata/satwa with NO `loading` flag and NO try/catch. It should be included for consistency. It has zero `CircularProgressIndicator` instances.

---

## Part E: Execution Order (Recommended)

To minimize rebase risk and allow incremental verification:

1. **Phase 1 — Inline Spinner Sweep (Part A)**  
   All 8 page files + 7 form files. Replace CPIs with `HudLoadingSpinner`. No behavioral changes — just widget swaps.

2. **Phase 2 — Form CRUD Overlay (Part B3)**  
   The 7 form files. Add HUD overlay + remove `loading`/`isSubmitting` flags. Verify submit flows.

3. **Phase 3 — Page Delete Overlay (Part B1–B2)**  
   The 8 page files. Add HUD overlay to delete methods. Verify delete flows.

4. **Phase 4 — Decision Points (Part D)**  
   Resolve CachedNetworkImage placeholders, fix senjata.dart missing spinner, expand try/catch.

---

## Part F: Import Summary

### Files needing `import '../widget/hud_loading_spinner.dart';`

| Page files (no path adjustment) | Form files (in `lib/widget/`) |
|---|---|
| `personel.dart` | `form_input_personel.dart` |
| `polda.dart` | `form_input_polda.dart` |
| `polres.dart` | `form_input_polres.dart` |
| `senjata.dart` | `form_input_sarpras.dart` |
| `sarpras.dart` | `form_input_senjata.dart` |
| `satwa.dart` | `form_input_user.dart` |
| `master_kategori_senjata.dart` | `form_inputan_satwa.dart` |
| `amunisi.dart` | |

### Files needing `import '../utils/hud_loading.dart';` (or `../../utils/hud_loading.dart'` for widgets)

| Page files | Form files |
|---|---|
| `personel.dart` | `form_input_personel.dart` — `'../../utils/hud_loading.dart'` |
| `polda.dart` | `form_input_polda.dart` — `'../../utils/hud_loading.dart'` |
| `polres.dart` | `form_input_polres.dart` — `'../../utils/hud_loading.dart'` |
| `senjata.dart` | `form_input_sarpras.dart` — `'../../utils/hud_loading.dart'` |
| `sarpras.dart` | `form_input_senjata.dart` — `'../../utils/hud_loading.dart'` |
| `satwa.dart` | `form_input_user.dart` — `'../../utils/hud_loading.dart'` |
| `master_kategori_senjata.dart` | `form_inputan_satwa.dart` — `'../../utils/hud_loading.dart'` |
| `amunisi.dart` | |

---

*End of audit. Ready for execution upon user approval.*
