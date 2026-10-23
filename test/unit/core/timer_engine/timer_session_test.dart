import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';

/// The TimerSession example from contracts/persistence-schema.md.
final _schemaExample = <String, Object?>{
  'schemaVersion': 1,
  'id': 'uuid',
  'status': 'running',
  'config': TimerConfig.defaults.toJson(),
  'startedAt': '2026-10-23T12:00:00.000Z',
  'endsAt': '2026-10-23T12:05:00.000Z',
  'pausedRemainingMs': null,
  'origin': {'type': 'preset', 'presetId': 'uuid'},
  'scheduledNotificationIds': [123456],
  'finishedAcknowledged': false,
};

void main() {
  final running = TimerSession(
    id: 'uuid',
    config: TimerConfig.defaults,
    status: SessionStatus.running,
    startedAt: DateTime.utc(2026, 10, 23, 12),
    endsAt: DateTime.utc(2026, 10, 23, 12, 5),
    origin: const PresetOrigin('uuid'),
    scheduledNotificationIds: const [123456],
  );

  group('JSON (contracts/persistence-schema.md)', () {
    test('encodes the schema example', () {
      expect(running.toJson(), _schemaExample);
    });

    test('decodes the schema example', () {
      expect(TimerSession.fromJson(_schemaExample), running);
    });

    test('round-trips a paused, manual session', () {
      final paused = TimerSession(
        id: 'p',
        config: TimerConfig.defaults,
        status: SessionStatus.paused,
        startedAt: DateTime.utc(2026, 10, 23, 12),
        pausedRemaining: const Duration(minutes: 3, milliseconds: 250),
      );

      expect(TimerSession.fromJson(paused.toJson()), paused);
    });

    test('round-trips a routine origin', () {
      final session = TimerSession(
        id: 'r',
        config: TimerConfig.defaults,
        status: SessionStatus.ready,
        origin: const RoutineOrigin(runId: 'run', stepIndex: 2),
      );

      expect(TimerSession.fromJson(session.toJson()), session);
    });

    test('decodes instants with an offset to UTC', () {
      final json = {
        ..._schemaExample,
        'startedAt': '2026-10-23T09:00:00-03:00',
      };

      final session = TimerSession.fromJson(json);

      expect(session.startedAt, DateTime.utc(2026, 10, 23, 12));
      expect(session.startedAt!.isUtc, isTrue);
    });

    test('rejects an unsupported schema version', () {
      final json = {..._schemaExample, 'schemaVersion': 2};

      expect(() => TimerSession.fromJson(json), throwsFormatException);
    });

    test('rejects an unknown origin type', () {
      final json = {
        ..._schemaExample,
        'origin': {'type': 'widget'},
      };

      expect(() => TimerSession.fromJson(json), throwsFormatException);
    });

    test('rejects an invalid instant', () {
      final json = {..._schemaExample, 'endsAt': 'tomorrow'};

      expect(() => TimerSession.fromJson(json), throwsFormatException);
    });

    test('rejects a running session without endsAt', () {
      final json = {..._schemaExample, 'endsAt': null};

      expect(() => TimerSession.fromJson(json), throwsFormatException);
    });

    test('rejects a paused session without pausedRemainingMs', () {
      final json = {..._schemaExample, 'status': 'paused', 'endsAt': null};

      expect(() => TimerSession.fromJson(json), throwsFormatException);
    });
  });

  group('invariants', () {
    test('a running session requires endsAt', () {
      expect(
        () => TimerSession(
          id: 'x',
          config: TimerConfig.defaults,
          status: SessionStatus.running,
        ),
        throwsArgumentError,
      );
    });

    test('a paused session requires pausedRemaining', () {
      expect(
        () => TimerSession(
          id: 'x',
          config: TimerConfig.defaults,
          status: SessionStatus.paused,
        ),
        throwsArgumentError,
      );
    });

    test('at most 60 scheduled notification ids', () {
      expect(
        () => running.copyWith(
          scheduledNotificationIds: List.generate(61, (i) => i),
        ),
        throwsArgumentError,
      );
    });
  });

  test('copyWith replaces the scheduled notification ids', () {
    final updated = running.copyWith(scheduledNotificationIds: const [7, 8]);

    expect(updated.scheduledNotificationIds, [7, 8]);
    expect(updated.copyWith(), updated);
    expect(updated, isNot(running));
  });

  test('origins have value equality', () {
    expect(const PresetOrigin('a'), const PresetOrigin('a'));
    expect(const PresetOrigin('a').hashCode, const PresetOrigin('a').hashCode);
    expect(
      const RoutineOrigin(runId: 'r', stepIndex: 1),
      isNot(const RoutineOrigin(runId: 'r', stepIndex: 2)),
    );
    expect(const ManualOrigin().hashCode, const ManualOrigin().hashCode);
  });
}
