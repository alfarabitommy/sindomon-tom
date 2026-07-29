# DataTable Enterprise Floating Card — Implementation Plan

## Problem

8 data pages share identical layout bug: `Expanded` wraps the `Card`, forcing it to fill all vertical space between search bar and footer. Result: massive white void below sparse tables. Also: harsh typography (pure black), cramped rows (default heights), zero dividers, distorted thumbnails with sharp corners.

## Root Cause

```
Column (content area)
  ├─ AppHeader
  ├─ ... search, title ...
  ├─ Expanded              ← THIS forces Card → full available height
  │  └─ SizedBox → Card
  │     └─ Column
  │        ├─ Expanded     ← Table area takes all Card space
  │        └─ AppPagination
  └─ AppFooter
```

## Target Files

| # | File | Has Images | Columns |
|---|------|-----------|---------|
| 1 | `lib/pages/personel.dart` | No | 5 |
| 2 | `lib/pages/polres.dart` | No | 5 |
| 3 | `lib/pages/polda.dart` | No | 6 |
| 4 | `lib/pages/inventaris.dart` | Yes (asset) | 5 |
| 5 | `lib/pages/satwa.dart` | Yes (asset) | 8 |
| 6 | `lib/pages/report.dart` | Yes (asset) | 5 |
| 7 | `lib/pages/senjata.dart` | Yes (network) | 5 |
| 8 | `lib/pages/user_page.dart` | No | 5 |

## Step-by-Step Implementation (per file, in order)

### Step 1: Layout Fix — Remove the White Void

**Replace** the outer `Expanded` wrapping the Card with a plain `SizedBox` child. Wrap the entire content `Column` in a `SingleChildScrollView` so the page scrolls when table content exceeds viewport.

**Before:**
```dart
Expanded(
  child: Padding(
    padding: const EdgeInsets.all(30),
    child: Column(
      children: [
        const AppHeader(...),
        const SizedBox(height: 25),
        // ... title row, search ...
        const SizedBox(height: 25),
        Expanded(                                          // ← DELETE
          child: SizedBox(
            width: double.infinity,
            child: Card(                                   // ← REPLACE WITH CONTAINER
              elevation: 3,
              shape: RoundedRectangleBorder(...),
              child: Column(
                children: [
                  Expanded(                                // ← CHANGE TO FLEXIBLE
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.vertical,  // ← DELETE
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                child: DataTable(...),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const AppPagination(),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const AppFooter(),
      ],
    ),
  ),
),
```

**After:**
```dart
Expanded(
  child: Padding(
    padding: const EdgeInsets.all(30),
    child: SingleChildScrollView(                          // NEW: page-level scroll
      child: Column(
        children: [
          const AppHeader(...),
          const SizedBox(height: 25),
          // ... title row, search ...
          const SizedBox(height: 25),
          SizedBox(                                         // NO Expanded wrapper
            width: double.infinity,
            child: Container(                               // Floating island card
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,             // Shrink-wrap to content
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(       // Horizontal only
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: DataTable(...),          // Styled in Step 2
                          ),
                        );
                      },
                    ),
                  ),
                  const AppPagination(),                    // Pinned to bottom of Card
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const AppFooter(),
        ],
      ),
    ),
  ),
),
```

**Key changes:**
1. Wrap `Column` children in `SingleChildScrollView` for page-level vertical scroll
2. Remove `Expanded` wrapper around the Card (was forcing height fill)
3. Replace `Card` widget with `Container` + `BoxDecoration` (floating island style)
4. Add `mainAxisSize: MainAxisSize.min` to Card's inner `Column`
5. Remove inner `Expanded` from table area (no longer needed)
6. Remove inner `SingleChildScrollView(vertical)` — page-level scroll handles vertical overflow; horizontal scroll stays for wide tables

### Step 2: DataTable Styling

Add these properties to every `DataTable` in all 8 files:

```dart
DataTable(
  headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
  dividerThickness: 0.5,                                       // NEW
  border: const TableBorder(                                   // NEW: soft divider color
    horizontalInside: BorderSide(
      color: Color(0xFFE5E7EB),
      width: 0.5,
    ),
  ),
  dataRowMinHeight: 60,                                        // NEW
  dataRowMaxHeight: 70,                                        // NEW
  headingTextStyle: const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: Color(0xFF6B7280),                                  // NEW: muted grey
  ),
  dataTextStyle: const TextStyle(                               // NEW
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Color(0xFF374151),                                  // Dark charcoal, not black
  ),
  columns: const [...],
  rows: ...,
)
```

### Step 3: Image Thumbnail Polish

**Files with images:** `inventaris.dart`, `satwa.dart`, `report.dart`, `senjata.dart`

#### inventaris.dart (line ~322)
**Before:**
```dart
DataCell(
  Image.asset(
    "assets/images/rantis.jpg",
    width: 100,
    fit: BoxFit.cover,
  ),
),
```
**After:**
```dart
DataCell(
  ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.asset(
      "assets/images/rantis.jpg",
      width: 80,
      height: 50,
      fit: BoxFit.cover,
    ),
  ),
),
```

#### report.dart (line ~296)
Same pattern as inventaris.dart — identical fix.

#### satwa.dart (line ~348)
**Before:**
```dart
DataCell(
  Padding(
    padding: const EdgeInsets.all(8.0),
    child: Image.asset(
      "assets/images/satwa.jpg",
      width: 100,
      height: 80,
      fit: BoxFit.cover,
    ),
  ),
),
```
**After:**
```dart
DataCell(
  Padding(
    padding: const EdgeInsets.all(8.0),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        "assets/images/satwa.jpg",
        width: 80,
        height: 50,
        fit: BoxFit.cover,
      ),
    ),
  ),
),
```

#### senjata.dart (line ~357) — Network image
**Before:**
```dart
DataCell(
  Image.network(
    e["foto"],
    width: 100,
    fit: BoxFit.cover,
  ),
),
```
**After:**
```dart
DataCell(
  ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.network(
      e["foto"],
      width: 80,
      height: 50,
      fit: BoxFit.cover,
    ),
  ),
),
```

### Step 4: Protection Boundary Checklist

- [ ] Do NOT modify `AppHeader` widget construction
- [ ] Do NOT modify `AppFooter` widget construction
- [ ] Do NOT modify `AppPagination` widget — only its position relative to the Card changes (it becomes a `Column` child naturally at Card bottom)
- [ ] Do NOT touch Sidebar
- [ ] Do NOT touch AppBackground or SafeArea

## Verification

After applying all changes, run:
```bash
cd /home/tommy/dev/sindomon-tom && flutter analyze lib/pages/personel.dart lib/pages/polres.dart lib/pages/polda.dart lib/pages/inventaris.dart lib/pages/satwa.dart lib/pages/report.dart lib/pages/senjata.dart lib/pages/user_page.dart
```

Expected: zero new errors.

Three visual smoke tests:
1. Page with few rows (e.g. fresh DB) — Card shrink-wraps, no white void below table
2. Page with many rows — page scrolls vertically, horizontal scroll works for wide tables
3. Image thumbnails — rounded corners, uniform 80×50, no distortion

## Open Questions

None. Plan is self-contained and covers all 4 requirements from the user specification.
