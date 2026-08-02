# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get          # Install/update dependencies
flutter analyze          # Static analysis (no errors, info-level only)
flutter run              # Run on connected device/emulator
flutter build windows    # Build Windows EXE (also in CI on push to dev)
flutter build linux      # Build Linux binary
flutter build macos      # Build macOS app
```

There are no tests yet — `flutter_test` is declared in `pubspec.yaml` but no `test/` directory exists.

## Architecture

SINDOMON is a Flutter desktop application for police resource management (personnel, weapons, inventory, K9, regional command hierarchy). Indonesian-language UI targeting Windows/Linux/macOS.

### Entry & navigation

`main.dart` → `MaterialApp(home: LoginPage)`. There is **no router** — all navigation uses `Navigator.push(MaterialPageRoute(...))`. No route-level role guards exist; any page is reachable by direct navigation regardless of role.

### Layout pattern (every authenticated page)

Every page follows the same structure:

```
Scaffold
  └─ AppBackground (stacked background image)
       └─ Row
            ├─ AppSidebar (260px, dark indigo, independently loads role)
            └─ Expanded
                 └─ Column
                      ├─ AppHeader (breadcrumb, username, role badge)
                      ├─ Title row + action button
                      ├─ AppSearchField
                      ├─ DataTable (with ActionButtons per row)
                      ├─ AppPagination (static, not wired)
                      └─ AppFooter
```

The `PlaceholderPage` is used as a stub for features not yet built — shows a construction icon and "Fitur dalam pengembangan" message.

### Authentication & session

| Key | Stored in SharedPreferences | Notes |
|-----|---------------------------|-------|
| `token` | JWT from `POST /api/v1/auth/login` → `data.jwt_token` | Sent as `authorization` header (**no "Bearer" prefix**) |
| `username_login` | From `data.user[0].username` | Displayed in AppHeader |
| `roleid_login` | From `data.user[0].roles_id` (String: `"1"`, `"2"`, `"3"`) | Drives sidebar menu + dashboard content |
| `polda_login` | From `data.user[0].polda_id` | Written but never read |
| `uuid_login` | From `data.user[0].uuid` | Written but never read |
| `expired_login` | From `data.user[0].expired` | Written but never read |

**Critical API response detail:** The login endpoint wraps user data inside an **array**: `data.user[0]` — not `data` directly. Parsing is in `lib/widget/login_card.dart:138-153`. All six keys are cleared on logout (`app_sidebar.dart:_logout()`).

No auth check on startup — the app always boots to `LoginPage`. No token expiry handling or refresh logic.

### Role & menu system

Three roles, identified by String keys:

| Key | Label | Menu |
|-----|-------|------|
| `"1"` | Super Admin | Dashboard, Laporan, + User management, Master data (Polda/Polres/Org/Logistik) |
| `"2"` | Operator Polda | Dashboard, Laporan, + 7 groups (SDM, Logistik, DMS, Operasional, Komunikasi, Hub Info, Mobile) |
| `"3"` | Command Center | Single item: "Command Center Nasional" → Dashboard (map view) |

**Menu config:** `lib/config/menu_config.dart` — defines `LeafMenuItem` and `MenuGroup` model classes, per-role menu lists (`role1Menu`, `role2Menu`, `role3Menu`), and the `roleMenus` lookup map. `commonTopItems` (Dashboard + Laporan) is exported as a fallback for unrecognized roles.

**Sidebar resolution:** `AppSidebar._resolveMenu()` (`lib/widget/app_sidebar.dart:64-72`) independently loads `roleid_login` from SharedPreferences, looks it up in `roleMenus`, falls back to `commonTopItems` if unknown. The `statusLabelFromId` static method maps IDs to display labels.

**Dashboard special case:** `lib/pages/dashboard.dart` shows a FlutterMap command center view with Polda markers for role `"3"` only; other roles see a "coming soon" placeholder. The Polda API call is gated (`if (_roleId != "3") return;`).

### API layer

Base URL centralized in `lib/config/api_config.dart`:

```dart
const String apiBaseUrl = "https://sindomon.cml-indonesia.com";
```

All endpoints follow `$apiBaseUrl/api/v1/<resource>`. There is **no HTTP service class** — every page/component calls `http.get/post/delete` directly with inline try/catch. Token is read from SharedPreferences on every call. Response parsing is ad-hoc `jsonDecode` → `List<Map<String, dynamic>>.from(json["data"])`. No request/response models or serialization.

### Widget library (`lib/widget/`)

| Widget | Purpose |
|--------|---------|
| `AppSidebar` | 260px role-based navigation panel, loads role from prefs, renders menu items |
| `AppBackground` | Full-screen background image stack |
| `AppHeader` | Breadcrumb + username + role badge (amber circle avatar) |
| `AppFooter` | Copyright + version footer |
| `AppSearchField` | Styled search text field (not wired to actual search) |
| `AppPagination` | Static pagination UI (not wired to data) |
| `ActionButtons` | Edit/delete icon buttons with hover effects |
| `login_card.dart` | Login form with blur-glass container, handles auth POST and SharedPreferences writes |
| `textfield.dart` | Custom text field with error state |
| `form_input_*.dart` | Form widgets for each entity (personel, polda, polres, senjata, user, inventaris, satwa) |

### Data pages (`lib/pages/`)

Each entity page (personel, senjata, polda, polres, satwa, inventaris, user_page) follows the identical pattern: load user info from prefs → fetch list from API → render DataTable with ActionButtons (edit/delete). Delete shows confirmation dialog then calls delete endpoint. Add pages (`add_*.dart`) embed the corresponding form widget.

`report.dart` is the exception — uses hardcoded static data, no API calls.

### Key dependencies

- `http` — raw HTTP client for all API calls
- `shared_preferences` — session persistence (token, role, user info)
- `flutter_map` + `latlong2` — interactive map on Command Center dashboard
- `google_fonts` — typography
- `data_table_2` — declared but unused in current code (standard `DataTable` is used instead)
- `image_picker` — declared, minimal usage

### CI/CD

GitHub Actions (`.github/workflows/build-windows.yml`) builds Windows EXE on push to `dev` branch using `subosito/flutter-action@v2`, uploads artifact.
