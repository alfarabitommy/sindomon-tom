# Personel CRUD — UI/UX Refactor Implementation Results

> **Plan:** `plan/flutter_personel_ux_plan.md`
> **Date:** 2026-08-04
> **Status:** ✅ Implemented & Verified

---

## 1. Execution Summary

Two files were modified, implementing the full approved UX refactor:

### `lib/pages/personel.dart` — DataTable Fix (Task 1)

Added a defensive documentation comment above the Polda DataCell (line 391). The functional fallback chain was verified as already correct on disk:

```dart
e["nama_polda"]?.toString() ?? e["polda_id"]?.toString() ?? "-"
```

The comment documents that the cell prefers the denormalized `nama_polda` name returned by `/api/v1/sdm/personil`, falling back to the raw FK so the cell never renders blank when the backend omits the key. **No functional change was required** — the fix pattern was already present.

### `lib/widget/form_input_personel.dart` — Dropdown UX Fix (Tasks 2–5)

Five targeted edits implemented the role-based Polda dropdown lock:

| # | Change | Location |
|---|--------|----------|
| 2 | Added `_userPoldaId` and `_poldaLocked` state fields | after `daftarJabatan` declaration |
| 3 | Added `_loadUserContext()` method reading `roleid_login` + `polda_login` from SharedPreferences; derives `_poldaLocked` and force-pins `selectedPoldaId` for Operator Polda (role `"2"`) | before `submitPersonel()` |
| 3 | Called `_loadUserContext()` from `initState()` | after `getJabatan()` |
| 4 | Replaced `getPolda()` setState with lock-aware logic — re-applies the lock after the Polda list loads and populates the dependent Polres list from the operator's own Polda (race-safe with `_loadUserContext()`) | inside `getPolda()` |
| 5 | Replaced the Polda `DropdownButtonFormField` with the locked variant — `onChanged` gated on `_poldaLocked`, blue helper text, and the visual lock indicator row | Polda field in `build()` |

---

## 2. Code Diff Highlights

### Visual Lock Indicator — helper text + lock icon row

The exact snippet where the lock UI was injected into the Polda `DropdownButtonFormField`:

```diff
                         DropdownButtonFormField<int>(
                           value: selectedPoldaId,
+                          // onChanged: null is Flutter's built-in disabled
+                          // state — the field greys out and ignores taps.
+                          // Operator Polda cannot change their assigned Polda.
+                          onChanged: _poldaLocked
+                              ? null
+                              : (value) {
                                   setState(() {
                                     selectedPoldaId = value;
                                     selectedPolresId = _polresNone;
                                     ...
                                   });
                                 },
+                          decoration: _poldaLocked
+                              ? _inputDecoration.copyWith(
+                                  helperText:
+                                      "Disesuaikan dengan Polda Anda",
+                                  helperStyle: const TextStyle(
+                                    color: Color(0xFF1D4ED8),
+                                    fontSize: 12,
+                                    fontWeight: FontWeight.w500,
+                                  ),
+                                )
+                              : _inputDecoration,
                           hint: const Text("Pilih Polda"),
                           items: daftarPolda.map((polda) {
                             ...
                           }).toList(),
                         ),
+                        // Lock indicator — only visible for Operator Polda
+                        if (_poldaLocked) ...[
+                          const SizedBox(height: 6),
+                          const Row(
+                            mainAxisSize: MainAxisSize.min,
+                            children: [
+                              Icon(Icons.lock_outline,
+                                  size: 14, color: Color(0xFF6B7280)),
+                              SizedBox(width: 4),
+                              Text(
+                                "Terkunci pada Polda Anda",
+                                style: TextStyle(
+                                  fontSize: 12,
+                                  color: Color(0xFF6B7280),
+                                ),
+                              ),
+                            ],
+                          ),
+                        ],
```

**UX signal stack for Operator Polda (role `"2"`):**
1. **Field disabled** — `onChanged: null` triggers Flutter's built-in greyed-out state; the field ignores taps
2. **Blue helper text** — "Disesuaikan dengan Polda Anda" explains the field is pre-configured to their jurisdiction
3. **Lock icon + caption** — 🔒 "Terkunci pada Polda Anda" confirms the lockdown, providing psychological reassurance that personnel cannot be silently transferred

### Supporting logic — `_loadUserContext()` core

```dart
final userPoldaInt = (polda != null && polda.isNotEmpty)
    ? int.tryParse(polda)
    : null;

setState(() {
  _userPoldaId = polda;

  // Lock only for Operator Polda (role "2") with a usable polda_id.
  // If polda_login is missing or unparseable, leave the dropdown
  // interactive — a locked-but-empty dropdown would block submission.
  _poldaLocked = role == "2" && userPoldaInt != null;

  if (_poldaLocked) {
    // Operator Polda: force their own Polda. This overrides the
    // edit-mode prefill from personilData["polda_id"] (requirement:
    // the backend always uses the JWT polda_id, so the UI must match).
    selectedPoldaId = userPoldaInt;
    selectedPolresId = _polresNone; // repopulated once daftarPolda loads
  }
});
```

### Race-condition safety net

Both async completion paths re-apply the lock — `_loadUserContext()` and `getPolda()` — so whichever finishes last wins with the same value:

```dart
// Re-apply Operator lock after Polda list loads. ... This is intentionally
// idempotent — whichever async completes last wins, and both set the same value.
if (_poldaLocked && _userPoldaId != null) {
  final lockedId = int.tryParse(_userPoldaId!);
  if (lockedId != null) {
    selectedPoldaId = lockedId;
    final match = daftarPolda.where(
      (p) => int.tryParse(p["id"].toString()) == lockedId,
    ).toList();
    if (match.isNotEmpty) {
      daftarPolres = List<Map<String, dynamic>>.from(
        match.first["polres"] ?? [],
      );
    }
  }
  return; // locked — skip the edit-mode branch below
}
```

---

## 3. Verification Status

**`flutter analyze`:** ✅ PASSED — **0 errors, 0 warnings** on both modified files

Full output summary:

```
Analyzing sindomon-tom...
4 issues found. (ran in 4.9s)
```

The 4 remaining `info`-level lints (`use_build_context_synchronously`) are **pre-existing** and located exclusively in `lib/widget/login_card.dart` — untouched by this change. This satisfies the project's static-analysis standard (CLAUDE.md: "no errors, info-level only").

**Cleanup note:** The initial analyze pass surfaced one `unused_field` warning for the `_roleId` field (stored but never read after deriving `_poldaLocked`). The field was removed and the lock derivation simplified to a local variable check — resulting in a fully clean pass with no warnings.

**Runtime verification checklist (manual, requires login as each role):**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Super Admin (role `"1"`) — create mode | Polda dropdown interactive, "Pilih Polda" hint, Polres cascade works |
| 2 | Super Admin (role `"1"`) — edit mode | Dropdown shows record's current Polda, changeable |
| 3 | Operator Polda (role `"2"`) — create mode | Dropdown **disabled**, pre-selected with operator's Polda name, blue helper "Disesuaikan dengan Polda Anda", lock icon "Terkunci pada Polda Anda", Polres lists only that Polda's polres |
| 4 | Operator Polda (role `"2"`) — edit mode | Dropdown shows **operator's** Polda (locked), not the record's original |
| 5 | DataTable Polda column | Shows Polda names; if a row shows raw ID, the backend `/api/v1/sdm/personil` response is missing `nama_polda` (client fallback is correct) |
| 6 | Degraded state (missing `polda_login`) | Operator sees interactive dropdown — safe fallback, no crash |
