# Fix `imagePath` Regression in 8 Data Pages

## Root Cause
The `AppBackground` widget requires `required String imagePath` (see `lib/widget/background.dart:7`). During the prior refactoring, the parameter was accidentally dropped from 8 data page files — the call went from `AppBackground(imagePath: 'assets/images/wp-putih-mabes.png',` to bare `AppBackground(`.

## Affected Files
All 8 files have the EXACT same broken pattern:

```dart
body: AppBackground(
        child: SafeArea(
```

| File | Line |
|------|------|
| `lib/pages/personel.dart` | 127 |
| `lib/pages/polda.dart` | 128 |
| `lib/pages/polres.dart` | 128 |
| `lib/pages/inventaris.dart` | 96 |
| `lib/pages/satwa.dart` | 111 |
| `lib/pages/senjata.dart` | 128 |
| `lib/pages/report.dart` | 95 |
| `lib/pages/user_page.dart` | 98 |

## Fix (per file)

**Edit**: Replace:
```dart
body: AppBackground(
        child: SafeArea(
```
With:
```dart
body: AppBackground(imagePath: 'assets/images/wp-putih-mabes.png',
        child: SafeArea(
```

## Verification
1. Run `flutter analyze` — all 8 `missing_required_argument` errors should disappear
2. Confirm no other layout changes were introduced (SafeArea, Row, sidebar all untouched)

## Implementation Order
Single pass: apply the identical edit to all 8 files.
