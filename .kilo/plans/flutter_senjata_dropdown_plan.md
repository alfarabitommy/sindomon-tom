# Flutter Senjata Dropdown Key Fix Plan

## 1. Audit Findings

**File**: `lib/widget/form_input_senjata.dart`

### Crash: `FormatException: null` at line 245

```dart
// Current (post-previous-fix):
value: int.parse(cat["id"].toString()),
```

Backend Kategori API (`/api/v1/master/kategori-senjata`) returns objects with primary key `"kategori_id"` (int), not `"id"`. `cat["id"]` is `null` → `null.toString()` → `"null"` → `int.parse("null")` → `FormatException: null`.

### Mismatch: label missing kaliber at line 246

```dart
// Current:
child: Text(cat["tipe_laras"]),
```

Only shows e.g. `"Panjang"`. Should show `"Panjang - 5.56mm"`.

---

## 2. Fix Plan

Replace lines 245–246:

**Before:**
```dart
value: int.parse(cat["id"].toString()),
child: Text(cat["tipe_laras"]),
```

**After:**
```dart
value: int.parse(cat["kategori_id"].toString()),
child: Text("${cat["tipe_laras"]} - ${cat["kaliber"]}"),
```

---

## 3. Files Changed

| File | Lines | Change |
|---|---|---|
| `lib/widget/form_input_senjata.dart` | 245–246 | `"id"` → `"kategori_id"`, `Text(tipe_laras)` → `Text("$tipe_laras - $kaliber")` |

## 4. Validation

1. Open Add Senjata form → Kategori dropdown populates without crash
2. Dropdown items display as `"Panjang - 5.56mm"` format
3. Selected value is correct `kategori_id` int → submitted correctly via existing `"kategori_id": selectedKatId` payload
