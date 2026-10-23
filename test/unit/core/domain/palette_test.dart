import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/domain/palette_id.dart';

void main() {
  group('phaseAt (progressive thresholds)', () {
    test('is the start phase (green) above 50%', () {
      expect(
        PaletteId.progressive.phaseAt(1),
        PaletteBlend.solid(PalettePhase.start),
      );
      expect(
        PaletteId.progressive.phaseAt(0.52),
        PaletteBlend.solid(PalettePhase.start),
      );
    });

    test('is the middle phase (yellow) between 20% and 50%', () {
      expect(
        PaletteId.progressive.phaseAt(0.48),
        PaletteBlend.solid(PalettePhase.middle),
      );
      expect(
        PaletteId.progressive.phaseAt(0.35),
        PaletteBlend.solid(PalettePhase.middle),
      );
      expect(
        PaletteId.progressive.phaseAt(0.22),
        PaletteBlend.solid(PalettePhase.middle),
      );
    });

    test('is the end phase (red) below 20%', () {
      expect(
        PaletteId.progressive.phaseAt(0.18),
        PaletteBlend.solid(PalettePhase.end),
      );
      expect(
        PaletteId.progressive.phaseAt(0),
        PaletteBlend.solid(PalettePhase.end),
      );
    });

    test('blends smoothly over a 2% band centered on each threshold', () {
      final atFifty = PaletteId.progressive.phaseAt(0.5);
      expect(atFifty.from, PalettePhase.start);
      expect(atFifty.to, PalettePhase.middle);
      expect(atFifty.t, closeTo(0.5, 1e-9));

      final nearFiftyOne = PaletteId.progressive.phaseAt(0.505);
      expect(nearFiftyOne.t, closeTo(0.25, 1e-9));

      final atTwenty = PaletteId.progressive.phaseAt(0.2);
      expect(atTwenty.from, PalettePhase.middle);
      expect(atTwenty.to, PalettePhase.end);
      expect(atTwenty.t, closeTo(0.5, 1e-9));
    });

    test('the blend is continuous at the band edges', () {
      const epsilon = 1e-6;
      expect(
        PaletteId.progressive.phaseAt(0.51 + epsilon),
        PaletteBlend.solid(PalettePhase.start),
      );
      expect(PaletteId.progressive.phaseAt(0.51 - epsilon).t, lessThan(0.001));
      expect(
        PaletteId.progressive.phaseAt(0.49 + epsilon).t,
        greaterThan(0.999),
      );
      expect(
        PaletteId.progressive.phaseAt(0.49 - epsilon),
        PaletteBlend.solid(PalettePhase.middle),
      );
    });

    test('clamps fractions outside [0, 1]', () {
      expect(
        PaletteId.progressive.phaseAt(1.4),
        PaletteBlend.solid(PalettePhase.start),
      );
      expect(
        PaletteId.progressive.phaseAt(-0.2),
        PaletteBlend.solid(PalettePhase.end),
      );
    });
  });

  test('calm mode follows the same smooth phases with its own colors', () {
    for (final fraction in [1.0, 0.5, 0.35, 0.2, 0.05]) {
      expect(
        PaletteId.calm.phaseAt(fraction),
        PaletteId.progressive.phaseAt(fraction),
      );
    }
  });

  test('the single color palette never changes phase', () {
    for (final fraction in [1.0, 0.5, 0.2, 0.0]) {
      expect(
        PaletteId.single.phaseAt(fraction),
        PaletteBlend.solid(PalettePhase.start),
      );
    }
  });

  test('only progressive uses alert colors', () {
    expect(PaletteId.progressive.usesAlertColors, isTrue);
    expect(PaletteId.calm.usesAlertColors, isFalse);
    expect(PaletteId.single.usesAlertColors, isFalse);
  });

  test('serializes by name', () {
    expect(PaletteId.calm.toJson(), 'calm');
    expect(PaletteId.fromJson('calm'), PaletteId.calm);
    expect(() => PaletteId.fromJson('neon'), throwsFormatException);
  });
}
