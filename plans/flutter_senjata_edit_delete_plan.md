# Flutter Senjata Edit & Delete UX Plan

## 1. Audit Findings

### `lib/widget/form_input_senjata.dart`
- **Constructor**: `const FormTambahSenjata({super.key})` — no parameters, add-mode only.
- **submitData()**: Always `http.post` — no edit/PUT path.
- **initState()**: Calls `getPolda()` + `getKategori()` — no pre-fill logic.
- **getPolda()**: Always sets `selectedPoldaId` from SharedPreferences; not overrideable.
- **getKategori()**: Only populates `daftarKategori` list; never sets `selectedKatId`.
- **Polda dropdown**: `onChanged: null` (disabled) — locked by design.
- **Title/Button**: Hardcoded "TAMBAH DATA SENJATA" / "Simpan Data".
- **SnackBar**: Default style, no explicit `backgroundColor`.

### `lib/pages/senjata.dart`
- **deleteSenjata()** (line 123–146): On 200, calls `debugPrint` then `getSenjataApi()` — no SnackBar feedback.
- **Edit button** (line 351): `onEdit: () {}` — empty/no-op callback.
- **Delete button** (line 352–403): Already wired with confirmation dialog → `deleteSenjata(id)`.
- **"Tambah Senjata" button** (line 191–201): Already awaits `Navigator.push<bool>` result and refreshes on `true` — good reference pattern.
- **Row data `e` keys**: `senjata_id`, `nomor_seri`, `tahun_pengadaan`, `polda_id`, `kategori` (nested Map with `kategori_id`, `tipe_laras`, `kaliber`), `foto_fisik`.

### `lib/pages/add_senjata.dart`
- **AddSenjataPage**: `const` constructor, no parameters.
- **FormTambahSenjata()** instantiated with `const` at line 118 — no way to pass `initialData`.

### Existing pattern to follow: `lib/widget/form_input_personel.dart`
- Constructor accepts `personilId` + `personilData`; sets `isEditMode` flag in `initState`.
- `initState` pre-fills text controllers synchronously, sets dropdown IDs synchronously.
- `submitPersonel()` branches on `isEditMode`: PUT vs POST.
- Success: `SnackBar(backgroundColor: Colors.green)` + `Navigator.pop(context, true)`.

---

## 2. Fix Plan

### File: `lib/widget/form_input_senjata.dart`

#### A. Constructor — Add `initialData` parameter

Replace:
```dart
class FormTambahSenjata extends StatefulWidget {
  const FormTambahSenjata({super.key});
```
With:
```dart
class FormTambahSenjata extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const FormTambahSenjata({super.key, this.initialData});
```

#### B. State — Add `_isEdit` flag

Add field after `List<Map<String, dynamic>> daftarKategori = [];`:
```dart
  late bool _isEdit;
```

#### C. `initState` — Pre-fill controllers + set `_isEdit`

Replace:
```dart
  @override
  void initState() {
    super.initState();
    getPolda();
    getKategori();
  }
```
With:
```dart
  @override
  void initState() {
    super.initState();
    _isEdit = widget.initialData != null;

    if (_isEdit) {
      final data = widget.initialData!;
      noSeri.text = data["nomor_seri"]?.toString() ?? "";
      tahunPengadaan.text = data["tahun_pengadaan"]?.toString() ?? "";
      selectedPoldaId = int.tryParse(data["polda_id"]?.toString() ?? "");
      final kat = data["kategori"];
      if (kat is Map<String, dynamic>) {
        selectedKatId = int.tryParse(kat["kategori_id"]?.toString() ?? "");
      }
    }

    getPolda();
    getKategori();
  }
```

#### D. `getPolda()` — Skip pref-polda override in edit mode

Inside the existing `setState` block of `getPolda()`, guard the SharedPreferences-polda assignment:

Replace:
```dart
        setState(() {
          daftarPolda = List<Map<String, dynamic>>.from(body['data']);
          if (poldaId != null &&
              daftarPolda.any((p) => int.tryParse(p["id"].toString()) == poldaId)) {
            selectedPoldaId = poldaId;
          }
        });
```
With:
```dart
        setState(() {
          daftarPolda = List<Map<String, dynamic>>.from(body['data']);
          if (!_isEdit &&
              poldaId != null &&
              daftarPolda.any((p) => int.tryParse(p["id"].toString()) == poldaId)) {
            selectedPoldaId = poldaId;
          }
        });
```

#### E. `submitData()` — PUT vs POST + green SnackBar

Replace the entire `submitData()` method (lines 121–157) with:
```dart
  Future<void> submitData() async {
    String? base64Image;

    if (_imageBytes != null) {
      base64Image = base64Encode(_imageBytes!);
    }

    final data = {
      "polda_id": selectedPoldaId,
      "nomor_seri": noSeri.text,
      "kategori_id": selectedKatId,
      "tahun_pengadaan": tahunPengadaan.text,
      "status_kelayakan": "Baik",
      "foto_fisik": base64Image,
    };

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final http.Response response;

    if (_isEdit) {
      final editData = Map<String, dynamic>.from(data);
      editData["senjata_id"] = widget.initialData!["senjata_id"];
      response = await http.put(
        Uri.parse("$apiBaseUrl/api/v1/logistik/senjata"),
        headers: {
          "Authorization": token.toString(),
          "Content-Type": "application/json",
        },
        body: jsonEncode(editData),
      );
    } else {
      response = await http.post(
        Uri.parse("$apiBaseUrl/api/v1/logistik/senjata"),
        headers: {
          "Authorization": token.toString(),
          "Content-Type": "application/json",
        },
        body: jsonEncode(data),
      );
    }

    debugPrint(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? "Data senjata berhasil diperbarui"
                : "Data senjata berhasil diregistrasi",
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  }
```

#### F. `build()` — Dynamic title + button text

Replace the title (line 211):
```dart
  "TAMBAH DATA SENJATA",
```
With ternary:
```dart
  _isEdit ? "EDIT DATA SENJATA" : "TAMBAH DATA SENJATA",
```

Replace the button label (line 349):
```dart
  "Simpan Data",
```
With:
```dart
  _isEdit ? "Update Data" : "Simpan Data",
```

---

### File: `lib/pages/add_senjata.dart`

#### G. Constructor — Accept `initialData`

Replace:
```dart
class AddSenjataPage extends StatefulWidget {
  const AddSenjataPage({super.key});
```
With:
```dart
class AddSenjataPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const AddSenjataPage({super.key, this.initialData});
```

#### H. Pass `initialData` to form

Replace (line 118):
```dart
  child: const FormTambahSenjata(),
```
With:
```dart
  child: FormTambahSenjata(initialData: widget.initialData),
```

#### I. Dynamic breadcrumb (optional polish)

Replace (line 58):
```dart
  breadcrumb: "Dashboard / Tambah Senjata",
```
With:
```dart
  breadcrumb: widget.initialData != null
      ? "Dashboard / Edit Senjata"
      : "Dashboard / Tambah Senjata",
```

---

### File: `lib/pages/senjata.dart`

#### J. `deleteSenjata()` — Red SnackBar on success

Replace lines 137–139:
```dart
      if (response.statusCode == 200) {
        debugPrint(response.body);
        getSenjataApi();
```
With:
```dart
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Data senjata berhasil dihapus"),
            backgroundColor: Colors.red,
          ),
        );
        getSenjataApi();
```

#### K. Edit button — Wire `onEdit` callback

Replace line 351:
```dart
  onEdit: () {},
```
With:
```dart
  onEdit: () async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddSenjataPage(initialData: e),
      ),
    );
    if (result == true) {
      getSenjataApi();
    }
  },
```

---

## 3. Validation Checklist

1. **Add mode unchanged**: Push `AddSenjataPage()` (no args) → POST, "TAMBAH", "Simpan Data" → green SnackBar "diregistrasi" → pop(true) → table refresh.
2. **Edit mode**: Push `AddSenjataPage(initialData: e)` → "EDIT", "Update Data", PUT with `senjata_id` → green SnackBar "diperbarui" → pop(true) → table refresh.
3. **Edit pre-fill**: No Seri, Tahun, Polda, Kategori all pre-populated from row data.
4. **Delete**: Confirm → DELETE API → red SnackBar "dihapus" → table refresh.
5. **Polda dropdown**: Disabled in both modes; add=pref, edit=row data.
6. **Kategori dropdown**: Pre-filled from nested `kategori.kategori_id`.
