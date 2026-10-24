import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/domain/dial_direction.dart';
import 'package:visual_time_counter/core/domain/dial_scale.dart';
import 'package:visual_time_counter/features/timer/application/dial_geometry.dart';

const _radius = 100.0;

/// The point on the ring a [fraction] of a turn away from 12 o'clock, in the
/// direction the sector opens for [direction] (screen coordinates, y down).
Offset _pointAt(double fraction, DialDirection direction) {
  final sign = direction == DialDirection.clockwise ? -1 : 1;
  final angle = DialGeometry.startAngle + sign * fraction * 2 * pi;
  return Offset(cos(angle), sin(angle)) * _radius;
}

DialGeometry _geometry({
  DialScale scale = DialScale.min60,
  DialDirection direction = DialDirection.clockwise,
}) => DialGeometry(scale: scale, direction: direction);

void main() {
  group('setup fraction (FR-001)', () {
    test('is the duration over the scale', () {
      expect(_geometry().fractionOf(const Duration(minutes: 15)), 0.25);
      expect(
        _geometry(scale: DialScale.min15)
            .fractionOf(const Duration(minutes: 15)),
        1,
      );
    });

    test('is clamped to the full circle', () {
      final geometry = _geometry(scale: DialScale.min5);

      expect(geometry.fractionOf(const Duration(minutes: 7)), 1);
      expect(geometry.fractionOf(Duration.zero), 0);
    });
  });

  group('sweep angle', () {
    test("starts at 12 o'clock", () {
      expect(DialGeometry.startAngle, -pi / 2);
    });

    test('opens counter-clockwise for a clockwise dial, so it shrinks '
        'clockwise', () {
      expect(
        _geometry().sweepAngleOf(const Duration(minutes: 15)),
        closeTo(-pi / 2, 1e-9),
      );
    });

    test('opens clockwise for a counter-clockwise dial', () {
      expect(
        _geometry(direction: DialDirection.counterClockwise)
            .sweepAngleOf(const Duration(minutes: 15)),
        closeTo(pi / 2, 1e-9),
      );
    });

    test('is a full turn at the scale and zero when time is up', () {
      final geometry = _geometry(scale: DialScale.min10);

      expect(
        geometry.sweepAngleOf(const Duration(minutes: 10)).abs(),
        closeTo(2 * pi, 1e-9),
      );
      expect(geometry.sweepAngleOf(Duration.zero), 0);
    });
  });

  group('filled sweep while running (FR-002)', () {
    const tenMinutes = Duration(minutes: 10);

    test('is empty at the start', () {
      expect(_geometry().filledSweepAngleOf(tenMinutes, total: tenMinutes), 0);
    });

    test('is relative to the set duration, not to the scale', () {
      for (final scale in [DialScale.min15, DialScale.min60]) {
        expect(
          _geometry(scale: scale)
              .filledSweepAngleOf(const Duration(minutes: 5), total: tenMinutes)
              .abs(),
          closeTo(pi, 1e-9),
          reason: '$scale',
        );
      }
    });

    test('is a full turn when time is up', () {
      expect(
        _geometry().filledSweepAngleOf(Duration.zero, total: tenMinutes).abs(),
        closeTo(2 * pi, 1e-9),
      );
    });

    test('grows clockwise for a clockwise dial', () {
      expect(
        _geometry().filledSweepAngleOf(
          const Duration(minutes: 7, seconds: 30),
          total: tenMinutes,
        ),
        closeTo(pi / 2, 1e-9),
      );
    });

    test('grows counter-clockwise for a counter-clockwise dial', () {
      expect(
        _geometry(direction: DialDirection.counterClockwise).filledSweepAngleOf(
          const Duration(minutes: 7, seconds: 30),
          total: tenMinutes,
        ),
        closeTo(-pi / 2, 1e-9),
      );
    });

    test('is clamped between empty and full', () {
      final geometry = _geometry();

      expect(
        geometry.filledSweepAngleOf(
          const Duration(minutes: 12),
          total: tenMinutes,
        ),
        0,
      );
      expect(
        geometry
            .filledSweepAngleOf(const Duration(seconds: -5), total: tenMinutes)
            .abs(),
        closeTo(2 * pi, 1e-9),
      );
    });
  });

  group('duration at a dragged point (FR-001)', () {
    for (final direction in DialDirection.values) {
      test('a quarter turn is a quarter of the scale ($direction)', () {
        final geometry = _geometry(direction: direction);

        expect(
          geometry.durationAt(_pointAt(0.25, direction)).value,
          const Duration(minutes: 15),
        );
        expect(
          geometry.durationAt(_pointAt(0.5, direction)).value,
          const Duration(minutes: 30),
        );
        expect(
          geometry.durationAt(_pointAt(0.75, direction)).value,
          const Duration(minutes: 45),
        );
      });
    }

    test("a clockwise dial reads 15 min at 9 o'clock and 45 min at 3", () {
      final geometry = _geometry();

      expect(
        geometry.durationAt(const Offset(-_radius, 0)).value,
        const Duration(minutes: 15),
      );
      expect(
        geometry.durationAt(const Offset(_radius, 0)).value,
        const Duration(minutes: 45),
      );
    });

    test("a counter-clockwise dial reads 15 min at 3 o'clock", () {
      expect(
        _geometry(direction: DialDirection.counterClockwise)
            .durationAt(const Offset(_radius, 0))
            .value,
        const Duration(minutes: 15),
      );
    });

    test('depends on the scale', () {
      expect(
        _geometry(scale: DialScale.min10)
            .durationAt(_pointAt(0.5, DialDirection.clockwise))
            .value,
        const Duration(minutes: 5),
      );
    });

    test('rounds to whole minutes from 2 min on', () {
      final geometry = _geometry();
      double fractionOf(Duration value) => value.inSeconds / 3600;

      expect(
        geometry
            .durationAt(
              _pointAt(
                fractionOf(const Duration(minutes: 14, seconds: 20)),
                DialDirection.clockwise,
              ),
            )
            .value,
        const Duration(minutes: 14),
      );
      expect(
        geometry
            .durationAt(
              _pointAt(
                fractionOf(const Duration(minutes: 14, seconds: 40)),
                DialDirection.clockwise,
              ),
            )
            .value,
        const Duration(minutes: 15),
      );
    });

    test('rounds to 10 s below 2 min', () {
      final geometry = _geometry(scale: DialScale.min10);
      double fractionOf(int seconds) => seconds / 600;

      expect(
        geometry
            .durationAt(_pointAt(fractionOf(64), DialDirection.clockwise))
            .value,
        const Duration(seconds: 60),
      );
      expect(
        geometry
            .durationAt(_pointAt(fractionOf(66), DialDirection.clockwise))
            .value,
        const Duration(seconds: 70),
      );
    });

    test('never goes below the 10 s minimum', () {
      expect(
        _geometry().durationAt(_pointAt(0.001, DialDirection.clockwise)).value,
        const Duration(seconds: 10),
      );
    });

    test('never goes past the scale', () {
      expect(
        _geometry(scale: DialScale.min15)
            .durationAt(_pointAt(0.999, DialDirection.clockwise))
            .value,
        const Duration(minutes: 15),
      );
    });

    test("dragging past 12 o'clock from a full dial stays full", () {
      expect(
        _geometry()
            .durationAt(
              _pointAt(0.02, DialDirection.clockwise),
              previous: const Duration(minutes: 55),
            )
            .value,
        const Duration(minutes: 60),
      );
    });

    test("dragging back past 12 o'clock from a short timer stays at the "
        'minimum', () {
      expect(
        _geometry()
            .durationAt(
              _pointAt(0.98, DialDirection.clockwise),
              previous: const Duration(minutes: 2),
            )
            .value,
        const Duration(seconds: 10),
      );
    });

    test("moves freely when the drag does not cross 12 o'clock", () {
      expect(
        _geometry()
            .durationAt(
              _pointAt(0.5, DialDirection.clockwise),
              previous: const Duration(minutes: 55),
            )
            .value,
        const Duration(minutes: 30),
      );
    });
  });

  group('ring hit test', () {
    test('accepts touches on and near the edge', () {
      final geometry = _geometry();

      expect(geometry.isOnRing(const Offset(0, -100), radius: _radius), true);
      expect(geometry.isOnRing(const Offset(0, -60), radius: _radius), true);
      expect(geometry.isOnRing(const Offset(120, 0), radius: _radius), true);
    });

    test('ignores touches near the center or far outside the ring', () {
      final geometry = _geometry();

      expect(geometry.isOnRing(const Offset(0, -40), radius: _radius), false);
      expect(geometry.isOnRing(Offset.zero, radius: _radius), false);
      expect(geometry.isOnRing(const Offset(0, 130), radius: _radius), false);
    });
  });
}
