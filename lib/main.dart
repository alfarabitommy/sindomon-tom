import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'config/api_config.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'theme/theme_scope.dart';

void main() {
  // Fail closed: credentials and JWTs are sent to apiBaseUrl, so a
  // misconfigured --dart-define=API_BASE_URL must never downgrade to http://.
  // (The default constant is https; this guards build-time overrides only.)
  final scheme = Uri.parse(apiBaseUrl).scheme.toLowerCase();
  if (scheme != 'https') {
    throw StateError(
      'apiBaseUrl must use https:// (got "$apiBaseUrl"). '
      'Fix the API_BASE_URL dart-define or api_config.dart.',
    );
  }
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
