# Flutter Async Gap Audit — `lib/widget/login_card.dart`

> **Audit date:** 2025-06-19  
> **Lint rule:** `use_build_context_synchronously`  
> **File under audit:** `lib/widget/login_card.dart`  
> **Severity:** info (7 occurrences)  
> **Status:** DEBUG / PLAN MODE — no code written yet

---

## 1. Warning Summary

All 7 warnings are in the `login()` async method (lines 51–234). The linter flags every post-`await` usage of the `context` variable:

| # | Line | Column | Snippet | Context usage |
|---|------|--------|---------|---------------|
| 1 | 162 | 11 | `Navigator.pushAndRemoveUntil(` | `context` (1st positional arg) |
| 2 | 168 | 25 | `HudLoading.hide(context);` | `context` argument |
| 3 | 170 | 11 | `showDialog(` → `context: context,` | `context` named parameter |
| 4 | 187 | 25 | `HudLoading.hide(context);` | `context` argument |
| 5 | 188 | 30 | `ScaffoldMessenger.of(context)` | `context` argument |
| 6 | 212 | 23 | `HudLoading.hide(context);` | `context` argument |
| 7 | 213 | 28 | `ScaffoldMessenger.of(context)` | `context` argument |

Every flagged line is inside the `try`/`catch` block of `login()` and comes **after** at least one `await` expression.

---

## 2. Root Cause Analysis

### 2.1 The async gaps in `login()`

The method `login()` has two tiers of async gaps:

```
Line 128:  await http.post(…)              ← Gap A (creates first async suspension)
Lines 150–156:
   await SharedPreferences.getInstance()  ← Gap B1
   await prefs.setString("token", …)      ← Gap B2
   await prefs.setString("username_login", …)  ← B3
   await prefs.setString("polda_login", …)     ← B4
   await prefs.setString("roleid_login", …)    ← B5
   await prefs.setString("uuid_login", …)      ← B6
   await prefs.setString("expired_login", …)   ← B7
```

After Gap A, execution branches into `if` (200), `else if` (403), `else`, or `catch`. After Gaps B1–B7 (inside the 200 branch only), execution reaches the navigation call.

### 2.2 Why the current guards fail the lint

The code already has 4 guard statements:

```dart
// Line 157 (inside statusCode == 200 block)
if (!context.mounted) return;

// Line 167 (inside statusCode == 403 block)
if (!context.mounted) return;

// Line 186 (inside else block)
if (!context.mounted) return;

// Line 211 (inside catch block)
if (!context.mounted) return;
```

These use **`context.mounted`** — the `BuildContext` extension getter introduced in Flutter 3.7.

**However**, the `use_build_context_synchronously` lint in the version shipped with `flutter_lints: ^5.0.0` (Dart SDK `^3.7.2`) does **not** recognize `context.mounted` as a valid async-gap guard. It only recognizes the older **`State.mounted`** property pattern:

```dart
if (!mounted) return;   // ✅ Recognized — clears the taint
if (!context.mounted) return;  // ❌ NOT recognized — taint persists
```

### 2.3 Proof from the codebase

A grep across the entire `lib/` directory reveals a stark pattern:

| Guard form | Occurrences | Files affected |
|------------|-------------|----------------|
| `if (!mounted) return;` | **~80** | 18 files (pages, widgets, forms) |
| `if (!context.mounted) return;` | **5** | Only `login_card.dart` (4) + `session_util.dart` (1) |

The ~80 usages of `if (!mounted) return;` produce **zero** `use_build_context_synchronously` warnings. The 5 usages of `if (!context.mounted) return;` are the only ones flagged. This is conclusive: the linter recognizes `State.mounted` but not `BuildContext.mounted` as a guard.

### 2.4 Why the two forms are equivalent here

Inside a `State<T>` subclass (which `_LoginCardState` is), `this.mounted` and `this.context.mounted` always return the same boolean:

- `State.mounted` — `true` after `initState`, `false` after `dispose`.
- `BuildContext.mounted` — `true` while the underlying `Element` is in the tree.

Since a `State` object's `context` is exactly its associated `Element`, the two values are always in sync. Swapping one for the other is **semantically neutral and safe**.

---

## 3. Detailed Line-by-Line Fix Plan

### 3.1 Guard at line 157 (200 branch — success navigation)

**Current code (lines 156–165):**
```dart
        await prefs.setString("expired_login", expired);
        if (!context.mounted) return;                         // ← line 157
        // pushAndRemoveUntil removes BOTH the login page and the HUD dialog
        // route, so the dashboard becomes the only route on the stack and the
        // back button can never return to the login form.
        Navigator.pushAndRemoveUntil(
          context,                                            // ← line 162 WARNING
          MaterialPageRoute(builder: (_) => const DashboardPage()),
          (route) => false,
        );
```

**Planned fix — replace the guard on line 157:**
```dart
        await prefs.setString("expired_login", expired);
        if (!mounted) return;                                 // ← FIX: use State.mounted
        Navigator.pushAndRemoveUntil(
          context,                                            // ← lint CLEARED
          MaterialPageRoute(builder: (_) => const DashboardPage()),
          (route) => false,
        );
```

This clears **warning #1** (line 162).

---

### 3.2 Guard at line 167 (403 branch — blocked dialog)

**Current code (lines 166–184):**
```dart
      } else if (response.statusCode == 403) {
        if (!context.mounted) return;                         // ← line 167
        HudLoading.hide(context);                             // ← line 168 WARNING
        showDialog(
          context: context,                                   // ← line 170 WARNING
          builder: (ctx) => AlertDialog(
            title: const Text("Akses Diblokir"),
            content: const Text(
              "Perangkat Anda belum terverifikasi. Sesi login diblokir. "
              "Silahkan hubungi Super Admin Mabes.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Tutup"),
              ),
            ],
          ),
        );
```

**Planned fix — replace the guard on line 167:**
```dart
      } else if (response.statusCode == 403) {
        if (!mounted) return;                                 // ← FIX: use State.mounted
        HudLoading.hide(context);                             // ← lint CLEARED
        showDialog(
          context: context,                                   // ← lint CLEARED
          builder: (ctx) => AlertDialog(
            …
          ),
        );
```

This clears **warnings #2 and #3** (lines 168, 170).

---

### 3.3 Guard at line 186 (else branch — credential error)

**Current code (lines 185–207):**
```dart
      } else {
        if (!context.mounted) return;                         // ← line 186
        HudLoading.hide(context);                             // ← line 187 WARNING
        ScaffoldMessenger.of(context).showSnackBar(           // ← line 188 WARNING
          SnackBar(…),
        );
      }
```

**Planned fix — replace the guard on line 186:**
```dart
      } else {
        if (!mounted) return;                                 // ← FIX: use State.mounted
        HudLoading.hide(context);                             // ← lint CLEARED
        ScaffoldMessenger.of(context).showSnackBar(           // ← lint CLEARED
          SnackBar(…),
        );
      }
```

This clears **warnings #4 and #5** (lines 187, 188).

---

### 3.4 Guard at line 211 (catch block — network/parse error)

**Current code (lines 209–233):**
```dart
    } catch (e, st) {
      debugPrint('Login error: $e\n$st');
      if (!context.mounted) return;                           // ← line 211
      HudLoading.hide(context);                               // ← line 212 WARNING
      ScaffoldMessenger.of(context).showSnackBar(             // ← line 213 WARNING
        SnackBar(…),
      );
    }
```

**Planned fix — replace the guard on line 211:**
```dart
    } catch (e, st) {
      debugPrint('Login error: $e\n$st');
      if (!mounted) return;                                   // ← FIX: use State.mounted
      HudLoading.hide(context);                               // ← lint CLEARED
      ScaffoldMessenger.of(context).showSnackBar(             // ← lint CLEARED
        SnackBar(…),
      );
    }
```

This clears **warnings #6 and #7** (lines 212, 213).

---

## 4. Total Change Set

Exactly **4 lines** change — all are 1:1 replacements:

| Line | Old | New |
|------|-----|-----|
| 157 | `if (!context.mounted) return;` | `if (!mounted) return;` |
| 167 | `if (!context.mounted) return;` | `if (!mounted) return;` |
| 186 | `if (!context.mounted) return;` | `if (!mounted) return;` |
| 211 | `if (!context.mounted) return;` | `if (!mounted) return;` |

No other logic, control flow, or behavior changes. All 7 warnings resolved.

---

## 5. Bonus: `lib/utils/session_util.dart`

The file `session_util.dart` also uses `context.mounted` at line 21:

```dart
Future<void> clearSessionAndLogout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  if (!context.mounted) return;   // ← same issue
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => const LoginPage()),
    (route) => false,
  );
}
```

However, this is a **top-level function** (not inside a `State` class), so `mounted` (the `State` property) is **not available**. The `context.mounted` guard here is actually correct and necessary. If the linter flags this file too, the options are:

1. **Suppress inline**: Add `// ignore: use_build_context_synchronously` on the `Navigator.pushAndRemoveUntil` line.
2. **Change the signature**: Accept a `State` reference so `mounted` is in scope.
3. **Accept the warning**: In a top-level function, `context.mounted` is the idiomatic choice, and the lint is overly strict here.

This is out of scope for the current fix but worth noting.

---

## 6. Recommended Codebase Pattern

For consistency and to prevent future regressions, the project should adopt a single pattern for async-gap guards across all `State` classes:

```dart
// ✅ PREFERRED (inside State<T> subclasses)
if (!mounted) return;

// ❌ AVOID (inside State<T> subclasses)
if (!context.mounted) return;

// ✅ REQUIRED (top-level functions / static methods)
if (!context.mounted) return;
```

The rationale:
- `mounted` is shorter, universally recognized by the linter, and idiomatic for `State` classes.
- `context.mounted` is reserved for situations where a `State` reference isn't available.

---

## 7. Verification Plan (post-fix)

After applying the 4-line change:

```bash
flutter analyze lib/widget/login_card.dart
```

Expected result: **0 issues** (no `use_build_context_synchronously` warnings).

Manual smoke test: log in with valid credentials → verify navigation to dashboard; log in with invalid credentials → verify snackbar; log in with blocked device → verify 403 dialog.
