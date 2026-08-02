# Flutter User Management — Edit & Delete Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire up Edit (PUT) and Soft Delete (DELETE) functionality on the User Management page, including a pre-filled edit form and confirmation-gated delete with SnackBar feedback.

**Architecture:** Add `deleteUser(int id)` and `updateUser(...)` methods to `_UserPageState`. Wire them to `ActionButtons` callbacks via inline `showDialog` (delete) and `Navigator.push` to a refactored `FormTambahUser` that accepts optional initial data for edit mode. Follow the existing `personel.dart` delete-dialog pattern exactly, but use RESTful URL-path IDs (`/api/v1/user/123`) instead of the JSON-body pattern used by other entity endpoints.

**Tech Stack:** Flutter/Dart, `http` package, `shared_preferences`, Material Design `AlertDialog` / `SnackBar`

## Global Constraints

- User API uses RESTful URL-path IDs: `PUT /api/v1/user/(:num)`, `DELETE /api/v1/user/(:num)` — NOT JSON-body IDs like other entity endpoints
- Auth header: `{"Authorization": "<token>"}` (no "Bearer" prefix; casing follows existing "Authorization" convention)
- Role values are integer strings: `"1"` (Super Admin), `"2"` (Operator Polda), `"3"` (Command Center) — "Operator Polres" (role_id=4) does NOT exist in DB per RBAC rules
- Password should be omitted from PUT body when left blank (partial update)
- All API responses follow standard envelope: `{"status": ..., "message": ..., "data": ...}`
- Indonesian-language UI: "Hapus Pengguna", "Apakah Anda yakin...", "Batal", "Hapus", etc.

---

## 1. UI & Data Flow Audit

### 1.1 Current State (All Files Found)

| File | Path | Current Status |
|------|------|----------------|
| **User list page** | `lib/pages/user_page.dart` | Edit/Delete callbacks are empty no-ops (`onEdit: () {}`, `onDelete: () {}` at lines 236–239). GET request at line 40 sends **no auth token** — this is the only list page in the app missing auth headers. |
| **Add user page** | `lib/pages/add_user.dart` | Thin scaffold wrapping `FormTambahUser` in a Card. Navigates back with `Navigator.pop(context)`. No API imports. |
| **User form widget** | `lib/widget/form_input_user.dart` | `FormTambahUser` is `const` with no constructor parameters — cannot receive initial data. "Simpan Akun" button has `onPressed: () {}` (no-op). Role dropdown uses hardcoded text labels ("Super Admin", "Operator Polda", "Operator Polres") instead of role_id integers. Polda dropdown is hardcoded (3 static names). No API submission logic. |
| **Action buttons** | `lib/widget/action_buttons.dart` | Clean widget accepting `onEdit`/`onDelete` `VoidCallback?` — ready to wire. Hover effects already implemented. |
| **API config** | `lib/config/api_config.dart` | Single const `apiBaseUrl = "https://sindomon.cml-indonesia.com"`. No helper methods. |

### 1.2 Existing Patterns to Follow

**Delete + Confirmation Dialog** (from `personel.dart:266-314`, identical in `polda.dart`, `senjata.dart`, `polres.dart`):
```dart
// Inline pattern in the DataCell for each row:
ActionButtons(
  onEdit: () {},  // never implemented anywhere
  onDelete: () async {
    final result = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Personel"),
        content: const Text("Apakah Anda yakin ingin menghapus data ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Hapus")),
        ],
      ),
    );
    if (result == true) { deletePersonel(int.parse(e["id"])); }
  },
)
```

**Token retrieval** (canonical, used ~40 times across codebase):
```dart
final prefs = await SharedPreferences.getInstance();
final token = prefs.getString("token");
headers: {"Authorization": token.toString()}
```

**SnackBar feedback** (from `form_input_personel.dart:submitPersonel()`):
```dart
if (!mounted) return;
final result = jsonDecode(response.body);
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(result["message"] ?? "Berhasil")),
);
```

**API-dynamic dropdown** (from `form_input_personel.dart:getPolda()`):
```dart
final response = await http.get(
  Uri.parse("$apiBaseUrl/api/v1/polda"),
  headers: {"Authorization": token.toString()},
);
setState(() { daftarPolda = List<Map<String, dynamic>>.from(jsonDecode(response.body)["data"]); });
```

### 1.3 Critical DIFFERENCES from Existing Patterns

| Aspect | Other Entities (personel, polda, etc.) | User API |
|--------|----------------------------------------|----------|
| **DELETE ID location** | JSON body: `{"personel_id": id}` | URL path: `/api/v1/user/123` |
| **PUT/PATCH** | Not implemented anywhere | `PUT /api/v1/user/(:num)` — first PUT in the app |
| **Password field** | N/A | Must be omissible (blank = unchanged) for edit |

### 1.4 Data Flow Diagram

```
UserPage (list)                         FormTambahUser (create/edit)
┌──────────────────────┐               ┌──────────────────────────┐
│ getUsers()           │               │ Mode: "add" or "edit"    │
│ → GET /api/v1/user   │               │                          │
│                      │  Navigator    │ username controller      │
│ DataTable            │  .push ───→   │ password controller      │
│  ActionButtons       │               │ role dropdown (int ids)  │
│   onEdit → editUser  │               │ status switch            │
│   onDelete → confirm │               │ polda dropdown (fetched) │
│              → delete │               │                          │
│                      │  ←─── pop()   │ onSubmit:                │
│ SnackBar + refresh   │               │  POST /api/v1/user (add) │
└──────────────────────┘               │  PUT /api/v1/user/:id    │
                                       └──────────────────────────┘
```

---

## 2. Delete Implementation Plan

> **Files modified:** `lib/pages/user_page.dart`

### Task 1: Add auth token to GET request + delete method

**Files:**
- Modify: `lib/pages/user_page.dart` (entire file)

**Interfaces:**
- Consumes: `apiBaseUrl` from `../config/api_config.dart`, `ActionButtons` from `../widget/action_buttons.dart`, `SharedPreferences`
- Produces: `deleteUser(int id)` method, wired `onDelete` callbacks, token on GET request

**Steps:**

- [ ] **Step 1: Add token header to `getUsers()`**

Replace the bare `http.get` call (lines 39–41) with the canonical auth pattern:

```dart
// OLD (lines 39–41):
final response = await http.get(
  Uri.parse("$apiBaseUrl/api/v1/user"),
);

// NEW:
final prefs = await SharedPreferences.getInstance();
final token = prefs.getString("token");
final response = await http.get(
  Uri.parse("$apiBaseUrl/api/v1/user"),
  headers: {"Authorization": token.toString()},
);
```

Note: `SharedPreferences` is already imported. This brings the user page in line with every other list page.

- [ ] **Step 2: Verify `e["id"]` is available in the response data**

The current row accesses `e["username"]`, `e["roles_id"]`, `e["polda"]`, `e["status"]`. The API response must include an `"id"` field for each user. Confirm by checking: the RBAC memory references `tbl_users` which has a primary key; the login response includes `user[0]` with `uuid` — an `id` integer field is standard. If the API returns a different key (e.g., `"user_id"`), adjust accordingly. For this plan, we assume `e["id"]` is the integer primary key.

- [ ] **Step 3: Add `deleteUser(int id)` method to `_UserPageState`**

Add after `getUsers()` (around line 62):

```dart
Future<void> deleteUser(int id) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.delete(
      Uri.parse("$apiBaseUrl/api/v1/user/$id"),
      headers: {
        "Authorization": token.toString(),
      },
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"] ?? "Pengguna berhasil dihapus"),
          backgroundColor: Colors.green,
        ),
      );
      getUsers(); // refresh list
    } else {
      final result = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"] ?? "Gagal menghapus pengguna"),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    debugPrint(e.toString());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Terjadi kesalahan jaringan"),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

- [ ] **Step 4: Wire `onDelete` callback in DataTable rows**

Replace the empty `onDelete: () {}` at line 238 with the confirmation dialog + delete call:

```dart
// OLD (lines 236–239):
DataCell(
  ActionButtons(
    onEdit: () {},
    onDelete: () {},
  ),
),

// NEW:
DataCell(
  ActionButtons(
    onEdit: () {}, // still stub for now; Task 3 wires this
    onDelete: () async {
      final userId = int.tryParse("${e["id"]}") ?? 0;
      if (userId == 0) return;

      final result = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Hapus Pengguna"),
          content: Text(
            "Apakah Anda yakin ingin menghapus pengguna \"${e["username"]}\"?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Hapus"),
            ),
          ],
        ),
      );

      if (result == true) {
        deleteUser(userId);
      }
    },
  ),
),
```

Key details:
- Uses `int.tryParse("${e["id"]}")` with a 0 guard — safe against null/missing id
- Shows the username in the confirmation message for clarity
- Red "Hapus" button styling for destructive action
- Follows the exact `showDialog<bool>` pattern from `personel.dart`

- [ ] **Step 5: Verify — hot reload the app and test delete**

1. Launch the app: `flutter run`
2. Navigate to "Daftar Pengguna" (requires Super Admin role, role_id=1)
3. Tap the delete (trash) icon on any user row
4. Confirm the dialog appears with the username
5. Tap "Batal" → dialog closes, no change
6. Tap delete icon again → tap "Hapus" → verify SnackBar appears, list refreshes
7. Verify the deleted user is no longer in the table

---

## 3. Edit Implementation Plan

> **Files modified:** `lib/pages/user_page.dart`, `lib/widget/form_input_user.dart`, `lib/pages/add_user.dart`

### 3.1 Architecture Decision: Edit Flow

Two approaches were considered:

**Approach A: Reuse `AddUserPage` + `FormTambahUser` with a "mode" parameter.** The existing `AddUserPage` wraps `FormTambahUser` in a Card. We add optional `userData` and `userId` parameters. `FormTambahUser` detects edit mode by presence of initial data and switches the button label from "Simpan Akun" to "Update Akun" and the submit method from POST to PUT.

**Approach B: Build a separate `EditUserPage` + `FormEditUser` widget.** Duplicates the layout shell and form UI.

**Decision: Approach A** — the form UI is identical for create and edit; only the pre-fill + HTTP method differ. This follows DRY and matches how a developer would naturally extend this codebase.

### Task 2: Refactor `FormTambahUser` for create + edit dual mode

**Files:**
- Modify: `lib/widget/form_input_user.dart` (entire file — major refactor)

**Interfaces:**
- Consumes: `apiBaseUrl` from `../config/api_config.dart`, `http`, `dart:convert`, `shared_preferences`
- Produces: `FormTambahUser({int? userId, Map<String, dynamic>? initialData})` — optional params for edit mode
- New method: `Future<void> submitUser()` — handles both POST (create) and PUT (update)
- New method: `Future<void> getPoldaList()` — fetches polda from API for dynamic dropdown

**Steps:**

- [ ] **Step 1: Add constructor parameters and imports**

```dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class FormTambahUser extends StatefulWidget {
  final int? userId;       // null = create mode, non-null = edit mode
  final Map<String, dynamic>? initialData; // pre-fill data for edit

  const FormTambahUser({
    super.key,
    this.userId,
    this.initialData,
  });

  @override
  State<FormTambahUser> createState() => _FormTambahUserState();
}
```

- [ ] **Step 2: Add state variables for dynamic dropdowns and API data**

Replace the current hardcoded state:

```dart
// REMOVE these hardcoded fields:
// bool aktif = true;
// String role = "Operator Polda";
// String? polda = "Polda Jawa Barat";

// ADD these:
late bool aktif;
late String? selectedRoleId; // "1", "2", or "3" — matches API role_id
late String? selectedPoldaId; // polda id from API, null = no polda
List<Map<String, dynamic>> daftarPolda = [];
bool isSubmitting = false;
bool isEditMode = false;

// Keep these controllers:
final username = TextEditingController();
final password = TextEditingController();
```

- [ ] **Step 3: Add `initState()` to detect mode and pre-fill**

```dart
@override
void initState() {
  super.initState();
  isEditMode = widget.userId != null && widget.initialData != null;

  if (isEditMode && widget.initialData != null) {
    final data = widget.initialData!;
    username.text = data["username"]?.toString() ?? "";
    // Password intentionally left blank — user enters new one only if changing
    password.text = "";

    // Map role_id (integer or string) to dropdown value
    final rawRole = data["roles_id"];
    if (rawRole != null) {
      selectedRoleId = rawRole.toString(); // "1", "2", "3"
    } else {
      selectedRoleId = "2"; // default Operator Polda
    }

    selectedPoldaId = data["polda_id"]?.toString();

    // Status: map API value to bool
    final rawStatus = data["status"]?.toString().toLowerCase() ?? "";
    aktif = rawStatus == "aktif" || rawStatus == "1" || rawStatus == "active";

    // Keep password hint empty
  } else {
    // Create mode defaults
    selectedRoleId = "2";
    selectedPoldaId = null;
    aktif = true;
  }

  getPoldaList();
}
```

- [ ] **Step 4: Add `getPoldaList()` method**

```dart
Future<void> getPoldaList() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final response = await http.get(
      Uri.parse("$apiBaseUrl/api/v1/polda"),
      headers: {"Authorization": token.toString()},
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (mounted) {
        setState(() {
          daftarPolda = List<Map<String, dynamic>>.from(json["data"] ?? []);
        });
      }
    }
  } catch (e) {
    debugPrint("Gagal memuat daftar polda: $e");
  }
}
```

- [ ] **Step 5: Add `submitUser()` method**

```dart
Future<void> submitUser() async {
  // Validate required fields
  if (username.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Username wajib diisi"),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (!isEditMode && password.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Password wajib diisi untuk akun baru"),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (selectedRoleId == "2" && (selectedPoldaId == null || selectedPoldaId!.isEmpty)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Polda wajib diisi untuk Operator Polda"),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  setState(() => isSubmitting = true);

  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    // Build request body
    final Map<String, dynamic> body = {
      "username": username.text.trim(),
      "roles_id": selectedRoleId,
      "status": aktif ? "aktif" : "tidak_aktif",
    };

    // Only include polda_id for Operator Polda
    if (selectedRoleId == "2" && selectedPoldaId != null) {
      body["polda_id"] = selectedPoldaId;
    } else {
      body["polda_id"] = null; // Super Admin / Command Center
    }

    // Password: required for create, optional for edit (omit if blank)
    if (isEditMode) {
      if (password.text.trim().isNotEmpty) {
        body["password"] = password.text.trim();
      }
      // If password is blank in edit mode, don't send it at all
    } else {
      body["password"] = password.text.trim(); // required for create
    }

    final http.Response response;

    if (isEditMode) {
      // PUT /api/v1/user/:id
      response = await http.put(
        Uri.parse("$apiBaseUrl/api/v1/user/${widget.userId}"),
        headers: {
          "Authorization": token.toString(),
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );
    } else {
      // POST /api/v1/user
      response = await http.post(
        Uri.parse("$apiBaseUrl/api/v1/user"),
        headers: {
          "Authorization": token.toString(),
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );
    }

    if (!mounted) return;

    final result = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"] ?? (isEditMode ? "Pengguna berhasil diupdate" : "Pengguna berhasil ditambahkan")),
          backgroundColor: Colors.green,
        ),
      );
      // Pop back to user list (the list page will refresh via .then() callback)
      Navigator.pop(context, true); // true = data changed, triggers refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"] ?? "Gagal menyimpan data"),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    debugPrint("Error submit user: $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Terjadi kesalahan jaringan"),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => isSubmitting = false);
    }
  }
}
```

- [ ] **Step 6: Replace hardcoded role dropdown with role_id-based dropdown**

Replace the hardcoded `DropdownMenuItem<String>` list (appears twice — desktop and mobile layouts) with:

```dart
// OLD (both occurrences — lines 129–142 and 173–197):
DropdownButtonFormField<String>(
  value: role,
  decoration: _inputDecoration,
  items: const [
    DropdownMenuItem(value: "Super Admin", child: Text("Super Admin")),
    DropdownMenuItem(value: "Operator Polda", child: Text("Operator Polda")),
    DropdownMenuItem(value: "Operator Polres", child: Text("Operator Polres")),
  ],
  onChanged: (v) { setState(() { role = v!; }); },
),

// NEW:
DropdownButtonFormField<String>(
  value: selectedRoleId,
  decoration: _inputDecoration,
  items: const [
    DropdownMenuItem(value: "1", child: Text("Super Admin")),
    DropdownMenuItem(value: "2", child: Text("Operator Polda")),
    DropdownMenuItem(value: "3", child: Text("Command Center")),
  ],
  onChanged: (v) {
    setState(() {
      selectedRoleId = v;
      // Clear polda selection if role changes away from Operator Polda
      if (v != "2") {
        selectedPoldaId = null;
      }
    });
  },
),
```

Note: "Operator Polres" (role_id=4) is removed because it doesn't exist in the database per RBAC rules. "Command Center" (role_id=3) is added — it was missing from the dropdown entirely, but the app has a Command Center role with full menu configuration in `menu_config.dart`.

- [ ] **Step 7: Replace hardcoded polda dropdown with API-fetched dynamic dropdown**

Replace both occurrences of the hardcoded Polda dropdown with:

```dart
// OLD (both occurrences):
DropdownButtonFormField<String>(
  value: polda,
  decoration: _inputDecoration,
  items: const [
    DropdownMenuItem(value: "Polda Jawa Barat", child: Text("Polda Jawa Barat")),
    DropdownMenuItem(value: "Polda Metro Jaya", child: Text("Polda Metro Jaya")),
    DropdownMenuItem(value: "Polda Jawa Tengah", child: Text("Polda Jawa Tengah")),
  ],
  onChanged: (v) { setState(() { polda = v; }); },
),

// NEW:
DropdownButtonFormField<String>(
  value: selectedPoldaId,
  decoration: _inputDecoration,
  hint: const Text("Pilih Polda"),
  items: daftarPolda.map((p) {
    return DropdownMenuItem<String>(
      value: p["id"]?.toString(),
      child: Text(p["nama_polda"]?.toString() ?? "-"),
    );
  }).toList(),
  onChanged: (v) {
    setState(() {
      selectedPoldaId = v;
    });
  },
),
```

The conditional display logic changes from `if (role == "Operator Polda")` to `if (selectedRoleId == "2")` — both occurrences.

- [ ] **Step 8: Replace submit button with wired version and add loading state**

Replace `onPressed: () {}` with `onPressed: isSubmitting ? null : submitUser`, update label:

```dart
// OLD (lines 307–322):
SizedBox(
  width: double.infinity,
  height: 50,
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xffF6B300),
      foregroundColor: const Color(0xFF23251D),
      shape: const StadiumBorder(),
    ),
    onPressed: () {},
    child: const Text("Simpan Akun", style: TextStyle(fontSize: 18)),
  ),
),

// NEW:
SizedBox(
  width: double.infinity,
  height: 50,
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xffF6B300),
      foregroundColor: const Color(0xFF23251D),
      shape: const StadiumBorder(),
    ),
    onPressed: isSubmitting ? null : submitUser,
    child: isSubmitting
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF23251D),
            ),
          )
        : Text(
            isEditMode ? "Update Akun" : "Simpan Akun",
            style: const TextStyle(fontSize: 18),
          ),
  ),
),
```

- [ ] **Step 9: Update title text for edit mode**

Replace the hardcoded title:

```dart
// OLD (lines 65–68):
const Text(
  "TAMBAH AKUN BARU",
  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
),

// NEW:
Text(
  isEditMode ? "EDIT AKUN" : "TAMBAH AKUN BARU",
  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
),
```

- [ ] **Step 10: Update the password field label for edit mode**

In edit mode, the password field should indicate it's optional:

```dart
// For edit mode, change:
label: "Password *" → label: isEditMode ? "Password (kosongkan jika tidak berubah)" : "Password *"
```

### Task 3: Wire Edit navigation in `UserPage`

**Files:**
- Modify: `lib/pages/user_page.dart` (the `onEdit` callback, lines 236–237)
- Modify: `lib/pages/add_user.dart` (add optional parameters)

**Interfaces:**
- Consumes: `FormTambahUser` (now with optional params), `AddUserPage` (now with optional params)
- Produces: Working edit flow — user list → add_user page with pre-filled form → PUT API → refresh list

**Steps:**

- [ ] **Step 1: Update `AddUserPage` to accept optional parameters**

Modify `lib/pages/add_user.dart`:

```dart
class AddUserPage extends StatefulWidget {
  final int? userId;       // null = create, non-null = edit
  final Map<String, dynamic>? userData; // pre-fill data

  const AddUserPage({super.key, this.userId, this.userData});

  // ... rest unchanged
}
```

Update the `FormTambahUser` instantiation (line 118):

```dart
// OLD:
child: const FormTambahUser(),

// NEW:
child: FormTambahUser(
  userId: widget.userId,
  initialData: widget.userData,
),
```

Note: The `const` keyword is removed because the widget is no longer compile-time constant.

Update the breadcrumb:

```dart
// OLD:
AppHeader(breadcrumb: "Dashboard / Tambah User", ...)

// NEW:
AppHeader(
  breadcrumb: widget.userId != null
      ? "Dashboard / Edit User"
      : "Dashboard / Tambah User",
  ...
)
```

- [ ] **Step 2: Wire `onEdit` callback in `_UserPageState`**

Replace the empty `onEdit: () {}` at lines 236–237:

```dart
// OLD (lines 236–239):
DataCell(
  ActionButtons(
    onEdit: () {},
    onDelete: () {}, // already wired in Task 1
  ),
),

// NEW:
DataCell(
  ActionButtons(
    onEdit: () {
      final id = int.tryParse("${e["id"]}");
      if (id == null || id <= 0) return; // guard against invalid/missing id

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddUserPage(
            userId: id,
            userData: e, // pass the entire row map
          ),
        ),
      ).then((result) {
        // Refresh list when returning from add/edit page
        if (result == true) {
          getUsers();
        }
      });
    },
    onDelete: () async { /* ... already wired in Task 1 ... */ },
  ),
),
```

Key details:
- Passes `userId` and the entire row map as `userData` — the form extracts what it needs
- Uses `.then((result) {...})` to refresh the list when `Navigator.pop(context, true)` is called from the form
- `int.tryParse` guards against null/missing id

- [ ] **Step 3: Verify — hot reload and test full edit flow**

1. Launch the app: `flutter run`
2. Navigate to "Daftar Pengguna"
3. Tap the edit (pencil) icon on any user row
4. Verify the form opens with:
   - Title "EDIT AKUN" (not "TAMBAH AKUN BARU")
   - Username pre-filled with existing value
   - Password field empty with hint "kosongkan jika tidak berubah"
   - Role dropdown showing current role
   - Polda dropdown (if Operator Polda) showing current polda
   - Status switch reflecting current status
5. Change the username, leave password blank, tap "Update Akun"
6. Verify SnackBar appears, page pops back, list refreshes with updated username
7. Test: change password too — verify it updates
8. Test: change role from Operator Polda to Super Admin — verify Polda dropdown disappears

---

## 4. State Management

### 4.1 Refresh Strategy

```
Edit flow:
  UserPage ──Navigator.push──→ AddUserPage ──submit──→ API PUT
     ↑                                                      │
     └──── .then((result) => getUsers()) ←── Navigator.pop(context, true)

Delete flow:
  UserPage ──showDialog──→ AlertDialog ──confirm──→ deleteUser(id)
     ↑                                                    │
     └──── getUsers() ←────────────────────────────────────┘

Create flow (unchanged):
  UserPage ──Navigator.push──→ AddUserPage ──submit──→ API POST
     ↑                                                      │
     └──── .then((result) => getUsers()) ←── Navigator.pop(context, true)
```

### 4.2 Mechanism

| Trigger | Refresh Method | How |
|---------|---------------|-----|
| Successful DELETE | `getUsers()` called directly in `deleteUser()` | After `response.statusCode == 200`, `getUsers()` re-fetches the full user list from API and `setState` updates `users` |
| Successful PUT (edit) | `Navigator.pop(context, true)` → `.then((result) => getUsers())` | Form pops with `true` (data changed). The `.then()` callback on the `Navigator.push` chain triggers `getUsers()` |
| Successful POST (create) | Same as edit | `Navigator.pop(context, true)` → `.then()` → `getUsers()` |
| Unsuccessful operations | No refresh | List stays as-is; error SnackBar shown |
| Cancel / back button | `Navigator.pop(context)` (no result) | `.then((result) => getUsers())` — `result` is `null`, so `result == true` is false, no refresh |

### 4.3 Why This Approach

1. **Matches existing patterns** — `personel.dart`, `polda.dart`, etc. all use the same `.then((result) => getXxxApi())` pattern for the add-navigate-back flow
2. **No state management library needed** — the app uses pure `StatefulWidget` + `setState`, no Provider/Riverpod/Bloc. Introducing one would be inconsistent
3. **Always fresh** — re-fetching from API after mutations ensures the table reflects the authoritative backend state, handling edge cases like concurrent changes
4. **Simple and debuggable** — direct method calls, no event buses or streams

---

## 5. Verification Checklist

After all tasks are complete, verify end-to-end:

### Delete
- [ ] Tap delete icon → confirmation dialog appears with username
- [ ] Tap "Batal" → dialog closes, user remains in list
- [ ] Tap "Hapus" → SnackBar "Pengguna berhasil dihapus" appears, list refreshes, user gone
- [ ] Test with network error → SnackBar "Terjadi kesalahan jaringan" appears

### Edit
- [ ] Tap edit icon → form opens with "EDIT AKUN" title
- [ ] Username pre-filled, password empty with hint text
- [ ] Role dropdown shows current role
- [ ] Polda dropdown shows current polda (if Operator Polda)
- [ ] Change username, leave password blank → "Update Akun" → success SnackBar, list refreshed
- [ ] Edit again, change password → success, list refreshed
- [ ] Change role from "Operator Polda" to "Super Admin" → Polda dropdown disappears
- [ ] Change role back to "Operator Polda" → Polda dropdown reappears, must select a polda
- [ ] Try to submit with empty username → validation SnackBar
- [ ] Test with network error → SnackBar "Terjadi kesalahan jaringan", form stays open

### Create (regression)
- [ ] "Tambah Pengguna" button still opens form with "TAMBAH AKUN BARU" title
- [ ] Form works for creating new users (password required, all fields)
- [ ] Successful create → SnackBar, list refreshes
- [ ] Back button returns to list without refreshing (unless data changed)

### Data Integrity
- [ ] GET `/api/v1/user` now sends auth token (check via network inspector or backend logs)
- [ ] Role dropdown no longer shows "Operator Polres"
- [ ] Polda dropdown populated from API, not hardcoded

---

## 6. Files Summary

| File | Action | Scope |
|------|--------|-------|
| `lib/pages/user_page.dart` | **Modify** | Add `deleteUser()` method, wire `onEdit`/`onDelete`, add auth token to GET |
| `lib/widget/form_input_user.dart` | **Modify** | Add `userId`/`initialData` params, dynamic dropdowns, `submitUser()`, POST+PUT logic, validation |
| `lib/pages/add_user.dart` | **Modify** | Add `userId`/`userData` optional params, dynamic breadcrumb, remove `const` from FormTambahUser |

No new files needed. No files deleted.
