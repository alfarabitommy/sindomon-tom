# Master Kategori Senjata CRUD — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a full CRUD page for "Master Kategori Senjata & Amunisi" (list, add, edit, delete) wired to `POST/GET/PUT/DELETE /api/v1/master/kategori-senjata`, following the Polda/Polres pattern exactly.

**Architecture:** 5 files (4 new + 1 modified). A `KategoriSenjata` model with defensive `fromJson`, a dual-mode form widget (`FormTambahKategoriSenjata`) that does POST (create) or PUT (edit), a host page (`AddKategoriSenjataPage`) that wraps the form in the standard AppBackground/AppSidebar/AppHeader scaffold, a list page (`KategoriSenjataPage`) with DataTable, color-coded tipe-laras badges, delete-with-409-handling, and menu registration in `role1Menu` → "Master Data Sistem". No routing table exists — the `AppSidebar` navigates via `LeafMenuItem.pageBuilder`.

**Tech Stack:** Flutter, `http` package, `shared_preferences` (auth token), DataTable + DropdownButtonFormField from Material.

---

## UI & Form Audit (Current State Analysis)

### What exists

| File | Role |
|---|---|
| `lib/widget/form_input_senjata.dart:56` | **Only** file calling `/api/v1/kategori_senjata` — as a dropdown lookup inside the senjata inventory form |
| `lib/pages/senjata.dart` | Lists *senjata inventory* (tbl_senjata), NOT kategori master. Edit is a stub (`onEdit: () {}`). No tipe_laras column, no kaliber column. |
| `lib/pages/add_senjata.dart` | Create-only senjata page. No edit mode. |
| `lib/config/menu_config.dart` | "Master Logistik" menu item points to inventaris, not kategori. "Kategori Senjata" has no menu item. |

### What does NOT exist (gaps to fill)

1. **No dedicated Kategori Senjata CRUD page** — no list page, no add/edit form, no model
2. **No `form_input_kategori_senjata.dart`** — the old dropdown in `form_input_senjata.dart` calls `/api/v1/kategori_senjata` (the old read-only endpoint), NOT the new `/api/v1/master/kategori-senjata`
3. **No badge/chip UI pattern** anywhere in the codebase — status/tipe values are always plain `Text`
4. **No 409 conflict handling** exists in any delete method — only 200 success / generic else
5. **No strict enum dropdown** pattern exists — existing dropdowns fetch options from APIs

### Audit answers to the user's specific questions

1. **Is the DataTable fetching from the correct endpoint?** — There IS no Kategori Senjata DataTable. The existing `form_input_senjata.dart` dropdown fetches from the old `/api/v1/kategori_senjata` (no `master/` prefix). The new CRUD endpoint must be `/api/v1/master/kategori-senjata`.
2. **Does the Form have a strict Dropdown for `tipe_laras` and TextField for `kaliber`?** — No dedicated form exists. The old senjata form has a dropdown showing tipe_laras values fetched from the API (not static/hardcoded), and no kaliber field. The new form must use hardcoded "Panjang"/"Pendek" options and include a kaliber TextField.

### Canonical pattern to follow

The Polda CRUD implementation is the gold standard. All new files mirror this pattern:
- **Model:** `lib/models/polda_model.dart` → `lib/models/kategori_senjata_model.dart`
- **Form:** `lib/widget/form_input_polda.dart` → `lib/widget/form_input_kategori_senjata.dart`
- **Host:** `lib/pages/add_polda.dart` → `lib/pages/add_kategori_senjata.dart`
- **List:** `lib/pages/polda.dart` → `lib/pages/kategori_senjata.dart`
- **Menu:** `lib/config/menu_config.dart` (modify existing)

---

## Global Constraints

- API base: `apiBaseUrl` from `lib/config/api_config.dart` (= `"https://sindomon.cml-indonesia.com"`). Never hardcode a URL.
- **Endpoint for this feature:** `/api/v1/master/kategori-senjata` (with `master/` prefix, like polres — NOT the old read-only `/api/v1/kategori-senjata`).
- Auth header: exactly `"Authorization"` (capital A), value `token.toString()` from `SharedPreferences` key `"token"`.
- User labels: `prefs.getString("username_login")` and `AppSidebar.roleLabelFromId(prefs.getString("roleid_login"))`.
- Success snackbars: green. Error snackbars: red. POST success = 200 or 201; PUT/DELETE success = 200. Form success → `Navigator.pop(context, true)`.
- DELETE 409 (FK conflict) → red SnackBar: `"Data kategori ini sedang digunakan oleh data Logistik dan tidak dapat dihapus"`.
- Tipe Laras dropdown: STRICT — exactly two hardcoded items `"Panjang"` and `"Pendek"` (values equal labels). No API call for options.
- Badge colors: PANJANG → bg `#DCEAF6` + text `#1E40AF`; PENDEK → bg `#E7D8EE` + text `#6B21A8`. Text: uppercase, bold, 12px.
- Form submit button: amber `Color(0xffF6B300)` bg, `Color(0xFF23251D)` fg, `StadiumBorder`.
- No new pubspec dependencies. No changes to `lib/main.dart`.
- Commit trailer: `Co-Authored-By: Claude <noreply@anthropic.com>`.

---

## Delete Implementation Plan

### DELETE endpoint and flow

The delete operation follows the Polda pattern (`polda.dart:86-126`) with one critical addition: **HTTP 409 Conflict handling**.

**Endpoint:** `DELETE /api/v1/master/kategori-senjata/{id}`
**Headers:** `{"Authorization": token.toString()}`
**No request body** (RESTful path-param delete)

### Confirmation dialog

```dart
final result = await showDialog<bool>(
  context: context,
  builder: (_) => AlertDialog(
    title: const Text("Hapus Kategori"),
    content: Text(
      'Apakah Anda yakin ingin menghapus kategori "${k.tipeLaras} ${k.kaliber}"?',
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
if (result == true) deleteKategori(k.id);
```

### Delete method with 409 handling

```dart
Future<void> deleteKategori(int id) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.delete(
      Uri.parse("$apiBaseUrl/api/v1/master/kategori-senjata/$id"),
      headers: {"Authorization": token.toString()},
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      // SUCCESS
      final result = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"] ?? "Kategori berhasil dihapus"),
          backgroundColor: Colors.green,
        ),
      );
      getKategoriApi(); // refresh list
    } else if (response.statusCode == 409) {
      // FK CONFLICT — kategori is referenced by Logistik data
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Data kategori ini sedang digunakan oleh data Logistik dan tidak dapat dihapus",
          ),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      // OTHER ERRORS
      final result = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"] ?? "Gagal menghapus kategori"),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    debugPrint("Error delete kategori: $e");
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

**Key difference from existing Polda pattern:** The `else if (response.statusCode == 409)` branch explicitly handles the soft-delete restriction. On 409, the list is NOT refreshed (the data wasn't deleted), and a red SnackBar warns the user. This is the only delete method in the app that handles 409.

---

## Edit & Create Implementation Plan

### Form widget: `lib/widget/form_input_kategori_senjata.dart`

**Mode detection (mirrors `form_input_polda.dart:24-35`):**
```dart
isEditMode = widget.kategoriId != null && widget.kategoriData != null;
```

**Pre-fill on edit (initState):**
```dart
if (isEditMode && widget.kategoriData != null) {
  final data = widget.kategoriData!;
  final tipe = data["tipe_laras"]?.toString();
  // Guard: only accept values that exist in the dropdown
  if (_tipeLarasOptions.contains(tipe)) {
    selectedTipeLaras = tipe;
  }
  kaliber.text = data["kaliber"]?.toString() ?? "";
}
```

### Strict Enum Dropdown (hardcoded, no API call)

```dart
static const List<String> _tipeLarasOptions = ["Panjang", "Pendek"];

DropdownButtonFormField<String>(
  value: selectedTipeLaras,
  decoration: _inputDecoration,
  hint: const Text("Pilih Tipe Laras"),
  items: const [
    DropdownMenuItem(value: "Panjang", child: Text("Panjang")),
    DropdownMenuItem(value: "Pendek", child: Text("Pendek")),
  ],
  onChanged: (value) {
    setState(() { selectedTipeLaras = value; });
  },
);
```

### POST vs PUT routing

```dart
if (isEditMode) {
  response = await http.put(
    Uri.parse("$apiBaseUrl/api/v1/master/kategori-senjata/${widget.kategoriId}"),
    headers: {"Authorization": token, "Content-Type": "application/json"},
    body: jsonEncode({"tipe_laras": selectedTipeLaras, "kaliber": kaliber.text}),
  );
} else {
  response = await http.post(
    Uri.parse("$apiBaseUrl/api/v1/master/kategori-senjata"),
    headers: {"Authorization": token, "Content-Type": "application/json"},
    body: jsonEncode({"tipe_laras": selectedTipeLaras, "kaliber": kaliber.text}),
  );
}
```

### Visual Badges rendering (in list page DataTable)

```dart
Widget _tipeLarasBadge(String tipeLaras) {
  final isPanjang = tipeLaras.toUpperCase() == "PANJANG";
  final bg = isPanjang ? const Color(0xFFDCEAF6) : const Color(0xFFE7D8EE);
  final fg = isPanjang ? const Color(0xFF1E40AF) : const Color(0xFF6B21A8);

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      tipeLaras.toUpperCase(),
      style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
    ),
  );
}
```

Used in the DataTable column:
```dart
DataCell(_tipeLarasBadge(k.tipeLaras)),
```

### Host page navigation (add vs edit)

**Add:** `Navigator.push(context, MaterialPageRoute(builder: (_) => const AddKategoriSenjataPage()))`
**Edit:** `Navigator.push(context, MaterialPageRoute(builder: (_) => AddKategoriSenjataPage(kategoriId: k.id, kategoriData: {"tipe_laras": k.tipeLaras, "kaliber": k.kaliber})))`
**Refresh:** `.then((result) { if (result == true) getKategoriApi(); })`

---

## File Structure

| File | Action | Responsibility |
|---|---|---|
| `lib/models/kategori_senjata_model.dart` | Create | `KategoriSenjata` model + `fromJson` |
| `lib/widget/form_input_kategori_senjata.dart` | Create | Dual-mode POST/PUT form with strict dropdown |
| `lib/pages/add_kategori_senjata.dart` | Create | Scaffold host for the form (add/edit) |
| `lib/pages/kategori_senjata.dart` | Create | List page: GET, DataTable + badge, delete w/ 409, add/edit nav |
| `lib/config/menu_config.dart` | Modify | Import + `_ks()` builder + LeafMenuItem in role1Menu |

---

## Task Breakdown

### Task 1: Create the KategoriSenjata Model

**Files:** Create `lib/models/kategori_senjata_model.dart`

- [ ] **Step 1: Create feature branch**
```bash
git checkout -b feat/master-kategori-senjata
```

- [ ] **Step 2: Write the model** (mirrors `polda_model.dart`)
```dart
class KategoriSenjata {
  final int id;
  final String tipeLaras;
  final String kaliber;
  final String? createdAt;

  const KategoriSenjata({
    required this.id,
    required this.tipeLaras,
    required this.kaliber,
    this.createdAt,
  });

  factory KategoriSenjata.fromJson(Map<String, dynamic> json) {
    return KategoriSenjata(
      id: json["id"] is int
          ? json["id"]
          : int.tryParse(json["id"].toString()) ?? 0,
      tipeLaras: json["tipe_laras"]?.toString() ?? "Unknown",
      kaliber: json["kaliber"]?.toString() ?? "",
      createdAt: json["created_at"]?.toString(),
    );
  }
}
```

- [ ] **Step 3: Verify**
```bash
flutter analyze
```

- [ ] **Step 4: Commit**
```bash
git add lib/models/kategori_senjata_model.dart
git commit -m "feat: add KategoriSenjata model with fromJson

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 2: Create the Dual-Mode Form Widget

**Files:** Create `lib/widget/form_input_kategori_senjata.dart`

- [ ] **Step 1: Write the form widget** (full implementation as designed in "Edit & Create Implementation Plan" section above — includes: `isEditMode` detection, strict `_tipeLarasOptions` dropdown, `kaliber` TextEditingController, `simpanKategori()` with POST/PUT routing, `_inputDecoration` copied from `form_input_polda.dart`, amber submit button with loading spinner, form titles "TAMBAH KATEGORI BARU" / "EDIT KATEGORI")

- [ ] **Step 2: Verify compiles**
```bash
flutter analyze
```

- [ ] **Step 3: Commit**
```bash
git add lib/widget/form_input_kategori_senjata.dart
git commit -m "feat: add dual-mode Kategori Senjata form widget with strict dropdown

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 3: Create the Add/Edit Host Page

**Files:** Create `lib/pages/add_kategori_senjata.dart`

- [ ] **Step 1: Write the host page** (mirrors `add_polda.dart` exactly — `AddKategoriSenjataPage` accepting `kategoriId`/`kategoriData`, Scaffold with AppBackground/AppSidebar(currentRoute: "kategori_senjata")/AppHeader with dynamic breadcrumb/title Row with "Kembali" black pill button/Expanded form inside centered Card)

- [ ] **Step 2: Verify compiles**
```bash
flutter analyze
```

- [ ] **Step 3: Commit**
```bash
git add lib/pages/add_kategori_senjata.dart
git commit -m "feat: add Kategori Senjata add/edit host page

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 4: Create the List Page

**Files:** Create `lib/pages/kategori_senjata.dart`

- [ ] **Step 1: Write the list page** (full implementation as designed in "Delete Implementation Plan" and "Visual Badges" sections above — includes: `getKategoriApi()` → GET `/api/v1/master/kategori-senjata`, `deleteKategori()` with 200/409/else handling, `_tipeLarasBadge()` with spec colors, DataTable columns ID/TIPE LARAS/KALIBER/CREATED AT/AKSI, add/edit navigation with `.then()` refresh, loading/error/empty states, "Master Kategori Senjata & Amunisi" title, amber "Tambah Kategori" button, empty state: `Icons.category_outlined` + "Belum ada kategori senjata terdaftar")

- [ ] **Step 2: Verify compiles**
```bash
flutter analyze
```

- [ ] **Step 3: Commit**
```bash
git add lib/pages/kategori_senjata.dart
git commit -m "feat: add Master Kategori Senjata list page with badge rendering and 409 delete handling

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 5: Register the Menu Item

**Files:** Modify `lib/config/menu_config.dart`

- [ ] **Step 1: Add import** (after line 11, `import '../pages/polres.dart';`)
```dart
import '../pages/kategori_senjata.dart';
```

- [ ] **Step 2: Add page builder** (after `Widget _pr() => const PolresPage();`)
```dart
Widget _ks() => const KategoriSenjataPage();
```

- [ ] **Step 3: Add LeafMenuItem** — inside `role1Menu` → `MenuGroup(label: "Master Data Sistem", ...)`, as the last child after "Master Logistik":
```dart
        LeafMenuItem(
          label: "Master Kategori Senjata",
          icon: Icons.category_rounded,
          routeName: "kategori_senjata",
          pageBuilder: _ks,
        ),
```

- [ ] **Step 4: Verify**
```bash
flutter analyze
```

- [ ] **Step 5: Commit**
```bash
git add lib/config/menu_config.dart
git commit -m "feat: register Master Kategori Senjata in role 1 menu

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Verification Plan

### Automated checks
```bash
flutter analyze        # Must show "No issues found"
flutter test           # Existing tests must still pass
```

### Manual QA checklist (run `flutter run`)

1. **Login as Super Admin (role 1)** → sidebar "Master Data Sistem" → "Master Kategori Senjata" appears
2. **List loads** with columns: ID, TIPE LARAS (badge), KALIBER, CREATED AT, AKSI
3. **Badges render correctly** — PANJANG on blue (#DCEAF6 bg, dark blue text), PENDEK on purple (#E7D8EE bg, purple text), uppercase, bold, 12px
4. **Add flow** — "Tambah Kategori" (amber) → form "TAMBAH KATEGORI BARU" → dropdown shows only "Panjang"/"Pendek" (no free typing, no network call for options) → empty submit shows red "Semua data wajib diisi" → valid save → green SnackBar, pop, list refreshed
5. **Edit flow** — pencil icon → form "EDIT KATEGORI" → dropdown and kaliber prefilled → modify and save → green SnackBar, list refreshed
6. **Delete unused category** — trash icon → confirm dialog → green SnackBar → list refreshed (row gone)
7. **Delete referenced category** (FK constraint) — trash icon → confirm dialog → **red SnackBar** "Data kategori ini sedang digunakan oleh data Logistik dan tidak dapat dihapus" → list NOT modified
8. **Empty state** — when no data: `Icons.category_outlined` icon + "Belum ada kategori senjata terdaftar"
9. **Error state** — when backend offline: red error icon + "Coba Lagi" button

---

## Design Decisions & Rationale

1. **Full-page form, not modal** — The UI/UX spec mentions a "modal_form_kategori" but the existing Polda/Polres patterns use full-page forms. Consistency with the rest of the desktop app takes precedence over the spec's mobile-oriented modal design. If a modal is later desired, the form widget is self-contained and can be dropped into a dialog.

2. **Static dropdown, no API call** — The spec explicitly states `dropdown_tipe_laras` must NOT allow free typing and the ERD defines it as `ENUM('Panjang','Pendek')`. Hardcoding the two values is simpler and faster than an API call. The old `/api/v1/kategori_senjata` endpoint is never called from the new form.

3. **No lock icon on delete** — The spec mentions a disabled delete button with lock icon for FK-referenced rows, but the GET list response doesn't include FK reference status. The 409 conflict SnackBar provides equivalent UX: user tries to delete, gets a clear red warning that it's restricted. A future enhancement could add a `has_relations` flag to the API response to enable the lock icon.

4. **`master/` prefix on all endpoints** — The new RESTful endpoint follows the Polda/Polres pattern (`/api/v1/master/polda`, `/api/v1/master/polres`). The old `/api/v1/kategori_senjata` (used by `form_input_senjata.dart`) is a read-only dropdown endpoint and is left untouched to avoid breaking the senjata form.
