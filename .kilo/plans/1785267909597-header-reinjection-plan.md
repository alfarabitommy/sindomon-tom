# Header Re-injection Plan

## Goal
Replace hardcoded legacy headers in 8 data pages with the clean `AppHeader` widget.

## AppHeader constructor

```dart
AppHeader(
  breadcrumb: String,
  username: String,
  role: String,
)
```

**No `const` prefix** — `username: unLogin` is a runtime variable.

## All 8 files — replacement signature

```dart
AppHeader(
  breadcrumb: "<page-specific>",
  username: unLogin,
  role: "Super Admin",
),
```

The legacy header block is always between `/// HEADER` comment and `const SizedBox(height: 25),` followed by `/// TITLE`.

---

## Per-file operations

### 1. personel.dart
- **Add import** after line 19 (`import '../widget/app_pagination.dart';`):
  ```dart
  import '../widget/app_header.dart';
  ```
- **Replace** lines 237–435 (`/// HEADER` block through closing `),` before `const SizedBox(height: 25),`) with:
  ```dart
                      AppHeader(
                        breadcrumb: "Dashboard / Personel",
                        username: unLogin,
                        role: "Super Admin",
                      ),
  ```
- **Preserve:** `const SizedBox(height: 25),` and `/// TITLE` block below.

### 2. polres.dart
- Import already present (line 18).
- **Replace** lines 237–440 with:
  ```dart
                      AppHeader(
                        breadcrumb: "Dashboard / Polres",
                        username: unLogin,
                        role: "Super Admin",
                      ),
  ```

### 3. polda.dart
- Import already present (line 18).
- **Replace** lines 237–440 with:
  ```dart
                      AppHeader(
                        breadcrumb: "Dashboard / Polda",
                        username: unLogin,
                        role: "Super Admin",
                      ),
  ```

### 4. inventaris.dart
- Import already present (line 14).
- **Replace** lines 208–406 with:
  ```dart
                      AppHeader(
                        breadcrumb: "Dashboard / Inventaris",
                        username: unLogin,
                        role: "Super Admin",
                      ),
  ```
- **Note:** Legacy header hardcoded `"Administrator"` — switching to `unLogin` for consistency per user decision.

### 5. satwa.dart
- Import already present (line 14).
- **Replace** lines 222–417 with:
  ```dart
                      AppHeader(
                        breadcrumb: "Dashboard / Satwa",
                        username: unLogin,
                        role: "Super Admin",
                      ),
  ```
- **Note:** Legacy header hardcoded `"Administrator"` — switching to `unLogin`.

### 6. report.dart
- Import already present (line 13).
- **Replace** lines 206–401 with:
  ```dart
                      AppHeader(
                        breadcrumb: "Dashboard / Report",
                        username: unLogin,
                        role: "Super Admin",
                      ),
  ```
- **Note:** Legacy header hardcoded `"Administrator"` — switching to `unLogin`.

### 7. senjata.dart
- Import already present (line 18).
- **Replace** lines 246–441 with:
  ```dart
                      AppHeader(
                        breadcrumb: "Dashboard / Inventaris / Senjata Api",
                        username: unLogin,
                        role: "Super Admin",
                      ),
  ```

### 8. user_page.dart
- Import already present (line 18).
- **Replace** lines 215–410 with:
  ```dart
                      AppHeader(
                        breadcrumb: "Dashboard / Pengguna",
                        username: unLogin,
                        role: "Super Admin",
                      ),
  ```

---

## Anchor strategy

**Start anchor (unique in each file):**
```
                      /// ============================
                      /// HEADER
                      /// ============================
                      Container(
                        height: 75,
```

**End anchor (unique in each file):**
The block terminates with the closing `),` immediately before:
```
                      const SizedBox(height: 25),

                      /// ============================
                      /// TITLE
                      /// ============================
```

Include the `/// HEADER` comment block in the removal so the replacement is clean — no orphaned comments.

---

## Strict Protection Boundary

**DO NOT modify:**
- `AppSearchField` widget calls
- `ActionButtons` widget calls
- Table headers (DataColumn labels, headingTextStyle)
- `AppFooter`, `_PaginationRow`, or any pagination/column structure
- The `const SizedBox(height: 25),` and `/// TITLE` block after the header
- Any other imports (only add `app_header.dart` where missing)
- `dart:ui` import — may remain if used elsewhere in the file, but flag if it becomes unused after removing `BackdropFilter`

---

## Implementation order

1. personel.dart (add import + replace header)
2. polres.dart
3. polda.dart
4. inventaris.dart
5. satwa.dart
6. report.dart
7. senjata.dart
8. user_page.dart

---

## Verification

```bash
flutter analyze lib/pages/
```

Confirm:
- Zero errors
- `AppHeader` resolves in all 8 files
- No unused import warnings for `dart:ui` where `BackdropFilter` was the only usage

Spot-check: Open any data page — header shows clean white container, amber home icon, breadcrumb, spacer, CircleAvatar with username/role on right. No search field, no bell icon.
