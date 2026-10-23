import 'package:meta/meta.dart';
import 'package:visual_time_counter/core/domain/json_utils.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';

/// A timer and its absolute instants (data-model TimerSession).
///
/// Remaining time is always derived from `endsAt − now` (Constitution III);
/// every instant is stored in UTC.
@immutable
final class TimerSession {
  /// Creates a session; throws an [ArgumentError] when the invariants of
  /// [status] do not hold.
  factory({
    required String id,
    required TimerConfig config,
    required SessionStatus status,
    DateTime? startedAt,
    DateTime? endsAt,
    Duration? pausedRemaining,
    SessionOrigin origin = const ManualOrigin(),
    List<int> scheduledNotificationIds = const [],
    bool finishedAcknowledged = false,
  }) {
    final violation = _violationOf(
      status: status,
      endsAt: endsAt,
      pausedRemaining: pausedRemaining,
      scheduledNotificationIds: scheduledNotificationIds,
    );
    if (violation != null) throw ArgumentError(violation);
    return TimerSession._(
      id: id,
      config: config,
      status: status,
      startedAt: startedAt?.toUtc(),
      endsAt: endsAt?.toUtc(),
      pausedRemaining: pausedRemaining,
      origin: origin,
      scheduledNotificationIds: List.unmodifiable(scheduledNotificationIds),
      finishedAcknowledged: finishedAcknowledged,
    );
  }

  /// Decodes `session["timer"]`; throws a [FormatException] for an
  /// unsupported schema version or an invalid document.
  factory fromJson(Map<String, Object?> json) {
    final version = json['schemaVersion'];
    if (version != schemaVersion) {
      throw FormatException('Unsupported TimerSession schema', version);
    }

    final status = SessionStatus.fromJson(json['status']);
    final endsAt = readOptionalInstant(json, 'endsAt');
    final pausedMs = json['pausedRemainingMs'];
    if (pausedMs != null && pausedMs is! int) {
      throw const FormatException('pausedRemainingMs must be an int');
    }
    final pausedRemaining = pausedMs == null
        ? null
        : Duration(milliseconds: pausedMs as int);
    final ids = readField<List<Object?>>(json, 'scheduledNotificationIds');
    if (ids.any((id) => id is! int)) {
      throw const FormatException('scheduledNotificationIds must be ints');
    }

    final violation = _violationOf(
      status: status,
      endsAt: endsAt,
      pausedRemaining: pausedRemaining,
      scheduledNotificationIds: ids,
    );
    if (violation != null) throw FormatException(violation);

    return TimerSession(
      id: readField<String>(json, 'id'),
      config: TimerConfig.fromJson(readObject(json, 'config')),
      status: status,
      startedAt: readOptionalInstant(json, 'startedAt'),
      endsAt: endsAt,
      pausedRemaining: pausedRemaining,
      origin: SessionOrigin.fromJson(readObject(json, 'origin')),
      scheduledNotificationIds: ids.cast<int>(),
      finishedAcknowledged: readField<bool>(json, 'finishedAcknowledged'),
    );
  }

  const new _({
    required this.id,
    required this.config,
    required this.status,
    required this.startedAt,
    required this.endsAt,
    required this.pausedRemaining,
    required this.origin,
    required this.scheduledNotificationIds,
    required this.finishedAcknowledged,
  });

  /// The persisted document version.
  static const schemaVersion = 1;

  /// The most OS notifications a session may keep pending (research R16).
  static const maxScheduledNotifications = 60;

  /// The session id (UUID).
  final String id;

  /// A frozen copy of the configuration at start.
  final TimerConfig config;

  /// The current state.
  final SessionStatus status;

  /// When the countdown first started (UTC).
  final DateTime? startedAt;

  /// When the countdown ends (UTC); set while running.
  final DateTime? endsAt;

  /// The time left when paused; set while paused.
  final Duration? pausedRemaining;

  /// What started the session.
  final SessionOrigin origin;

  /// Ids scheduled with the OS, kept for cancellation.
  final List<int> scheduledNotificationIds;

  /// Whether the final screen was tapped.
  final bool finishedAcknowledged;

  /// The time left at [now], never negative.
  Duration remaining(DateTime now) => switch (status) {
    SessionStatus.ready => config.duration.value,
    SessionStatus.running => _nonNegative(endsAt!.difference(now)),
    SessionStatus.paused => pausedRemaining!,
    SessionStatus.finished || SessionStatus.cancelled => Duration.zero,
  };

  /// The remaining share of the configured duration at [now], in [0, 1].
  double progress(DateTime now) =>
      (remaining(now).inMicroseconds / config.duration.value.inMicroseconds)
          .clamp(0.0, 1.0);

  /// Whether the session is running and its end has passed at [now].
  bool isOverdue(DateTime now) =>
      status == SessionStatus.running && !now.isBefore(endsAt!);

  /// A copy with the given fields replaced.
  TimerSession copyWith({
    List<int>? scheduledNotificationIds,
    bool? finishedAcknowledged,
  }) => TimerSession(
    id: id,
    config: config,
    status: status,
    startedAt: startedAt,
    endsAt: endsAt,
    pausedRemaining: pausedRemaining,
    origin: origin,
    scheduledNotificationIds:
        scheduledNotificationIds ?? this.scheduledNotificationIds,
    finishedAcknowledged: finishedAcknowledged ?? this.finishedAcknowledged,
  );

  /// Encodes per contracts/persistence-schema.md.
  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'id': id,
    'status': status.toJson(),
    'config': config.toJson(),
    'startedAt': startedAt?.toIso8601String(),
    'endsAt': endsAt?.toIso8601String(),
    'pausedRemainingMs': pausedRemaining?.inMilliseconds,
    'origin': origin.toJson(),
    'scheduledNotificationIds': scheduledNotificationIds,
    'finishedAcknowledged': finishedAcknowledged,
  };

  @override
  bool operator ==(Object other) =>
      other is TimerSession &&
      other.id == id &&
      other.config == config &&
      other.status == status &&
      other.startedAt == startedAt &&
      other.endsAt == endsAt &&
      other.pausedRemaining == pausedRemaining &&
      other.origin == origin &&
      _sameIds(other.scheduledNotificationIds, scheduledNotificationIds) &&
      other.finishedAcknowledged == finishedAcknowledged;

  @override
  int get hashCode => Object.hash(
    id,
    config,
    status,
    startedAt,
    endsAt,
    pausedRemaining,
    origin,
    Object.hashAll(scheduledNotificationIds),
    finishedAcknowledged,
  );

  @override
  String toString() => 'TimerSession($id, $status, endsAt: $endsAt)';

  static String? _violationOf({
    required SessionStatus status,
    required DateTime? endsAt,
    required Duration? pausedRemaining,
    required List<Object?> scheduledNotificationIds,
  }) {
    if (status == SessionStatus.running && endsAt == null) {
      return 'A running session requires endsAt';
    }
    if (status == SessionStatus.paused && pausedRemaining == null) {
      return 'A paused session requires pausedRemaining';
    }
    if (scheduledNotificationIds.length > maxScheduledNotifications) {
      return 'At most $maxScheduledNotifications scheduled notifications';
    }
    return null;
  }

  static Duration _nonNegative(Duration value) =>
      value.isNegative ? Duration.zero : value;

  static bool _sameIds(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// What started a session.
@immutable
sealed class SessionOrigin {
  const new();

  /// Decodes a persisted origin.
  factory fromJson(Map<String, Object?> json) => switch (json['type']) {
    ManualOrigin._type => const ManualOrigin(),
    PresetOrigin._type => PresetOrigin(readField<String>(json, 'presetId')),
    RoutineOrigin._type => RoutineOrigin(
      runId: readField<String>(json, 'runId'),
      stepIndex: readField<int>(json, 'stepIndex'),
    ),
    final type => throw FormatException('Unknown origin type: $type'),
  };

  /// Encodes this origin.
  Map<String, Object?> toJson();
}

/// Started from the home screen.
final class ManualOrigin extends SessionOrigin {
  /// Creates a manual origin.
  const new();

  static const _type = 'manual';

  @override
  Map<String, Object?> toJson() => {'type': _type};

  @override
  bool operator ==(Object other) => other is ManualOrigin;

  @override
  int get hashCode => _type.hashCode;
}

/// Started from a preset.
final class PresetOrigin extends SessionOrigin {
  /// Creates an origin for the preset [presetId].
  const new(this.presetId);

  static const _type = 'preset';

  /// The preset id.
  final String presetId;

  @override
  Map<String, Object?> toJson() => {'type': _type, 'presetId': presetId};

  @override
  bool operator ==(Object other) =>
      other is PresetOrigin && other.presetId == presetId;

  @override
  int get hashCode => Object.hash(_type, presetId);
}

/// A step of a routine run (v1.x).
final class RoutineOrigin extends SessionOrigin {
  /// Creates an origin for step [stepIndex] of the run [runId].
  const new({required this.runId, required this.stepIndex});

  static const _type = 'routine';

  /// The routine run id.
  final String runId;

  /// The zero-based step index.
  final int stepIndex;

  @override
  Map<String, Object?> toJson() => {
    'type': _type,
    'runId': runId,
    'stepIndex': stepIndex,
  };

  @override
  bool operator ==(Object other) =>
      other is RoutineOrigin &&
      other.runId == runId &&
      other.stepIndex == stepIndex;

  @override
  int get hashCode => Object.hash(_type, runId, stepIndex);
}
