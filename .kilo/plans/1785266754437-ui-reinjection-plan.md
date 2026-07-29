# UI Re-injection Plan: Search, Action Buttons, Table Headers

## Overview
Three changes to each of 8 data pages. Each change is independent and can be applied file-by-file. No modification to `AppFooter`, `AppPagination`, or the `Column` that wraps them.

---

## Change 1 — Replace legacy search `TextField` with `AppSearchField`

**Pattern (all 8 files identical in structure):**

Delete this entire block:
```dart
                      /// SEARCH
                      TextField(
                        decoration: InputDecoration(
                          hintText: "Cari XXXXX...",
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
```

Replace with:
```dart
                      /// SEARCH
                      AppSearchField(hintText: "Cari XXXXX..."),
```

Per-file hintText values:

| File | hintText |
|------|----------|
| `personel.dart` | `"Cari Personel..."` |
| `polres.dart` | `"Cari Polres..."` |
| `polda.dart` | `"Cari Polda..."` |
| `inventaris.dart` | `"Cari Inventaris..."` |
| `satwa.dart` | `"Cari Satwa..."` |
| `report.dart` | `"Cari Report..."` |
| `senjata.dart` | `"Cari Senjata..."` |
| `user_page.dart` | `"Cari Pengguna..."` |

**Anchor note:** Some files have `const SizedBox(height: 20),` immediately before the `/// SEARCH` comment; others do not. Use the `/// SEARCH` + `TextField(` + `decoration: InputDecoration(` + `hintText: "Cari` block as the unique anchor. Always include the leading whitespace and preceding lines back to the `/// SEARCH` comment.

---

## Change 2 — Replace legacy action `Row` of `IconButton`s with `ActionButtons`

### Type A: Files with full delete confirmation dialog

**Files:** `personel.dart`, `polres.dart`, `polda.dart`, `senjata.dart`

**personel.dart** — replace the DataCell line 565-635 with:
```dart
DataCell(ActionButtons(onEdit: () {}, onDelete: () async {
  final result = await showDialog(context: context, builder: (_) => AlertDialog(
    title: const Text("Hapus Personel"),
    content: const Text("Apakah Anda yakin ingin menghapus data ini?"),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
      ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Hapus")),
    ],
  ));
  if (result == true) { deletePersonel(int.parse(e["id"])); }
})),
```

**polres.dart** — same pattern, replace `"Hapus Personel"` → `"Hapus Polres"`, `deletePersonel` → `deletePolres`

**polda.dart** — same pattern, `"Hapus Personel"` → `"Hapus Polda"`, `deletePersonel` → `deletePolda`

**senjata.dart** — same pattern, `"Hapus Personel"` → `"Hapus Senjata"`, `deletePersonel` → `deleteSenjata`

**Anchor:** The entire `DataCell(Row(...))` block from `DataCell(` through the matching closing `),` before the next `],` — this is unique in each file.

### Type B: Files with empty action callbacks

**Files:** `inventaris.dart`, `satwa.dart`, `report.dart`, `user_page.dart`

Replace:
```dart
DataCell(Row(children: [IconButton(icon: const Icon(Icons.edit), onPressed: () {},), IconButton(icon: const Icon(Icons.delete, color: Colors.red,), onPressed: () {},),],),),
```

With:
```dart
DataCell(ActionButtons(onEdit: () {}, onDelete: () {})),
```

*(Formatting varies slightly — each file's exact whitespace may differ. Match by anchoring on `Row(children: [` + `Icons.edit` + `Icons.delete` within a `DataCell`.)*

---

## Change 3 — Restore table header typography

### 3a: headingTextStyle

In all 8 files, find:
```dart
headingTextStyle: const TextStyle(
  fontWeight: FontWeight.bold,
),
```

Replace with:
```dart
headingTextStyle: const TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w700,
),
```

### 3b: DataColumn labels → UPPERCASE

| File | Current Labels | New Labels |
|------|---------------|------------|
| `personel.dart` | `"Nama Lengkap"`, `"Polres ID"`, `"Status Aktif"` | `"NAMA LENGKAP"`, `"POLRES ID"`, `"STATUS AKTIF"` |
| `polres.dart` | `"Polda ID"`, `"Nama Polres"`, `"Created At"` | `"POLDA ID"`, `"NAMA POLRES"`, `"CREATED AT"` |
| `polda.dart` | `"Nama Polda"`, `"Latitude"`, `"Longitude"`, `"Created At"` | `"NAMA POLDA"`, `"LATITUDE"`, `"LONGITUDE"`, `"CREATED AT"` |
| `inventaris.dart` | `"Foto"`, `"nama"`, `"kategori"`, `"kondisi"` | `"FOTO"`, `"NAMA"`, `"KATEGORI"`, `"KONDISI"` |
| `satwa.dart` | `"Foto Satwa"`, `"No Registrasi"`, `"Jenis"`, `"Nama"`, `"Kualifikasi"`, `"Jadwal Vaksin"`, `"Status Vaksin"` | `"FOTO SATWA"`, `"NO REGISTRASI"`, `"JENIS"`, `"NAMA"`, `"KUALIFIKASI"`, `"JADWAL VAKSIN"`, `"STATUS VAKSIN"` |
| `report.dart` | `"Foto"`, `"nama"`, `"kategori"`, `"kondisi"` | `"FOTO"`, `"NAMA"`, `"KATEGORI"`, `"KONDISI"` |
| `senjata.dart` | `"Foto Unit"`, `"No Seri"`, `"Kategori"`, `"Tahun"` | `"FOTO UNIT"`, `"NO SERI"`, `"KATEGORI"`, `"TAHUN"` |
| `user_page.dart` | `"Nama"`, `"Role"`, `"Polda"`, `"Status"` | `"NAMA"`, `"ROLE"`, `"POLDA"`, `"STATUS"` |

*(Labels already uppercase and unchanged: `"NRP"`, `"AKSI"`, `"ID"`)*

---

## Change 4 — Add missing imports

Add to all 8 files, near existing `../widget/app_footer.dart` and `../widget/app_pagination.dart` imports:

```dart
import '../widget/app_search_field.dart';
import '../widget/action_buttons.dart';
```

| File | Insert after line |
|------|-------------------|
| `personel.dart` | line 19 (`import '../widget/app_pagination.dart';`) |
| `polres.dart` | line 20 (`import '../widget/app_pagination.dart';`) |
| `polda.dart` | line 20 (`import '../widget/app_pagination.dart';`) |
| `inventaris.dart` | line 16 (`import '../widget/app_pagination.dart';`) |
| `satwa.dart` | line 16 (`import '../widget/app_pagination.dart';`) |
| `report.dart` | line 15 (`import '../widget/app_pagination.dart';`) |
| `senjata.dart` | line 20 (`import '../widget/app_pagination.dart';`) |
| `user_page.dart` | line 20 (`import '../widget/app_pagination.dart';`) |

---

## Strict Protection Boundary

**DO NOT modify:**
- `const AppFooter()` — leave exactly as-is
- `const AppPagination()` — leave exactly as-is
- The `Column(children: [` that wraps `Expanded(...DataTable...)` + `const AppPagination()`
- The `const SizedBox(height: 20),` before `const AppFooter()`
- Any other layout structure (SafeArea, Row sidebar, Card, etc.)

---

## Implementation Order
Per file, in sequence:
1. Add imports
2. Replace search TextField
3. Replace action buttons DataCell
4. Fix headingTextStyle
5. Uppercase DataColumn labels

Process files in this order (no inter-file dependencies):
1. `personel.dart`
2. `polres.dart`
3. `polda.dart`
4. `inventaris.dart`
5. `satwa.dart`
6. `report.dart`
7. `senjata.dart`
8. `user_page.dart`

## Verification
```bash
flutter analyze lib/pages/
```
Confirm zero errors. Spot-check by opening any page — search field uses grey `AppSearchField` style, action buttons are grey ghost icons, column headers are bold uppercase 12px.
