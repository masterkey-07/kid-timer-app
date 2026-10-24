import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/platform/alarm/alarm_scheduler.dart';
import 'package:visual_time_counter/core/platform/providers.dart';
import 'package:visual_time_counter/features/settings/application/app_settings_state.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';
import 'package:visual_time_counter/features/timer/application/background_alarm_notice.dart';
import 'package:visual_time_counter/features/timer/application/start_preflight.dart';

import '../../../../helpers/test_app.dart';

/// Records the prompts in the order shown and answers with the configured
/// choices.
class _RecordingPrompts implements PreflightPrompts {
  new({
    this.notificationsChoice = NotificationsDeniedChoice.continueAnyway,
    this.exactAlarmChoice = ExactAlarmChoice.notNow,
  });

  final NotificationsDeniedChoice notificationsChoice;
  final ExactAlarmChoice exactAlarmChoice;
  final List<String> shown = [];

  @override
  Future<void> showKeepOpen() async => shown.add('keepOpen');

  @override
  Future<NotificationsDeniedChoice> showNotificationsDenied() async {
    shown.add('notificationsDenied');
    return notificationsChoice;
  }

  @override
  Future<ExactAlarmChoice> showExactAlarm() async {
    shown.add('exactAlarm');
    return exactAlarmChoice;
  }

  @override
  Future<void> showIosSilent() async => shown.add('iosSilent');

  @override
  void showVolumeZero() => shown.add('volumeZero');
}

const _allGranted = AlarmCapabilities(
  scheduling: SchedulingSupport.native,
  notifications: PermissionState.granted,
  exactAlarm: PermissionState.granted,
);

const _iosGranted = AlarmCapabilities(
  scheduling: SchedulingSupport.native,
  notifications: PermissionState.granted,
  exactAlarm: PermissionState.notApplicable,
);

void main() {
  late TestAppDependencies dependencies;
  final containers = <ProviderContainer>[];

  setUp(() async {
    dependencies = await TestAppDependencies.create();
    dependencies.alarms.capabilitiesValue = _allGranted;
  });

  tearDown(() async {
    for (final container in containers) {
      container.dispose();
    }
    containers.clear();
    await dependencies.dispose();
  });

  StartPreflight preflight({
    AppPlatform platform = AppPlatform.android,
    OnboardingFlags onboarding = OnboardingFlags.none,
  }) {
    dependencies.platform = platform;
    final container = ProviderContainer(
      overrides: dependencies.overrides(
        settings: AppSettings(onboarding: onboarding),
      ),
    );
    containers.add(container);
    return container.read(startPreflightProvider);
  }

  OnboardingFlags savedFlags() =>
      dependencies.settingsRepository.load().onboarding;

  OnboardingFlags currentFlags() =>
      containers.last.read(appSettingsProvider).onboarding;

  test('with everything granted it shows nothing and asks nothing', () async {
    final prompts = _RecordingPrompts();

    await preflight().run(prompts);

    expect(prompts.shown, isEmpty);
    expect(dependencies.alarms.calls, isEmpty);
  });

  group('scheduling unsupported (Web, Linux)', () {
    setUp(
      () =>
          dependencies.alarms.capabilitiesValue = AlarmCapabilities.unsupported,
    );

    test(
      'the first start shows "Keep this window open" and saves the flag',
      () async {
        final prompts = _RecordingPrompts();

        await preflight(platform: AppPlatform.web).run(prompts);

        expect(prompts.shown, ['keepOpen']);
        expect(currentFlags().webKeepOpenSeen, isTrue);
        expect(savedFlags().webKeepOpenSeen, isTrue);
      },
    );

    test('later starts show no dialog (only the banner)', () async {
      final prompts = _RecordingPrompts();

      await preflight(
        platform: AppPlatform.linux,
        onboarding: const OnboardingFlags(webKeepOpenSeen: true),
      ).run(prompts);

      expect(prompts.shown, isEmpty);
    });
  });

  group('notification permission', () {
    test('not determined: asks the OS and continues when granted', () async {
      dependencies.alarms
        ..capabilitiesValue = const AlarmCapabilities(
          scheduling: SchedulingSupport.native,
          notifications: PermissionState.notDetermined,
          exactAlarm: PermissionState.granted,
        )
        ..permissionAfterRequest = PermissionState.granted;
      final prompts = _RecordingPrompts();

      await preflight().run(prompts);

      expect(dependencies.alarms.calls, ['requestNotificationPermission']);
      expect(prompts.shown, isEmpty);
    });

    test('not determined and then refused: explains the consequence', () async {
      dependencies.alarms
        ..capabilitiesValue = const AlarmCapabilities(
          scheduling: SchedulingSupport.native,
          notifications: PermissionState.notDetermined,
          exactAlarm: PermissionState.granted,
        )
        ..permissionAfterRequest = PermissionState.denied;
      final prompts = _RecordingPrompts();

      await preflight().run(prompts);

      expect(prompts.shown, ['notificationsDenied']);
    });

    test('denied: shows the dialog without asking the OS again', () async {
      dependencies.alarms.capabilitiesValue = const AlarmCapabilities(
        scheduling: SchedulingSupport.native,
        notifications: PermissionState.denied,
        exactAlarm: PermissionState.granted,
      );
      final prompts = _RecordingPrompts();

      await preflight().run(prompts);

      expect(prompts.shown, ['notificationsDenied']);
      expect(dependencies.alarms.calls, isEmpty);
      expect(dependencies.systemSettings.opened, isEmpty);
    });

    test(
      'denied: "Open settings" opens the app notification settings',
      () async {
        dependencies.alarms.capabilitiesValue = const AlarmCapabilities(
          scheduling: SchedulingSupport.native,
          notifications: PermissionState.denied,
          exactAlarm: PermissionState.granted,
        );

        await preflight().run(
          _RecordingPrompts(
            notificationsChoice: NotificationsDeniedChoice.openSettings,
          ),
        );

        expect(dependencies.systemSettings.opened, ['notifications']);
      },
    );

    test('denied: warns on every start, since nothing makes it safe', () async {
      dependencies.alarms.capabilitiesValue = const AlarmCapabilities(
        scheduling: SchedulingSupport.native,
        notifications: PermissionState.denied,
        exactAlarm: PermissionState.granted,
      );
      final checker = preflight();
      final first = _RecordingPrompts();
      final second = _RecordingPrompts();

      await checker.run(first);
      await checker.run(second);

      expect(first.shown, ['notificationsDenied']);
      expect(second.shown, ['notificationsDenied']);
    });
  });

  group('exact alarm (Android 12–13)', () {
    const exactDenied = AlarmCapabilities(
      scheduling: SchedulingSupport.inexactOnly,
      notifications: PermissionState.granted,
      exactAlarm: PermissionState.denied,
    );

    setUp(() => dependencies.alarms.capabilitiesValue = exactDenied);

    test('the first time explains it and saves the flag', () async {
      final prompts = _RecordingPrompts();

      await preflight().run(prompts);

      expect(prompts.shown, ['exactAlarm']);
      expect(savedFlags().exactAlarmExplained, isTrue);
      expect(dependencies.alarms.calls, isEmpty);
    });

    test(
      '"Allow" opens the setting and re-checks when the app returns',
      () async {
        final checker = preflight();
        final container = containers.last
          ..listen(backgroundAlarmNoticeProvider, (_, _) {});
        expect(
          await container.read(backgroundAlarmNoticeProvider.future),
          BackgroundAlarmNotice.reducedAccuracy,
        );
        var isDone = false;

        final run = checker
            .run(_RecordingPrompts(exactAlarmChoice: ExactAlarmChoice.allow))
            .then((_) => isDone = true);
        await pumpEventQueue();

        expect(dependencies.alarms.calls, ['openExactAlarmSettings']);
        expect(isDone, isFalse, reason: 'waits for the adult to come back');

        dependencies.alarms.capabilitiesValue = _allGranted;
        dependencies.lifecycle.emit(AppLifecycleState.resumed);
        await run;

        expect(isDone, isTrue);
        expect(
          await container.read(backgroundAlarmNoticeProvider.future),
          isNull,
          reason: 'the banner re-checks the capabilities',
        );
      },
    );

    test('already explained: no dialog, reduced accuracy only', () async {
      final prompts = _RecordingPrompts();

      await preflight(
        onboarding: const OnboardingFlags(exactAlarmExplained: true),
      ).run(prompts);

      expect(prompts.shown, isEmpty);
    });
  });

  group('iOS silent mode', () {
    setUp(() => dependencies.alarms.capabilitiesValue = _iosGranted);

    test('the first timer on iOS warns once and saves the flag', () async {
      final prompts = _RecordingPrompts();

      await preflight(platform: AppPlatform.ios).run(prompts);

      expect(prompts.shown, ['iosSilent']);
      expect(savedFlags().iosSilentWarned, isTrue);
    });

    test('later timers do not warn again', () async {
      final prompts = _RecordingPrompts();

      await preflight(
        platform: AppPlatform.ios,
        onboarding: const OnboardingFlags(iosSilentWarned: true),
      ).run(prompts);

      expect(prompts.shown, isEmpty);
    });

    test(
      'an alarm that bypasses silent mode (AlarmKit) needs no warning',
      () async {
        dependencies.alarms.capabilitiesValue = const AlarmCapabilities(
          scheduling: SchedulingSupport.native,
          notifications: PermissionState.granted,
          exactAlarm: PermissionState.notApplicable,
          bypassesSilentMode: true,
        );
        final prompts = _RecordingPrompts();

        await preflight(platform: AppPlatform.ios).run(prompts);

        expect(prompts.shown, isEmpty);
      },
    );

    test('other platforms never show it', () async {
      final prompts = _RecordingPrompts();

      await preflight(platform: AppPlatform.macos).run(prompts);

      expect(prompts.shown, isEmpty);
    });
  });

  group('system volume', () {
    test('zero shows the non-blocking volume notice', () async {
      dependencies.audio.systemVolumeValue = 0;
      final prompts = _RecordingPrompts();

      await preflight().run(prompts);

      expect(prompts.shown, ['volumeZero']);
    });

    test('above zero or unknown (desktop, Web) shows nothing', () async {
      for (final volume in [0.4, null]) {
        dependencies.audio.systemVolumeValue = volume;
        final prompts = _RecordingPrompts();

        await preflight().run(prompts);

        expect(prompts.shown, isEmpty, reason: 'volume $volume');
      }
    });
  });

  test('prompts follow the contract order', () async {
    dependencies.alarms
      ..capabilitiesValue = const AlarmCapabilities(
        scheduling: SchedulingSupport.inexactOnly,
        notifications: PermissionState.notDetermined,
        exactAlarm: PermissionState.denied,
      )
      ..permissionAfterRequest = PermissionState.denied;
    dependencies.audio.systemVolumeValue = 0;
    final prompts = _RecordingPrompts();

    await preflight().run(prompts);

    expect(prompts.shown, ['notificationsDenied', 'exactAlarm', 'volumeZero']);
  });

  test(
    'every capability combination gets the dialogs the tree expects',
    () async {
      for (final scheduling in SchedulingSupport.values) {
        for (final notifications in PermissionState.values) {
          for (final exactAlarm in PermissionState.values) {
            dependencies.alarms
              ..capabilitiesValue = AlarmCapabilities(
                scheduling: scheduling,
                notifications: notifications,
                exactAlarm: exactAlarm,
              )
              ..permissionAfterRequest = PermissionState.denied
              ..calls.clear();
            final prompts = _RecordingPrompts();

            await preflight().run(prompts);

            final asksOs = notifications == PermissionState.notDetermined;
            expect(prompts.shown, [
              if (scheduling == SchedulingSupport.unsupported) 'keepOpen',
              if (notifications == PermissionState.denied || asksOs)
                'notificationsDenied',
              if (exactAlarm == PermissionState.denied) 'exactAlarm',
            ], reason: '$scheduling / $notifications / $exactAlarm');
            expect(dependencies.alarms.calls, [
              if (asksOs) 'requestNotificationPermission',
            ]);
          }
        }
      }
    },
  );

  test('a flag that cannot be saved never blocks the start', () async {
    dependencies.alarms.capabilitiesValue = AlarmCapabilities.unsupported;
    final checker = preflight(platform: AppPlatform.web);
    await dependencies.breakSettingsStorage();
    final prompts = _RecordingPrompts();

    await checker.run(prompts);

    expect(prompts.shown, ['keepOpen']);
    expect(currentFlags().webKeepOpenSeen, isTrue);
  });
}
