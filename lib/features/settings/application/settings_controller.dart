import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/features/settings/application/app_settings_state.dart';

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
}
