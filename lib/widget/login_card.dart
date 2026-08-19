import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../widget/textfield.dart';
import '../pages/dashboard.dart';
import '../config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/hud_loading.dart';
import '../theme/theme_scope.dart';

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

  /// Standard red error snackbar used by every failure path.
  ///
  /// Backend-provided text is reflected here, so cap its length to keep
  /// unbounded server messages from dominating the UI (phishing-style text).
  void _showError(String message) {
    const int maxLength = 160;
    // characters (grapheme clusters) — a plain substring could split an
    // emoji surrogate pair at the boundary and render a broken glyph.
    final text = message.characters.length > maxLength
        ? "${message.characters.take(maxLength)}…"
        : message;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
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

  Future<void> login() async {
    // Desktop copy-paste (Windows) commonly carries trailing spaces/newlines
    // on the USERNAME — trim the identity. The password is a secret and is
    // sent VERBATIM: trimming it could lock out users whose real password
    // intentionally has leading/trailing whitespace.
    final username = usernameController.text.trim();
    final password = passwordController.text;

    setState(() {
      usernameError = username.isEmpty;
      passwordError = password.trim().isEmpty;
    });

    if (username.isEmpty && password.isEmpty) {
      _showError("Kredensial tidak valid. Silahkan periksa kembali.");
      return;
    }

    if (username.isEmpty) {
      _showError("Username wajib diisi");
      return;
    }

    if (password.isEmpty) {
      _showError("Password wajib diisi");
      return;
    }

    // Block the UI with the HUD overlay while the request is in flight.
    HudLoading.show(context, label: "MENGOTENTIKASI...");
    debugPrint("Login → POST $apiBaseUrl/api/v1/auth/login");

    try {
      final response = await http
          .post(
            Uri.parse("$apiBaseUrl/api/v1/auth/login"),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
              // dart:io (Windows desktop) sends "Dart/3.x (dart:io)" unless
              // overridden; pin a stable client identity. Browsers ignore the
              // User-Agent header on XHR, hence the kIsWeb guard.
              if (!kIsWeb) "User-Agent": "SINDOMON-Client/1.0",
            },
            body: jsonEncode({
              "username": username,
              "password": password,
            }),
          )
          // No HTTP timeout existed anywhere in the app — a hung connection
          // (broken IPv4/IPv6 path, proxy) kept the HUD up forever.
          .timeout(const Duration(seconds: 20));

      // Decode the envelope defensively: the body may be HTML/empty on
      // gateway errors, so never assume valid JSON.
      // (Non-final: assigned from both the try and the catch path.)
      Map<String, dynamic> envelope;
      try {
        final decoded = jsonDecode(response.body);
        envelope = decoded is Map<String, dynamic>
            ? decoded
            : <String, dynamic>{};
      } catch (_) {
        envelope = <String, dynamic>{};
      }
      final backendMessage = envelope["message"] is String
          ? (envelope["message"] as String).trim()
          : "";

      if (response.statusCode == 200) {
        final payload = envelope["data"] is Map<String, dynamic>
            ? envelope["data"] as Map<String, dynamic>
            : <String, dynamic>{};

        // --- JARING PENGAMAN NULL ---
        // Backend history ships BOTH shapes for `user`:
        //   data.user = { ... }   (object — current)
        //   data.user = [ {...} ] (array — legacy, see flutter_login_fix_plan.md)
        // Accept either so a shape mismatch can never surface as a fake
        // "invalid credentials" snackbar.
        final rawUser = payload["user"];
        final Map<String, dynamic> userData;
        if (rawUser is Map<String, dynamic>) {
          userData = rawUser;
        } else if (rawUser is List &&
            rawUser.isNotEmpty &&
            rawUser.first is Map<String, dynamic>) {
          userData = rawUser.first as Map<String, dynamic>;
        } else {
          userData = <String, dynamic>{};
        }

        final token = payload["jwt_token"]?.toString().trim() ?? "";
        if (token.isEmpty) {
          // HTTP 200 without a token is a broken contract, not a success.
          if (!mounted) return;
          HudLoading.hide(context);
          _showError("Respons login tidak valid (token kosong). Silahkan coba lagi.");
          return;
        }

        final usernameLogin = userData["username"]?.toString() ?? "";
        final poldaLogin = userData["polda_id"]?.toString() ?? "";
        final roleID = userData["roles_id"]?.toString() ?? "";
        final uuid = userData["uuid"]?.toString() ?? "";
        final expired = userData["expired"]?.toString() ?? "";
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", token);
        await prefs.setString("username_login", usernameLogin);
        await prefs.setString("polda_login", poldaLogin);
        await prefs.setString("roleid_login", roleID);
        await prefs.setString("uuid_login", uuid);
        await prefs.setString("expired_login", expired);
        if (!mounted) return;
        // pushAndRemoveUntil removes BOTH the login page and the HUD dialog
        // route, so the dashboard becomes the only route on the stack and the
        // back button can never return to the login form.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
          (route) => false,
        );
      } else if (response.statusCode == 403) {
        if (!mounted) return;
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
      } else if (response.statusCode == 401 ||
          response.statusCode == 400 ||
          response.statusCode == 422) {
        // Credential/validation failure — prefer the backend's own message
        // (e.g. "Username atau password salah.") over the hardcoded text.
        if (!mounted) return;
        HudLoading.hide(context);
        _showError(backendMessage.isNotEmpty
            ? backendMessage
            : "Kredensial tidak valid. Silahkan periksa kembali.");
      } else {
        if (!mounted) return;
        HudLoading.hide(context);
        _showError(backendMessage.isNotEmpty
            ? backendMessage
            : "Gagal masuk (HTTP ${response.statusCode}). Silahkan coba lagi.");
      }
    } on TimeoutException {
      debugPrint("Login timeout");
      if (!mounted) return;
      HudLoading.hide(context);
      _showError("Koneksi ke server timeout. Silahkan coba lagi.");
    } on http.ClientException catch (e) {
      // dart:io (Windows/Linux/macOS desktop) surfaces connectivity failures
      // here — DNS failure, no route, proxy rejection, IPv4/IPv6 blackhole.
      // These are NOT credential problems and must not claim to be.
      debugPrint("Login network error: $e");
      if (!mounted) return;
      HudLoading.hide(context);
      _showError(
        "Tidak dapat terhubung ke server. Periksa koneksi internet atau proxy Anda.",
      );
    } catch (e, st) {
      debugPrint('Login error: $e\n$st');
      if (!mounted) return;
      HudLoading.hide(context);
      final text = e.toString();
      if (text.contains('Handshake') ||
          text.contains('CERTIFICATE') ||
          text.contains('TLS')) {
        _showError(
          "TRACE: $text",
        );
      } else {
        _showError("Terjadi kesalahan tidak terduga. Silahkan coba lagi.");
      }
    }
  }

  /// Theme toggle: identical to the sidebar's switcher, but compact so it
  /// sits snugly in the login card's top-right corner.
  Widget _buildThemeToggle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: () => ThemeScope.of(context).toggleTheme(),
      tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) =>
            RotationTransition(turns: animation, child: child),
        child: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          key: ValueKey(isDark),
          color: scheme.onSurface,
          size: 22,
        ),
      ),
      style: IconButton.styleFrom(
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: scheme.outline.withValues(alpha: 0.4),
              width: 1.0,
            ),
          ),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    "assets/images/logo-korsabhara.png",
                    height: 95,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "SINDOMON - Portal Masuk",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 25),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Username / NRP",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  AppTextField(
                    hint: "Masukkan NRP atau Username",
                    controller: usernameController,
                    error: usernameError,
                  ),

                  const SizedBox(height: 15),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Kata Sandi",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: scheme.onSurface,
                      ),
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
              Positioned(
                top: 0,
                right: 0,
                child: _buildThemeToggle(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
