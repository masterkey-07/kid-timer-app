import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/platform/alarm/alarm_scheduler.dart';
import 'package:visual_time_counter/features/timer/application/background_alarm_notice.dart';

/// Which banner each alarm situation gets (contracts/ui/08 §8.2).
void main() {
  BackgroundAlarmNotice? noticeFor({
    SchedulingSupport scheduling = SchedulingSupport.native,
    PermissionState notifications = PermissionState.granted,
    PermissionState exactAlarm = PermissionState.granted,
  }) => backgroundAlarmNoticeFor(
    AlarmCapabilities(
      scheduling: scheduling,
      notifications: notifications,
      exactAlarm: exactAlarm,
    ),
  );

  test('a reliable OS alarm needs no banner', () {
    expect(noticeFor(), isNull);
    expect(noticeFor(exactAlarm: PermissionState.notApplicable), isNull);
    expect(noticeFor(notifications: PermissionState.notApplicable), isNull);
  });

  test('no OS scheduling asks to keep the app open', () {
    expect(
      backgroundAlarmNoticeFor(AlarmCapabilities.unsupported),
      BackgroundAlarmNotice.keepAppOpen,
    );
  });

  test('notifications off or never granted: only rings with the app open', () {
    for (final state in [
      PermissionState.denied,
      PermissionState.notDetermined,
    ]) {
      expect(
        noticeFor(notifications: state, exactAlarm: PermissionState.denied),
        BackgroundAlarmNotice.notificationsOff,
        reason: '$state',
      );
    }
  });

  test('inexact scheduling or a denied exact alarm may ring late', () {
    expect(
      noticeFor(scheduling: SchedulingSupport.inexactOnly),
      BackgroundAlarmNotice.reducedAccuracy,
    );
    expect(
      noticeFor(exactAlarm: PermissionState.denied),
      BackgroundAlarmNotice.reducedAccuracy,
    );
  });
}
