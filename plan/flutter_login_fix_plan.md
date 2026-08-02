# Flutter Login Parsing Fix Plan

> **For agentic workers:** This is a single-task fix — no subagent dispatch needed.

**Goal:** Fix `NoSuchMethodError: '[]' Dynamic call of null` during login caused by treating a JSON Object as a JSON Array.

**Architecture:** The backend returns `user` as a `Map<String, dynamic>` but the Flutter code treats it as a `List`. The fix is a one-line change to parse it directly as a Map with a null-safety fallback.

**Tech Stack:** Dart, Flutter, `dart:convert`

---

## 1. Root Cause Identification

**File:** `lib/widget/login_card.dart`, lines 142-145

```dart
final userArray = payload["user"];                          // line 142 — actually a Map, not a List
final userData = (userArray != null && userArray.isNotEmpty) // line 143 — isNotEmpty is true for non-empty Map
    ? userArray[0]                                           // line 144 — Map[0] returns null (no key 0)
    : {};                                                    // line 145
```

**What happens:**
1. The backend returns `"user": {"id": "4", "username": "admin", ...}` — a JSON **Object**.
2. `jsonDecode` parses this into a `Map<String, dynamic>`.
3. The code assigns it to `userArray` and checks `.isNotEmpty` — a Map with entries returns `true`.
4. `userArray[0]` looks up key `0` in the Map, finds nothing, returns `null`.
5. `userData` becomes `null`.
6. `userData["username"]` (line 148) throws `NoSuchMethodError: Class '_Map<String, dynamic>' has no instance method '[]'` on null.

**Why the old code existed:** According to CLAUDE.md, the login API response wraps user data inside an array: `data.user[0]`. This was the documented contract when the code was written. The backend has since changed (or was misunderstood) to return `user` as a single object instead of an array.

---

## 2. Refactor Plan

### 2.1 Primary Fix: `lib/widget/login_card.dart` lines 138-153

**Replace:**

```dart
        final data = jsonDecode(response.body);
        // --- JARING PENGAMAN NULL ---
        // Response menaruh user di dalam array "user" — ambil objek pertama
        final payload = data["data"];
        final userArray = payload["user"];
        final userData = (userArray != null && userArray.isNotEmpty)
            ? userArray[0]
            : {};

        String token = payload["jwt_token"]?.toString() ?? "";
        String usernameLogin = userData["username"]?.toString() ?? "";
        String poldaLogin = userData["polda_id"]?.toString() ?? "";
        String roleID = userData["roles_id"]?.toString() ?? "";
        String uuid = userData["uuid"]?.toString() ?? "";
        String expired = userData["expired"]?.toString() ?? "";
```

**With:**

```dart
        final data = jsonDecode(response.body);
        // --- JARING PENGAMAN NULL ---
        // Response menaruh user sebagai Map<String, dynamic> (JSON Object)
        final payload = data["data"] as Map<String, dynamic>? ?? {};
        final userData = payload["user"] as Map<String, dynamic>? ?? {};

        String token = payload["jwt_token"]?.toString() ?? "";
        String usernameLogin = userData["username"]?.toString() ?? "";
        String poldaLogin = userData["polda_id"]?.toString() ?? "";
        String roleID = userData["roles_id"]?.toString() ?? "";
        String uuid = userData["uuid"]?.toString() ?? "";
        String expired = userData["expired"]?.toString() ?? "";
```

### 2.2 What Changed

| Line | Before | After | Why |
|------|--------|-------|-----|
| `payload` | `data["data"]` (dynamic) | `data["data"] as Map<String, dynamic>? ?? {}` | Explicit type cast with `{}` fallback guards against `data` being null/missing |
| `userData` | List indexing via `userArray[0]` with `isNotEmpty` guard | `payload["user"] as Map<String, dynamic>? ?? {}` | Direct Map cast — no more `[0]` index on a Map |
| Comment | "menaruh user di dalam array" | "menaruh user sebagai Map" | Reflects actual API contract |

### 2.3 Safety Guarantees

All downstream variable extractions (lines 148-152) are **unchanged** and retain their `?.toString() ?? ""` null-safety:
- `userData["username"]?.toString() ?? ""` — if `userData` is `{}` (empty Map), `{}["username"]` returns `null`, `null?.toString()` short-circuits to `null`, and `?? ""` yields `""`.
- Same for `polda_id`, `roles_id`, `uuid`, `expired`.
- `payload["jwt_token"]?.toString() ?? ""` — same chain; if `payload` is `{}`, token defaults to `""`.

No `NoSuchMethodError` can occur because `as Map<String, dynamic>? ?? {}` guarantees `userData` is always a non-null `Map`.

---

## 3. Verification

1. **Build check:** Run `flutter analyze` — should produce no new errors.
2. **Login test:** Run the app, enter valid credentials, confirm login succeeds and navigates to `DashboardPage`.
3. **Null resilience:** If the API ever returns `"user": null` or omits the `"user"` key entirely, the `?? {}` fallback ensures the app doesn't crash — it will attempt navigation with empty credentials (which the dashboard/sidebar will handle gracefully with their own fallback logic).
