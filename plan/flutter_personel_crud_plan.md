# Flutter Personil SDM CRUD — Full Refactoring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate the Personel CRUD from the old `/api/v1/personel` endpoints to the new RESTful `/api/v1/sdm/personil` endpoints, implement full Edit/Create/Delete with SnackBar feedback, loading/error/empty states, nullable Polres dropdown, and 422 NRP validation — mirroring the gold-standard Polres CRUD pattern.

**Architecture:** Three files form the complete CRUD flow: `personel.dart` (list page with DataTable), `add_personel_page.dart` (page wrapper with breadcrumb), and `form_input_personel.dart` (form widget with dropdowns). The form gains optional `personilId`/`personilData` constructor params for dual Create/Edit mode — replicating the exact `polresId`/`polresData` pattern from the Polres trio. The list page gains full state handling (loading spinner, error+retry, empty state) and RESTful path-param DELETE with typed confirmation dialog and green/red SnackBar feedback.

**Tech Stack:** Flutter, Dart, `http` package, `shared_preferences`

**API Endpoints (confirmed by backend team):**
- `GET /api/v1/sdm/personil` — list all
- `POST /api/v1/sdm/personil` — create
- `PUT /api/v1/sdm/personil/$uuid` — update (RESTful path-param, string UUID)
- `DELETE /api/v1/sdm/personil/$uuid` — soft delete (RESTful path-param, string UUID)

**Key Design Decision — UUID vs int:** The DB schema confirms `personil_id` is `varchar(36)` (UUID), but FK columns (`polda_id`, `polres_id`, `pangkat_id`, `jabatan_id`) remain `int(11)`. So only the route param and delete/list identifier use string UUIDs — dropdown values stay `int?`.

---

## UI & Form Audit

### Personel List Page (`lib/pages/personel.dart`) — Current State

| Aspect | Status | Issue |
|--------|--------|-------|
| GET endpoint | `/api/v1/personel` | **Wrong** — must be `/api/v1/sdm/personil` |
| DELETE endpoint | `/api/v1/personel` with body `{"personel_id": id}` | **Wrong** — must be RESTful `DELETE /api/v1/sdm/personil/$uuid` |
| ID type | `int.parse(e["id"])` | **Wrong** — `personil_id` is UUID string, `int.parse` will crash |
| SnackBar on delete | None | Only `debugPrint` — no user feedback |
| Loading state | `isLoading` set but never rendered | No spinner, blank page while loading |
| Error state | None | No error message, no retry button |
| Empty state | None | Blank table when no data |
| Edit button | `onEdit: () {}` | **No-op stub** |
| Add button refresh | No `.then()` callback | List never refreshes after adding |
| Delete dialog | Generic text "data ini" | No entity name interpolation |
| Delete button style | Default theme | Not red, inconsistent with polres/polda |
| Columns | NRP, NAMA LENGKAP, POLRES ID, STATUS AKTIF | Missing PANGKAT, JABATAN, POLDA name columns |

### Add Personel Page (`lib/pages/add_personel_page.dart`) — Current State

| Aspect | Status | Issue |
|--------|--------|-------|
| Constructor params | None | Create-only — no `personilId`/`personilData` |
| Breadcrumb | Hardcoded "Tambah Personel" | No Edit mode breadcrumb |
| Form instantiation | `const FormTambahPersonel()` | No params forwarded |

### Form Input Personel (`lib/widget/form_input_personel.dart`) — Current State

| Aspect | Status | Issue |
|--------|--------|-------|
| Submit mode | POST only | No PUT/edit branching |
| Endpoint | `$apiBaseUrl/api/v1/personel` | **Wrong** — must be `/api/v1/sdm/personil` |
| Loading state | None | Button always enabled, no spinner |
| 422 handling | None | NRP duplicate validation not surfaced |
| Polres "Tidak Ada" option | Missing | `polres_id` always required |
| Success behavior | Clears fields, stays on page | Should `Navigator.pop(context, true)` |
| Unused controllers | `polres`, `status` TextEditingControllers | Dead code |
| Duplicate annotation | `@override` twice at line 187-188 | Compile warning |
| `dispose()` | Missing | Minor memory leak |
| Dropdown pre-fill | N/A (no edit mode) | Must sync async-loaded dropdowns with prefill data |

### Reference Pattern: Polres CRUD (gold standard)

The Polres trio (`polres.dart` + `add_polres.dart` + `form_input_polres.dart`) is the **exact pattern to replicate**. Key patterns:

| Pattern | Polres (reference) |
|---------|-------------------|
| Delete API | `DELETE /api/v1/master/polres/$id` (RESTful path param) |
| Delete SnackBar | Green success / red failure, `mounted` guard |
| Delete dialog | `showDialog<bool>`, red Hapus button, interpolated name |
| Edit nav | `AddPolresPage(polresId: ..., polresData: {...})` + `.then()` refresh |
| Add nav | `.then((result) { if (result == true) getPolresApi(); })` |
| Form edit detection | `isEditMode = widget.polresId != null && widget.polresData != null` |
| Form submit branch | PUT for edit, POST for create |
| Form success | Green SnackBar + `Navigator.pop(context, true)` |
| Form loading | `bool loading`, button disabled + `CircularProgressIndicator` |
| Form validation | Red SnackBar "Semua data wajib diisi" before request |
| List loading state | `CircularProgressIndicator` (amber) |
| List error state | Error icon + message + "Coba Lagi" retry button |
| List empty state | Table icon + "Tidak ada data" message |

### Critical Difference: Personel has Cascade Dropdowns

Unlike Polres (single independent dropdown), the Personel form has a **cascade**: polda → polres. When polda changes, polres resets and repopulates from the polda's nested `polres` array. Edit prefill must:
1. Set `selectedPoldaId` synchronously in `initState`
2. After `getPolda()` async completes, extract the matching polda's nested `polres` to populate `daftarPolres`
3. The polres dropdown must include a "Tidak Ada / Mako Polda" sentinel option (value `0`, mapped to `null` in request body)

### "Tidak Ada / Mako Polda" Sentinel Design

Flutter's `DropdownButtonFormField` cannot show `null` as a selectable item (null means "show hint"). Solution: use sentinel value `0` (never a valid FK):

```dart
static const int _polresNone = 0;

// In the dropdown items list:
if (daftarPolres.isNotEmpty)
  const DropdownMenuItem<int>(
    value: _polresNone,
    child: Text("Tidak Ada / Mako Polda"),
  ),

// In the request body:
"polres_id": (selectedPolresId == null || selectedPolresId == _polresNone)
    ? null
    : selectedPolresId,
```

The sentinel item is guarded by `if (daftarPolres.isNotEmpty)` — a sentinel-only list with a mismatched real polres ID would crash `DropdownButton`'s assert.

---

## Task 1: Refactor Form Input Personel (`lib/widget/form_input_personel.dart`)

**Files:**
- Modify: `lib/widget/form_input_personel.dart` (complete replacement)

**Interfaces:**
- Produces: `FormTambahPersonel({String? personilId, Map<String, dynamic>? personilData})` — dual Create/Edit form
- Produces: `Navigator.pop(context, true)` on success (signals list page to refresh)
- Consumes: `apiBaseUrl` from `config/api_config.dart`

### Changes

1. **Constructor**: Add `String? personilId` and `Map<String, dynamic>? personilData` params
2. **State**: Add `late bool isEditMode`, `bool loading = false`, `static const int _polresNone = 0`, `int? _toInt(dynamic v)` helper
3. **Remove dead code**: Delete unused `polres` and `status` TextEditingControllers
4. **Add `dispose()`**: Dispose `nrp` and `namaLengkap` controllers
5. **`initState`**: Set `isEditMode` from params; prefill controllers and all four dropdown state values synchronously
6. **`getPolda()`**: Add edit-mode `daftarPolres` population block
7. **`submitPersonel()`**: Full rewrite:
   - Field validation guard (all required fields, polres optional)
   - `loading = true` with try/catch/finally
   - POST vs PUT branching to `/api/v1/sdm/personil`
   - `polres_id` sentinel → null mapping
   - Green SnackBar + `Navigator.pop(context, true)` on 200/201
   - Explicit 422 branch (red SnackBar, stays on form)
   - Red fallback for other errors
   - Network error catch with `mounted` guard
8. **Polres dropdown**: Add "Tidak Ada / Mako Polda" sentinel item (guarded), remove `*` from label
9. **Title/button**: Branch on `isEditMode` ("EDIT PERSONEL" / "TAMBAH PERSONEL BARU", "Update Personel" / "Simpan Data")
10. **Loading in button**: Disable button + show `CircularProgressIndicator` when `loading`
11. **Remove duplicated `@override`** on line 187-188

### Key Code Snippets

**Edit mode prefill in initState:**
```dart
isEditMode = widget.personilId != null && widget.personilData != null;

if (isEditMode && widget.personilData != null) {
  final data = widget.personilData!;
  nrp.text = data["nrp"]?.toString() ?? "";
  namaLengkap.text = data["nama_lengkap"]?.toString() ?? "";
  selectedPoldaId = _toInt(data["polda_id"]);
  selectedPolresId = _toInt(data["polres_id"]) ?? _polresNone;
  selectedPangkatId = _toInt(data["pangkat_id"]);
  selectedJabatanId = _toInt(data["jabatan_id"]);
}
```

**Edit-mode daftarPolres population in getPolda():**
```dart
if (isEditMode && selectedPoldaId != null) {
  final match = daftarPolda.where(
    (p) => int.tryParse(p["id"].toString()) == selectedPoldaId,
  ).toList();
  if (match.isNotEmpty) {
    daftarPolres = List<Map<String, dynamic>>.from(
      match.first["polres"] ?? [],
    );
  }
}
```

**Submit branching:**
```dart
if (isEditMode) {
  response = await http.put(
    Uri.parse("$apiBaseUrl/api/v1/sdm/personil/${widget.personilId}"),
    headers: {"Authorization": token.toString(), "Content-Type": "application/json"},
    body: jsonEncode(body),
  );
} else {
  response = await http.post(
    Uri.parse("$apiBaseUrl/api/v1/sdm/personil"),
    headers: {"Authorization": token.toString(), "Content-Type": "application/json"},
    body: jsonEncode(body),
  );
}
```

**422 branch:**
```dart
} else if (response.statusCode == 422) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(result["message"] ?? "Validasi data gagal"),
      backgroundColor: Colors.red,
    ),
  );
  // Stay on form — user can fix the field
}
```

---

## Task 2: Refactor Add Personel Page (`lib/pages/add_personel_page.dart`)

**Files:**
- Modify: `lib/pages/add_personel_page.dart`

**Interfaces:**
- Produces: `AddPersonelPage({String? personilId, Map<String, dynamic>? personilData})`
- Consumes: `FormTambahPersonel(personilId:, personilData:)` from Task 1

### Changes

1. **Constructor**: Add `String? personilId` and `Map<String, dynamic>? personilData` params
2. **Breadcrumb**: Dynamic based on `widget.personilId != null`
3. **Form**: Remove `const` from Padding, forward `personilId` and `personilData` to `FormTambahPersonel`

---

## Task 3: Refactor Personel List Page (`lib/pages/personel.dart`)

**Files:**
- Modify: `lib/pages/personel.dart` (complete replacement)

**Interfaces:**
- Consumes: `AddPersonelPage(personilId:, personilData:)` from Task 2
- Uses: `apiBaseUrl` from `config/api_config.dart`

### Changes

1. **GET endpoint**: Migrate to `$apiBaseUrl/api/v1/sdm/personil`
2. **State handling (polres pattern)**: Add full branching in `build()`:
   - `if (isLoading)` → amber `CircularProgressIndicator`
   - `else if (errorMessage.isNotEmpty)` → error icon + message + "Coba Lagi" retry button
   - `else if (datapersonel.isEmpty)` → table icon + "Tidak ada data" message
   - `else ...[...]` → title row, search, table, pagination, footer
3. **`deletePersonel`**: Complete rewrite:
   - Accept `String personilId` (UUID) instead of `int id`
   - `DELETE $apiBaseUrl/api/v1/sdm/personil/$personilId` (RESTful path param, no body)
   - Green SnackBar on 200 + `getPersonelApi()` refresh
   - Red SnackBar on failure
   - Network error catch with `mounted` guard
4. **Add button**: Add `.then((result) { if (result == true) getPersonelApi(); })`
5. **Edit button**: Wire `onEdit` to navigate to `AddPersonelPage` with `personilId` + `personilData` + `.then()` refresh
6. **Delete dialog**: Typed `showDialog<bool>`, interpolated name `"${e["nama_lengkap"]}"`, red styled Hapus button
7. **Delete call**: `deletePersonel(e["personil_id"].toString())` (string UUID)
8. **Columns**: Expand to 8 columns — NRP, NAMA LENGKAP, PANGKAT, JABATAN, POLDA, POLRES, STATUS AKTIF, AKSI — with defensive fallbacks to FK IDs

**Delete dialog pattern:**
```dart
onDelete: () async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Hapus Personel"),
      content: Text(
        "Apakah Anda yakin ingin menghapus Personel \"${e["nama_lengkap"]}\"?",
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
    deletePersonel(e["personil_id"].toString());
  }
},
```

**Edit navigation pattern:**
```dart
onEdit: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AddPersonelPage(
        personilId: e["personil_id"].toString(),
        personilData: {
          "nrp": "${e["nrp"]}",
          "nama_lengkap": "${e["nama_lengkap"]}",
          "polda_id": e["polda_id"],
          "polres_id": e["polres_id"],
          "pangkat_id": e["pangkat_id"],
          "jabatan_id": e["jabatan_id"],
        },
      ),
    ),
  ).then((result) {
    if (result == true) getPersonelApi();
  });
},
```

---

## Verification Checklist

1. `flutter analyze` — zero errors, info-level only
2. **Create** — all fields filled: green SnackBar, pops to list, list refreshes
3. **Create** — Polres = "Tidak Ada / Mako Polda": sends `"polres_id": null`, succeeds
4. **Create** — empty required field: red "Semua data wajib diisi", no request sent
5. **Create** — duplicate NRP: 422 red SnackBar with backend message, form stays open
6. **Edit** — all fields + dropdowns pre-filled correctly (including "Tidak Ada" for null polres)
7. **Edit** — save sends `PUT /api/v1/sdm/personil/<uuid>`, pops `true`, list refreshes
8. **Edit** — change Polda: polres resets to "Tidak Ada / Mako Polda", repopulates
9. **Delete** — dialog shows name, red Hapus button, green SnackBar + refresh on success
10. **Delete** — API failure shows red SnackBar
11. **List states** — loading spinner, error+retry, and empty state all render correctly
12. **Operator Polda (role 2)** — jurisdiction-scoped rows (backend filter, no frontend change)

## Open Questions for Backend Verification

- Confirm GET response key is `personil_id` (UUID) and joined names (`nama_pangkat`, `nama_jabatan`, `nama_polda`, `nama_polres`) are present
- Confirm create returns 201, update/delete return 200
