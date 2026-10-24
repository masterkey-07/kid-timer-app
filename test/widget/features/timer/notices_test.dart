import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/platform/alarm/alarm_scheduler.dart';
import 'package:visual_time_counter/core/platform/providers.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';

import '../../../helpers/test_app.dart';

const _notificationsDenied = AlarmCapabilities(
  scheduling: SchedulingSupport.native,
  notifications: PermissionState.denied,
  exactAlarm: PermissionState.granted,
);

const _exactAlarmDenied = AlarmCapabilities(
  scheduling: SchedulingSupport.inexactOnly,
  notifications: PermissionState.granted,
  exactAlarm: PermissionState.denied,
);

const _iosGranted = AlarmCapabilities(
  scheduling: SchedulingSupport.native,
  notifications: PermissionState.granted,
  exactAlarm: PermissionState.notApplicable,
);

TimerSession _running() => TimerSession(
  id: 'notices-1',
  config: TimerConfig.defaults,
  status: SessionStatus.running,
  startedAt: testNow,
  endsAt: testNow.add(const Duration(minutes: 5)),
);

/// Start dialogs and the platform banner (contracts/ui/08).
void main() {
  late TestAppDependencies dependencies;

  setUp(() async => dependencies = await TestAppDependencies.create());
  tearDown(() => dependencies.dispose());

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> pumpHome(
    WidgetTester tester, {
    AppPlatform platform = AppPlatform.android,
    OnboardingFlags onboarding = OnboardingFlags.none,
  }) async {
    dependencies.platform = platform;
    await tester.pumpKidTimerApp(
      dependencies,
      settings: AppSettings(childLockEnabled: false, onboarding: onboarding),
    );
    await settle(tester);
  }

  Future<void> tap(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await settle(tester);
  }

  Finder byKey(String key) => find.byKey(Key(key));

  group('start dialogs', () {
    testWidgets('"Keep this window open" shows once, then the timer starts', (
      tester,
    ) async {
      dependencies.alarms.capabilitiesValue = AlarmCapabilities.unsupported;
      await pumpHome(tester, platform: AppPlatform.web);

      await tap(tester, 'home.start');
      expect(byKey('notice.keepOpen'), findsOneWidget);
      expect(byKey('run.screen'), findsNothing);

      await tap(tester, 'notice.keepOpen.ok');
      expect(byKey('notice.keepOpen'), findsNothing);
      expect(byKey('run.screen'), findsOneWidget);
      expect(
        dependencies.settingsRepository.load().onboarding.webKeepOpenSeen,
        isTrue,
      );
    });

    testWidgets('once seen, Web starts without the dialog', (tester) async {
      dependencies.alarms.capabilitiesValue = AlarmCapabilities.unsupported;
      await pumpHome(
        tester,
        platform: AppPlatform.web,
        onboarding: const OnboardingFlags(webKeepOpenSeen: true),
      );

      await tap(tester, 'home.start');

      expect(byKey('notice.keepOpen'), findsNothing);
      expect(byKey('run.screen'), findsOneWidget);
    });

    testWidgets('notifications denied: "Open settings" opens them and starts', (
      tester,
    ) async {
      dependencies.alarms.capabilitiesValue = _notificationsDenied;
      await pumpHome(tester);

      await tap(tester, 'home.start');
      expect(byKey('notice.notificationsDenied'), findsOneWidget);

      await tap(tester, 'notice.notificationsDenied.openSettings');
      expect(dependencies.systemSettings.opened, ['notifications']);
      expect(byKey('run.screen'), findsOneWidget);
    });

    testWidgets('notifications denied: "Continue anyway" starts', (
      tester,
    ) async {
      dependencies.alarms.capabilitiesValue = _notificationsDenied;
      await pumpHome(tester);

      await tap(tester, 'home.start');
      await tap(tester, 'notice.notificationsDenied.continue');

      expect(dependencies.systemSettings.opened, isEmpty);
      expect(byKey('run.screen'), findsOneWidget);
    });

    testWidgets('exact alarm: "Allow" opens the setting, starts on return', (
      tester,
    ) async {
      dependencies.alarms.capabilitiesValue = _exactAlarmDenied;
      await pumpHome(tester);

      await tap(tester, 'home.start');
      expect(byKey('notice.exactAlarm'), findsOneWidget);

      await tap(tester, 'notice.exactAlarm.allow');
      expect(dependencies.alarms.calls, ['openExactAlarmSettings']);
      expect(byKey('run.screen'), findsNothing);

      dependencies.lifecycle.emit(AppLifecycleState.resumed);
      await settle(tester);
      expect(byKey('run.screen'), findsOneWidget);
    });

    testWidgets('exact alarm: "Not now" starts with reduced accuracy', (
      tester,
    ) async {
      dependencies.alarms.capabilitiesValue = _exactAlarmDenied;
      await pumpHome(tester);

      await tap(tester, 'home.start');
      await tap(tester, 'notice.exactAlarm.notNow');

      expect(dependencies.alarms.calls, isEmpty);
      expect(byKey('run.screen'), findsOneWidget);
    });

    testWidgets('iOS: the silent mode warning shows on the first timer', (
      tester,
    ) async {
      dependencies.alarms.capabilitiesValue = _iosGranted;
      await pumpHome(tester, platform: AppPlatform.ios);

      await tap(tester, 'home.start');
      expect(byKey('notice.iosSilent'), findsOneWidget);

      await tap(tester, 'notice.iosSilent.ok');
      expect(byKey('run.screen'), findsOneWidget);
      expect(
        dependencies.settingsRepository.load().onboarding.iosSilentWarned,
        isTrue,
      );
    });

    testWidgets('volume at zero: a notice that does not block the start', (
      tester,
    ) async {
      dependencies.audio.systemVolumeValue = 0;
      await pumpHome(tester);

      await tap(tester, 'home.start');

      expect(byKey('notice.volumeZero'), findsOneWidget);
      expect(byKey('run.screen'), findsOneWidget);
    });
  });

  group('banner', () {
    testWidgets('home shows it when the alarm needs the app open', (
      tester,
    ) async {
      dependencies.alarms.capabilitiesValue = AlarmCapabilities.unsupported;
      await pumpHome(tester, platform: AppPlatform.web);

      expect(byKey('notice.banner'), findsOneWidget);
    });

    testWidgets('home shows it when the alarm may be late', (tester) async {
      dependencies.alarms.capabilitiesValue = _exactAlarmDenied;
      await pumpHome(tester);

      expect(byKey('notice.banner'), findsOneWidget);
    });

    testWidgets('home hides it when the OS alarm is reliable', (tester) async {
      await pumpHome(tester);

      expect(byKey('notice.banner'), findsNothing);
    });

    testWidgets('it updates when permissions change in the settings', (
      tester,
    ) async {
      dependencies.alarms.capabilitiesValue = _notificationsDenied;
      await pumpHome(tester);
      expect(byKey('notice.banner'), findsOneWidget);

      dependencies.alarms.capabilitiesValue = const AlarmCapabilities(
        scheduling: SchedulingSupport.native,
        notifications: PermissionState.granted,
        exactAlarm: PermissionState.granted,
      );
      dependencies.lifecycle.emit(AppLifecycleState.resumed);
      await settle(tester);

      expect(byKey('notice.banner'), findsNothing);
    });

    testWidgets('the countdown shows it with the controls visible', (
      tester,
    ) async {
      dependencies.alarms.capabilitiesValue = AlarmCapabilities.unsupported;
      dependencies.platform = AppPlatform.web;
      await tester.pumpKidTimerApp(
        dependencies,
        session: _running(),
        settings: const AppSettings(childLockEnabled: false),
      );
      await settle(tester);

      expect(byKey('run.screen'), findsOneWidget);
      expect(byKey('notice.banner'), findsOneWidget);
    });

    testWidgets('the countdown never shows it in child mode', (tester) async {
      dependencies.alarms.capabilitiesValue = AlarmCapabilities.unsupported;
      dependencies.platform = AppPlatform.web;
      // The child lock is on by default.
      await tester.pumpKidTimerApp(dependencies, session: _running());
      await settle(tester);

      expect(byKey('run.screen'), findsOneWidget);
      expect(byKey('notice.banner'), findsNothing);
    });
  });
}
