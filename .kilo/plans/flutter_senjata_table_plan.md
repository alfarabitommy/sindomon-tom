# Flutter Senjata DataTable — Ghost Data Fix Plan

## 1. Audit Findings

### Root Cause: JSON key + structure mismatch between API response and Dart mapping

**File**: `lib/pages/senjata.dart`

API returns:
```json
[
  {
    "senjata_id": "...",
    "nomor_seri": "...",
    "foto_url": "...",
    "tahun_pengadaan": "2024",
    "kategori": { "tipe_laras": "Panjang", "kaliber": "5.56mm" },
    "status_kelayakan": "Baik",
    ...
  }
]
```

Code at `senjata.dart:49-52` maps **every key wrong**:

| Code key (`e["..."]`) | API key              | Line |
|-------------------------|----------------------|------|
| `e["foto"]`            | `e["foto_url"]`      |  256 |
| `e["no_seri"]`         | `e["nomor_seri"]`    |  267 |
| `e["kategori"]`        | nested `Map` object  |  272 |
| `e["tahun"]`           | `e["tahun_pengadaan"]` | 277 |
| `e["id"]` (delete)     | `e["senjata_id"]`    |  325 |

Null access to nonexistent map keys in Dart returns `null` (no crash), so DataRows render empty `Text(null?)` cells — `Text` widget renders empty string for null, giving the illusion of zero rows returning data.

Additionally, `senjata.dart:44` uses wrong URL path `/api/v1/senjata` — must be `/api/v1/logistik/senjata`.

`senjata.dart:52` wraps with `json["data"]`. If API returns flat array (not `{ data: [...] }`), `json["data"]` is `null` → `List.from(null)` throws → caught silently in catch block → `senjataapi` stays `[]` → DataTable has zero rows.

### Pagination: hardcoded static text

`lib/widget/app_pagination.dart:19` — text `"Menampilkan 1 hingga 10 dari 50 data"` is not bound to any state. This explains the misleading "1 to 10 of 50" while zero rows render.

### Search: not wired

`senjata.dart:173` — `AppSearchField` has `onChanged` and `controller` params but **neither is passed**. The TextField changes fire nowhere.

### Monospace: missing

`senjata.dart:266-269` — `nomor_seri` DataCell uses default `Text` widget. No `fontFamily: 'monospace'` or equivalent.

---

## 2. Fix Plan

### 2.1 Fix API URL + JSON parsing

**File**: `lib/pages/senjata.dart`

Replace `getSenjataApi()` (lines 37–67):

```dart
static const _basePath = "$apiBaseUrl/api/v1/logistik/senjata";

Future<void> getSenjataApi() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";

    final uri = Uri.parse(_basePath).replace(queryParameters: {
      if (_searchQuery.isNotEmpty) "search": _searchQuery,
    });

    final response = await http.get(
      uri,
      headers: {"Authorization": token},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        senjataapi = data.cast<Map<String, dynamic>>();
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  } catch (e) {
    setState(() => isLoading = false);
    debugPrint(e.toString());
  }
}
```

Key changes:
- URL → `/api/v1/logistik/senjata`
- `json["data"]` removed — parses top-level array directly (`List<dynamic>` then `.cast<>()`)
- Authorization header capitalized consistently
- Search query param support (see 2.5)

### 2.2 Fix column key mappings in DataRow

**File**: `lib/pages/senjata.dart`, lines 248–331

Replace the entire `rows:` block:

```dart
rows: senjataapi.map((e) => DataRow(cells: [
  DataCell(
    ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        e["foto_url"] ?? "",
        width: 80,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 40),
      ),
    ),
  ),
  DataCell(
    Text(
      e["nomor_seri"] ?? "",
      style: const TextStyle(fontFamily: "monospace"),
    ),
  ),
  DataCell(
    Text(
      _formatKategori(e["kategori"]),
    ),
  ),
  DataCell(
    Text("${e["tahun_pengadaan"] ?? "-"}"),
  ),
  DataCell(
    ActionButtons(
      onEdit: () {},
      onDelete: () async {
        final result = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Hapus Senjata"),
            content: const Text("Apakah Anda yakin ingin menghapus data ini?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Hapus"),
              ),
            ],
          ),
        );
        if (result == true) {
          deleteSenjata(int.parse(e["senjata_id"].toString()));
        }
      },
    ),
  ),
])).toList(),
```

### 2.3 Add `_formatKategori` helper

**File**: `lib/pages/senjata.dart` — add to `_SenjataPageState`:

```dart
String _formatKategori(dynamic kategori) {
  if (kategori is Map<String, dynamic>) {
    final laras = kategori["tipe_laras"] ?? "";
    final kaliber = kategori["kaliber"] ?? "";
    if (laras.isNotEmpty && kaliber.isNotEmpty) return "$laras - $kaliber";
    if (laras.isNotEmpty) return laras;
    if (kaliber.isNotEmpty) return kaliber;
  }
  return "-";
}
```

### 2.4 Monospace font registration

`fontFamily: "monospace"` uses Flutter's built-in monospace fallback. Works on all platforms.

**Optional enhancement**: add a custom font (e.g., "Source Code Pro") in `pubspec.yaml` and reference it. Recommended only if monospace fallback appears inconsistent on target devices.

### 2.5 Wire up search with debounce

**File**: `lib/pages/senjata.dart`

Add to `_SenjataPageState`:

```dart
String _searchQuery = "";
Timer? _debounce;
final TextEditingController _searchController = TextEditingController();

void _onSearchChanged(String value) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 400), () {
    _searchQuery = value;
    getSenjataApi();
  });
}
```

Update `initState`/`dispose`:

```dart
@override
void dispose() {
  _debounce?.cancel();
  _searchController.dispose();
  super.dispose();
}
```

Update `AppSearchField` invocation (line 173):

```dart
AppSearchField(
  hintText: "Cari Senjata...",
  controller: _searchController,
  onChanged: _onSearchChanged,
),
```

### 2.6 Add missing import

Add to imports (line 2 area):

```dart
import 'dart:async';
```

---

## 3. Files Changed

| File | Change |
|-------|--------|
| `lib/pages/senjata.dart` | API URL, JSON parse, key mappings, monospace, search wiring, debounce, `dispose` |
| `lib/widget/app_pagination.dart` | Out of scope for this fix — static text remains but noted as future work |

---

## 4. Validation Steps

1. Run the app, navigate to Senjata page
2. Verify rows render with correct data:
   - Foto column shows image from `foto_url`
   - No Seri column uses monospace font
   - Kategori column shows "Panjang - 5.56mm"
   - Tahun column shows e.g. "2024"
3. Type in search box — verify API is called after 400ms debounce with `?search=` param
4. Delete a row — verify correct `senjata_id` sent in body
5. Verify no unhandled exceptions in debug console

---

## 5. Skipped / Future

- **Pagination**: `AppPagination` widget is purely cosmetic. Real pagination needs API metadata (`page`, `per_page`, `total`) and a refactor of the pagination widget. Out of scope.
- **Error states**: No loading shimmer, no empty-state illustration, no retry button. Add when UX polish is requested.
- **Pull-to-refresh**: Not requested.
- **Custom monospace font**: Not requested; built-in fallback used.
