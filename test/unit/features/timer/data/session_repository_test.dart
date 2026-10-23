import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:mocktail/mocktail.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/timer/data/session_repository.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/hive_test_utils.dart';

class _MockBox extends Mock implements Box<Map<dynamic, dynamic>>;

void main() {
  final running = TimerSession(
    id: 's1',
    config: TimerConfig.defaults,
    status: SessionStatus.running,
    startedAt: DateTime.utc(2026, 10, 23, 12),
    endsAt: DateTime.utc(2026, 10, 23, 12, 5),
  );

  group('with Hive', () {
    useTemporaryHive();

    late Box<Map<dynamic, dynamic>> box;
    late SessionRepository repository;

    setUp(() async {
      box = await Hive.openBox<Map<dynamic, dynamic>>('session');
      repository = SessionRepository(box);
    });

    test('load returns null without a saved session', () {
      expect(repository.load(), isNull);
    });

    test('save then load returns the same session', () async {
      await repository.save(running);

      expect(repository.load(), running);
    });

    test('the session survives reopening the box', () async {
      await repository.save(running);
      await box.close();

      final reopened = await Hive.openBox<Map<dynamic, dynamic>>('session');

      expect(SessionRepository(reopened).load(), running);
    });

    test('clear removes the session', () async {
      await repository.save(running);

      await repository.clear();

      expect(repository.load(), isNull);
    });

    test('loads the v1 fixture', () async {
      await box.put(
        'timer',
        readJsonFixture('persistence/v1/session_running.json'),
      );

      final session = repository.load()!;

      expect(session.id, '6f1c2a52-8d1e-4f0b-9a43-0d5c3e2b7a10');
      expect(session.status, SessionStatus.running);
      expect(session.endsAt, DateTime.utc(2026, 10, 23, 12, 5));
      expect(
        session.origin,
        const PresetOrigin('0b7e4f7c-3a9d-4c55-8f0e-5d2a1b6c9e88'),
      );
      expect(session.config, TimerConfig.defaults);
    });

    test('a corrupt document surfaces as a FormatException', () async {
      await box.put('timer', {'schemaVersion': 1, 'status': 'running'});

      expect(repository.load, throwsFormatException);
    });
  });

  group('durability', () {
    late _MockBox box;

    setUp(() {
      box = _MockBox();
      when(() => box.put(any<Object?>(), any())).thenAnswer((_) async {});
      when(() => box.delete(any<Object?>())).thenAnswer((_) async {});
      when(box.flush).thenAnswer((_) async {});
    });

    test('save writes then flushes before completing', () async {
      await SessionRepository(box).save(running);

      verifyInOrder([() => box.put('timer', running.toJson()), box.flush]);
    });

    test('clear deletes then flushes', () async {
      await SessionRepository(box).clear();

      verifyInOrder([() => box.delete('timer'), box.flush]);
    });

    test('a storage failure propagates to the caller', () async {
      when(() => box.put(any<Object?>(), any()))
          .thenThrow(const FileSystemFull());

      await expectLater(
        SessionRepository(box).save(running),
        throwsA(isA<FileSystemFull>()),
      );
      verifyNever(box.flush);
    });
  });
}

class FileSystemFull implements Exception {
  const new();
}
