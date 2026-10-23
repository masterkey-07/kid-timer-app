import 'package:visual_time_counter/core/platform/alarm/alarm_scheduler.dart';

/// [AlarmScheduler] for platforms without OS scheduling (Web, Linux): the
/// alarm only rings while the app is open, and the start preflight tells
/// the adult so (FR-015).
final class ForegroundOnlyAlarmScheduler implements AlarmScheduler {
  /// Creates the scheduler.
  const new();

  @override
  Future<AlarmCapabilities> capabilities() async =>
      AlarmCapabilities.unsupported;

  @override
  Future<PermissionState> requestNotificationPermission() async =>
      PermissionState.notApplicable;

  @override
  Future<bool> openExactAlarmSettings() async => false;

  @override
  Future<ScheduleResult> schedule(AlarmRequest request) async =>
      const NotSupported();

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelGroup(String groupKey) async {}

  @override
  Stream<String> get notificationTaps => const Stream.empty();

  @override
  Future<String?> launchPayload() async => null;
}
