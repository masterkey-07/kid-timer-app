import 'dart:ui';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/persistence/hive_bootstrap.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/timer/application/timer_controller.dart';
import 'package:visual_time_counter/features/timer/data/session_repository.dart';
import 'package:visual_time_counter/startup_state.dart';

import '../../../../helpers/hive_test_utils.dart';
import '../../../../helpers/test_app.dart';

TimerSession _running({required DateTime endsAt}) => TimerSession(
  id: 'reconcile-1',
  config: TimerConfig.defaults,
  status: SessionStatus.running,
  startedAt: endsAt.subtract(const Duration(minutes: 5)),
  endsAt: endsAt,
);

/// Reconciling with the real clock on resume and at startup (FR-010,
/// FR-013; US2 acceptance 2 and 3).
void main() {
  group('on resume', () {
    late TestAppDependencies dependencies;
    late ProviderContainer container;

    setUp(() async => dependencies = await TestAppDependencies.create());

    tearDown(() async {
      container.dispose();
      await dependencies.dispose();
    });

    /// Restores [session] the way bootstrap does and keeps the controller
    /// alive, as the running app would.
    Future<void> restore(TimerSession session) async {
      await dependencies.sessionRepository.save(session);
      container = ProviderContainer(
        overrides: dependencies.overrides(session: session),
      )..listen(timerControllerProvider, (_, _) {});
    }

    TimerSession? current() => container.read(timerControllerProvider);

    Future<void> resume() async {
      dependencies.lifecycle.emit(AppLifecycleState.resumed);
      await pumpEventQueue();
    }

    int alarmsPlayed() => dependencies.audio.calls
        .where((call) => call.startsWith('playAlarm'))
        .length;

    test(
      'before the end it keeps running with the real remaining time',
      () async {
        await restore(
          _running(endsAt: testNow.add(const Duration(minutes: 5))),
        );
        dependencies.now = testNow.add(const Duration(minutes: 2, seconds: 30));

        await resume();

        expect(current()!.status, SessionStatus.running);
        expect(
          current()!.remaining(dependencies.now),
          const Duration(minutes: 2, seconds: 30),
        );
        expect(alarmsPlayed(), 0);
      },
    );

    test('after the end it finishes, saves and rings once', () async {
      await restore(_running(endsAt: testNow.add(const Duration(minutes: 5))));
      dependencies.now = testNow.add(const Duration(minutes: 7));

      await resume();

      expect(current()!.status, SessionStatus.finished);
      expect(
        dependencies.sessionRepository.load()!.status,
        SessionStatus.finished,
      );
      expect(alarmsPlayed(), 1);
    });

    test('resuming again does not ring a second time', () async {
      await restore(_running(endsAt: testNow.add(const Duration(minutes: 5))));
      dependencies.now = testNow.add(const Duration(minutes: 7));

      await resume();
      await resume();

      expect(alarmsPlayed(), 1);
    });

    test('a paused session stays paused with its remaining time', () async {
      final paused = TimerSession(
        id: 'reconcile-paused',
        config: TimerConfig.defaults,
        status: SessionStatus.paused,
        startedAt: testNow,
        pausedRemaining: const Duration(minutes: 3),
      );
      await restore(paused);
      dependencies.now = testNow.add(const Duration(hours: 2));

      await resume();

      expect(current(), paused);
    });
  });

  group('at startup', () {
    useTemporaryHive();

    final start = DateTime.utc(2026, 10, 23, 8);

    Future<StartupState> launchAt(DateTime now) async => await loadStartupState(
      boxes: await openPersistence(clock: Clock.fixed(now)),
      clock: Clock.fixed(now),
    );

    Future<void> saveRunning(DateTime endsAt) async {
      final boxes = await openPersistence(clock: Clock.fixed(start));
      await SessionRepository(boxes.session).save(_running(endsAt: endsAt));
    }

    test(
      'reopened before the end it continues from the real remaining time',
      () async {
        await saveRunning(start.add(const Duration(minutes: 5)));

        final state = await launchAt(start.add(const Duration(minutes: 4)));

        expect(state.session!.status, SessionStatus.running);
        expect(
          state.session!.remaining(start.add(const Duration(minutes: 4))),
          const Duration(minutes: 1),
        );
      },
    );

    test(
      'reopened hours later it shows the final screen exactly once',
      () async {
        await saveRunning(start.add(const Duration(minutes: 5)));
        final hoursLater = start.add(const Duration(hours: 6));

        final first = await launchAt(hoursLater);
        expect(first.session!.status, SessionStatus.finished);
        expect(first.session!.finishedAcknowledged, isFalse);

        // The adult taps the final screen, which clears the session.
        final boxes = await openPersistence(clock: Clock.fixed(hoursLater));
        await SessionRepository(boxes.session).clear();

        final second = await launchAt(hoursLater.add(const Duration(hours: 1)));
        expect(second.session, isNull);
      },
    );
  });
}
