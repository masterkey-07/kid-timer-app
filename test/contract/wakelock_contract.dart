import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/platform/wakelock/wakelock_port.dart';

/// The WakeLockPort contract, shared by the fake and the real
/// implementation.
void runWakelockContract(
  String description,
  Future<WakeLockPort> Function() createPort,
) {
  group('$description WakeLockPort contract', () {
    late WakeLockPort port;

    setUp(() async => port = await createPort());
    tearDown(() => port.disable());

    test('enable keeps the screen on', () async {
      await port.enable();

      expect(await port.isEnabled, isTrue);
    });

    test('disable releases it', () async {
      await port.enable();
      await port.disable();

      expect(await port.isEnabled, isFalse);
    });

    test('enable and disable are idempotent', () async {
      await port.enable();
      await port.enable();
      expect(await port.isEnabled, isTrue);

      await port.disable();
      await port.disable();
      expect(await port.isEnabled, isFalse);
    });
  });
}
