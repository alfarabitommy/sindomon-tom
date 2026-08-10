# Phase 2 Report — HUD Sweep (Form Files)

> **Mode**: CODE/EXECUTE — changes applied directly to source.
> **Date**: 2026-08-10
> **Scope**: 7 form files in `lib/widget/` — submit-overlay integration, button-flag removal, multipart try/catch bug fix.
> **Diff footprint**: 7 files changed, **+172 / −204** lines (net −32).

---

## 1. Goal

Phase 2 of the J.A.R.V.I.S Arc Reactor loading-system integration:

1. Wrap every **submit operation** in a `HudLoading` overlay ("MENYIMPAN...").
2. **Remove** the `loading` / `isSubmitting` boolean flags that disabled submit buttons — the non-dismissible overlay barrier makes them redundant.
3. **Fix a pre-existing bug**: in the 3 multipart forms, the request preparation sat OUTSIDE the try/catch, so malformed fields could throw uncaught (and would have orphaned the overlay).
4. Replace image-**compression** `CircularProgressIndicator`s with `HudLoadingSpinner(size: 30)`.

**Explicitly NOT touched**:
- `CachedNetworkImage` placeholder in `form_inputan_satwa.dart` (line 198) — left exactly as-is.
- `form_input_amunisi.dart` — out of the 7-file scope (see § 7).
- Page files (Phase 1 scope, already done).

---

## 2. The Canonical Pattern Applied (JSON forms)

All 4 JSON-submit forms now follow this shape:

```dart
Future<void> submitX() async {
  // ...field validation (unchanged, returns early BEFORE show)...

  try {
    HudLoading.show(context, label: "MENYIMPAN...");   // ① top of try, before prefs

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    // ...build body, http.put / http.post ...

    final result = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      HudLoading.hide(context);                        // ② success — BEFORE mounted check
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(...); // success
      Navigator.pop(context, true);
    } else if (response.statusCode == 422) {           // personel only
      HudLoading.hide(context);                        // ③ business validation
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(...); // stay on form
    } else {
      HudLoading.hide(context);                        // ④ error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(...);
    }
  } catch (e) {
    HudLoading.hide(context);                          // ⑤ network error
    debugPrint(...);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(...);
    }
  }
  // NO finally block — see "Why the finally was removed" below
}
```

### Key placement decisions

**① `show` at the TOP of the `try` block (before `SharedPreferences`)**
The original code called `show` after token retrieval. Placing it before `prefs` means *every* code path after it has a real dialog up — so a `hide()` in `catch` can never pop an app page (the dialog always exists). `HudLoading.hide` is internally try/catch-guarded but a second pop is the one thing it cannot guard against; this ordering makes double-pop structurally impossible.

**②–⑤ `hide` BEFORE every `if (!mounted) return;` and every `ScaffoldMessenger` call**
Guarantees the barrier is down before any UI feedback, and that early-exit paths never orphan the overlay. The previous single `if (!mounted) return;` (before the status branch) was moved into each branch, after `hide()`.

**Why the `finally { setState(loading = false) }` blocks were REMOVED (not converted to `finally { HudLoading.hide() }`)**
The audit draft suggested converting the finally, but that creates a **double-pop hazard**: if `hide()` is already called in the exit path, a `finally` hide would pop the route *underneath* the dialog (the actual form page). Since the `loading` flag is gone, the finally has nothing left to do — so it was deleted entirely. Exactly one `hide()` per execution path is the invariant.

---

## 3. Per-File Changes

### 3.1 JSON forms — flag removal + overlay (4 files)

| File | Method | Removed flag | `hide` count | Why 4 hides for personel |
|---|---|---|---|---|
| `form_input_personel.dart` | `submitPersonel()` | `bool loading = false;` | **4** | 200 / **422** / else / catch — the 422 branch (e.g. duplicate NRP) stays on the form |
| `form_input_polda.dart` | `simpanPolda()` | `bool loading = false;` | 3 | 200 / else / catch |
| `form_input_polres.dart` | `simpanPolres()` | `bool loading = false;` | 3 | 200 / else / catch |
| `form_input_user.dart` | `submitUser()` | `bool isSubmitting = false;` | 3 | 200 / else / catch |

**Button changes (all 4 files):**
```dart
// BEFORE
onPressed: loading ? null : submitX,          // ← disabled while loading
child: loading
    ? const SizedBox(width: 24, height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: ...))
    : Text("Simpan Data", style: ...),

// AFTER
onPressed: submitX,                            // ← always enabled; overlay blocks input
child: Text(
  isEditMode ? "Update X" : "Simpan Data",
  style: const TextStyle(fontSize: 18),
),
```

### 3.2 Multipart forms — full try/catch wrapper fix (3 files)

| File | Method | Files affected |
|---|---|---|
| `form_input_sarpras.dart` | `submitData()` | sarpras |
| `form_input_senjata.dart` | `submitData()` | senjata |
| `form_inputan_satwa.dart` | `submitData()` | satwa |

**The pre-existing bug fixed**: previously only `request.send()` → `Response.fromStream()` was inside the `try`; the `MultipartRequest` construction, header/field assignment, and file attachment were OUTSIDE it. A throw in that setup (e.g. malformed field value) would escape uncaught.

**Now**: everything from `prefs` through the response handling is inside one `try`:
```dart
try {
  HudLoading.show(context, label: "MENYIMPAN...");

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("token") ?? "";
  final Uri uri = _isEdit ? ... : ...;
  final request = http.MultipartRequest("POST", uri);
  request.headers["Authorization"] = token;
  request.fields[...] = ...;
  if (_imageBytes != null) { request.files.add(...); }

  final streamed = await request.send();
  final response = await http.Response.fromStream(streamed);

  if (response.statusCode == 200 || response.statusCode == 201) {
    HudLoading.hide(context);
    if (!mounted) return;
    ScaffoldMessenger...; Navigator.pop(context, true);
  } else {
    HudLoading.hide(context);
    if (!mounted) return;
    ScaffoldMessenger...;
  }
} catch (e) {
  HudLoading.hide(context);
  debugPrint(e.toString());
  if (!mounted) return;
  ScaffoldMessenger...;  // "Gagal menyimpan data: jaringan bermasalah"
}
```
All original BUG-FIX comments (ID-in-URL, POST-for-both-modes) preserved verbatim.

### 3.3 Compression spinners (3 files)

| File | Location | Change |
|---|---|---|
| `form_input_sarpras.dart` | photo preview, `_isCompressing` ternary | `const Center(child: CircularProgressIndicator())` → `const Center(child: HudLoadingSpinner(size: 30))` |
| `form_input_senjata.dart` | photo preview, `_isCompressing` ternary | same |
| `form_inputan_satwa.dart` | photo preview, `_isCompressing` ternary | same |

These spinners indicate local WebP compression (not API calls) — the `size: 30` arc reactor matches the "form/dropdown" size tier from the audit.

---

## 4. Imports Added

| File | Import(s) |
|---|---|
| `form_input_personel.dart` | `import '../../utils/hud_loading.dart';` |
| `form_input_polda.dart` | `import '../../utils/hud_loading.dart';` |
| `form_input_polres.dart` | `import '../../utils/hud_loading.dart';` |
| `form_input_user.dart` | `import '../../utils/hud_loading.dart';` |
| `form_input_sarpras.dart` | `'../../utils/hud_loading.dart'` + `'../../widget/hud_loading_spinner.dart'` |
| `form_input_senjata.dart` | `'../../utils/hud_loading.dart'` + `'../../widget/hud_loading_spinner.dart'` |
| `form_inputan_satwa.dart` | `'../../utils/hud_loading.dart'` + `'../../widget/hud_loading_spinner.dart'` |

(Spinner import only where `HudLoadingSpinner` is actually used — the 3 multipart forms.)

---

## 5. Files Modified (diff summary)

| File | ± lines | What |
|---|---|---|
| `form_input_personel.dart` | 43 changed | flag, overlay, 422 branch, button |
| `form_input_polda.dart` | 41 changed | flag, overlay, button |
| `form_input_polres.dart` | 41 changed | flag, overlay, button |
| `form_input_user.dart` | 36 changed | flag, overlay, button |
| `form_input_sarpras.dart` | 75 changed | full try wrapper, overlay, compression spinner |
| `form_input_senjata.dart` | 67 changed | full try wrapper, overlay, compression spinner |
| `form_inputan_satwa.dart` | 73 changed | full try wrapper, overlay, compression spinner |

**Total: +172 / −204** — net line reduction of 32 (flags, ternaries, finally-blocks removed; try-wrapper adds indentation).

---

## 6. Verification Evidence

| Check | Method | Result |
|---|---|---|
| Only intended CPI remains | `grep CircularProgressIndicator lib/widget/` | 1 match: `form_inputan_satwa.dart:198` — the `CachedNetworkImage` placeholder, **intentionally ignored** ✅ |
| All flags removed | `grep "loading =\|isSubmitting" lib/widget/` | 0 matches ✅ |
| All show/hide present | `grep HudLoading.(show\|hide)` | 7 shows; hides per method = exit-path count (personel 4, others 3) ✅ |
| Compression spinners | `grep HudLoadingSpinner(size: 30)` | 3 files × 1 ✅ |
| `submitPersonel` structure | read-back lines 192–291 | show→prefs→put/post→200/422/else hides→catch hide; no finally, no loading ✅ |
| `submitData` (sarpras) structure | read-back lines 162–242 | entire multipart prep + send inside single try; hide before every mounted-check/snackbar ✅ |
| Imports | `grep hud_loading` | 4 files × 1 import; 3 files × 2 imports ✅ |

**Not verified**: `flutter analyze` — no `flutter`/`dart` binary in this environment. Syntax verified by structural review only. **Run `flutter analyze` before committing.**

---

## 7. Caveats & Follow-ups

1. **`flutter analyze` pending** — must run in a Flutter-enabled environment (CI or dev machine).
2. **`form_input_amunisi.dart` untouched** — out of the 7-file scope, but it has the same pre-fix shape: `submitData()` with **no try/catch at all** and no HUD overlay. Recommended as a small Phase 3 item to match the other forms.
3. **Overlay UX note**: for the 4 JSON forms, validation failures (e.g. empty required fields, missing password) still return BEFORE `show` — the user gets an instant snackbar with no flicker of the overlay. Intentional.
4. **422 branch (personel)**: user stays on the form after hide — correct, since they must fix the field. Snackbar appears after the barrier drops.
5. **`CachedNetworkImage` placeholder** in `form_inputan_satwa.dart` remains a plain CPI by design (image-loading indicator, not a loading state) — revisit only if 100% CPI removal is required.
6. **Phase 3 candidate list** (from audit): `form_input_amunisi.dart` submit, decision on remaining CachedNetworkImage placeholders, `dart format` normalization of `senjata.dart` (Phase 1 note).

---

*End of Phase 2 report.*
