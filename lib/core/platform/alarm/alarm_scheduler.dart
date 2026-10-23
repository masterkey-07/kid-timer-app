import 'package:meta/meta.dart';
import 'package:visual_time_counter/core/domain/sound_id.dart';

/// Schedules the end-of-timer alarm with the operating system
/// (contracts/platform-ports.md).
///
/// Methods never throw for an expected platform condition; they return a
/// typed result instead.
abstract interface class AlarmScheduler {
  /// The most alarms pending at once for one `groupKey` (iOS allows 64;
  /// research R16).
  static const maxPendingPerGroup = 60;

  /// What the current platform can do right now (queries permissions).
  Future<AlarmCapabilities> capabilities();

  /// Requests notification permission (no-op where not applicable).
  Future<PermissionState> requestNotificationPermission();

  /// Opens the exact alarm setting (Android 12–13) or returns false.
  Future<bool> openExactAlarmSettings();

  /// Schedules the alarm; a request with the same id replaces the previous
  /// one.
  Future<ScheduleResult> schedule(AlarmRequest request);

  /// Cancels a scheduled alarm; unknown ids are ignored.
  Future<void> cancel(int id);

  /// Cancels every alarm of [groupKey] (e.g., a routine run).
  Future<void> cancelGroup(String groupKey);

  /// Notification taps; the payload is a deep link.
  Stream<String> get notificationTaps;

  /// The payload of the notification that opened the app, if any.
  Future<String?> launchPayload();
}

/// Whether the platform can fire an alarm without the app running.
enum SchedulingSupport {
  /// Exact OS scheduling.
  native,

  /// OS scheduling without exactness (Android without exact alarm access).
  inexactOnly,

  /// No OS scheduling; the alarm only rings with the app open.
  unsupported,
}

/// The state of a runtime permission.
enum PermissionState {
  /// Granted.
  granted,

  /// Denied by the user.
  denied,

  /// Not asked yet.
  notDetermined,

  /// The platform has no such permission.
  notApplicable,
}

/// What [AlarmScheduler] can do right now.
@immutable
final class AlarmCapabilities {
  /// Creates the capabilities.
  const new({
    required this.scheduling,
    required this.notifications,
    required this.exactAlarm,
    this.bypassesSilentMode = false,
  });

  /// Capabilities of a platform without OS scheduling (Web, Linux).
  static const unsupported = AlarmCapabilities(
    scheduling: SchedulingSupport.unsupported,
    notifications: PermissionState.notApplicable,
    exactAlarm: PermissionState.notApplicable,
  );

  /// OS scheduling support.
  final SchedulingSupport scheduling;

  /// Notification permission.
  final PermissionState notifications;

  /// Exact alarm permission (Android 12+).
  final PermissionState exactAlarm;

  /// Whether the alarm rings in silent mode (AlarmKit, iOS 26+; v1.x).
  final bool bypassesSilentMode;

  @override
  bool operator ==(Object other) =>
      other is AlarmCapabilities &&
      other.scheduling == scheduling &&
      other.notifications == notifications &&
      other.exactAlarm == exactAlarm &&
      other.bypassesSilentMode == bypassesSilentMode;

  @override
  int get hashCode =>
      Object.hash(scheduling, notifications, exactAlarm, bypassesSilentMode);

  @override
  String toString() =>
      'AlarmCapabilities($scheduling, notifications: $notifications, '
      'exactAlarm: $exactAlarm, bypassesSilentMode: $bypassesSilentMode)';
}

/// The kind of alarm, which selects the notification channel.
enum AlarmKind {
  /// The end of a timer.
  end,

  /// A warning before the end (v1.x).
  warning,

  /// The end of a routine step (v1.x).
  stepEnd,
}

/// An alarm to schedule.
@immutable
final class AlarmRequest {
  /// Creates a request.
  const new({
    required this.id,
    required this.groupKey,
    required this.fireAtUtc,
    required this.kind,
    required this.title,
    required this.body,
    required this.sound,
    required this.payload,
  });

  /// Stable id derived from the session id (+ step index).
  final int id;

  /// The session or routine run the alarm belongs to.
  final String groupKey;

  /// When the alarm fires (UTC).
  final DateTime fireAtUtc;

  /// The alarm kind.
  final AlarmKind kind;

  /// The localized notification title.
  final String title;

  /// The localized notification body.
  final String body;

  /// The bundled sound to play.
  final SoundId sound;

  /// The deep link opened on tap, e.g. `vtc://run`.
  final String payload;

  @override
  bool operator ==(Object other) =>
      other is AlarmRequest &&
      other.id == id &&
      other.groupKey == groupKey &&
      other.fireAtUtc == fireAtUtc &&
      other.kind == kind &&
      other.title == title &&
      other.body == body &&
      other.sound == sound &&
      other.payload == payload;

  @override
  int get hashCode =>
      Object.hash(id, groupKey, fireAtUtc, kind, title, body, sound, payload);

  @override
  String toString() => 'AlarmRequest($id, $groupKey, $fireAtUtc, $kind)';
}

/// The outcome of [AlarmScheduler.schedule].
@immutable
sealed class ScheduleResult {
  const new();
}

/// The alarm was scheduled with the OS.
final class Scheduled extends ScheduleResult {
  /// Creates the result; [isExact] is false for inexact Android alarms.
  const new({required this.isExact});

  /// Whether the OS will fire it on time.
  final bool isExact;

  @override
  bool operator ==(Object other) =>
      other is Scheduled && other.isExact == isExact;

  @override
  int get hashCode => isExact.hashCode;

  @override
  String toString() => 'Scheduled(isExact: $isExact)';
}

/// The platform cannot schedule alarms.
final class NotSupported extends ScheduleResult {
  /// Creates the result.
  const new();

  @override
  bool operator ==(Object other) => other is NotSupported;

  @override
  int get hashCode => (NotSupported).hashCode;

  @override
  String toString() => 'NotSupported()';
}

/// Scheduling failed for [reason].
final class Failed extends ScheduleResult {
  /// Creates the result.
  const new(this.reason);

  /// Why scheduling failed.
  final ScheduleFailure reason;

  @override
  bool operator ==(Object other) => other is Failed && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;

  @override
  String toString() => 'Failed($reason)';
}

/// Why an alarm could not be scheduled.
enum ScheduleFailure {
  /// `fireAtUtc` is not in the future.
  pastTime,

  /// The group already has [AlarmScheduler.maxPendingPerGroup] alarms.
  tooManyPending,

  /// The notification permission is denied.
  permissionDenied,

  /// The platform reported an unexpected error.
  platformError,
}
