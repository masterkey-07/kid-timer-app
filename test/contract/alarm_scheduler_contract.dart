import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/domain/sound_id.dart';
import 'package:visual_time_counter/core/platform/alarm/alarm_scheduler.dart';

/// An alarm the platform reports as pending.
typedef PendingAlarm = ({int id, String title});

/// What the contract needs from an [AlarmScheduler] under test.
typedef AlarmSchedulerHarness = ({
  AlarmScheduler scheduler,
  DateTime Function() now,
  Future<List<PendingAlarm>> Function() pending,
});

/// The AlarmScheduler contract (contracts/platform-ports.md), shared by the
/// fake (unit) and the real implementations (integration).
///
/// Set [supportsScheduling] to false for foreground-only implementations.
void runAlarmSchedulerContract(
  String description,
  Future<AlarmSchedulerHarness> Function() createHarness, {
  bool supportsScheduling = true,
}) {
  group('$description AlarmScheduler contract', () {
    late AlarmSchedulerHarness harness;

    setUp(() async => harness = await createHarness());

    tearDown(() async {
      for (final alarm in await harness.pending()) {
        await harness.scheduler.cancel(alarm.id);
      }
    });

    AlarmRequest request(
      int id, {
      String group = 'session-a',
      Duration inFuture = const Duration(minutes: 5),
      String title = 'Time is up',
    }) => AlarmRequest(
      id: id,
      groupKey: group,
      fireAtUtc: harness.now().toUtc().add(inFuture),
      kind: AlarmKind.end,
      title: title,
      body: 'body',
      sound: SoundId.chimeSoft,
      payload: 'vtc://run',
    );

    test('reports its scheduling support', () async {
      final capabilities = await harness.scheduler.capabilities();

      expect(
        capabilities.scheduling == SchedulingSupport.unsupported,
        !supportsScheduling,
      );
    });

    if (!supportsScheduling) {
      test('schedule returns NotSupported and schedules nothing', () async {
        final result = await harness.scheduler.schedule(request(1));

        expect(result, const NotSupported());
        expect(await harness.pending(), isEmpty);
      });

      test('cancel and cancelGroup are harmless no-ops', () async {
        await harness.scheduler.cancel(1);
        await harness.scheduler.cancelGroup('session-a');
      });

      return;
    }

    test('schedules a future alarm', () async {
      final result = await harness.scheduler.schedule(request(1));

      expect(result, isA<Scheduled>());
      expect((await harness.pending()).map((alarm) => alarm.id), [1]);
    });

    test('a request with the same id replaces the previous one', () async {
      await harness.scheduler.schedule(request(1, title: 'first'));
      await harness.scheduler.schedule(request(1, title: 'second'));

      final pending = await harness.pending();
      expect(pending, hasLength(1));
      expect(pending.single.title, 'second');
    });

    test('cancel removes a scheduled alarm', () async {
      await harness.scheduler.schedule(request(1));
      await harness.scheduler.schedule(request(2));

      await harness.scheduler.cancel(1);

      expect((await harness.pending()).map((alarm) => alarm.id), [2]);
    });

    test('cancelling an unknown id does not fail', () async {
      await harness.scheduler.cancel(424242);

      expect(await harness.pending(), isEmpty);
    });

    test('a time in the past fails with pastTime', () async {
      final result = await harness.scheduler.schedule(
        request(1, inFuture: const Duration(seconds: -1)),
      );

      expect(result, const Failed(ScheduleFailure.pastTime));
      expect(await harness.pending(), isEmpty);
    });

    test('never more than 60 pending per group', () async {
      for (var id = 1; id <= AlarmScheduler.maxPendingPerGroup; id++) {
        expect(await harness.scheduler.schedule(request(id)), isA<Scheduled>());
      }

      final overflow = await harness.scheduler.schedule(request(61));
      final otherGroup = await harness.scheduler.schedule(
        request(62, group: 'session-b'),
      );

      expect(overflow, const Failed(ScheduleFailure.tooManyPending));
      expect(otherGroup, isA<Scheduled>());
      expect(await harness.pending(), hasLength(61));
    });

    test('replacing an id does not count against the group limit', () async {
      for (var id = 1; id <= AlarmScheduler.maxPendingPerGroup; id++) {
        await harness.scheduler.schedule(request(id));
      }

      expect(await harness.scheduler.schedule(request(1)), isA<Scheduled>());
    });

    test('cancelGroup removes only that group', () async {
      await harness.scheduler.schedule(request(1));
      await harness.scheduler.schedule(request(2));
      await harness.scheduler.schedule(request(3, group: 'session-b'));

      await harness.scheduler.cancelGroup('session-a');

      expect((await harness.pending()).map((alarm) => alarm.id), [3]);
    });
  });
}
