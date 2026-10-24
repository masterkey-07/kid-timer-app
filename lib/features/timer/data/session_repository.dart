import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:visual_time_counter/core/persistence/migrator.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';

/// The session repository; bootstrap provides it over the opened box.
final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => throw StateError(
    'sessionRepositoryProvider must be overridden in bootstrap',
  ),
);

/// Stores the active timer session in the `session` box under `"timer"`.
///
/// Every write is flushed before it completes, so the session is on disk
/// before an alarm is scheduled (Constitution III).
final class SessionRepository {
  /// Creates a repository over the opened `session` box.
  new(this._box);

  static const _timerKey = 'timer';

  final Box<Map<dynamic, dynamic>> _box;

  /// The saved session, or null when there is none.
  ///
  /// Throws a [FormatException] when the stored document is invalid.
  TimerSession? load() {
    final stored = _box.get(_timerKey);
    return stored == null ? null : TimerSession.fromJson(toDocument(stored));
  }

  /// Writes [session] and flushes it to disk; storage errors propagate.
  Future<void> save(TimerSession session) async {
    await _box.put(_timerKey, session.toJson());
    await _box.flush();
  }

  /// Removes the saved session and flushes.
  Future<void> clear() async {
    await _box.delete(_timerKey);
    await _box.flush();
  }
}
