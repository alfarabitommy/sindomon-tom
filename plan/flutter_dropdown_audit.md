# Flutter Dropdown Auto-Select Audit

**File audited:** `lib/widget/form_input_senjata.dart`  
**API inspected:** `application/controllers/Logistik.php` → `senjata_get()` (line 169-234)  
**Date:** 2026-08-05

---

## 1. Auto-Select Logic Check

### `initState()` (lines 187-204)

```dart
if (_isEdit) {
  final data = widget.initialData!;
  noSeri.text       = data["nomor_seri"]?.toString() ?? "";
  tahunPengadaan.text = data["tahun_pengadaan"]?.toString() ?? "";
  selectedPoldaId   = int.tryParse(data["polda_id"]?.toString() ?? "");  // ✅ correct path
  final kat         = data["kategori"];                                   // ⚠️ nested object, NOT top-level
  if (kat is Map<String, dynamic>) {
    selectedKatId   = int.tryParse(kat["kategori_id"]?.toString() ?? ""); // ❌ WRONG PATH — see below
  }
}
```

| Variable | Source Path | Exists in API? | Result |
|----------|------------|----------------|--------|
| `selectedPoldaId` | `data["polda_id"]` | ✅ Top-level key | Works — parsed as `int` |
| `selectedKatId` | `data["kategori"]["kategori_id"]` | ❌ Nested object has no `kategori_id` | **Always `null`** |

### API Response Shape (`GET /api/v1/logistik/senjata`)

```json
{
  "senjata_id": 1,
  "nomor_seri": "ABC123",
  "kategori_id": 5,          // ← EXISTS at TOP LEVEL
  "polda_id": 2,
  "tahun_pengadaan": 2024,
  "kategori": {               // ← NESTED object: ONLY tipe_laras + kaliber
    "tipe_laras": "Pendek",
    "kaliber": "9mm"
  }
}
```

The nested `kategori` object (PHP lines 218-221) is hand-built with **only** `tipe_laras` and `kaliber`. It does NOT include `kategori_id`.

**Root cause (BUG #1):** `selectedKatId` reads `data["kategori"]["kategori_id"]` but should read `data["kategori_id"]`. The value is always `null`, so the Kategori dropdown never auto-selects.

### `getPolda()` override logic (lines 48-55)

```dart
setState(() {
  daftarPolda = List<Map<String, dynamic>>.from(body['data']);
  if (!_isEdit &&    // ← guards against overwriting in edit mode ✅
      poldaId != null &&
      daftarPolda.any((p) => int.tryParse(p["id"].toString()) == poldaId)) {
    selectedPoldaId = poldaId;
  }
});
```

Correctly skips override in edit mode (`_isEdit` is `true`). The value set in `initState()` is preserved through the async reload.

### `getKategori()` (lines 68-90)

Only populates `daftarKategori`. Never sets `selectedKatId`. Since BUG #1 causes `selectedKatId` to already be `null`, this has no observable effect — but even if BUG #1 were fixed, there is no re-validation that the selected ID actually exists in the loaded list.

---

## 2. Type Matching Check

| Component | Type | Value Source | Match? |
|-----------|------|-------------|--------|
| `selectedPoldaId` | `int?` | `int.tryParse(...)` | ✅ |
| Polda Dropdown | `DropdownButtonFormField<int>` | — | ✅ |
| Polda items `value` | `int.parse(polda["id"].toString())` | API `id` field | ✅ |
| `selectedKatId` | `int?` | `int.tryParse(...)` (but always null per BUG #1) | ✅ |
| Kategori Dropdown | `DropdownButtonFormField<int>` | — | ✅ |
| Kategori items `value` | `int.parse(cat["kategori_id"].toString())` | API `kategori_id` field | ✅ |

**No type mismatch.** All IDs flow through `int.parse` / `int.tryParse` and the dropdowns are typed `DropdownButtonFormField<int>`.

---

## 3. Race Condition (BUG #2 — HIGH, masked by BUG #1)

**Sequence:**

1. `initState()` sets `selectedPoldaId` to a non-null `int` (e.g. `2`)
2. `initState()` sets `selectedKatId` to `null` (due to BUG #1)
3. `getPolda()` and `getKategori()` are called asynchronously
4. Widget **builds immediately** with `daftarPolda = []` and `daftarKategori = []`
5. Polda dropdown: `value: 2` but no items exist → **assertion error in debug mode**
6. Kategori dropdown: `value: null` with empty items → shows hint text (OK, by accident)

**Impact once BUG #1 is fixed:** BOTH dropdowns will hit the assertion — `selectedKatId` will be non-null but `daftarKategori` will be empty on first build.

**In release mode:** Assertions are stripped. Dropdown silently shows hint text on first frame, then when `setState` fires from HTTP responses, the values match items and the dropdown renders correctly. So release builds may appear to work.

---

## 4. Summary of Findings

| # | Severity | Description | Symptom |
|---|----------|-------------|---------|
| 1 | **CRITICAL** | `selectedKatId` reads `kategori_id` from nested `kategori` object instead of top-level `data` | Kategori dropdown never auto-selects in edit mode |
| 2 | **HIGH** | Race condition: dropdown `value` is non-null while item list is empty on first build | Assertion error in debug mode; may work in release |
| 3 | LOW | `getKategori()` never re-validates `selectedKatId` against loaded items | If ID doesn't exist in master data, silent mismatch |

### Proposed Fix (for reference, DO NOT apply in audit mode)

```dart
// BUG #1 fix — line 196-198 of form_input_senjata.dart
// BEFORE:
final kat = data["kategori"];
if (kat is Map<String, dynamic>) {
  selectedKatId = int.tryParse(kat["kategori_id"]?.toString() ?? "");
}

// AFTER:
selectedKatId = int.tryParse(data["kategori_id"]?.toString() ?? "");
```

```dart
// BUG #2 fix — guard dropdown value when list is empty
// Polda dropdown (line 266-278):
value: daftarPolda.isEmpty ? null : selectedPoldaId,

// Kategori dropdown (line 302-312):
value: daftarKategori.isEmpty ? null : selectedKatId,
```
