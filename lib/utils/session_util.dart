import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/login_page.dart';

/// Clears the persisted session (all SharedPreferences keys) and navigates
/// back to the [LoginPage], removing every route from the stack.
Future<void> clearSessionAndLogout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  if (!context.mounted) return;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => const LoginPage()),
    (route) => false,
  );
}
