import 'dart:async';

import 'package:clock/clock.dart';
import 'package:visual_time_counter/core/platform/alarm/alarm_scheduler.dart';

/// An in-memory [AlarmScheduler] that follows the port contract and lets
/// tests set permissions and simulate notification taps.
class FakeAlarmScheduler implements AlarmScheduler {
  new({
    required this._clock,
    AlarmCapabilities capabilities = const AlarmCapabilities(
      scheduling: SchedulingSupport.native,
      notifications: PermissionState.granted,
      exactAlarm: PermissionState.granted,
    ),
  }) : capabilitiesValue = capabilities;

  final Clock _clock;
  final _taps = StreamController<String>.broadcast();

  /// What [capabilities] returns; tests may change it.
  AlarmCapabilities capabilitiesValue;

  /// What [requestNotificationPermission] returns.
  PermissionState permissionAfterRequest = PermissionState.granted;

  /// What [launchPayload] returns.
  String? launchPayloadValue;

  /// Scheduled alarms by id.
  final Map<int, AlarmRequest> pending = {};

  /// Every scheduled request, in order.
  final List<AlarmRequest> scheduledRequests = [];

  /// Every cancelled id, in order.
  final List<int> cancelledIds = [];

  /// Names of the permission/settings calls, in order.
  final List<String> calls = [];

  /// Emits a notification tap with [payload].
  void simulateTap(String payload) => _taps.add(payload);

  @override
  Future<AlarmCapabilities> capabilities() async => capabilitiesValue;

  @override
  Future<PermissionState> requestNotificationPermission() async {
    calls.add('requestNotificationPermission');
    return permissionAfterRequest;
  }

  @override
  Future<bool> openExactAlarmSettings() async {
    calls.add('openExactAlarmSettings');
    return true;
  }

  @override
  Future<ScheduleResult> schedule(AlarmRequest request) async {
    scheduledRequests.add(request);
    final capabilities = capabilitiesValue;
    if (capabilities.scheduling == SchedulingSupport.unsupported) {
      return const NotSupported();
    }
    if (capabilities.notifications == PermissionState.denied) {
      return const Failed(ScheduleFailure.permissionDenied);
    }
    if (!request.fireAtUtc.isAfter(_clock.now().toUtc())) {
      return const Failed(ScheduleFailure.pastTime);
    }
    final pendingInGroup = pending.values.where(
      (other) => other.groupKey == request.groupKey && other.id != request.id,
    );
    if (pendingInGroup.length >= AlarmScheduler.maxPendingPerGroup) {
      return const Failed(ScheduleFailure.tooManyPending);
    }

    pending[request.id] = request;
    return Scheduled(
      isExact: capabilities.scheduling == SchedulingSupport.native,
    );
  }

  @override
  Future<void> cancel(int id) async {
    cancelledIds.add(id);
    pending.remove(id);
  }

  @override
  Future<void> cancelGroup(String groupKey) async {
    pending.removeWhere((_, request) => request.groupKey == groupKey);
  }

  @override
  Stream<String> get notificationTaps => _taps.stream;

  @override
  Future<String?> launchPayload() async => launchPayloadValue;
}
