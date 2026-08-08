# Flutter Dashboard Audit — National Command Center

**File:** `lib/pages/dashboard.dart` (448 lines)
**Model:** `lib/models/polda_model.dart`
**Date:** 2025-08-08
**Auditor:** Reasonix (Senior Flutter Auditor)

---

## 1. Current UI Architecture

### 1.1 Page Scaffold

The `DashboardPage` is a `StatefulWidget` rendered inside the standard layout:

```
Scaffold
  └─ AppBackground (wp-putih-mabes.png)
       └─ SafeArea → Row
            ├─ AppSidebar(currentRoute: "dashboard")
            └─ Expanded → role-gated content
```

**Role gate (line 102):** `_roleId == "3"` → Command Center view. All other roles see `_buildPlaceholder()` (a "Segera Hadir" card). The role is read from `SharedPreferences` key `roleid_login`.

### 1.2 Map Layer (lines 146–222)

| Aspect | Detail |
|---|---|
| **Library** | `flutter_map` + `latlong2` |
| **Tile source** | ArcGIS World Imagery (satellite) |
| **Center** | `LatLng(-2.5, 118.0)` — hardcoded, roughly Indonesia centroid |
| **Zoom** | `4.3` — hardcoded |
| **Overlay** | A semi-transparent black overlay (`0.20` alpha) sits on top of the map via `IgnorePointer` so it doesn't block interactions |

### 1.3 Marker Rendering (lines 158–220)

```dart
provinsi.where((p) => p.hasValidCoordinates).map((p) {
  return Marker(
    point: p.latLng,
    width: 50, height: 50,
    child: GestureDetector(
      onTap: () { showDialog(...) },
      child: Tooltip(
        message: p.namaPolda,
        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
      ),
    ),
  );
}).toList()
```

- **Markers ARE data-driven:** They iterate over the `provinsi` list (fetched from `/api/v1/polda`).
- **Icon:** Hardcoded red `Icons.location_on` (the default Material pin icon) at size 40.
- **Filtering:** Only Polda with `hasValidCoordinates == true` (lat != 0.0 && lng != 0.0) get markers.
- **Tooltip:** Shows `namaPolda` on hover/long-press.

### 1.4 Drill-Down Popup (lines 167–207)

| Aspect | Detail |
|---|---|
| **Widget** | `AlertDialog` with dark indigo background (`0xff1E1B4B`) |
| **Trigger** | `onTap` on the marker's `GestureDetector` |
| **Title** | `p.namaPolda` — **real data** |
| **Body** | Mixed — lat/lng are real, but stats are **100% hardcoded** |
| **Close** | `Navigator.pop(context)` on "Tutup" button |

**Hardcoded dummy values in the popup body:**
```
👮 Personel : 2.450
📦 Inventaris : 1.200
🔫 Senjata : 500
🐕 Satwa : 25
STATUS : AKTIF
```

**The popup does NOT receive `polda_id` for any secondary API call.** It only displays fields from the `Polda` model plus the hardcoded stats above.

### 1.5 Overlay Panels (all hardcoded)

#### Right-Top Aggregate Panel (lines 262–328)

A 240px-wide glassmorphism container (`Colors.black 0.20 alpha` + cyan border) showing three KPIs:

| Label | Display Value | Hardcoded |
|---|---|---|
| Total Personel | `153,500` | ✅ Yes |
| Defense Equipment | `97%` | ✅ Yes |
| Vacant Position | `218` | ✅ Yes |

#### Bottom-Left Sitkamtibmas Panel (lines 330–362)

A 250×120px dark container with a `ListView` of 5 hardcoded report items:
```
• Laporan 1
• Laporan 2
• Laporan 3
• Laporan 4
• Laporan 5
```

#### Bottom-Center KPI Cards (lines 364–377)

Two `_kpiCard` widgets in a `Row`:

| Label | Value | Hardcoded |
|---|---|---|
| Active Fleet | `300` | ✅ Yes |
| K9 Standby | `140` | ✅ Yes |

---

## 2. Data Binding Status

### 2.1 State Variables

| Variable | Type | Source | Notes |
|---|---|---|---|
| `provinsi` | `List<Polda>` | API `GET /api/v1/polda` | Only data state. Drives markers + popup title/coords |
| `isLoading` | `bool` | Local | Controls spinner vs. content |
| `_roleId` | `String?` | `SharedPreferences` | Gates the Command Center view |

### 2.2 What IS Data-Bound

- ✅ Polda list (fetched from API, parsed into `Polda` model)
- ✅ Marker positions (`p.latLng` → real coordinates)
- ✅ Marker tooltip (`p.namaPolda`)
- ✅ Popup title (`p.namaPolda`)
- ✅ Popup lat/lng display (`p.latitude`, `p.longitude`)

### 2.3 What is HARDCODED (needs state variables)

| UI Element | Current Value | Missing State Variable |
|---|---|---|
| Popup: Personel count | `2.450` | Per-Polda personel count |
| Popup: Inventaris count | `1.200` | Per-Polda inventaris count |
| Popup: Senjata count | `500` | Per-Polda senjata count |
| Popup: Satwa count | `25` | Per-Polda satwa count |
| Popup: Status | `AKTIF` | Per-Polda status |
| Right-Top: Total Personel | `153,500` | National aggregate personel |
| Right-Top: Defense Equipment | `97%` | National readiness percentage |
| Right-Top: Vacant Position | `218` | National vacant positions |
| Bottom-Center: Active Fleet | `300` | National active fleet count |
| Bottom-Center: K9 Standby | `140` | National K9 standby count |
| Bottom-Left: Reports | 5 static lines | `List<SitkamtibmasReport>` |

### 2.4 Polda Model Gap

The current `Polda` model (`lib/models/polda_model.dart`) has only 5 fields:
```dart
id, namaPolda, latitude, longitude, createdAt
```

It has **no fields** for personel count, inventaris, senjata, satwa, or status. These would either need to be added to the model (if the `/api/v1/polda` endpoint returns them) or fetched from a separate per-Polda summary endpoint.

---

## 3. Integration Blueprint

### 3.1 API Endpoint Strategy

Two approaches, depending on what the backend provides:

**Approach A — Enriched `/api/v1/polda` response (preferred)**

If the backend can return summary stats alongside each Polda:

```json
{
  "data": [{
    "id": 1,
    "nama_polda": "Polda Kalimantan Barat",
    "latitude": "-0.0263",
    "longitude": "109.3425",
    "personel_count": 2450,
    "inventaris_count": 1200,
    "senjata_count": 500,
    "satwa_count": 25,
    "status": "AKTIF"
  }]
}
```

**Changes needed:**
1. Add fields to `Polda` model (`lib/models/polda_model.dart`, lines 3–8)
2. Update `Polda.fromJson` to parse new fields
3. Replace hardcoded values in the `AlertDialog` `content` (lines 181–187) with `p.personelCount`, etc.

**Approach B — Separate dashboard summary endpoint**

A new endpoint like `GET /api/v1/dashboard/national` returns aggregates + per-Polda stats:

```json
{
  "aggregates": {
    "total_personel": 153500,
    "defense_equipment_pct": 97,
    "vacant_positions": 218,
    "active_fleet": 300,
    "k9_standby": 140
  },
  "polda_stats": [{
    "polda_id": 1,
    "personel": 2450,
    "inventaris": 1200,
    "senjata": 500,
    "satwa": 25,
    "status": "AKTIF"
  }],
  "sitkamtibmas": [
    {"id": 1, "title": "Laporan 1", "date": "2025-08-01"}
  ]
}
```

**Changes needed:**
1. Create a `DashboardData` model (new file: `lib/models/dashboard_data.dart`)
2. Add `getDashboardData()` method (in `_DashboardPageState`, ~line 31 area)
3. New state variables: `_aggregates`, `_poldaStats`, `_sitkamtibmasReports`
4. Wire all overlay panels to state variables instead of `const` widgets

### 3.2 Injection Points Map

```
┌─────────────────────────────────────────────────────────────────┐
│ _DashboardPageState                                              │
│                                                                  │
│ NEW STATE VARIABLES (add after line 20):                         │
│   DashboardAggregates? _aggregates;                              │
│   Map<int, PoldaStats>? _poldaStats;   // keyed by polda_id     │
│   List<SitkamtibmasReport>? _reports;                            │
│                                                                  │
│ NEW METHOD (add after getPoldaApi, ~line 83):                    │
│   Future<void> getDashboardSummary() async { ... }   ◄── INJECT │
│                                                                  │
│ MODIFY _init() [line 24-29]:                                     │
│   → call getDashboardSummary() after getPoldaApi()   ◄── INJECT │
│                                                                  │
│ MODIFY popup content [lines 181-187]:                            │
│   → replace hardcoded stats with lookup:             ◄── INJECT │
│     final stats = _poldaStats?[p.id];                            │
│     "👮 Personel : ${stats?.personel ?? '-'}"                    │
│                                                                  │
│ MODIFY right-top panel [lines 274-326]:                          │
│   → replace const with _aggregates?.totalPersonel    ◄── INJECT │
│                                                                  │
│ MODIFY bottom-center KPIs [lines 365-377]:                       │
│   → replace "300"/"140" with _aggregates fields      ◄── INJECT │
│                                                                  │
│ MODIFY bottom-left Sitkamtibmas [lines 342-359]:                 │
│   → replace const ListView with dynamic list         ◄── INJECT │
└─────────────────────────────────────────────────────────────────┘
```

### 3.3 Popup `polda_id` Flow (already working)

The popup already receives the `Polda` object directly from the closure:

```dart
onTap: () {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(p.namaPolda),     // ← `p` is in scope
        content: Text("...${p.latitude}..."),
      );
    },
  );
}
```

**The `p.id` is already available inside the popup builder.** No additional plumbing is needed to pass `polda_id` — just use `p.id` for any secondary API call (e.g., fetching detailed stats or navigating to a per-Polda detail page).

### 3.4 Recommended Implementation Order

| Step | File | Effort | Description |
|---|---|---|---|
| 1 | `polda_model.dart` | Small | Add `personelCount`, `inventarisCount`, `senjataCount`, `satwaCount`, `status` fields + `fromJson` parsing |
| 2 | `dashboard.dart` | Small | Replace popup hardcoded values with `p.*` fields from enriched model |
| 3 | `dashboard.dart` | Medium | Create `DashboardAggregates` model, add `getDashboardSummary()`, wire right-top + bottom-center panels |
| 4 | `dashboard.dart` | Medium | Create `SitkamtibmasReport` model, wire bottom-left panel |
| 5 | `dashboard.dart` | Small | Add pull-to-refresh or auto-refresh timer for live data |

### 3.5 No Structural Refactor Required

The current architecture is clean enough that **no widget tree restructuring is needed**. All changes are:
- Adding fields to the existing `Polda` model
- Adding new state variables and a fetch method to `_DashboardPageState`
- Replacing `const` hardcoded strings with state-driven values

The popup trigger chain (`Marker → GestureDetector.onTap → showDialog`) and the `polda_id` capture via closure are already correct and need no changes.
