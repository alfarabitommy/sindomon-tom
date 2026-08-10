import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/login_page.dart';

/// Maps a persisted `roles_id` (String "1"/"2"/"3") to its display label.
/// Must stay in sync with the keys of `roleMenus` in menu_config.dart.
String roleLabelFromId(String? roleId) {
  switch (roleId) {
    case "1": return "Super Admin";
    case "2": return "Operator Polda";
    case "3": return "Command Center";
    default: return "Operator";
  }
}

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
