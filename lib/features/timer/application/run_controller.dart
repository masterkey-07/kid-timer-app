import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/core/platform/alarm/alarm_scheduler.dart';
import 'package:visual_time_counter/core/platform/audio/audio_port.dart';
import 'package:visual_time_counter/core/platform/fullscreen/fullscreen_port.dart';
import 'package:visual_time_counter/core/platform/providers.dart';
import 'package:visual_time_counter/core/platform/wakelock/wakelock_port.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/settings/application/app_settings_state.dart';
import 'package:visual_time_counter/features/timer/application/timer_controller.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// The countdown's side effects, alive while `/run` shows an active timer:
/// the countdown screen watches it.
final Provider<RunController> runControllerProvider =
    Provider.autoDispose<RunController>((ref) {
      final controller = RunController._(ref);
      ref.onDispose(controller._leave);
      controller._enter();
      return controller;
    });

/// Keeps the screen on, enters full screen, ticks and keeps the end ringing
/// exactly once (contracts/ui/02 Behavior 1, 5 and 6; FR-014).
///
/// On Android and Windows the OS alarm is cancelled while the app is in
/// front, where the app rings by itself, and scheduled again whenever it
/// leaves the front. Apple platforms keep it scheduled with no foreground
/// presentation; Web and Linux have none.
class RunController {
  new _(this._ref)
    : _alarms = _ref.read(alarmSchedulerProvider),
      _notificationTexts = _ref.read(timerNotificationTextsProvider),
      _wakeLock = _ref.read(wakeLockProvider),
      _fullscreen = _ref.read(fullscreenProvider),
      _audio = _ref.read(audioProvider),
      _cancelsOsAlarmInFront = switch (_ref.read(appPlatformProvider)) {
        AppPlatform.android || AppPlatform.windows => true,
        AppPlatform.ios ||
        AppPlatform.macos ||
        AppPlatform.linux ||
        AppPlatform.web => false,
      };

  final Ref _ref;

  // Captured up front: the alarm calls also run while this provider is
  // disposed, where Riverpod forbids reading other providers.
  final AlarmScheduler _alarms;
  final AppLocalizations _notificationTexts;
  final WakeLockPort _wakeLock;
  final FullscreenPort _fullscreen;
  final AudioPort _audio;
  final bool _cancelsOsAlarmInFront;

  StreamSubscription<AppLifecycleState>? _lifecycle;
  TimerSession? _session;
  bool _isInFront = true;
  bool _enteredFullscreen = false;

  bool get _isRunning => _session?.status == SessionStatus.running;

  /// The screen opens in front, right after Start or a launch into `/run`.
  void _enter() {
    _lifecycle = _ref.read(appLifecycleProvider).states.listen(_onLifecycle);
    _ref.listen<TimerSession?>(timerControllerProvider, _onSessionChanged);

    unawaited(_wakeLock.enable());
    if (_ref.read(appSettingsProvider).childLockEnabled &&
        _fullscreen.isSupported) {
      _enteredFullscreen = true;
      unawaited(_fullscreen.enter());
    }

    final session = _ref.read(timerControllerProvider);
    if (session != null) unawaited(_audio.preload([session.config.soundId]));
    _onSessionChanged(null, session);
  }

  void _leave() {
    unawaited(_lifecycle?.cancel());
    unawaited(_audio.stopTicking());
    if (_enteredFullscreen) unawaited(_fullscreen.exit());
    // The final screen keeps the screen on by itself.
    if (_session?.status != SessionStatus.finished) {
      unawaited(_wakeLock.disable());
    }
    // A timer still running must not be left without its OS alarm.
    if (_isRunning && _cancelsOsAlarmInFront) _scheduleOsAlarm();
  }

  void _onSessionChanged(TimerSession? previous, TimerSession? next) {
    _session = next;
    final wasRunning = previous?.status == SessionStatus.running;
    // TimerController only sets a new running session after starting,
    // resuming or restarting, each of which scheduled the OS alarm.
    final startedRunning = _isRunning && !identical(previous, next);

    if (startedRunning) {
      final config = next!.config;
      if (config.tickEnabled) {
        unawaited(_audio.startTicking(volume: config.tickVolume));
      }
      if (_cancelsOsAlarmInFront && _isInFront) _cancelOsAlarms();
    } else if (wasRunning && !_isRunning) {
      unawaited(_audio.stopTicking());
    }
  }

  void _onLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isInFront = true;
        if (_isRunning && _cancelsOsAlarmInFront) _cancelOsAlarms();
      case AppLifecycleState.inactive ||
          AppLifecycleState.hidden ||
          AppLifecycleState.paused:
        // inactive, hidden and paused arrive in a row; schedule once.
        if (!_isInFront) return;
        _isInFront = false;
        if (_isRunning && _cancelsOsAlarmInFront) _scheduleOsAlarm();
      case AppLifecycleState.detached:
        break;
    }
  }

  /// The session is already saved, so scheduling may happen at any time.
  void _scheduleOsAlarm() =>
      unawaited(scheduleEndAlarm(_alarms, _session!, _notificationTexts));

  void _cancelOsAlarms() {
    for (final id in _session!.scheduledNotificationIds) {
      unawaited(_alarms.cancel(id));
    }
  }
}
