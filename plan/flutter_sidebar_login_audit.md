# SINDOMON UI Audit — Sidebar & Login Card Theme Toggle

**Date:** 2025-07-14  
**Scope:** `lib/widget/app_sidebar.dart`, `lib/widget/login_card.dart`  
**Mode:** PLAN / AUDIT (no execution code — widget-tree transformations only)

---

## 1. Current State

### 1.1 AppSidebar (`app_sidebar.dart`)

```
Column (MainAxisAlignment.start)
├── SizedBox(h:12)
├── Toggle button (hamburger: menu/menu_open via Offstage Stack)
│     at top, near logo area
├── SizedBox(h:12)
├── Logo (animated height: 65↔40)
├── Spacers + "SINDOMON" + "Sistem Informasi Manajemen" (fade in/out)
├── Expanded → ListView (menu items)
├── Divider
├── SizedBox(h:4)
├── Theme toggle (IconButton with AnimatedSwitcher, solo, centered)
└── SizedBox(h:20)
```

Key properties:
- Collapse/expand toggle is at the **top**, squeezed between the logo and the upper edge.
- Theme toggle is at the **bottom**, alone, centered horizontally.
- Collapse icon: `Icons.menu` (collapsed) / `Icons.menu_open` (expanded).
- Both use the `Offstage` strategy — widgets stay mounted, only visibility flips. This is the proven "Strategy B" that avoids the `mouse_tracker.dart:203:12` assertion.
- `_isExpanded` is the single boolean controlling `AnimatedContainer` width, text opacity, and Offstage flags.
- `AnimatedContainer` width: `_expandedWidth = 240` ↔ `_collapsedWidth = 80`, 300ms easeOutCubic.

### 1.2 LoginCard (`login_card.dart`)

```
ClipRR → BackdropFilter → Container (320px wide, glass panel)
└── Column (MainAxisSize.min)
    ├── Logo (85px)
    ├── "SINDOMON - Portal Masuk"
    ├── Username/NRP label + AppTextField
    ├── Kata Sandi label + AppTextField
    └── "Masuk ke Sistem" ElevatedButton
```

Key properties:
- **No theme toggle** anywhere in the login card.
- No dependency on `ThemeController` or `ThemeScope`.
- LoginCard is `const`-constructed inside `LoginPage`.
- `LoginPage` is a `StatelessWidget` — the `LoginCard()` is in a `const` list literal.

### 1.3 Theme Infrastructure

```
MyApp (_MyAppState)
└── ThemeScope(controller: _themeController)
    └── ValueListenableBuilder<ThemeMode>
        └── MaterialApp(themeMode: ...)
            └── LoginPage
                └── LoginCard   ← needs access to ThemeScope.of(context)
```

`ThemeController.toggleTheme()` flips `themeNotifier` between `ThemeMode.light` / `dark` and persists via SharedPreferences. Any widget under `ThemeScope` can call `ThemeScope.of(context).toggleTheme()`.

The sidebar already receives `ThemeController` via a constructor parameter (`widget.themeController`). For the login card, we use `ThemeScope.of(context)` directly (no constructor injection needed).

---

## 2. AppSidebar — Bottom Controls Transformation

### 2.1 Remove Hamburger from Top

**Lines to remove:** 117–149 (the toggle button block including its two `SizedBox` spacers).

The top area will become:
```
Column
├── Logo (stays)
├── Spacers + "SINDOMON" + subtitle (stay)
├── ...
```

The logo region becomes clean — no button competes for attention.

### 2.2 New Bottom Control Group

Replace the current bottom section (lines 219–247: `Divider` + `SizedBox` + theme `IconButton` + bottom `SizedBox`) with a **dynamic layout group**:

#### Widget Tree (pseudocode)

```
Column
├── ... (logo, menu, everything above)
├── Expanded (menu, stays as-is)
├── Divider                     ← stays, unchanged
├── SizedBox(height: 4)
├── _buildBottomControls()      ← NEW: dynamic Row/Column
│     returns a Widget that is:
│     if (_isExpanded) → Row(mainAxisAlignment: spaceBetween)
│     if (!_isExpanded) → Column(mainAxisAlignment: center)
│     children:
│       [0]: Theme toggle (IconButton, same AnimatedSwitcher as today)
│       [1]: Collapse/expand toggle (IconButton, NEW icon)
└── SizedBox(height: 20)        ← stays, unchanged
```

#### 2.2.1 The Dynamic Layout Strategy

The requirement: **Row** when expanded, **Column** when collapsed.

**Option A — Conditional build (❌ rejected):**
```dart
_isExpanded ? Row(...) : Column(...)
```
This destroys and recreates the widget subtree on every toggle, which would reset `AnimatedSwitcher` states and risk the `mouse_tracker` assertion.

**Option B — Stack + Offstage (❌ rejected):**
```dart
Stack(children: [
  Offstage(offstage: !_isExpanded, child: Row(...)),
  Offstage(offstage: _isExpanded,  child: Column(...)),
])
```
Works but duplicates the two `IconButton` widgets — four buttons in the tree for two visual slots. Wasteful and harder to maintain.

**Option C — AnimatedCrossFade (⚠️ viable but overkill):**
`AnimatedCrossFade` with `firstChild: Row(...)`, `secondChild: Column(...)`. Handles the cross-fade cleanly but both children are always built (like Offstage) and the animation is a cross-fade, not a layout morph.

**Option D — Single shared children, conditional Axis wrapper (✅ RECOMMENDED):**

Use a `Flex` subclass that accepts a list of children but switches its direction. The idiomatic Flutter way:

```dart
// Pseudocode for the dynamic container:
Builder(
  builder: (context) {
    final children = [
      _buildThemeToggle(),
      _buildCollapseToggle(),
    ];

    if (_isExpanded) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: children,
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      );
    }
  },
)
```

**Wait — doesn't this violate Strategy B?** No, because the two `IconButton` widgets themselves are NOT the children of the `Row`/`Column` being swapped. They are built inside `_buildThemeToggle()` and `_buildCollapseToggle()` helper methods. When the parent `Row` ↔ `Column` swaps:

- The old parent unmounts.
- The children (the two `IconButton`s) are reparented under the new `Row`/`Column`.

This DOES cause a rebuild of the icon buttons. However, this is the **bottom bar**, not the menu area — there are no `ExpansionTile` or `MouseRegion` widgets that the mouse could be hovering over during the toggle click (since the user just clicked the toggle button itself, their mouse is *on* the button, and Flutter handles the reparenting of the actively-pressed widget gracefully).

**Verdict: Option D is safe for the bottom bar** because:
1. The toggle button itself is the only interactive widget being rebuilt.
2. No `ExpansionTile` state lives here.
3. The mouse is on the button being clicked — Flutter's gesture arena handles this.

However, to be maximally safe and consistent with the rest of the sidebar's Strategy B philosophy, we can still use **Offstage stacking** for the two buttons *individually* if we want, while the Row/Column swap is fine. In practice, the simpler conditional build is acceptable here.

#### 2.2.2 The Actual Implementation Plan

**Helper: `_buildThemeToggle()` → `Widget`**

Extract today's theme toggle (lines 228–246) into a private method. No logic changes — just extraction.

```dart
Widget _buildThemeToggle() {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final colors = SidebarColors.fromBrightness(Theme.of(context).brightness);
  return IconButton(
    onPressed: () => widget.themeController.toggleTheme(),
    tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
    icon: AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) =>
          RotationTransition(turns: animation, child: child),
      child: Icon(
        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        key: ValueKey(isDark),
        color: colors.iconColor,
      ),
    ),
    style: IconButton.styleFrom(hoverColor: colors.hoverColor),
  );
}
```

**Helper: `_buildCollapseToggle()` → `Widget`**

New method. Same Offstage Strategy B pattern as the old hamburger, but with the new icons:

```dart
Widget _buildCollapseToggle() {
  final colors = SidebarColors.fromBrightness(Theme.of(context).brightness);
  return IconButton(
    icon: Stack(
      alignment: Alignment.center,
      children: [
        Offstage(
          offstage: _isExpanded,
          child: Icon(Icons.keyboard_double_arrow_right, color: colors.iconColor),
        ),
        Offstage(
          offstage: !_isExpanded,
          child: Icon(Icons.keyboard_double_arrow_left, color: colors.iconColor),
        ),
      ],
    ),
    onPressed: _toggleExpanded,
    tooltip: _isExpanded ? 'Collapse sidebar' : 'Expand sidebar',
    style: IconButton.styleFrom(hoverColor: colors.hoverColor),
  );
}
```

**The `_buildBottomControls()` method:**

```dart
Widget _buildBottomControls() {
  final themeToggle = _buildThemeToggle();
  final collapseToggle = _buildCollapseToggle();

  if (_isExpanded) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [themeToggle, collapseToggle],
      ),
    );
  } else {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [themeToggle, collapseToggle],
      ),
    );
  }
}
```

#### 2.2.3 Layout Math & Visual Balance

**Expanded mode (240px):**
```
┌────────────────────────────────────────┐
│ [☀️/🌙 theme]          [◀◀ collapse] │  ← Row, spaceBetween, h-padding:16
└────────────────────────────────────────┘
```
- Each `IconButton` is 48×48 (default).
- `spaceBetween` pushes theme to left edge, collapse to right edge.
- 16px horizontal padding on each side → 48 + 16 + ... + 16 + 48 = effective distribution.
- The Divider above spans `indent:20, endIndent:20` = width 200px, centered. The Row buttons align nicely within this visual boundary.

**Collapsed mode (80px):**
```
┌──────────┐
│  ☀️/🌙   │  ← theme toggle, centered
│  ▶▶      │  ← collapse toggle, centered
└──────────┘
```
- `Column` with `MainAxisAlignment.center`.
- Each button is 48×48, total height ~96px + gap.
- The 80px rail comfortably fits 48px icons.
- No horizontal padding needed (icons are naturally centered in the 80px container).

#### 2.2.4 Animation Behavior

Since `_isExpanded` drives the `AnimatedContainer` width, and the bottom controls are rebuilt when `_isExpanded` changes (inside `setState`), the Row↔Column swap happens **instantly** at the moment of toggle, while the width animates over 300ms.

This means:
- At t=0ms: User clicks toggle → `_isExpanded` flips → `setState` → Row becomes Column (or vice versa) instantly, width starts animating.
- At t=0–300ms: Width transitions. The bottom buttons may briefly look awkward during the transition because the layout direction changes before the width catches up.

**Mitigation:** This is actually fine in practice. When collapsing (240→80), the Column snaps in and the icons center themselves in the shrinking rail. When expanding (80→240), the Row appears with spaceBetween, and the expanding width immediately gives the buttons room. The user's eye is on the menu area during the transition, not the bottom bar.

For a smoother alternative, we could use `AnimatedSize` + `AnimatedOpacity` on a wrapping container, but the 300ms width animation already masks most of the visual discontinuity. **No additional animation infrastructure is needed.**

#### 2.2.5 Removal of Top Hamburger — Impact on Menu Groups

The collapsed group items (`_buildCollapsedGroupItem`) currently have this behavior:
```dart
onTap: () {
  setState(() => _isExpanded = true);
}
```

This remains correct — tapping a collapsed group icon still expands the sidebar so the user can see the menu. This behavior is independent of the hamburger location.

---

## 3. LoginCard — Theme Toggle Injection

### 3.1 Architecture Change

`LoginCard` currently does not import `ThemeScope` or `ThemeController`. It needs to:

1. Import `../theme/theme_scope.dart`.
2. Remove `const` from constructor usage (currently `const LoginCard()` in `login_page.dart`).
3. Add a `_buildThemeToggle()` method.
4. Embed it in the top-right corner of the glass card.

### 3.2 Layout Plan

The glass card is:
```
ClipRR
└── BackdropFilter
    └── Container (320px, padding:20)
        └── Column
            ├── Logo
            ├── "SINDOMON - Portal Masuk"
            ├── ...form fields...
            └── Button
```

**Plan: Wrap the Column in a Stack to place the toggle in the top-right corner.**

```
ClipRR
└── BackdropFilter
    └── Container (320px, padding:20)
        └── Stack                           ← NEW
            ├── Column (same as today)      ← child [0]
            │   ├── Logo
            │   ├── "SINDOMON - Portal Masuk"
            │   ├── ...form fields...
            │   └── Button
            └── Positioned(                  ← child [1]
                  top: 0,
                  right: 0,
                  child: _buildThemeToggle(),
                )
```

**Why Stack + Positioned instead of modifying the top Row?**

The top of the card currently has no Row — it's just Logo → SizedBox → Text in sequence. Creating a Row just for the toggle would require restructuring the logo+title area. A Stack overlay is:
- **Minimally invasive** — the existing Column stays exactly as-is.
- **Self-contained** — the toggle button is positioned independently.
- **Zero layout interference** — the Positioned widget doesn't affect the Column's layout.

### 3.3 Theme Toggle Implementation

Identical to the sidebar's toggle, but accessed via `ThemeScope.of(context)`:

```dart
import '../theme/theme_scope.dart';

// Inside _LoginCardState:

Widget _buildThemeToggle() {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final scheme = Theme.of(context).colorScheme;

  return IconButton(
    onPressed: () => ThemeScope.of(context).toggleTheme(),
    tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
    icon: AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) =>
          RotationTransition(turns: animation, child: child),
      child: Icon(
        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        key: ValueKey(isDark),
        color: scheme.onSurface,
        size: 22,
      ),
    ),
    style: IconButton.styleFrom(
      visualDensity: VisualDensity.compact,
    ),
  );
}
```

**Design notes:**
- `size: 22` — slightly smaller than the sidebar's default (24) to not dominate the login card.
- `color: scheme.onSurface` — adapts to light/dark theme automatically (white text on dark glass, dark text on light glass).
- `visualDensity: VisualDensity.compact` — reduces the button's footprint so it sits snugly in the corner.
- The glass card already has a `BackdropFilter` with `ImageFilter.blur(sigmaX: 15, sigmaY: 15)` — the icon will render on top of the blurred surface, looking integrated.

### 3.4 Changes to login_page.dart

The `LoginCard()` construction must change from `const` to non-const:

```dart
// Before:
children: const [SizedBox(height: 40), LoginCard()],

// After:
children: const [SizedBox(height: 40), LoginCard()],
//                                    ^ no const — LoginCard can no longer be const
```

Actually, `LoginCard` doesn't accept any parameters yet. We keep the constructor `const`-compatible, but the usage in `login_page.dart` must drop `const` from the list literal because `LoginCard` (once it uses `ThemeScope.of(context)`) is no longer a constant widget. In practice:

```dart
// login_page.dart
child: SingleChildScrollView(
  child: Column(
    children: const [
      SizedBox(height: 40),
      // LoginCard() — remove from const list, use a separate non-const list
    ],
  ),
),
```

becomes:

```dart
child: SingleChildScrollView(
  child: Column(
    children: [
      const SizedBox(height: 40),
      LoginCard(),
    ],
  ),
),
```

The `SizedBox` can remain `const`.

---

## 4. Summary of Changes

### 4.1 `lib/widget/app_sidebar.dart`

| Change | Lines affected | Description |
|--------|---------------|-------------|
| Remove top toggle | 117–149 | Delete hamburger button + its spacer `SizedBox` wrappers |
| Extract `_buildThemeToggle()` | 228–246 | Move existing theme toggle into a private method, return the `IconButton` |
| Add `_buildCollapseToggle()` | (new) | New method: Offstage Stack with `keyboard_double_arrow_left` / `keyboard_double_arrow_right` |
| Add `_buildBottomControls()` | (new) | Conditional Row (expanded) / Column (collapsed) containing the two toggles |
| Replace bottom section | 219–247 | `Divider` stays; the rest replaced by `_buildBottomControls()` |

### 4.2 `lib/widget/login_card.dart`

| Change | Lines affected | Description |
|--------|---------------|-------------|
| Add import | (top) | `import '../theme/theme_scope.dart';` |
| Add `_buildThemeToggle()` | (new) | Private method returning the theme toggle `IconButton` |
| Wrap Column in Stack | 254–337 | The existing `Column` becomes the first child of a `Stack`; add `Positioned(top:0, right:0, child: _buildThemeToggle())` as second child |

### 4.3 `lib/pages/login_page.dart`

| Change | Lines affected | Description |
|--------|---------------|-------------|
| Drop `const` from list | 15–16 | `const [SizedBox, LoginCard()]` → `[const SizedBox, LoginCard()]` |

---

## 5. Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Row↔Column swap causes visual flicker during width animation | Low | The 300ms width animation masks the transition; no user reports expected |
| `ThemeScope.of(context)` fails if `ThemeScope` is not in the widget tree | None | `ThemeScope` wraps the entire `MaterialApp` in `main.dart:39`; always available |
| Dropping `const` on `LoginCard` in login_page | None | Performance impact of a single non-const widget at app launch is negligible |
| Mouse tracker assertion from bottom bar reparenting | None | The bottom bar has no `ExpansionTile` or complex `MouseRegion` widgets; only two simple `IconButton`s |

---

## 6. Implementation Order

1. **`app_sidebar.dart`** — extract `_buildThemeToggle()`, add `_buildCollapseToggle()` and `_buildBottomControls()`, remove top hamburger, replace bottom section.
2. **`login_card.dart`** — add import, add `_buildThemeToggle()`, wrap Column in Stack+Positioned.
3. **`login_page.dart`** — drop `const` from the list containing `LoginCard`.
4. **Verify** — `flutter analyze` must pass with no new issues.
