import 'package:flutter/material.dart';
import 'package:visual_time_counter/app/theme/tokens.dart';
import 'package:visual_time_counter/app/theme/typography.dart';

/// The light, dark and high-contrast themes (FR-055). `MaterialApp` picks
/// the high-contrast variants when the system asks for more contrast.
abstract final class AppTheme {
  /// The light theme.
  static ThemeData light() => _build(AppColors.light, Brightness.light);

  /// The dark theme.
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  /// The high-contrast light theme.
  static ThemeData highContrastLight() =>
      _build(AppColors.highContrastLight, Brightness.light, highContrast: true);

  /// The high-contrast dark theme.
  static ThemeData highContrastDark() =>
      _build(AppColors.highContrastDark, Brightness.dark, highContrast: true);

  static ThemeData _build(
    ThemeColors colors,
    Brightness brightness, {
    bool highContrast = false,
  }) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: colors.primary,
          brightness: brightness,
          contrastLevel: highContrast ? 1 : 0,
        ).copyWith(
          primary: colors.primary,
          onPrimary: colors.onPrimary,
          surface: colors.surface,
          onSurface: colors.text,
          onSurfaceVariant: colors.secondaryText,
          // The dial outline: secondary text, or the text color in high
          // contrast (contracts/ui/00 §3.2 and §4).
          outline: highContrast ? colors.text : colors.secondaryText,
        );

    final base = ThemeData(
      colorScheme: scheme,
      fontFamily: AppTokens.fontFamily,
      scaffoldBackgroundColor: colors.surface,
    );

    return base.copyWith(
      textTheme: AppTypography.apply(base.textTheme),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(
            AppTokens.primaryButtonHeight,
            AppTokens.primaryButtonHeight,
          ),
          shape: const StadiumBorder(),
        ),
      ),
      cardTheme: const CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppTokens.cardRadius)),
        ),
      ),
    );
  }
}
