import 'package:flutter/material.dart';

/// Design tokens from contracts/ui/00 §4.
abstract final class AppTokens {
  /// The bundled app font (SIL OFL 1.1).
  static const fontFamily = 'AtkinsonHyperlegibleNext';

  /// Corner radius of cards.
  static const cardRadius = 16.0;

  /// Minimum height of primary buttons.
  static const primaryButtonHeight = 56.0;

  /// Minimum touch target (Constitution V).
  static const minTouchTarget = 48.0;

  /// Default animation duration; 0 or opacity-only with reduce motion.
  static const motion = Duration(milliseconds: 200);

  /// Default animation curve.
  static const Cubic motionCurve = Curves.easeOutCubic;

  /// Page margins per size class.
  static const marginCompact = 16.0;

  /// Page margin, medium class.
  static const marginMedium = 24.0;

  /// Page margin, expanded class.
  static const marginExpanded = 32.0;
}

/// The base colors of one theme variant.
typedef ThemeColors = ({
  Color surface,
  Color text,
  Color secondaryText,
  Color primary,
  Color onPrimary,
});

/// The four theme variants (contracts/ui/00 §4; FR-055).
abstract final class AppColors {
  /// Light theme.
  static const ThemeColors light = (
    surface: Color(0xFFFFFBF5),
    text: Color(0xFF1C1B1F),
    secondaryText: Color(0xFF5F6368),
    primary: Color(0xFF3A6FD8),
    onPrimary: Color(0xFFFFFFFF),
  );

  /// Dark theme.
  static const ThemeColors dark = (
    surface: Color(0xFF14161A),
    text: Color(0xFFECEDEE),
    secondaryText: Color(0xFFB0B4BA),
    primary: Color(0xFF8AB0FF),
    onPrimary: Color(0xFF0B1F44),
  );

  /// High-contrast light theme.
  static const ThemeColors highContrastLight = (
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF000000),
    secondaryText: Color(0xFF1F1F1F),
    primary: Color(0xFF0039A6),
    onPrimary: Color(0xFFFFFFFF),
  );

  /// High-contrast dark theme.
  static const ThemeColors highContrastDark = (
    surface: Color(0xFF000000),
    text: Color(0xFFFFFFFF),
    secondaryText: Color(0xFFE6E6E6),
    primary: Color(0xFFA8C7FF),
    onPrimary: Color(0xFF000000),
  );
}

/// Notice banner colors: a soft amber container with the theme's text
/// color; high contrast uses the plain surface with a text-colored border.
abstract final class WarningColors {
  /// Banner background in the light theme.
  static const containerLight = Color(0xFFFFF1CC);

  /// Banner background in the dark theme.
  static const containerDark = Color(0xFF3A3020);
}
