import 'dart:ui';
import 'package:flutter/material.dart';
import '../widget/textfield.dart';
import '../pages/dashboard.dart';
import '../config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/hud_loading.dart';

class LoginCard extends StatefulWidget {
  const LoginCard({super.key});

  @override
  State<LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<LoginCard> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool usernameError = false;
  bool passwordError = false;

  @override
  void initState() {
    super.initState();
    usernameController.addListener(_clearErrorOnInput);
    passwordController.addListener(_clearErrorOnInput);
  }

  void _clearErrorOnInput() {
    if (usernameError || passwordError) {
      setState(() {
        usernameError = false;
        passwordError = false;
      });
    }
  }

  @override
  void dispose() {
    usernameController.removeListener(_clearErrorOnInput);
    passwordController.removeListener(_clearErrorOnInput);
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final usernameEmpty = usernameController.text.trim().isEmpty;
    final passwordEmpty = passwordController.text.trim().isEmpty;

    setState(() {
      usernameError = usernameEmpty;
      passwordError = passwordEmpty;
    });

    if (usernameEmpty && passwordEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Kredensial tidak valid. Silahkan periksa kembali.",
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (usernameEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text("Username wajib diisi"),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (passwordEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text("Password wajib diisi"),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    // Block the UI with the HUD overlay while the request is in flight.
    HudLoading.show(context, label: "MENGOTENTIKASI...");

    try {
      final response = await http.post(
        Uri.parse("$apiBaseUrl/api/v1/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": usernameController.text,
          "password": passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);  
        // --- JARING PENGAMAN NULL ---
        // Response menaruh user sebagai Map<String, dynamic> (JSON Object)
        final payload = data["data"] as Map<String, dynamic>? ?? {};
        final userData = payload["user"] as Map<String, dynamic>? ?? {};

        String token = payload["jwt_token"]?.toString() ?? "";
        String usernameLogin = userData["username"]?.toString() ?? "";
        String poldaLogin = userData["polda_id"]?.toString() ?? "";
        String roleID = userData["roles_id"]?.toString() ?? "";
        String uuid = userData["uuid"]?.toString() ?? "";
        String expired = userData["expired"]?.toString() ?? "";
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", token);
        await prefs.setString("username_login", usernameLogin);
        await prefs.setString("polda_login", poldaLogin);
        await prefs.setString("roleid_login", roleID);
        await prefs.setString("uuid_login", uuid);
        await prefs.setString("expired_login", expired);
        if (!context.mounted) return;
        // pushAndRemoveUntil removes BOTH the login page and the HUD dialog
        // route, so the dashboard becomes the only route on the stack and the
        // back button can never return to the login form.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
          (route) => false,
        );
      } else if (response.statusCode == 403) {
        if (!context.mounted) return;
        HudLoading.hide(context);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Akses Diblokir"),
            content: const Text(
              "Perangkat Anda belum terverifikasi. Sesi login diblokir. "
              "Silahkan hubungi Super Admin Mabes.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Tutup"),
              ),
            ],
          ),
        );
      } else {
        if (!context.mounted) return;
        HudLoading.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Kredensial tidak valid. Silahkan periksa kembali.",
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('Login error: $e\n$st');
      if (!context.mounted) return;
      HudLoading.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Kredensial tidak valid. Silahkan periksa kembali.",
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.0),
          ),
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset("assets/images/polri-logo.png", height: 85, fit: BoxFit.contain),

          const SizedBox(height: 12),

          const Text(
            "SINDOMON - Portal Masuk",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF23251D)),
          ),

          const SizedBox(height: 25),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Username / NRP",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF23251D)),
            ),
          ),

          const SizedBox(height: 6),

          AppTextField(
            hint: "Masukkan NRP atau Username",
            controller: usernameController,
            error: usernameError,
          ),

          const SizedBox(height: 15),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Kata Sandi",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF23251D)),
            ),
          ),

          const SizedBox(height: 6),

          AppTextField(
            hint: "••••••••",
            controller: passwordController,
            obscure: true,
            error: passwordError,
          ),

          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: login,

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffF6B300),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),

              child: const Text(
                "Masuk ke Sistem",
                style: TextStyle(fontWeight: FontWeight.bold),
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
