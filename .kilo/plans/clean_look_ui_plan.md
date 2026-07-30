# Clean Look UI Overhaul Plan

## Scope Summary

| Layer | Files | What Changes |
|-------|-------|--------------|
| Card wrapper | 7 `add_*.dart` pages | `elevation: 8` → `0`, add white fill + subtle border |
| Input decoration | 7 form widget files | Outline → Soft Filled, muted borders |
| Field labels | 7 form widget files | Default black → `Colors.grey.shade700` |
| Section headings | 7 form widget files | Default black → `Color(0xFF111827)` (soft near-black) |

**Background**: All Cards sit on `AppBackground` with `wp-putih-mabes.png`. White Card with border separates cleanly.

---

## Files Affected

### Group A — Card wrapper (7 files, identical Card widget)

1. `lib/pages/add_polda.dart`
2. `lib/pages/add_polres.dart`
3. `lib/pages/add_satwa.dart`
4. `lib/pages/add_user.dart`
5. `lib/pages/add_senjata.dart`
6. `lib/pages/add_inventaris_page.dart`
7. `lib/pages/add_personel_page.dart`

### Group B — Input decoration + labels (7 files, identical `_inputDecoration`)

1. `lib/widget/form_input_polda.dart`
2. `lib/widget/form_input_polres.dart`
3. `lib/widget/form_input_senjata.dart`
4. `lib/widget/form_input_personel.dart`
5. `lib/widget/form_input_user.dart`
6. `lib/widget/form_inputan_satwa.dart`
7. `lib/widget/form_inputan_inventaris.dart`

### Group C — form_input_user.dart mobile fallback (lines 90–92, 101–103)
Plain `OutlineInputBorder()` for Username/Password at `< 700` width.

---

## Step 1: Card Overhaul (7 `add_*.dart`)

**Before:**
```dart
Card(
  elevation: 8,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(15),
  ),
  child: const Padding(...),
),
```

**After:**
```dart
Card(
  elevation: 0,
  color: Colors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: BorderSide(color: Colors.grey.shade200, width: 1.5),
  ),
  child: const Padding(...),
),
```

Apply identically to all 7 files.

---

## Step 2: InputDecoration → Soft Filled (7 form files)

**Before:**
```dart
static const InputDecoration _inputDecoration = InputDecoration(
  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(6)),
    borderSide: BorderSide(color: Color(0xFFBFC1B7), width: 1.2),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(6)),
    borderSide: BorderSide(color: Color(0xFF1D4ED8), width: 2),
  ),
  isDense: true,
  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
);
```

**After:**
```dart
static const InputDecoration _inputDecoration = InputDecoration(
  filled: true,
  fillColor: Color(0xFFF9FAFB),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
    borderSide: BorderSide(color: Color(0xFFE5E7EB)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
    borderSide: BorderSide(color: Color(0xFFE5E7EB), width: 1),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
    borderSide: BorderSide(color: Color(0xFF1D4ED8), width: 1.5),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
    borderSide: BorderSide(color: Color(0xFFEF4444), width: 1),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
    borderSide: BorderSide(color: Color(0xFFEF4444), width: 1.5),
  ),
  isDense: true,
  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
);
```

Changes: `filled: true, fillColor: 0xFFF9FAFB`, enabledBorder `0xFFE5E7EB` (subtle), focusedBorder width 1.5, borderRadius 8, added error borders (previously missing).

---

## Step 3: form_input_user.dart Mobile Fallback

**Before (lines 90–92, 101–103):**
```dart
decoration: const InputDecoration(
  border: OutlineInputBorder(),
),
```

**After:**
```dart
decoration: _inputDecoration,
```

Reuse static const — no need for separate bare decoration.

---

## Step 4: Field Label Color (7 form files)

### Pattern A — Inline Text labels
Files: `form_input_polda.dart`, `form_input_polres.dart`, `form_inputan_satwa.dart`, `form_inputan_inventaris.dart`

**Before:**
```dart
const Text("Nama Polda *", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
```

**After:**
```dart
const Text("Nama Polda *",
    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF374151))),
```

### Pattern B — formField() helper
Files: `form_input_senjata.dart`, `form_input_personel.dart`, `form_input_user.dart`

**Before:**
```dart
Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
```

**After:**
```dart
Text(label,
    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF374151))),
```

`0xFF374151` = gray-700, premium muted but fully readable.

---

## Step 5: Section Heading Color (7 form files)

**Before:**
```dart
const Text(
  "TAMBAH POLDA BARU",
  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
),
```

**After:**
```dart
const Text(
  "TAMBAH POLDA BARU",
  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
),
```

`0xFF111827` = gray-900, soft near-black.

---

## Step 6: Page Title Color (7 `add_*.dart`)

**Before:**
```dart
const Text(
  "Pengaturan Polda",
  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
),
```

**After:**
```dart
const Text(
  "Pengaturan Polda",
  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
),
```

---

## Validation

1. `flutter analyze` — all values are const-compatible, no new errors expected
2. Visual: flat white Card, soft-filled inputs, muted labels across all 7 forms
3. Mobile layout in `form_input_user.dart` uses same `_inputDecoration`

---

## NOT Changed

- Layout structure (ConstrainedBox, padding, scroll)
- Submit button (`Color(0xffF6B300)`, `StadiumBorder`)
- "Kembali" button (black/white)
- Pilih Foto container
- `Colors.grey` footer text & `Colors.red` note text
