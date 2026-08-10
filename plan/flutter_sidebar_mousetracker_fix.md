# Flutter Sidebar — MouseTracker Assertion Fix Build Report

**Date:** 2025-07-14
**Status:** ✅ EXECUTED — group-item swap hardened against `mouse_tracker.dart:203:12`

---

## 1. Root Cause

When the sidebar is collapsed (80px) and the user taps a group, the old
`onTap` called `setState` **synchronously** inside the gesture callback. The
rebuild swaps the tapped `ListTile` for an `ExpansionTile` **while the
pointer gesture is still active** — the `ListTile`'s render object is
destroyed mid-gesture, and Flutter's `MouseTracker` (which still holds a
pointer-device annotation referencing the disposed render object) trips the
`mouse_tracker.dart:203:12` assertion, freezing the UI in debug mode.

## 2. Fixes Applied (`lib/widget/app_sidebar.dart`)

### Fix A — `_buildCollapsedGroupItem`: microtask delay + stable key

- `onTap` now defers the rebuild with `Future.delayed(Duration.zero, ...)`,
  letting the gesture pipeline fully release the pointer before the widget
  tree changes, and guards with `if (mounted)`.
- The root `Padding` now carries `key: ValueKey('collapsed_${group.label}')`
  so Flutter can identify the tile during reconciliation.

### Fix B — `_buildGroupItem`: stable key

- The root `Container` now carries `key: ValueKey('expanded_${group.label}')`.

Together, the two keys make the collapsed↔expanded swap a **keyed
reconciliation** (same slot, different key → clean element replacement)
instead of an unkeyed positional swap, eliminating stale subtree/gesture
state.

---

## 3. Updated Methods (replace the existing ones)

```dart
Widget _buildGroupItem(MenuGroup group) {
  return Container(
    // Distinguishes the ExpansionTile from the collapsed icon tile during
    // the widget swap, so Flutter reconciles (not destroys) the subtree.
    key: ValueKey('expanded_${group.label}'),
    margin: const EdgeInsets.symmetric(vertical: 2),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(group.icon, color: Colors.white70),
        title: AnimatedOpacity(
          duration: _textFadeDuration,
          curve: _textFadeCurve,
          opacity: _isExpanded ? 1.0 : 0.0,
          child: Text(
            group.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        // Expansion state is hoisted so it survives the collapsed ↔
        // expanded widget swap (initiallyExpanded re-applies on rebuild).
        initiallyExpanded: _expandedGroups.contains(group.label),
        onExpansionChanged: (expanded) {
          setState(() {
            if (expanded) {
              _expandedGroups.add(group.label);
            } else {
              _expandedGroups.remove(group.label);
            }
          });
        },
        collapsedIconColor: Colors.white70,
        iconColor: Colors.amber,
        childrenPadding: const EdgeInsets.only(left: 24, bottom: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.04),
        collapsedBackgroundColor: Colors.transparent,
        children: group.children
            .map((child) => _buildChildItem(child))
            .toList(),
      ),
    ),
  );
}

/// Collapsed-mode (80px) rendering of a group: icon only, centered.
/// The title stays in the tree at opacity 0 so the ListTile reserves the
/// standard 40px leading slot, which centers the icon in the 80px rail
/// (mirrors [_buildLeafItem]'s collapsed layout exactly).
/// Tapping auto-expands the rail AND opens the group.
Widget _buildCollapsedGroupItem(MenuGroup group) {
  return Padding(
    // Distinguishes the collapsed icon tile from the ExpansionTile during
    // the widget swap, so Flutter reconciles (not destroys) the subtree.
    key: ValueKey('collapsed_${group.label}'),
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: ListTile(
      leading: Icon(group.icon, color: Colors.white70),
      title: AnimatedOpacity(
        duration: _textFadeDuration,
        curve: _textFadeCurve,
        opacity: _isExpanded ? 1.0 : 0.0,
        child: Text(
          group.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      hoverColor: Colors.white10,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      onTap: () {
        // Defer the rebuild until the gesture fully completes — the
        // ListTile is swapped for an ExpansionTile on expand, and
        // destroying it mid-gesture trips the mouse_tracker assertion.
        Future.delayed(Duration.zero, () {
          if (mounted) {
            setState(() {
              _isExpanded = true;
              _expandedGroups.add(group.label);
            });
          }
        });
      },
    ),
  );
}
```

---

## 4. Verification

- ✅ Full file `() [] {}` balanced (interpolation-aware validator).
- ✅ `key: ValueKey('expanded_${group.label}')` on `_buildGroupItem`'s root `Container`.
- ✅ `key: ValueKey('collapsed_${group.label}')` on `_buildCollapsedGroupItem`'s root `Padding`.
- ✅ `Future.delayed(Duration.zero, () { if (mounted) { setState(...); } });`
  exactly as specified.
- ✅ Exactly 2 `ValueKey(` usages (one per method).
- ✅ No other methods touched; `AppSidebar` public API unchanged.
- ⚠️ Manual smoke test needed on-device: collapse → tap a group icon →
  rail expands + group opens, no assertion, no freeze.
