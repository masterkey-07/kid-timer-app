import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/domain/timer_duration.dart';

void main() {
  group('limits (v1.0)', () {
    test('accepts 10 s and 2 h', () {
      expect(TimerDuration(const Duration(seconds: 10)).value.inSeconds, 10);
      expect(TimerDuration(const Duration(hours: 2)).value.inHours, 2);
    });

    test('rejects less than 10 s', () {
      expect(
        () => TimerDuration(const Duration(seconds: 9)),
        throwsArgumentError,
      );
    });

    test('rejects more than 2 h', () {
      expect(
        () => TimerDuration(const Duration(hours: 2, seconds: 1)),
        throwsArgumentError,
      );
    });

    test('rejects values that are not whole seconds', () {
      expect(
        () => TimerDuration(const Duration(seconds: 30, milliseconds: 500)),
        throwsArgumentError,
      );
    });

    test('clamped keeps values inside the limits and drops fractions', () {
      expect(
        TimerDuration.clamped(const Duration(seconds: 3)).value,
        TimerDuration.min,
      );
      expect(
        TimerDuration.clamped(const Duration(hours: 5)).value,
        TimerDuration.max,
      );
      expect(
        TimerDuration.clamped(const Duration(seconds: 42, milliseconds: 900))
            .value,
        const Duration(seconds: 42),
      );
    });
  });

  group('adjustment step (FR-001)', () {
    test('is 10 s below 2 min and 1 min from 2 min on', () {
      expect(
        TimerDuration.stepAt(const Duration(minutes: 1, seconds: 59)),
        const Duration(seconds: 10),
      );
      expect(
        TimerDuration.stepAt(const Duration(minutes: 2)),
        const Duration(minutes: 1),
      );
    });

    test('increment uses the step of the current value', () {
      final at = TimerDuration.new;
      expect(
        at(const Duration(minutes: 1, seconds: 50)).increment().value,
        const Duration(minutes: 2),
      );
      expect(
        at(const Duration(minutes: 2)).increment().value,
        const Duration(minutes: 3),
      );
    });

    test('decrement uses the step of the value below', () {
      final at = TimerDuration.new;
      expect(
        at(const Duration(minutes: 2)).decrement().value,
        const Duration(minutes: 1, seconds: 50),
      );
      expect(
        at(const Duration(minutes: 3)).decrement().value,
        const Duration(minutes: 2),
      );
    });

    test('increment and decrement stop at the limits', () {
      expect(
        TimerDuration(TimerDuration.max).increment().value,
        TimerDuration.max,
      );
      expect(
        TimerDuration(TimerDuration.min).decrement().value,
        TimerDuration.min,
      );
    });

    test('snapped rounds to the nearest step and clamps', () {
      expect(
        TimerDuration.snapped(const Duration(seconds: 44)).value,
        const Duration(seconds: 40),
      );
      expect(
        TimerDuration.snapped(const Duration(seconds: 45)).value,
        const Duration(seconds: 50),
      );
      expect(
        TimerDuration.snapped(const Duration(minutes: 7, seconds: 29)).value,
        const Duration(minutes: 7),
      );
      expect(
        TimerDuration.snapped(const Duration(minutes: 7, seconds: 30)).value,
        const Duration(minutes: 8),
      );
      expect(
        TimerDuration.snapped(const Duration(seconds: 1)).value,
        TimerDuration.min,
      );
      expect(
        TimerDuration.snapped(const Duration(hours: 3)).value,
        TimerDuration.max,
      );
    });

    test('adjustedBy adds a delta and clamps (quick buttons)', () {
      final fiveMinutes = TimerDuration(const Duration(minutes: 5));
      expect(
        fiveMinutes.adjustedBy(const Duration(minutes: 1)).value,
        const Duration(minutes: 6),
      );
      expect(
        fiveMinutes.adjustedBy(const Duration(minutes: -10)).value,
        TimerDuration.min,
      );
    });
  });

  test('has value equality', () {
    expect(
      TimerDuration(const Duration(minutes: 5)),
      TimerDuration(const Duration(seconds: 300)),
    );
    expect(
      TimerDuration(const Duration(minutes: 5)).hashCode,
      TimerDuration(const Duration(seconds: 300)).hashCode,
    );
    expect(
      TimerDuration(const Duration(minutes: 5)),
      isNot(TimerDuration(const Duration(minutes: 6))),
    );
  });

  test('serializes as integer milliseconds', () {
    final duration = TimerDuration(const Duration(minutes: 5));

    expect(duration.toJson(), 300000);
    expect(TimerDuration.fromJson(300000), duration);
  });

  test('fromJson rejects invalid values', () {
    expect(() => TimerDuration.fromJson('300000'), throwsFormatException);
    expect(() => TimerDuration.fromJson(5000), throwsFormatException);
  });
}
