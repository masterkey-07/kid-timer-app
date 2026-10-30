import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/core/domain/sound_info.dart';
import 'package:visual_time_counter/features/timer/data/sound_manifest_loader.dart';

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
