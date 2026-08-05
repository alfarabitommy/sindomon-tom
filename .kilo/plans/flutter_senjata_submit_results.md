# Flutter Senjata Submit — Implementation Results

> Report path note: requested `plan/flutter_senjata_submit_results.md` is blocked by project permission rules; file lives at `.kilo/plans/flutter_senjata_submit_results.md` (same content).

## 1. Execution Summary

**File modified**: `lib/widget/form_input_senjata.dart`

| Change | Status |
|--------|--------|
| `getPolda()`: read `"polda_id"` from SharedPreferences, parse to int, pre-select dropdown | Done |
| Polda `DropdownButtonFormField`: `onChanged: null` → locked/grayed, still shows selected value | Done |
| Submit `http.post`: added `"Content-Type": "application/json"` header (fixes 415) + capitalized `"Authorization"` | Done |
| `body: jsonEncode(data)` — was already present, no change needed | Confirmed |

### Deviation from approved plan (required for correctness)

The approved plan assigned `selectedPoldaId` then called `setState`, expecting the dropdown `value:` param to display the selection. **This does not work on Flutter 3.29.3**: `DropdownButtonFormField` maps `value` → `FormField.initialValue`, which is only read once at state creation (first build, before the async `getPolda()` returns). `FormFieldState._value` is never resynced from `initialValue` on rebuild (`didUpdateWidget` in `form.dart:699` only handles `forceErrorText`).

Fix: added `GlobalKey<FormFieldState<int>> _poldaFieldKey` and call `_poldaFieldKey.currentState?.didChange(selectedPoldaId!)` after the dropdown is built. `didChange` updates `state.value`, which drives the inner `DropdownButton` (dropdown.dart:1773 uses `value: state.value`).

Additional guard: the dropdown asserts (dropdown.dart:1734) that `value` matches exactly one item. `didChange` is only fired when the stored `polda_id` actually matches an item in the fetched `daftarPolda` — stale/missing Polda IDs degrade gracefully (hint shown) instead of Red Screen.

## 2. Code Diff Proof

### `getPolda()` — pre-fill + safe match

```dart
final poldaIdStr = pref.getString("polda_id");
final poldaId = (poldaIdStr != null && poldaIdStr.isNotEmpty)
    ? int.tryParse(poldaIdStr)
    : null;

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

### Locked Polda Dropdown

```dart
DropdownButtonFormField<int>(
  key: _poldaFieldKey,          // NEW — enables programmatic selection
  value: selectedPoldaId,
  decoration: _inputDecoration.copyWith(hintText: "Pilih Polda"),
  items: daftarPolda.map((polda) {
    return DropdownMenuItem<int>(
      value: int.parse(polda["id"].toString()),
      child: Text(polda["nama_polda"]),
    );
  }).toList(),
  onChanged: null,               // was interactive setState block → now locked
),
```

`onChanged: null` natively disables the field in Flutter: grays out, ignores taps, shows the selected value via `state.value`.

### Updated HTTP headers (fixes 415)

```dart
final response = await http.post(
  Uri.parse("$apiBaseUrl/api/v1/logistik/senjata"),
  headers: {
    "Authorization": token.toString(),          // was lowercase "authorization"
    "Content-Type": "application/json",         // NEW — required by backend
  },
  body: jsonEncode(data),                       // already present
);
```

## 3. Verification Status

- `flutter analyze lib/widget/form_input_senjata.dart` → **No issues found!**
- Diff verified: `+28/-14` cumulative this session; submit block + dropdown + getPolda changes confirmed.
- No runtime test executed (no device/emulator in this environment).

## 4. Note

`getPolda()` still fetches from `$apiBaseUrl/api/v1/polda` — correct endpoint per audit, not in fix scope. Payload `polda_id: selectedPoldaId` is preserved for the POST; backend auto-injects from JWT anyway per Endpoint 4.1 blueprint.
