import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/core/platform/providers.dart';
import 'package:visual_time_counter/features/settings/application/app_settings_state.dart';
import 'package:visual_time_counter/features/settings/application/settings_controller.dart';
import 'package:visual_time_counter/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:visual_time_counter/features/timer/application/sound_catalog.dart';
import 'package:visual_time_counter/features/timer/presentation/widgets/sound_picker_sheet.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// The "Sound and vibration" section (contracts/ui/06 §6.1): the defaults
/// for the alarm sound, volume, ticking and vibration.
///
/// Keys: `settings.sound`, `settings.tick`, `settings.tickVolume`,
/// `settings.vibrate`.
class SoundSection extends ConsumerWidget {
  /// Creates the section.
  const new({super.key});

  static const _volumeSteps = 20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final defaults = ref.watch(
      appSettingsProvider.select((settings) => settings.defaults),
    );
    final controller = ref.read(settingsControllerProvider);
    final hasVibrator = ref.watch(hapticsProvider).hasVibrator;
    final soundLabel = soundNameOf(
      l10n,
      ref.watch(soundCatalogProvider).value,
      defaults.soundId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionHeader(
          sectionKey: 'sound',
          title: l10n.settingsSectionSound,
        ),
        ListTile(
          key: const Key('settings.sound'),
          title: Text(l10n.presetEditorSound),
          subtitle: Text(soundLabel),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => unawaited(
            showSoundPicker(
              context,
              current: (sound: defaults.soundId, volume: defaults.alarmVolume),
              onChanged: (choice) => controller.changeDefaults(
                (config) => config.copyWith(
                  soundId: choice.sound,
                  alarmVolume: choice.volume,
                ),
              ),
            ),
          ),
        ),
        SwitchListTile(
          key: const Key('settings.tick'),
          title: Text(l10n.presetEditorTick),
          value: defaults.tickEnabled,
          onChanged: (isOn) => controller.changeDefaults(
            (config) => config.copyWith(tickEnabled: isOn),
          ),
        ),
        ListTile(
          title: Text(l10n.settingsTickVolume),
          subtitle: Slider(
            key: const Key('settings.tickVolume'),
            value: defaults.tickVolume,
            divisions: _volumeSteps,
            onChanged: defaults.tickEnabled
                ? (volume) => controller.changeDefaults(
                    (config) => config.copyWith(tickVolume: volume),
                  )
                : null,
          ),
        ),
        if (hasVibrator)
          SwitchListTile(
            key: const Key('settings.vibrate'),
            title: Text(l10n.presetEditorVibrate),
            value: defaults.vibrate,
            onChanged: (isOn) => controller.changeDefaults(
              (config) => config.copyWith(vibrate: isOn),
            ),
          ),
      ],
    );
  }
}
