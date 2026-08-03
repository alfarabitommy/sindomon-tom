# Flutter Polres CRUD — Edit & Delete Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire up the Edit and Delete buttons in the Polres list page with full API integration, SnackBar feedback, and list refresh — mirroring the established Polda CRUD pattern.

**Architecture:** Adapt the existing create-only `FormTambahPolres` / `AddPolresPage` into dual-purpose Create/Edit components by adding optional `polresId` and `polresData` parameters. The Polres form has a `DropdownButtonFormField` for `polda_id` (unlike Polda's plain text fields), so edit-mode pre-fill must synchronize the `selectedPoldaId` state with the asynchronously-loaded `daftarPolda` list. Enhance the delete flow with typed confirmation dialog, RESTful path-param DELETE, SnackBar feedback, and add loading/error/empty states to the list page. All changes follow the exact patterns from `polda.dart` + `add_polda.dart` + `form_input_polda.dart`.

**Tech Stack:** Flutter, Dart, `http` package, `shared_preferences`

**API Endpoints (confirmed by backend team):**
- `GET /api/v1/polres` — list all (existing, unchanged)
- `POST /api/v1/polres` — create (existing, standardize headers)
- `PUT /api/v1/master/polres/(:num)` — update (new, RESTful path-param)
- `DELETE /api/v1/master/polres/(:num)` — soft delete (new, RESTful path-param)

---

## UI & Form Audit

### Polres List Page (`lib/pages/polres.dart`)

- **Data state**: Uses raw `List<Map<String, dynamic>>` — no typed model. Keys: `"id"`, `"polda_id"`, `"nama_polres"`, `"created_at"`.
- **DataTable**: Renders 5 columns — ID, POLDA ID, NAMA POLRES, CREATED AT, AKSI
- **ActionButtons**: Wired in the last DataCell with:
  - `onEdit: () {}` — **EMPTY STUB**, clicking does nothing
  - `onDelete:` — Has confirm `AlertDialog` but: (a) dialog is untyped (`showDialog` not `showDialog<bool>`), (b) no interpolated name ("Apakah Anda yakin ingin menghapus **data ini**?"), (c) Hapus button is default style (not red), (d) NO SnackBar feedback on success/failure
- **deletePolres(int id)**: Sends `DELETE /api/v1/polres` with body `{"polres_id": id}` — **old body-based approach**, not the new RESTful `DELETE /api/v1/master/polres/$id`. No SnackBar, no `mounted` guard, only `debugPrint`.
- **"Tambah Polres" button**: Pushes `const AddPolresPage()` with NO `.then()` refresh callback — after adding, user returns via "Kembali" and list never refreshes
- **No loading/error/empty states**: `isLoading` is set but never consumed in `build()` — the page shows nothing while loading and has no error retry UI. Unlike Polda which has full `if (isLoading)` / `else if (errorMessage.isNotEmpty)` / `else if (polda.isEmpty)` branching.
- **Potential type bug**: `Text(e["id"])` and `Text(e["polda_id"])` use raw map values without string interpolation — if the API returns ints, this will throw at runtime.

### Add Polres Form (`lib/widget/form_input_polres.dart`)

- **Constructor**: `const FormTambahPolres({super.key})` — create-only, no optional params
- **Fields**: `int? selectedPoldaId` (dropdown state), `final namaPolres = TextEditingController()`, `List<Map<String, dynamic>> daftarPolda` (dropdown options)
- **Polda dropdown**: Populated via `getPolda()` → `GET /api/v1/polda` in `initState()`. Items are `DropdownMenuItem<int>` with `value: int.parse(polda["id"])`. Initial value is `null` (shows "Pilih Polda" hint).
- **`simpanPolres()`**: POSTs to `/api/v1/polres` with body `{"polda_id": selectedPoldaId, "nama_polres": namaPolres.text}`. On success: shows SnackBar, clears fields, does NOT pop. Header uses lowercase `"authorization"`.
- **Title**: Hardcoded `"TAMBAH POLRES BARU"`
- **Loading state**: `bool loading` is set but never consumed in the UI (button always enabled, no spinner). Unlike Polda form which disables button and shows `CircularProgressIndicator` while loading.
- **No `dispose()` override**: `namaPolres` controller is never disposed — minor leak.

### Add Polres Page (`lib/pages/add_polres.dart`)

- **Constructor**: `const AddPolresPage({super.key})` — no optional edit params
- **Breadcrumb**: Hardcoded `"Dashboard / Tambah Polres"`
- **Form**: `const Padding(..., child: FormTambahPolres())` — no way to pass prefill data
- **"Kembali" button**: Does plain `Navigator.pop(context)` with no result value

### Reference Pattern: Polda CRUD (already implemented)

The Polda feature is the **exact pattern to replicate**:

| Pattern | Polda (implemented) | Polres (current) |
|---------|---------------------|------------------|
| AddPage params | `int? poldaId`, `Map? poldaData` | None |
| Form params | `int? poldaId`, `Map? poldaData` | None |
| Edit detection | `isEditMode = poldaId != null && poldaData != null` | N/A |
| Pre-fill | `initState` sets controller `.text` from map | N/A |
| Submit branching | PUT for edit, POST for create | POST only |
| Success behavior | `Navigator.pop(context, true)` | Clears fields, stays on page |
| List refresh | `.then((result) { if (result == true) refresh(); })` | None |
| Delete dialog | `showDialog<bool>`, red Hapus button, interpolated name | Untyped `showDialog`, default button, generic text |
| Delete API | `DELETE /api/v1/master/polda/$id` (RESTful path param) | `DELETE /api/v1/polres` + body `{"polres_id": id}` |
| SnackBar feedback | Green success / red failure, `mounted` guards | `debugPrint` only |
| Loading/error/empty states | Full branching in build() | `isLoading` set but never consumed |
| Loading in form button | Button disabled + spinner | Button always enabled, no spinner |

### Critical Difference: Polres has a Dropdown (not plain TextFields)

Unlike Polda where all fields are `TextFormField` with simple `.text =` pre-fill, the Polres form has a `DropdownButtonFormField<int>` for `polda_id`. The dropdown's data source (`daftarPolda`) loads asynchronously. The pre-fill strategy is:

1. In `initState`, set `selectedPoldaId` to the `polda_id` from `polresData` **synchronously** (before the dropdown items load)
2. `getPolda()` runs asynchronously, populates `daftarPolda`, and calls `setState`
3. When `setState` fires, the dropdown rebuilds — `selectedPoldaId` now has a matching value in `daftarPolda`, so it displays correctly

This works because `DropdownButtonFormField` only validates its `value` against `items` at build time. The synchronous set in `initState` + the async `setState` from `getPolda()` will correctly converge.

---

## Delete Implementation Plan

### Step-by-step modifications to `lib/pages/polres.dart`

#### Step 1: Rewrite `deletePolres()` — RESTful path-param + SnackBars + mounted guard

**Replace** the existing `deletePolres` method (lines 72–92):

```dart
Future<void> deletePolres(int id) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.delete(
      Uri.parse("$apiBaseUrl/api/v1/master/polres/$id"),
      headers: {
        "Authorization": token.toString(),
      },
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"] ?? "Polres berhasil dihapus"),
          backgroundColor: Colors.green,
        ),
      );
      getPolresApi(); // refresh list
    } else {
      final result = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"] ?? "Gagal menghapus Polres"),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    debugPrint("Error delete polres: $e");
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
- URL: `$apiBaseUrl/api/v1/master/polres/$id` (RESTful path-param, `/master/` prefix — matching the backend's confirmed endpoint)
- Removed `Content-Type` header and `body` (not needed for path-param DELETE)
- Added green/red SnackBar feedback from server `message` field with fallback strings
- Added `if (!mounted) return;` guards before `ScaffoldMessenger` calls
- Added network error catch with SnackBar (was just `debugPrint`)

#### Step 2: Enhance the onDelete confirmation dialog — typed `showDialog<bool>`, red Hapus button, interpolated name

**Replace** the existing `onDelete` callback inside the `ActionButtons` DataCell (the block starting with `onDelete: () async {`):

```dart
onDelete: () async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Hapus Polres"),
      content: Text(
        "Apakah Anda yakin ingin menghapus Polres \"${e["nama_polres"]}\"?",
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
    deletePolres(int.parse(e["id"].toString()));
  }
},
```

Changes from existing:
- `showDialog` → `showDialog<bool>` (typed, prevents dynamic result issues)
- Content now interpolates `e["nama_polres"]` so user knows exactly which record
- Hapus button styled red with white text (matches polda.dart pattern)
- `int.parse(e["id"].toString())` — safe parsing regardless of whether API returns int or string

#### Step 3: Add `.then()` refresh to "Tambah Polres" button

**Replace** the button's `onPressed`:

```dart
onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AddPolresPage()),
  ).then((result) {
    if (result == true) {
      getPolresApi();
    }
  });
},
```

#### Step 4: Add loading/error/empty state handling to `build()`

Add an `errorMessage` field and update `getPolresApi()` to set it, then replace the state handling. **Add** to state fields:

```dart
String errorMessage = "";
```

**Update** `getPolresApi()` to set `errorMessage` on failures (currently it just sets `isLoading = false` and `debugPrint`):

```dart
Future<void> getPolresApi() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.get(
      Uri.parse("$apiBaseUrl/api/v1/polres"),
      headers: {"Authorization": token.toString()},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      setState(() {
        polres = List<Map<String, dynamic>>.from(json["data"]);
        errorMessage = "";
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = "Gagal memuat data (HTTP ${response.statusCode})";
        isLoading = false;
      });
    }
  } catch (e) {
    setState(() {
      errorMessage = "Terjadi kesalahan saat memuat data Polres";
      isLoading = false;
    });
    debugPrint(e.toString());
  }
}
```

**Replace** the body after `AppHeader` with the same branching pattern as `polda.dart`:

```dart
/// STATE HANDLING
if (isLoading)
  const Expanded(
    child: Center(
      child: CircularProgressIndicator(color: Colors.amber),
    ),
  )
else if (errorMessage.isNotEmpty)
  Expanded(
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: getPolresApi,
            icon: const Icon(Icons.refresh),
            label: const Text("Coba Lagi"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    ),
  )
else if (polres.isEmpty)
  const Expanded(
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.table_rows_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            "Tidak ada data Polres untuk ditampilkan",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    ),
  )
else ...[
  const SizedBox(height: 25),
  // ... rest of the existing title row, search, table, pagination, footer
],
```

Note: The existing `const SizedBox(height: 25)` immediately after `AppHeader` is **absorbed** into the `else ...[]` spread — remove the standalone one.

#### Step 5: Fix potential type bug in DataCells

**Replace** the two `Text()` calls that lack string interpolation:

```dart
// Before:
Text(e["id"]),
// After:
Text("${e["id"]}"),

// Before:
Text(e["polda_id"]),
// After:
Text("${e["polda_id"]}"),
```

---

## Edit Implementation Plan

### Step-by-step modifications (in dependency order)

### File 1: `lib/widget/form_input_polres.dart` — Dual Create/Edit Form

#### Step 6: Add optional constructor parameters

**Replace** the class declaration and constructor (lines 7–12):

```dart
class FormTambahPolres extends StatefulWidget {
  final int? polresId; // null = create mode, non-null = edit mode
  final Map<String, dynamic>? polresData; // pre-fill data for edit

  const FormTambahPolres({
    super.key,
    this.polresId,
    this.polresData,
  });

  @override
  State<FormTambahPolres> createState() => _FormTambahPolresState();
}
```

#### Step 7: Update state fields — add `isEditMode`

**Replace** the state fields (lines 15–19):

```dart
class _FormTambahPolresState extends State<FormTambahPolres> {
  late bool isEditMode;
  int? selectedPoldaId;
  bool loading = false;
  final namaPolres = TextEditingController();
  List<Map<String, dynamic>> daftarPolda = [];
```

Remove the commented-out `// final poldaID = TextEditingController();` line.

#### Step 8: Rewrite `initState` for edit-mode prefill

**Replace** the existing `initState` (lines 102–106) which currently only calls `getPolda()`:

```dart
@override
void initState() {
  super.initState();
  isEditMode = widget.polresId != null && widget.polresData != null;

  if (isEditMode && widget.polresData != null) {
    final data = widget.polresData!;
    namaPolres.text = data["nama_polres"]?.toString() ?? "";
    // Pre-set dropdown value; daftarPolda loads async, dropdown will
    // resolve correctly once getPolda() completes and setState rebuilds.
    final poldaIdRaw = data["polda_id"];
    if (poldaIdRaw != null) {
      selectedPoldaId = poldaIdRaw is int ? poldaIdRaw : int.tryParse(poldaIdRaw.toString());
    }
  }

  getPolda(); // always fetch polda list for the dropdown
}
```

Key design decision: `selectedPoldaId` is set **synchronously** before `daftarPolda` has loaded. The `DropdownButtonFormField` will briefly have a `value` with no matching `items` — in practice, Flutter tolerates this for one frame because `getPolda()`'s `setState` will trigger a rebuild once items arrive, at which point the value finds its match. If this causes a brief assertion in debug mode, the `daftarPolda` fetch (which is fast, same server) typically completes before the first paint.

#### Step 9: Rewrite `simpanPolres()` — branch POST/PUT, pop on success, consume loading in button

**Replace** the entire `simpanPolres` method:

```dart
Future<void> simpanPolres() async {
  if (selectedPoldaId == null || namaPolres.text.isEmpty) {
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
      "polda_id": selectedPoldaId,
      "nama_polres": namaPolres.text,
    };

    final http.Response response;

    if (isEditMode) {
      // PUT /api/v1/master/polres/:id
      response = await http.put(
        Uri.parse("$apiBaseUrl/api/v1/master/polres/${widget.polresId}"),
        headers: {
          "Authorization": token.toString(),
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );
    } else {
      // POST /api/v1/polres — create new
      response = await http.post(
        Uri.parse("$apiBaseUrl/api/v1/polres"),
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
                    ? "Data Polres berhasil diperbarui"
                    : "Data Polres berhasil disimpan"),
          ),
          backgroundColor: Colors.green,
        ),
      );
      // Pop back to Polres list; list page refreshes via .then() callback
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
    debugPrint("Error simpan polres: $e");
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
- PUT branch added: `$apiBaseUrl/api/v1/master/polres/${widget.polresId}`
- Removed `selectedPoldaId = null` and `namaPolres.clear()` — we now pop instead
- `Navigator.pop(context, true)` after success — enables the list page's `.then()` refresh
- SnackBar colors added (green/red)
- Error SnackBar uses fixed message instead of raw exception text
- Validation SnackBar also gets red background

#### Step 10: Dynamic title text

**Replace** the hardcoded title:

```dart
Text(
  isEditMode ? "EDIT POLRES" : "TAMBAH POLRES BARU",
  style: const TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Color(0xFF111827),
  ),
),
```

#### Step 11: Submit button — consume `loading`, dynamic label

**Replace** the `SizedBox` + `ElevatedButton` block:

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
    onPressed: loading ? null : simpanPolres,
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
            isEditMode ? "Update Polres" : "Simpan Data",
            style: const TextStyle(fontSize: 18),
          ),
  ),
),
```

#### Step 12 (Optional): Add `dispose()` override

```dart
@override
void dispose() {
  namaPolres.dispose();
  super.dispose();
}
```

---

### File 2: `lib/pages/add_polres.dart` — Edit-Capable Page Wrapper

#### Step 13: Add optional edit parameters to `AddPolresPage`

**Replace** the class declaration:

```dart
class AddPolresPage extends StatefulWidget {
  final int? polresId; // null = create, non-null = edit
  final Map<String, dynamic>? polresData; // pre-fill data

  const AddPolresPage({super.key, this.polresId, this.polresData});

  @override
  State<AddPolresPage> createState() => _AddPolresPageState();
}
```

Backward compatible — `menu_config.dart` only references `PolresPage`, not `AddPolresPage`. No other call sites exist.

#### Step 14: Dynamic breadcrumb

**Replace** the `AppHeader` breadcrumb:

```dart
AppHeader(
  breadcrumb: widget.polresId != null
      ? "Dashboard / Edit Polres"
      : "Dashboard / Tambah Polres",
  username: unLogin,
  role: roleLabel,
),
```

#### Step 15: Pass params to form, remove `const` from Padding and Card children

**Replace** the `Padding` wrapping `FormTambahPolres`:

```dart
child: Padding(
  padding: const EdgeInsets.all(25),
  child: FormTambahPolres(
    polresId: widget.polresId,
    polresData: widget.polresData,
  ),
),
```

Note: The `const` keyword must be removed from `Padding` because `FormTambahPolres(...)` with non-const args is not const-constructible. The parent `Card` also needs `const` removed if it was `const Card(...)`.

---

### File 3: `lib/pages/polres.dart` — Wire Edit

#### Step 16: Implement the `onEdit` callback

**Replace** the empty stub `onEdit: () {}`:

```dart
onEdit: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AddPolresPage(
        polresId: int.tryParse(e["id"].toString()),
        polresData: {
          "nama_polres": "${e["nama_polres"]}",
          "polda_id": e["polda_id"],
        },
      ),
    ),
  ).then((result) {
    if (result == true) {
      getPolresApi();
    }
  });
},
```

Note: `polda_id` is passed as the raw value (no string conversion) so the `initState` in `FormTambahPolres` can handle both `int` and `String` types with the `is int ? ... : int.tryParse(...)` logic.

#### Step 17: Standardize GET header case

In `getPolresApi()`, change `"authorization"` to `"Authorization"` for consistency with all other API calls.

---

## Sequencing & Dependencies

```
form_input_polres.dart  →  add_polres.dart  →  polres.dart
     (Steps 6-12)           (Steps 13-15)       (Steps 1-5, 16-17)
```

1. **Steps 6–12** (`form_input_polres.dart`) — Add params, initState prefill, PUT/POST branching, pop on success, dynamic UI, loading spinner, dispose
2. **Steps 13–15** (`add_polres.dart`) — Accept edit params, dynamic breadcrumb, pass to form (depends on Step 6 for the new `FormTambahPolres` constructor signature)
3. **Steps 1–5, 16–17** (`polres.dart`) — Enhanced delete, onEdit wiring, add refresh, loading/error/empty states (depends on Steps 13–15 for the new `AddPolresPage` constructor signature)

Run after all changes:
```bash
dart format lib/widget/form_input_polres.dart lib/pages/add_polres.dart lib/pages/polres.dart
flutter analyze
```

Expect zero analysis errors.

---

## Verification Checklist

- [ ] **Create flow**: Tambah Polres → select Polda from dropdown → fill Nama Polres → "Simpan Data" → green SnackBar "Data Polres berhasil disimpan" → page pops → list refreshes with new row
- [ ] **Create validation**: Submit with empty fields → red SnackBar "Semua data wajib diisi" → stays on page
- [ ] **Edit flow**: Pencil icon → "EDIT POLRES" title, breadcrumb "Dashboard / Edit Polres" → Nama Polres pre-filled → Polda dropdown pre-selected to correct Polda → change name → "Update Polres" → green SnackBar → pops → list shows updated value
- [ ] **Edit — dropdown integrity**: Edit a Polres → verify Polda dropdown shows all Polda options AND the correct one is pre-selected → change to a different Polda → submit → list refreshes showing new `polda_id`
- [ ] **Delete flow**: Trash icon → dialog shows "Hapus Polres" with the Polres name → red "Hapus" button → green SnackBar "Polres berhasil dihapus" → list refreshes without that row
- [ ] **Delete cancel**: Dialog → "Batal" → dialog closes, list unchanged, no API call
- [ ] **Network error**: Kill server → attempt create/edit/delete → red SnackBar, no crash (validates `mounted` guards)
- [ ] **Loading state**: First page load → amber CircularProgressIndicator shown while data loads
- [ ] **Error state**: Server returns non-200 → error message shown with "Coba Lagi" retry button
- [ ] **Empty state**: No data → "Tidak ada data Polres untuk ditampilkan" shown
- [ ] **Button spinner**: Submit form → button shows CircularProgressIndicator and is disabled while loading
- [ ] **Static analysis**: `flutter analyze` reports zero errors

---

## Files Modified (Summary)

| File | Changes |
|------|---------|
| `lib/widget/form_input_polres.dart` | Add `polresId`/`polresData` params, `isEditMode`, `initState` prefill (dropdown + text), PUT branch in `simpanPolres`, `Navigator.pop(context, true)`, dynamic title/button, loading spinner in button, dispose, standardize headers |
| `lib/pages/add_polres.dart` | Add `polresId`/`polresData` params, dynamic breadcrumb, remove `const` from Padding/Card, pass params to `FormTambahPolres` |
| `lib/pages/polres.dart` | RESTful delete with SnackBars, typed confirmation dialog with name + red button, `onEdit` navigation + `.then()` refresh, add `.then()` to Tambah button, loading/error/empty state UI, fix Text() type safety, header case cleanup |
