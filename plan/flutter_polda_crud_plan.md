# Flutter Polda CRUD — Edit & Delete Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire up the Edit and Delete buttons in the Polda list page with full API integration, SnackBar feedback, and list refresh — mirroring the established User Management pattern.

**Architecture:** Adapt the existing create-only `FormTambahPolda` / `AddPoldaPage` into dual-purpose Create/Edit components by adding optional `poldaId` and `poldaData` parameters. Enhance the delete flow with typed confirmation dialog, RESTful path-param DELETE, and SnackBar feedback. All changes follow the exact patterns from `user_page.dart` + `add_user.dart` + `form_input_user.dart`.

**Tech Stack:** Flutter, Dart, `http` package, `shared_preferences`

**API Endpoints (confirmed):**
- `GET /api/v1/polda` — list all (existing, unchanged)
- `POST /api/v1/polda` — create (existing, standardized headers)
- `PUT /api/v1/master/polda/(:num)` — update (new)
- `DELETE /api/v1/master/polda/(:num)` — soft delete (new, RESTful path-param)

---

## UI & Form Audit

### Polda List Page (`lib/pages/polda.dart`)

- **DataTable**: Renders 6 columns — ID, NAMA POLDA, LATITUDE, LONGITUDE, CREATED AT, AKSI
- **ActionButtons**: Wired in the last DataCell with:
  - `onEdit: () {}` — **EMPTY STUB**, clicking does nothing
  - `onDelete:` — Working confirm `AlertDialog` → `deletePolda(p.id)`, but NO SnackBar feedback (only `debugPrint`)
- **deletePolda(int id)**: Sends `DELETE /api/v1/polda` with body `{"polda_id": id}` — works but no user feedback
- **"Tambah Polda" button**: Pushes `const AddPoldaPage()` with NO `.then()` refresh callback
- **Uses typed `Polda` model** (the only entity page with a model class): `id`, `namaPolda`, `latitude` (double), `longitude` (double), `createdAt`

### Add Polda Form (`lib/widget/form_input_polda.dart`)

- **Constructor**: `const FormTambahPolda({super.key})` — create-only, no optional params
- **Fields**: 3 `TextEditingController`s — `namaPolda`, `lat`, `long`
- **GPS fields exist**: YES — both Latitude and Longitude fields are present
- **`simpanPolda()`**: POSTs to `/api/v1/polda`, clears fields on success, does NOT pop
- **Title**: Hardcoded `"TAMBAH POLDA BARU"`
- **Loading state**: `bool loading` is set but never consumed in the UI (button doesn't disable/spin)
- **Dead code**: `String? pangkat;` — declared but never used

### Add Polda Page (`lib/pages/add_polda.dart`)

- **Constructor**: `const AddPoldaPage({super.key})` — no optional edit params
- **Breadcrumb**: Hardcoded `"Dashboard / Tambah Polda"`
- **Form**: `const Padding(..., child: FormTambahPolda())` — no way to pass prefill data

### Reference Pattern: User Management

The User Management feature (`user_page.dart` + `add_user.dart` + `form_input_user.dart`) is the **only entity with working Edit** and is the exact pattern to replicate:

| Pattern | User Management | Polda (current) |
|---------|----------------|-----------------|
| AddPage params | `int? userId`, `Map? userData` | None |
| Form params | `int? userId`, `Map? initialData` | None |
| Edit detection | `isEditMode = userId != null && initialData != null` | N/A |
| Submit branching | PUT for edit, POST for create | POST only |
| Success behavior | `Navigator.pop(context, true)` | Clears fields, stays on page |
| List refresh | `.then((result) { if (result == true) refresh(); })` | None |
| Delete dialog | `showDialog<bool>`, red Hapus button, interpolated name | Untyped `showDialog`, default button |
| Delete API | `DELETE /api/v1/user/$id` (RESTful path param) | `DELETE /api/v1/polda` + body `{"polda_id": id}` |
| SnackBar feedback | Green success / red failure, `mounted` guards | `debugPrint` only |

---

## Delete Implementation Plan

### Step-by-step modifications to `lib/pages/polda.dart`

#### Step 1: Rewrite `deletePolda()` — RESTful path-param + SnackBars + mounted guard

**Replace** the existing `deletePolda` method (lines 85–108):

```dart
Future<void> deletePolda(int id) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.delete(
      Uri.parse("$apiBaseUrl/api/v1/master/polda/$id"),
      headers: {
        "Authorization": token.toString(),
      },
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"] ?? "Polda berhasil dihapus"),
          backgroundColor: Colors.green,
        ),
      );
      getPoldaApi(); // refresh list
    } else {
      final result = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"] ?? "Gagal menghapus Polda"),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    debugPrint("Error delete polda: $e");
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

Changes from existing:
- URL: `$apiBaseUrl/api/v1/master/polda/$id` (RESTful path-param, master prefix)
- Removed `Content-Type` header and `body` (not needed for path-param DELETE)
- Added green/red SnackBar feedback from server `message` field
- Added `if (!mounted) return;` guards before `setState`/`ScaffoldMessenger`

#### Step 2: Enhance the onDelete confirmation dialog — typed `showDialog<bool>`, red Hapus button, interpolated name

**Replace** the existing `onDelete` callback inside the `ActionButtons` DataCell (lines 337–379):

```dart
onDelete: () async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Hapus Polda"),
      content: Text(
        "Apakah Anda yakin ingin menghapus Polda \"${p.namaPolda}\"?",
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
    deletePolda(p.id);
  }
},
```

Changes from existing:
- `showDialog` → `showDialog<bool>` (typed, prevents dynamic result issues)
- Content now interpolates `p.namaPolda` so user knows exactly which record
- Hapus button styled red with white text (matches user_page.dart pattern)
- Uses `p` from the enclosing `.map()` closure

---

## Edit Implementation Plan

### Step-by-step modifications (in dependency order)

### File 1: `lib/widget/form_input_polda.dart` — Dual Create/Edit Form

#### Step 3: Add optional constructor parameters

**Replace** the class declaration and constructor (lines 7–11):

```dart
class FormTambahPolda extends StatefulWidget {
  final int? poldaId; // null = create mode, non-null = edit mode
  final Map<String, dynamic>? poldaData; // pre-fill data for edit

  const FormTambahPolda({
    super.key,
    this.poldaId,
    this.poldaData,
  });

  @override
  State<FormTambahPolda> createState() => _FormTambahPoldaState();
}
```

#### Step 4: Update state fields — add `isEditMode`, remove dead `pangkat`

**Replace** the state fields (lines 14–19):

```dart
class _FormTambahPoldaState extends State<FormTambahPolda> {
  late bool isEditMode;
  final namaPolda = TextEditingController();
  final lat = TextEditingController();
  final long = TextEditingController();
  bool loading = false;
```

Remove `String? pangkat;` — it's never read or written.

#### Step 5: Add `initState` for edit-mode prefill

**Insert** after the state fields (before `simpanPolda`):

```dart
@override
void initState() {
  super.initState();
  isEditMode = widget.poldaId != null && widget.poldaData != null;

  if (isEditMode && widget.poldaData != null) {
    final data = widget.poldaData!;
    namaPolda.text = data["nama_polda"]?.toString() ?? "";
    lat.text = data["latitude"]?.toString() ?? "";
    long.text = data["longitude"]?.toString() ?? "";
  }
}
```

Note: `latitude`/`longitude` arrive as `double` from the `Polda` model. `.toString()` on e.g. `-6.900000` produces exactly the string format the API expects.

#### Step 6: Rewrite `simpanPolda()` — branch POST/PUT, pop on success

**Replace** the entire `simpanPolda` method (lines 22–79):

```dart
Future<void> simpanPolda() async {
  if (namaPolda.text.isEmpty || lat.text.isEmpty || long.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Semua data wajib diisi"),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  setState(() {
    loading = true;
  });

  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final Map<String, dynamic> body = {
      "nama_polda": namaPolda.text,
      "latitude": lat.text,
      "longitude": long.text,
    };

    final http.Response response;

    if (isEditMode) {
      // PUT /api/v1/master/polda/:id
      response = await http.put(
        Uri.parse("$apiBaseUrl/api/v1/master/polda/${widget.poldaId}"),
        headers: {
          "Authorization": token.toString(),
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );
    } else {
      // POST /api/v1/polda — create new
      response = await http.post(
        Uri.parse("$apiBaseUrl/api/v1/polda"),
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
          content: Text(
            result["message"] ??
                (isEditMode
                    ? "Data Polda berhasil diperbarui"
                    : "Data Polda berhasil disimpan"),
          ),
          backgroundColor: Colors.green,
        ),
      );
      // Pop back to Polda list; list page refreshes via .then() callback
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
    debugPrint("Error simpan polda: $e");
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
      setState(() {
        loading = false;
      });
    }
  }
}
```

Key changes:
- POST header standardized to `"Authorization"` + `"Content-Type: application/json"` (was lowercase `"authorization"` without Content-Type)
- PUT branch added: `$apiBaseUrl/api/v1/master/polda/${widget.poldaId}`
- Removed `namaPolda.clear()` / `lat.clear()` / `long.clear()` — we now pop instead
- `Navigator.pop(context, true)` after success — enables the list page's `.then()` refresh

#### Step 7: Dynamic title text

**Replace** the hardcoded title (line ~113):

```dart
Text(
  isEditMode ? "EDIT POLDA" : "TAMBAH POLDA BARU",
  style: const TextStyle(
      fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
),
```

#### Step 8: Submit button — consume `loading`, dynamic label

**Replace** the `SizedBox` + `ElevatedButton` block (lines ~157–169):

```dart
SizedBox(
  width: double.infinity,
  height: 50,
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xffF6B300),
      foregroundColor: const Color(0xFF23251D),
      shape: const StadiumBorder(),
    ),
    onPressed: loading ? null : simpanPolda,
    child: loading
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF23251D),
            ),
          )
        : Text(
            isEditMode ? "Update Polda" : "Simpan Data",
            style: const TextStyle(fontSize: 18),
          ),
  ),
),
```

The `_inputDecoration` static, field labels, and layout remain unchanged.

---

### File 2: `lib/pages/add_polda.dart` — Edit-Capable Page Wrapper

#### Step 9: Add optional edit parameters to `AddPoldaPage`

**Replace** the class declaration (lines 9–14):

```dart
class AddPoldaPage extends StatefulWidget {
  final int? poldaId; // null = create, non-null = edit
  final Map<String, dynamic>? poldaData; // pre-fill data

  const AddPoldaPage({super.key, this.poldaId, this.poldaData});

  @override
  State<AddPoldaPage> createState() => _AddPoldaPageState();
}
```

Backward compatible — `menu_config.dart` only references `PoldaPage`, not `AddPoldaPage`. No other call sites exist.

#### Step 10: Dynamic breadcrumb

**Replace** the `AppHeader` breadcrumb (line ~58):

```dart
AppHeader(
  breadcrumb: widget.poldaId != null
      ? "Dashboard / Edit Polda"
      : "Dashboard / Tambah Polda",
  username: unLogin,
  role: roleLabel,
),
```

#### Step 11: Pass params to form, remove `const` from Padding

**Replace** the `Padding` wrapping `FormTambahPolda` (lines ~116–119):

```dart
child: Padding(
  padding: const EdgeInsets.all(25),
  child: FormTambahPolda(
    poldaId: widget.poldaId,
    poldaData: widget.poldaData,
  ),
),
```

Note: `const` removed from `Padding` because `FormTambahPolda(...)` with non-const args is not const-constructible.

---

### File 3: `lib/pages/polda.dart` — Wire Edit + Add Refresh

#### Step 12: Add `.then()` refresh to "Tambah Polda" button

**Replace** the button's `onPressed` (lines ~212–220):

```dart
onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AddPoldaPage()),
  ).then((result) {
    if (result == true) {
      getPoldaApi();
    }
  });
},
```

#### Step 13: Implement the `onEdit` callback

**Replace** the empty stub `onEdit: () {}` (line ~336):

```dart
onEdit: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AddPoldaPage(
        poldaId: p.id,
        poldaData: {
          "nama_polda": p.namaPolda,
          "latitude": p.latitude,
          "longitude": p.longitude,
        },
      ),
    ),
  ).then((result) {
    if (result == true) {
      getPoldaApi();
    }
  });
},
```

#### Step 14 (Optional cleanup): Standardize GET header

In `getPoldaApi()`, change `"authorization"` to `"Authorization"` on the GET line. HTTP headers are case-insensitive so this is cosmetic — but it aligns with all other calls in the file.

---

## Sequencing & Dependencies

```
form_input_polda.dart  →  add_polda.dart  →  polda.dart
      (Step 3-8)           (Step 9-11)       (Step 1-2, 12-13)
```

1. **Steps 3–8** (`form_input_polda.dart`) — Add params, initState, PUT/POST branching, pop on success, dynamic UI
2. **Steps 9–11** (`add_polda.dart`) — Accept edit params, dynamic breadcrumb, pass to form (depends on Step 3 for the new `FormTambahPolda` constructor signature)
3. **Steps 1–2, 12–13** (`polda.dart`) — Enhanced delete, onEdit wiring, add refresh (depends on Steps 9–11 for the new `AddPoldaPage` constructor signature)

Run after all changes:
```bash
dart format lib/widget/form_input_polda.dart lib/pages/add_polda.dart lib/pages/polda.dart
flutter analyze
```

Expect zero analysis errors.

---

## Verification Checklist

- [ ] **Create flow**: Tambah Polda → fill form → Simpan Data → green SnackBar "Data Polda berhasil disimpan" → page pops → list refreshes with new row
- [ ] **Edit flow**: Pencil icon → "EDIT POLDA" title, breadcrumb "Dashboard / Edit Polda" → all 3 fields pre-filled with correct values → change Nama Polda → "Update Polda" → green SnackBar → pops → list shows updated value
- [ ] **Edit — coordinates**: Edit a Polda → verify latitude/longitude fields are pre-filled with correct coordinate values → change one → submit → list refreshes with new coordinates
- [ ] **Delete flow**: Trash icon → dialog shows "Hapus Polda" with the Polda name → red "Hapus" button → green SnackBar "Polda berhasil dihapus" → list refreshes without that row
- [ ] **Delete cancel**: Dialog → "Batal" → dialog closes, list unchanged, no API call
- [ ] **Network error**: Kill server → attempt create/edit/delete → red SnackBar, no crash (validates `mounted` guards)
- [ ] **Validation**: Submit with empty Nama Polda → red SnackBar "Semua data wajib diisi" → stays on page
- [ ] **Static analysis**: `flutter analyze` reports zero errors

---

## Files Modified (Summary)

| File | Changes |
|------|---------|
| `lib/widget/form_input_polda.dart` | Add `poldaId`/`poldaData` params, `initState` prefill, `isEditMode`, PUT branch, `Navigator.pop(context, true)`, dynamic title/button, remove dead `pangkat` |
| `lib/pages/add_polda.dart` | Add `poldaId`/`poldaData` params, dynamic breadcrumb, remove `const` from Padding, pass params to `FormTambahPolda` |
| `lib/pages/polda.dart` | RESTful delete with SnackBars, typed confirmation dialog with name + red button, `onEdit` navigation + `.then()` refresh, add `.then()` to Tambah button, optional header case cleanup |
