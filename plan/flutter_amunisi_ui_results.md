# Flutter Amunisi UI — Execution Results

**Date:** 2026-08-05  
**Developer:** Senior Flutter Developer (CODE/EXECUTE MODE)  
**Module:** Stok Amunisi (Table View + Add Form)

---

## 1. Execution Summary

| File | Action | Status |
|---|---|---|
| `lib/pages/amunisi.dart` | Created (Table view, search, pagination, H-90 alert) | ✅ DONE |
| `lib/pages/add_amunisi.dart` | Created (Add/Edit page wrapper) | ✅ DONE |
| `lib/widget/form_input_amunisi.dart` | Created (POST/PUT form w/ native DatePickers) | ✅ DONE |
| `lib/config/menu_config.dart` | Updated (placeholder → `AmunisiPage`) | ✅ DONE |

### Additional changes
- `pubspec.yaml`: added `font_awesome_flutter: ^10.9.1` (required for `fa-triangle-exclamation`)
- `flutter analyze`: **0 issues** across all 4 files

### Menu link (`menu_config.dart`)
```dart
Widget _as() => const AmunisiPage();   // was: _ph("Stok Amunisi", "ammo_stock")
```

### API contract used (confirmed against `plan/sindomondb010826.sql`)
- `GET/POST /api/v1/logistik/amunisi`
- Body: `polda_id`, `kode_batch`, `kategori_id`, `jumlah_butir`, `tanggal_masuk`, `tanggal_kedaluwarsa` (dates as `yyyy-MM-dd`)
- PK: `batch_id`

---

## 2. H-90 UI Logic

Rendered in the **Status** column of the DataTable (`lib/pages/amunisi.dart`).

```dart
bool _isH90(Map<String, dynamic> e) {
  return e["is_h90_alert"] == true || e["is_h90_alert"] == 1;
}

Widget _buildStatusBadge(bool isH90) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: isH90 ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isH90) ...[
          const FaIcon(
            FontAwesomeIcons.triangleExclamation,
            size: 12,
            color: Color(0xFFB91C1C),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          isH90 ? "H-90 ALERT" : "AMAN",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isH90 ? const Color(0xFFB91C1C) : const Color(0xFF166534),
          ),
        ),
      ],
    ),
  );
}
```

### Badge behavior
| Condition | Background | Text/Icon | Label |
|---|---|---|---|
| `is_h90_alert == true` | Pastel Red `#FEE2E2` | Dark Red `#B91C1C` + `fa-triangle-exclamation` | **H-90 ALERT** |
| otherwise | Pastel Green `#DCFCE7` | Dark Green `#166534` | **AMAN** |

---

## 3. Date Validation (Form)

`tanggal_kedaluwarsa` is enforced **twice**:

1. **Picker-level** (`form_input_amunisi.dart`): the kedaluwarsa picker's `firstDate` is `tanggalMasuk + 1 day` — selecting a date ≤ tanggal_masuk is physically impossible.
2. **Submit-level**: a `!tanggalKedaluwarsa.isAfter(tanggalMasuk)` guard blocks POST with a snackbar. If the user changes `tanggal_masuk` to a date ≥ an already-picked `tanggal_kedaluwarsa`, the latter resets to null.

```dart
firstDate: tanggalMasuk != null
    ? tanggalMasuk!.add(const Duration(days: 1))
    : DateTime.now(),
```
