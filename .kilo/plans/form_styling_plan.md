# SINDOMON Form Styling Modernization Plan

## Overview

Refactor 7 form widgets + 7 parent add-pages to match SINDOMON design system specs: constrained card width, amber CTA buttons, modern outlined text fields, semi-bold labels.

---

## Affected Files

### Parent pages (7 files)
| File | Change |
|------|--------|
| `lib/pages/add_polda.dart:107` | `maxWidth: 1000` → `maxWidth: 600` |
| `lib/pages/add_polres.dart:107` | `maxWidth: 1000` → `maxWidth: 600` |
| `lib/pages/add_satwa.dart:107` | `maxWidth: 1000` → `maxWidth: 600` |
| `lib/pages/add_user.dart:107` | `maxWidth: 1000` → `maxWidth: 600` |
| `lib/pages/add_senjata.dart:107` | `maxWidth: 1000` → `maxWidth: 600` |
| `lib/pages/add_inventaris_page.dart:107` | `maxWidth: 1000` → `maxWidth: 600` |
| `lib/pages/add_personel_page.dart:107` | `maxWidth: 1000` → `maxWidth: 600` |

### Form widgets (7 files)
| File | Changes |
|------|---------|
| `lib/widget/form_input_personel.dart` | Button color, InputDecoration, label typography |
| `lib/widget/form_input_polda.dart` | Button color, InputDecoration, label typography |
| `lib/widget/form_input_polres.dart` | Button color, InputDecoration, label typography |
| `lib/widget/form_input_user.dart` | Button color, InputDecoration, label typography |
| `lib/widget/form_input_senjata.dart` | MISSING SUBMIT BUTTON — add one; InputDecoration; labels |
| `lib/widget/form_inputan_satwa.dart` | Button color, InputDecoration, label typography |
| `lib/widget/form_inputan_inventaris.dart` | Button color, InputDecoration, label typography |

---

## Step-by-Step Refactor

### Step 1: Constrain Card Max Width

**Location**: 7 `add_*.dart` files, line 107.

**Before:**
```dart
constraints: const BoxConstraints(maxWidth: 1000),
```
**After:**
```dart
constraints: const BoxConstraints(maxWidth: 600),
```

The `Center` widget wrapper already handles horizontal centering.

---

### Step 2: SINDOMON Primary CTA Button

**Target**: Every `ElevatedButton` used as submit/save action.

**Token values:**
- Background: `const Color(0xffF6B300)`
- Foreground/text: `const Color(0xFF23251D)`
- Shape: `StadiumBorder()`

**Before (current pattern):**
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
  ),
  ...
)
```

**After:**
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xffF6B300),
    foregroundColor: const Color(0xFF23251D),
    shape: const StadiumBorder(),
  ),
  ...
)
```

**Files/line# affected:**
- `form_input_personel.dart:331-334`
- `form_input_polda.dart:133-136`
- `form_input_polres.dart:165-169`
- `form_input_user.dart:288-291`
- `form_inputan_satwa.dart:212-215`
- `form_inputan_inventaris.dart:176-179`
- `form_input_senjata.dart` — **no submit button exists**. Add after photo section, before `]` closing Column. Wire to `submitData()`.

---

### Step 3: Modern InputDecoration

**Target**: Every `TextFormField` and `DropdownButtonFormField` across all 7 form widgets.

**New spec:**
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

**Counts by file:**
| File | TextFormField | DropdownButtonFormField |
|------|---------------|-------------------------|
| `form_input_personel.dart` | 2 | 4 |
| `form_input_polda.dart` | 3 | 0 |
| `form_input_polres.dart` | 1 | 1 |
| `form_input_user.dart` | 2 | 2 |
| `form_input_senjata.dart` | 2 | 2 |
| `form_inputan_satwa.dart` | 2 | 2 |
| `form_inputan_inventaris.dart` | 2 | 1 |
| **Total** | **14** | **12** |

**Special cases:**
- `form_input_user.dart:107,156` — Role dropdowns have NO `decoration` at all.
- `form_input_user.dart:209,250` — Polda dropdowns have NO `decoration` at all.
- `form_inputan_inventaris.dart:93` — Kategori dropdown has NO `decoration` at all.

---

### Step 4: Label Typography

**Before:**
```dart
Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
```
**After:**
```dart
Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
```

**Location method per file:**
| File | Pattern |
|------|---------|
| `form_input_personel.dart` | `formField()` helper at line 152 → change there |
| `form_input_polda.dart` | 3 inline labels (lines 93-94, 106, 117-118) |
| `form_input_polres.dart` | 2 inline labels (lines 119-120, 148-149) |
| `form_input_user.dart` | `formField()` helper at line 21 → change there |
| `form_input_senjata.dart` | `formField()` helper at line 143 → change there |
| `form_inputan_satwa.dart` | 4 inline labels (lines 69-70, 87-88, 119-120, 138-139) |
| `form_inputan_inventaris.dart` | 4 inline labels (lines 68-69, 86-87, 110-111, 129-130) |

---

### Step 5: Missing Submit Button (form_input_senjata.dart)

Insert after photo section (after line 297 `],`), before Column's closing bracket:
```dart
const SizedBox(height: 30),
SizedBox(
  width: double.infinity,
  height: 50,
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xffF6B300),
      foregroundColor: const Color(0xFF23251D),
      shape: const StadiumBorder(),
    ),
    onPressed: submitData,
    child: const Text("Simpan Data", style: TextStyle(fontSize: 18)),
  ),
),
const SizedBox(height: 20),
const Text(
  "Lengkapi semua data bertanda *",
  style: TextStyle(color: Colors.grey),
),
```

---

## Execution Order

1. **Change `maxWidth: 1000` → `maxWidth: 600`** in all 7 `add_*.dart` files (identical one-line change).
2. **Add `_inputDecoration` static const** to each of the 7 form widget classes.
3. **Replace** all `decoration: const InputDecoration(border: OutlineInputBorder())` → `decoration: _inputDecoration`.
4. **Add missing `decoration: _inputDecoration`** to dropdowns in `form_input_user.dart` (4 instances) and `form_inputan_inventaris.dart` (1 instance).
5. **Change label styles**: `FontWeight.bold` → `FontWeight.w600, fontSize: 14`.
6. **Replace submit button colors/shapes** in all 7 forms.
7. **Add missing submit button** to `form_input_senjata.dart`.

---

## Non-Changes / Edge Cases

- **"Kembali" buttons in add_*.dart**: Page navigation, not form CTAs. Keep `Colors.black`.
- **Photo picker containers**: Keep current `borderRadius: 8`, `Colors.grey` border.
- **`textfield.dart` (AppTextField)**: Unused by forms. Not touched.
- **No ThemeData extraction** in this phase. Colors repeated inline per file. Extract to `lib/theme/app_theme.dart` when the project adds more pages.
- **No tests exist** — manual visual QA required.
