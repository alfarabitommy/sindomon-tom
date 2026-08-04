# Polres Column Fallback Text Plan

> **Goal:** Change the Polres column fallback text from `"-"` to `"Tidak Ada / Mako Polda"` when `polres_id` is null (personel belongs to Mako Polda).

**Tech Stack:** Flutter / Dart

---

## 1. Audit Findings

**File:** `lib/pages/personel.dart`, lines 403–411

The Polres `DataCell` currently renders as:

```dart
DataCell(
  Text(
    e["nama_polres"]
            ?.toString() ??
        e["polres_id"]
            ?.toString() ??
        "-",
  ),
),
```

**Fallback chain (current):**
1. `e["nama_polres"]` — the denormalized Polres name from the API (preferred)
2. `e["polres_id"]` — the raw foreign key as a fallback
3. `"-"` — final fallback when both above are null

**Problem:** When a personel is assigned to Mako Polda (headquarters), `polres_id` is intentionally `null`, causing the column to display `"-"`. This is not informative — the user should know the personel is assigned to Mako Polda, not just see a dash.

---

## 2. Fix Plan

**File:** `lib/pages/personel.dart`  
**Change:** Line 409 — replace `"-"` with `"Tidak Ada / Mako Polda"`

**Before:**
```dart
DataCell(
  Text(
    e["nama_polres"]
            ?.toString() ??
        e["polres_id"]
            ?.toString() ??
        "-",
  ),
),
```

**After:**
```dart
DataCell(
  Text(
    e["nama_polres"]
            ?.toString() ??
        e["polres_id"]
            ?.toString() ??
        "Tidak Ada / Mako Polda",
  ),
),
```

**Impact:**
- Single-line change, no logic modified
- No new imports or dependencies
- All other columns (Polda, Pangkat, Jabatan) remain unchanged
- When `nama_polres` or `polres_id` have values, behavior is identical

---

## 3. Verification

1. Run the app: `flutter run`
2. Navigate to **Dashboard / Personel**
3. Find a personel with no Polres assignment (Mako Polda)
4. Confirm the Polres column displays **"Tidak Ada / Mako Polda"** instead of `"-"`
5. Confirm personel with Polres assignments still show their actual Polres name
