import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/core/a11y/announce_throttle.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/features/settings/application/app_settings_state.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';

/// The rules behind the settings screen (contracts/ui/06).
final settingsControllerProvider = Provider<SettingsController>(
  SettingsController.new,
);

/// Changes the adult's preferences, asking first where a change weakens
/// the child's protection.
class SettingsController {
  /// Creates the controller over [_ref].
  const new(this._ref);

  final Ref _ref;

  /// Turns the child lock on or off (FR-032). Turning it off only happens
  /// once [confirmTurnOff] resolves true, since the child will then be able
  /// to pause the timer. Returns whether the setting changed; storage
  /// errors propagate.
  Future<bool> setChildLockEnabled({
    required bool isEnabled,
    required Future<bool> Function() confirmTurnOff,
  }) async {
    if (!isEnabled && !await confirmTurnOff()) return false;
    await _ref
        .read(appSettingsProvider.notifier)
        .update((settings) => settings.copyWith(childLockEnabled: isEnabled));
    return true;
  }

  /// Sets the theme preference.
  Future<void> setThemeMode(AppThemeMode themeMode) =>
      _update((settings) => settings.copyWith(themeMode: themeMode));

  /// Sets how often screen readers hear the remaining time.
  Future<void> setA11yAnnounceInterval(AnnounceInterval interval) =>
      _update((settings) => settings.copyWith(a11yAnnounceInterval: interval));

  /// Changes the configuration new timers start from. The home screen's
  /// last configuration follows while it still equals the old default, so
  /// the adult sees the change without having to touch the dial.
  Future<void> changeDefaults(
    TimerConfig Function(TimerConfig defaults) change,
  ) => _update((settings) {
    final newDefaults = change(settings.defaults);
    final isLastConfigUntouched = settings.lastConfig == settings.defaults;
    return settings.copyWith(
      defaults: newDefaults,
      lastConfig: isLastConfigUntouched ? newDefaults : settings.lastConfig,
    );
  });

  Future<void> _update(AppSettings Function(AppSettings current) change) =>
      _ref.read(appSettingsProvider.notifier).update(change);
}
