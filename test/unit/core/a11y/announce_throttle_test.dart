import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/a11y/announce_throttle.dart';

void main() {
  late DateTime now;
  final clock = Clock(() => now);

  setUp(() => now = DateTime.utc(2026, 10, 23, 12));

  void advance(Duration duration) => now = now.add(duration);

  test('the first announcement is allowed', () {
    final throttle = AnnounceThrottle(
      interval: AnnounceInterval.oneMin,
      clock: clock,
    );

    expect(throttle.tryAnnounce(), isTrue);
  });

  for (final (interval, period) in [
    (AnnounceInterval.oneMin, const Duration(minutes: 1)),
    (AnnounceInterval.fiveMin, const Duration(minutes: 5)),
  ]) {
    test('allows at most one announcement per ${interval.name}', () {
      final throttle = AnnounceThrottle(interval: interval, clock: clock)
        ..tryAnnounce();

      advance(period - const Duration(seconds: 1));
      expect(throttle.tryAnnounce(), isFalse);

      advance(const Duration(seconds: 1));
      expect(throttle.tryAnnounce(), isTrue);
      expect(throttle.tryAnnounce(), isFalse);
    });
  }

  test('a rejected attempt does not restart the interval', () {
    final throttle = AnnounceThrottle(
      interval: AnnounceInterval.oneMin,
      clock: clock,
    )..tryAnnounce();

    advance(const Duration(seconds: 30));
    throttle.tryAnnounce();
    advance(const Duration(seconds: 30));

    expect(throttle.tryAnnounce(), isTrue);
  });

  test('off never announces', () {
    final throttle = AnnounceThrottle(
      interval: AnnounceInterval.off,
      clock: clock,
    );

    expect(throttle.tryAnnounce(), isFalse);
    advance(const Duration(hours: 1));
    expect(throttle.tryAnnounce(), isFalse);
  });

  test('reset allows the next announcement immediately', () {
    final throttle =
        AnnounceThrottle(interval: AnnounceInterval.fiveMin, clock: clock)
          ..tryAnnounce()
          ..reset();

    expect(throttle.tryAnnounce(), isTrue);
  });

  test('intervals serialize by name (settings a11yAnnounceInterval)', () {
    expect(AnnounceInterval.fiveMin.toJson(), 'fiveMin');
    expect(AnnounceInterval.fromJson('off'), AnnounceInterval.off);
    expect(() => AnnounceInterval.fromJson('tenMin'), throwsFormatException);
    expect(AnnounceInterval.oneMin.period, const Duration(minutes: 1));
    expect(AnnounceInterval.off.period, isNull);
  });
}
