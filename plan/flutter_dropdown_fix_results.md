# Flutter Dropdown Fix Results

**File modified:** `lib/widget/form_input_senjata.dart`  
**Date:** 2026-08-05  
**Verification:** `flutter analyze lib/widget/form_input_senjata.dart` → No issues found

---

## 1. Execution Summary

Two bugs from the audit (`plan/flutter_dropdown_audit.md`) were fixed:

### Bug #1 — JSON Path (CRITICAL)

`selectedKatId` was read from the nested `kategori` object (`data["kategori"]["kategori_id"]`), but the API returns `kategori_id` at the **top level** of the senjata record. The nested `kategori` object only contains `tipe_laras` and `kaliber`. The corrected code now reads the top-level `data["kategori_id"]`, so `selectedKatId` receives the real ID in edit mode and the dropdown can auto-select.

### Bug #2 — Race Condition (HIGH)

`initState()` sets `selectedPoldaId` / `selectedKatId` synchronously, but `getPolda()` / `getKategori()` populate the item lists asynchronously. On the first `build()`, the lists are still empty while `value` is non-null — Flutter throws an assertion because the value matches no `DropdownMenuItem`. Each dropdown's `value` is now guarded with `daftarX.isEmpty ? null : selectedX`, so the first frame renders with `value: null` (hint text), and once the async lists arrive, `setState` rebuilds with the matching value and the correct item auto-selects.

---

## 2. Code Diff Proof

### Fix #1 — `initState()` (line 195-196)

```dart
// BEFORE (lines 195-199):
selectedPoldaId = int.tryParse(data["polda_id"]?.toString() ?? "");
final kat = data["kategori"];
if (kat is Map<String, dynamic>) {
  selectedKatId = int.tryParse(kat["kategori_id"]?.toString() ?? "");
}

// AFTER:
selectedPoldaId = int.tryParse(data["polda_id"]?.toString() ?? "");
selectedKatId = int.tryParse(data["kategori_id"]?.toString() ?? "");
```

### Fix #2a — Polda Dropdown `value` (line 265)

```dart
// BEFORE:
value: selectedPoldaId,

// AFTER:
value: daftarPolda.isEmpty ? null : selectedPoldaId,
```

### Fix #2b — Kategori Dropdown `value` (line 300)

```dart
// BEFORE:
value: selectedKatId,

// AFTER:
value: daftarKategori.isEmpty ? null : selectedKatId,
```

---

## 3. Behavior After CORS Fix

| Scenario | Result |
|----------|--------|
| Edit mode, lists loaded | Both dropdowns auto-select the initial `polda_id` and `kategori_id` |
| First build, lists still empty | `value: null` — hint text shown, no assertion error |
| Lists arrive via `setState` | Values match items → dropdowns render selected values |
| Add mode (`initialData == null`) | Both IDs null, unaffected; Polda still auto-selects from `polda_login` preference via `getPolda()` |
