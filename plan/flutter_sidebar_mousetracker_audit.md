# Flutter Sidebar — MouseTracker Crash Deep-Dive Audit

**Date:** 2025-07-14
**Auditor:** Reasonix (Senior Flutter Auditor)
**Mode:** DEBUG / PLAN (no code changes)

---

## 1. The Exact Crash Chain

The sidebar's `_buildMenuItems()` (line 213) conditionally renders groups:

```dart
widgets.add(
  _isExpanded ? _buildGroupItem(item) : _buildCollapsedGroupItem(item),
);
```

When the sidebar is collapsed (80px), **every `MenuGroup`** is rendered via
`_buildCollapsedGroupItem`. That method returns a `Padding` wrapping a
`ListTile` with `hoverColor: Colors.white10` (line 353).

Here's the exact sequence that triggers `mouse_tracker.dart:203:12`:

```
Frame N (collapsed, 80px rail)
  ┌─ Mouse pointer enters the collapsed group's ListTile bounding box
  │  → ListTile's internal InkResponse creates a MouseRegion
  │  → MouseRegion registers annotation with the global MouseTracker
  │  → MouseTracker.onEnter → InkResponse shows hover highlight (White10)
  │
  │  User clicks (tap-down → tap-up)
  │  → onTap fires (line 355)
  │  → Future.delayed(Duration.zero) schedules the setState for
  │    the next microtask
  │
  ├─ Microtask fires
  │  → setState: _isExpanded = true; _expandedGroups.add(group.label)
  │  → Full sidebar rebuild
  │
Frame N+1 (expanded, 240px rail)
  ┌─ Ternary flips: _buildCollapsedGroupItem → _buildGroupItem
  │  → OLD: ListTile Element is unmounted
  │  → OLD: ListTile's RenderObject (with InkResponse + MouseRegion)
  │     is detached from the render tree
  │  → CRITICAL: the disposed MouseRegion's annotation is still
  │     resident in MouseTracker._lastAnnotations
  │  → NEW: ExpansionTile Element is mounted
  │  → NEW: ExpansionTile's internal MouseRegion registers fresh
  │
  ├─ Mouse moves (even 1px) or next frame's pointer update
  │  → MouseTracker._updateWithEvent() iterates _lastAnnotations
  │  → Encounters the dangling annotation from the disposed ListTile
  │  → FLUTTER ASSERT: '!_debugDuringDeviceUpdate' is not true
  │  → mouse_tracker.dart:203:12
  └─ UI freezes with cascading assertion failures
```

### Why `Future.delayed(Duration.zero)` doesn't fix it

The delay defers `setState` by one microtask. The tap gesture pipeline
completes *before* that microtask fires, which is good — the synchronous
`onTap` handler doesn't trigger a rebuild while the gesture arena is still
tracking the pointer. But the delay does **nothing** to clean up the
`MouseTracker` annotation for the disposed `ListTile`. The annotation
persists across frames because:

- The mouse **never left** the region — it's still at the same screen
  coordinates after the rebuild
- `MouseTracker` only removes annotations in response to `MouseRegion`
  disposal or `onExit` events — neither happens cleanly when a widget is
  torn down mid-hover by a `setState` rebuild

The `ValueKey('collapsed_${label}')` / `ValueKey('expanded_${label}')`
correctly signals to Flutter that these are different widgets (preventing an
attempt to `updateRenderObject` across incompatible types), but it does not
control the `MouseTracker` annotation lifecycle.

---

## 2. The Four `hoverColor` / MouseRegion Sources in the File

| # | Line | Widget | Conditional swap? | MouseTracker risk? |
|---|---|---|---|---|
| 1 | 122 | `IconButton(hoverColor: White10)` — hamburger toggle | No — same widget, just width animates | ✅ Safe |
| 2 | 256 | `_buildLeafItem` → `ListTile(hoverColor: White10)` | No — leaf items always render the same widget tree | ✅ Safe |
| 3 | **353** | **`_buildCollapsedGroupItem` → `ListTile(hoverColor: White10)`** | **Yes — swapped with `_buildGroupItem(ExpansionTile)` when `_isExpanded` flips** | **🔥 CRASH** |
| 4 | 396 | `_buildChildItem` → `ListTile(hoverColor: White10)` | No — children only exist inside `ExpansionTile` (only when expanded) | ✅ Safe |

**Only one widget is the problem:** the `ListTile` inside
`_buildCollapsedGroupItem`, created at line 335, destroyed when
`_isExpanded` flips from `false` → `true`.

---

## 3. Option Analysis

### Option A — `hoverColor: Colors.transparent` on the collapsed ListTile

> Completely disable hover effects on the collapsed group item.

**Verdict: INEFFECTIVE.** `ListTile` internally creates an `InkResponse` (or
`InkWell`) regardless of the `hoverColor` value. The `InkResponse` always
registers a `MouseRegion` with the `MouseTracker` to detect enter/exit for
the splash animation. Setting `hoverColor: Colors.transparent` only makes
the visual highlight invisible — the `MouseRegion` still exists, still
registers with the tracker, and still dangles on disposal.

### Option B — Stack overlay: render both widgets simultaneously

> Both `_buildCollapsedGroupItem` and `_buildGroupItem` exist permanently
> in the tree; `AnimatedOpacity` + `IgnorePointer` toggle visibility.

**Verdict: TOO COMPLEX (but would work).** This prevents the dispose
entirely — the `ListTile` is never removed, only hidden. However:

- Every group permanently has TWO widget subtrees → ~2× widget count for
  menus. For 10 groups that's 10 extra `ListTile`/`ExpansionTile` pairs
  — not a performance problem for a sidebar, but architecturally messy.
- The `ExpansionTile` rendered at 80px width overflows (leading icon +
  title + trailing arrow don't fit), generating `RenderFlex` overflow
  warnings on every frame while it's "invisible." Requires extra
  `ClipRect`/`OverflowBox` wrappers to suppress.
- The expanded `AnimatedContainer` width animation (80↔240) would affect
  the "hidden" widget's layout mid-animation, potentially causing jank
  in the `Stack`'s size calculation.

### Option C — Replace `ListTile` with raw `GestureDetector`

> In the collapsed state, don't use a `ListTile` at all. Use a plain
> `GestureDetector` (which uses `Listener`/`RenderPointerListener` — zero
> `MouseRegion`, zero `MouseTracker` involvement).

**Verdict: ✅ RECOMMENDED.**

`GestureDetector` detects taps via the raw pointer event pipeline
(`HitTestBehavior` + `PointerDownEvent`/`PointerUpEvent`). It creates a
`RawGestureDetector` → `Listener` → `RenderPointerListener`. None of these
widgets register with `MouseTracker`.

When the collapsed `GestureDetector` is swapped for the expanded
`ExpansionTile`:
- The old `GestureDetector` is disposed — no `MouseTracker` annotation
  to leak.
- The new `ExpansionTile` creates its own `MouseRegion`(s) which register
  with the tracker cleanly — new annotations are always welcome.

**Trade-off:** Hover feedback on the collapsed group icon is lost (no
splash, no highlight). This is acceptable because:
- The collapsed 80px rail is intentionally minimal — icon-only, no text,
  no interaction chrome.
- Hover feedback returns the moment the rail expands (the `ExpansionTile`
  has full `ListTile` hover behavior).
- The hamburger toggle could be given a brief tooltip-style instruction
  ("⋮ Tap to expand") to compensate — but that's cosmetic polish,
  not part of the structural fix.

### Option D (Auditor's alternative) — `Listener` with manual pointer tracking

> Use a raw `Listener` widget and track `onPointerDown`/`onPointerUp`
> manually for tap detection, plus `onPointerEnter`/`onPointerHover` for
> hover styling via `setState`.

**Verdict: OVERKILL.** Option C is simpler and sufficient. Manual pointer
tracking is only worth the complexity if we absolutely need collapsed-state
hover feedback, which the specs do not require.

---

## 4. Recommended Fix — Exact Plan

### 4.1 Replace `_buildCollapsedGroupItem` entirely

Replace the `ListTile`-based implementation (lines 329–370) with a
`GestureDetector`-based version:

```dart
/// Collapsed-mode (80px) rendering of a group: icon only, centered.
/// Uses a raw GestureDetector (not a ListTile/InkWell) so there is no
/// MouseRegion to leak when the widget is swapped for an ExpansionTile
/// on expand — avoids the known mouse_tracker.dart:203:12 crash.
Widget _buildCollapsedGroupItem(MenuGroup group) {
  return Padding(
    key: ValueKey('collapsed_${group.label}'),
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = true;
          _expandedGroups.add(group.label);
        });
      },
      child: Center(
        // 48px minimum height matches ListTile's tap-target size so the
        // layout footprint in the menu list is identical.
        child: SizedBox(
          height: 48,
          child: Center(
            child: Icon(group.icon, color: Colors.white70),
          ),
        ),
      ),
    ),
  );
}
```

**Key differences from the current code:**

| Aspect | Old (ListTile) | New (GestureDetector) |
|---|---|---|
| Tap detection | `ListTile.onTap` → `Future.delayed(...)` → `setState` | `GestureDetector.onTap` → `setState` (synchronous — safe!) |
| MouseTracker | ✅ `MouseRegion` registered via `InkResponse` | ❌ No `MouseRegion` — `GestureDetector` uses raw `Listener` |
| Hover highlight | `hoverColor: Colors.white10` splash | None (acceptable for 80px icon-only rail) |
| Icon centring | `ListTile.leading` slot (40px) + `contentPadding` math | `Center` + `SizedBox(height: 48, child: Center(...))` — identical visual result |
| Vertical footprint | `ListTile` intrinsic height (~48px) | `SizedBox(height: 48)` — rigid, same as expanded group's collapsed state |
| `Future.delayed` | Required (tried to dodge the crash) | **Removed** — not needed; no `MouseRegion` to worry about |
| `ValueKey` | `collapsed_${label}` | Kept — clean reconciliation when switching directions |

### 4.2 Remove `Future.delayed`

The `Future.delayed(Duration.zero, ...)` wrapper in `onTap` is no longer
necessary and should be removed. `GestureDetector.onTap` fires after the
pointer-up event is processed by the gesture arena — synchronously calling
`setState` at that point is safe because:

1. The gesture arena has already resolved the tap.
2. No `MouseRegion` annotations exist to leak on disposal.
3. The new `ExpansionTile`'s `MouseRegion` will register in the next frame
   after the rebuild, with a fresh annotation.

### 4.3 What does NOT need to change

- **`_buildGroupItem`** (lines 269–322): stays exactly as-is. Its
  `ExpansionTile`/`ListTile` is only created when `_isExpanded == true`
  (the rail is wide enough to render it safely). It is never disposed
  while the mouse hovers over it — when the user collapses the rail
  (via the hamburger button), the hamburger is at the top of the sidebar,
  far from the menu area. Safe.
- **`_buildLeafItem`** (lines 221–267): stays exactly as-is. Never
  conditionally swapped. Safe.
- **Hamburger toggle** (lines 110–126): stays exactly as-is. The
  `IconButton` is never destroyed. Safe.
- **`_buildChildItem`** (lines 372–401): stays exactly as-is. Only
  rendered inside `ExpansionTile` (expanded state only). Safe.

---

## 5. Summary of Changes (single method replacement)

| File | Lines | Change |
|---|---|---|
| `lib/widget/app_sidebar.dart` | 329–370 | Replace `_buildCollapsedGroupItem` — swap `ListTile` + `Future.delayed` for `GestureDetector` + centered icon, synchronous `setState` |

**No other file is touched.**
