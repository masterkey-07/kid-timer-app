import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/domain/timer_duration.dart';
import 'package:visual_time_counter/features/settings/application/app_settings_state.dart';

/// The configuration being set up on the home screen.
final setupConfigProvider =
    NotifierProvider<SetupConfigController, TimerConfig>(
      SetupConfigController.new,
    );

/// Holds the home screen configuration, starting from the last one used,
/// and remembers it as `lastConfig` (FR-006).
class SetupConfigController extends Notifier<TimerConfig> {
  /// How long changes settle before `lastConfig` is written, so dragging the
  /// dial does not write on every frame (contracts/ui/01).
  static const saveDebounce = Duration(milliseconds: 300);

  Timer? _pendingSave;

  @override
  TimerConfig build() {
    ref.onDispose(() => _pendingSave?.cancel());
    return ref.read(appSettingsProvider).lastConfig;
  }

  /// Replaces the configuration.
  void change(TimerConfig config) {
    state = config;
    _pendingSave?.cancel();
    _pendingSave = Timer(saveDebounce, _saveLastConfig);
  }

  /// Sets the duration, keeping the rest of the configuration.
  void setDuration(TimerDuration duration) =>
      change(state.copyWith(duration: duration));

  void _saveLastConfig() {
    final config = state;
    unawaited(
      ref
          .read(appSettingsProvider.notifier)
          .update((settings) => settings.copyWith(lastConfig: config))
          .catchError(
            // Losing lastConfig only costs the adult a re-setup; the timer
            // itself is unaffected, so the failure is logged, not shown.
            (Object error) => debugPrint('Could not save lastConfig: $error'),
          ),
    );
  }
}
