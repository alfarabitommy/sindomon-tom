# Flutter Sidebar Animation Audit

**Date:** 2025-07-14  
**Auditor:** Reasonix (Senior Flutter Auditor)  
**Mode:** DEBUG / PLAN (no code changes)

---

## 1. Executive Summary

We are refactoring the static 260px `AppSidebar` into a **collapsible Navigation Rail** that is **80px collapsed (icons only)** and **240px expanded (icons + text)**. The expanded state is triggered by mouse hover and overlays the main content with a **glassmorphism effect** (backdrop blur).

This document audits the current widget tree, identifies every touchpoint, and proposes a concrete architectural plan.

---

## 2. Current State: `AppSidebar` (`lib/widget/app_sidebar.dart`)

### 2.1 Widget Class

- **Type:** `StatefulWidget` → `_AppSidebarState`
- **Constructor:** takes `currentRoute: String` (used to highlight the active item)
- **State fields today:**
  - `_roleId` (String?) — loaded from SharedPreferences
  - `_loaded` (bool) — whether prefs have resolved
  - **No hover/expansion state exists yet.**

### 2.2 Root Widget

```dart
Container(
  width: 260,                        // ← HARDCODED fixed width
  decoration: BoxDecoration(
    color: Color(0xff1E1B4B),        // Solid dark indigo
    borderRadius: BorderRadius.only(
      topRight: Radius.circular(25),
      bottomRight: Radius.circular(25),
    ),
    boxShadow: [...],                // Drop shadow on the right edge
  ),
  child: Column(children: [...]),
)
```

**Key observations:**
- The `Container` is a fixed `width: 260` — this is the PRIMARY target for animation.
- The background is a **solid color** (`0xff1E1B4B`). We will replace this with a semi-transparent + `BackdropFilter` for glassmorphism.
- `BorderRadius` only on the right side (pill shape on the right edge). This should be preserved.
- There is already a `boxShadow` — we may keep or tweak it to complement the glass effect.

### 2.3 Internal Layout

```
Column
 ├─ SizedBox(height: 35)
 ├─ Image.asset("polri-logo.png", height: 65)     ← logo (needs to shrink/hide in 80px mode)
 ├─ SizedBox(height: 15)
 ├─ Text("SINDOMON", fontSize: 26)                 ← title (needs to hide in 80px mode)
 ├─ SizedBox(height: 5)
 ├─ Text("Sistem Informasi Manajemen", ...)         ← subtitle (needs to hide in 80px mode)
 ├─ SizedBox(height: 30)
 ├─ Expanded
 │   └─ ListView (padding: horizontal 12)
 │       └─ _buildMenuItems()
 │           ├─ _buildLeafItem(LeafMenuItem)        ← ListTile(leading: Icon, title: Text)
 │           └─ _buildGroupItem(MenuGroup)          ← ExpansionTile(leading: Icon, title: Text)
 └─ SizedBox(height: 20)
```

### 2.4 Menu Item Rendering

**Leaf items** (`_buildLeafItem`):
- Uses `ListTile` with `leading: Icon` and `title: Text`
- Already wrapped in an `AnimatedContainer` (200ms) for the selection highlight
- Has `hoverColor: Colors.white10` on the `ListTile`

**Group items** (`_buildGroupItem`):
- Uses `ExpansionTile` with `leading: Icon` and `title: Text`
- Children are rendered via `_buildChildItem` → also `ListTile`

**Decision point for icons-only mode:**
- `ListTile.leading` (Icon) stays visible in both modes
- `ListTile.title` (Text) needs `AnimatedOpacity` or conditional rendering based on `isExpanded`
- `ExpansionTile.title` same treatment
- The header logo/title text needs the same opacity gating

### 2.5 Existing Animations

The individual leaf items already use `AnimatedContainer(duration: 200ms)` for the selection background color transition. This is a minor detail — we can keep it or refactor it into the larger animation system.

---

## 3. Current State: Parent Layout (All 22 Pages)

### 3.1 The Pattern

Every authenticated page follows this identical structure:

```dart
Scaffold(
  body: AppBackground(                          // Stack with background image
    imagePath: 'assets/images/wp-putih-mabes.png',
    child: SafeArea(
      child: Row(                               // ← THE ROW
        children: [
          const AppSidebar(currentRoute: "X"),   // 260px fixed sidebar
          Expanded(                              // content fills remaining space
            child: Padding(
              padding: EdgeInsets.all(30),
              child: Column(children: [...]),    // AppHeader, DataTable, etc.
            ),
          ),
        ],
      ),
    ),
  ),
)
```

### 3.2 Page Inventory (22 pages × identical layout)

| Page | Route |
|---|---|
| `personel.dart` | `personel` |
| `senjata.dart` | `senjata` |
| `satwa.dart` | `satwa` |
| `amunisi.dart` | `ammo_stock` |
| `sarpras.dart` | `sarpras` |
| `inventaris.dart` | `inventaris` |
| `polda.dart` | `polda` |
| `polres.dart` | `polres` |
| `user_page.dart` | `pengguna` |
| `master_kategori_senjata.dart` | `kategori_senjata` |
| `dashboard.dart` | `dashboard` |
| `placeholder_page.dart` | (dynamic) |
| `pangaturan.dart` | `pengaturan` |
| `add_personel_page.dart` | (add form) |
| `add_senjata.dart` | (add form) |
| `add_satwa.dart` | (add form) |
| `add_amunisi.dart` | (add form) |
| `add_sarpras.dart` | (add form) |
| `add_inventaris_page.dart` | (add form) |
| `add_polda.dart` | (add form) |
| `add_polres.dart` | (add form) |
| `add_user.dart` | (add form) |

### 3.3 `AppBackground` (`lib/widget/background.dart`)

```dart
class AppBackground extends StatelessWidget {
  final Widget child;
  final String imagePath;
  // ...
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: Image.asset(imagePath, fit: BoxFit.cover)),
        child,   // ← the Row (sidebar + content)
      ],
    );
  }
}
```

Already a `Stack` — this is good. The glassmorphism `BackdropFilter` can live either inside `AppSidebar` itself or in the parent `Stack`.

---

## 4. Architectural Plan

### 4.1 High-Level Strategy

**Change the parent layout from `Row` to `Stack`:**

```
┌─────────────────────────────────────────────────────┐
│ AppBackground (Stack)                               │
│  ┌──────────────────────────────────────────────┐   │
│  │ Background Image (Positioned.fill)            │   │
│  └──────────────────────────────────────────────┘   │
│  ┌──┐ ┌────────────────────────────────────────┐   │
│  │ S│ │ Content Area                            │   │
│  │ i│ │ (Positioned.fill, margin left: 80)      │   │
│  │ d│ │                                          │   │
│  │ e│ │  AppHeader / DataTable / ...             │   │
│  │ b│ │                                          │   │
│  │ a│ └────────────────────────────────────────┘   │
│  │ r│                                              │
│  └──┘                                              │
│   ↑                                                │
│   Sidebar (Positioned left:0, animated 80↔240)     │
│   with BackdropFilter glassmorphism                 │
└─────────────────────────────────────────────────────┘
```

**When collapsed (80px):** Content has a 80px left margin — sidebar sits in that margin showing only icons. No overlap.

**When expanded (240px):** Sidebar grows to 240px and **overlays** the first 160px of content. The glassmorphism blur ensures the content underneath is still visible but the sidebar text is readable.

### 4.2 Option A: Refactor Each Page (22 files) — NOT RECOMMENDED

Changing the `Row` to a `Stack` in all 22 pages is tedious, error-prone, and creates a maintenance nightmare. This approach is **rejected**.

### 4.3 Option B: Create a `AppScaffold` Wrapper — RECOMMENDED ✅

Introduce a **single shared layout widget** that encapsulates the sidebar + content relationship. All 22 pages then use `AppScaffold` instead of manually composing `Row`/`Stack`.

```dart
// NEW FILE: lib/widget/app_scaffold.dart

class AppScaffold extends StatefulWidget {
  final String currentRoute;
  final String imagePath;
  final Widget child;              // the page content
  // ... optional: breadcrumb, username, role for AppHeader

  const AppScaffold({
    super.key,
    required this.currentRoute,
    required this.imagePath,
    required this.child,
  });
  // ...
}
```

**Benefits:**
- **One place** to define the `Stack`/`AnimatedPositioned`/`BackdropFilter` layout
- Each page becomes: `AppScaffold(currentRoute: "personel", child: _buildContent())`
- Future layout changes are trivial
- The sidebar hover state can live here or be lifted up

**Migration plan:**
1. Create `AppScaffold`
2. Replace the `Row` boilerplate in all 22 pages (mechanical, safe find-and-replace)
3. Remove the manual `AppHeader` calls from pages (can be absorbed into `AppScaffold`)

### 4.4 Sidebar Animation Mechanics

#### New State (`_AppSidebarState`)

```dart
bool _isExpanded = false;   // controlled by MouseRegion onEnter/onExit
```

#### Animated Width

Replace `Container(width: 260)` with:

```dart
AnimatedContainer(
  duration: Duration(milliseconds: 300),
  curve: Curves.easeOutCubic,
  width: _isExpanded ? 240 : 80,
  // ...
)
```

#### Glassmorphism Background

Replace `color: Color(0xff1E1B4B)` with:

```dart
ClipRRect(
  borderRadius: BorderRadius.only(
    topRight: Radius.circular(25),
    bottomRight: Radius.circular(25),
  ),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
    child: Container(
      decoration: BoxDecoration(
        color: Color(0xff1E1B4B).withOpacity(0.85),
        borderRadius: ...,
      ),
      child: Column(...),
    ),
  ),
)
```

**Note:** `BackdropFilter` requires the widget to be in a `Stack` where the content it should blur is *behind* it in the paint order. This is satisfied by the `Stack` in `AppScaffold`.

#### Hover Detection

Wrap the entire sidebar in `MouseRegion`:

```dart
MouseRegion(
  onEnter: (_) => setState(() => _isExpanded = true),
  onExit: (_) => setState(() => _isExpanded = false),
  child: AnimatedContainer(...),
)
```

#### Text Visibility

For the logo text, subtitle, and menu item labels, use `AnimatedOpacity`:

```dart
AnimatedOpacity(
  duration: Duration(milliseconds: 200),
  opacity: _isExpanded ? 1.0 : 0.0,
  child: Text("SINDOMON", ...),
)
```

For menu items, the `ListTile.title` can be wrapped similarly. The `ListTile.leading` (Icon) stays visible always.

#### Collapsed Mode Considerations (80px)

- **Logo:** Shrink to ~48px or keep at 65px but center it (it's 65px, fits in 80px)
- **SINDOMON text + subtitle:** `AnimatedOpacity(opacity: 0)` when collapsed
- **Menu leaf items:** `ListTile` with `AnimatedOpacity` on `title`; `leading` icon always visible; center the icon by removing `contentPadding` or adjusting alignment
- **Menu group items:** `ExpansionTile` needs special handling — in collapsed mode, clicking the icon should expand the group in a **popup/overlay** rather than inline (or we could disable expansion in collapsed mode and require the user to hover-expand first)
- **Selected state indicator:** The amber background highlight still works in collapsed mode (just around the icon area)

#### ExpansionTile in Collapsed Mode

This is the trickiest UX question. Options:
1. **Disable expansion in collapsed mode** — clicking a group icon does nothing; user must hover to expand sidebar first, then expand the group.
2. **Show a popup menu** on click — the group's children appear in a floating dropdown anchored to the icon.
3. **Auto-expand sidebar** on group click — when user clicks a group icon in collapsed mode, the sidebar auto-expands and opens the group.

**Recommendation:** Option 1 is simplest and most predictable. Option 3 is the best UX and can be implemented by setting `_isExpanded = true` on group tap when collapsed.

### 4.5 Proposed File Changes Summary

| File | Action | Effort |
|---|---|---|
| `lib/widget/app_scaffold.dart` | **NEW** — shared layout wrapper with Stack + animated sidebar | Medium |
| `lib/widget/app_sidebar.dart` | **REFACTOR** — add hover state, AnimatedContainer, BackdropFilter, AnimatedOpacity | High |
| `lib/pages/*.dart` (22 files) | **SIMPLIFY** — replace `Row` boilerplate with `AppScaffold` | Low (mechanical) |
| `lib/widget/app_header.dart` | **Optional** — absorb into `AppScaffold` to reduce duplication | Low |

### 4.6 Risks & Mitigations

| Risk | Mitigation |
|---|---|
| `BackdropFilter` is GPU-intensive | Use `sigmaX/Y: 8-12` (moderate blur); it only runs during the hover expansion transition; acceptable for desktop |
| `ExpansionTile` state loss on rebuild | `ExpansionTile` manages its own state internally; the animated width change triggers a rebuild but the tile state persists |
| Menu flicker during animation | Use `AnimatedContainer` + `AnimatedOpacity` with synchronized durations (both 300ms, same curve) |
| Scrolling in 80px mode | `ListView` with horizontal padding 12 → reduce to 4-6px in collapsed; ensure tap targets remain ≥48px |
| 22-page migration breaks something | Mechanical change: find `Row(children: [const AppSidebar(` → replace with `AppScaffold(currentRoute:` — review diff carefully before commit |

---

## 5. Detailed Implementation Sequence

### Step 1: Create `AppScaffold`

- Extract the `Stack` layout pattern
- Accept `currentRoute`, `imagePath`, and `child`
- Optionally accept header data (`breadcrumb`, `username`, `role`)
- Use `AnimatedPadding` or `margin` on the content to create the 80px gutter

### Step 2: Refactor `AppSidebar`

- Add `_isExpanded` state + `MouseRegion`
- Change `Container` → `AnimatedContainer(width: ...)`
- Add `ClipRRect` + `BackdropFilter` wrapper
- Wrap text elements in `AnimatedOpacity`
- Handle `ExpansionTile` interaction in collapsed mode (Option 3: auto-expand)

### Step 3: Migrate Pages

- Replace the `Row` pattern in all 22 pages
- Test page-by-page

### Step 4: Polish

- Tune animation curves (`easeOutCubic` feels premium)
- Test with all three roles (Super Admin has ExpansionTile groups; Command Center has a single leaf item)
- Verify the glassmorphism looks correct over light backgrounds (the content area has a white/light theme)
- Ensure the 80px collapsed sidebar doesn't clip the POLRI logo

---

## 6. Key Code Anchors (Current State)

| What | File | Line(s) |
|---|---|---|
| Sidebar root `Container(width: 260)` | `lib/widget/app_sidebar.dart` | 61-63 |
| `_buildLeafItem` (ListTile) | `lib/widget/app_sidebar.dart` | 133-163 |
| `_buildGroupItem` (ExpansionTile) | `lib/widget/app_sidebar.dart` | 166-195 |
| Parent `Row` layout pattern | `lib/pages/personel.dart` (example) | 205-210 |
| `LeafMenuItem` / `MenuGroup` models | `lib/config/menu_config.dart` | 14-38 |
| `AppBackground` (Stack) | `lib/widget/background.dart` | 10-18 |
| Role menu definitions | `lib/config/menu_config.dart` | 62-269 |

---

## 7. Conclusion

The current architecture is **well-prepared** for this refactor:
- `AppSidebar` is already a `StatefulWidget` — adding hover state is trivial
- Individual items already use `AnimatedContainer` — the animation idiom is familiar
- The `AppBackground` is already a `Stack` — glassmorphism fits naturally
- All pages share an identical layout pattern — a single `AppScaffold` wrapper can absorb the complexity

**Recommended approach:** Option B (`AppScaffold` wrapper) — one new file, one refactored file, 22 mechanical page simplifications. Total estimated effort: 2-3 hours of focused work.
