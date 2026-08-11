# Flutter Forms Async Gap Audit — 7 Form Widget Files

> **Audit date:** 2025-06-19  
> **Lint rule:** `use_build_context_synchronously`  
> **Severity:** info (15 occurrences across 7 files)  
> **Status:** DEBUG / PLAN MODE — no code written yet

---

## 1. Warning Summary

| # | File | Lines | Count |
|---|------|-------|-------|
| 1 | `form_input_personel.dart` | ~253, ~271, ~280 | 3 |
| 2 | `form_input_polda.dart` | ~88, ~104 | 2 |
| 3 | `form_input_polres.dart` | ~96, ~112 | 2 |
| 4 | `form_input_sarpras.dart` | ~231, ~245 | 2 |
| 5 | `form_input_senjata.dart` | ~244, ~258 | 2 |
| 6 | `form_input_user.dart` | ~222, ~236 | 2 |
| 7 | `form_inputan_satwa.dart` | ~294, ~308 | 2 |
| **Total** | | | **15** |

---

## 2. Root Cause: `HudLoading.hide(context)` BEFORE the mount guard

### 2.1 The universal anti-pattern

Every single warning shares the identical root cause. All 7 files follow the same submit flow:

```dart
try {
  HudLoading.show(context, label: "MENYIMPAN...");

  final prefs = await SharedPreferences.getInstance();     // ← async gap
  final token = prefs.getString("token");

  // ... HTTP request (await) ...                          // ← async gap

  if (response.statusCode == 200 || response.statusCode == 201) {
    HudLoading.hide(context);       // ❌ LINE FLAGGED — context used BEFORE the guard
    if (!mounted) return;           // guard comes too late
    ScaffoldMessenger.of(context).showSnackBar(...);
    Navigator.pop(context, true);
  } else {
    HudLoading.hide(context);       // ❌ LINE FLAGGED — same bug
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(...);
  }
} catch (e) {
  HudLoading.hide(context);         // ⚠️ same bug in catch blocks (bonus finding)
  // ...
}
```

**The `HudLoading.hide(context)` call passes `context` as an argument — this is a `BuildContext` usage after an `await`, and it sits on the line IMMEDIATELY BEFORE the `if (!mounted) return;` guard.** The guard exists but it's one line too late. The linter sees `context` used at `HudLoading.hide(context)` with no guard between it and the preceding `await`.

### 2.2 Why `HudLoading.hide(context)` uses `BuildContext`

```dart
// lib/utils/hud_loading.dart:48
static void hide(BuildContext context) {
  try {
    Navigator.of(context, rootNavigator: true).pop();
  } catch (_) {}
}
```

The method signature takes `BuildContext context` as a parameter. When called as `HudLoading.hide(context)`, the `context` (which is `State.context`) is passed as an argument across the async gap — triggering `use_build_context_synchronously`.

### 2.3 The fix: swap — guard first, then hide

**Before (broken):**
```dart
      HudLoading.hide(context);       // ❌ context across async gap
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(...);
```

**After (fixed):**
```dart
      if (!mounted) return;
      HudLoading.hide(context);       // ✅ guarded
      ScaffoldMessenger.of(context).showSnackBar(...);
```

This is safe because:
- `HudLoading.hide()` already wraps its logic in `try { Navigator.pop() } catch (_) {}` — if the navigator is gone, it fails silently
- The `if (!mounted) return;` guard ensures we bail out early before touching the navigator, snackbar, or any other context-dependent API
- Semantically, it's identical: if the widget was unmounted during the HTTP request, neither hiding the HUD nor showing a snackbar is useful

---

## 3. Per-File Line-by-Line Detail

### 3.1 `form_input_personel.dart` — 3 warnings

**Method:** `submitPersonel()` (line 192)  
**Async gaps:** line 211 (`await SharedPreferences.getInstance()`), line 231/240 (`await http.put/post(...)`)

```dart
// SUCCESS BRANCH (line 252)
      if (response.statusCode == 200 || response.statusCode == 201) {
        HudLoading.hide(context);       // ← LINE 253 FLAGGED
        if (!mounted) return;           // ← guard at 254 comes AFTER context usage
        ScaffoldMessenger.of(context).showSnackBar(...);
        Navigator.pop(context, true);

// 422 BRANCH (line 268)
      } else if (response.statusCode == 422) {
        HudLoading.hide(context);       // ← LINE 271 FLAGGED
        if (!mounted) return;           // ← guard at 272 comes AFTER
        ScaffoldMessenger.of(context).showSnackBar(...);

// ELSE BRANCH (line 279)
      } else {
        HudLoading.hide(context);       // ← LINE 280 FLAGGED
        if (!mounted) return;           // ← guard at 281 comes AFTER
        ScaffoldMessenger.of(context).showSnackBar(...);
      }
```

**Fix:** For each branch, move `if (!mounted) return;` above `HudLoading.hide(context)`.

---

### 3.2 `form_input_polda.dart` — 2 warnings

**Method:** `simpanPolda()` (line 37)  
**Async gaps:** line 52 (`await SharedPreferences.getInstance()`), line 65/75 (`await http.put/post(...)`)

```dart
// SUCCESS BRANCH (line 87)
      if (response.statusCode == 200 || response.statusCode == 201) {
        HudLoading.hide(context);       // ← LINE 88 FLAGGED
        if (!mounted) return;           // ← guard at 89 too late
        ScaffoldMessenger.of(context).showSnackBar(...);
        Navigator.pop(context, true);

// ELSE BRANCH (line 103)
      } else {
        HudLoading.hide(context);       // ← LINE 104 FLAGGED
        if (!mounted) return;           // ← guard at 105 too late
        ScaffoldMessenger.of(context).showSnackBar(...);
      }
```

**Fix:** Move guard above `HudLoading.hide(context)` in both branches.

---

### 3.3 `form_input_polres.dart` — 2 warnings

**Method:** `simpanPolres()` (line 47)  
**Async gaps:** line 61 (`await SharedPreferences.getInstance()`), line 73/83 (`await http.put/post(...)`)

```dart
// SUCCESS BRANCH (line 95)
      if (response.statusCode == 200 || response.statusCode == 201) {
        HudLoading.hide(context);       // ← LINE 96 FLAGGED
        if (!mounted) return;           // ← guard at 97 too late
        ScaffoldMessenger.of(context).showSnackBar(...);
        Navigator.pop(context, true);

// ELSE BRANCH (line 111)
      } else {
        HudLoading.hide(context);       // ← LINE 112 FLAGGED
        if (!mounted) return;           // ← guard at 113 too late
        ScaffoldMessenger.of(context).showSnackBar(...);
      }
```

**Fix:** Same swap.

---

### 3.4 `form_input_sarpras.dart` — 2 warnings

**Method:** `submitData()` (line 164)  
**Async gaps:** line 192 (`await SharedPreferences.getInstance()`), line 225 (`await request.send()`), line 226 (`await http.Response.fromStream(streamed)`)

```dart
// SUCCESS BRANCH (line 230)
      if (response.statusCode == 200 || response.statusCode == 201) {
        HudLoading.hide(context);       // ← LINE 231 FLAGGED
        if (!mounted) return;           // ← guard at 232 too late
        ScaffoldMessenger.of(context).showSnackBar(...);
        Navigator.pop(context, true);

// ELSE BRANCH (line 244)
      } else {
        HudLoading.hide(context);       // ← LINE 245 FLAGGED
        if (!mounted) return;           // ← guard at 246 too late
        ScaffoldMessenger.of(context).showSnackBar(...);
      }
```

**Fix:** Same swap.

---

### 3.5 `form_input_senjata.dart` — 2 warnings

**Method:** `submitData()` (line 182)  
**Async gaps:** line 209 (`await SharedPreferences.getInstance()`), line 238 (`await request.send()`), line 239 (`await http.Response.fromStream(streamed)`)

```dart
// SUCCESS BRANCH (line 243)
      if (response.statusCode == 200 || response.statusCode == 201) {
        HudLoading.hide(context);       // ← LINE 244 FLAGGED
        if (!mounted) return;           // ← guard at 245 too late
        ScaffoldMessenger.of(context).showSnackBar(...);
        Navigator.pop(context, true);

// ELSE BRANCH (line 257)
      } else {
        HudLoading.hide(context);       // ← LINE 258 FLAGGED
        if (!mounted) return;           // ← guard at 259 too late
        ScaffoldMessenger.of(context).showSnackBar(...);
      }
```

**Fix:** Same swap.

---

### 3.6 `form_input_user.dart` — 2 warnings

**Method:** `submitUser()` (line 132)  
**Async gaps:** line 168 (`await SharedPreferences.getInstance()`), line 199/209 (`await http.put/post(...)`)

```dart
// SUCCESS BRANCH (line 221)
      if (response.statusCode == 200 || response.statusCode == 201) {
        HudLoading.hide(context);       // ← LINE 222 FLAGGED
        if (!mounted) return;           // ← guard at 223 too late
        ScaffoldMessenger.of(context).showSnackBar(...);
        Navigator.pop(context, true);

// ELSE BRANCH (line 235)
      } else {
        HudLoading.hide(context);       // ← LINE 236 FLAGGED
        if (!mounted) return;           // ← guard at 237 too late
        ScaffoldMessenger.of(context).showSnackBar(...);
      }
```

**Fix:** Same swap.

---

### 3.7 `form_inputan_satwa.dart` — 2 warnings

**Method:** `submitData()` (line 227)  
**Async gaps:** line 256 (`await SharedPreferences.getInstance()`), line 288 (`await request.send()`), line 289 (`await http.Response.fromStream(streamed)`)

```dart
// SUCCESS BRANCH (line 293)
      if (response.statusCode == 200 || response.statusCode == 201) {
        HudLoading.hide(context);       // ← LINE 294 FLAGGED
        if (!mounted) return;           // ← guard at 295 too late
        ScaffoldMessenger.of(context).showSnackBar(...);
        Navigator.pop(context, true);

// ELSE BRANCH (line 307)
      } else {
        HudLoading.hide(context);       // ← LINE 308 FLAGGED
        if (!mounted) return;           // ← guard at 309 too late
        ScaffoldMessenger.of(context).showSnackBar(...);
      }
```

**Fix:** Same swap.

---

## 4. Total Change Set — Identical Transformation × 15

Every fix is mechanically identical. In every branch:

### Before
```dart
        HudLoading.hide(context);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
```

### After
```dart
        if (!mounted) return;
        HudLoading.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
```

This is swapping exactly **two adjacent lines**: the `HudLoading.hide(context)` call and the `if (!mounted) return;` guard.

**Per-file swap count:**

| File | Swaps | Lines affected |
|------|-------|----------------|
| `form_input_personel.dart` | 3 | 253↔254, 271↔272, 280↔281 |
| `form_input_polda.dart` | 2 | 88↔89, 104↔105 |
| `form_input_polres.dart` | 2 | 96↔97, 112↔113 |
| `form_input_sarpras.dart` | 2 | 231↔232, 245↔246 |
| `form_input_senjata.dart` | 2 | 244↔245, 258↔259 |
| `form_input_user.dart` | 2 | 222↔223, 236↔237 |
| `form_inputan_satwa.dart` | 2 | 294↔295, 308↔309 |

**Total: 15 line-pair swaps across 7 files. Zero logic changes — pure reordering.**

---

## 5. Bonus: Catch Blocks

Every file's catch block has the same latent issue:

```dart
    } catch (e) {
      HudLoading.hide(context);      // ← same bug: context before guard
      debugPrint("Error: $e");
      if (!mounted) return;          // or: if (mounted) { ... }
      ScaffoldMessenger.of(context).showSnackBar(...);
    }
```

These weren't reported by the user (possibly the linter treats catch blocks differently, or they were filtered). They follow the identical pattern and would benefit from the same fix. They are noted here for completeness but are **out of scope** for this audit.

---

## 6. Verification Plan

After applying all 15 swaps:

```bash
flutter analyze lib/widget/
```

Expected: all 15 `use_build_context_synchronously` warnings in these 7 files cleared. Any remaining instances in catch blocks would be a separate follow-up.

Manual smoke test: submit each form (personel, polda, polres, sarpras, senjata, user, satwa) in both create and edit modes → verify HUD dismisses, snackbar appears, and navigation pops correctly.
