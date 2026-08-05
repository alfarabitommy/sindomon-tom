# Flutter Senjata Polda Auto-Select Fix Plan

## 1. Audit Findings

### Root Cause: wrong SharedPreferences key

`lib/widget/form_input_senjata.dart` reads:
```dart
final poldaIdStr = pref.getString("polda_id");
```

But the login flow never writes that key. **`lib/widget/login_card.dart:153`**:
```dart
String poldaLogin = userData["polda_id"]?.toString() ?? "";  // line 146
await prefs.setString("polda_login", poldaLogin);            // line 153
```

The user's Polda ID is stored as a **String** under **`"polda_login"`**.

Result: `getString("polda_id")` → `null` → `poldaId` → `null` → `selectedPoldaId` stays `null` → `didChange` never fires → dropdown shows hint.

### User hypotheses — cross-check

| Hypothesis | Verdict |
|---|---|
| #1 `polda_id` saved as int → `getString` returns null | **False.** No `setInt` call anywhere in the codebase. Login always `setString("polda_login", ...)`. Even the raw backend value is stringified first (`?.toString()`). |
| #2 `value:` not assigned to `selectedPoldaId` | **False.** `value: selectedPoldaId` present; `didChange` mechanism in place. |
| #3 `int` vs `int.parse` type mismatch | **False.** `selectedPoldaId` is `int`, items are `DropdownMenuItem<int>` with `int.parse(...)` → same type. |

### Established pattern (sibling form already does this right)

`lib/widget/form_input_personel.dart:166-172`:
```dart
final polda = prefs.getString("polda_login");
final userPoldaInt = (polda != null && polda.isNotEmpty)
    ? int.tryParse(polda)
    : null;
```

---

## 2. Fix Plan

### 2.1 Fix the key in `getPolda()` (the only real fix)

**File**: `lib/widget/form_input_senjata.dart`, lines 40–42.

**Before:**
```dart
final poldaIdStr = pref.getString("polda_id");
final poldaId = (poldaIdStr != null && poldaIdStr.isNotEmpty)
    ? int.tryParse(poldaIdStr)
    : null;
```

**After:**
```dart
final poldaIdStr = pref.getString("polda_login");
final poldaId = (poldaIdStr != null && poldaIdStr.isNotEmpty)
    ? int.tryParse(poldaIdStr)
    : null;
```

That is the entire fix. The existing match-guard + `didChange` logic (lines 44–56) already handles display correctly once `poldaId` is non-null:

```dart
setState(() {
  daftarPolda = List<Map<String, dynamic>>.from(body['data']);
  if (poldaId != null &&
      daftarPolda.any((p) => int.tryParse(p["id"].toString()) == poldaId)) {
    selectedPoldaId = poldaId;
  }
});

if (selectedPoldaId != null) {
  _poldaFieldKey.currentState?.didChange(selectedPoldaId!);
}
```

### 2.2 Optional hardening (not strictly needed)

The user asked for a "bulletproof fetcher" with `getInt` fallback. Since `setString` is the only writer, `getInt` would always return null → dead code. If desired anyway (defense in depth against future writers), use:

```dart
int? _poldaIdFromPrefs(SharedPreferences pref) {
  final asInt = pref.getInt("polda_login");
  if (asInt != null) return asInt;
  final asStr = pref.getString("polda_login");
  return (asStr != null && asStr.isNotEmpty) ? int.tryParse(asStr) : null;
}
```

**Recommendation: skip it** — one-line key fix suffices; the value is guaranteed to be a non-empty string on login.

### 2.3 Verify (no changes expected)

- `value: selectedPoldaId` on the Polda dropdown — already correct.
- Item types `DropdownMenuItem<int>` / `int.parse(polda["id"].toString())` — already correct.
- `setState` timing — correct (guard + `didChange` inside `getPolda()` success branch).

---

## 3. Files Changed

| File | Line | Change |
|---|---|---|
| `lib/widget/form_input_senjata.dart` | 40 | `"polda_id"` → `"polda_login"` |

## 4. Validation Steps

1. Login as Operator Polda (role "2").
2. Open Add Senjata form → Polda dropdown shows the user's Polda (e.g., "Polda Jawa Barat"), locked.
3. Confirm dropdown is grayed/unresponsive but value visible.
4. Submit → `polda_id` sent; no 415.
5. `flutter analyze lib/widget/form_input_senjata.dart` clean.

## 5. Out of Scope Notes

- `form_input_senjata.dart` locks Polda unconditionally (`onChanged: null`). `form_input_personel.dart` gates the lock to role `"2"` only (`_poldaLocked = role == "2" && ...`). If Super Admin / Command Center should keep the dropdown editable in the Senjata form too, add the same role gate. Not part of this fix.
