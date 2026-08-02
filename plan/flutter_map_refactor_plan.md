# Flutter Map Refactor Plan — Polda Model & Typed Pages

> **Status:** AWAITING APPROVAL — No Dart code will be modified until user gives APPROVE.

**Prerequisite (confirmed):** CodeIgniter backend `GET /api/v1/polda` now correctly returns `latitude` and `longitude` fields.
**Target:** Flutter frontend (`/home/tommy/dev/sindomon-tom`)
**Files touched:** `lib/models/polda_model.dart`, `lib/pages/polda.dart`
**Out of scope:** `lib/pages/polres.dart` (separate entity, follow-up), `lib/widget/form_input_polda.dart` (correct as-is), `lib/pages/dashboard.dart` (already refactored — reference pattern)

---

## Current State Summary

### Already done ✅

| File | Status |
|------|--------|
| `lib/models/polda_model.dart` | Exists — `Polda` class with `fromJson`, `hasValidCoordinates`, `latLng` getter. **One bug: `hasValidCoordinates` uses `\|\|` instead of `&&`.** |
| `lib/pages/dashboard.dart` | Fully refactored — `List<Polda>`, `Polda.fromJson()` parsing, `debugPrint` logging, `CircularProgressIndicator` loading state, empty state with icon+message, `where((p) => p.hasValidCoordinates)` filter, safe typed dialog. **No changes needed.** |

### Needs work ❌

| File | Issues |
|------|--------|
| `lib/pages/polda.dart` | Still uses `List<Map<String, dynamic>>`, unsafe `int.parse(e["id"])` for delete, `isLoading` declared but **never checked** in `build()`, no empty/error states |

---

## 1. Model Implementation — `lib/models/polda_model.dart`

### Current code (complete, with bug annotated)

```dart
import 'package:latlong2/latlong.dart';

class Polda {
  final int id;
  final String namaPolda;
  final double latitude;
  final double longitude;
  final String? createdAt;

  const Polda({
    required this.id,
    required this.namaPolda,
    required this.latitude,
    required this.longitude,
    this.createdAt,
  });

  factory Polda.fromJson(Map<String, dynamic> json) {
    return Polda(
      id: json["id"] is int
          ? json["id"]
          : int.tryParse(json["id"].toString()) ?? 0,
      namaPolda: json["nama_polda"]?.toString() ?? "Unknown",
      latitude: double.tryParse(
              (json["latitude"] ?? json["lat"]).toString()) ??
          0.0,
      longitude: double.tryParse(
              (json["longitude"] ?? json["lng"] ?? json["lon"]).toString()) ??
          0.0,
      createdAt: json["created_at"]?.toString(),
    );
  }

  bool get hasValidCoordinates => latitude != 0.0 || longitude != 0.0;  // ← BUG: OR should be AND

  LatLng get latLng => LatLng(latitude, longitude);
}
```

### Fix — change line 34

```dart
// Before (BUG):
bool get hasValidCoordinates => latitude != 0.0 || longitude != 0.0;

// After (FIXED):
bool get hasValidCoordinates => latitude != 0.0 && longitude != 0.0;
```

**Why:** With `||`, a Polda with `lat=0.0, lng=106.8` passes the filter and renders at the equator (0°N, off West Africa). Both coordinates must be non-zero for a meaningful map position. This fix affects `dashboard.dart:156` — marker filtering becomes correct without any other code change.

---

## 2. API Parsing Refactor — `lib/pages/polda.dart`

The CRUD table page mirrors the same `Polda.fromJson` pattern already working in `dashboard.dart`.

### 2.1 Add import

After line 1 (`import 'package:flutter/material.dart';`):

```dart
import '../models/polda_model.dart';
```

### 2.2 Change state variable (line 23)

```dart
// Before:
List<Map<String, dynamic>> polda = [];

// After:
List<Polda> polda = [];
String errorMessage = "";
```

### 2.3 Rewrite `getPoldaApi()` (lines 37-67)

Replace the entire method:

```dart
Future<void> getPoldaApi() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.get(
      Uri.parse("$apiBaseUrl/api/v1/polda"),
      headers: {"authorization": token.toString()},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final rawList = json["data"] as List;
      final parsed = rawList
          .map((e) => Polda.fromJson(e as Map<String, dynamic>))
          .toList();

      debugPrint("Polda fetched: ${parsed.length} total for CRUD table");

      setState(() {
        polda = parsed;
        errorMessage = "";
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = "Gagal memuat data (HTTP ${response.statusCode})";
        isLoading = false;
      });
    }
  } catch (e) {
    setState(() {
      errorMessage = "Terjadi kesalahan saat memuat data Polda";
      isLoading = false;
    });
    debugPrint(e.toString());
  }
}
```

**Key changes:**
- `json["data"] as List` + `.map((e) => Polda.fromJson(...))` — same pattern as `dashboard.dart:49-52`
- `debugPrint` logged count for debugging
- `errorMessage` set on HTTP errors and exceptions
- No more raw `List<Map<String, dynamic>>.from()`

### 2.4 Fix DataTable cells — typed properties (lines 244-327)

Replace the entire `rows:` block:

```dart
rows: polda
    .map((p) => DataRow(
          cells: [
            DataCell(Text(p.id.toString())),
            DataCell(Text(p.namaPolda)),
            DataCell(Text(p.latitude.toStringAsFixed(6))),
            DataCell(Text(p.longitude.toStringAsFixed(6))),
            DataCell(Text(p.createdAt ?? "-")),
            DataCell(
              ActionButtons(
                onEdit: () {},
                onDelete: () async {
                  final result = await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Hapus Polda"),
                      content: const Text(
                        "Apakah Anda yakin ingin menghapus data ini?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Batal"),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Hapus"),
                        ),
                      ],
                    ),
                  );
                  if (result == true) {
                    deletePolda(p.id);  // was: int.parse(e["id"]) — no more parsing needed
                  }
                },
              ),
            ),
          ],
        ))
    .toList(),
```

**Crash fixes:**
| Before | After | Fix |
|--------|-------|-----|
| `Text(e["id"])` | `Text(p.id.toString())` | No dynamic→String coercion crash |
| `int.parse(e["id"])` | `p.id` (already int) | No `FormatException` on null |
| `"${e["created_at"]}"` | `p.createdAt ?? "-"` | No literal `"null"` text |

---

## 3. UI & State Refactor — `lib/pages/polda.dart`

### 3.1 Add loading / error / empty states in `build()`

The current `build()` renders the DataTable immediately without checking `isLoading`. Replace the inner `child:` of `Expanded` (currently wrapping the `SingleChildScrollView` containing the DataTable, starting around line 193) with:

```dart
child: isLoading
    ? const Center(child: CircularProgressIndicator(color: Colors.amber))
    : errorMessage.isNotEmpty
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 64, color: Colors.redAccent),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 15, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: getPoldaApi,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Coba Lagi"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          )
        : polda.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.table_rows_outlined,
                        size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      "Tidak ada data Polda untuk ditampilkan",
                      style: TextStyle(
                          fontSize: 16, color: Colors.black54),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                // ... existing table content unchanged
              ),
```

**Note:** Use dark text/icon colors (`Colors.black54`, `Colors.black87`, `Colors.grey.shade400`) because the Polda page has a white background, unlike dashboard.dart which uses white text on a dark map.

### 3.2 Styling consistency note

The polda CRUD page sits on `AppBackground(imagePath: 'assets/images/wp-putih-mabes.png')` with white card containers, so use dark-themed empty/error states — opposite of dashboard.dart's white-on-dark.

---

## Verification Checklist

| # | What | How | Expected |
|---|------|-----|----------|
| 1 | Static analysis | `flutter analyze` | Zero errors |
| 2 | Model fix | Check `polda_model.dart:34` | `&&` not `\|\|` |
| 3 | Dashboard — role 3 | Login as Command Center | Loading → map with red markers OR empty state |
| 4 | Dashboard — tap marker | Click red pin | Dialog: name + `Lat: X.XXXX` + `Lng: X.XXXX` |
| 5 | Dashboard — no (0,0) markers | Scroll map to Gulf of Guinea | No markers there |
| 6 | Console — dashboard | `debugPrint` output | `Polda fetched: X total, Y with valid coordinates` |
| 7 | Polda CRUD page — load | Navigate to Polda | Spinner → table with typed data |
| 8 | Polda CRUD — delete | Click delete → confirm | Row removed, table refreshes |
| 9 | Polda CRUD — empty | (Dev: point API at `{"data":[]}`) | "Tidak ada data Polda" message |
| 10 | Polda CRUD — error | Stop backend / disable network | Error icon + "Terjadi kesalahan..." + "Coba Lagi" button |
| 11 | Non-role-3 dashboard | Login as Super Admin / Operator | "Segera Hadir" placeholder (unchanged) |

---

## Commit Plan

```bash
# Commit 1: Model bug fix
git add lib/models/polda_model.dart
git commit -m "fix(model): change hasValidCoordinates from OR to AND

Both coordinates must be non-zero for a valid map marker.
OR logic was rendering markers at wrong positions when
only one coordinate was valid (e.g. lat=0.0 → equatorial Atlantic).
"

# Commit 2: Polda CRUD page refactor
git add lib/pages/polda.dart
git commit -m "refactor(polda): use typed Polda model with loading/empty/error states

- Import Polda model, replace List<Map<String,dynamic>> with List<Polda>
- Map API JSON through Polda.fromJson() with debugPrint logging
- Replace unsafe bracket access (e['id'], e['nama_polda']) with typed properties
- Replace int.parse(e['id']) with p.id (already int) in delete handler
- Add CircularProgressIndicator loading state
- Add empty state (icon + message)
- Add error state (icon + message + retry button)
"
```

---

**⚠️ Do NOT execute any Dart code changes. Await APPROVE command from user.**
