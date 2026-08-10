# FlutterMap HUD Camera Bounds Audit

**Date:** 2025-07-21  
**File:** `lib/pages/dashboard.dart`  
**Issue:** "World Wrap" — when zooming out completely, the Earth duplicates horizontally, scattering HUD markers across multiple "Indonesias".

---

## 1. Current `MapOptions` (lines 196–199)

```dart
options: const MapOptions(
  initialCenter: LatLng(-2.5, 118.0),
  initialZoom: 4.3,
),
```

| Property         | Value                  | Status                         |
|------------------|------------------------|--------------------------------|
| `initialCenter`  | `LatLng(-2.5, 118.0)`  | ✅ Centered on Indonesia        |
| `initialZoom`    | `4.3`                  | ✅ Reasonable starting zoom     |
| `minZoom`        | **not set**            | ❌ User can zoom out to level 0 |
| `maxZoom`        | **not set**            | ⚠️ Acceptable, but could cap    |
| `cameraConstraint` | **not set**          | ❌ No pan/zoom bounds at all    |

**Version:** `flutter_map: ^8.3.1` (resolved to `8.3.1`), `latlong2: ^0.9.1`

**No existing usage** of `CameraConstraint`, `maxBounds`, or `cameraConstraint` anywhere in `lib/`.

---

## 2. Planned Camera Constraint — `CameraConstraint.contain`

In `flutter_map` 8.x, the legacy `maxBounds` is replaced by:

```dart
cameraConstraint: CameraConstraint.contain(bounds: LatLngBounds(...))
```

`CameraConstraint.contain` enforces that the given `LatLngBounds` are **always fully visible** in the viewport. It implicitly constrains both **pan** (no scrolling past the edges) and **zoom** (no zooming out beyond where the bounds fit).

---

## 3. Indonesia Bounding Box Coordinates

| Corner   | Region                 | Latitude | Longitude |
|----------|------------------------|----------|-----------|
| NW       | Sabang (Aceh)          | 6.0° N   | 95.0° E   |
| SE       | Merauke / Rote Island  | -11.0° S | 141.0° E  |

Span: ~17° latitude × ~46° longitude — comfortably covers all Polda markers from Sabang to Merauke.

### `LatLngBounds` construction (latlong2 0.9.x):

```dart
const LatLngBounds(
  LatLng(-11.0, 95.0),   // southwest-ish corner
  LatLng(6.0, 141.0),    // northeast-ish corner
)
```

> **Note:** `LatLngBounds` in `latlong2` automatically normalizes the two corners — order does not matter.

---

## 4. Planned `minZoom`

Even with `CameraConstraint.contain`, adding an explicit `minZoom` is a belt-and-suspenders safeguard:

```dart
minZoom: 4.0,
```

At zoom level 0–3, the entire globe fits multiple times in the viewport, which is exactly the "world wrap" trigger. `minZoom: 4.0` keeps the viewport zoomed close enough to Indonesia that duplicate worlds never appear, while still allowing the user to see the full archipelago.

---

## 5. Final Code Snippet (targeted replacement)

**Current** (lines 196–199):

```dart
options: const MapOptions(
  initialCenter: LatLng(-2.5, 118.0),
  initialZoom: 4.3,
),
```

**Planned replacement:**

```dart
options: const MapOptions(
  initialCenter: LatLng(-2.5, 118.0),
  initialZoom: 4.3,
  minZoom: 4.0,
  cameraConstraint: CameraConstraint.contain(
    bounds: LatLngBounds(
      LatLng(-11.0, 95.0),
      LatLng(6.0, 141.0),
    ),
  ),
),
```

### Required imports (already present):

| Import                                | Provides                        |
|---------------------------------------|---------------------------------|
| `package:flutter_map/flutter_map.dart`  | `MapOptions`, `CameraConstraint` |
| `package:latlong2/latlong.dart`         | `LatLng`, `LatLngBounds`         |

Both are already imported at lines 10–11. **No new imports needed.**

---

## 6. Edge Cases & Considerations

1. **`const` compatibility:** `MapOptions` with `cameraConstraint` can remain `const` because `LatLngBounds` and `CameraConstraint.contain` are all `const`-constructible. ✅

2. **Small viewports (windowed mode on desktop):** `CameraConstraint.contain` adapts to viewport size at runtime — a smaller window means less room for the bounds, so the minimum zoom rises automatically. No extra work needed.

3. **Polda markers near the edges:** The bounding box extends well past the actual marker locations (Sabang ≈ 5.9°N 95.3°E, Merauke ≈ -8.5°S 140.4°E), giving ~2–2.5° buffer on all sides.

4. **Zoom-to-fit on initial load:** With `initialZoom: 4.3` and the contain constraint, the map opens showing the full Indonesian archipelago without world-wrap — the constraint is immediately active.

5. **No impact on non-Command-Center roles:** The `FlutterMap` widget only renders when `_roleId == "3"` (line 157). Other roles see a placeholder and are unaffected.

---

## 7. Verification Checklist

- [ ] Build and run → Command Center map loads centered on Indonesia
- [ ] Zoom out fully (pinch/scroll) → stops at the constraint, no world duplication
- [ ] Pan in all directions → stops at the bounding edges, no white space or lost map
- [ ] Resize the window → constraint recalculates correctly
- [ ] Verify markers for all Polda are reachable and not clipped by the bounds
