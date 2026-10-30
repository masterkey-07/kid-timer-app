import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/core/domain/sound_id.dart';
import 'package:visual_time_counter/core/domain/sound_info.dart';
import 'package:visual_time_counter/features/timer/data/sound_manifest_loader.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// Every bundled sound, read once from the manifest.
final soundCatalogProvider = FutureProvider<List<SoundInfo>>(
  (ref) => const SoundManifestLoader().load(rootBundle),
);

/// The sounds the adult can pick as the alarm, in manifest order.
final alarmSoundsProvider = FutureProvider<List<SoundInfo>>((ref) async {
  final sounds = await ref.watch(soundCatalogProvider.future);
  return [
    for (final sound in sounds)
      if (sound.kind == SoundKind.alarm) sound,
  ];
});

/// The display name of [sound] in the language of [l10n]; the id itself
/// until the catalog has loaded.
String soundName(
  AppLocalizations l10n,
  List<SoundInfo>? catalog,
  SoundId sound,
) {
  if (sound == SoundId.none) return l10n.soundNone;
  final info = catalog?.where((candidate) => candidate.id == sound).firstOrNull;
  return info?.nameIn(l10n.localeName) ?? sound.value;
}
