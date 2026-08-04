# Personel CRUD — UI/UX Fix Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix two UX anomalies in the Personel module: (1) DataTable displaying raw Polda ID instead of name (verification), and (2) Operator Polda users seeing an editable Polda dropdown that the backend ignores — the illusion of choice.

**Architecture:** Two independent fixes in two files. Bug 1 is verification + comment only (the functional fix already exists on disk). Bug 2 adds `_roleId`, `_userPoldaId`, and `_poldaLocked` fields to `_FormTambahPersonelState`, loads them via a standalone `_loadUserContext()` async method, and re-applies the lock in `getPolda()` for race safety. The Polda dropdown's `onChanged` gates on `_poldaLocked`.

**Tech Stack:** Flutter 3.29.3 (Dart), SharedPreferences, http

**Critical reference keys (from login_card.dart:152-156):**
- `roleid_login` → String `"1"`, `"2"`, or `"3"` (mapped by `AppSidebar.roleLabelFromId`)
- `polda_login` → String polda ID (NOT `polda_id` — that's an API JSON key, not a prefs key)

---

## 1. UI Audit Findings

### Bug 1 — DataTable Polda Column (personel.dart:391–399)

**Status: Fixed on disk, needs verification.** The DataCell at lines 391–399 already contains the correct fallback chain:

```dart
DataCell(
  Text(
    e["nama_polda"]?.toString() ??
        e["polda_id"]?.toString() ??
        "-",
  ),
),
```

The same `nama_*` → `*_id` → `"-"` pattern is used for Pangkat (373–381), Jabatan (382–390), and Polres (400–408). If the DataTable still shows raw integers at runtime, the backend's `/api/v1/sdm/personil` is not returning `nama_polda` — the client code is already correct. The plan adds only a defensive comment.

### Bug 2 — Illusion of Choice (form_input_personel.dart:354–385)

**Confirmed active bug.** The Polda `DropdownButtonFormField<int>` at lines 354–385 has no role awareness:
- No `roleId` field exists in the State class
- No SharedPreferences read for `roleid_login` or `polda_login`
- `onChanged` is always active; an Operator Polda (role `"2"`) sees a full Polda picker and may select any Polda
- The backend ignores the submitted value and force-injects the JWT `polda_id` — the user's choice is silently discarded

**No precedent exists** in the app for `onChanged: null` (disabled dropdown). The closest pattern is `form_input_user.dart:435` which conditionally **shows/hides** the Polda field based on role. We are **locking** (not hiding) because the Operator needs to see their assigned Polda to understand the personnel's jurisdiction.

---

## 2. DataTable Fix Plan (personel.dart)

### Task 1: Verify and document the existing fix

**File:** `lib/pages/personel.dart`

- [ ] **Step 1: Read the Polda DataCell (lines 391–399)**

Confirm the current code matches:
```dart
DataCell(
  Text(
    e["nama_polda"]
            ?.toString() ??
        e["polda_id"]
            ?.toString() ??
        "-",
  ),
),
```

- [ ] **Step 2: If pattern is present — add a comment only**

Insert above line 391:
```dart
// POLDA: prefer the denormalized name returned by /api/v1/sdm/personil;
// fall back to the raw FK so the cell never renders blank when the
// backend omits nama_polda (defensive — same pattern as Pangkat/Jabatan/Polres).
```

- [ ] **Step 3: If pattern is missing — apply the full fallback**

Replace the existing DataCell content with the snippet from Step 1, matching the 70-column indentation style of surrounding columns.

- [ ] **Step 4: Run `flutter analyze`**

```bash
flutter analyze
```

Expected: zero errors on `personel.dart`.

---

## 3. Dropdown UX Fix Plan (form_input_personel.dart)

### Design decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Lock vs. Hide | **Lock** (disable) | Operator sees their Polda name — confirms jurisdiction. Hiding the field creates confusion about where personnel is saved. |
| Prefs read location | **Separate `_loadUserContext()` method** | Avoids coupling the Polda list fetch with role resolution. Both `_loadUserContext()` and `getPolda()` re-apply the lock — whichever finishes last wins, closing race windows. |
| State flag | **`_poldaLocked` boolean** | Cleaner than repeating `_roleId == "2" && _userPoldaId != null` everywhere. Derived once after both prefs resolve. |
| Visual signal | **`onChanged: null` + lock icon row + helper text** | Flutter's built-in disabled state greys out the dropdown. The lock icon and helper text explain *why* — not just *that* — it's locked. |
| Edit mode override | **Operator lock always wins** | The backend force-injects the JWT `polda_id`. If the Operator edits a person from another Polda, the form must reflect what will actually happen on save. |

### Task 2: Add new state fields

**File:** `lib/widget/form_input_personel.dart`

- [ ] **Step 1: Insert after line 35** (`List<Map<String, dynamic>> daftarJabatan = [];`)

```dart

  // Role context loaded from SharedPreferences.
  // _roleId: "1" (Super Admin), "2" (Operator Polda), "3" (Command Center)
  // _userPoldaId: raw string from "polda_login" prefs key
  // _poldaLocked: derived flag — true only when role == "2" AND polda is parseable
  String? _roleId;
  String? _userPoldaId;
  bool _poldaLocked = false;
```

### Task 3: Add `_loadUserContext()` method

- [ ] **Step 1: Insert the method** — place it after `getJabatan()` (ends around line 126) and before `submitPersonel()` (around line 128)

```dart
  /// Reads the logged-in user's role and Polda from SharedPreferences.
  /// For Operator Polda (role "2"), derives the [_poldaLocked] flag and
  /// force-sets [selectedPoldaId] to the operator's own Polda.
  ///
  /// Called from [initState]. Runs concurrently with [getPolda]; both
  /// completion paths re-apply the lock so the last writer always wins.
  Future<void> _loadUserContext() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString("roleid_login");
    final polda = prefs.getString("polda_login");

    if (!mounted) return;

    final userPoldaInt = (polda != null && polda.isNotEmpty)
        ? int.tryParse(polda)
        : null;

    setState(() {
      _roleId = role;
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
  }
```

- [ ] **Step 2: Call it from `initState()`** (line 262 — after `getPangkat(); getJabatan();`)

Add after line 261 (`getJabatan();`):
```dart
    _loadUserContext();
```

### Task 4: Make `getPolda()` re-apply the lock (race safety + polres cascade)

**File:** `lib/widget/form_input_personel.dart`

- [ ] **Step 1: Replace the `setState` block inside `getPolda()`** (lines 55–71)

Replace:
```dart
          setState(() {
            daftarPolda = List<Map<String, dynamic>>.from(body['data']);

            // Edit mode: polda is pre-selected in initState...
            if (isEditMode && selectedPoldaId != null) {
              final match = daftarPolda.where(
                (p) => int.tryParse(p["id"].toString()) == selectedPoldaId,
              ).toList();
              if (match.isNotEmpty) {
                daftarPolres = List<Map<String, dynamic>>.from(
                  match.first["polres"] ?? [],
                );
              }
            }
          });
```

With:
```dart
          setState(() {
            daftarPolda = List<Map<String, dynamic>>.from(body['data']);

            // Re-apply Operator lock after Polda list loads.
            // _loadUserContext() may already have pinned selectedPoldaId,
            // but we need the full daftarPolda list to populate daftarPolres
            // (the dependent Polres dropdown). This is intentionally
            // idempotent — whichever async completes last wins, and both
            // set the same value.
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

            // Edit mode (non-locked): match pre-selected polda from
            // initState and populate its polres list.
            if (isEditMode && selectedPoldaId != null) {
              final match = daftarPolda.where(
                (p) => int.tryParse(p["id"].toString()) == selectedPoldaId,
              ).toList();
              if (match.isNotEmpty) {
                daftarPolres = List<Map<String, dynamic>>.from(
                  match.first["polres"] ?? [],
                );
              }
            }
          });
```

### Task 5: Lock the Polda DropdownButtonFormField

**File:** `lib/widget/form_input_personel.dart`

- [ ] **Step 1: Replace the Polda dropdown block** (lines 354–385)

Replace the entire `SizedBox(width: itemWidth, child: formField(...))` containing the Polda dropdown with:

```dart
                SizedBox(
                  width: itemWidth,
                  child: formField(
                    label: "Polda *",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<int>(
                          value: selectedPoldaId,
                          // onChanged: null is Flutter's built-in disabled
                          // state — the field greys out and ignores taps.
                          // Operator Polda cannot change their assigned Polda.
                          onChanged: _poldaLocked
                              ? null
                              : (value) {
                                  setState(() {
                                    selectedPoldaId = value;
                                    selectedPolresId = _polresNone;

                                    final selectedPolda = daftarPolda.firstWhere(
                                      (item) =>
                                          int.tryParse(item["id"].toString()) ==
                                          value,
                                    );

                                    daftarPolres =
                                        List<Map<String, dynamic>>.from(
                                      selectedPolda["polres"] ?? [],
                                    );
                                  });
                                },
                          decoration: _poldaLocked
                              ? _inputDecoration.copyWith(
                                  helperText:
                                      "Disesuaikan dengan Polda Anda",
                                  helperStyle: const TextStyle(
                                    color: Color(0xFF1D4ED8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              : _inputDecoration,
                          hint: const Text("Pilih Polda"),
                          items: daftarPolda.map((polda) {
                            return DropdownMenuItem<int>(
                              value:
                                  int.tryParse(polda["id"].toString()) ?? 0,
                              child: Text(polda["nama_polda"]),
                            );
                          }).toList(),
                        ),
                        // Lock indicator — only visible for Operator Polda
                        if (_poldaLocked) ...[
                          const SizedBox(height: 6),
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_outline,
                                  size: 14, color: Color(0xFF6B7280)),
                              SizedBox(width: 4),
                              Text(
                                "Terkunci pada Polda Anda",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
```

**Note on `_inputDecoration.copyWith`:** `_inputDecoration` is a `static const` (line 271). `copyWith` on it is fine — it produces a new `InputDecoration` instance per build. The `helperText` and `helperStyle` are only set when locked; the unlocked path uses the original `_inputDecoration`.

**Note on `Column` wrapping:** The dropdown and lock indicator are wrapped in a `Column` inside `formField`. The `Wrap` parent (line 328) will flow this as a single item — no layout disruption.

### Task 6: Add defensive lock check in `submitPersonel()` (optional, defense-in-depth)

**File:** `lib/widget/form_input_personel.dart`

- [ ] **Step 1: Insert before the validation block** (before line 130, where `selectedPoldaId == null` check is)

```dart
    // Defense-in-depth: re-pin Operator Polda to their own Polda before
    // validation. The dropdown lock already enforces this; this guards
    // against any future code path that might mutate selectedPoldaId.
    if (_poldaLocked && _userPoldaId != null) {
      selectedPoldaId = int.tryParse(_userPoldaId!);
    }
```

This is optional. Skip if you prefer minimal changes — the lock already prevents mutation.

---

## 4. Edge Cases

| Scenario | Behavior |
|----------|----------|
| **Super Admin (role `"1"`) creates personnel** | Polda dropdown fully interactive. `_poldaLocked == false`, so `onChanged` is active. Hint: "Pilih Polda". No lock icon. |
| **Operator Polda (role `"2"`) creates personnel** | Polda dropdown locked with operator's Polda pre-selected (by name). Hint: "Pilih Polda" (but field is greyed out). Helper text: "Disesuaikan dengan Polda Anda" (blue). Lock icon row: "Terkunci pada Polda Anda". Polres list auto-populated from operator's Polda's nested polres. |
| **Command Center (role `"3"`)** | Same as Super Admin — fully interactive. Role `"3"` doesn't have Personel access in the menu, but if reached directly, no lock applies. |
| **`roleid_login` is null/missing** | `_roleId` stays null, `_poldaLocked == false`. Dropdown fully interactive (safe default). |
| **Role `"2"` but `polda_login` missing or unparseable** | `_poldaLocked == false`. Dropdown interactive. User can still select any Polda — the backend will reject or force-override, but at least the form is usable. |
| **Edit mode + Operator Polda** | `_loadUserContext()` overrides `selectedPoldaId` with operator's Polda, discarding the record's original `polda_id`. This matches the backend behavior (JWT force-inject). The operator sees a warning via the lock indicator that they cannot transfer personnel. |
| **Edit mode + Super Admin** | `selectedPoldaId` pre-filled from `personilData["polda_id"]` in `initState`. `getPolda()` matches it and populates Polres. Dropdown fully interactive — admin can transfer personnel. |
| **Async race: `getPolda()` finishes before `_loadUserContext()`** | `getPolda()` sees `_poldaLocked == false` (default), skips the lock branch. `_loadUserContext()` then sets `_poldaLocked = true` and `selectedPoldaId`. A subsequent `setState` in `getPolda()` would NOT re-run because it already completed — BUT the lock is already applied via `_loadUserContext()`. The dropdown renders locked. ✅ |
| **Async race: `_loadUserContext()` finishes before `getPolda()`** | `_loadUserContext()` sets `_poldaLocked = true` and `selectedPoldaId = userPoldaInt`. `getPolda()` then sees `_poldaLocked == true`, re-applies the lock, and populates `daftarPolres`. ✅ |
| **Dropdown items empty while locked value is set** | `DropdownButtonFormField` asserts only when `items` is non-empty but lacks the value. While `daftarPolda` is empty (async load in flight), a locked non-null `selectedPoldaId` renders the hint safely — same pattern the existing edit-mode prefill already relies on. No crash. |
| **Polres cascade for operator** | Operator sees only their Polda's Polres in the Polres dropdown. They can still choose "Tidak Ada / Mako Polda" (the `_polresNone` sentinel). Polres is within their jurisdiction — no lock needed. |

---

## 5. Verification

- [ ] **1. `flutter analyze`** — zero errors on both `personel.dart` and `form_input_personel.dart`
- [ ] **2. Super Admin (Role 1) — create mode:** Login as Super Admin → Personel → Tambah → Polda dropdown is interactive with "Pilih Polda" hint. Select a Polda → Polres dropdown populates. Submit succeeds.
- [ ] **3. Super Admin (Role 1) — edit mode:** Edit existing personnel → Polda dropdown shows the personnel's current Polda, can be changed. Polres cascade works.
- [ ] **4. Operator Polda (Role 2) — create mode:** Login as Operator → Personel → Tambah → Polda dropdown is **disabled** (greyed out), pre-selected with operator's Polda name. Helper text visible: "Disesuaikan dengan Polda Anda". Lock icon row visible: "Terkunci pada Polda Anda". Polres dropdown lists only that Polda's polres.
- [ ] **5. Operator Polda (Role 2) — edit mode:** Edit a personnel from a different Polda → Polda dropdown still shows the **operator's** Polda (locked), not the record's original Polda.
- [ ] **6. DataTable Polda column:** Open Personel list → POLDA column shows names ("Polda Metro Jaya"), not integers. If a row shows raw ID, check the network tab — the backend response is missing `nama_polda`.
- [ ] **7. Degraded state:** Simulate missing `polda_login` (clear it from SharedPreferences) → Operator sees an interactive Polda dropdown (no lock, no crash — safe fallback).

---

## 6. Files Summary

| File | Action | Lines |
|------|--------|-------|
| `lib/pages/personel.dart` | Verify `nama_polda` fallback + add comment | ~391 |
| `lib/widget/form_input_personel.dart` | Add `_roleId`, `_userPoldaId`, `_poldaLocked` fields | after 35 |
| `lib/widget/form_input_personel.dart` | Add `_loadUserContext()` method | after ~126 |
| `lib/widget/form_input_personel.dart` | Call `_loadUserContext()` from `initState()` | after 261 |
| `lib/widget/form_input_personel.dart` | Replace `setState` in `getPolda()` with lock-aware logic | 55–71 |
| `lib/widget/form_input_personel.dart` | Replace Polda dropdown with locked variant | 354–385 |
| `lib/widget/form_input_personel.dart` | Optional: defensive lock in `submitPersonel()` | before 130 |
