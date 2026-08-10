import 'package:flutter/material.dart';
import 'theme_controller.dart';

/// Exposes the app-wide [ThemeController] to the widget tree without a
/// third-party state-management package.
///
/// Placed above [MaterialApp] in `main.dart`; any descendant (e.g. the
/// `AppScaffold` → `AppSidebar` chain) reads it with [ThemeScope.of].
class ThemeScope extends InheritedWidget {
  const ThemeScope({
    super.key,
    required this.controller,
    required super.child,
  });

  /// The app-wide theme controller.
  final ThemeController controller;

  /// Returns the nearest [ThemeScope]'s controller.
  ///
  /// Registers a dependency so the caller rebuilds if the scope is ever
  /// replaced (the controller instance itself never changes at runtime).
  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope not found above this context');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(ThemeScope oldWidget) =>
      controller != oldWidget.controller;
}
