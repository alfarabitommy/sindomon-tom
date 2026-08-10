# Flutter Sidebar — MouseTracker Crash Final Audit

**Date:** 2025-07-14
**Auditor:** Reasonix (Senior Flutter Auditor)
**Mode:** DEBUG / PLAN (no code changes)
**Status:** Option C confirmed insufficient — crash persists despite removing `ListTile` from `_buildCollapsedGroupItem`

---

## 1. What We Know

| Attempt | What was done | Result |
|---|---|---|
| Original | `ListTile` (collapsed) → tapped → `ExpansionTile` swap → `MouseTracker` crash | ❌ crash |
| Fix 1 (`ValueKey` + `Future.delayed`) | Added keys + microtask deferral | ❌ crash |
| Fix 2 (Option C — `GestureDetector`) | Replaced collapsed `ListTile` with raw `GestureDetector` — zero `MouseRegion` in the collapsed path | ❌ **still crashes** |

**The `_buildCollapsedGroupItem` is no longer the source.** If Option C removed the only `MouseRegion` from the widget being conditionally swapped, the crash must originate from a **sibling or ancestor widget** whose `MouseRegion` is disposed as a side effect of the `_isExpanded` rebuild.

---

## 2. The Rebuild Blast Radius

When `setState(() { _isExpanded = true; })` fires inside `onTap`, the entire
`_AppSidebarState.build()` method runs again. The following widgets are
**re-created** (new widget instances from the updated `_isExpanded` value).
Element reconciliation reuses old `Element`s *unless* the widget `Key`
changes, forcing disposal + recreation.

### 2.1 Hamburger `IconButton` — `tooltip` string changes

```dart
// line 121
tooltip: _isExpanded ? 'Collapse sidebar' : 'Expand sidebar',
```

`IconButton` internally wraps itself in a `Tooltip` widget. On desktop
Flutter, `Tooltip` can use `MouseRegion` for hover-based triggering
(depending on `TooltipTheme`'s `triggerMode`). When `_isExpanded` changes,
the `tooltip` string changes → `Tooltip` widget receives a new `message`
property → `_TooltipState.didUpdateWidget` runs. **Key:** The `IconButton`
has no explicit key → its `Element` is reused (no unmount). The internal
`Tooltip` `State` also survives. However, if changing the `message` triggers
`_TooltipState` to call `setState` internally, it could rebuild its
`MouseRegion` subtree within the same frame that `MouseTracker` is still
processing the pointer event. **Potential reentrancy trigger.**

### 2.2 Leaf `ListTile`s — `contentPadding`, `trailing`, `AnimatedOpacity` title

```dart
// lines 237–239, 252–254, 260–262
title: AnimatedOpacity(opacity: _isExpanded ? 1.0 : 0.0, ...),
trailing: selected && _isExpanded ? Icon(...) : null,
contentPadding: EdgeInsets.symmetric(horizontal: _isExpanded ? 16 : 20),
```

Every leaf item `ListTile` receives three changed properties. The `ListTile`
`StatelessWidget` rebuilds internally — creating a new `InkResponse` widget.
The old `InkResponse`'s `_InkResponseState` receives the new widget via
`didUpdateWidget`. Normally this does NOT dispose the internal `MouseRegion`
— it only updates highlight/hover tracking parameters. **Key:** Leaf items
have no explicit key → `Element` reused. **Low risk, but not zero** — if
`_InkResponseState._handleHoverChange` or `_updateFocusHighlights` calls
back into `MouseTracker` while `_updateWithEvent` is still on the stack,
reentrancy occurs.

### 2.3 `ListView` padding change

```dart
// line 187
horizontal: _isExpanded ? 12 : 0,
```

`ListView`'s `padding` property changes from `horizontal: 0` to `horizontal:
12`. `ListView` uses `SliverChildListDelegate` to manage children. The
padding change is handled by `SliverPadding` — it does NOT trigger child
reconciliation. **Low risk.**

### 2.4 Group item key swap — Element cascade

```dart
// line 212–213
widgets.add(
  _isExpanded ? _buildGroupItem(item) : _buildCollapsedGroupItem(item),
);
```

The collapsed variant has `key: ValueKey('collapsed_${group.label}')` and
the expanded variant has `key: ValueKey('expanded_${group.label}')`. When
`_isExpanded` flips, the `SliverChildListDelegate` sees a different `Key` at
the group's position → unmounts the old `Element` (GestureDetector-based, no
`MouseRegion`) and mounts a new one (`ExpansionTile`-based, with
`MouseRegion`).

While the collapsed `GestureDetector` itself has no `MouseRegion`, the
**`Key` change in the children list** forces `SliverChildListDelegate` to
run its full diff algorithm. If neighboring leaf items (which DO have
`MouseRegion`s in their `ListTile`s) are misidentified by the diff and
unnecessarily unmounted/remounted, their `MouseRegion`s are disposed while
the mouse is still over them. **This is the most likely hidden trigger.**

### 2.5 New `ExpansionTile` — `initiallyExpanded: true`

```dart
// line 297
initiallyExpanded: _expandedGroups.contains(group.label),
```

When `_isExpanded` flips and the group is created as an `ExpansionTile` with
`initiallyExpanded: true`, the header `ListTile` (with its `MouseRegion`) is
created fresh. Creating a new `MouseRegion` is safe — the `MouseTracker`
welcomes new annotations. **Not the crash source.**

---

## 3. Root Cause Hypothesis

### Primary theory: SliverChildListDelegate key-change cascade

The `_isExpanded` rebuild changes the widget returned at every group's
position in the children list (different `Key`). `SliverChildListDelegate`
uses `RenderSliverList`'s element diffing — a standard LCS-based algorithm.
When keys change for some children but not others, the diff algorithm may
**over-detach** siblings:

```
Before (collapsed):  [Leaf-K, Group(collapsed_key), Leaf-K+1, ...]
After  (expanded):    [Leaf-K, Group(expanded_key),   Leaf-K+1, ...]
```

The framework sees that position K+0 is the same (Leaf-K, same type, same
null key → reused). Position K+1 has a DIFFERENT key → unmount old, mount
new. Position K+2 (Leaf-K+1) — the LCS algorithm might misalign this,
causing it to also be unmounted and recreated. When Leaf-K+1's `ListTile` is
unmounted, its internal `InkResponse` → `MouseRegion` is **disposed while
the mouse is hovering over it** → `MouseTracker` assertion.

This theory explains why:
- Option C didn't fix it (collapsed `GestureDetector` was never the source)
- The crash only happens when the user clicks a group item (the mouse is
  over the clickable area when the rebuild fires)
- Hovering + clicking the hamburger toggle at the TOP of the sidebar does
  NOT crash (the mouse is far from the ListView children — no leaf item
  `MouseRegion` is under the pointer during the toggle rebuild)

### Secondary theory: Tooltip `MouseRegion` reentrancy

On desktop builds, `Tooltip`'s `_TooltipState` may create a `MouseRegion`
for hover-detection. When `_isExpanded` changes, the `tooltip` string
changes → `_TooltipState.didUpdateWidget` → potentially calls `setState`
internally → rebuilds its `MouseRegion` subtree. If this happens within the
same frame as `MouseTracker._updateWithEvent` (which is processing the
pointer event that triggered the tap), it's **reentrancy** →
`mouse_tracker.dart:203:12` assertion. This theory is less likely but
explains why even the hamburger toggle (which is far from the menu) might
theoretically trigger the crash if `Tooltip`'s internal rebuild happens at
exactly the wrong time on that widget.

---

## 4. Strategy Evaluation

### Strategy A — `addPostFrameCallback` / Timer delay

> Defer the `setState` until after the current frame's pointer events are
> fully flushed.

```dart
// In _buildCollapsedGroupItem's onTap:
onTap: () {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      setState(() {
        _isExpanded = true;
        _expandedGroups.add(group.label);
      });
    }
  });
},
```

| Aspect | Verdict |
|---|---|
| Fixes reentrancy (secondary theory) | ✅ — `_updateWithEvent` has fully returned before the rebuild |
| Fixes key-change cascade (primary theory) | ⚠️ Maybe — the pointer event is done, but the mouse is still at the same position. When the Element diff unmounts a sibling `ListTile` in the NEXT frame, does `MouseTracker` still hold a dangling annotation? If so, the NEXT pointer move will crash anyway |
| Platform portability | ⚠️ Fragile — relies on `addPostFrameCallback` firing AFTER `MouseTracker` cleanup, which may vary by platform/Flutter version |
| Code complexity | Low |

**Assessment:** Might work for reentrancy but does NOT prevent sibling
`MouseRegion` disposal. A deferred crash (on the next mouse move) is still
a crash.

### Strategy B — `Offstage` / immutable tree

> Keep ALL `MouseRegion`-bearing widgets permanently mounted. Use `Offstage`
> to show/hide the appropriate variant without ever disposing a widget.

```dart
// Instead of conditionally swapping:
_isExpanded ? _buildGroupItem(item) : _buildCollapsedGroupItem(item)

// Both live in the tree permanently:
Stack(
  children: [
    Offstage(offstage: !_isExpanded, child: _buildGroupItem(item)),
    Offstage(offstage: _isExpanded, child: _buildCollapsedGroupItem(item)),
  ],
)
```

Apply the same pattern to:
- Leaf item `trailing` arrow (always render the `Icon`, wrap in `Offstage`)
- Leaf item text labels (already using `AnimatedOpacity`, which is safe — but
  keep as-is)
- Hamburger `tooltip` (render both `IconButton`s or ensure the `Tooltip`
  MouseRegion isn't recreated)

| Aspect | Verdict |
|---|---|
| Fixes key-change cascade | ✅ — no keys change because no widgets are swapped |
| Fixes reentrancy | ✅ — no `MouseRegion` dispose callbacks |
| Platform portability | ✅ — works identically on all platforms |
| Code complexity | Medium — requires wrapping groups in `Stack` + `Offstage`, adjusting layout for the hidden (80px width) `ExpansionTile` |
| Performance | Negligible impact — ~10 extra widgets permanently mounted |

**Assessment:** Bulletproof. ZERO `MouseRegion` disposal during the toggle.
The only engineering concern is making the `ExpansionTile` render correctly
at 80px width when `Offstage` — but `Offstage` skips layout, so the
`ExpansionTile` is never laid out at the narrow width.

---

## 5. Recommendation

### Implement Strategy B (Offstage Preservation)

**Why Strategy B over A:**

Strategy A is a timing band-aid. Even if `addPostFrameCallback` separates
the rebuild from the current frame's `_updateWithEvent`, the underlying
problem — sibling `ListTile` `MouseRegion`s being disposed by the key-change
cascade — remains. The next pointer movement after the rebuild will still
trigger the assertion if the `MouseRegion`'s disposal wasn't cleanly
unregistered from `MouseTracker`.

Strategy B attacks the root cause: **nothing is ever disposed.** The widget
tree is structurally identical in both modes. The only thing that changes is
`Offstage.offstage` flags. `MouseTracker` annotations stay valid across the
entire toggle animation because their `RenderMouseRegion` objects never
leave the render tree — they're simply hidden from hit-testing by `Offstage`.

### Implementation blueprint

1. **Group items** — wrap both variants in a `Stack` + `Offstage` pair
   (collapsed icon tile `offstage: _isExpanded`, expanded `ExpansionTile`
   `offstage: !_isExpanded`). Remove the `Key` hack entirely — no
   reconciliation needed when both variants live in the same `Stack` slot.

2. **Leaf items** — keep `AnimatedOpacity` for the title text (already safe,
   no `MouseRegion` involved). For the `trailing` arrow that conditionally
   appears at `null` → `Icon`, wrap the icon in `Offstage(offstage: !_isExpanded || !selected)` instead of `selected && _isExpanded ? Icon : null`. This
   prevents `ListTile` from creating/destroying a trailing child (which
   internally triggers `MultiChildRenderObjectWidget` child reconciliation
   that can cascade into `MouseRegion` re-creation).

3. **Hamburger toggle** — render BOTH icons inside the `IconButton` using
   `Stack`: `Offstage(offstage: _isExpanded, child: Icon(Icons.menu))` +
   `Offstage(offstage: !_isExpanded, child: Icon(Icons.menu_open))`. This
   keeps the `IconButton`'s widget identity stable (same `IconButton`
   Element), preventing its internal `Tooltip`/`InkResponse` from
   re-creating `MouseRegion`s.

### Scope of changes

| File | Lines | Change |
|---|---|---|
| `lib/widget/app_sidebar.dart` | ~209–218 | `_buildMenuItems` — wrap groups in `Stack` + `Offstage` |
| `lib/widget/app_sidebar.dart` | ~329–350 | `_buildCollapsedGroupItem` — simplify (no key needed, no tap-expand needed — tap is just a visual option now) |
| `lib/widget/app_sidebar.dart` | ~252–254 | `_buildLeafItem` — `Offstage` for trailing arrow instead of conditional null |
| `lib/widget/app_sidebar.dart` | ~110–125 | Hamburger — `Stack` + `Offstage` for icon swap |
| `lib/widget/app_sidebar.dart` | ~43 | Remove `_expandedGroups` state — no longer needed (groups are always in the tree) |
| `lib/widget/app_sidebar.dart` | ~273, 329 | Remove `ValueKey` from both group methods |
