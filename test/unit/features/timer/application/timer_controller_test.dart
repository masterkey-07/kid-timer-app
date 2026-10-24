import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:mocktail/mocktail.dart';
import 'package:visual_time_counter/core/clock/clock_provider.dart';
import 'package:visual_time_counter/core/domain/sound_id.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/domain/timer_duration.dart';
import 'package:visual_time_counter/core/platform/alarm/alarm_scheduler.dart';
import 'package:visual_time_counter/core/platform/providers.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/timer/application/active_session.dart';
import 'package:visual_time_counter/features/timer/application/timer_controller.dart';
import 'package:visual_time_counter/features/timer/data/session_repository.dart';

import '../../../../helpers/fakes/fake_alarm_scheduler.dart';
import '../../../../helpers/fakes/fake_audio.dart';
import '../../../../helpers/fakes/fake_haptics.dart';

final _t0 = DateTime.utc(2026, 10, 23, 12);

final _fiveMinutes = TimerConfig(
  duration: TimerDuration(const Duration(minutes: 5)),
);

class _MockBox extends Mock implements Box<Map<dynamic, dynamic>>;

class _StorageFull implements Exception {
  const new();
}

/// Records what was on disk each time the alarm port was called, to check
/// that the session is persisted before alarms are touched.
class _OrderCheckingScheduler extends FakeAlarmScheduler {
  new({required super.clock, super.capabilities});

  late SessionRepository repository;

  final List<TimerSession?> storedAtSchedule = [];
  final List<TimerSession?> storedAtCancel = [];

  @override
  Future<ScheduleResult> schedule(AlarmRequest request) {
    storedAtSchedule.add(repository.load());
    return super.schedule(request);
  }

  @override
  Future<void> cancel(int id) {
    storedAtCancel.add(repository.load());
    return super.cancel(id);
  }
}

var _boxCount = 0;

Future<Box<Map<dynamic, dynamic>>> _memoryBox() =>
    Hive.openBox<Map<dynamic, dynamic>>(
      'timer_controller_${_boxCount++}',
      bytes: Uint8List(0),
    );

class _Harness {
  new({
    required this.sessionBox,
    required Clock clock,
    this.restored,
    FakeHaptics? haptics,
    AlarmCapabilities? capabilities,
  }) : scheduler = capabilities == null
           ? _OrderCheckingScheduler(clock: clock)
           : _OrderCheckingScheduler(clock: clock, capabilities: capabilities),
       haptics = haptics ?? FakeHaptics() {
    repository = SessionRepository(sessionBox);
    scheduler.repository = repository;
    container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(clock),
        sessionRepositoryProvider.overrideWithValue(repository),
        alarmSchedulerProvider.overrideWithValue(scheduler),
        audioProvider.overrideWithValue(audio),
        hapticsProvider.overrideWithValue(this.haptics),
        restoredSessionProvider.overrideWithValue(restored),
        sessionIdGeneratorProvider.overrideWithValue(
          () => 'session-${_sessionCount++}',
        ),
      ],
    );
  }

  final Box<Map<dynamic, dynamic>> sessionBox;
  final TimerSession? restored;
  final _OrderCheckingScheduler scheduler;
  final FakeHaptics haptics;
  final audio = FakeAudio();
  late final SessionRepository repository;
  late final ProviderContainer container;
  var _sessionCount = 1;

  TimerController get controller =>
      container.read(timerControllerProvider.notifier);

  TimerSession? get session => container.read(timerControllerProvider);
}

void main() {
  late DateTime now;
  late Clock clock;
  late Box<Map<dynamic, dynamic>> sessionBox;
  final harnesses = <_Harness>[];

  _Harness harness({
    TimerSession? restored,
    FakeHaptics? haptics,
    AlarmCapabilities? capabilities,
    Box<Map<dynamic, dynamic>>? box,
    Clock? withClock,
  }) {
    final created = _Harness(
      sessionBox: box ?? sessionBox,
      clock: withClock ?? clock,
      restored: restored,
      haptics: haptics,
      capabilities: capabilities,
    );
    harnesses.add(created);
    return created;
  }

  setUp(() async {
    now = _t0;
    clock = Clock(() => now);
    sessionBox = await _memoryBox();
  });

  tearDown(() async {
    for (final created in harnesses) {
      created.container.dispose();
    }
    harnesses.clear();
    await sessionBox.close();
  });

  group('start', () {
    test('runs a session ending one duration from now', () async {
      final h = harness();

      final result = await h.controller.start(_fiveMinutes);

      expect(result, TimerActionResult.done);
      expect(h.session!.id, 'session-1');
      expect(h.session!.status, SessionStatus.running);
      expect(h.session!.endsAt, _t0.add(const Duration(minutes: 5)));
      expect(h.session!.origin, const ManualOrigin());
      expect(h.container.read(activeSessionProvider), h.session);
    });

    test('persists the session before scheduling the alarm', () async {
      final h = harness();

      await h.controller.start(_fiveMinutes);

      expect(h.scheduler.storedAtSchedule, [h.session]);
      expect(h.repository.load(), h.session);
    });

    test('schedules the end alarm at endsAt and records its id', () async {
      final h = harness();

      await h.controller.start(_fiveMinutes);

      final request = h.scheduler.scheduledRequests.single;
      expect(request.id, alarmIdFor('session-1'));
      expect(request.groupKey, 'session-1');
      expect(request.fireAtUtc, h.session!.endsAt);
      expect(request.kind, AlarmKind.end);
      expect(request.sound, SoundId.chimeSoft);
      expect(request.payload, 'vtc://run');
      expect(request.title, isNotEmpty);
      expect(h.session!.scheduledNotificationIds, [request.id]);
    });

    test('the notification names the timer (contracts/ui/08 §8.3)', () async {
      final h = harness();

      await h.controller.start(_fiveMinutes);

      final request = h.scheduler.scheduledRequests.single;
      expect(request.title, "Time's up!");
      expect(request.body, 'Timer: 5 minutes');
    });

    test('keeps the origin it is given', () async {
      final h = harness();

      await h.controller.start(_fiveMinutes, origin: const PresetOrigin('p1'));

      expect(h.session!.origin, const PresetOrigin('p1'));
    });

    test('still starts where the OS cannot schedule alarms', () async {
      final h = harness(capabilities: AlarmCapabilities.unsupported);

      final result = await h.controller.start(_fiveMinutes);

      expect(result, TimerActionResult.done);
      expect(h.session!.status, SessionStatus.running);
    });

    test(
      'a failure to persist neither starts nor schedules an alarm',
      () async {
        final failingBox = _MockBox();
        when(() => failingBox.get(any<Object?>())).thenReturn(null);
        when(() => failingBox.put(any<Object?>(), any()))
            .thenThrow(const _StorageFull());
        final h = harness(box: failingBox);

        final result = await h.controller.start(_fiveMinutes);

        expect(result, TimerActionResult.storageFailed);
        expect(h.session, isNull);
        expect(h.scheduler.scheduledRequests, isEmpty);
      },
    );

    group('with an active session (FR-007)', () {
      test('asks for confirmation and changes nothing', () async {
        final h = harness();
        await h.controller.start(_fiveMinutes);
        final first = h.session;

        final result = await h.controller.start(_fiveMinutes);

        expect(result, TimerActionResult.needsConfirmation);
        expect(h.session, first);
        expect(h.scheduler.scheduledRequests, hasLength(1));
      });

      test('replaces it once confirmed', () async {
        final h = harness();
        await h.controller.start(_fiveMinutes);

        final result = await h.controller.start(
          _fiveMinutes,
          replaceActive: true,
        );

        expect(result, TimerActionResult.done);
        expect(h.session!.id, 'session-2');
        expect(h.repository.load(), h.session);
        expect(h.scheduler.cancelledIds, [alarmIdFor('session-1')]);
        expect(h.scheduler.pending.keys, [alarmIdFor('session-2')]);
      });
    });
  });

  group('pause', () {
    test(
      'keeps the time left and cancels the alarm after persisting',
      () async {
        final h = harness();
        await h.controller.start(_fiveMinutes);
        now = _t0.add(const Duration(minutes: 2));

        final result = await h.controller.pause();

        expect(result, TimerActionResult.done);
        expect(h.session!.status, SessionStatus.paused);
        expect(h.session!.pausedRemaining, const Duration(minutes: 3));
        expect(h.scheduler.storedAtCancel, [h.session]);
        expect(h.scheduler.pending, isEmpty);
      },
    );
  });

  group('resume', () {
    test('ends after the time left and schedules after persisting', () async {
      final h = harness();
      await h.controller.start(_fiveMinutes);
      now = _t0.add(const Duration(minutes: 2));
      await h.controller.pause();
      now = _t0.add(const Duration(minutes: 10));

      final result = await h.controller.resume();

      expect(result, TimerActionResult.done);
      expect(h.session!.status, SessionStatus.running);
      expect(h.session!.endsAt, _t0.add(const Duration(minutes: 13)));
      expect(h.scheduler.storedAtSchedule.last, h.session);
      expect(
        h.scheduler.pending[alarmIdFor('session-1')]!.fireAtUtc,
        h.session!.endsAt,
      );
    });
  });

  group('restart', () {
    test(
      'runs the full duration again and reschedules the same alarm',
      () async {
        final h = harness();
        await h.controller.start(_fiveMinutes);
        now = _t0.add(const Duration(minutes: 4));

        final result = await h.controller.restart();

        expect(result, TimerActionResult.done);
        expect(h.session!.endsAt, _t0.add(const Duration(minutes: 9)));
        expect(h.scheduler.storedAtSchedule.last, h.session);
        expect(h.scheduler.pending.keys, [alarmIdFor('session-1')]);
        expect(
          h.scheduler.pending.values.single.fireAtUtc,
          _t0.add(const Duration(minutes: 9)),
        );
      },
    );
  });

  group('cancel', () {
    test('clears the session, then cancels the alarm', () async {
      final h = harness();
      await h.controller.start(_fiveMinutes);

      final result = await h.controller.cancel();

      expect(result, TimerActionResult.done);
      expect(h.session, isNull);
      expect(h.repository.load(), isNull);
      expect(h.scheduler.storedAtCancel, [null]);
      expect(h.scheduler.pending, isEmpty);
    });
  });

  group('end with the app open (FR-005)', () {
    void runEnd(
      void Function(FakeAsync async, _Harness h) body, {
      TimerConfig? config,
      FakeHaptics? haptics,
    }) {
      fakeAsync((async) {
        final h = harness(withClock: async.getClock(_t0), haptics: haptics);
        h.controller.start(config ?? _fiveMinutes).ignore();
        async.flushMicrotasks();
        body(async, h);
      });
    }

    test('goes to finished, plays the alarm once and vibrates', () {
      runEnd((async, h) {
        async
          ..elapse(const Duration(minutes: 5))
          ..flushMicrotasks();

        expect(h.session!.status, SessionStatus.finished);
        expect(h.repository.load()!.status, SessionStatus.finished);
        expect(h.audio.calls, ['stopTicking', 'playAlarm(chime_soft, 0.7, 1)']);
        expect(h.haptics.calls, ['alarmPattern']);

        async.elapse(const Duration(minutes: 5));

        expect(
          h.audio.calls.where((call) => call.startsWith('playAlarm')),
          hasLength(1),
        );
      });
    });

    test('does nothing before the end', () {
      runEnd((async, h) {
        async.elapse(const Duration(minutes: 4, seconds: 59));

        expect(h.session!.status, SessionStatus.running);
        expect(h.audio.calls, isEmpty);
      });
    });

    test('respects "no sound" and "no vibration"', () {
      runEnd((async, h) {
        async
          ..elapse(const Duration(minutes: 5))
          ..flushMicrotasks();

        expect(h.session!.status, SessionStatus.finished);
        expect(h.audio.calls, ['stopTicking']);
        expect(h.haptics.calls, isEmpty);
      }, config: _fiveMinutes.copyWith(soundId: SoundId.none, vibrate: false));
    });

    test('does not vibrate without a vibrator', () {
      runEnd((async, h) {
        async
          ..elapse(const Duration(minutes: 5))
          ..flushMicrotasks();

        expect(h.haptics.calls, isEmpty);
      }, haptics: FakeHaptics(hasVibrator: false));
    });

    test('a paused session never ends', () {
      runEnd((async, h) {
        h.controller.pause().ignore();
        async
          ..flushMicrotasks()
          ..elapse(const Duration(minutes: 10));

        expect(h.session!.status, SessionStatus.paused);
      });
    });

    test('a restored running session ends on time', () {
      fakeAsync((async) {
        final restored = TimerSession(
          id: 'restored',
          config: _fiveMinutes,
          status: SessionStatus.running,
          startedAt: _t0,
          endsAt: _t0.add(const Duration(minutes: 1)),
        );
        final h = harness(withClock: async.getClock(_t0), restored: restored);

        expect(h.session, restored);
        async
          ..elapse(const Duration(minutes: 1))
          ..flushMicrotasks();

        expect(h.session!.status, SessionStatus.finished);
      });
    });
  });

  group('acknowledge', () {
    test('clears the finished session and stops the sound', () async {
      final finished = TimerSession(
        id: 'done',
        config: _fiveMinutes,
        status: SessionStatus.finished,
        startedAt: _t0,
        endsAt: _t0,
      );
      final h = harness(restored: finished);
      await h.repository.save(finished);

      await h.controller.acknowledge();

      expect(h.session, isNull);
      expect(h.repository.load(), isNull);
      expect(h.audio.calls, ['stopAll']);
    });
  });

  group('alarmIdFor', () {
    test('is a stable non-negative 31-bit hash of the session id', () {
      expect(alarmIdFor('a'), 0x640c292c);
      expect(alarmIdFor('session-1'), alarmIdFor('session-1'));
      expect(alarmIdFor('session-1'), isNot(alarmIdFor('session-2')));
      expect(alarmIdFor('session-1'), inInclusiveRange(0, 0x7fffffff));
    });
  });
}
