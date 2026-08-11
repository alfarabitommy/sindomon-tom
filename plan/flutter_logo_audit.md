# Flutter Logo Replacement Audit

**Status:** 📋 AUDIT COMPLETE — ready for execution phase  
**Date:** 2025-07-09  
**Goal:** Replace `polri-logo.png` with `logo-korsabhara.png` across the app

---

## 1. Current Logo Asset

| Property | Value |
|---|---|
| **Old path** | `assets/images/polri-logo.png` |
| **New path** | `assets/images/logo-korsabhara.png` |
| **New file present?** | ✅ YES — already exists at `assets/images/logo-korsabhara.png` |

---

## 2. All `Image.asset` Usages in `lib/`

### 2.1 Logo usages (MUST update)

| # | File | Line | Current Path | Sizing | Fit |
|---|------|------|-------------|--------|-----|
| 1 | `lib/widget/app_sidebar.dart` | 200 | `"assets/images/polri-logo.png"` | `AnimatedContainer(height: _isExpanded ? 65 : 40)` | `BoxFit.contain` |
| 2 | `lib/widget/login_card.dart` | 287 | `"assets/images/polri-logo.png"` | `height: 85` | `BoxFit.contain` |

These are the **only two** files that need code changes.

### 2.2 Non-logo usages (DO NOT TOUCH)

| # | File | Line | Path | Purpose |
|---|------|------|------|---------|
| 3 | `lib/pages/inventaris.dart` | 178 | `"assets/images/rantis.jpg"` | Vehicle photo in inventory table — unrelated |

---

## 3. `pubspec.yaml` Audit

### Current assets section (lines 72–76)

```yaml
assets:
    - assets/images/
    - assets/images/mabes-wp.png
    - assets/images/wp-putih-mabes.png
    - assets/images/polri-logo.png
```

### Assessment

- ✅ `- assets/images/` (line 73) already declares the **entire folder** — `logo-korsabhara.png` is already covered. No build error regardless.
- ⚠️ `- assets/images/polri-logo.png` (line 76) is a **redundant explicit entry** (already covered by the folder declaration). For tidiness, this line should be updated to `- assets/images/logo-korsabhara.png`, OR simply removed since the folder entry already captures it.

**Recommendation:** Replace line 76 with the new filename for explicitness and audit-trail clarity.

---

## 4. Sizing / Aspect-Ratio Analysis

### 4.1 Sidebar logo (`app_sidebar.dart:198-202`)

```dart
AnimatedContainer(
  duration: _widthAnimationDuration,
  curve: Curves.easeOutCubic,
  height: _isExpanded ? 65 : 40,
  child: Image.asset(
    "assets/images/polri-logo.png",
    fit: BoxFit.contain,
  ),
),
```

- **Container width:** determined by parent layout (collapsed sidebar = 80px, expanded = 260px).
- **Fit mode:** `BoxFit.contain` — the image scales proportionally to fit within the container, letterboxing if the aspect ratio differs.
- **Risk if new logo has different aspect ratio:** LOW. The image will simply appear smaller within the allocated height. No code change required unless the visual result looks off. If the Sabhara logo is significantly wider (e.g., a horizontal wordmark), consider adding `width` constraint or switching to `BoxFit.fitWidth`.

### 4.2 Login logo (`login_card.dart:286-290`)

```dart
Image.asset(
  "assets/images/polri-logo.png",
  height: 85,
  fit: BoxFit.contain,
),
```

- **Width:** unconstrained (image takes its natural width up to parent container).
- **Fit mode:** `BoxFit.contain` with only `height` specified — the width scales proportionally.
- **Risk if new logo has different aspect ratio:** LOW. The height anchors the size; width auto-scales via `BoxFit.contain`. No code change required unless the logo looks too small or overflows.

---

## 5. Execution Plan (for next phase)

### 5.1 File changes required

| Step | File | Action | Line(s) |
|------|------|--------|---------|
| 1 | `pubspec.yaml` | Change `- assets/images/polri-logo.png` → `- assets/images/logo-korsabhara.png` | 76 |
| 2 | `lib/widget/app_sidebar.dart` | Change `"assets/images/polri-logo.png"` → `"assets/images/logo-korsabhara.png"` | 200 |
| 3 | `lib/widget/login_card.dart` | Change `"assets/images/polri-logo.png"` → `"assets/images/logo-korsabhara.png"` | 287 |

### 5.2 No-change confirmations

| Concern | Verdict |
|---------|---------|
| Sizing adjustments needed? | ❌ No — `BoxFit.contain` handles aspect-ratio differences gracefully |
| New asset file needed? | ✅ Already present at `assets/images/logo-korsabhara.png` |
| Other files referencing the old logo? | ❌ None in `lib/`. 7 hits in `plan/` docs, but those are historical audit/build artifacts — no action needed |

### 5.3 Verification after execution

```bash
flutter analyze          # No new errors
flutter run              # Visual check: sidebar logo and login logo show the Sabhara emblem
```

---

## 6. Total Impact Summary

| Metric | Count |
|--------|-------|
| Files to edit | **3** |
| Lines to change | **3** (one per file) |
| Risk level | 🟢 **TRIVIAL** — pure string replacement, no layout logic changes |
| Estimated time | < 2 minutes |
