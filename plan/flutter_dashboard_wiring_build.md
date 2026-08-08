# Flutter Dashboard Wiring Build — `lib/pages/dashboard.dart`

**Status:** ✅ WIRED — real `DashboardNasional` / `DashboardDrilldown` data now drives the Command Center
**File modified:** `lib/pages/dashboard.dart` (448 → 629 lines; +257 / −76 per `git diff --stat`)
**Models consumed:** `lib/models/dashboard_model.dart` (built in previous step)
**Backend endpoints hit:**
- `GET $apiBaseUrl/api/v1/dashboard/nasional` (page load)
- `GET $apiBaseUrl/api/v1/dashboard/drilldown?polda_id={id}` (marker tap)

---

## 1. Import (relative — adjusted per codebase convention)

`package:sindomon/...` is valid (pubspec name is `sindomon`), but every local import in this project is relative, so the adjusted path is used:

```dart
import '../config/api_config.dart';
+ import '../models/dashboard_model.dart';
import '../models/polda_model.dart';
```

---

## 2. State Variables

```dart
  List<Polda> provinsi = [];            // retained — legacy getPoldaApi() (see §10)
  bool isLoading = true;                // retained — legacy
  String? _roleId;

+ /// Real national dashboard payload from GET /api/v1/dashboard/nasional.
+ DashboardNasional? _nasionalData;
+ bool _isLoadingDashboard = true;
```

---

## 3. `_init()` — fetch sequencing

```dart
  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _roleId = prefs.getString("roleid_login"));
    await getPoldaApi();
+   await getDashboardSummary();
  }
```

---

## 4. New fetch methods (inserted before `initState`)

### `getDashboardSummary()` — national payload

```dart
  /// Fetches the national dashboard payload (ringkasan + peta nodes +
  /// sitkamtibmas terkini) for the Command Center map.
  Future<void> getDashboardSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final response = await http.get(
        Uri.parse("$apiBaseUrl/api/v1/dashboard/nasional"),
        headers: {"authorization": token.toString()},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          _nasionalData = DashboardNasional.fromJson(json["data"]);
          _isLoadingDashboard = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoadingDashboard = false);
      }
    } catch (e) {
      debugPrint("getDashboardSummary error: $e");
      if (!mounted) return;
      setState(() => _isLoadingDashboard = false);
    }
  }
```

### `_fetchDrilldown()` — per-polda popup payload

```dart
  /// Fetches per-polda drill-down aggregates for the marker popup.
  /// Throws on non-200 so the FutureBuilder surfaces the error state.
  Future<DashboardDrilldown> _fetchDrilldown(int poldaId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final response = await http.get(
      Uri.parse(
        "$apiBaseUrl/api/v1/dashboard/drilldown?polda_id=$poldaId",
      ),
      headers: {"authorization": token.toString()},
    );
    if (response.statusCode != 200) {
      throw Exception("drilldown HTTP ${response.statusCode}");
    }
    final json = jsonDecode(response.body);
    return DashboardDrilldown.fromJson(json["data"]);
  }
```

Both follow the app-wide auth convention: token from `SharedPreferences`, sent as lowercase `authorization` header, **no "Bearer" prefix**.

---

## 5. Loading / Empty-state gates (`_buildCommandCenterContent`)

```dart
-   if (isLoading) {
+   if (_isLoadingDashboard) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.cyanAccent),
      );
    }

+   final petaNodes = _nasionalData?.peta ?? const <PetaNode>[];
-   if (provinsi.isEmpty) {
+   if (petaNodes.isEmpty) {
```

Loading and empty states now key off the new `/nasional` payload (single source of truth for the map).

---

## 6. Map Markers — iterate `_nasionalData?.peta`

```dart
              MarkerLayer(
-               markers:
-                   provinsi.where((p) => p.hasValidCoordinates).map((p) {
+               markers: petaNodes
+                   .where((n) => n.hasValidCoordinates)
+                   .map((n) {
                      return Marker(
-                       point: p.latLng,
+                       point: n.latLng,
                        width: 50,
                        height: 50,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
-                         onTap: () { showDialog(...hardcoded dialog...) },
+                         onTap: () => _showDrilldownDialog(n),
                          child: Tooltip(
-                           message: p.namaPolda,
+                           message: n.namaPolda,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
```

The inline hardcoded `showDialog` was extracted to `_showDrilldownDialog(PetaNode node)` — the marker `onTap` is now a one-liner.

---

## 7. Drill-Down Popup — `FutureBuilder<DashboardDrilldown>`

Replaces the hardcoded "DATA WILAYAH / 👮 Personel : 2.450 ..." text. New method:

```dart
  /// Drill-down popup for a map node. Fetches `/dashboard/drilldown` on open
  /// and renders the real per-polda aggregates once the payload arrives.
  void _showDrilldownDialog(PetaNode node) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xff1E1B4B),
          title: Text(
            node.namaPolda,                      // ← real: from peta node
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: FutureBuilder<DashboardDrilldown>(
            future: _fetchDrilldown(node.poldaId),   // ← polda_id from tapped node
            builder: (context, snapshot) {
              // ⏳ While the drill-down request is in flight:
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 160,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.cyanAccent,
                    ),
                  ),
                );
              }

              final drilldown = snapshot.data;
              // ⚠️ Error / empty snapshot — no force-unwrap, safe fallback:
              if (snapshot.hasError || drilldown == null) {
                return const SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      "Gagal memuat data wilayah.\n"
                      "Periksa koneksi atau hubungi administrator.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                );
              }

              return SizedBox(
                width: 260,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _drilldownRow("Personel", _formatNumber(drilldown.personil.totalAktif)),
                    const SizedBox(height: 8),
                    _drilldownRow("Senjata", _formatNumber(drilldown.logistik.senjata.total)),
                    const SizedBox(height: 8),
                    _drilldownRow("Sarpras", _formatNumber(drilldown.logistik.sarpras.total)),
                    const SizedBox(height: 8),
                    _drilldownRow("Satwa K9", _formatNumber(drilldown.logistik.satwaK9.total)),
                    const SizedBox(height: 8),
                    _drilldownRow("Vakansi", _formatNumber(drilldown.vakansi.selisih)),
                    const SizedBox(height: 12),
                    Text(
                      "📍 ${drilldown.polda.latitude}, "
                      "${drilldown.polda.longitude}",
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Tutup", style: TextStyle(color: Colors.amber)),
            ),
          ],
        );
      },
    );
  }
```

Supporting helpers (same file):

```dart
  /// One label/value row inside the drill-down dialog.
  Widget _drilldownRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 15)),
        Text(
          value,
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Formats an int with thousands separators: 153500 → "153,500".
  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
```

**Popup flow:** marker tap → `showDialog` → `FutureBuilder` creates `_fetchDrilldown(node.poldaId)` → spinner while in flight → real aggregates on success → friendly error card on failure (no crash, no `!`).

---

## 8. Right-Top Aggregate Panel

| KPI | Before | After |
|---|---|---|
| Total Personel | `"153,500"` (hardcoded) | `_formatNumber(_nasionalData?.ringkasan.totalPersonilAktif ?? 0)` |
| Defense Equipment | `"97%"` (hardcoded) | `_defenseEquipmentLabel` getter — **calculated** |
| Vacant Position | `"218"` (hardcoded) | `_formatNumber(_nasionalData?.ringkasan.selisihKekurangan ?? 0)` |

The `const Column` became non-const; labels stay `const`. Defense Equipment calculation (no direct percentage exists in the payload, so it is derived from weapon readiness):

```dart
  /// Calculated readiness percentage (layak / total senjata). Falls back to
  /// "0%" when no weapon data is available yet.
  String get _defenseEquipmentLabel {
    final total = _nasionalData?.ringkasan.totalSenjata ?? 0;
    if (total <= 0) return "0%";
    final layak = _nasionalData?.ringkasan.totalSenjataLayak ?? 0;
    return "${((layak / total) * 100).toStringAsFixed(0)}%";
  }
```

---

## 9. Bottom-Center KPIs + Bottom-Left Sitkamtibmas

### K9 Standby

```dart
-             _kpiCard("K9 Standby", "140"),
+             _kpiCard(
+               "K9 Standby",
+               _formatNumber(_nasionalData?.ringkasan.totalSatwaK9 ?? 0),
+             ),
```

`Active Fleet "300"` is **intentionally left hardcoded** — GPS/fleet tracking is a future module with no backend aggregate (mission directive).

### Sitkamtibmas List

```dart
-           child: ListView(
-             children: const [
-               Text("Sitkamtibmas Reports", ...),
-               SizedBox(height: 10),
-               Text(
-                 "• Laporan 1\n• Laporan 2\n• Laporan 3\n• Laporan 4\n• Laporan 5",
-                 style: TextStyle(color: Colors.white70),
-               ),
-             ],
-           ),
+           child: Column(
+             crossAxisAlignment: CrossAxisAlignment.start,
+             children: [
+               const Text(
+                 "Sitkamtibmas Reports",
+                 style: TextStyle(color: Colors.white),
+               ),
+               const SizedBox(height: 10),
+               Expanded(
+                 child: ListView.builder(
+                   itemCount: _nasionalData?.sitkamtibmasTerkini.length ?? 0,
+                   itemBuilder: (context, index) {
+                     final report = _nasionalData?.sitkamtibmasTerkini[index];
+                     if (report == null) return const SizedBox.shrink();
+                     return Padding(
+                       padding: const EdgeInsets.only(bottom: 6),
+                       child: Text(
+                         "• ${report.deskripsiKejadian} "
+                         "[${report.levelKritis}]",
+                         maxLines: 2,
+                         overflow: TextOverflow.ellipsis,
+                         style: const TextStyle(
+                           color: Colors.white70,
+                           fontSize: 12,
+                         ),
+                       ),
+                     );
+                   },
+                 ),
+               ),
+             ],
+           ),
```

`Expanded` + `ListView.builder` keeps the header pinned while up to 10 real reports scroll inside the fixed 250×120 panel.

---

## 10. Design Decisions & Notes

1. **`getPoldaApi()` / `provinsi` / `isLoading` retained** — mission directive: `getDashboardSummary()` is called *after* `getPoldaApi()` in `_init()`. The old `/polda` fetch is now superseded (the `/nasional` payload contains the same map nodes) and is a candidate for removal in a follow-up cleanup pass.
2. **Loading/empty gates now key off `_nasionalData`** — the map's single source of truth, avoiding the two-source-of-truth bug where `/polda` fails but `/nasional` succeeds (and vice versa).
3. **Defense Equipment** is calculated (`layak / total * 100`) since the backend has no direct percentage; falls back to `"0%"` with zero/absent data.
4. **Zero force-unwraps** — `FutureBuilder` data is read via `final drilldown = snapshot.data; if (snapshot.hasError || drilldown == null) ...` — no `!` anywhere.
5. **Import path** — relative (`../models/dashboard_model.dart`) per project convention; `package:sindomon/...` would also resolve.

---

## 11. Verification

| Check | Result |
|---|---|
| Force-unwrap `!` scan on `dashboard.dart` | 0 matches ✅ |
| Delimiter balance `{}` / `()` / `[]` | 56/56, 277/277, 22/22 ✅ |
| Model class references (`DashboardNasional`, `DashboardDrilldown`, `PetaNode`) | All defined in `dashboard_model.dart` ✅ |
| Model member references (e.g. `ringkasan.totalPersonilAktif`, `logistik.satwaK9.total`, `vakansi.selisih`, `polda.latitude`) | All exist in the model ✅ |
| Endpoint URLs | `$apiBaseUrl/api/v1/dashboard/nasional` + `/dashboard/drilldown?polda_id=$poldaId` ✅ |
| Remaining hardcoded UI values | Only `Active Fleet "300"` (intentional, future GPS module) ✅ |
| `flutter analyze` | ⚠️ NOT RUN — Flutter SDK not installed on this machine; run `flutter analyze` in CI/local before merge |

---

## 12. Manual Test Checklist (when Flutter SDK available)

- [ ] Login as role 3 → spinner → map renders markers from `/nasional` `peta` nodes
- [ ] Tap a marker → dialog with spinner → real Personel / Senjata / Sarpras / Satwa K9 / Vakansi values from `/drilldown`
- [ ] Kill network mid-popup → error card "Gagal memuat data wilayah", no crash
- [ ] Right-top panel shows real Total Personel, calculated Defense Equipment %, Vacant Position (thousands-separated)
- [ ] K9 Standby shows `ringkasan.totalSatwaK9`
- [ ] Sitkamtibmas panel lists real reports with `levelKritis` tags, scrollable
- [ ] `flutter analyze` clean
