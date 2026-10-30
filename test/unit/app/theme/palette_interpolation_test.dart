import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/app/theme/palettes.dart';
import 'package:visual_time_counter/core/domain/color_token.dart';
import 'package:visual_time_counter/core/domain/palette_id.dart';

/// Hues in [345°, 15°] read as red.
const _redHueStart = 345.0;
const _redHueEnd = 15.0;

const _upperThreshold = 0.5;
const _lowerThreshold = 0.2;
const _halfBand = 0.01;

void main() {
  Color progressive(double remaining) =>
      DialPalettes.colorAt(PaletteId.progressive, remaining);

  group('progressive thresholds with 2% interpolation', () {
    final green = progressive(1);
    final yellow = progressive(0.35);
    final red = progressive(0);

    test('is solid green above the upper band', () {
      expect(progressive(_upperThreshold + _halfBand), green);
    });

    test('is solid yellow between the bands', () {
      expect(progressive(_upperThreshold - _halfBand), yellow);
      expect(progressive(_lowerThreshold + _halfBand), yellow);
    });

    test('is solid red below the lower band', () {
      expect(progressive(_lowerThreshold - _halfBand), red);
    });

    test('blends inside each band', () {
      final insideUpper = progressive(_upperThreshold + _halfBand / 2);
      final insideLower = progressive(_lowerThreshold + _halfBand / 2);

      expect(insideUpper, isNot(anyOf(green, yellow)));
      expect(insideLower, isNot(anyOf(yellow, red)));
    });

    test('changes continuously across the whole range', () {
      var previous = progressive(1);
      for (var step = 99; step >= 0; step--) {
        final current = progressive(step / 100);
        expect(
          _distance(previous, current),
          lessThan(0.5),
          reason: 'jump at $step%',
        );
        previous = current;
      }
    });
  });

  group('calm mode', () {
    test('never has a red hue', () {
      for (var step = 0; step <= 100; step++) {
        final hue = HSVColor.fromColor(
          DialPalettes.colorAt(PaletteId.calm, step / 100),
        ).hue;
        final isRedHue = hue >= _redHueStart || hue <= _redHueEnd;
        expect(isRedHue, isFalse, reason: 'hue $hue at $step%');
      }
    });
  });

  group('single color', () {
    test('is constant over the whole range', () {
      final expected = DialPalettes.tokenColor(ColorToken.purple);
      for (var step = 0; step <= 100; step++) {
        expect(
          DialPalettes.colorAt(
            PaletteId.single,
            step / 100,
            singleColor: ColorToken.purple,
          ),
          expected,
        );
      }
    });
  });
}

double _distance(Color a, Color b) =>
    (a.r - b.r).abs() + (a.g - b.g).abs() + (a.b - b.b).abs();
