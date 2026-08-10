import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences key that persists the user's theme choice.
/// Values: `"light"` | `"dark"` (== [ThemeMode.name]).
const String kThemeModeKey = "theme_mode";

/// Owns the global [ThemeMode] state and persists it to [SharedPreferences].
///
/// Usage:
/// - At startup call [initTheme] once (before/while building the root).
/// - Wrap [MaterialApp] in a `ValueListenableBuilder<ThemeMode>`
///   listening to [themeNotifier] and pass `themeMode: notifier.value`.
/// - The sidebar toggle calls [toggleTheme].
class ThemeController {
  ThemeController() : themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

  /// Public notifier consumed by the root [MaterialApp].
  final ValueNotifier<ThemeMode> themeNotifier;

  /// Loads the persisted theme preference ("theme_mode") from
  /// [SharedPreferences]. Falls back to the current value when the key is
  /// missing or holds an unknown string.
  Future<void> initTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(kThemeModeKey);
    if (saved == null) return;
    final parsed = ThemeMode.values.asNameMap()[saved];
    if (parsed != null) themeNotifier.value = parsed;
  }

  /// Flips between [ThemeMode.light] and [ThemeMode.dark], then persists the
  /// new value so the choice survives app restarts.
  Future<void> toggleTheme() async {
    final next = themeNotifier.value == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    themeNotifier.value = next;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kThemeModeKey, next.name);
  }

  /// Releases the notifier. Call from the owning widget's `dispose()`.
  void dispose() => themeNotifier.dispose();
}
