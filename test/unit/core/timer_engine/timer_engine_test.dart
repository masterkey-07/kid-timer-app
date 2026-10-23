import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/domain/timer_duration.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/core/timer_engine/timer_engine.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';

void main() {
  final startInstant = DateTime.utc(2026, 10, 23, 12);
  late DateTime now;
  late TimerEngine engine;

  void advance(Duration duration) => now = now.add(duration);

  final fiveMinutes = TimerConfig.defaults.copyWith(
    duration: TimerDuration(const Duration(minutes: 5)),
  );

  TimerSession readySession() =>
      engine.create(id: 'session-1', config: fiveMinutes);

  setUp(() {
    now = startInstant;
    engine = TimerEngine(clock: Clock(() => now));
  });

  group('create', () {
    test('returns a ready session with the full duration remaining', () {
      final session = readySession();

      expect(session.status, SessionStatus.ready);
      expect(session.origin, const ManualOrigin());
      expect(session.startedAt, isNull);
      expect(session.endsAt, isNull);
      expect(session.remaining(now), const Duration(minutes: 5));
      expect(session.progress(now), 1);
    });
  });

  group('start', () {
    test('sets startedAt = now and endsAt = now + duration', () {
      final session = engine.start(readySession());

      expect(session.status, SessionStatus.running);
      expect(session.startedAt, startInstant);
      expect(session.endsAt, startInstant.add(const Duration(minutes: 5)));
      expect(session.finishedAcknowledged, isFalse);
    });

    test('remaining is endsAt − now', () {
      final session = engine.start(readySession());
      advance(const Duration(minutes: 1, seconds: 30));

      expect(
        engine.remaining(session),
        const Duration(minutes: 3, seconds: 30),
      );
      expect(engine.progress(session), closeTo(0.7, 1e-9));
    });

    test('remaining never goes below zero', () {
      final session = engine.start(readySession());
      advance(const Duration(minutes: 9));

      expect(engine.remaining(session), Duration.zero);
      expect(engine.progress(session), 0);
      expect(engine.isOverdue(session), isTrue);
    });
  });

  group('pause and resume', () {
    test('pause stores the remaining time and clears endsAt', () {
      final running = engine.start(readySession());
      advance(const Duration(minutes: 1));

      final paused = engine.pause(running);

      expect(paused.status, SessionStatus.paused);
      expect(paused.pausedRemaining, const Duration(minutes: 4));
      expect(paused.endsAt, isNull);
    });

    test('a 20 s pause preserves the remaining time', () {
      final running = engine.start(readySession());
      advance(const Duration(minutes: 1));
      final paused = engine.pause(running);

      advance(const Duration(seconds: 20));
      expect(engine.remaining(paused), const Duration(minutes: 4));

      final resumed = engine.resume(paused);
      expect(resumed.status, SessionStatus.running);
      expect(resumed.pausedRemaining, isNull);
      expect(resumed.endsAt, now.add(const Duration(minutes: 4)));
      expect(engine.remaining(resumed), const Duration(minutes: 4));
    });

    test('pausing after the end stores zero remaining', () {
      final running = engine.start(readySession());
      advance(const Duration(minutes: 6));

      expect(engine.pause(running).pausedRemaining, Duration.zero);
    });
  });

  group('cancel', () {
    test('cancels a running session', () {
      final cancelled = engine.cancel(engine.start(readySession()));

      expect(cancelled.status, SessionStatus.cancelled);
      expect(engine.remaining(cancelled), Duration.zero);
    });

    test('cancels a paused session', () {
      final paused = engine.pause(engine.start(readySession()));

      expect(engine.cancel(paused).status, SessionStatus.cancelled);
    });
  });

  group('restart', () {
    for (final (description, prepare) in <(String, TimerSession Function())>[
      ('running', () => engine.start(readySession())),
      ('paused', () => engine.pause(engine.start(readySession()))),
      (
        'finished',
        () {
          final running = engine.start(readySession());
          advance(const Duration(minutes: 5));
          return engine.reconcile(running);
        },
      ),
    ]) {
      test('starts a $description session again with the same config', () {
        final previous = prepare();
        advance(const Duration(seconds: 10));

        final restarted = engine.restart(previous);

        expect(restarted.status, SessionStatus.running);
        expect(restarted.id, previous.id);
        expect(restarted.config, previous.config);
        expect(restarted.startedAt, now);
        expect(restarted.endsAt, now.add(const Duration(minutes: 5)));
        expect(restarted.pausedRemaining, isNull);
        expect(restarted.finishedAcknowledged, isFalse);
      });
    }
  });

  group('reconcile', () {
    test('finishes a running session when now ≥ endsAt', () {
      final running = engine.start(readySession());
      advance(const Duration(minutes: 5));

      final reconciled = engine.reconcile(running);

      expect(reconciled.status, SessionStatus.finished);
      expect(reconciled.finishedAcknowledged, isFalse);
      expect(engine.remaining(reconciled), Duration.zero);
    });

    test('keeps a running session before the end', () {
      final running = engine.start(readySession());
      advance(const Duration(minutes: 4, seconds: 59));

      expect(engine.reconcile(running), running);
    });

    test('leaves the other states unchanged', () {
      final ready = readySession();
      final paused = engine.pause(engine.start(readySession()));
      advance(const Duration(hours: 3));

      expect(engine.reconcile(ready), ready);
      expect(engine.reconcile(paused), paused);
    });
  });

  group('acknowledge', () {
    test('marks a finished session as acknowledged', () {
      final running = engine.start(readySession());
      advance(const Duration(minutes: 5));

      final acknowledged = engine.acknowledge(engine.reconcile(running));

      expect(acknowledged.status, SessionStatus.finished);
      expect(acknowledged.finishedAcknowledged, isTrue);
    });
  });

  group('invalid transitions throw InvalidTransition', () {
    late TimerSession ready;
    late TimerSession running;
    late TimerSession paused;
    late TimerSession finished;
    late TimerSession cancelled;

    setUp(() {
      ready = readySession();
      running = engine.start(readySession());
      paused = engine.pause(running);
      cancelled = engine.cancel(running);
      advance(const Duration(minutes: 5));
      finished = engine.reconcile(running);
    });

    final invalid = <(String, TimerSession Function())>[
      ('start running', () => engine.start(running)),
      ('start paused', () => engine.start(paused)),
      ('start finished', () => engine.start(finished)),
      ('pause ready', () => engine.pause(ready)),
      ('pause paused', () => engine.pause(paused)),
      ('pause finished', () => engine.pause(finished)),
      ('resume ready', () => engine.resume(ready)),
      ('resume running', () => engine.resume(running)),
      ('cancel ready', () => engine.cancel(ready)),
      ('cancel finished', () => engine.cancel(finished)),
      ('cancel cancelled', () => engine.cancel(cancelled)),
      ('restart ready', () => engine.restart(ready)),
      ('restart cancelled', () => engine.restart(cancelled)),
      ('acknowledge running', () => engine.acknowledge(running)),
      ('start cancelled', () => engine.start(cancelled)),
    ];

    for (final (description, transition) in invalid) {
      test(description, () {
        expect(transition, throwsA(isA<InvalidTransition>()));
      });
    }

    test('the exception names the state and the action', () {
      expect(
        () => engine.pause(ready),
        throwsA(
          isA<InvalidTransition>()
              .having((e) => e.from, 'from', SessionStatus.ready)
              .having((e) => e.action, 'action', 'pause')
              .having((e) => e.toString(), 'toString', contains('pause')),
        ),
      );
    });
  });

  group('time zone independence', () {
    test('instants are stored in UTC even with a local clock', () {
      final localNow = DateTime(2026, 10, 23, 9);
      final localEngine = TimerEngine(clock: Clock.fixed(localNow));

      final session = localEngine.start(
        localEngine.create(id: 'tz', config: fiveMinutes),
      );

      expect(session.startedAt!.isUtc, isTrue);
      expect(session.endsAt!.isUtc, isTrue);
      expect(session.startedAt, localNow.toUtc());
      expect(
        session.remaining(localNow.add(const Duration(minutes: 1))),
        const Duration(minutes: 4),
      );
    });
  });
}
