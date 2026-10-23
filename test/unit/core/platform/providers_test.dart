import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/platform/providers.dart';

void main() {
  group('choosePorts', () {
    test('Android: OS alarms, immersive mode, vibrator, settings channel', () {
      expect(
        choosePorts(AppPlatform.android),
        const PortChoice(
          alarm: AlarmChoice.localNotifications,
          fullscreen: FullscreenChoice.systemChrome,
          hasVibrator: true,
          hasSystemSettings: true,
        ),
      );
    });

    test('iOS: OS alarms, system chrome, vibrator', () {
      expect(
        choosePorts(AppPlatform.ios),
        const PortChoice(
          alarm: AlarmChoice.localNotifications,
          fullscreen: FullscreenChoice.systemChrome,
          hasVibrator: true,
          hasSystemSettings: false,
        ),
      );
    });

    test('macOS: OS alarms, window manager, no vibrator', () {
      expect(
        choosePorts(AppPlatform.macos),
        const PortChoice(
          alarm: AlarmChoice.localNotifications,
          fullscreen: FullscreenChoice.windowManager,
          hasVibrator: false,
          hasSystemSettings: false,
        ),
      );
    });

    test('Windows: foreground-only alarm until spike T042 passes', () {
      expect(
        choosePorts(AppPlatform.windows).alarm,
        AlarmChoice.foregroundOnly,
      );
      expect(
        choosePorts(AppPlatform.windows).fullscreen,
        FullscreenChoice.windowManager,
      );
    });

    test('Linux: foreground-only alarm, window manager', () {
      expect(choosePorts(AppPlatform.linux).alarm, AlarmChoice.foregroundOnly);
      expect(
        choosePorts(AppPlatform.linux).fullscreen,
        FullscreenChoice.windowManager,
      );
    });

    test('Web: foreground-only alarm, browser fullscreen', () {
      expect(
        choosePorts(AppPlatform.web),
        const PortChoice(
          alarm: AlarmChoice.foregroundOnly,
          fullscreen: FullscreenChoice.web,
          hasVibrator: false,
          hasSystemSettings: false,
        ),
      );
    });
  });

  group('AppPlatform.resolve', () {
    test('Web wins over the target platform', () {
      expect(
        AppPlatform.resolve(isWeb: true, target: TargetPlatform.android),
        AppPlatform.web,
      );
    });

    for (final (target, platform) in [
      (TargetPlatform.android, AppPlatform.android),
      (TargetPlatform.iOS, AppPlatform.ios),
      (TargetPlatform.macOS, AppPlatform.macos),
      (TargetPlatform.windows, AppPlatform.windows),
      (TargetPlatform.linux, AppPlatform.linux),
      (TargetPlatform.fuchsia, AppPlatform.linux),
    ]) {
      test('$target → $platform', () {
        expect(AppPlatform.resolve(isWeb: false, target: target), platform);
      });
    }
  });

  test('the platform provider reflects the current platform', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(appPlatformProvider), AppPlatform.ios);
  });

  group('port providers must be overridden', () {
    final providers = <String, ProviderListenable<Object?>>{
      'alarmScheduler': alarmSchedulerProvider,
      'wakeLock': wakeLockProvider,
      'fullscreen': fullscreenProvider,
      'audio': audioProvider,
      'haptics': hapticsProvider,
      'imagePicker': imagePickerProvider,
      'systemSettings': systemSettingsProvider,
      'externalLink': externalLinkProvider,
      'appLifecycle': appLifecycleProvider,
    };

    for (final MapEntry(key: name, value: provider) in providers.entries) {
      test(name, () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(
          () => container.read(provider),
          throwsA(
            predicate(
              (error) => error.toString().contains('must be overridden'),
            ),
          ),
        );
      });
    }
  });
}
