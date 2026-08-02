# Map Marker Debug Plan — Command Center Dashboard

> **Status: INVESTIGATION COMPLETE — AWAITING APPROVAL**
> Tidak ada kode Dart yang akan dimodifikasi sampai user memberikan APPROVE.

---

## 1. FRONTEND DATA FLOW AUDIT

### 1A. Data Model: Polda

**Tidak ada model class.** Data Polda disimpan sebagai `List<Map<String, dynamic>>` di dua tempat:

| File | Line | Variable |
|------|------|----------|
| `lib/pages/dashboard.dart` | 19 | `List<Map<String, dynamic>> provinsi = [];` |
| `lib/pages/polda.dart` | 23 | `List<Map<String, dynamic>> polda = [];` |

Tidak ada `models/` directory, tidak ada freezed/json_serializable, tidak ada type safety sama sekali. Semua field JSON diakses langsung sebagai `dynamic` via bracket notation (`p["latitude"]`).

### 1B. API Call — `getPoldaApi()` (`dashboard.dart:30-65`)

```
Role Gate (line 31):
  _roleId != "3" → set isLoading=false, return (provinsi tetap [])

HTTP GET (line 41-44):
  URL:  https://sindomon.cml-indonesia.com/api/v1/polda
  Header: authorization: <jwt_token>  (lowercase, tanpa "Bearer" prefix)

Response Parsing (line 47-50):
  jsonDecode(body) → json["data"] → List<Map<String, dynamic>>.from(...)
  NO per-field extraction, NO validation at parse time
```

**Critical detail:** `isLoading` (line 20) diset di 5 tempat berbeda tetapi **tidak pernah dibaca di `build()`**. Tidak ada loading spinner, tidak ada empty state. Jika `provinsi` kosong (API gagal atau role bukan "3"), user melihat peta kosong tanpa indikasi apapun. `print("ini json ${json}")` di line 48 sudah **di-comment-out** — tidak ada debug logging.

### 1C. Marker Generation (`dashboard.dart:112-193`)

```dart
// Line 112-194 — MarkerLayer inside FlutterMap
MarkerLayer(
  markers: provinsi.map((p) {
    return Marker(
      point: LatLng(
        double.tryParse(p["latitude"].toString()) ?? 0.0,   // line 117-120
        double.tryParse(p["longitude"].toString()) ?? 0.0,  // line 121-124
      ),
      width: 50, height: 50,
      child: GestureDetector(
        onTap: () { showDialog(...) },   // p["nama_polda"] as String (line 143)
        child: Tooltip(
          message: p["nama_polda"] as String,  // line 183 — CRASH RISK
          child: Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
      ),
    );
  }).toList(),
)
```

**Tiga karakteristik kritis marker creation:**

| Aspek | Perilaku | Risiko |
|-------|----------|--------|
| **No skip condition** | Setiap elemen `provinsi` SELALU menghasilkan Marker — tidak ada `if` guard | Markers yang jatuh di (0,0) tetap dirender |
| **Silent fallback ke (0,0)** | `double.tryParse(...) ?? 0.0` → jika field tidak ada/null/unparseable, marker jatuh ke **Null Island** (0°N 0°E, Gulf of Guinea) | Semua 38 marker invisible karena peta di-center di Indonesia (-2.5, 118.0, zoom 4.3) — Null Island ~12,000 km dari Indonesia |
| **`as String` crash** | `p["nama_polda"] as String` di line 143 & 183 — jika `nama_polda` null, cast throws di `build()` | Seluruh FlutterMap crash → red error screen atau blank widget |

### 1D. Type Safety — Ringkasan

| Lokasi | Tipe lat/lng |
|--------|-------------|
| API Response (JSON) | Unknown — bisa `String`, `double`, atau tidak ada sama sekali |
| `Map<String, dynamic>` storage | `dynamic` — tidak ada compile-time check |
| Parsing ke `LatLng` | `double.tryParse(dynamic.toString())` → `double` |
| Fallback | `0.0` (hardcoded) |
| Form input (`form_input_polda.dart:46-47`) | Dikirim sebagai `String` ke API |

**Kesimpulan type safety:** Tidak ada. Pipeline sepenuhnya "stringly-typed" dengan silent fallback.

---

## 2. ROOT CAUSE ANALYSIS

### Primary Suspect: BACKEND API TIDAK MENGEMBALIKAN `latitude` DAN `longitude`

**Evidence dari Flutter codebase:**

1. `dashboard.dart:117-124` — Field `"latitude"` dan `"longitude"` diakses dari JSON map. Jika API tidak mengirim field ini, `p["latitude"]` = `null` → `null.toString()` = `"null"` → `double.tryParse("null")` = `null` → `?? 0.0` = `0.0`.

2. **Semua 38 marker akan jatuh di LatLng(0.0, 0.0)** — Null Island, Samudra Atlantik. Pada peta Indonesia yang di-center di `LatLng(-2.5, 118.0)` dengan zoom 4.3, marker di (0,0) TIDAK AKAN TERLIHAT karena jaraknya ~12,000 km.

3. **Tidak ada error atau warning** — silent failure. `debugPrint` di catch block (line 63) hanya triggered saat HTTP exception, bukan saat field JSON missing.

4. `lib/pages/polda.dart:259,264` juga membaca field yang sama — jika field ada, DataTable akan menampilkan nilai; jika tidak, cell akan kosong. Ini bisa dijadikan cross-check.

**Mengapa backend mungkin tidak mengirim lat/lng:**
- Backend CodeIgniter mungkin memiliki hardcoded `SELECT id, nama_polda, created_at FROM tbl_polda` yang tidak menyertakan kolom `latitude` dan `longitude`
- Kolom di dump awal adalah `VARCHAR(100)`, setelah SQL patch dikonversi ke `DECIMAL(10,8)`/`DECIMAL(11,8)` — jika backend menggunakan model/ORM yang caching column list, field baru mungkin tidak terdaftar
- API `GET /api/v1/polda` mungkin return field yang berbeda dari `GET /api/v1/master/wilayah` (API Doc §2.1 menyebut endpoint berbeda untuk master wilayah)

### Secondary Suspect: FLUTTER CODE DEFECTS

Bahkan jika API MENGIRIM lat/lng, kode Flutter memiliki defect yang bisa menyebabkan marker tidak muncul:

| Defect | Lokasi | Dampak |
|--------|--------|--------|
| `p["nama_polda"] as String` crash | `dashboard.dart:143,183` | Jika `nama_polda` null, FlutterMap crash di build() |
| Tidak ada empty state | `dashboard.dart:94-362` | Jika `provinsi = []`, marker layer kosong tanpa indikasi |
| Tidak ada debug log | `dashboard.dart:48` (commented out) | Tidak bisa verifikasi response API |
| `isLoading` tidak digunakan | `dashboard.dart:20` vs build() | Tidak ada loading indicator saat fetch |

### Direction: Frontend Fix + Backend Verification

**Untuk menentukan mana root cause sebenarnya, perlu verifikasi API terlebih dahulu.** Rekomendasi: uncomment `print("ini json ${json}")` di line 48 dashboard.dart, jalankan aplikasi dengan role 3, dan periksa console output apakah `"latitude"` dan `"longitude"` ada dalam setiap object di `json["data"]`.

Jika **ada**: masalah di Flutter parsing/marker (lanjut ke §3 — Frontend Fix).
Jika **tidak ada**: masalah di backend API — perlu eskalasi ke backend developer untuk menambah `latitude` dan `longitude` ke SELECT query.

---

## 3. REFACTOR PLAN (FLUTTER SIDE)

Berdasarkan audit, baik API mengirim lat/lng atau tidak, kode Flutter memiliki defect serius yang harus diperbaiki. Berikut adalah step-by-step refactor:

### Task 1: Buat Polda Model Class

**File baru:** `lib/models/polda_model.dart`

Buat model sederhana dengan `factory` constructor dari JSON untuk menggantikan `Map<String, dynamic>`:

```dart
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
      id: json["id"] is int ? json["id"] : int.tryParse(json["id"].toString()) ?? 0,
      namaPolda: json["nama_polda"]?.toString() ?? "Unknown",
      latitude: double.tryParse((json["latitude"] ?? json["lat"]).toString()) ?? 0.0,
      longitude: double.tryParse((json["longitude"] ?? json["lng"] ?? json["lon"]).toString()) ?? 0.0,
      createdAt: json["created_at"]?.toString(),
    );
  }

  bool get hasValidCoordinates => latitude != 0.0 || longitude != 0.0;

  LatLng get latLng => LatLng(latitude, longitude);
}
```

### Task 2: Parsing API dengan Model + Validasi

**Modify:** `lib/pages/dashboard.dart:30-65` (method `getPoldaApi`)

Ganti `List<Map<String, dynamic>>` dengan `List<Polda>`, tambah validasi dan debug logging:

```dart
List<Polda> provinsi = [];   // ganti deklarasi di line 19

// Di dalam getPoldaApi(), setelah jsonDecode:
final rawList = json["data"] as List;
final parsed = rawList
    .map((e) => Polda.fromJson(e as Map<String, dynamic>))
    .toList();

final validCount = parsed.where((p) => p.hasValidCoordinates).length;
debugPrint("Polda fetched: ${parsed.length} total, $validCount with valid coordinates");

if (validCount == 0 && parsed.isNotEmpty) {
  debugPrint("WARNING: All ${parsed.length} Polda have (0,0) coordinates. "
      "API may not be returning latitude/longitude fields.");
}

setState(() {
  provinsi = parsed;
  isLoading = false;
});
```

### Task 3: Filter Markers + Defensive Null Handling

**Modify:** `lib/pages/dashboard.dart:112-193` (bagian MarkerLayer)

Ganti mapping yang selalu membuat Marker untuk setiap element dengan filter + handling aman:

```dart
MarkerLayer(
  markers: provinsi
      .where((p) => p.hasValidCoordinates)   // ← FILTER: skip Null Island
      .map((p) {
        return Marker(
          point: p.latLng,                    // ← gunakan getter dari model
          width: 50,
          height: 50,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xff1E1B4B),
                  title: Text(
                    p.namaPolda,              // ← NON-NULL (default "Unknown")
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  content: Text(
                    "DATA WILAYAH\n\n"
                    "📍 Lat: ${p.latitude.toStringAsFixed(4)}\n"
                    "📍 Lng: ${p.longitude.toStringAsFixed(4)}\n"
                    "👮 Personel : 2.450\n"
                    "📦 Inventaris : 1.200\n"
                    "🔫 Senjata : 500\n"
                    "🐕 Satwa : 25\n\n"
                    "STATUS : AKTIF",
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Tutup", style: TextStyle(color: Colors.amber)),
                    ),
                  ],
                ),
              );
            },
            child: Tooltip(
              message: p.namaPolda,
              child: const Icon(Icons.location_on, color: Colors.red, size: 40),
            ),
          ),
        );
      }).toList(),
),
```

### Task 4: Tambah Empty State

**Modify:** `lib/pages/dashboard.dart:_buildCommandCenterContent()` (tambah di awal method, sebelum return Stack)

```dart
Widget _buildCommandCenterContent() {
  if (isLoading) {
    return const Center(
      child: CircularProgressIndicator(color: Colors.cyanAccent),
    );
  }

  if (provinsi.isEmpty) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map_off, size: 64, color: Colors.white38),
          const SizedBox(height: 16),
          const Text(
            "Tidak ada data Polda untuk ditampilkan",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            "Periksa koneksi atau hubungi administrator",
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }

  return Stack( ... );   // kode existing Stack
}
```

### Task 5: Verifikasi End-to-End

**Verification steps setelah perubahan:**

1. Aktifkan debug console: uncomment `print` di `getPoldaApi()` atau gunakan `debugPrint` dari Task 2
2. Jalankan `flutter run` dengan akun role 3 (Command Center / Eksekutif)
3. Periksa console output: `"Polda fetched: X total, Y with valid coordinates"`
4. **Jika Y = 0:** API tidak mengembalikan lat/lng — eskalasi ke backend developer. Flutter akan menampilkan empty state.
5. **Jika Y > 0:** Marker akan muncul di peta. Flutter hanya merender marker dengan koordinat valid.

### Task 6: Commit

```bash
git add lib/models/polda_model.dart lib/pages/dashboard.dart
git commit -m "fix(dashboard): add Polda model, validate map markers, handle empty state

- Create Polda model class with fromJson, hasValidCoordinates, latLng getter
- Replace raw Map<String, dynamic> with typed Polda list
- Filter markers to skip (0,0) Null Island fallback
- Add debug logging for API coordinate validation
- Add loading spinner + empty state UI
- Replace unsafe 'as String' cast with non-null default

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## 4. VERIFICATION CHECKLIST

| # | Verifikasi | Metode | Expected |
|---|-----------|--------|----------|
| 1 | Model parsing | Jalankan app, login sebagai role 3, cek console | `debugPrint` menampilkan jumlah Polda dengan koordinat valid |
| 2 | Marker visibility | Dashboard Command Center | Jika API mengirim lat/lng → marker merah muncul di peta Indonesia. Jika tidak → empty state message |
| 3 | No crash | Tap marker, tap peta, close dialog | Tidak ada crash "Null check operator" atau "type cast" error |
| 4 | Loading state | Refresh dashboard | Spinner muncul sebentar saat data di-fetch |
| 5 | Empty state | Logout, atau gunakan role non-3 | Placeholder "Segera Hadir" untuk non-3, empty state untuk role 3 tanpa data |
| 6 | API verification | Periksa console output | Jika semua koordinat (0,0) → eskalasi ke backend |

---

**⚠️ PERHATIAN: Jangan modifikasi kode Dart apapun sebelum user memberikan APPROVE.**
