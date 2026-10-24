import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/platform/alarm/alarm_scheduler.dart';
import 'package:visual_time_counter/core/platform/providers.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';
import 'package:visual_time_counter/features/timer/application/run_controller.dart';
import 'package:visual_time_counter/features/timer/application/timer_controller.dart';

import '../../../../helpers/test_app.dart';

const _sessionId = 'run-controller-1';

final _alarmId = alarmIdFor(_sessionId);

TimerSession _running({bool tickEnabled = false}) => TimerSession(
  id: _sessionId,
  config: TimerConfig.defaults.copyWith(tickEnabled: tickEnabled),
  status: SessionStatus.running,
  startedAt: testNow,
  endsAt: testNow.add(const Duration(minutes: 5)),
  scheduledNotificationIds: [_alarmId],
);

/// The side effects of the countdown screen (contracts/ui/02 Behavior 1,
/// 4, 5 and 6; FR-014).
void main() {
  late TestAppDependencies dependencies;
  late ProviderContainer container;
  late ProviderSubscription<RunController> screen;

  setUp(() async => dependencies = await TestAppDependencies.create());

  tearDown(() async {
    container.dispose();
    await dependencies.dispose();
  });

  /// Opens the countdown for [session] as the screen does. The alarm was
  /// scheduled when the timer started, before the screen opened.
  Future<void> enterRun({
    TimerSession? session,
    AppPlatform platform = AppPlatform.android,
    AppSettings settings = const AppSettings(childLockEnabled: false),
  }) async {
    final running = session ?? _running();
    dependencies.platform = platform;
    await dependencies.sessionRepository.save(running);
    if (running.endsAt case final endsAt?) {
      dependencies.alarms.pending[_alarmId] = _alarmRequest(endsAt);
    }
    container = ProviderContainer(
      overrides: dependencies.overrides(session: running, settings: settings),
    );
    container.listen(timerControllerProvider, (_, _) {});
    screen = container.listen(runControllerProvider, (_, _) {});
    await pumpEventQueue();
  }

  Future<void> leaveRun() async {
    screen.close();
    await pumpEventQueue();
  }

  Future<void> lifecycle(AppLifecycleState state) async {
    dependencies.lifecycle.emit(state);
    await pumpEventQueue();
  }

  TimerController timer() => container.read(timerControllerProvider.notifier);

  bool isAlarmPending() => dependencies.alarms.pending.containsKey(_alarmId);

  group('entering and leaving', () {
    test('keeps the screen on while the countdown is open', () async {
      await enterRun();
      expect(dependencies.wakeLock.enabled, isTrue);

      await timer().cancel();
      await leaveRun();
      expect(dependencies.wakeLock.enabled, isFalse);
    });

    test('enters full screen only with the child lock on (FR-030)', () async {
      await enterRun(settings: const AppSettings(childLockEnabled: true));
      expect(dependencies.fullscreen.isFullscreen, isTrue);

      await leaveRun();
      expect(dependencies.fullscreen.isFullscreen, isFalse);
    });

    test('stays windowed with the child lock off', () async {
      await enterRun();

      expect(dependencies.fullscreen.isFullscreen, isFalse);
    });

    test('preloads the alarm sound', () async {
      await enterRun();

      expect(dependencies.audio.calls, contains('preload(chime_soft)'));
    });

    test('ticks only when enabled and while running', () async {
      await enterRun(session: _running(tickEnabled: true));
      expect(dependencies.audio.isTicking, isTrue);

      await timer().pause();
      expect(dependencies.audio.isTicking, isFalse);

      await timer().resume();
      expect(dependencies.audio.isTicking, isTrue);

      await leaveRun();
      expect(dependencies.audio.isTicking, isFalse);
    });

    test('does not tick when ticking is off', () async {
      await enterRun();

      expect(dependencies.audio.isTicking, isFalse);
    });

    test(
      'leaving for the final screen keeps it in charge of the wakelock',
      () async {
        await enterRun();
        dependencies.now = testNow.add(const Duration(minutes: 6));
        await timer().checkTimeUp();
        // The final screen turned the wakelock on before /run closed.
        await dependencies.wakeLock.enable();

        await leaveRun();

        expect(dependencies.wakeLock.enabled, isTrue);
      },
    );
  });

  group('single ring on Android and Windows', () {
    for (final platform in [AppPlatform.android, AppPlatform.windows]) {
      test('${platform.name}: no OS alarm while the app is in front', () async {
        await enterRun(platform: platform);

        expect(isAlarmPending(), isFalse);
      });

      test(
        '${platform.name}: rescheduled when the app leaves the front',
        () async {
          await enterRun(platform: platform);
          final scheduledBefore = dependencies.alarms.scheduledRequests.length;

          await lifecycle(AppLifecycleState.inactive);
          await lifecycle(AppLifecycleState.hidden);
          await lifecycle(AppLifecycleState.paused);

          expect(isAlarmPending(), isTrue);
          expect(
            dependencies.alarms.scheduledRequests.length,
            scheduledBefore + 1,
            reason: 'scheduled once per trip to the background',
          );
          expect(
            dependencies.alarms.pending[_alarmId]!.fireAtUtc,
            _running().endsAt,
          );
        },
      );

      test('${platform.name}: cancelled again when the app returns', () async {
        await enterRun(platform: platform);
        await lifecycle(AppLifecycleState.paused);

        await lifecycle(AppLifecycleState.resumed);

        expect(isAlarmPending(), isFalse);
      });
    }

    test('resuming or restarting in front leaves no OS alarm behind', () async {
      await enterRun();

      await timer().pause();
      await timer().resume();
      await pumpEventQueue();
      expect(isAlarmPending(), isFalse);

      dependencies.now = testNow.add(const Duration(seconds: 20));
      await timer().restart();
      await pumpEventQueue();
      expect(isAlarmPending(), isFalse);
    });

    test('a paused timer is not rescheduled in the background', () async {
      await enterRun();
      await timer().pause();

      await lifecycle(AppLifecycleState.paused);

      expect(isAlarmPending(), isFalse);
    });

    test('nothing is rescheduled after leaving the countdown', () async {
      await enterRun();
      await timer().cancel();
      await leaveRun();

      await lifecycle(AppLifecycleState.paused);

      expect(isAlarmPending(), isFalse);
    });
  });

  group('iOS and macOS', () {
    for (final platform in [AppPlatform.ios, AppPlatform.macos]) {
      test(
        '${platform.name}: the OS alarm stays scheduled throughout',
        () async {
          await enterRun(platform: platform);
          await lifecycle(AppLifecycleState.paused);
          await lifecycle(AppLifecycleState.resumed);

          expect(isAlarmPending(), isTrue);
          expect(dependencies.alarms.cancelledIds, isEmpty);
        },
      );
    }
  });

  group('Web and Linux', () {
    for (final platform in [AppPlatform.web, AppPlatform.linux]) {
      test('${platform.name}: the app sound is the only alarm', () async {
        await enterRun(platform: platform);
        dependencies.alarms.pending.clear();
        final scheduledBefore = dependencies.alarms.scheduledRequests.length;

        await lifecycle(AppLifecycleState.paused);
        await lifecycle(AppLifecycleState.resumed);

        expect(dependencies.alarms.scheduledRequests.length, scheduledBefore);
        expect(dependencies.alarms.cancelledIds, isEmpty);
      });
    }
  });
}

/// What [TimerController] scheduled for the test session when it started.
AlarmRequest _alarmRequest(DateTime endsAt) => AlarmRequest(
  id: _alarmId,
  groupKey: _sessionId,
  fireAtUtc: endsAt,
  kind: AlarmKind.end,
  title: "Time's up!",
  body: 'Tap to open Kid Timer.',
  sound: TimerConfig.defaults.soundId,
  payload: timerNotificationPayload,
);
