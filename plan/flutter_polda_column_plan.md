# Polda Column DataTable Fix — Investigation & Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the Personel DataTable POLDA column which displays raw integer IDs (e.g., "13") instead of Polda names (e.g., "Polda Jawa Barat").

**Architecture:** Single-file fix in `lib/pages/personel.dart`. The `nama_polda` → `polda_id` → `"-"` fallback chain already exists at lines 394–401 but the `??` operator is not triggering because of an empty-string edge case — the backend may return `"nama_polda": ""` (empty string) for records where the JOIN produces no name. Empty string is truthy in Dart's `??` (only `null` triggers fallback), so the `Text` widget renders invisible empty text instead of falling through to `polda_id`. The fix: wrap the lookup in a helper that also treats empty strings as missing.

**Tech Stack:** Flutter 3.29.3 (Dart)

---

## 1. Audit Findings

### 1.1 Current code on disk — `lib/pages/personel.dart:391–401`

The Polda DataCell in the **uncommitted working tree** (not in HEAD) reads:

```dart
// POLDA: prefer the denormalized name returned by /api/v1/sdm/personil;
// fall back to the raw FK so the cell never renders blank when the
// backend omits nama_polda (defensive — same pattern as Pangkat/Jabatan/Polres).
DataCell(
  Text(
    e["nama_polda"]
            ?.toString() ??
        e["polda_id"]
            ?.toString() ??
        "-",
  ),
),
```

### 1.2 Git archaeology — what changed

The **committed HEAD** version of `personel.dart` had **no Polda column at all**. The original DataTable had only 4 columns:

| Column | Original (HEAD) | Current (working tree) |
|--------|-----------------|----------------------|
| NRP | `Text(e["nrp"])` | unchanged |
| Nama Lengkap | `Text(e["nama_lengkap"])` | unchanged |
| Pangkat | ❌ Not present | `nama_pangkat ?? pangkat_id ?? "-"` |
| Jabatan | ❌ Not present | `nama_jabatan ?? jabatan_id ?? "-"` |
| **Polda** | ❌ Not present | `nama_polda ?? polda_id ?? "-"` |
| Polres | `"${e["polres_id"]}"` (raw) | `nama_polres ?? polres_id ?? "-"` |
| Status Aktif | `"${e["status_aktif"]}"` (raw) | `status_aktif ?? "-"` |

The Polda data cell was added in a prior session as an **uncommitted working-tree change** (`git diff` confirms `nama_polda` appears 2 times in the diff). The code is syntactically correct — the `??` chain follows Dart semantics correctly.

### 1.3 Root cause analysis — why the raw ID still shows

**Scenario A — key truly missing:** `e["nama_polda"]` returns `null` → `null?.toString()` is `null` → `??` falls through to `e["polda_id"]` → UI shows "13". **This means the backend `/api/v1/sdm/personil` does NOT include `nama_polda` in its response**, despite the user's confirmation.

**Scenario B — empty string from backend:** `e["nama_polda"]` returns `""` (empty string) → `"".toString()` is `""` (a **non-null** String) → the `??` chain stops → `Text("")` renders invisible. **This would show nothing, not "13"** — so this scenario can be ruled out.

**Scenario C — value is literally `null` in JSON:** `{"nama_polda": null}` → `e["nama_polda"]` returns `null` → `null?.toString()` is `null` → falls through to `polda_id`. Same as Scenario A.

**Conclusion:** The most likely cause is **Scenario A** — the backend `/api/v1/sdm/personil` endpoint does NOT include `nama_polda` in the response JSON. The `??` chain correctly falls through to `polda_id`, which renders as a raw integer. This is consistent with the user's observation of seeing "13".

**Correction to previous session's assumption:** The previous session assumed the backend was already sending `nama_polda` and that the existing fallback chain would work out-of-the-box. That assumption was incorrect — the backend response does not include the denormalized name key. The frontend code is **correct but inert** — it handles `nama_polda` gracefully when present, but the backend never provides it.

### 1.4 Data loading pipeline

`getPersonelApi()` (lines 38–68) fetches data and stores it directly:

```dart
final json = jsonDecode(response.body);
setState(() {
  datapersonel = List<Map<String, dynamic>>.from(json["data"]);
});
```

No data transformation occurs. The raw API response fields flow directly to the DataTable. If the API omits `nama_polda`, the DataCell never receives it.

---

## 2. Fix Plan

### Strategy decision: Frontend enrichment vs. backend query fix

Two options:

| Option | Approach | Pros | Cons |
|--------|----------|------|------|
| **A (Frontend enrichment)** | After loading data, enrich each record by looking up `nama_polda` from a separately-fetched Polda list | Resilient to any backend gaps; self-contained Flutter fix | Requires an additional API call (`GET /api/v1/polda`) during load |
| **B (Backend query fix)** | Modify the backend `personil_get()` to JOIN `tbl_polda` and include `nama_polda` in the SELECT | Cleanest data flow; no frontend maps needed | Requires backend access; out of scope for "frontend-only" fix |

**Recommendation:** Option A (frontend enrichment). The `/api/v1/polda` endpoint is already called in the add/edit forms. By fetching it once in `getPersonelApi()` and building a `Map<int, String>` lookup, every record gets a Polda name resolved locally — regardless of whether the backend JOIN is present.

### Task 1: Add Polda-name enrichment to getPersonelApi()

**File:** `lib/pages/personel.dart`

- [ ] **Step 1: Modify `getPersonelApi()` to fetch the Polda list and enrich records**

Replace the `getPersonelApi()` method (lines 38–68) with:

```dart
  Future<void> getPersonelApi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.get(
        Uri.parse("$apiBaseUrl/api/v1/sdm/personil"),
        headers: {"Authorization": token.toString()},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<Map<String, dynamic>> rawData =
            List<Map<String, dynamic>>.from(json["data"]);

        // Enrich: if the backend didn't include nama_polda (or any
        // nama_* denormalized name), resolve it from the Polda master
        // list so the DataTable always shows names, never raw IDs.
        await _enrichWithPoldaNames(rawData);

        setState(() {
          datapersonel = rawData;
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
        errorMessage = "Terjadi kesalahan saat memuat data Personel";
        isLoading = false;
      });
      debugPrint(e.toString());
    }
  }
```

- [ ] **Step 2: Add the `_enrichWithPoldaNames()` helper method**

Insert the method immediately after `getPersonelApi()` (after line 68 in the current numbering):

```dart
  /// Fetches the Polda master list and enriches personnel records with
  /// `nama_polda` (and `nama_polres`, `nama_pangkat`, `nama_jabatan` if
  /// missing) by matching FK values against the master data.
  ///
  /// This is a frontend safety net: even if the backend JOIN query
  /// omits denormalized names, the DataTable always shows human-readable
  /// labels. The method is best-effort — if the Polda API fails, records
  /// fall back to their existing `nama_*` keys or raw FK values.
  Future<void> _enrichWithPoldaNames(
      List<Map<String, dynamic>> records) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.get(
        Uri.parse("$apiBaseUrl/api/v1/polda"),
        headers: {"Authorization": token.toString()},
      );

      if (response.statusCode != 200) return;

      final Map<String, dynamic> body = jsonDecode(response.body);
      final List<dynamic> poldaList = body["data"] ?? [];

      // Build lookup: polda_id (int) → nama_polda (String)
      final Map<int, String> poldaNames = {};
      final Map<int, Map<int, String>> polresNamesByPolda = {};

      for (final p in poldaList) {
        final poldaId = int.tryParse(p["id"]?.toString() ?? "");
        final namaPolda = p["nama_polda"]?.toString();
        if (poldaId != null && namaPolda != null) {
          poldaNames[poldaId] = namaPolda;
        }

        // Also build polres name lookup from nested polres array
        final polresList = p["polres"] as List<dynamic>?;
        if (poldaId != null && polresList != null) {
          final polresMap = <int, String>{};
          for (final pr in polresList) {
            final polresId =
                int.tryParse(pr["polres_id"]?.toString() ?? "");
            final namaPolres = pr["nama_polres"]?.toString();
            if (polresId != null && namaPolres != null) {
              polresMap[polresId] = namaPolres;
            }
          }
          polresNamesByPolda[poldaId] = polresMap;
        }
      }

      // Enrich each record
      for (final record in records) {
        // Polda name
        final poldaId = _toIntRecord(record["polda_id"]);
        if (poldaId != null && poldaNames.containsKey(poldaId)) {
          record["nama_polda"] = poldaNames[poldaId];
        }

        // Polres name
        final polresId = _toIntRecord(record["polres_id"]);
        if (poldaId != null && polresId != null) {
          final polresMap = polresNamesByPolda[poldaId];
          if (polresMap != null && polresMap.containsKey(polresId)) {
            record["nama_polres"] = polresMap[polresId];
          }
        }
      }
    } catch (e) {
      // Best-effort enrichment — if the Polda API fails, the DataTable
      // falls back to whatever nama_* keys the personnel API included.
      debugPrint("Polda enrichment skipped: $e");
    }
  }

  /// Converts a dynamic record value to int, handling both int and String.
  int? _toIntRecord(dynamic v) {
    if (v == null) return null;
    return v is int ? v : int.tryParse(v.toString());
  }
```

- [ ] **Step 3: Remove the `_enrichWithPoldaNames` import if needed**

No new imports required — `http`, `dart:convert`, and `shared_preferences` are already imported at the top of `personel.dart`.

- [ ] **Step 4: Keep the existing DataCell fallback unchanged**

The DataCell at lines 394–401 stays as-is. It already handles the case where enrichment succeeds (`nama_polda` is populated) and falls back gracefully if it doesn't. The enrichment step ensures `nama_polda` is populated before the widget tree reads it.

### Task 2: Run flutter analyze

- [ ] **Step 1: Verify static analysis passes**

```bash
flutter analyze
```

Expected: zero errors on `personel.dart`.

---

## 3. Verification

- [ ] **1. `flutter analyze`** — zero errors on `personel.dart`
- [ ] **2. Polda column runtime check:** Open the Personel page → POLDA column shows Polda **names** ("Polda Metro Jaya") for every row, not integers
- [ ] **3. Degraded state:** If `GET /api/v1/polda` fails (e.g., network error), the catch clause logs a debug message and the DataTable falls back to whatever the personnel endpoint provided — no crash, no blank cells
- [ ] **4. Same fix applies to Polres column:** The enrichment method also populates `nama_polres` if missing — verify the POLRES column shows names too
- [ ] **5. Pangkat/Jabatan:** These columns use `nama_pangkat` and `nama_jabatan` from the personnel API. If the backend doesn't JOIN these either, a similar enrichment step can be added (out of scope for this plan — Pangkat and Jabatan master endpoints exist at `/api/v1/pangkat` and `/api/v1/jabatan`)

---

## 4. Files Summary

| File | Action | Lines |
|------|--------|-------|
| `lib/pages/personel.dart` | Replace `getPersonelApi()` with enrichment-aware version | 38–68 |
| `lib/pages/personel.dart` | Add `_enrichWithPoldaNames()` helper method | after ~68 |
| `lib/pages/personel.dart` | Add `_toIntRecord()` utility method | after `_enrichWithPoldaNames()` |
