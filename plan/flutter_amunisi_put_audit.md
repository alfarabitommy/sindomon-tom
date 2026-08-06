# Flutter Amunisi PUT Audit — Kategori Dropdown Auto-Select Bug

## 1. Auto-Select Logic

**File:** `lib/widget/form_input_amunisi.dart`, `initState()` at lines 217–233.

The exact snippet that extracts the kategori ID from the edit payload:

```dart
@override
void initState() {
  super.initState();
  _isEdit = widget.initialData != null;

  if (_isEdit) {
    final data = widget.initialData!;
    kodeBatch.text = data["kode_batch"]?.toString() ?? "";
    jumlahButir.text = data["jumlah_butir"]?.toString() ?? "";
    selectedPoldaId = int.tryParse(data["polda_id"]?.toString() ?? "");
    selectedKatId = int.tryParse(data["kategori_id"]?.toString() ?? "");  // ← LINE 226
    tanggalMasuk = _parseDate(data["tanggal_masuk"]);
    tanggalKedaluwarsa = _parseDate(data["tanggal_kedaluwarsa"]);
  }

  getPolda();
  getKategori();
}
```

The dropdown widget binds the extracted value at line 374:

```dart
DropdownButtonFormField<int>(
  value: daftarKategori.isEmpty ? null : selectedKatId,  // ← selectedKatId = null → shows hint
  decoration: _inputDecoration.copyWith(hintText: "Pilih Kategori"),
  items: daftarKategori.map((cat) {
    return DropdownMenuItem<int>(
      value: int.parse(cat["kategori_id"].toString()),
      child: Text("${cat["tipe_laras"]} - ${cat["kaliber"]}"),
    );
  }).toList(),
  onChanged: (value) {
    setState(() { selectedKatId = value; });
  },
),
```

---

## 2. Bug Identification

### CONFIRMED: Wrong JSON path — identical to the Senjata module bug

**The API returns `kategori` as a nested object, NOT as a flat `kategori_id` field.**

#### Proof from the list page (`lib/pages/amunisi.dart`, lines 386–388):

```dart
DataCell(
  Text(
    _formatKaliber(
      e["kategori"],       // ← NESTED OBJECT, not e["kategori_id"]
    ),
  ),
),
```

The helper `_formatKaliber` (line 95–103) confirms the shape:

```dart
String _formatKaliber(dynamic kategori) {
  if (kategori is Map<String, dynamic>) {
    final laras = kategori["tipe_laras"] ?? "";
    final kaliber = kategori["kaliber"] ?? "";
    if (laras.isNotEmpty && kaliber.isNotEmpty) return "$laras - $kaliber";
    ...
  }
  return "-";
}
```

#### API response shape (inferred from the list-page rendering):

```json
{
  "batch_id": 1,
  "kode_batch": "PROD-001/2026",
  "polda_id": 2,
  "kategori": {
    "kategori_id": 5,
    "tipe_laras": "Pistol",
    "kaliber": "9mm"
  },
  "jumlah_butir": 100,
  "tanggal_masuk": "2025-06-01",
  "tanggal_kedaluwarsa": "2026-06-01"
}
```

#### The mismatch in `initState()`:

| What | Code | Result |
|------|------|--------|
| What the form reads | `data["kategori_id"]` | **`null`** — no such top-level key exists |
| What the API actually returns | `data["kategori"]["kategori_id"]` | `5` — nested inside the `kategori` relationship object |

Because `data["kategori_id"]` is always `null`, `int.tryParse(null ?? "")` → `int.tryParse("")` → `null`. So `selectedKatId` stays `null`.

When the dropdown renders, `value: daftarKategori.isEmpty ? null : selectedKatId` → `value: null`. Since `null` does not match any `DropdownMenuItem<int>` value, Flutter falls back to showing the `hintText` ("Pilih Kategori") instead of the actual selected item.

#### Comparison with Senjata module:

| Module | List page reads | Form initState reads | Bug present? |
|--------|----------------|---------------------|--------------|
| Senjata | `e["kategori"]` (nested, `senjata.dart:350`) | `data["kategori_id"]` (flat, `form_input_senjata.dart:196`) | **YES** |
| Amunisi | `e["kategori"]` (nested, `amunisi.dart:387`) | `data["kategori_id"]` (flat, `form_input_amunisi.dart:226`) | **YES** |

Both modules share the identical root cause: the backend Laravel API eager-loads the `kategori` relationship as a nested JSON object, but the Flutter form's `initState()` tries to extract `kategori_id` from the top level of the JSON payload.

### Root Cause

The Laravel backend returns `kategori` as an eager-loaded Eloquent relationship (a nested object). The `kategori_id` foreign key column exists in the database but is **not included** in the JSON serialization — only the relationship object is included. The Flutter form should drill into `data["kategori"]["kategori_id"]` instead of reading `data["kategori_id"]`.

---

## 3. Fix Required

In `lib/widget/form_input_amunisi.dart`, line 226, change:

```dart
// BEFORE (broken):
selectedKatId = int.tryParse(data["kategori_id"]?.toString() ?? "");

// AFTER (fixed):
final kat = data["kategori"];
selectedKatId = (kat is Map<String, dynamic>)
    ? int.tryParse(kat["kategori_id"]?.toString() ?? "")
    : null;
```

The identical fix is also needed in `lib/widget/form_input_senjata.dart` line 196 for the Senjata module.
