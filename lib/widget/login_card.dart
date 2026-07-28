import 'package:flutter/material.dart';
import '../widget/textfield.dart';
import '../pages/dashboard.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginCard extends StatefulWidget {
  const LoginCard({super.key});

  @override
  State<LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<LoginCard> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool usernameError = false;
  bool passwordError = false;

  @override
  void dispose() {
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
        const SnackBar(
          content: Text("Kredensial tidak valid. Silahkan periksa kembali."),
        ),
      );
      return;
    }

    if (usernameEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username wajib diisi")),
      );
      return;
    }

    if (passwordEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password wajib diisi")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("https://sindomon.yoknusantara.com/api/v1/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": usernameController.text,
          "password": passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String token = data["jwt_token"];
        String usernameLogin = data["data"][0]["username"];
        String poldaLogin = data["data"][0]["polda_id"];
        String roleID = data["data"][0]["roles_id"];
        String uuid = data["data"][0]["uuid"];
        String expired = data["data"][0]["expired"];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", token);
        await prefs.setString("username_login", usernameLogin);
        await prefs.setString("polda_login", poldaLogin);
        await prefs.setString("roleid_login", roleID);
        await prefs.setString("uuid_login", uuid);
        await prefs.setString("expired_login", expired);
        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Kredensial tidak valid. Silahkan periksa kembali."),
          ),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kredensial tidak valid. Silahkan periksa kembali."),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset("assets/images/mascot_login.jpg", width: 80),

          const SizedBox(height: 12),

          const Text(
            "SINDOMON - Portal Masuk",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 25),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Username / NRP",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),

          const SizedBox(height: 6),

          AppTextField(
            hint: "input_username",
            controller: usernameController,
            error: usernameError,
          ),

          const SizedBox(height: 15),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Kata Sandi",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),

          const SizedBox(height: 6),

          AppTextField(
            hint: "input_password",
            controller: passwordController,
            obscure: true,
            error: passwordError,
          ),

          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: isLoading ? null : login,

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
    );
  }
}
