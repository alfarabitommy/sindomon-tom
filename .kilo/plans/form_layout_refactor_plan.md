# Form Layout Refactor Plan — 7 add_*.dart Pages

## Goal

Replace the 160-line inline glassmorphism header with `AppHeader` widget and restructure from full-page scroll to Fixed Viewport (sticky header/footer, scrollable form only).

## Current vs Target Structure

```
BEFORE (all 7 add_*.dart — 287 lines each):        AFTER (target ~135 lines each):
══════════════════════════════════════════           ═════════════════════════════════════
Scaffold                                             Scaffold
└─ AppBackground                                     └─ AppBackground
   └─ SafeArea                                          └─ SafeArea
      └─ Row                                               └─ Row
         ├─ AppSidebar                                        ├─ AppSidebar
         └─ Expanded                                          └─ Expanded
            └─ SingleChildScrollView  ← ENTIRE PAGE              └─ Padding(30)
               └─ Column(scrolls)                                    └─ Column   ← NO SCROLL
                  ├─ [~160 line inline header]     ← DELETE              ├─ AppHeader(...)        ← STICKY
                  ├─ Title + Kembali button                                ├─ SizedBox(25)
                  ├─ Form Card                                            ├─ Title + Kembali       ← STICKY
                  └─ AppFooter  ← scrolls away                            ├─ SizedBox(25)
                                                                          ├─ Expanded             ← FILLS REMAINING
                                                                          │  └─ SingleChildScrollView
                                                                          │     └─ Form Card
                                                                          ├─ SizedBox(20)
                                                                          └─ AppFooter()          ← STICKY
```

## Per-File Mapping

| File | Class | Sidebar route | breadcrumb | Title text | Form Widget |
|------|-------|--------------|------------|------------|-------------|
| `add_senjata.dart` | `AddSenjataPage` | `senjata` | `Dashboard / Tambah Senjata` | `Pengaturan Senjata` | `FormTambahSenjata` |
| `add_inventaris_page.dart` | — | `inventaris` | `Dashboard / Tambah Inventaris` | `Pengaturan Inventaris` | `FormTambahInventaris` |
| `add_personel_page.dart` | — | `personel` | `Dashboard / Tambah Personel` | `Pengaturan Personel` | `FormTambahPersonel` |
| `add_satwa.dart` | — | `satwa` | `Dashboard / Tambah Satwa` | `Pengaturan Satwa` | `FormTambahSatwa` |
| `add_user.dart` | — | `pengguna` | `Dashboard / Tambah User` | `Pengaturan User` | `FormTambahUser` |
| `add_polres.dart` | — | `polres` | `Dashboard / Tambah Polres` | `Pengaturan Polres` | `FormTambahPolres` |
| `add_polda.dart` | — | `polda` | `Dashboard / Tambah Polda` | `Pengaturan Polda` | `FormTambahPolda` |

## Step-by-Step Changes (per file)

### 1. Imports

- **Remove:** `import 'dart:ui';` (was needed for `ImageFilter.blur` / `BackdropFilter` in the inline glassmorphism header)
- **Add:** `import '../widget/app_header.dart';` (after the existing form import line)

### 2. Delete Inline Header (lines ~57–215)

Remove the entire block from `/// HEADER` comment through the closing of the header Container tree (~160 lines). This includes:
- The outer `Container(height: 75, ...)` with glassmorphism decorations
- `ClipRRect` / `BackdropFilter` / inner `Container`
- The `Row` with icon, breadcrumb text, search `TextField`, notification `IconButton`, user avatar `CircleAvatar`, and `Column` for `unLogin`/`roleLabel`

### 3. Insert AppHeader

Replace the deleted header block with:

```dart
AppHeader(
  breadcrumb: "Dashboard / Tambah {Entity}",
  username: unLogin,
  role: roleLabel,
),
```

### 4. Restructure Scroll Layout

**Remove** the outer `SingleChildScrollView` wrapper (lines 49–50) so the structure becomes:
```dart
Expanded(
  child: Padding(
    padding: const EdgeInsets.all(30),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [...]
    ),
  ),
),
```

The `Column` children become:
1. `AppHeader(...)` — sticky
2. `const SizedBox(height: 25)`
3. Title Row (existing, unchanged) — sticky
4. `const SizedBox(height: 25)`
5. **`Expanded(child: SingleChildScrollView(child: Center(child: ConstrainedBox(...) { form Card })))`** — scrolls
6. `const SizedBox(height: 20)`
7. `const AppFooter()` — sticky

### 5. Title Row — No Change

The existing title row (`Row` with `Text("Pengaturan XXXX")` + `ElevatedButton.icon` "Kembali" back button) stays exactly as-is, just repositioned inside the new Column hierarchy.

### 6. Form Card — Wrap in Expanded + ScrollView

The existing form Card code (lines 257–271) is unchanged but must be wrapped:

```dart
Expanded(
  child: SingleChildScrollView(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Padding(
            padding: EdgeInsets.all(25),
            child: FormTambah{Entity}(),
          ),
        ),
      ),
    ),
  ),
),
```

### 7. AppFooter — Move Outside ScrollView

The existing `const AppFooter()` at the bottom moves to the last child of the outer `Column` (after `SizedBox(height: 20)`). Already imported and used — no import change needed.

## Validation Plan

After all 7 files are refactored:

1. **Dart analysis:** `flutter analyze` or `dart analyze lib/pages/add_*.dart` — must pass zero errors
2. **Import check:** Verify no unused `dart:ui` import remains; verify `app_header.dart` is imported
3. **Structure sanity:** Visual diff each file — output ~135 lines (287 − 160 + 5 = ~132)
4. **Runtime test (manual):** Navigate to each add page — verify:
   - Header renders at top, does not scroll
   - Footer renders at bottom, does not scroll
   - Form content scrolls vertically between header/footer
   - "Kembali" button navigates back correctly
   - User name/role display correctly from SharedPreferences

## Edge Cases & Notes

- **add_user.dart sidebar route** is `"pengguna"` not `"user"` — keep existing value unchanged
- **AppHeader styling mismatch:** AppHeader is solid white card (no glassmorphism). This is intentional — it matches the data page pattern and the brand's centralized header style
- **Search field / notification bell:** The inline header's non-functional search field and notification button are intentionally dropped (they were dead UI). AppHeader has no equivalents
- **`loadUser()` state:** `unLogin` and `roleLabel` fields and `loadUser()` method remain unchanged — they feed into `AppHeader` params
- **No new dependencies:** All needed widgets (`AppHeader`, `AppFooter`, `AppSidebar`, `AppBackground`) are already in the project

## Pseudo-Code Tree of Final Structure

```
add_*.dart final build():
══════════════════════════
Scaffold
└─ AppBackground(imagePath: 'assets/images/wp-putih-mabes.png')
   └─ SafeArea
      └─ Row
         ├─ AppSidebar(currentRoute: "{route}")
         └─ Expanded
            └─ Padding(all: 30)
               └─ Column(crossAxisAlignment: start)
                  ├─ AppHeader(
                  │     breadcrumb: "Dashboard / Tambah {Entity}",
                  │     username: unLogin,
                  │     role: roleLabel,
                  │  )                                          ← STICKY
                  ├─ const SizedBox(height: 25)
                  ├─ Row(                                        ← STICKY
                  │     ├─ Text("Pengaturan {Entity}", 34, bold)
                  │     └─ ElevatedButton.icon("Kembali", back)
                  │  )
                  ├─ const SizedBox(height: 25)
                  ├─ Expanded(                                    ← SCROLLS
                  │     └─ SingleChildScrollView
                  │        └─ Center
                  │           └─ ConstrainedBox(maxWidth: 1000)
                  │              └─ Card(elevation: 8)
                  │                 └─ Padding(25)
                  │                    └─ FormTambah{Entity}()
                  │  )
                  ├─ const SizedBox(height: 20)
                  └─ const AppFooter()                           ← STICKY
```
