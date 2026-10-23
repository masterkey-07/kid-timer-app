import 'package:flutter/material.dart';

/// The type scale of contracts/ui/00 §4: display 56/64 (countdown digits),
/// title 22/28, body 16/24, label 14/20.
abstract final class AppTypography {
  /// Applies the scale to [base]; the display style uses tabular figures so
  /// the countdown digits do not jump.
  static TextTheme apply(TextTheme base) => base.copyWith(
    displayLarge: _sized(
      base.displayLarge,
      size: 56,
      lineHeight: 64,
    ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
    titleLarge: _sized(base.titleLarge, size: 22, lineHeight: 28),
    bodyLarge: _sized(base.bodyLarge, size: 16, lineHeight: 24),
    labelLarge: _sized(base.labelLarge, size: 14, lineHeight: 20),
  );

  static TextStyle _sized(
    TextStyle? style, {
    required double size,
    required double lineHeight,
  }) => (style ?? const TextStyle()).copyWith(
    fontSize: size,
    height: lineHeight / size,
  );
}
