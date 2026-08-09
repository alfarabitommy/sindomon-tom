# Settings Page Final Polish

**File:** `lib/pages/pangaturan.dart`  
**Status:** ✅ LAYOUT + DATA SURGERY COMPLETE  
**Lines:** 299 (was 256)

---

## What Changed

### 1. Imports (3 added)
```dart
import 'package:http/http.dart' as http;      // HTTP client for fetchProfile()
import 'dart:convert';                        // jsonDecode() for response parsing
import '../config/api_config.dart';            // apiBaseUrl constant
```

### 2. Data Fetching (`fetchProfile()`)
- New method `Future<void> fetchProfile()` → `GET $apiBaseUrl/api/v1/profile` with `Authorization: <jwt_token>` header
- Parses `data.nama_polda` and updates the `polda` state variable via `setState()`
- Graceful fallback: keeps the SharedPreferences raw-ID value if the API fails
- Called in `initState()` right after `loadUser()`

### 3. Layout Refactor (Three-Zone Pattern)
Replaced the single `Expanded → SingleChildScrollView → Column` chain with:

```
Expanded
  └─ Padding(30.0)
       └─ Column
            ├─ AppHeader                          ← TOP ZONE (fixed)
            ├─ Title Row ("Profil & Pengaturan" + "Kembali")
            ├─ Expanded                           ← MIDDLE ZONE (fills remaining space)
            │    └─ SingleChildScrollView
            │         └─ Wrap(info cards) + _bindingCard()
            ├─ SizedBox(20)
            └─ AppFooter                          ← BOTTOM ZONE (fixed, sibling of Expanded)
```

- `AppFooter` is now pinned to the bottom of the viewport
- Only the middle content scrolls
- Title restyled per spec: `fontSize: 22`, `color: Color(0xFF23251D)`, button `Color(0xFF23251D)` bg, `borderRadius: 20`, `icon size: 16`

---

## Verification

| Check | Result |
|-------|--------|
| Bracket balance (strings/comments stripped) | ✅ BALANCED |
| `fetchProfile` present | ✅ |
| `http.get` / `jsonDecode` / `apiBaseUrl` / `nama_polda` present | ✅ |
| `AppHeader` / `AppFooter` / `SingleChildScrollView` / `Expanded` present | ✅ |
| `flutter analyze` | ⚠️ Not runnable (no Flutter SDK in this environment) |

---

## Final Code — `lib/pages/pangaturan.dart` (complete)

```dart
import 'package:flutter/material.dart';
import '../widget/background.dart';
import '../widget/app_sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widget/app_footer.dart';
import '../widget/app_header.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class AccountSettingPage extends StatefulWidget {
  const AccountSettingPage({super.key});

  @override
  State<AccountSettingPage> createState() => _AccountSettingPageState();
}

class _AccountSettingPageState extends State<AccountSettingPage> {
  String unLogin = "";
  String roleLabel = "Operator";
  String polda = "";

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      unLogin = prefs.getString("username_login") ?? "";
      roleLabel = AppSidebar.roleLabelFromId(prefs.getString("roleid_login"));
      polda = prefs.getString("polda_login") ?? "";
    });
  }

  /// Fetch real profile data (e.g. `nama_polda`) from the backend and
  /// refresh the UI. Falls back to the SharedPreferences value on failure.
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
          if (namaPolda.isNotEmpty) polda = namaPolda;
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    loadUser();
    fetchProfile();
  }

  /// Read-only info card: icon + label + value.
  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.amber, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// Full-width device binding status card (placeholder state).
  Widget _bindingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Colors.green,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Status Binding Perangkat",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Perangkat Terverifikasi",
                style: TextStyle(fontSize: 13, color: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        imagePath: 'assets/images/wp-putih-mabes.png',
        child: SafeArea(
          child: Row(
            children: [
              const AppSidebar(currentRoute: "pengaturan"),

              /// ========================
              /// CONTENT
              /// ========================
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// ============================
                      /// TOP ZONE: HEADER
                      /// ============================
                      AppHeader(
                        breadcrumb: "Dashboard / Profil Saya",
                        username: unLogin,
                        role: roleLabel,
                      ),

                      const SizedBox(height: 25),

                      /// ============================
                      /// TITLE
                      /// ============================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Profil & Pengaturan",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF23251D),
                            ),
                          ),

                          ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back, size: 16),
                            label: const Text("Kembali"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF23251D),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      /// ============================
                      /// MIDDLE ZONE: SCROLLABLE CONTENT
                      /// ============================
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// ============================
                              /// PROFIL (READ-ONLY)
                              /// ============================
                              Wrap(
                                spacing: 20,
                                runSpacing: 20,
                                children: [
                                  _infoCard(
                                    icon: Icons.person_rounded,
                                    label: "Nama Pengguna",
                                    value: unLogin,
                                  ),
                                  _infoCard(
                                    icon: Icons.admin_panel_settings_rounded,
                                    label: "Level Akses",
                                    value: roleLabel,
                                  ),
                                  _infoCard(
                                    icon: Icons.map_rounded,
                                    label: "Polda",
                                    value: polda.isEmpty ? "-" : polda,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              /// ============================
                              /// KEAMANAN PERANGKAT
                              /// ============================
                              _bindingCard(),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// ============================
                      /// BOTTOM ZONE: FOOTER
                      /// ============================
                      const AppFooter(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Post-Surgery Notes

1. **`fetchProfile()` is non-blocking** — the page renders instantly from SharedPreferences, then updates the Polda card when the API responds.
2. **Graceful degradation** — if `/api/v1/profile` doesn't exist yet on the backend (404) or fails, `polda` keeps the raw ID from `polda_login`; the UI already guards with `polda.isEmpty ? "-" : polda`.
3. **Recommended verification** on a Flutter-capable machine: `flutter analyze` then run the app, log in, open **Pengaturan** from the profile dropdown, and confirm: (a) header at top / footer at bottom, (b) Polda card shows the full name (e.g. "Polda Jawa Barat").
