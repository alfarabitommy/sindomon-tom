# Flutter Amunisi Async Gap Audit — `lib/pages/amunisi.dart`

> **Audit date:** 2025-06-19  
> **Lint rule:** `use_build_context_synchronously`  
> **Severity:** info (3 occurrences)  
> **Status:** DEBUG / PLAN MODE — no code written yet

---

## 1. Warning Summary

| # | File | Line | Expression | Bug |
|---|------|------|------------|-----|
| 1 | `amunisi.dart` | ~187 | `HudLoading.show(context, label: "MENGHAPUS...")` | A |
| 2 | `amunisi.dart` | ~197 | `HudLoading.hide(context)` | B |
| 3 | `amunisi.dart` | ~207 | `HudLoading.hide(context)` | B |

---

## 2. Method: `deleteAmunisi()` (line 182)

This method is structurally identical to every other `deleteXxx()` method already fixed in the pages audit (personel, polda, polres, sarpras, satwa, senjata). Same two bugs, same fix.

### Bug A — line 187: `HudLoading.show()` after `await`, no guard

```dart
      final prefs = await SharedPreferences.getInstance();   // line 184 — async gap
      final token = prefs.getString("token");

      HudLoading.show(context, label: "MENGHAPUS...");       // line 187 — ❌ context used unguarded
```

**Fix:** Insert `if (!mounted) return;` on the line before `HudLoading.show`.

### Bug B — lines 197/207: `HudLoading.hide()` before guard

```dart
      if (response.statusCode == 200) {
        HudLoading.hide(context);      // line 197 — ❌ context BEFORE guard
        if (!mounted) return;          // line 198 — guard one line too late
        ...
      } else {
        HudLoading.hide(context);      // line 207 — ❌ same
        if (!mounted) return;          // line 208 — same
        ...
      }
```

**Fix:** Swap `HudLoading.hide(context);` ↔ `if (!mounted) return;` in both branches.

---

## 3. Total Change Set

| Fix | Line(s) | Operation | Old | New |
|-----|---------|-----------|-----|-----|
| 1 | 187 | Insert | `      HudLoading.show(context, label: "MENGHAPUS...");` | `      if (!mounted) return;\n      HudLoading.show(...)` |
| 2 | 197–198 | Swap | `HudLoading.hide(context);` above `if (!mounted) return;` | `if (!mounted) return;` above `HudLoading.hide(context);` |
| 3 | 207–208 | Swap | Same | Same |

Three mechanical changes, zero logic alterations. The catch block at lines 217–221 has the same latent issue (out of scope per the user's report).

---

## 4. Verification

```bash
flutter analyze lib/pages/amunisi.dart
```

Expected: **0 issues** — all 3 `use_build_context_synchronously` warnings cleared.
