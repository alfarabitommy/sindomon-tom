# Fixed Viewport / Sticky Layout Refactoring Plan

## Target Files (8 pages, identical structure)
- `lib/screens/personel.dart`
- `lib/screens/polres.dart`
- `lib/screens/polda.dart`
- `lib/screens/inventaris.dart`
- `lib/screens/satwa.dart`
- `lib/screens/report.dart`
- `lib/screens/senjata.dart`
- `lib/screens/user_page.dart`

## Current Structure
```
Row
├── Sidebar (Container, 260px, Color(0xff1E1B4B))
└── Expanded → Content
    └── Padding(EdgeInsets.all(30))
        └── SingleChildScrollView(vertical)           ← REMOVE
            └── Column
                ├── AppHeader(breadcrumb, username, role)
                ├── SizedBox(25)
                ├── Row: title Text + ElevatedButton.icon ("Tambah")
                ├── SizedBox(20)
                ├── AppSearchField(hintText)
                ├── SizedBox(25)
                ├── SizedBox(width: double.infinity)   ← REMOVE (redundant with Exp)
                │   └── Container(                     ← THE FLOATING CARD
                │       │   color: Colors.white,
                │       │   borderRadius: 12,
                │       │   boxShadow: [...]
                │       └── Column(mainAxisSize: min)  ← DROP mainAxisSize: min
                │           ├── Padding(20) > LayoutBuilder
                │           │   └── SingleChildScrollView(horizontal)
                │           │       └── ConstrainedBox(minWidth: constraints.maxWidth)
                │           │           └── DataTable(...)
                │           └── AppPagination()
                ├── SizedBox(20)
                └── AppFooter()
```

## Target Structure
```
Row
├── Sidebar (Container, 260px, Color(0xff1E1B4B))    ← UNCHANGED
└── Expanded → Content
    └── Padding(EdgeInsets.all(30))
        └── Column                                     ← REPLACE SingleChildScrollView
            ├── AppHeader(breadcrumb, username, role)  ← FIXED
            ├── SizedBox(25)
            ├── Row: title Text + ElevatedButton.icon  ← FIXED
            ├── SizedBox(20)
            ├── AppSearchField(hintText)               ← FIXED
            ├── SizedBox(25)
            ├── Expanded                                ← NEW: card fills remaining space
            │   └── Container(                          ← PRESERVED: BoxDecoration intact
            │       │   color: Colors.white,
            │       │   borderRadius: 12,
            │       │   boxShadow: [...]
            │       └── Column                          ← NO mainAxisSize (fills Expanded)
            │           ├── Expanded                    ← NEW: table area scrolls internally
            │           │   └── SingleChildScrollView(vertical)   ← NEW
            │           │       └── Padding(20) > LayoutBuilder
            │           │           └── SingleChildScrollView(horizontal)
            │           │               └── ConstrainedBox(minWidth: constraints.maxWidth)
            │           │                   └── DataTable(...)
            │           └── AppPagination()             ← FIXED at card bottom
            ├── SizedBox(20)
            └── AppFooter()                             ← FIXED at page bottom
```

## Step-by-Step Changes (per file)

### Step 1: Remove outer SingleChildScrollView
Replace:
```dart
child: SingleChildScrollView(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppHeader(...),
```
With:
```dart
child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    AppHeader(...),
```
And remove the closing `)` of `SingleChildScrollView` at the bottom.

### Step 2: Remove SizedBox wrapper around the card
Find the card section:
```dart
SizedBox(
  width: double.infinity,
  child: Container(
```
Remove the `SizedBox(width: double.infinity, child:` line and its closing `)`.

### Step 3: Wrap card in Expanded
```dart
Expanded(                                         // NEW
  child: Container(                                // was step 2, now wrapped
    decoration: BoxDecoration(
      color: Colors.white,
      ...
```

### Step 4: Drop mainAxisSize from card's inner Column
Replace:
```dart
child: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
```
With:
```dart
child: Column(
  children: [
```

### Step 5: Wrap table padding+LayoutBuilder in Expanded + vertical scroll
Replace:
```dart
Padding(
  padding: const EdgeInsets.all(20),
  child: LayoutBuilder(
    builder: (context, constraints) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: DataTable(...)
        ),
      );
    },
  ),
),
```
With:
```dart
Expanded(
  child: SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(...)
            ),
          );
        },
      ),
    ),
  ),
),
```

### Step 6: Close the two new Expanded brackets
- After `AppPagination()`: close the card's Expanded bracket
- After `AppFooter()`: adjust column bracket closure (Step 1 removed the SingleChildScrollView closure)

## Visual Pseudo-Code Tree (after refactoring)

```
Padding(all: 30)
└── Column(cross: start)
    ├── [FIXED] AppHeader
    ├── [FIXED] SizedBox(h: 25)
    ├── [FIXED] Row(title + btn)
    ├── [FIXED] SizedBox(h: 20)
    ├── [FIXED] AppSearchField
    ├── [FIXED] SizedBox(h: 25)
    ├── [EXPAND] Expanded ─────────── fills remaining space ──────────┐
    │   └── Container[white, r:12, shadow]                           │
    │       └── Column                                                │
    │           ├── [EXPAND] Expanded ─ fills rest of card ───┐      │
    │           │   └── SingleChildScrollView(↓)              │      │
    │           │       └── Padding(20)                       │      │
    │           │           └── LayoutBuilder                 │      │
    │           │               └── SingleChildScrollView(→)  │      │
    │           │                   └── ConstrainedBox        │      │
    │           │                       └── DataTable[scroll] │ ◄────┘
    │           └── [FIXED] AppPagination ── always visible ──┘
    ├── [FIXED] SizedBox(h: 20)
    └── [FIXED] AppFooter ──────── always visible ────────────┘
```

## Protection Boundary (NOT touched)
- `AppHeader` widget implementation
- `AppFooter` widget implementation
- `AppPagination` widget implementation
- Container `decoration`: color, borderRadius, boxShadow
- DataTable: headingRowColor, headingTextStyle, dataTextStyle, dividerThickness, border, row heights
- All sidebar code
- All business logic, API calls, data mapping

## Edge Case Validation
| Scenario | Behavior |
|---|---|
| Table has 0 rows | Card fills space, empty scroll area, pagination at bottom |
| Table has many rows | Vertical scroll inside card handles overflow, pagination stays visible |
| Very small screen (e.g. 600px tall) | Expanded shrinks card, header/footer still visible |
| Very wide table (many columns) | Horizontal scroll still works inside vertical scroll |

## Application Strategy
Apply the same 5 structural edits to all 8 files. Each file needs identical changes at the same code locations. Files differ only in: title string, breadcrumb string, hintText string, column definitions, and row data mapping.
