# Flutter Senjata Submit — 415 Fix + Polda Dropdown Lock Plan

## 1. Audit Findings

**File**: `lib/widget/form_input_senjata.dart`

### 415 Unsupported Media Type

**Line 127**: `headers: {"authorization": token.toString()}` — missing `"Content-Type": "application/json"`.

The backend requires it (`"Content-Type harus application/json"`).

**Note**: line 128 already has `body: jsonEncode(data)` — `jsonEncode` is present. User's claim that it might be missing is incorrect per code audit. Only the header is needed.

### Polda Dropdown UX: not locked, not pre-filled

- **Line 21**: `int? selectedPoldaId;` — null on init, only set via `onChanged`.
- **Line 210**: `onChanged: (value) { setState(() { selectedPoldaId = value; }); }` — fully interactive.
- No code reads user's `polda_id` from `SharedPreferences`.

User's Polda ID is stored in SharedPreferences during login under key `"polda_id"` (as String). The backend auto-injects it from JWT on POST — frontend only needs to display + lock.

---

## 2. Fix Plan

### 2.1 Pre-fill Polda from SharedPreferences

Read `polda_id` from SharedPreferences and assign to `selectedPoldaId` so the dropdown shows the user's Polda pre-selected.

**File**: `lib/widget/form_input_senjata.dart`, inside `getPolda()` method (lines 26–48).

Add after line 40 (`daftarPolda = ...`), before the `}` of the success branch:

```dart
final poldaIdStr = pref.getString("polda_id");
if (poldaIdStr != null && poldaIdStr.isNotEmpty) {
  selectedPoldaId = int.tryParse(poldaIdStr);
}
```

Full updated `getPolda()` success branch:

```dart
if (responses.statusCode == 200) {
  final Map<String, dynamic> body = jsonDecode(responses.body);

  final poldaIdStr = pref.getString("polda_id");
  if (poldaIdStr != null && poldaIdStr.isNotEmpty) {
    selectedPoldaId = int.tryParse(poldaIdStr);
  }

  setState(() {
    daftarPolda = List<Map<String, dynamic>>.from(body['data']);
  });
}
```

Why inside `getPolda()` and not `initState()`: `selectedPoldaId` is set before `daftarPolda` is populated. That's fine — Flutter dropdown won't crash; it shows the hint until data arrives, then auto-matches. If `polda_id` doesn't match any item in the list, it shows the hint (graceful degradation).

### 2.2 Lock Polda Dropdown

**File**: `lib/widget/form_input_senjata.dart`, line 210.

**Before:**
```dart
onChanged: (value) {
  setState(() {
    selectedPoldaId = value;
  });
},
```

**After:**
```dart
onChanged: null,
```

Flutter natively disables a `DropdownButtonFormField` when `onChanged` is `null` — grays out and ignores taps. No `IgnorePointer` or `AbsorbPointer` needed.

### 2.3 Fix 415: add Content-Type header

**File**: `lib/widget/form_input_senjata.dart`, line 127.

**Before:**
```dart
headers: {"authorization": token.toString()},
```

**After:**
```dart
headers: {
  "Authorization": token.toString(),
  "Content-Type": "application/json",
},
```

Also capitalizes `"authorization"` → `"Authorization"` for consistency with the rest of the codebase.

`body: jsonEncode(data)` on line 128 already correct — no change needed.

---

## 3. Files Changed

| File | Lines | Change |
|---|---|---|
| `lib/widget/form_input_senjata.dart` | 39–41 | Read `polda_id` from SharedPreferences, set `selectedPoldaId` in `getPolda()` |
| `lib/widget/form_input_senjata.dart` | 210 | `onChanged` → `null` |
| `lib/widget/form_input_senjata.dart` | 127–129 | Add `"Content-Type": "application/json"`, capitalize `Authorization` |

## 4. Validation Steps

1. Open Add Senjata form → Polda dropdown shows user's Polda pre-selected, visually locked (grayed out, unresponsive to taps)
2. Fill other fields, submit → debugger shows 200 OK (no 415)
3. Verify `selectedPoldaId` is submitted in payload even when dropdown is locked
4. `flutter analyze` clean on `form_input_senjata.dart`
