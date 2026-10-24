import 'package:flutter/material.dart';
import 'package:visual_time_counter/core/domain/color_token.dart';
import 'package:visual_time_counter/core/domain/palette_id.dart';

/// Dial colors (contracts/ui/00 §4); the domain decides the phase, this
/// maps phases and tokens to colors.
abstract final class DialPalettes {
  static const Map<PalettePhase, Color> _progressive = {
    PalettePhase.start: Color(0xFF3BAA5C),
    PalettePhase.middle: Color(0xFFF2C14E),
    PalettePhase.end: Color(0xFFE05A47),
  };

  /// Calm mode: blue, lilac and peach; no red or alert color.
  static const Map<PalettePhase, Color> _calm = {
    PalettePhase.start: Color(0xFF8FB8E8),
    PalettePhase.middle: Color(0xFFB9A7E0),
    PalettePhase.end: Color(0xFFF3C3A3),
  };

  static const Map<ColorToken, Color> _tokens = {
    ColorToken.blue: Color(0xFF4A90E2),
    ColorToken.green: Color(0xFF4CAF7A),
    ColorToken.yellow: Color(0xFFF2C14E),
    ColorToken.orange: Color(0xFFF29A4A),
    ColorToken.purple: Color(0xFF9B7AD8),
    ColorToken.pink: Color(0xFFE88AB8),
    ColorToken.teal: Color(0xFF3BB3A6),
    ColorToken.gray: Color(0xFF9AA0A6),
  };

  static const _emptyGray = Color(0xFF9AA0A6);
  static const _emptyLightAlpha = 0.18;
  static const _emptyDarkAlpha = 0.28;
  static const _emptyHighContrastLight = Color(0xFFE3E5E8);
  static const _emptyHighContrastDark = Color(0xFF2A2D33);

  /// The remaining-sector color of [palette] at [remainingFraction];
  /// [singleColor] is required for [PaletteId.single].
  static Color colorAt(
    PaletteId palette,
    double remainingFraction, {
    ColorToken? singleColor,
  }) {
    if (palette == PaletteId.single) {
      if (singleColor == null) throw ArgumentError.notNull('singleColor');
      return tokenColor(singleColor);
    }
    final phases = palette == PaletteId.calm ? _calm : _progressive;
    final blend = palette.phaseAt(remainingFraction);
    return Color.lerp(phases[blend.from], phases[blend.to], blend.t)!;
  }

  /// The color of a single-palette [token].
  static Color tokenColor(ColorToken token) => _tokens[token]!;

  /// The color of the dial's empty part; opaque when the system asks for more
  /// contrast (also covering "reduce transparency").
  static Color empty(Brightness brightness, {required bool highContrast}) {
    final isLight = brightness == Brightness.light;
    if (highContrast) {
      return isLight ? _emptyHighContrastLight : _emptyHighContrastDark;
    }
    return _emptyGray.withValues(
      alpha: isLight ? _emptyLightAlpha : _emptyDarkAlpha,
    );
  }
}
