import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/features/timer/application/setup_config_controller.dart';
import 'package:visual_time_counter/features/timer/application/sound_catalog.dart';
import 'package:visual_time_counter/features/timer/presentation/widgets/sound_picker_sheet.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// The home chip naming the alarm sound (contracts/ui/01): opens the
/// [SoundPickerSheet].
class SoundChip extends ConsumerWidget {
  /// Creates the chip for the setup's current sound.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final config = ref.watch(setupConfigProvider);
    final name = soundNameOf(
      l10n,
      ref.watch(soundCatalogProvider).value,
      config.soundId,
    );
    return ActionChip(
      key: const Key('home.soundPicker'),
      avatar: const Icon(Icons.volume_up_rounded),
      label: Text(l10n.homeSound(name), overflow: TextOverflow.ellipsis),
      onPressed: () => unawaited(
        showSoundPicker(
          context,
          current: (sound: config.soundId, volume: config.alarmVolume),
          onChanged: (choice) => ref
              .read(setupConfigProvider.notifier)
              .change(
                ref
                    .read(setupConfigProvider)
                    .copyWith(
                      soundId: choice.sound,
                      alarmVolume: choice.volume,
                    ),
              ),
        ),
      ),
    );
  }
}
