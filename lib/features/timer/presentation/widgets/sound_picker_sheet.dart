import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/core/domain/sound_id.dart';
import 'package:visual_time_counter/core/platform/audio/audio_port.dart';
import 'package:visual_time_counter/core/platform/providers.dart';
import 'package:visual_time_counter/features/timer/application/sound_catalog.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// The alarm sound and volume together: the sheet reports both on every
/// change, so a caller holding an older config never undoes the other half.
typedef SoundChoice = ({SoundId sound, double volume});

/// Opens the [SoundPickerSheet] as a modal bottom sheet. [onChanged] fires
/// on every change, so the caller applies choices as they are made.
Future<void> showSoundPicker(
  BuildContext context, {
  required SoundChoice current,
  required ValueChanged<SoundChoice> onChanged,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) =>
      SoundPickerSheet(current: current, onChanged: onChanged),
);

/// The alarm sound list with preview and volume (contracts/ui/01 "Sound",
/// contracts/ui/06; FR-052).
///
/// Tapping a sound chooses and previews it at the chosen volume; another
/// preview replaces the previous one, and closing the sheet stops it.
///
/// Keys: `soundPicker.sound.<id>`, `soundPicker.preview.<id>`,
/// `soundPicker.volume`.
class SoundPickerSheet extends ConsumerStatefulWidget {
  /// Creates the sheet showing the [current] choice.
  const new({required this.current, required this.onChanged, super.key});

  /// The sound and volume (0.0–1.0) when the sheet opens.
  final SoundChoice current;

  /// Called when the adult chooses a sound or moves the volume slider.
  final ValueChanged<SoundChoice> onChanged;

  @override
  ConsumerState<SoundPickerSheet> createState() => _SoundPickerSheetState();
}

class _SoundPickerSheetState extends ConsumerState<SoundPickerSheet> {
  static const _volumeSteps = 20;
  static const _padding = 16.0;

  // Captured up front: dispose cannot read providers.
  late final AudioPort _audio;

  late SoundId _selected = widget.current.sound;
  late double _volume = widget.current.volume;

  @override
  void initState() {
    super.initState();
    _audio = ref.read(audioProvider);
  }

  @override
  void dispose() {
    unawaited(_audio.stopPreview());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(alarmSoundsProvider).value ?? const [];
    final sounds = [for (final info in catalog) info.id, SoundId.none];

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(0, 0, 0, _padding),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _padding),
            child: Text(
              l10n.soundPickerTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final sound in sounds)
            _SoundRow(
              sound: sound,
              name: soundNameOf(l10n, catalog, sound),
              isSelected: sound == _selected,
              onChoose: () => _choose(sound),
              onPreview: () => _preview(sound),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _padding),
            child: Semantics(
              label: l10n.soundPickerVolume,
              child: Slider(
                key: const Key('soundPicker.volume'),
                value: _volume,
                divisions: _volumeSteps,
                onChanged: _changeVolume,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _choose(SoundId sound) {
    setState(() => _selected = sound);
    widget.onChanged((sound: sound, volume: _volume));
    _preview(sound);
  }

  void _preview(SoundId sound) {
    if (!sound.isAudible) {
      unawaited(_audio.stopPreview());
      return;
    }
    unawaited(_audio.playPreview(sound, volume: _volume));
  }

  void _changeVolume(double volume) {
    setState(() => _volume = volume);
    widget.onChanged((sound: _selected, volume: volume));
  }
}

class _SoundRow extends StatelessWidget {
  const new({
    required this.sound,
    required this.name,
    required this.isSelected,
    required this.onChoose,
    required this.onPreview,
  });

  final SoundId sound;
  final String name;
  final bool isSelected;
  final VoidCallback onChoose;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      key: Key('soundPicker.sound.${sound.value}'),
      selected: isSelected,
      leading: Icon(
        isSelected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_unchecked_rounded,
      ),
      title: Text(name),
      trailing: sound.isAudible
          ? IconButton(
              key: Key('soundPicker.preview.${sound.value}'),
              tooltip: l10n.soundPickerPlay(name),
              icon: const Icon(Icons.volume_up_rounded),
              onPressed: onPreview,
            )
          : null,
      onTap: onChoose,
    );
  }
}
