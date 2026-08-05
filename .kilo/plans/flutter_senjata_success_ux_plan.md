# Flutter Senjata Success UX Plan

> Report/plan path note: requested `plan/flutter_senjata_success_ux_plan.md` is blocked by project permission rules; file lives at `.kilo/plans/flutter_senjata_success_ux_plan.md`.

## 1. Audit Findings

### File: `lib/widget/form_input_senjata.dart` — `submitData()` (lines 121–149)

No success/error handling after the POST. Line 148:
```dart
debugPrint(response.body);
```
- No SnackBar, no `Navigator.pop`, no `mounted` check. After a 201, the form stays frozen with no feedback.

### File: `lib/pages/senjata.dart` — "Tambah Senjata" button (lines 180–188)

```dart
onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const AddSenjataPage(),
    ),
  );
},
```
- Fire-and-forget: result not awaited, `getSenjataApi()` never re-called after returning. Table stays stale.

---

## 2. Fix Plan

### 2.1 Form widget: success SnackBar + pop with `true`

**File**: `lib/widget/form_input_senjata.dart`, replace lines 147–149:

```dart
    debugPrint(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data senjata berhasil diregistrasi")),
      );
      Navigator.pop(context, true);
    }
```

Notes:
- `if (!context.mounted) return;` required — `submitData()` is async; the `await http.post` gap invalidates the context without the guard (`use_build_context_synchronously` lint).
- SnackBar is shown via the **form's** `ScaffoldMessenger`, then the screen pops — the SnackBar survives the pop because `ScaffoldMessenger` is app-scoped, so the message is visible on the table page.
- Non-2xx responses fall through: response body already printed; no error SnackBar requested (can add later).

### 2.2 Table page: await result + refresh

**File**: `lib/pages/senjata.dart`, replace lines 180–188:

```dart
ElevatedButton.icon(
  onPressed: () async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddSenjataPage(),
      ),
    );
    if (result == true) {
      getSenjataApi();
    }
  },
  icon: const Icon(Icons.add),
  label: const Text("Tambah Senjata"),
  ...
),
```

Notes:
- `Navigator.push<bool>` — typed so `result` is `bool?`; `AddSenjataPage` does not need a return-type change (push pops with the value from the form's `Navigator.pop(context, true)`).
- `onPressed: () async` — the closure becomes async; no `mounted` guard needed here because no context use occurs after `await` (only `getSenjataApi()`, a State method).
- `getSenjataApi()` refreshes the table, showing the newly created row.

---

## 3. Files Changed

| File | Lines | Change |
|---|---|---|
| `lib/widget/form_input_senjata.dart` | 147–149 | Success branch: mounted guard + SnackBar + `Navigator.pop(context, true)` |
| `lib/pages/senjata.dart` | 180–188 | Await push result; `if (result == true) getSenjataApi();` |

## 4. Validation Steps

1. Open Add Senjata, fill required fields, submit.
2. Backend returns 201 → SnackBar "Data senjata berhasil diregistrasi" visible, screen pops to table.
3. Table refreshes automatically; new row visible.
4. Backend non-2xx → no pop (user stays on form; body printed to console).
5. `flutter analyze` clean on both files.

## 5. Out of Scope

- Loading spinner / button disable during submit (prevent double-submit). Add when requested.
- Error-path SnackBar (e.g., "Gagal menyimpan data"). Add when requested.
- Same UX for other forms (Personel, Polres, Polda, User) — pattern exists in `form_input_personel.dart`; replicate per-module.
