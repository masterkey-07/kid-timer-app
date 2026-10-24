import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:visual_time_counter/core/domain/json_utils.dart';
import 'package:visual_time_counter/core/domain/palette_id.dart';
import 'package:visual_time_counter/core/domain/sound_id.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/domain/timer_duration.dart';
import 'package:visual_time_counter/core/domain/warning_offsets.dart';
import 'package:visual_time_counter/core/persistence/migrator.dart';
import 'package:visual_time_counter/core/platform/alarm/alarm_scheduler.dart';
import 'package:visual_time_counter/core/platform/providers.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';

import '../../helpers/hive_test_utils.dart';

/// Equal values are ==, share a hash code and describe themselves.
void expectValueSemantics(Object value, Object equal, Object different) {
  expect(value, equal);
  expect(value.hashCode, equal.hashCode);
  expect(value, isNot(different));
  expect(value.toString(), isNot(contains("Instance of '")));
}

void main() {
  group('value semantics', () {
    test('AlarmCapabilities', () {
      expectValueSemantics(
        const AlarmCapabilities(
          scheduling: SchedulingSupport.native,
          notifications: PermissionState.granted,
          exactAlarm: PermissionState.granted,
        ),
        const AlarmCapabilities(
          scheduling: SchedulingSupport.native,
          notifications: PermissionState.granted,
          exactAlarm: PermissionState.granted,
        ),
        AlarmCapabilities.unsupported,
      );
    });

    test('AlarmRequest', () {
      AlarmRequest request(int id) => AlarmRequest(
        id: id,
        groupKey: 'g',
        fireAtUtc: DateTime.utc(2026, 10, 23, 12),
        kind: AlarmKind.end,
        title: 't',
        body: 'b',
        sound: SoundId.chimeSoft,
        payload: 'vtc://run',
      );
      expectValueSemantics(request(1), request(1), request(2));
    });

    test('ScheduleResult variants', () {
      expectValueSemantics(
        const Scheduled(isExact: true),
        const Scheduled(isExact: true),
        const Scheduled(isExact: false),
      );
      expectValueSemantics(
        const NotSupported(),
        const NotSupported(),
        const Failed(ScheduleFailure.pastTime),
      );
      expectValueSemantics(
        const Failed(ScheduleFailure.pastTime),
        const Failed(ScheduleFailure.pastTime),
        const Failed(ScheduleFailure.platformError),
      );
    });

    test('PortChoice', () {
      expectValueSemantics(
        choosePorts(AppPlatform.android),
        choosePorts(AppPlatform.android),
        choosePorts(AppPlatform.web),
      );
    });

    test('PaletteBlend', () {
      expectValueSemantics(
        const PaletteBlend(PalettePhase.start, PalettePhase.middle, 0.5),
        const PaletteBlend(PalettePhase.start, PalettePhase.middle, 0.5),
        const PaletteBlend.solid(PalettePhase.end),
      );
    });

    test('TimerDuration, TimerConfig and WarningOffsets', () {
      expectValueSemantics(
        TimerDuration(const Duration(minutes: 3)),
        TimerDuration(const Duration(minutes: 3)),
        TimerDuration(const Duration(minutes: 4)),
      );
      expectValueSemantics(
        TimerConfig.defaults,
        TimerConfig.defaults.copyWith(),
        TimerConfig.defaults.copyWith(showDigits: false),
      );
      expectValueSemantics(
        WarningOffsets(const {1}),
        WarningOffsets(const {1}),
        WarningOffsets.none,
      );
    });

    test('TimerSession and origins', () {
      TimerSession session(String id) => TimerSession(
        id: id,
        config: TimerConfig.defaults,
        status: SessionStatus.ready,
        origin: const RoutineOrigin(runId: 'r', stepIndex: 0),
      );
      expectValueSemantics(session('a'), session('a'), session('b'));
      expectValueSemantics(
        const RoutineOrigin(runId: 'r', stepIndex: 0),
        const RoutineOrigin(runId: 'r', stepIndex: 0),
        const ManualOrigin(),
      );
      expectValueSemantics(
        const PresetOrigin('p'),
        const PresetOrigin('p'),
        const ManualOrigin(),
      );
      expect(const ManualOrigin().toString(), 'ManualOrigin()');
    });
  });

  group('SoundId', () {
    test('rejects invalid ids', () {
      expect(() => SoundId.fromJson(''), throwsFormatException);
      expect(() => SoundId.fromJson(3), throwsFormatException);
      expect(SoundId.fromJson('bell'), const SoundId('bell'));
    });

    test('none is the only silent sound', () {
      expect(SoundId.none.isAudible, isFalse);
      expect(SoundId.chimeSoft.isAudible, isTrue);
    });
  });

  test('readOptionalInstant rejects a non-string', () {
    expect(() => readOptionalInstant({'at': 5}, 'at'), throwsFormatException);
  });

  group('Migrator backups', () {
    useTemporaryHive();

    test('compares nested lists when deduplicating backups', () async {
      final box = await Hive.openBox<Map<dynamic, dynamic>>('routines');
      await box.put('r', {
        'schemaVersion': 9,
        'steps': [
          {'name': 'a'},
          {'name': 'b'},
        ],
      });
      final clock = Clock.fixed(DateTime.utc(2026, 10, 23));
      final migrator = Migrator(currentVersion: 1, clock: clock);

      await migrator.migrateBox(box);
      await box.put('r', {
        'schemaVersion': 9,
        'steps': [
          {'name': 'a'},
          {'name': 'c'},
        ],
      });
      final later = Migrator(
        currentVersion: 1,
        clock: Clock.fixed(DateTime.utc(2026, 10, 24)),
      );
      final report = await later.migrateBox(box);

      expect(report.failures.single.isNewBackup, isTrue);
      final backups = await Hive.openBox<Map<dynamic, dynamic>>(
        'routines_backup',
      );
      expect(backups.length, 2);
    });
  });
}
