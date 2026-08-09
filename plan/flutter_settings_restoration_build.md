# Flutter Settings Restoration — Build Report

**Date:** 2025-07-16  
**Scope:** Amputated the rogue "Tambah Akun" form from the Settings page (`lib/pages/pangaturan.dart`) and restored it as a clean, read-only profile page. Based on the audit in `plan/flutter_settings_cleanup_audit.md`.

---

## 1. Changes applied to `lib/pages/pangaturan.dart`

| # | Change | Detail |
|---|--------|--------|
| 1 | **REMOVED import** | `import '../widget/form_input_user.dart';` — the rogue `FormTambahUser` widget is no longer referenced |
| 2 | **REMOVED form block** | The entire `Center → SizedBox(w:470) → Card → Padding → FormTambahUser()` block (was lines 253–270) |
| 3 | **CHANGED breadcrumb** | `"Dashboard / Tambah Pengguna"` → `"Dashboard / Profil Saya"` |
| 4 | **CHANGED title** | `"Pengaturan Pengguna"` → `"Profil & Pengaturan"` |
| 5 | **INJECTED read-only UI** | Three `_infoCard` widgets (Nama Pengguna, Level Akses, Polda) + full-width `_bindingCard` (Status Binding Perangkat) |

**Kept:** `import 'dart:ui';` (still required by the header's `BackdropFilter`), the glassmorphism header bar, the "Kembali" button, `AppFooter`, and the `AppSidebar`.

**Unaffected:** `FormTambahUser` still exists in `lib/widget/form_input_user.dart` and is still used by `lib/pages/add_user.dart` (the legitimate Super Admin "Daftar Pengguna" add/edit flow). The `AccountSettingPage` class name and `const` constructor are unchanged, so both callers (`lib/pages/dashboard.dart:299`, `lib/widget/app_header.dart:33`) compile without modification.

---

## 2. Data sources

| Card | Source | State field |
|------|--------|-------------|
| Nama Pengguna | `SharedPreferences["username_login"]` | `unLogin` (pre-existing) |
| Level Akses | `SharedPreferences["roleid_login"]` → `AppSidebar.roleLabelFromId()` | `roleLabel` (pre-existing) |
| Polda | `SharedPreferences["polda_login"]` (**newly read** — was previously written but never read per project docs) | `polda` (new) |
| Status Binding Perangkat | Placeholder UI (no API yet) | — |

---

## 3. Completely refactored code — `lib/pages/pangaturan.dart`

```dart
import 'package:flutter/material.dart';
import '../widget/background.dart';
import '../widget/app_sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widget/app_footer.dart';
import 'dart:ui';

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

  @override
  void initState() {
    super.initState();
    loadUser();
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// ============================
                      /// HEADER
                      /// ============================
                      Container(
                        height: 75,
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.black26),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                color: Colors.white.withValues(alpha: 0.18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: const Icon(
                                      Icons.home_rounded,
                                      color: Colors.amber,
                                      size: 28,
                                    ),
                                  ),

                                  const SizedBox(width: 15),

                                  const Expanded(
                                    child: Text(
                                      "Dashboard / Profil Saya",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 20),

                                  SizedBox(
                                    width: 250,
                                    height: 45,
                                    child: TextField(
                                      decoration: InputDecoration(
                                        hintText: "Cari Menu...",
                                        prefixIcon: const Icon(Icons.search),
                                        filled: true,
                                        fillColor: Colors.white.withValues(
                                          alpha: 0.15,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 20),

                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.15,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      onPressed: () {},
                                      icon: const Icon(
                                        Icons.notifications_none,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 15),

                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                        width: 2,
                                      ),
                                    ),
                                    child: const CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.amber,
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        unLogin,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        roleLabel,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text("Kembali"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

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

                      const SizedBox(height: 20),

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

## 4. Verification

| Check | Result |
|-------|--------|
| `FormTambahUser` references in `pangaturan.dart` | ✅ zero (grep: `FormTambahUser|form_input_user|Tambah Pengguna|Pengaturan Pengguna` → no matches) |
| `AccountSettingPage` constructor unchanged | ✅ `const AccountSettingPage({super.key})` — callers in `dashboard.dart:299` and `app_header.dart:33` unaffected |
| `FormTambahUser` still available for `add_user.dart` | ✅ widget file untouched |
| `dart:ui` import kept | ✅ still used by header `BackdropFilter` |
| `flutter analyze` | Not runnable — no Flutter SDK on this machine (run in Flutter-enabled environment/CI) |

## 5. Files touched

| File | Action |
|------|--------|
| `lib/pages/pangaturan.dart` | refactored — form amputated, read-only profile UI injected |
| `plan/flutter_settings_restoration_build.md` | **created** — this report |
