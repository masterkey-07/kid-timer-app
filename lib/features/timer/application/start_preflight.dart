import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/core/platform/alarm/alarm_scheduler.dart';
import 'package:visual_time_counter/core/platform/providers.dart';
import 'package:visual_time_counter/features/settings/application/app_settings_state.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';
import 'package:visual_time_counter/features/timer/application/background_alarm_notice.dart';

/// The adult's answer to the notifications-denied dialog.
enum NotificationsDeniedChoice {
  /// Open the app notification settings, then start.
  openSettings,

  /// Start without notifications.
  continueAnyway,
}

/// The adult's answer to the exact alarm explanation.
enum ExactAlarmChoice {
  /// Open the "Alarms & reminders" setting, then start.
  allow,

  /// Start with inexact scheduling.
  notNow,
}

/// The dialogs and notices the preflight shows; the UI implements them
/// (`preflight_dialogs.dart`). Each future completes when the adult
/// answers.
abstract interface class PreflightPrompts {
  /// "Keep this window open" (no OS scheduling).
  Future<void> showKeepOpen();

  /// "Without notifications, the alarm only rings with the app open".
  Future<NotificationsDeniedChoice> showNotificationsDenied();

  /// Why the exact alarm permission matters (Android 12–13).
  Future<ExactAlarmChoice> showExactAlarm();

  /// Silent mode silences the alarm with the app closed (iOS).
  Future<void> showIosSilent();

  /// A brief, non-blocking notice that the volume is at zero.
  void showVolumeZero();
}

/// Checks what the alarm can do before a timer starts.
final startPreflightProvider = Provider<StartPreflight>(StartPreflight.new);

/// Walks the contracts/ui/08 §8.1 tree before a timer starts, so the adult
/// knows when the alarm may not ring (Constitution VI).
///
/// It never blocks the start: once each dialog is answered the timer
/// starts, and one-time answers are stored in [OnboardingFlags].
class StartPreflight {
  /// Creates the preflight.
  const new(this._ref);

  final Ref _ref;

  AlarmScheduler get _alarms => _ref.read(alarmSchedulerProvider);

  /// Runs the checks in the contract order, showing [prompts] as needed.
  Future<void> run(PreflightPrompts prompts) async {
    final capabilities = await _alarms.capabilities();

    if (capabilities.scheduling == SchedulingSupport.unsupported) {
      await _keepOpen(prompts);
    }
    await _notifications(capabilities.notifications, prompts);
    if (capabilities.exactAlarm == PermissionState.denied) {
      await _exactAlarm(prompts);
    }
    if (_ref.read(appPlatformProvider) == AppPlatform.ios &&
        !capabilities.bypassesSilentMode) {
      await _iosSilent(prompts);
    }
    if (await _ref.read(audioProvider).systemVolume() == 0) {
      prompts.showVolumeZero();
    }

    // The answers may have changed what the banner should say.
    _ref.invalidate(backgroundAlarmNoticeProvider);
  }

  Future<void> _keepOpen(PreflightPrompts prompts) async {
    if (_flags.webKeepOpenSeen) return;
    await prompts.showKeepOpen();
    await _saveFlags((flags) => flags.copyWith(webKeepOpenSeen: true));
  }

  /// Asks the OS when it never asked, and explains a refusal on every
  /// start: no flag can make a denied alarm safe.
  Future<void> _notifications(
    PermissionState permission,
    PreflightPrompts prompts,
  ) async {
    final current = permission == PermissionState.notDetermined
        ? await _alarms.requestNotificationPermission()
        : permission;
    if (current != PermissionState.denied) return;

    final choice = await prompts.showNotificationsDenied();
    if (choice == NotificationsDeniedChoice.openSettings) {
      await _ref.read(systemSettingsProvider).openAppNotificationSettings();
    }
  }

  Future<void> _exactAlarm(PreflightPrompts prompts) async {
    if (_flags.exactAlarmExplained) return;
    final choice = await prompts.showExactAlarm();
    await _saveFlags((flags) => flags.copyWith(exactAlarmExplained: true));
    if (choice != ExactAlarmChoice.allow) return;

    // Listen before leaving the app so the return is never missed; run()
    // then re-checks the capabilities through the banner.
    final returned = _ref
        .read(appLifecycleProvider)
        .states
        .firstWhere((state) => state == AppLifecycleState.resumed);
    if (await _alarms.openExactAlarmSettings()) {
      await returned;
    } else {
      returned.ignore();
    }
  }

  Future<void> _iosSilent(PreflightPrompts prompts) async {
    if (_flags.iosSilentWarned) return;
    await prompts.showIosSilent();
    await _saveFlags((flags) => flags.copyWith(iosSilentWarned: true));
  }

  OnboardingFlags get _flags => _ref.read(appSettingsProvider).onboarding;

  /// Saves a one-time answer. If storage fails the answer still holds for
  /// this run; the dialog shows once more next launch, which is harmless.
  Future<void> _saveFlags(
    OnboardingFlags Function(OnboardingFlags flags) change,
  ) async {
    try {
      await _ref
          .read(appSettingsProvider.notifier)
          .update(
            (settings) =>
                settings.copyWith(onboarding: change(settings.onboarding)),
          );
    } on Object catch (error) {
      debugPrint('Could not save a preflight answer: $error');
    }
  }
}
