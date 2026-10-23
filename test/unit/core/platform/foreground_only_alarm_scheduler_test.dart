import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/platform/alarm/alarm_scheduler.dart';
import 'package:visual_time_counter/core/platform/alarm/foreground_only_alarm_scheduler.dart';

import '../../../contract/alarm_scheduler_contract.dart';

void main() {
  runAlarmSchedulerContract(
    'ForegroundOnlyAlarmScheduler',
    () async => (
      scheduler: ForegroundOnlyAlarmScheduler(),
      now: DateTime.now,
      pending: () async => <PendingAlarm>[],
    ),
    supportsScheduling: false,
  );

  test('reports no scheduling, permissions or launch payload', () async {
    final scheduler = ForegroundOnlyAlarmScheduler();

    expect(await scheduler.capabilities(), AlarmCapabilities.unsupported);
    expect(
      await scheduler.requestNotificationPermission(),
      PermissionState.notApplicable,
    );
    expect(await scheduler.openExactAlarmSettings(), isFalse);
    expect(await scheduler.launchPayload(), isNull);
    expect(await scheduler.notificationTaps.isEmpty, isTrue);
  });
}
