import 'package:flutter/material.dart';

import '../widget/hud_loading_spinner.dart';

/// Global HUD loading overlay helper.
///
/// Shows a full-screen, non-dismissible overlay containing an
/// [HudLoadingSpinner] above a dark barrier. Pair every [HudLoading.show]
/// with a matching [HudLoading.hide] once the blocking operation completes.
///
/// No static state is kept: `show()` always creates a fresh dialog route and
/// `hide()` is a guarded pop, so a stale flag can never silently swallow a
/// `show()` call.
class HudLoading {
  HudLoading._();

  /// Displays the HUD loading overlay above [context].
  ///
  /// [label] is rendered below the spinner. The overlay cannot be dismissed
  /// by tapping the barrier or by the system back button.
  static void show(BuildContext context, {String? label}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      useRootNavigator: true,
      builder: (_) {
        return PopScope<void>(
          canPop: false,
          child: Material(
            type: MaterialType.transparency,
            child: Center(
              child: HudLoadingSpinner(
                size: 80,
                label: label ?? 'MEMUAT...',
              ),
            ),
          ),
        );
      },
    );
  }

  /// Dismisses the HUD loading overlay shown via [HudLoading.show].
  ///
  /// Safe to call when no overlay is visible — the pop is wrapped in a
  /// try/catch so it can never accidentally remove an application route.
  static void hide(BuildContext context) {
    try {
      Navigator.of(context, rootNavigator: true).pop();
    } catch (_) {
      // No overlay to dismiss — ignore.
    }
  }
}
