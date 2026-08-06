# Flutter Amunisi PUT — Kategori Dropdown Auto-Select Fix Results

## 1. Execution Summary

**File modified:** `lib/widget/form_input_amunisi.dart` — `initState()` (edit-mode branch).

**Root cause (confirmed by audit `plan/flutter_amunisi_put_audit.md`):** the backend serializes the `kategori` relationship as an **eager-loaded nested object** (evidence: `lib/pages/amunisi.dart:387` passes `e["kategori"]` to `_formatKaliber()`, which checks `kategori is Map<String, dynamic>` and reads `kategori["tipe_laras"]` / `kategori["kaliber"]`). The old code read `data["kategori_id"]` from the top level → always `null` → `selectedKatId` stayed `null` → the Kategori `DropdownButtonFormField` fell back to its hint text.

**Logic fix applied:** `selectedKatId` is now extracted from the nested `data["kategori"]["kategori_id"]` path. A defensive fallback to the flat top-level `data["kategori_id"]` is included, so the form auto-selects correctly regardless of whether the backend returns the relationship nested or flattened.

**Race-condition guard verified (no change needed):** the Kategori dropdown already guards its `value`:

```dart
value: daftarKategori.isEmpty ? null : selectedKatId,   // line 380
```

This is correct: `selectedKatId` is assigned synchronously inside `initState()` (before `getKategori()`'s async HTTP response resolves), and the `daftarKategori.isEmpty` guard prevents Flutter's assertion error when a non-null `value` is supplied while `items` is still empty. Once `getKategori()` populates `daftarKategori`, the dropdown renders with the matching `DropdownMenuItem<int>` pre-selected.

**Verification note:** `flutter analyze` could not be executed — no Flutter/Dart SDK is installed in this environment. The change is a small, syntactically self-contained expression replacement verified by file inspection (lines 226–232).

## 2. Code Diff Proof

**Before (`initState()`, edit-mode branch):**

```dart
selectedPoldaId = int.tryParse(data["polda_id"]?.toString() ?? "");
selectedKatId = int.tryParse(data["kategori_id"]?.toString() ?? "");   // ← BROKEN: key missing at top level → null
```

**After:**

```dart
selectedPoldaId = int.tryParse(data["polda_id"]?.toString() ?? "");
// Backend returns `kategori` as an eager-loaded nested object
// (e.g. {"kategori_id": 5, "tipe_laras": "Pistol", "kaliber": "9mm"}).
// Fall back to a flat top-level `kategori_id` for robustness.
final rawKategori = data["kategori"];
selectedKatId = (rawKategori is Map<String, dynamic>)
    ? int.tryParse(rawKategori["kategori_id"]?.toString() ?? "")
    : int.tryParse(data["kategori_id"]?.toString() ?? "");
```

**Dropdown binding (unchanged, confirmed correct at line 380):**

```dart
DropdownButtonFormField<int>(
  value: daftarKategori.isEmpty ? null : selectedKatId,
  ...
)
```

### Behavior after fix

| Scenario | `data["kategori"]` | Result |
|----------|-------------------|--------|
| Backend nested relationship (actual, per list-page evidence) | `{"kategori_id": 5, "tipe_laras": "Pistol", "kaliber": "9mm"}` | `selectedKatId = 5` → dropdown pre-selects "Pistol - 9mm" |
| Flat top-level int (defensive fallback) | absent | `selectedKatId = int.tryParse(data["kategori_id"])` → still works |
| Malformed/missing | absent + no top-level key | `selectedKatId = null` → hint shown (no crash) |

## 3. Files Changed

| File | Line(s) | Change |
|------|---------|--------|
| `lib/widget/form_input_amunisi.dart` | 226–232 | Nested-path extraction for `selectedKatId` with flat fallback |

## 4. Outstanding (related, not in scope)

- `lib/widget/form_input_senjata.dart:196` has the **identical** flat-path bug (`data["kategori_id"]`) while `lib/pages/senjata.dart:350` renders the nested `e["kategori"]`. Apply the same fix there to keep both modules consistent.
