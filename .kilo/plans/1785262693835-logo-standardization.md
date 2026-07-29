# Logo Standardization Plan

Replace disparate logos/icons with `assets/images/polri-logo.png` across two locations.

## File 1: `lib/widget/login_card.dart`

### Change — Line 174

**Before:**
```dart
Image.asset("assets/images/mascot_login.jpg", width: 80),
```

**After:**
```dart
Image.asset("assets/images/polri-logo.png", height: 85, fit: BoxFit.contain),
```

**Spacing:** Keep `SizedBox(height: 12)` on line 176 unchanged. The 85px-height logo with `BoxFit.contain` will respect aspect ratio and center within its constrained height. The 12px gap to the title below remains proportional.

---

## File 2: `lib/pages/dashboard.dart`

### Change — Lines 126-135 (the CircleAvatar block)

**Before (lines 126-135):**
```dart
                    /// Logo
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      child: const Icon(
                        Icons.security,
                        color: Colors.amber,
                        size: 38,
                      ),
                    ),
```

**After:**
```dart
                    Image.asset(
                      "assets/images/polri-logo.png",
                      height: 65,
                      fit: BoxFit.contain,
                    ),
```

**Spacing:** Keep `SizedBox(height: 15)` on line 137 unchanged. The new logo (65px height, `BoxFit.contain`) is slightly smaller than the former CircleAvatar diameter (70px) but lacks the padded circle background, yielding a cleaner look on the dark `#1E1B4B` sidebar.

---

## Verification

1. Confirm `assets/images/polri-logo.png` is declared in `pubspec.yaml` — already present at line 73.
2. After changes, run `flutter analyze` to ensure no lint/type errors.
3. Visually verify:
   - Login screen: logo appears above "SINDOMON - Portal Masuk" title, not stretched, well-spaced.
   - Dashboard sidebar: logo appears above "SINDOMON" text, transparent on dark background, proportional.

## Removal

The old file `assets/images/mascot_login.jpg` is now unused. Optionally delete it if desired (not part of this plan).
