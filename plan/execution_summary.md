# Build Summary — Circuit Background & Glassmorphism Rescue

> Scope of this session series: (1) PCB circuit background, (2) Micro-HUD Promax density upgrade, (3) Glassmorphism audit, (4) Glassmorphism Phase 1 execution.
> All code verified with `dart analyze` (0 errors) and `flutter test` (7/7 passing).

---

## 1. What Was Built

### 1.1 PCB Circuit Background (completed)

Replaced the old dark-mode-only square HUD grid (`cyber_grid_painter.dart`, deleted) with a procedural PCB circuit backdrop that renders in **both** light and dark modes.

**`lib/widget/cyber_circuit_painter.dart`** — deterministic `CustomPainter`:
- **Seeded PRNG** (`_SeededRandom`, xorshift32, seed `0x504342`) — same size → byte-identical layout every rebuild, no frame drops.
- **Anchor grid** → L/Z/S/jog routes with 45° chamfers, vias (fill + ring) at anchors and every corner, ~7% of anchors become chip nodes.
- **Two palettes**: light = slate/silver (0.07–0.18 alpha, "corporate blueprint"); dark = Jarvis cyan + gold chips with `MaskFilter.blur(2.0)` glow.
- **Static size-keyed cache** (`_cacheBySize`, capped 8 entries) — geometry only regenerates on resize.
- `shouldRepaint` only on `brightness` or size change.

**`lib/widget/background.dart`** — `AppBackground` now **always** wraps content in `CustomPaint(painter: CyberCircuitPainter(brightness: Theme.of(context).brightness))` (the old `isDark ? CustomPaint : child` ternary removed). Zero call-site changes.

### 1.2 Micro-HUD Promax Upgrade (completed)

Rebuilt the same painter to be ~3× denser with a strict visual hierarchy:

| New default | Old | 
|---|---|
| `stepSize` 90.0 | 140.0 |
| `density` 0.50 | 0.35 |
| `jitter` 25.0 | 30.0 |
| `chamferSize` 8.0 | 12.0 |
| `busSpacing` 5.0, `maxBusLanes` 3 | — (new) |

- **4-tier path system**: `nanoTraces` (0.5px, <160px links), `midTraces` (1.0px), `majorTraces` (1.5px, ≥350px arteries), `busTraces` (0.8px).
- **Data Bus generator** (`_buildBusLanes`): 30% of major arteries get 2–3 parallel offset copies (constant perpendicular vector, chamfered at 0.65×).
- **Crosshairs**: `+` marks at 30% of empty grid cells, batched into one `Path`.
- **Micro-labels**: 20-word pool (`SYS:ON`, `0x8FA`, `DATA_LINK`…), ~20 labels at chips + 8% of empty cells; **`TextPainter` instances pre-laid-out inside `_generate()`** and cached — zero text layout in `paint()`.
- **Cache key now includes `Brightness`** so light/dark label colors cache separately.
- **Benchmark**: 1.54 ms average `paint()` at 1920×1080 dark (software renderer) — ~9% of the 16.67 ms frame budget.

### 1.3 Glassmorphism Audit (delivered as plan)

`plan/flutter_glassmorphism_audit.md` — catalogued the "Flashbang" bugs: 33 files with hardcoded `Colors.white` containers, `Color(0xFF23251D)`/`Colors.black` text, `grey.shade50` DataTable headings, `0xFFE5E7EB` borders. Defined the standard and the color-mapping table (hardcoded → `ColorScheme` token).

### 1.4 Glassmorphism Phase 1 (completed)

| File | Action | Change |
|---|---|---|
| `lib/widget/glass_surface.dart` | **created** | Reusable surface: dark = `surface` @ 75% alpha + `white10` border, **no shadow**; light = solid `surface` + soft shadow, no border |
| `lib/widget/textfield.dart` | overwritten | Text → `onSurface`, hint → `onSurfaceVariant`, borders → `outline` |
| `lib/widget/app_search_field.dart` | overwritten | Hint/icon/border → `onSurfaceVariant`; fill `0xFFF3F4F6` → `surfaceContainerHighest` |
| `lib/widget/app_pagination.dart` | overwritten | Border → `outlineVariant`, texts → `onSurfaceVariant`, dots theme-aware (active amber kept) |
| `lib/widget/login_card.dart` | patched | Glass → `surface` @ 15%, border → `outline` @ 40%, title/labels → `onSurface`; gold button kept |

**Design decision:** one `GlassSurface` wrapper instead of `if (isDark)` sprinkles across 30+ files — the widget reads brightness from context automatically.

---

## 2. File Inventory

### Created (4)
| File | Purpose |
|---|---|
| `lib/widget/cyber_circuit_painter.dart` (819 lines) | Micro-HUD Promax circuit painter |
| `lib/widget/glass_surface.dart` (76 lines) | Reusable glass/light surface |
| `test/background_test.dart` | 7-test suite (determinism, palette, cache, shouldRepaint, both themes) |
| `plan/flutter_circuit_background_audit.md` + `plan/flutter_circuit_promax_audit.md` + `plan/flutter_glassmorphism_audit.md` | Design/audit artifacts |

### Deleted (1)
| File | Reason |
|---|---|
| `lib/widget/cyber_grid_painter.dart` | Replaced by circuit painter |

### Modified (7)
| File | Change |
|---|---|
| `lib/widget/background.dart` | Always-on `CustomPaint` + brightness pass-through |
| `lib/widget/textfield.dart` | Theme-aware colors |
| `lib/widget/app_search_field.dart` | Theme-aware colors |
| `lib/widget/app_pagination.dart` | Theme-aware colors |
| `lib/widget/login_card.dart` | Theme-aware glass/text |
| `test/background_test.dart` | Added shared-cache test |
| `lib/widget/cyber_circuit_painter.dart` | (rewritten twice: PCB → Promax) |

---

## 3. Verification Evidence

| Check | Result |
|---|---|
| `dart analyze` (project-wide) | **0 errors** |
| `flutter test test/background_test.dart` | **7/7 passed** — byte-identical frames for same config; light ≠ dark; cache regeneration on resize; `shouldRepaint` contract; `CustomPaint` present in both themes; no paint exceptions |
| Paint benchmark 1920×1080 dark | **1.54 ms avg** (software renderer; faster on GPU) |
| Remaining analyze findings | 7 pre-existing info-level `use_build_context_synchronously` in `login_card.dart` (verified via `git stash` — predate this work) |

---

## 4. Known Notes & Next Steps

- **Pending (Glassmorphism Phases 2–6)**: 9 form input widgets, 9 add-page cards, 10 data-table pages, profile page (`pangaturan.dart`) still use hardcoded white/gray — the `GlassSurface` widget is ready for them.
- `dashboard.dart` command-center overlays use intentional black/cyan HUD styling over the map — deliberately **excluded** from the glassmorphism pass.
- The stale `test/widget_test.dart` (default counter test) fails on full-suite runs; predates this work, left untouched.
- Environment note: the Flutter SDK at `~/.config/FlyEnv/...` is mounted read-only — local verification used a temp copy of the SDK; `flutter analyze`/`test` on CI will work normally.
