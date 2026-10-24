import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/app/theme/palettes.dart';
import 'package:visual_time_counter/core/domain/color_token.dart';
import 'package:visual_time_counter/core/domain/palette_id.dart';

void main() {
  group('dialColor', () {
    test('progressive phases are green, yellow and red', () {
      expect(
        DialPalettes.colorAt(PaletteId.progressive, 1),
        const Color(0xFF3BAA5C),
      );
      expect(
        DialPalettes.colorAt(PaletteId.progressive, 0.35),
        const Color(0xFFF2C14E),
      );
      expect(
        DialPalettes.colorAt(PaletteId.progressive, 0.05),
        const Color(0xFFE05A47),
      );
    });

    test('blends halfway at a threshold', () {
      expect(
        DialPalettes.colorAt(PaletteId.progressive, 0.5),
        isSameColorAs(
          Color.lerp(const Color(0xFF3BAA5C), const Color(0xFFF2C14E), 0.5)!,
        ),
      );
    });

    test('calm phases are blue, lilac and peach', () {
      expect(DialPalettes.colorAt(PaletteId.calm, 1), const Color(0xFF8FB8E8));
      expect(
        DialPalettes.colorAt(PaletteId.calm, 0.35),
        const Color(0xFFB9A7E0),
      );
      expect(
        DialPalettes.colorAt(PaletteId.calm, 0.05),
        const Color(0xFFF3C3A3),
      );
    });

    test('calm mode never uses red, even while blending', () {
      for (var step = 0; step <= 100; step++) {
        final color = DialPalettes.colorAt(PaletteId.calm, step / 100);
        expect(_isRed(color), isFalse, reason: 'at $step%: $color');
      }
    });

    test('the progressive end color is red', () {
      expect(_isRed(DialPalettes.colorAt(PaletteId.progressive, 0)), isTrue);
    });

    test('the single palette keeps its token color', () {
      for (final fraction in [1.0, 0.5, 0.1]) {
        expect(
          DialPalettes.colorAt(
            PaletteId.single,
            fraction,
            singleColor: ColorToken.teal,
          ),
          DialPalettes.tokenColor(ColorToken.teal),
        );
      }
    });

    test('the single palette needs a color', () {
      expect(
        () => DialPalettes.colorAt(PaletteId.single, 1),
        throwsArgumentError,
      );
    });
  });

  test('offers 8 distinct token colors (FR-051)', () {
    final colors = ColorToken.values.map(DialPalettes.tokenColor).toSet();

    expect(colors, hasLength(8));
  });

  group('empty part of the dial', () {
    test('is translucent gray in the regular themes', () {
      expect(
        DialPalettes.empty(Brightness.light, highContrast: false),
        const Color(0xFF9AA0A6).withValues(alpha: 0.18),
      );
      expect(
        DialPalettes.empty(Brightness.dark, highContrast: false),
        const Color(0xFF9AA0A6).withValues(alpha: 0.28),
      );
    });

    test('is opaque with increased contrast', () {
      expect(
        DialPalettes.empty(Brightness.light, highContrast: true),
        const Color(0xFFE3E5E8),
      );
      expect(
        DialPalettes.empty(Brightness.dark, highContrast: true),
        const Color(0xFF2A2D33),
      );
    });
  });
}

/// A saturated hue within 20° of pure red.
bool _isRed(Color color) {
  final hsl = HSLColor.fromColor(color);
  final hue = hsl.hue;
  return hsl.saturation > 0.4 && (hue <= 20 || hue >= 340);
}
