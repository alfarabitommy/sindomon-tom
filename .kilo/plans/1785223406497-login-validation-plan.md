# Plan: Login Form Validation Refactor

**File:** `lib/widget/login_card.dart`
**Scope:** `login()` method only (lines 30-91)

## Changes

### Step 1 — Replace the early-return validation block (lines 30-38)

Remove this:

```dart
setState(() {
  usernameError = usernameController.text.trim().isEmpty;
  passwordError = passwordController.text.trim().isEmpty;
});

if (usernameError || passwordError) {
  return;
}
```

Replace with:

```dart
final usernameEmpty = usernameController.text.trim().isEmpty;
final passwordEmpty = passwordController.text.trim().isEmpty;

setState(() {
  usernameError = usernameEmpty;
  passwordError = passwordEmpty;
});

if (usernameEmpty && passwordEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Kredensial tidak valid. Silahkan periksa kembali.")),
  );
  return;
}

if (usernameEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Username wajib diisi")),
  );
  return;
}

if (passwordEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Password wajib diisi")),
  );
  return;
}
```

- Red-border state (`usernameError`/`passwordError`) retained for visual feedback alongside the SnackBar.
- Local `bool` variables avoid calling `.trim().isEmpty` twice.

### Step 2 — Replace API-failure SnackBar text (line 77)

Change:

```dart
SnackBar(content: Text("Login gagal: ${response.body}")),
```

To:

```dart
const SnackBar(content: Text("Kredensial tidak valid. Silahkan periksa kembali.")),
```

The existing `if (!mounted) return;` guard on line 75 remains.

### Step 3 — Replace exception SnackBar text + add mounted guard (lines 80-84)

Change:

```dart
} catch (e) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text("Terjadi kesalahan: $e")));
}
```

To:

```dart
} catch (_) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Kredensial tidak valid. Silahkan periksa kembali.")),
  );
}
```

- Exception variable `e` removed (no longer used).
- `mounted` guard added before `ScaffoldMessenger.of(context)` — prevents "use after async gap" linter warnings.

## Validation Checklist

| Scenario | Expected SnackBar |
|---|---|
| Username empty, password filled | "Username wajib diisi" |
| Password empty, username filled | "Password wajib diisi" |
| Both empty | "Kredensial tidak valid. Silahkan periksa kembali." |
| API returns 401/404/500 | "Kredensial tidak valid. Silahkan periksa kembali." |
| Exception (network timeout, bad JSON) | "Kredensial tidak valid. Silahkan periksa kembali." |

## Not In Scope

- No changes to `AppTextField` widget.
- No changes to success path (token storage, navigation).
- No changes to `isLoading`/button-disabled logic.
- No regex/length validation — only empty-check per requirements.
