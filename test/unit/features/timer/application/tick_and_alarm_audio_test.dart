import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/domain/sound_id.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';
import 'package:visual_time_counter/features/timer/application/run_controller.dart';
import 'package:visual_time_counter/features/timer/application/timer_controller.dart';

import '../../../../helpers/test_app.dart';

const _sessionId = 'tick-and-alarm-1';
const _timerLength = Duration(minutes: 5);

/// The volumes and sound the adult chose reach the audio port (FR-052).
void main() {
  late TestAppDependencies dependencies;
  late ProviderContainer container;

  setUp(() async => dependencies = await TestAppDependencies.create());

  tearDown(() async {
    container.dispose();
    await dependencies.dispose();
  });

  /// Opens the countdown of a running timer with [config].
  Future<void> enterRun(TimerConfig config) async {
    final session = TimerSession(
      id: _sessionId,
      config: config,
      status: SessionStatus.running,
      startedAt: testNow,
      endsAt: testNow.add(_timerLength),
      scheduledNotificationIds: [alarmIdFor(_sessionId)],
    );
    await dependencies.sessionRepository.save(session);
    container =
        ProviderContainer(
            overrides: dependencies.overrides(
              session: session,
              settings: const AppSettings(childLockEnabled: false),
            ),
          )
          ..listen(timerControllerProvider, (_, _) {})
          ..listen(runControllerProvider, (_, _) {});
    await pumpEventQueue();
  }

  Future<void> reachTheEnd() async {
    dependencies.now = testNow.add(_timerLength);
    await container.read(timerControllerProvider.notifier).checkTimeUp();
  }

  List<String> audioCalls(String name) =>
      dependencies.audio.calls.where((call) => call.startsWith(name)).toList();

  group('ticking', () {
    test('uses the configured tick volume', () async {
      await enterRun(
        TimerConfig.defaults.copyWith(tickEnabled: true, tickVolume: 0.15),
      );

      expect(audioCalls('startTicking'), ['startTicking(0.15)']);
    });

    test('never starts while ticking is off', () async {
      await enterRun(
        TimerConfig.defaults.copyWith(tickEnabled: false, tickVolume: 0.9),
      );

      expect(audioCalls('startTicking'), isEmpty);
    });

    test('stops when the timer ends', () async {
      await enterRun(TimerConfig.defaults.copyWith(tickEnabled: true));

      await reachTheEnd();

      expect(dependencies.audio.isTicking, isFalse);
    });
  });

  group('alarm at the end', () {
    test('plays the chosen sound at the configured volume', () async {
      await enterRun(
        TimerConfig.defaults.copyWith(
          soundId: const SoundId('marimba'),
          alarmVolume: 0.4,
        ),
      );

      await reachTheEnd();

      expect(audioCalls('playAlarm'), ['playAlarm(marimba, 0.4, 1)']);
    });

    test('stays silent for "no sound"', () async {
      await enterRun(TimerConfig.defaults.copyWith(soundId: SoundId.none));

      await reachTheEnd();

      expect(audioCalls('playAlarm'), isEmpty);
    });
  });
}
