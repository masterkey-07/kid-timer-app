import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/clock/clock_provider.dart';

void main() {
  test('provides the system clock by default', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final now = container.read(clockProvider).now();

    expect(
      now.difference(DateTime.now()).abs(),
      lessThan(const Duration(seconds: 5)),
    );
  });

  test('can be overridden with a fixed clock in tests', () {
    final fixed = DateTime.utc(2026, 10, 23, 12);
    final container = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(Clock.fixed(fixed))],
    );
    addTearDown(container.dispose);

    expect(container.read(clockProvider).now(), fixed);
  });
}
