import 'package:visual_time_counter/core/domain/json_utils.dart';

/// The states of a timer session (data-model state machine).
enum SessionStatus {
  /// Configured, not started yet.
  ready,

  /// Counting down; `endsAt` is set.
  running,

  /// Paused; `pausedRemaining` is set.
  paused,

  /// Time is up; stays until acknowledged on the final screen.
  finished,

  /// Stopped before the end; the session is discarded.
  cancelled;

  /// Decodes the persisted name.
  factory fromJson(Object? json) => enumFromJson(values, json, 'status');

  /// Whether a countdown is in progress (running or paused).
  bool get isActive => this == running || this == paused;

  /// Encodes as the enum name.
  String toJson() => name;
}
