import 'package:flutter/material.dart';

/// Global theme definitions for SINDOMON.
///
/// - [AppThemeData.light] — **"Clean Corporate"**: crisp white/slate surfaces,
///   indigo primary + gold secondary (matches the existing brand identity).
/// - [AppThemeData.dark] — **"J.A.R.V.I.S Cyberpunk"**: deep void surfaces,
///   cyan primary glow + amber highlights.
///
/// Both themes keep `scaffoldBackgroundColor` transparent so the code-generated
/// [AppBackground] (gradient + cyber grid) shows through every page.
abstract final class AppThemeData {
  // ── Brand tokens ──────────────────────────────────────────────────────────
  static const Color brandIndigo = Color(0xFF1E1B4B);
  static const Color brandGold = Color(0xFFF6B300);
  static const Color jarvisCyan = Color(0xFF00E5FF);

  // ── Light: Clean Corporate ────────────────────────────────────────────────
  static ThemeData get light => _build(
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: brandIndigo,
          onPrimary: Colors.white,
          secondary: brandGold,
          onSecondary: brandIndigo,
          surface: Colors.white,
          onSurface: Color(0xFF1E293B), // slate-800
          error: Color(0xFFDC2626), // red-600
          onError: Colors.white,
          outline: Color(0xFFCBD5E1), // slate-300
          outlineVariant: Color(0xFFE2E8F0), // slate-200
          surfaceContainerHighest: Color(0xFFF1F5F9), // slate-100
        ),
        dividerColor: Colors.black.withValues(alpha: 0.08),
      );

  // ── Dark: J.A.R.V.I.S Cyberpunk ───────────────────────────────────────────
  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: jarvisCyan,
          onPrimary: Color(0xFF00222B), // deep cyan for text on the glow
          secondary: brandGold,
          onSecondary: brandIndigo,
          surface: Color(0xFF12142A), // void indigo surface
          onSurface: Color(0xFFE2E8F0), // slate-200
          error: Color(0xFFEF4444), // red-500
          onError: Colors.white,
          outline: Color(0xFF2A2E4A),
          outlineVariant: Color(0xFF1E2238),
          surfaceContainerHighest: Color(0xFF1A1E38),
        ),
        dividerColor: Colors.white.withValues(alpha: 0.08),
      );

  // ── Shared construction ───────────────────────────────────────────────────
  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color dividerColor,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      // Transparent so AppBackground's gradient/grid renders behind content.
      scaffoldBackgroundColor: Colors.transparent,
      dividerTheme: DividerThemeData(
        color: dividerColor,
        space: 1,
        thickness: 1,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surface,
        surfaceTintColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: brightness == Brightness.dark
              ? const Color(0xFF1A1E38)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
