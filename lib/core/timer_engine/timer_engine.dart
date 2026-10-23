import 'package:clock/clock.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';

/// The timer state machine (data-model TimerSession).
///
/// Pure: it only computes new sessions from the injected [Clock]; persisting
/// them and scheduling alarms is the caller's job.
final class TimerEngine {
  /// Creates an engine reading time from [_clock].
  const new({required this._clock});

  final Clock _clock;

  DateTime get _now => _clock.now().toUtc();

  /// A new session in the ready state.
  TimerSession create({
    required String id,
    required TimerConfig config,
    SessionOrigin origin = const ManualOrigin(),
  }) => TimerSession(
    id: id,
    config: config,
    status: SessionStatus.ready,
    origin: origin,
  );

  /// ready → running: `endsAt = now + duration`.
  TimerSession start(TimerSession session) {
    _require(session, 'start', const {SessionStatus.ready});
    return _running(session, remaining: session.config.duration.value);
  }

  /// running → paused: keeps `endsAt − now` (never negative).
  TimerSession pause(TimerSession session) {
    _require(session, 'pause', const {SessionStatus.running});
    return _with(
      session,
      status: SessionStatus.paused,
      pausedRemaining: session.remaining(_now),
    );
  }

  /// paused → running: `endsAt = now + pausedRemaining`.
  TimerSession resume(TimerSession session) {
    _require(session, 'resume', const {SessionStatus.paused});
    return _running(session, remaining: session.pausedRemaining!);
  }

  /// running or paused → cancelled.
  TimerSession cancel(TimerSession session) {
    _require(session, 'cancel', const {
      SessionStatus.running,
      SessionStatus.paused,
    });
    return _with(session, status: SessionStatus.cancelled);
  }

  /// running, paused or finished → running again with the same config.
  TimerSession restart(TimerSession session) {
    _require(session, 'restart', const {
      SessionStatus.running,
      SessionStatus.paused,
      SessionStatus.finished,
    });
    return _running(
      session,
      remaining: session.config.duration.value,
      startedAt: _now,
    );
  }

  /// running with `now ≥ endsAt` → finished; any other session is returned
  /// unchanged.
  TimerSession reconcile(TimerSession session) {
    if (!session.isOverdue(_now)) return session;
    return _with(
      session,
      status: SessionStatus.finished,
      endsAt: session.endsAt,
    );
  }

  /// Marks a finished session as acknowledged (tap on the final screen).
  TimerSession acknowledge(TimerSession session) {
    _require(session, 'acknowledge', const {SessionStatus.finished});
    return session.copyWith(finishedAcknowledged: true);
  }

  /// The time left now.
  Duration remaining(TimerSession session) => session.remaining(_now);

  /// The remaining share of the duration now, in [0, 1].
  double progress(TimerSession session) => session.progress(_now);

  /// Whether the session is running past its end now.
  bool isOverdue(TimerSession session) => session.isOverdue(_now);

  TimerSession _running(
    TimerSession session, {
    required Duration remaining,
    DateTime? startedAt,
  }) {
    final now = _now;
    return _with(
      session,
      status: SessionStatus.running,
      startedAt: startedAt ?? session.startedAt ?? now,
      endsAt: now.add(remaining),
    );
  }

  /// A copy in [status]; `endsAt` and `pausedRemaining` are cleared unless
  /// given, and the acknowledgement is reset.
  TimerSession _with(
    TimerSession session, {
    required SessionStatus status,
    DateTime? startedAt,
    DateTime? endsAt,
    Duration? pausedRemaining,
  }) => TimerSession(
    id: session.id,
    config: session.config,
    status: status,
    startedAt: startedAt ?? session.startedAt,
    endsAt: endsAt,
    pausedRemaining: pausedRemaining,
    origin: session.origin,
    scheduledNotificationIds: session.scheduledNotificationIds,
  );

  static void _require(
    TimerSession session,
    String action,
    Set<SessionStatus> allowed,
  ) {
    if (!allowed.contains(session.status)) {
      throw InvalidTransition(from: session.status, action: action);
    }
  }
}

/// Thrown when an action is not allowed in the session's current state.
final class InvalidTransition implements Exception {
  /// Creates the exception for [action] attempted in [from].
  const new({required this.from, required this.action});

  /// The state the session was in.
  final SessionStatus from;

  /// The attempted action.
  final String action;

  @override
  String toString() => 'InvalidTransition: cannot $action from $from';
}
