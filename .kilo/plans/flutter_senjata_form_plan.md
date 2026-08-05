# Flutter Senjata Form — 404 + Type Mismatch Fix Plan

## 1. Audit Findings (contradictions with user report)

### Cross-check: user claims vs actual code in `lib/widget/form_input_senjata.dart`

| User claim | Actual code | Verdict |
|---|---|---|
| `selectedKategoriId` is `String` | Line 22: `int? selectedKatId;` | Already `int?` — no refactor needed |
| `DropdownButtonFormField<String>` | Line 239: `DropdownButtonFormField<int>` | Already `<int>` — no refactor needed |
| Edit-mode prefill via `widget.senjataData` in `initState` | `FormTambahSenjata` has **no constructor parameters** (line 10: `const FormTambahSenjata({super.key})`) — pure add-only form | **N/A** — no edit mode exists, no `senjataData` prop to cast |

**Conclusion**: The type system is already correct. The two real bugs are simpler.

---

### Bug 1: 404 on Kategori dropdown fetch

**File**: `lib/widget/form_input_senjata.dart`  
**Line 56**:  
```dart
Uri.parse('$apiBaseUrl/api/v1/kategori_senjata'),
```
→ wrong URL. Backend endpoint is `/api/v1/master/kategori-senjata`.

---

### Bug 2: `int.parse(…)` crash on both dropdown values (root cause of Red Screen)

**File**: `lib/widget/form_input_senjata.dart`

**Line 206** (Polda dropdown):  
```dart
value: int.parse(polda["id"]),
```
**Line 245** (Kategori dropdown):  
```dart
value: int.parse(cat["id"]),
```

Backend returns `"id": 13` as an `int`. `int.parse()` only accepts `String`. Dart throws:
`TypeError: type 'int' is not a subtype of type 'String'`

This crash hits the Polda dropdown first (line 206 matches debugger). If Kategori API were reachable, line 245 would crash identically.

---

### Bug 3 (bonus, not causing current crash): Submit endpoint + field names wrong

**Line 126**:  
```dart
Uri.parse("$apiBaseUrl/api/v1/senjata"),
```
→ should be `$apiBaseUrl/api/v1/logistik/senjata`.

**Lines 114–120** (submit body):  
```dart
final data = {
  "polda_id": selectedPoldaId,
  "no_seri": noSeri.text,      // → "nomor_seri"
  "kategori": selectedKatId,   // → "kategori_id"
  "tahun": tahunPengadaan.text, // → "tahun_pengadaan"
  "foto": base64Image,
};
```
Field names: `"no_seri"` → `"nomor_seri"`, `"kategori"` → `"kategori_id"`, `"tahun"` → `"tahun_pengadaan"`.

These crash on **submit**, not on form open. Included in plan since they're in the same module.

---

## 2. Fix Plan

### 2.1 Fix Kategori API URL

**File**: `lib/widget/form_input_senjata.dart`, line 56

**Before:**
```dart
Uri.parse('$apiBaseUrl/api/v1/kategori_senjata'),
```

**After:**
```dart
Uri.parse('$apiBaseUrl/api/v1/master/kategori-senjata'),
```

### 2.2 Fix `int.parse()` crash on both dropdowns

**File**: `lib/widget/form_input_senjata.dart`

**Line 206** (Polda dropdown) — before:
```dart
value: int.parse(polda["id"]),
```
— after:
```dart
value: int.parse(polda["id"].toString()),
```

**Line 245** (Kategori dropdown) — before:
```dart
value: int.parse(cat["id"]),
```
— after:
```dart
value: int.parse(cat["id"].toString()),
```

`.toString()` converts `int` → `"13"` → `int.parse("13")` → `13`. Safe for both `int` and `String` backend responses.

### 2.3 Fix submit endpoint

**File**: `lib/widget/form_input_senjata.dart`, line 126

**Before:**
```dart
Uri.parse("$apiBaseUrl/api/v1/senjata"),
```

**After:**
```dart
Uri.parse("$apiBaseUrl/api/v1/logistik/senjata"),
```

### 2.4 Fix submit field names

**File**: `lib/widget/form_input_senjata.dart`, lines 114–120

**Before:**
```dart
final data = {
  "polda_id": selectedPoldaId,
  "no_seri": noSeri.text,
  "kategori": selectedKatId,
  "tahun": tahunPengadaan.text,
  "foto": base64Image,
};
```

**After:**
```dart
final data = {
  "polda_id": selectedPoldaId,
  "nomor_seri": noSeri.text,
  "kategori_id": selectedKatId,
  "tahun_pengadaan": tahunPengadaan.text,
  "foto": base64Image,
};
```

---

## 3. Not Needed (user assumptions contradicted by code audit)

- `selectedKategoriId` is already `int?` — no refactor.
- `DropdownButtonFormField` is already `<int>` — no update.
- No `widget.senjataData` / edit-mode prefill exists — pure add-only form. Feature not yet built.

---

## 4. Files Changed

| File | Changes |
|---|---|
| `lib/widget/form_input_senjata.dart` | Kategori URL (line 56), `int.parse(…"id".toString())` ×2 (lines 206, 245), submit URL (line 126), submit field names (lines 115–119) |

---

## 5. Validation Steps

1. Open Add Senjata form → Kategori dropdown populates (no 404)
2. Polda dropdown shows values — no crash
3. Kategori dropdown shows values — no crash
4. Fill all fields, submit → 200 OK (no field-name mismatch)
