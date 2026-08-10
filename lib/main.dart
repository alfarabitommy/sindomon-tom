import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'theme/theme_scope.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  /// Owns the global [ThemeMode]; exposed to the tree via [ThemeScope] and
  /// consumed by the [ValueListenableBuilder] below.
  final ThemeController _themeController = ThemeController();

  @override
  void initState() {
    super.initState();
    // Async load of the persisted "theme_mode" preference. When it resolves,
    // the notifier fires and the ValueListenableBuilder swaps the theme.
    _themeController.initTheme();
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: _themeController,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: _themeController.themeNotifier,
        builder: (context, themeMode, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: "SINDOMON",
            theme: AppThemeData.light,
            darkTheme: AppThemeData.dark,
            themeMode: themeMode,
            home: const LoginPage(),
          );
        },
      ),
    );
  }
}
