# Settings Page Layout & Data Audit

**File:** `lib/pages/pangaturan.dart`  
**Audit date:** 2025-01-XX  
**Status:** TWO ISSUES IDENTIFIED — READY FOR SURGERY

---

## ISSUE 1: Layout — AppHeader & AppFooter Floating in Mid-Screen

### Root Cause

The entire page content (header, cards, footer) is wrapped inside a **single `SingleChildScrollView`** that is the **direct child of `Expanded`**.

**Current (broken) widget tree:**
```
Expanded
  └─ SingleChildScrollView(padding: 30)        ← gives child Column UNBOUNDED height
       └─ Column(crossAxisAlignment: start)    ← compact height (wraps children only)
            ├─ AppHeader                       ← top of Column ✓
            ├─ SizedBox + Title Row
            ├─ Wrap(info cards)
            ├─ _bindingCard()
            └─ AppFooter                       ← sits right after last card, NOT at screen bottom ✗
```

**Why it breaks:** `SingleChildScrollView` tells its child `Column` it has infinite vertical space. The `Column` with `mainAxisSize: max` (default) in unbounded space behaves as `mainAxisSize: min` — it sizes to its children's intrinsic height. Result: the entire block is compact, and `AppFooter` appears right below `_bindingCard()` instead of at the bottom of the viewport. On a tall screen, the whole block centers/gravitates upward.

### Reference Pattern (from `polda.dart`, `personel.dart`, etc.)

The standard layout used by **every other data page**:

```
Expanded
  └─ Padding(padding: 30)
       └─ Column(crossAxisAlignment: start)    ← Column fills Expanded height
            ├─ AppHeader                       ← top anchor
            ├─ SizedBox(h: 25)
            ├─ Title Row                       ← page title + action button
            ├─ SizedBox(h: 25)
            ├─ Expanded(                       ← flex:1, fills REMAINING space
            │    └─ SingleChildScrollView      ← scrolls ONLY the content area
            │         └─ <content widgets>     ← cards, tables, etc.
            │   )
            ├─ SizedBox(h: 20)
            └─ AppFooter                       ← bottom anchor (SIBLING of Expanded, NOT inside it!)
```

**Key insight:** `AppFooter` is a **sibling** of `Expanded(SingleChildScrollView(...))`, not a child of it. The `Expanded` with `flex: 1` pushes the footer to the bottom of the column.

### Required Refactor

Replace lines 159–250 (the `Expanded → SingleChildScrollView → Column` chain) with the standard three-zone pattern:

| Zone | Widget | Position |
|-------|--------|----------|
| Top | `AppHeader` | Direct child of outer `Column` |
| Middle (scrollable) | `Expanded → SingleChildScrollView` containing cards | Between header and footer |
| Bottom | `AppFooter` | Direct child of outer `Column`, after `Expanded` |

---

## ISSUE 2: Data — Polda Card Shows Raw ID Instead of Name

### Root Cause

`loadUser()` (lines 20–28) reads `polda_login` from `SharedPreferences`:

```dart
polda = prefs.getString("polda_login") ?? "";  // → "13"
```

The `polda_login` key is populated during login (`login_card.dart:146, 153`) from `userData["polda_id"]` — an integer ID, **not** a human-readable name string. The login endpoint's `user` object only stores `polda_id`; there is no `nama_polda` persisted to `SharedPreferences`.

At display time (line 231):
```dart
value: polda.isEmpty ? "-" : polda,  // → "13" shown instead of "Polda Jawa Barat"
```

### Data Flow (current vs. needed)

```
Current:  Login API → SharedPreferences["polda_login"] = polda_id (integer string)
          pangaturan.dart → loadUser() → polda = "13"
          UI → displays "13" ✗

Needed:   Login API → SharedPreferences["polda_login"] = polda_id
    AND   Profile API → returns { nama_polda: "Polda Jawa Barat", ... }
          pangaturan.dart → fetchProfile() → polda = "Polda Jawa Barat"
          UI → displays "Polda Jawa Barat" ✓
```

### Proposed API Integration

Add a `fetchProfile()` method to `_AccountSettingPageState`:

**Endpoint:** `GET $apiBaseUrl/api/v1/profile`  
**Headers:** `{"Authorization": "<jwt_token>"}`  
**Expected response shape:**
```json
{
  "data": {
    "username": "...",
    "roles_id": "...",
    "polda_id": 13,
    "nama_polda": "Polda Jawa Barat"
  }
}
```

**Implementation outline:**
```dart
Future<void> fetchProfile() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.get(
      Uri.parse("$apiBaseUrl/api/v1/profile"),
      headers: {"Authorization": token.toString()},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = json["data"] as Map<String, dynamic>? ?? {};
      final namaPolda = data["nama_polda"]?.toString() ?? "";

      if (!mounted) return;
      setState(() {
        polda = namaPolda.isNotEmpty ? namaPolda : polda;
      });
    }
  } catch (e) {
    debugPrint("Error fetching profile: $e");
  }
}
```

**Init call:**
```dart
@override
void initState() {
  super.initState();
  loadUser();
  fetchProfile();   // ← ADD — fire-and-forget, non-blocking
}
```

### New Imports Required

| Import | Reason |
|--------|--------|
| `import 'package:http/http.dart' as http;` | `http.get()` for API call |
| `import 'dart:convert';` | `jsonDecode()` for response parsing |
| `import '../config/api_config.dart';` | `apiBaseUrl` constant |

### Fallback Strategy

If the profile API returns no `nama_polda` (or the call fails), `polda` retains its SharedPreferences value (the raw ID). The UI already has the `polda.isEmpty ? "-" : polda` guard, so it degrades gracefully — just showing the ID instead of the name.

### Alternative: Capture `nama_polda` During Login

A simpler approach (if the login response already includes `nama_polda` in the `user` object) would be to also store it in `SharedPreferences` during login (`login_card.dart`). However, this would require modifying the login flow and a re-login — the profile API approach is self-contained and doesn't depend on changes to the login page.

---

## Combined Fix Plan Summary

| Step | Action | Lines Affected |
|------|--------|---------------|
| 1 | Add 3 new imports (`http`, `dart:convert`, `api_config`) | After line 6 |
| 2 | Refactor `build()` layout to three-zone pattern | Lines 159–250 |
| 3 | Add `fetchProfile()` method | After `loadUser()` |
| 4 | Call `fetchProfile()` in `initState()` | Line 33 |
