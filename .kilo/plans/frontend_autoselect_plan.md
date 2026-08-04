# Frontend Autoselect Plan — Pangkat & Jabatan Pre-fill

## Audit Findings

**File:** `lib/widget/form_input_personel.dart`

### Location of edit-mode pre-fill logic

`initState()` at lines 307–327 already includes Pangkat & Jabatan pre-fill:

```dart
// line 319
selectedPangkatId = _toInt(data["pangkat_id"]);
// line 320
selectedJabatanId = _toInt(data["jabatan_id"]);
```

### How the existing pattern works (Polda/Polres reference)

1. `initState` synchronously sets `selectedPoldaId` from `personilData` (line 317).
2. `getPolda()` fires async — when it completes, `setState` rebuilds the widget tree.
3. The Polda `DropdownButtonFormField` has `value: selectedPoldaId`. On first build, `daftarPolda` is `[]`, so no item matches. After rebuild, the populated list matches and the dropdown resolves.
4. Pangkat/Jabatan follow the **identical** pattern: `initState` sets the IDs (lines 319–320), `getPangkat()`/`getJabatan()` fire async, `setState` populates `daftarPangkat`/`daftarJabatan`, dropdowns resolve.

### Root cause analysis

**The Flutter code is not the issue.** Lines 319–320 already exist and are correct.

The dropdowns appear "not pre-filled" because the backend response for `personilData` likely does **not** include `pangkat_id` and `jabatan_id`. When these keys are absent, `_toInt(data["pangkat_id"])` returns `null`, and the dropdown shows the hint text "Pilih Pangkat" / "Pilih Jabatan".

## Fix Plan

### No Dart changes needed

The frontend code is ready. The fix is **backend-side**: ensure the API endpoint that serves `personilData` (used to populate `widget.personilData`) includes `pangkat_id` and `jabatan_id` as integer fields in the response body.

### Verification checklist

- [ ] Backend API returns `pangkat_id: <int>` in `personilData` response.
- [ ] Backend API returns `jabatan_id: <int>` in `personilData` response.
- [ ] Key names match exactly: `pangkat_id`, `jabatan_id`.
- [ ] Values parse to valid `int` — matching the IDs in `/api/v1/pangkat` and `/api/v1/jabatan` dropdown data.

### If a defensive fallback is desired (optional)

If the backend keys might be inconsistent (e.g., `id_pangkat` instead of `pangkat_id`), add a fallback in `initState`:

```dart
selectedPangkatId = _toInt(data["pangkat_id"]) ?? _toInt(data["id_pangkat"]);
selectedJabatanId = _toInt(data["jabatan_id"]) ?? _toInt(data["id_jabatan"]);
```

**Recommendation:** align backend keys to `pangkat_id` / `jabatan_id`. No frontend changes needed.

## Summary

| Component | Status |
|-----------|--------|
| `initState` pre-fill for Pangkat | Already present (line 319) |
| `initState` pre-fill for Jabatan | Already present (line 320) |
| `_toInt` safe parsing | Already present (line 45) |
| Async dropdown resolution | Works via `getPangkat()`/`getJabatan()` → `setState` |
| **Missing piece** | Backend must send `pangkat_id` and `jabatan_id` in `personilData` |
