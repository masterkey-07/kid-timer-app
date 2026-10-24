import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:visual_time_counter/app/locale_resolution.dart';
import 'package:visual_time_counter/core/clock/clock_provider.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/platform/alarm/alarm_scheduler.dart';
import 'package:visual_time_counter/core/platform/providers.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/core/timer_engine/timer_engine.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/timer/application/active_session.dart';
import 'package:visual_time_counter/features/timer/data/session_repository.dart';
import 'package:visual_time_counter/features/timer/presentation/spoken_duration.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// Creates the id of each new session (a UUID); tests override it.
final sessionIdGeneratorProvider = Provider<String Function()>(
  (ref) => const Uuid().v4,
);

/// The localized texts of the end-of-timer notification, in the system
/// language (the alarm is scheduled outside any widget).
final timerNotificationTextsProvider = Provider<AppLocalizations>(
  (ref) => lookupAppLocalizations(
    resolveAppLocale(WidgetsBinding.instance.platformDispatcher.locales),
  ),
);

/// The timer session and the actions on it.
final timerControllerProvider =
    NotifierProvider<TimerController, TimerSession?>(TimerController.new);

/// The outcome of a [TimerController] action.
enum TimerActionResult {
  /// The action was applied and saved.
  done,

  /// Another timer is active; the adult must confirm replacing it
  /// (FR-007).
  needsConfirmation,

  /// The session could not be saved, so nothing changed and no alarm was
  /// touched; the UI shows an error.
  storageFailed,
}

/// The deep link a timer notification opens.
const timerNotificationPayload = 'vtc://run';

/// The OS alarm id for [sessionId]: a 32-bit FNV-1a hash kept within 31 bits,
/// stable across runs and platforms (unlike `String.hashCode`).
int alarmIdFor(String sessionId) {
  const fnvOffsetBasis = 0x811c9dc5;
  const fnvPrime = 0x01000193;
  const uint32Mask = 0xffffffff;
  const positiveInt31Mask = 0x7fffffff;

  var hash = fnvOffsetBasis;
  for (final codeUnit in sessionId.codeUnits) {
    hash = ((hash ^ codeUnit) * fnvPrime) & uint32Mask;
  }
  return hash & positiveInt31Mask;
}

/// Owns the timer session: drives [TimerEngine], persists every change and
/// keeps the OS alarm in sync (Constitution III).
///
/// Every action saves the session (with flush) before scheduling or
/// cancelling the alarm, so a crash in between never leaves an alarm
/// without its session or a session that believes in a missing alarm.
class TimerController extends Notifier<TimerSession?> {
  Timer? _endTimer;

  TimerEngine get _engine => TimerEngine(clock: ref.read(clockProvider));

  SessionRepository get _repository => ref.read(sessionRepositoryProvider);

  AlarmScheduler get _alarms => ref.read(alarmSchedulerProvider);

  @override
  TimerSession? build() {
    ref.onDispose(_disarmEndTimer);
    final restored = ref.read(restoredSessionProvider);
    _armEndTimer(restored);
    return restored;
  }

  /// Starts a timer with [config]. With another timer active it returns
  /// [TimerActionResult.needsConfirmation] unless [replaceActive] is true.
  Future<TimerActionResult> start(
    TimerConfig config, {
    SessionOrigin origin = const ManualOrigin(),
    bool replaceActive = false,
  }) async {
    final previous = state;
    final isReplacing = previous?.status.isActive ?? false;
    if (isReplacing && !replaceActive) {
      return TimerActionResult.needsConfirmation;
    }

    final id = ref.read(sessionIdGeneratorProvider)();
    final engine = _engine;
    final session = engine
        .start(engine.create(id: id, config: config, origin: origin))
        .copyWith(scheduledNotificationIds: [alarmIdFor(id)]);
    if (!await _persist(session)) return TimerActionResult.storageFailed;

    if (isReplacing) await _cancelAlarms(previous!);
    await _scheduleEndAlarm(session);
    _become(session);
    return TimerActionResult.done;
  }

  /// Pauses the running timer and cancels its alarm.
  Future<TimerActionResult> pause() async {
    final paused = _engine.pause(state!);
    if (!await _persist(paused)) return TimerActionResult.storageFailed;

    await _cancelAlarms(paused);
    _become(paused);
    return TimerActionResult.done;
  }

  /// Resumes the paused timer and schedules its alarm again.
  Future<TimerActionResult> resume() => _runAgain(_engine.resume(state!));

  /// Runs the full duration again from now.
  Future<TimerActionResult> restart() => _runAgain(_engine.restart(state!));

  /// Stops the timer and discards the session.
  Future<TimerActionResult> cancel() async {
    final session = state!;
    _engine.cancel(session);
    if (!await _clear()) return TimerActionResult.storageFailed;

    await _cancelAlarms(session);
    await ref.read(audioProvider).stopAll();
    _become(null);
    return TimerActionResult.done;
  }

  /// Moves a running session whose end has passed to finished and, with the
  /// app open, rings once (FR-005). Safe to call at any time.
  Future<void> checkTimeUp() async {
    final session = state;
    if (session == null) return;
    final reconciled = _engine.reconcile(session);
    if (identical(reconciled, session)) {
      _armEndTimer(session);
      return;
    }

    _become(reconciled);
    // The final screen must show even if saving fails; on the next launch
    // the stored running session reconciles to finished again.
    await _persist(reconciled);
    await _ring(reconciled.config);
  }

  /// Removes the session's notifications from the tray (contracts/ui/03:
  /// on entering the final screen).
  Future<void> dismissNotifications() async {
    final session = state;
    if (session != null) await _cancelAlarms(session);
  }

  /// Acknowledges the final screen: silences the alarm and clears the
  /// session.
  Future<void> acknowledge() async {
    _engine.acknowledge(state!);
    await ref.read(audioProvider).stopAll();
    // If clearing fails, the next launch shows the final screen once more,
    // which is harmless.
    await _clear();
    _become(null);
  }

  Future<TimerActionResult> _runAgain(TimerSession running) async {
    if (!await _persist(running)) return TimerActionResult.storageFailed;

    await _scheduleEndAlarm(running);
    _become(running);
    return TimerActionResult.done;
  }

  void _become(TimerSession? session) {
    state = session;
    _armEndTimer(session);
  }

  Future<void> _ring(TimerConfig config) async {
    final audio = ref.read(audioProvider);
    await audio.stopTicking();
    if (config.soundId.isAudible) {
      await audio.playAlarm(config.soundId, volume: config.alarmVolume);
    }
    final haptics = ref.read(hapticsProvider);
    if (config.vibrate && haptics.hasVibrator) await haptics.alarmPattern();
  }

  Future<void> _scheduleEndAlarm(TimerSession session) async {
    final texts = ref.read(timerNotificationTextsProvider);
    final result = await _alarms.schedule(
      AlarmRequest(
        id: alarmIdFor(session.id),
        groupKey: session.id,
        fireAtUtc: session.endsAt!,
        kind: AlarmKind.end,
        title: texts.notificationTimerEndTitle,
        body: texts.notificationTimerEndBody(
          spokenDuration(texts, session.config.duration.value),
        ),
        sound: session.config.soundId,
        payload: timerNotificationPayload,
      ),
    );
    // With the app open the end still rings through checkTimeUp; the
    // preflight notices (US2) tell the adult about background limits.
    if (result is Failed) debugPrint('End alarm not scheduled: $result');
  }

  Future<void> _cancelAlarms(TimerSession session) async {
    for (final id in session.scheduledNotificationIds) {
      await _alarms.cancel(id);
    }
  }

  /// Saves [session]; returns false when storage failed.
  Future<bool> _persist(TimerSession session) =>
      _guardStorage(() => _repository.save(session));

  /// Removes the saved session; returns false when storage failed.
  Future<bool> _clear() => _guardStorage(_repository.clear);

  /// Storage errors come from Hive and the file system with no common
  /// type, so every error is caught here, logged and reported to the caller.
  Future<bool> _guardStorage(Future<void> Function() write) async {
    try {
      await write();
      return true;
    } on Object catch (error, stackTrace) {
      debugPrint('Session storage failed: $error\n$stackTrace');
      return false;
    }
  }

  void _armEndTimer(TimerSession? session) {
    _disarmEndTimer();
    if (session == null || session.status != SessionStatus.running) return;
    final remaining = session.remaining(ref.read(clockProvider).now());
    _endTimer = Timer(remaining, () => unawaited(checkTimeUp()));
  }

  void _disarmEndTimer() {
    _endTimer?.cancel();
    _endTimer = null;
  }
}
