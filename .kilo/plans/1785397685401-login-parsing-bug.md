# Login Parsing Bug — Plan

## Root Cause

`lib/widget/login_card.dart:100-104` indexes `data["data"]` with `[0]`, treating it as a `List`. The actual CodeIgniter API returns `data` as a single `Map`:

```json
// Actual API response (Postman-verified):
{ "status": 200, "message": "success", "jwt_token": "...",
  "data": { "id": "1", "username": "admin", ... } }

// What the Flutter code expects (WRONG):
data["data"][0]["username"]   // TypeError: Map is not a List

// What it should be:
data["data"]["username"]
```

Dart throws `TypeError` at runtime. The bare `catch (_)` on line 142 swallows it and shows the misleading "Kredensial tidak valid" message — login succeeded, but parsing failed.

## Fixes

### 1. Fix response parsing (lines 100-104)
Replace all 5 `data["data"][0]` accesses with `data["data"]`:
```dart
String usernameLogin = data["data"]["username"];
String poldaLogin = data["data"]["polda_id"];
String roleID = data["data"]["roles_id"];
String uuid = data["data"]["uuid"];
String expired = data["data"]["expired"];
```

### 2. Add debug logging to catch block (line 142)
Replace `catch (_)` with `catch (e, st)` and add `debugPrint` so future failures are debuggable:
```dart
} catch (e, st) {
  debugPrint('Login error: $e\n$st');
  ...
}
```

### 3. Add null-safety fallback (line 98)
Guard `jsonDecode` + field access against missing keys with `??` defaults. If any key is absent, log a warning but don't crash — show the correct error message.

## Files Changed
- `lib/widget/login_card.dart` — lines 98-148 only

## Validation
1. Build the app: `flutter build apk --debug`
2. Test login with valid credentials → should navigate to DashboardPage
3. Test login with invalid credentials → should show "Kredensial tidak valid"
4. Check `debugPrint` output in logcat/console on failure scenarios

## Risk
None. Change is isolated to login parsing; no other file uses `[0]` on `data["data"]`.
