import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/platform/system_settings/method_channel_system_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('vtc/system_settings');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<String> calls;

  void answer(Object? Function(MethodCall call) handler) {
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return handler(call);
    });
  }

  setUp(() => calls = []);
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('on Android', () {
    const settings = MethodChannelSystemSettings(isAndroid: true);

    test('invokes the channel methods and returns their result', () async {
      answer((_) => true);

      expect(await settings.openExactAlarmSettings(), isTrue);
      expect(await settings.openAppNotificationSettings(), isTrue);
      expect(await settings.openBatteryOptimizationSettings(), isTrue);
      expect(calls, [
        'openExactAlarm',
        'openNotifications',
        'openBatteryOptimization',
      ]);
    });

    test('returns false when the screen could not be opened', () async {
      answer((_) => false);

      expect(await settings.openExactAlarmSettings(), isFalse);
    });

    test('returns false on a platform error instead of throwing', () async {
      answer((_) => throw PlatformException(code: 'no_activity'));

      expect(await settings.openBatteryOptimizationSettings(), isFalse);
    });

    test('returns false when the channel answers null', () async {
      answer((_) => null);

      expect(await settings.openAppNotificationSettings(), isFalse);
    });
  });

  test('is a no-op returning false on other platforms', () async {
    answer((_) => true);
    const settings = MethodChannelSystemSettings(isAndroid: false);

    expect(await settings.openExactAlarmSettings(), isFalse);
    expect(await settings.openAppNotificationSettings(), isFalse);
    expect(await settings.openBatteryOptimizationSettings(), isFalse);
    expect(calls, isEmpty);
  });
}
