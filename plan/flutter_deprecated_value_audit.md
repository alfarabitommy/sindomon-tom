# Flutter Deprecated `value:` → `initialValue:` Audit Report

**Generated:** 2025-07-17  
**Scope:** 9 files, 19 `DropdownButtonFormField` instances  
**Severity:** Warning (`deprecated_member_use`) — non-breaking, but should be cleaned up  
**Root cause:** Flutter renamed `DropdownButtonFormField.value` to `initialValue` to align with the `FormField<T>` base class naming convention. In the source, `value` was literally passed as `initialValue` to the `FormField` super constructor — they are **identical in behavior**. The change is a pure rename with zero functional difference.

---

## Summary Table

| # | File | Line | Current `value:` expression | Risk |
|---|------|------|---------------------------|------|
| 1 | `master_kategori_senjata.dart` | 242 | `value: selectedTipe,` | LOW |
| 2 | `form_input_amunisi.dart` | 341 | `value: daftarPolda.isEmpty ? null : selectedPoldaId,` | LOW |
| 3 | `form_input_amunisi.dart` | 387 | `value: daftarKategori.isEmpty ? null : selectedKatId,` | LOW |
| 4 | `form_input_personel.dart` | 429 | `value: selectedPoldaId,` | LOW |
| 5 | `form_input_personel.dart` | 502 | `value: selectedPolresId,` | LOW |
| 6 | `form_input_personel.dart` | 536 | `value: selectedPangkatId,` | LOW |
| 7 | `form_input_personel.dart` | 560 | `value: selectedJabatanId,` | LOW |
| 8 | `form_input_polres.dart` | 221 | `value: selectedPoldaId,` | LOW |
| 9 | `form_input_sarpras.dart` | 398 | `value: _kategoriItems.contains(selectedKategori) ? selectedKategori : null,` | LOW |
| 10 | `form_input_sarpras.dart` | 474 | `value: _kondisiItems.contains(selectedKondisi) ? selectedKondisi : null,` | LOW |
| 11 | `form_input_senjata.dart` | 364 | `value: daftarPolda.isEmpty ? null : selectedPoldaId,` | LOW |
| 12 | `form_input_senjata.dart` | 399 | `value: daftarKategori.isEmpty ? null : selectedKatId,` | LOW |
| 13 | `form_input_user.dart` | 340 | `value: selectedRoleId,` | LOW |
| 14 | `form_input_user.dart` | 393 | `value: selectedRoleId,` | LOW |
| 15 | `form_input_user.dart` | 452 | `value: selectedPoldaId,` | LOW |
| 16 | `form_input_user.dart` | 488 | `value: selectedPoldaId,` | LOW |
| 17 | `form_inputan_inventaris.dart` | 121 | `value: kategori,` | LOW |
| 18 | `form_inputan_satwa.dart` | 482 | `value: _jenisItems.contains(selectedJenisSatwa) ? selectedJenisSatwa : null,` | LOW |
| 19 | `form_inputan_satwa.dart` | 542 | `value: _kualifikasiItems.contains(selectedKualifikasi) ? selectedKualifikasi : null,` | LOW |

---

## Per-File Detailed Analysis

### 1. `lib/pages/master_kategori_senjata.dart`

**Context:** `StatefulBuilder` inside `AlertDialog` — add/edit modal.

**Line 241–260:**
```dart
DropdownButtonFormField<String>(
  value: selectedTipe,                          // ← FIX: change `value:` to `initialValue:`
  isExpanded: true,
  decoration: _dialogInputDecoration(scheme).copyWith(
    hintText: "Pilih Tipe Laras",
  ),
  items: _tipeLarasOptions
      .map(
        (o) => DropdownMenuItem<String>(
          value: o,                              // ← SAFE: child DropdownMenuItem — DO NOT TOUCH
          child: Text(o),
        ),
      )
      .toList(),
  onChanged: (value) {
    setDialogState(() {
      selectedTipe = value;
    });
  },
),
```

**Plan:** Change `value: selectedTipe,` (line 242) to `initialValue: selectedTipe,`.

**Child `value:` to IGNORE:** Line 250 — `DropdownMenuItem<String>(value: o, ...)` — this is the item's selection value, NOT deprecated.

---

### 2. `lib/widget/form_input_amunisi.dart`

#### Instance A — Polda dropdown (line 339–352)

```dart
DropdownButtonFormField<int>(
  key: _poldaFieldKey,
  value: daftarPolda.isEmpty ? null : selectedPoldaId,   // ← FIX
  decoration: _inputDecoration(scheme).copyWith(hintText: "Pilih Polda"),
  items: daftarPolda.map((polda) {
    return DropdownMenuItem<int>(
      value: int.parse(polda["id"].toString()),           // ← SAFE
      child: Text(polda["nama_polda"]),
    );
  }).toList(),
  onChanged: null,      // disabled — preset from polda_login
),
```

**Plan:** Change `value: daftarPolda.isEmpty ? null : selectedPoldaId,` → `initialValue: daftarPolda.isEmpty ? null : selectedPoldaId,`.

**Child `value:` to IGNORE:** Line 346 — `DropdownMenuItem<int>(value: int.parse(...), ...)`.

#### Instance B — Kategori dropdown (line 386–402)

```dart
DropdownButtonFormField<int>(
  value: daftarKategori.isEmpty ? null : selectedKatId,   // ← FIX
  decoration: _inputDecoration(scheme).copyWith(hintText: "Pilih Kategori"),
  items: daftarKategori.map((cat) {
    return DropdownMenuItem<int>(
      value: int.parse(cat["kategori_id"].toString()),     // ← SAFE
      child: Text("${cat["tipe_laras"]} - ${cat["kaliber"]}"),
    );
  }).toList(),
  onChanged: (value) {
    setState(() {
      selectedKatId = value;
    });
  },
),
```

**Plan:** Change `value: daftarKategori.isEmpty ? null : selectedKatId,` → `initialValue: daftarKategori.isEmpty ? null : selectedKatId,`.

**Child `value:` to IGNORE:** Line 392 — `DropdownMenuItem<int>(value: int.parse(...), ...)`.

---

### 3. `lib/widget/form_input_personel.dart`

Four `DropdownButtonFormField<int>` instances — all follow the same pattern.

#### Instance A — Polda (line 428–471)
- **Line 429:** `value: selectedPoldaId,` → `initialValue: selectedPoldaId,`
- **Child `value:` to IGNORE:** Line 467 — `DropdownMenuItem<int>(value: int.tryParse(...) ?? 0, ...)`

#### Instance B — Polres (line 501–528)
- **Line 502:** `value: selectedPolresId,` → `initialValue: selectedPolresId,`
- **Child `value:` to IGNORE:**
  - Line 512 — `const DropdownMenuItem<int>(value: _polresNone, ...)` (sentinel)
  - Line 518 — `DropdownMenuItem<int>(value: int.tryParse(...) ?? -1, ...)`

#### Instance C — Pangkat (line 535–552)
- **Line 536:** `value: selectedPangkatId,` → `initialValue: selectedPangkatId,`
- **Child `value:` to IGNORE:** Line 542 — `DropdownMenuItem<int>(value: int.tryParse(...) ?? 0, ...)`

#### Instance D — Jabatan (line 559–576)
- **Line 560:** `value: selectedJabatanId,` → `initialValue: selectedJabatanId,`
- **Child `value:` to IGNORE:** Line 566 — `DropdownMenuItem<int>(value: int.tryParse(...) ?? 0, ...)`

---

### 4. `lib/widget/form_input_polres.dart`

**Line 220–235:**
```dart
DropdownButtonFormField<int>(
  value: selectedPoldaId,                                          // ← FIX
  decoration: _inputDecoration(scheme).copyWith(hintText: "Pilih Polda"),
  items: daftarPolda.map((polda) {
    return DropdownMenuItem<int>(
      value: int.tryParse(polda["id"].toString()) ?? 0,            // ← SAFE
      child: Text(polda["nama_polda"]),
    );
  }).toList(),
  onChanged: (value) {
    setState(() {
      selectedPoldaId = value;
    });
  },
),
```

**Plan:** Change `value: selectedPoldaId,` → `initialValue: selectedPoldaId,`.

**Child `value:` to IGNORE:** Line 226 — `DropdownMenuItem<int>(value: int.tryParse(...) ?? 0, ...)`.

---

### 5. `lib/widget/form_input_sarpras.dart`

#### Instance A — Kategori (line 397–418)
- **Line 398:** `value: _kategoriItems.contains(selectedKategori) ? selectedKategori : null,` → `initialValue: _kategoriItems.contains(selectedKategori) ? selectedKategori : null,`
- **Child `value:` to IGNORE:** Line 407 — `DropdownMenuItem<String>(value: item, ...)`

#### Instance B — Kondisi (line 473–494)
- **Line 474:** `value: _kondisiItems.contains(selectedKondisi) ? selectedKondisi : null,` → `initialValue: _kondisiItems.contains(selectedKondisi) ? selectedKondisi : null,`
- **Child `value:` to IGNORE:** Line 483 — `DropdownMenuItem<String>(value: item, ...)`

---

### 6. `lib/widget/form_input_senjata.dart`

#### Instance A — Polda (line 362–375)
- **Line 364:** `value: daftarPolda.isEmpty ? null : selectedPoldaId,` → `initialValue: daftarPolda.isEmpty ? null : selectedPoldaId,`
- **Child `value:` to IGNORE:** Line 369 — `DropdownMenuItem<int>(value: int.parse(...), ...)`

#### Instance B — Kategori (line 398–414)
- **Line 399:** `value: daftarKategori.isEmpty ? null : selectedKatId,` → `initialValue: daftarKategori.isEmpty ? null : selectedKatId,`
- **Child `value:` to IGNORE:** Line 404 — `DropdownMenuItem<int>(value: int.parse(...), ...)`

---

### 7. `lib/widget/form_input_user.dart`

#### Instance A — Role (desktop layout, line 339–366)
- **Line 340:** `value: selectedRoleId,` → `initialValue: selectedRoleId,`
- **Child `value:` to IGNORE:**
  - Line 344 — `DropdownMenuItem(value: "1", ...)`
  - Line 348 — `DropdownMenuItem(value: "2", ...)`
  - Line 352 — `DropdownMenuItem(value: "3", ...)`

#### Instance B — Role (mobile layout, line 392–419)
- **Line 393:** `value: selectedRoleId,` → `initialValue: selectedRoleId,`
- **Child `value:` to IGNORE:**
  - Line 397 — `DropdownMenuItem(value: "1", ...)`
  - Line 401 — `DropdownMenuItem(value: "2", ...)`
  - Line 405 — `DropdownMenuItem(value: "3", ...)`

#### Instance C — Polda (desktop layout, line 451–467)
- **Line 452:** `value: selectedPoldaId,` → `initialValue: selectedPoldaId,`
- **Child `value:` to IGNORE:** Line 457 — `DropdownMenuItem<String>(value: p["id"]?.toString(), ...)`

#### Instance D — Polda (mobile layout, line 487–503)
- **Line 488:** `value: selectedPoldaId,` → `initialValue: selectedPoldaId,`
- **Child `value:` to IGNORE:** Line 493 — `DropdownMenuItem<String>(value: p["id"]?.toString(), ...)`

---

### 8. `lib/widget/form_inputan_inventaris.dart`

**Line 120–133:**
```dart
DropdownButtonFormField<String>(
  value: kategori,                                          // ← FIX
  decoration: _inputDecoration(scheme),
  hint: Text("Pilih Pangkat"),
  items: const [
    DropdownMenuItem(value: "rantis", child: Text("Rantis")),          // ← SAFE
    DropdownMenuItem(value: "water_canon", child: Text("Water Canon")), // ← SAFE
  ],
  onChanged: (value) {
    setState(() {
      kategori = value!;
    });
  },
),
```

**Plan:** Change `value: kategori,` → `initialValue: kategori,`.

**Child `value:` to IGNORE:** Lines 125–126 — both `DropdownMenuItem(value: "rantis"/"water_canon", ...)`.

---

### 9. `lib/widget/form_inputan_satwa.dart`

#### Instance A — Jenis Satwa (line 481–502)
- **Line 482:** `value: _jenisItems.contains(selectedJenisSatwa) ? selectedJenisSatwa : null,` → `initialValue: _jenisItems.contains(selectedJenisSatwa) ? selectedJenisSatwa : null,`
- **Child `value:` to IGNORE:** Line 491 — `DropdownMenuItem<String>(value: item, ...)`

#### Instance B — Kualifikasi (line 541–562)
- **Line 542:** `value: _kualifikasiItems.contains(selectedKualifikasi) ? selectedKualifikasi : null,` → `initialValue: _kualifikasiItems.contains(selectedKualifikasi) ? selectedKualifikasi : null,`
- **Child `value:` to IGNORE:** Line 551 — `DropdownMenuItem<String>(value: item, ...)`

---

## Technical Justification: Why This Is a Pure Rename (Zero Behavioral Change)

In the Flutter SDK source, `DropdownButtonFormField` passes its `value` parameter directly to `FormField.initialValue`:

```dart
// Flutter SDK — dropdown_button_form_field.dart
class DropdownButtonFormField<T> extends FormField<T> {
  DropdownButtonFormField({
    // ...
    @Deprecated('Use initialValue instead.')
    T? value,
    // ...
  }) : super(
    initialValue: value,  // <-- literal pass-through
    // ...
  );
}
```

This means:
1. **No semantic difference** — `value:` and `initialValue:` behave identically.
2. **No state-management change** — the existing `onChanged` → `setState` pattern continues to work because the FormField's internal `_state.value` is updated by `didChange()` when the user selects, not by the widget rebuild.
3. **The guard expressions** (`daftarPolda.isEmpty ? null : selectedPoldaId`, `_kategoriItems.contains(...) ? ... : null`) remain correct — they prevent setting an `initialValue` not present in the `items` list, which avoids Flutter's assertion error.

---

## Execution Checklist (for the implementation phase)

### Files to modify (9 files, 19 edits):

- [ ] `lib/pages/master_kategori_senjata.dart` — 1 edit (line 242)
- [ ] `lib/widget/form_input_amunisi.dart` — 2 edits (lines 341, 387)
- [ ] `lib/widget/form_input_personel.dart` — 4 edits (lines 429, 502, 536, 560)
- [ ] `lib/widget/form_input_polres.dart` — 1 edit (line 221)
- [ ] `lib/widget/form_input_sarpras.dart` — 2 edits (lines 398, 474)
- [ ] `lib/widget/form_input_senjata.dart` — 2 edits (lines 364, 399)
- [ ] `lib/widget/form_input_user.dart` — 4 edits (lines 340, 393, 452, 488)
- [ ] `lib/widget/form_inputan_inventaris.dart` — 1 edit (line 121)
- [ ] `lib/widget/form_inputan_satwa.dart` — 2 edits (lines 482, 542)

### Verification after fix:

```bash
flutter analyze 2>&1 | grep -c "deprecated_member_use.*value"
# Expected: 0 (zero remaining warnings about deprecated value)
```

### NEVER touch these `value:` occurrences (child widgets):

- **`DropdownMenuItem.value:`** — ~30+ occurrences across all files. These define the selection value for each item. They are NOT deprecated and must NOT be changed.
- **`Switch.value:`** — in `form_input_user.dart` line 376, 427. NOT deprecated.
- **`Radio.value:`** — not found in these files, but would also be safe.
- **`TextEditingController` text assignments** — NOT related.

---

## Risk Assessment

| Risk | Level | Mitigation |
|------|-------|------------|
| Breaking dropdown selection | **NONE** | `value` was a pass-through to `initialValue` — identical behavior |
| Breaking `onChanged` callbacks | **NONE** | `onChanged` → `didChange` → internal state update is independent of constructor parameter name |
| Breaking `StatefulBuilder` dialogs | **NONE** | `master_kategori_senjata.dart` uses `setDialogState` — same mechanism, same result |
| Breaking disabled dropdowns (`onChanged: null`) | **NONE** | `form_input_amunisi.dart` and `form_input_senjata.dart` Polda dropdowns are disabled — `initialValue` handles this identically |
| Breaking `GlobalKey<FormFieldState>` pattern | **NONE** | `_poldaFieldKey.currentState?.didChange(...)` works the same way regardless of constructor parameter name |
| Accidental edit of `DropdownMenuItem.value` | **MEDIUM** | Search-and-replace tools could catch these. Each edit must be verified manually or with exact-string replacement (not regex) |
