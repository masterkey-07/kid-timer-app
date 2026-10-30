import 'package:meta/meta.dart';
import 'package:visual_time_counter/core/domain/json_utils.dart';
import 'package:visual_time_counter/core/domain/sound_id.dart';

/// What a bundled sound is used for.
enum SoundKind {
  /// The end-of-timer alarm; the adult picks one.
  alarm,

  /// The once-per-second tick.
  tick,

  /// The soft cue between routine steps.
  transition;

  /// Decodes the manifest name.
  factory fromJson(Object? json) => enumFromJson(values, json, 'kind');
}

/// A bundled sound as listed in `assets/sounds/manifest.json`.
@immutable
final class SoundInfo {
  /// Creates a sound whose [names] has an entry for [fallbackLanguage].
  const new({required this.id, required this.kind, required this.names});

  /// The language used when a name is missing in the requested one.
  static const fallbackLanguage = 'en';

  /// The sound's id; the file is `<id>.wav`.
  final SoundId id;

  /// What the sound is used for.
  final SoundKind kind;

  /// The display name per language code.
  final Map<String, String> names;

  /// The display name in [languageCode], or in English when it has none.
  String nameIn(String languageCode) =>
      names[languageCode] ?? names[fallbackLanguage]!;

  @override
  String toString() => 'SoundInfo(${id.value}, $kind)';
}
