import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/core/platform/alarm/alarm_scheduler.dart';
import 'package:visual_time_counter/core/platform/providers.dart';

/// Why the alarm is not guaranteed with the app in the background; the
/// `PlatformNotice` banner says it (contracts/ui/08 §8.2).
enum BackgroundAlarmNotice {
  /// The platform cannot schedule OS alarms (Web, Linux): keep it open.
  keepAppOpen,

  /// Notifications are off: the alarm only rings with the app open.
  notificationsOff,

  /// Only inexact OS alarms: the alarm may ring a few minutes late.
  reducedAccuracy,
}

/// The banner for [capabilities], or null when the OS alarm is reliable.
///
/// Notifications that were never asked for count as off: until the adult
/// grants them, the alarm cannot ring in the background.
BackgroundAlarmNotice? backgroundAlarmNoticeFor(
  AlarmCapabilities capabilities,
) {
  if (capabilities.scheduling == SchedulingSupport.unsupported) {
    return BackgroundAlarmNotice.keepAppOpen;
  }
  if (capabilities.notifications
      case PermissionState.denied || PermissionState.notDetermined) {
    return BackgroundAlarmNotice.notificationsOff;
  }
  if (capabilities.scheduling == SchedulingSupport.inexactOnly ||
      capabilities.exactAlarm == PermissionState.denied) {
    return BackgroundAlarmNotice.reducedAccuracy;
  }
  return null;
}

/// The current banner. It re-checks whenever the app returns to the front,
/// since the adult may have changed a permission in the system settings.
final backgroundAlarmNoticeProvider = FutureProvider<BackgroundAlarmNotice?>((
  ref,
) async {
  final returns = ref
      .read(appLifecycleProvider)
      .states
      .where((state) => state == AppLifecycleState.resumed)
      .listen((_) => ref.invalidateSelf());
  ref.onDispose(returns.cancel);

  final capabilities = await ref.read(alarmSchedulerProvider).capabilities();
  return backgroundAlarmNoticeFor(capabilities);
});
