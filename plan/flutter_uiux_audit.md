# SINDOMON — Flutter UI/UX Audit & Design System Specification

> **Audit scope:** `lib/theme/`, `lib/widget/`, `lib/utils/`, global layout  
> **Audit date:** 2026-03-17  
> **Version:** Ground-truth extraction from the current codebase — no speculative additions.

---

## 1. Design System & Theming

### 1.1 Theme Architecture

The app supports exactly **two** named themes, toggled at runtime via `ThemeController` and persisted to `SharedPreferences` under key `"theme_mode"`.

| Key | Label | Base Brightness |
|-----|-------|-----------------|
| `ThemeMode.light` | **"Clean Corporate"** | `Brightness.light` |
| `ThemeMode.dark` | **"J.A.R.V.I.S Cyberpunk"** | `Brightness.dark` |

**Wiring path:**  
`main.dart` → `ThemeScope` (InheritedWidget) → `ValueListenableBuilder<ThemeMode>` → `MaterialApp(theme:, darkTheme:, themeMode:)`

Toggle is available from:
- **Login page:** compact `IconButton` in the top-right corner of `LoginCard` (rotation-animated sun/moon icon, 22px)
- **Sidebar:** `IconButton` in the bottom control cluster (rotation-animated sun/moon icon, theme-aware color)

**Theme swap animation:** The `AnimatedSwitcher` with `RotationTransition` (300 ms) on the theme icon only. The rest of the UI rebuilds reactively — there is no crossfade on the background or content.

---

### 1.2 Light Mode — "Clean Corporate"

**Description:** Crisp white/slate surfaces, indigo primary, gold secondary.

#### Color Palette

| Token | HEX | Usage |
|-------|-----|-------|
| `brandIndigo` | `#1E1B4B` | Primary (buttons, selected menu bg, app identity) |
| `brandGold` | `#F6B300` | Secondary accent (amber badges, pagination active) |
| `surface` | `#FFFFFF` | Card/surface background |
| `onSurface` | `#1E293B` (slate-800) | Primary body text |
| `onSurfaceVariant` | *(system default)* | Hint/secondary text |
| `error` | `#DC2626` (red-600) | Error borders, error messages |
| `onError` | `#FFFFFF` | Text on error backgrounds |
| `outline` | `#CBD5E1` (slate-300) | Text field enabled borders |
| `outlineVariant` | `#E2E8F0` (slate-200) | Dividers, pagination border |
| `surfaceContainerHighest` | `#F1F5F9` (slate-100) | Search field fill, elevated containers |
| `dividerColor` | `#000000` @ 8% alpha | Subtle dividers |

#### Light Sidebar Colors

| Token | HEX |
|-------|-----|
| `background` | `#FFFFFF` (crisp white) |
| `textPrimary` | `#1E293B` (slate-800) |
| `textSecondary` | `#64748B` (slate-500) |
| `iconColor` | `#475569` (slate-600) |
| `selectedBg` | `#1E1B4B` (brand indigo) |
| `selectedText` | `#FFFFFF` |
| `hoverColor` | `#000000` @ 4% alpha |
| `shadowColor` | `#000000` @ 12% alpha (`Colors.black12`) |

#### Light Background Gradient (AppBackground)

| Stop | HEX |
|------|-----|
| 0% | `#F8FCFF` (icy white) |
| 50% | `#E8F4FB` (frost blue-white) |
| 100% | `#D2E8F5` (pale cyan-blue) |

Gradient type: `LinearGradient` (top → bottom)

#### Light Circuit Watermark Palette (CyberCircuitPainter)

| Element | Color | Opacity |
|---------|-------|---------|
| Nano traces | `#94A3B8` (slate-400) | 6% |
| Mid traces | `#64748B` (slate-500) | 8% |
| Bus traces | `#64748B` (slate-500) | 7% |
| Major traces | `#475569` (slate-600) | 12% |
| Crosshairs | `#94A3B8` (slate-400) | 8% |
| Vias | `#475569` (slate-600) | 14% |
| Ring labels | `#94A3B8` (slate-400) | 10% |
| Chip fill | `#00E5FF` (jarvis cyan) | 14% |
| Chip stroke | `#00E5FF` (jarvis cyan) | 20% |
| Labels | `#00E5FF` (jarvis cyan) | 18% |
| **Chip glow** | *Disabled* (light mode) | — |

---

### 1.3 Dark Mode — "J.A.R.V.I.S Cyberpunk"

**Description:** Deep void surfaces, cyan primary glow, gold/amber highlights.

#### Color Palette

| Token | HEX | Usage |
|-------|-----|-------|
| `primary` | `#00E5FF` (jarvis cyan) | Primary accent, HUD elements |
| `onPrimary` | `#00222B` | Text on cyan backgrounds |
| `secondary` | `#F6B300` (brand gold) | Secondary accent |
| `onSecondary` | `#1E1B4B` (brand indigo) | Text on gold backgrounds |
| `surface` | `#12142A` (void indigo) | Card/surface background |
| `onSurface` | `#E2E8F0` (slate-200) | Primary body text |
| `error` | `#EF4444` (red-500) | Error borders, error messages |
| `onError` | `#FFFFFF` | Text on error backgrounds |
| `outline` | `#2A2E4A` | Text field enabled borders |
| `outlineVariant` | `#1E2238` | Dividers, pagination border |
| `surfaceContainerHighest` | `#1A1E38` | Search field fill, elevated containers |
| `dividerColor` | `#FFFFFF` @ 8% alpha | Subtle dividers |

#### Dark Sidebar Colors

| Token | HEX |
|-------|-----|
| `background` | `#0F0B2E` (deep void indigo) |
| `textPrimary` | `#FFFFFF` |
| `textSecondary` | `#FFFFFF` @ 54% alpha (`Colors.white54`) |
| `iconColor` | `#FFFFFF` @ 70% alpha (`Colors.white70`) |
| `selectedBg` | `#F6B300` (brand gold) |
| `selectedText` | `#0F0B2E` (dark text on gold) |
| `hoverColor` | `#FFFFFF` @ 10% alpha (`Colors.white10`) |
| `shadowColor` | `#000000` @ 38% alpha (`Colors.black38`) |

#### Dark Background Gradient (AppBackground)

| Stop | HEX |
|------|-----|
| Center (TL) | `#1B1240` (deep void purple) |
| Mid | `#0F0B2E` (dark indigo) |
| Edge | `#070A1F` (near-black navy) |

Gradient type: `RadialGradient` (center: top-left, radius: 1.6)

#### Dark Circuit Watermark Palette (CyberCircuitPainter)

| Element | Color | Opacity |
|---------|-------|---------|
| Nano traces | `#00E5FF` (jarvis cyan) | 6% |
| Mid traces | `#00E5FF` (jarvis cyan) | 8% |
| Bus traces | `#00E5FF` (jarvis cyan) | 7% |
| Major traces | `#00E5FF` (jarvis cyan) | 13% |
| Crosshairs | `#00E5FF` (jarvis cyan) | 8% |
| Vias | `#00E5FF` (jarvis cyan) | 14% |
| Ring labels | `#00E5FF` (jarvis cyan) | 10% |
| Chip fill | `#F6B300` (brand gold) | 10% |
| Chip stroke | `#F6B300` (brand gold) | 16% |
| Labels | `#00E5FF` (jarvis cyan) | 16% |
| **Chip glow** | *Enabled* (2px `MaskFilter.blur`, gold chips only) | — |

---

### 1.4 Typography

| Property | Value |
|----------|-------|
| **Font family** | `Barlow Semi Condensed` (via `google_fonts` package) |
| **Text theme** | `GoogleFonts.barlowSemiCondensedTextTheme().apply(bodyColor:, displayColor:, decorationColor:)` |
| **Material version** | Material 3 (`useMaterial3: true`) |

#### Type Scale Observed in Code

| Usage | Size | Weight | Letter Spacing |
|-------|------|--------|----------------|
| Sidebar "SINDOMON" title | `26px` | `bold` (w700) | `1.5px` |
| Sidebar subtitle | `13px` | `normal` (w400) | — |
| Page breadcrumb (AppHeader) | `16px` | `w600` | — |
| Login title "Portal Masuk" | `22px` | `w800` | — |
| Login field labels | `14px` | `w600` | — |
| Login subtitle/error | `14px` | `normal` (w400) | — |
| Footer text | `13px` | `normal` / `bold` | — |
| Tooltip text | `12px` | `w600` | — |
| HUD label "MEMUAT..." | `12px` | `w600` | `2px` |
| Menu group label | `14px` | `w600` | — |
| Child menu item | `13px` | `w500` / `bold` | — |
| Drilldown row label | `14px` | `normal` | `0.5px` |
| Drilldown row value | `16px` | `bold` | — (+ `tabularFigures`) |
| HUD title bar | `15px` | `bold` | `1.2px` |

---

## 2. Global Component Library

### 2.1 `AppScaffold`

**Role:** Authenticated-page root scaffold. Every page after login uses this.

**Structure:**
```
Scaffold(body: AppBackground [zero-asset procedural background])
  └─ SafeArea
       └─ Row
            ├─ AppSidebar (left, push-content: 80px ↔ 240px)
            └─ Expanded (right, fills remaining space)
                 ├─ Padding: 30px all sides (when `showHeaderFooter: true`)
                 │    └─ Column
                 │         ├─ AppHeader (65px height)
                 │         ├─ Expanded (page content via `child` prop)
                 │         └─ AppFooter
                 └─ OR bare `child` (when `showHeaderFooter: false` — Command Center map)
```

**Props:**
| Prop | Type | Required | Notes |
|------|------|----------|-------|
| `currentRoute` | `String` | Yes | Matched against sidebar menu `routeName` for selected highlight |
| `child` | `Widget` | Yes | Page body content |
| `breadcrumb` | `String?` | No | Shown in AppHeader, e.g. `"Dashboard / Personel"` |
| `showHeaderFooter` | `bool` | No | Default `true`; set `false` for full-bleed content (Command Center map) |

**State:** Loads `username_login` and `roleid_login` from `SharedPreferences` on `initState`, passes to `AppHeader`.

---

### 2.2 `AppSidebar`

**Role:** Collapsible role-based navigation rail/panel.

#### Dimensional Constants

| Property | Value |
|----------|-------|
| Collapsed width | `80px` |
| Expanded width | `240px` |
| Width animation duration | `300ms` |
| Width animation curve | `Curves.easeOutCubic` |
| Text fade duration | `200ms` |
| Text fade curve | `Interval(0.5, 1.0, curve: Curves.easeOutCubic)` |
| Border radius (right corners) | `25px` |
| Shadow blur radius | `20px` |
| Shadow offset | `(5, 0)` |

#### Expanded State (240px)

- Logo: 90px height (scales down from 55px collapsed)
- Brand text "SINDOMON" visible (26px bold, letter-spaced)
- Subtitle "Sistem Informasi Manajemen" visible (13px)
- Menu items show icons + labels
- Selected leaf items show trailing `Icons.arrow_forward_ios` (14px)
- Menu groups render as `ExpansionTile` (persistent internal state)
- Content padding on leaf items: `16px` horizontal
- Bottom controls: **Row** with theme toggle + collapse toggle (space-between)

#### Collapsed State (80px)

- Logo: 55px height
- Brand text: hidden (`AnimatedOpacity` → 0)
- Menu labels: hidden (`AnimatedOpacity` → 0)
- Trailing arrows: hidden (`Offstage`)
- Menu groups: render as icon-only `GestureDetector` (48px tap target) — tapping **expands** the sidebar
- Content padding on leaf items: `20px` horizontal (centers the 40px icon slot in 80px rail)
- Bottom controls: **Column** with theme + collapse stacked vertically
- Group `ExpansionTile` is **never unmounted** — it sits `Offstage` beside the icon-only hit target

#### Selection Highlight

- Selected item: background animates to `selectedBg` color over 200ms
- Selected item: icon + text switch to `selectedText` color
- Selected item border radius: `14px` (`RoundedRectangleBorder`)

#### State Management

- Role loaded from `SharedPreferences("roleid_login")` independently
- Fallback if role unknown: `commonTopItems` (Dashboard only)
- Uses **Strategy B (Offstage Preservation)**: all expanded/collapsed widget variants are permanently mounted; `Offstage(offstage:)` toggles visibility — prevents `mouse_tracker.dart:203:12` assertion on hover-dispose races

#### Bottom Controls

| Element | Expanded Layout | Collapsed Layout |
|---------|----------------|------------------|
| Theme toggle | `IconButton` (sun/moon, rotation-animated, 300ms) | Same |
| Collapse toggle | `IconButton` (double-arrow left/right) | Same |

---

### 2.3 `AppBackground`

**Role:** Full-screen, **code-generated** background (zero asset images).

**Architecture:**
```
Container(gradient: isDark ? _darkGradient : _lightGradient)
  └─ CustomPaint(painter: CyberCircuitPainter)
       └─ child (actual content)
```

#### Gradients (see §1.2 & §1.3)

#### `CyberCircuitPainter` Key Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `stepSize` | `90.0` | Anchor grid spacing in logical pixels |
| `density` | `0.50` | Probability a grid point becomes an anchor |
| `jitter` | `25.0` | Max random anchor offset in pixels |
| `chamferSize` | `8.0` | 45° chamfer length at trace corners |
| `busSpacing` | `5.0` | Perpendicular pitch between parallel bus lanes |
| `maxBusLanes` | `3` | Max parallel data-bus lane count |
| `seed` | `0x504342` ("PCB") | Fixed xorshift32 PRNG seed — layout is deterministic |

**Element metrics:** via radius 2.0px, ring radius 3.5px, chip size 7.0px (corner radius 2.0px), crosshair arm 3.0px.

**Trace tiers (rendered bottom→top):**
1. Nano traces (0.5px stroke) — distance ≤ 160px
2. Mid traces (1.0px stroke) — all anchor pairs
3. Bus lane traces (0.8px stroke) — 30% chance
4. Major data arteries (1.5px stroke) — distance ≥ 350px

**Ornament probabilities:** bus chance 30%, crosshair 30%, empty-cell label 8%, chip label 20%.

**Performance:** All geometry pre-generated once per `(Size, Brightness, tuning)` tuple and cached in static map; `shouldRepaint` only on brightness change or resize. No per-frame PRNG, no per-frame text layout.

---

### 2.4 `GlassSurface`

**Role:** Theme-aware frosted glass container — the single source of truth for panel surfaces.

#### Dark Mode

| Property | Value |
|----------|-------|
| Background | `ColorScheme.surface` @ 75% alpha |
| Border | `white` @ 10% alpha, 1px |
| Border radius | Default `12px` (configurable) |
| Shadow | **None** (omitted — muddy on transparent surfaces) |
| BackdropFilter | **None** (no blur pass on dark mode) |

#### Light Mode

| Property | Value |
|----------|-------|
| Background | `ColorScheme.surface` @ 80% alpha |
| Border | `white` @ 35% alpha, 1px |
| Border radius | Default `12px` (configurable) |
| Shadow | `black` @ 6% alpha, blur 12px, offset (0, 4) |
| BackdropFilter | `ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0)` — true frosted glass |

**Note:** `GlassSurface` is **declared** but its usage is minimal in the current codebase. Most pages use raw `Container` with theme-aware colors from `ColorScheme`. The `LoginCard` has its own inline glass effect with blur σ=15, surface at 15% alpha.

---

### 2.5 `LoginCard`

**Role:** Login form with blur-glass container (inline, not via `GlassSurface`).

| Property | Value |
|----------|-------|
| Container width | `320px` |
| Padding | `20px` all sides |
| Border radius | `6px` |
| Surface color | `ColorScheme.surface` @ 15% alpha |
| Border | `ColorScheme.outline` @ 40% alpha, 1px |
| BackdropFilter | `ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0)` |
| Logo height | `95px` |
| Button width | `double.infinity`, height `45px` |
| Button color | `#F6B300` (brand gold) |
| Button text color | `black` |
| Button border radius | `30px` (pill shape) |

**Error handling:** See §4.

---

### 2.6 `ActionButtons`

**Role:** Ghost icon buttons (edit/delete) for data table rows.

#### Visual States

| State | Edit Icon | Delete Icon |
|-------|-----------|-------------|
| **Default** | `Icons.edit_outlined`, 20px, `Colors.grey.shade400` | `Icons.delete_outlined`, 20px, `Colors.grey.shade400` |
| **Hover** | Icon → `Colors.blue`; background → `Colors.blue` @ 8% alpha | Icon → `Colors.red`; background → `Colors.red` @ 8% alpha |

#### Parameters

| Property | Value |
|----------|-------|
| Gap between buttons | `4px` |
| Container shape | `RoundedRectangleBorder(8px)` |
| Splash radius | `18px` |
| Visual density | `compact` |
| Hover trigger | `MouseRegion` → `_isHovered` state flag |

---

### 2.7 `AppSearchField`

**Role:** Theme-aware search text field.

| Property | Value |
|----------|-------|
| Fill color | `ColorScheme.surfaceContainerHighest` |
| Hint style | `ColorScheme.onSurfaceVariant`, 14px |
| Prefix icon | `Icons.search`, 20px, `ColorScheme.onSurfaceVariant` |
| Border radius | `6px` |
| Enabled border | `BorderSide.none` |
| Focused border | `ColorScheme.onSurfaceVariant`, 1px solid |
| Content padding | `horizontal: 16px, vertical: 14px` |

---

### 2.8 `AppHeader`

**Role:** Page header bar (breadcrumb + user info + profile dropdown).

| Property | Value |
|----------|-------|
| Height | `65px` |
| Horizontal padding | `24px` |
| Border radius | `12px` |
| Background | `ColorScheme.surface` |
| Shadow (Dark) | `black` @ 30% alpha, blur 12px, offset (0, 4) |
| Shadow (Light) | `black` @ 6% alpha, blur 12px, offset (0, 4) |
| Home icon container | `Colors.amber` @ 20% alpha, 10px radius, `Icons.home_rounded` 22px |
| Breadcrumb font | 16px, w600, `ColorScheme.onSurface` |
| User avatar | `CircleAvatar` radius 18px, `Colors.amber` background, black person icon |
| Avatar border | 1.5px, `Colors.grey.shade300`(light) / `Colors.grey.shade700`(dark) |
| Username font | 13px, bold |
| Role label font | 11px, `ColorScheme.onSurfaceVariant` |
| Dropdown offset | `Offset(0, 50)` |
| Dropdown items | "Pengaturan" (→ `AccountSettingPage`), "Logout" (→ `clearSessionAndLogout`) |

---

### 2.9 `AppFooter`

| Property | Value |
|----------|-------|
| Padding | `horizontal: 20px, vertical: 14px` |
| Layout | Row: copyright left, version right |
| Text color (Light) | `#6B7280` (slate-500) |
| Text color (Dark) | `#94A3B8` (slate-400) |
| Font size | `13px` |
| Version text | `"v1.0.0"` bold |

---

### 2.10 `AppPagination`

| Property | Value |
|----------|-------|
| Container border | Top: `ColorScheme.outlineVariant`, 0.5px |
| Page button size | `36×36px` |
| Active page bg | `Colors.amber` |
| Active page text | `black`, 13px, w600 |
| Inactive page border | `ColorScheme.outlineVariant`, 1px |
| Inactive page text | `ColorScheme.onSurfaceVariant`, 13px |
| Border radius | `6px` |
| Ellipsis text | `"..."`, 13px, `ColorScheme.onSurfaceVariant` |
| Display text format | "Menampilkan X hingga Y dari Z data" |
| Visible pages logic | ≤ 7 pages: show all; > 7 pages: 1, last, current ± 1 |

---

### 2.11 `PlaceholderPage`

**Role:** "Under construction" stub for unbuilt features.

- Icon: `Icons.construction_rounded`, 80px, `Colors.amber.shade700`
- Title: 28px bold, `#1E1B4B`
- Subtitle: "Fitur dalam pengembangan", 16px, `Colors.grey.shade600`
- Uses `AppScaffold` with `showHeaderFooter: false`

---

## 3. Micro-interactions & Animations

### 3.1 `HudLoadingSpinner` — "Arc Reactor" HUD Spinner

**Architecture:** A single `AnimationController` drives two counter-rotating painted layers on a `CustomPainter` + a static glowing core.

#### Controller Parameters

| Parameter | Value |
|-----------|-------|
| Duration | `2000ms` (one full cycle) |
| Repeat | `.repeat()` (seamless loop) |
| Mode | `.repeat()` / `.stop()` toggled via `animate` prop |
| Ticker | `SingleTickerProviderStateMixin` |

#### Animation Specs

| Layer | Tween | Rotation | Notes |
|-------|-------|----------|-------|
| **Outer dashed ring** | `0 → 2π` (clockwise) | Forward | 24 dashes, each sweep = `(2π/24) × 0.55` = ~14.3° per dash, 55% fill |
| **Inner solid arc** | `0 → -2π` (counter-clockwise) | Reversed | 270° sweep (90° gap), starts at 135° (down-left) |

#### Visual Specs

| Element | Value |
|---------|-------|
| Default diameter | `80px` |
| Outer stroke width | `2.5px` |
| Inner stroke width | `3.0px` |
| Stroke cap | `StrokeCap.round` |
| Color (all layers) | `Colors.cyanAccent` |

#### Glowing Core (Layer 3 — no `MaskFilter`, Impeller-compatible)

| Layer | Radius (× coreRadius) | Alpha |
|-------|----------------------|-------|
| Outer glow 1 | `r × 4.0` | 8% |
| Outer glow 2 | `r × 2.5` | 15% |
| Outer glow 3 | `r × 1.4` | 30% |
| Solid core | `r × 1.0` | 100% |

Core radius: `max(3.5px, spinnerDiameter × 0.12)`

#### Label (optional)

| Property | Value |
|----------|-------|
| Font size | `12px` (configurable via `labelSize`) |
| Font weight | `w600` |
| Letter spacing | `2px` |
| Color | `Colors.cyanAccent` |
| Gap above label | `12px` |

---

### 3.2 `_HudMarker` — Pulsating Radar Map Marker

**Location:** `lib/pages/dashboard.dart` (private, Command Center only)

**Description:** Two staggered expanding cyan pulse rings, a static crosshair, and a glowing core dot — all rendered in an 80×80px hit target.

#### Controller Parameters

| Parameter | Value |
|-----------|-------|
| Duration | `1500ms` |
| Repeat | `.repeat()` |

#### Primary Ring Animation

| Property | Tween | Curve |
|----------|-------|-------|
| Scale | `1.0 → 2.5` | `Curves.easeOut` (full cycle) |
| Opacity | `0.7 → 0.0` | `Curves.easeOut` (full cycle) |

#### Staggered Secondary Ring Animation

| Property | Tween | Curve |
|----------|-------|-------|
| Scale | `1.0 → 2.5` | `Interval(0.4, 1.0, curve: Curves.easeOut)` — rests at scale 1.0 for first 40% of cycle |
| Opacity | `0.5 → 0.0` | `Interval(0.4, 1.0, curve: Curves.easeOut)` |

#### Static Elements

| Element | Size | Color |
|---------|------|-------|
| Pulse ring (shared widget) | `20×20px` circle, border 1.5px | `Colors.cyanAccent` |
| Crosshair arms | 4 arms, `8px` long, `1px` thick, positioned at center of 80×80 box | `Colors.cyanAccent` @ 50% alpha |
| Glowing core dot | `10×10px` circle | `Colors.cyanAccent`, boxShadow: cyan @ 90% alpha, blur 10px, spread 2px |

---

### 3.3 `_HudMarqueeText` — Auto-scrolling Text

**Location:** `lib/pages/dashboard.dart` (private, HUD drilldown panel title bar)

**Behavior:**
1. Render text statically inside a measured container
2. Post-frame: measure text width via `TextPainter` vs container width via `RenderBox`
3. If text fits → render static `Text` widget (no animation)
4. If text overflows → after a **1500ms pause**, start seamless scroll loop

#### Scroll Loop Parameters

| Parameter | Value |
|-----------|-------|
| Pause before scroll | `1500ms` (`Timer`) |
| Total distance per cycle | `textWidth + 40px` (40px gap between copies) |
| Cycle duration | `(totalWidth / 30) × 1000` ms, clamped to `[1500, 12000]` |
| Scroll speed | ~30 px/s |
| Loop mechanism | Two side-by-side copies of text in a `Row`, translated by `AnimationController(0→1, linear)` via `Transform.translate` |
| Seamless wrap | When controller resets 1.0→0.0, second copy occupies first copy's exact start position |
| Clipping | `ClipRect` constrains the visible area |

---

### 3.4 Sidebar Expand/Collapse

| Property | Value |
|----------|-------|
| Width transition | `AnimatedContainer`, 300ms, `Curves.easeOutCubic` |
| Text/label fade | `AnimatedOpacity`, 200ms, `Interval(0.5, 1.0, curve: Curves.easeOutCubic)` |
| Logo height | `AnimatedContainer`: 90px → 55px |
| Spacer compaction | `AnimatedContainer` height shrinks proportionally |
| Menu item selection bg | `AnimatedContainer`, 200ms |

---

### 3.5 Theme Toggle Icon

| Property | Value |
|----------|-------|
| Widget | `AnimatedSwitcher` with `RotationTransition` |
| Duration | `300ms` |
| Icon (Dark mode) | `Icons.light_mode_rounded` |
| Icon (Light mode) | `Icons.dark_mode_rounded` |
| Key | `ValueKey(isDark)` for proper swap animation |

---

### 3.6 `ActionButtons` Hover

| Property | Value |
|----------|-------|
| Trigger | `MouseRegion` → `onEnter`/`onExit` → `setState(_isHovered)` |
| Transition | Instant (no tween — direct color swap) |

---

### 3.7 `AppPagination` Active/Inactive

| Property | Value |
|----------|-------|
| Transition | Instant (no animation on page change) |
| Visual feedback | `InkWell` ripple on tap (built-in Material) |

---

## 4. Error Handling & Feedback UX

### 4.1 SnackBar Feedback System

SnackBars are the primary user-facing feedback mechanism for CRUD operations and validation. They all use `SnackBarBehavior.floating` with `borderRadius: 8px`.

#### Color-Coded Severity Levels

| Severity | SnackBar Background | Icon | Usage |
|----------|---------------------|------|-------|
| **Success** | `Colors.green` | No icon (inline text only) | Delete success, save success |
| **Error (Critical)** | `Colors.red` (`#EF4444` in login; `Colors.red` elsewhere) | `Icons.error_outline` white 20px (login only) | Login failure, delete failure, network error |
| **Warning/Validation** | `Colors.orange` | No icon | Form validation, partial failures |
| **Info** | *(Not observed in codebase)* | — | — |

#### SnackBar Patterns Observed

**Pattern A — Login validation (rich, with icon row):**
```dart
SnackBar(
  content: Row([
    Icon(Icons.error_outline, color: Colors.white, size: 20),
    SizedBox(width: 8),
    Expanded(Text("message")),
  ]),
  behavior: SnackBarBehavior.floating,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  backgroundColor: Color(0xFFEF4444), // red-500
)
```

**Pattern B — CRUD results (simple, no icon):**
```dart
SnackBar(
  content: Text("message"),
  backgroundColor: Colors.green,
)
```

**Pattern C — Network/catch errors:**
```dart
SnackBar(
  content: Text("Terjadi kesalahan jaringan"),
  backgroundColor: Colors.red,
)
```

### 4.2 Text Field Error States

**`AppTextField` (login form):**

| State | Border | Width |
|-------|--------|-------|
| **Normal (enabled)** | `ColorScheme.outline` | `1.2px` |
| **Focused** | `ColorScheme.outline` | `2px` |
| **Error (enabled)** | `Colors.red` | `1.2px` |
| **Error (focused)** | `Colors.red` | `2px` |
| **Error border** | `Colors.red` | `2px` |
| **Focused error border** | `Colors.red` | `2px` |

**Error state is controlled by a boolean `error` prop** — no built-in validation, caller toggles it.
- Auto-clear: error flags reset to `false` when user types (listener on both controllers calls `_clearErrorOnInput`).

**`AppSearchField`:** No error state. Focused border uses `ColorScheme.onSurfaceVariant` @ 1px.

### 4.3 HUD Loading Overlay

**Location:** `lib/utils/hud_loading.dart`

| Property | Value |
|----------|-------|
| Barrier color | `Colors.black54` (50% black) |
| Barrier dismissible | `false` (blocks all interaction) |
| Back button | Blocked (`PopScope(canPop: false)`) |
| Root navigator | Yes (`useRootNavigator: true`) |
| Spinner size | `80px` |
| Default label | `"MEMUAT..."` |
| Dismiss safety | `hide()` wrapped in try/catch — no-op if overlay absent |
| Material type | `MaterialType.transparency` |

**Usage pattern:** Every delete/save operation follows the same sequence:
```
HudLoading.show(context, label: "MENGHAPUS...")
  → await API call
  → HudLoading.hide(context)
  → show SnackBar (success/failure)
  (catch: HudLoading.hide + show error SnackBar)
```

### 4.4 API Error Dialogs

**403 Forbidden (login):**
Full `AlertDialog` with title "Akses Diblokir", device-verification message, and "Tutup" button.

**Other errors (login):**
Falls through to generic SnackBar "Kredensial tidak valid" — same message for wrong credentials and network failures.

**Drilldown panel error (Command Center map):**
HUD-styled inline error state inside the glass panel:
- `Icons.error_outline`, 36px, cyan
- "GAGAL MEMUAT" (14px, cyan, letter-spaced 2px)
- "Periksa koneksi atau hubungi administrator." (12px, white38)
- No `SnackBar` — error is contained within the panel

### 4.5 Delete Confirmation

Every entity page shows a standard `AlertDialog` before delete:
- Title: entity name (e.g., "Hapus Personel")
- Content: "Apakah Anda yakin ingin menghapus data [entity] ini?"
- Actions: "Batal" (TextButton), "Ya, Hapus" (TextButton, red)

On confirm → `HudLoading.show` → API DELETE → `HudLoading.hide` → success/error SnackBar → refresh list.

### 4.6 Data Table Empty/Loading States

| State | Rendering |
|-------|-----------|
| **Loading** | `Center(child: HudLoadingSpinner(size: 50))` |
| **Error** | `Center(child: Text(errorMessage))` — plain text, no icon |
| **Empty** | *(Not explicitly handled — falls through to empty DataTable)* |

---

## 5. Summary: Key Design Tokens Quick Reference

### Brand Colors (both themes)

| Token | HEX | Role |
|-------|-----|------|
| `brandIndigo` | `#1E1B4B` | Primary in light; onSecondary in dark |
| `brandGold` | `#F6B300` | Secondary accent; login button; selected sidebar item in dark |
| `jarvisCyan` | `#00E5FF` | Primary in dark; circuit traces; HUD elements; cyanAccent throughout |

### Semantic Feedback Colors

| Level | HEX | Context |
|-------|-----|---------|
| Error text border | `#DC2626` (red-600) / `#EF4444` (red-500 dark) | Theme colorScheme.error |
| Error SnackBar | `Colors.red` | Delete failure, network error |
| Warning SnackBar | `Colors.orange` | Validation, partial failures |
| Success SnackBar | `Colors.green` | Successful save/delete |
| Login error SnackBar | `#EF4444` | Credential validation |

### Spacing System

| Context | Value |
|---------|-------|
| Page padding (AppScaffold) | `30px` all sides |
| Card border radius (header) | `12px` |
| GlassSurface default radius | `12px` |
| Sidebar border radius (right) | `25px` |
| Menu item radius | `14px` |
| Search field radius | `6px` |
| Text field radius | `6px` |
| SnackBar radius | `8px` |
| Login card radius | `6px` |
| Login button radius | `30px` (pill) |
| Tooltip radius | `6px` |
| Popup menu radius | `12px` |

### Animation Duration Constants

| Element | Duration | Curve |
|---------|----------|-------|
| Sidebar width | `300ms` | `easeOutCubic` |
| Sidebar text fade | `200ms` | `Interval(0.5, 1.0, easeOutCubic)` |
| Sidebar selection bg | `200ms` | (AnimatedContainer default) |
| Theme toggle icon | `300ms` | `RotationTransition` |
| HUD spinner cycle | `2000ms` | Linear (outer CW, inner CCW) |
| Map marker pulse | `1500ms` | `easeOut` (ring 1), `Interval(0.4, 1.0, easeOut)` (ring 2) |
| Marquee pause | `1500ms` | — |
| Marquee scroll speed | ~30 px/s | Linear |
| Tooltip wait | `300ms` | — |
| Login search debounce | `400ms` | — |
