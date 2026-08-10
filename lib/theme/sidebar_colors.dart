import 'package:flutter/material.dart';

/// Theme-aware color tokens for the [AppSidebar].
///
/// Resolve once per build with
/// `SidebarColors.fromBrightness(Theme.of(context).brightness)` so every
/// hardcoded color in the sidebar becomes reactive to the global theme.
class SidebarColors {
  const SidebarColors({
    required this.background,
    required this.textPrimary,
    required this.textSecondary,
    required this.iconColor,
    required this.selectedBg,
    required this.selectedText,
    required this.hoverColor,
    required this.shadowColor,
  });

  /// Sidebar panel background.
  final Color background;

  /// Primary text (title, selected labels).
  final Color textPrimary;

  /// Secondary text (subtitle, unselected labels).
  final Color textSecondary;

  /// Menu icons (unselected).
  final Color iconColor;

  /// Highlight background of the selected menu item.
  final Color selectedBg;

  /// Text/icon color on top of [selectedBg].
  final Color selectedText;

  /// Hover ripple background for menu tiles.
  final Color hoverColor;

  /// BoxShadow color cast over the content area.
  final Color shadowColor;

  /// Dark = Deep Indigo/Void, Light = Crisp White/Slate.
  factory SidebarColors.fromBrightness(Brightness brightness) {
    return brightness == Brightness.dark
        ? const SidebarColors(
            background: Color(0xFF0F0B2E), // deep void indigo
            textPrimary: Colors.white,
            textSecondary: Colors.white54,
            iconColor: Colors.white70,
            selectedBg: Color(0xFFF6B300), // brand gold
            selectedText: Color(0xFF0F0B2E), // dark text on gold
            hoverColor: Colors.white10,
            shadowColor: Colors.black38,
          )
        : const SidebarColors(
            background: Colors.white, // crisp white
            textPrimary: Color(0xFF1E293B), // slate-800
            textSecondary: Color(0xFF64748B), // slate-500
            iconColor: Color(0xFF475569), // slate-600
            selectedBg: Color(0xFF1E1B4B), // brand indigo
            selectedText: Colors.white,
            hoverColor: Color(0x0A000000), // black @ 4%
            shadowColor: Colors.black12,
          );
  }
}
