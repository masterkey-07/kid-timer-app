import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:visual_time_counter/core/domain/json_utils.dart';
import 'package:visual_time_counter/core/domain/sound_id.dart';
import 'package:visual_time_counter/core/domain/sound_info.dart';

/// Reads the bundled sounds from `assets/sounds/manifest.json`, checked in
/// CI by `tool/sounds/check_sounds.dart`.
final class SoundManifestLoader {
  /// Creates the loader.
  const new();

  static const _manifestPath = 'assets/sounds/manifest.json';
  static const _schemaVersion = 1;
  static const _requiredLanguages = ['pt', 'en'];

  /// Loads the manifest from [bundle].
  Future<List<SoundInfo>> load(AssetBundle bundle) async =>
      parse(await bundle.loadString(_manifestPath));

  /// Decodes [manifestJson], keeping its order; throws a [FormatException]
  /// when an entry is invalid.
  static List<SoundInfo> parse(String manifestJson) {
    final manifest = jsonDecode(manifestJson);
    if (manifest is! Map<String, Object?>) {
      throw const FormatException('The manifest must be a JSON object');
    }
    final version = manifest['schemaVersion'];
    if (version != _schemaVersion) {
      throw FormatException('Unsupported manifest version: $version');
    }
    return [
      for (final entry in readField<List<Object?>>(manifest, 'sounds'))
        _soundFrom(entry),
    ];
  }

  static SoundInfo _soundFrom(Object? entry) {
    if (entry is! Map<String, Object?>) {
      throw FormatException('Invalid manifest entry: $entry');
    }
    final id = readField<String>(entry, 'id');
    final names = {
      for (final MapEntry(:key, :value) in readObject(entry, 'names').entries)
        if (value is String && value.trim().isNotEmpty) key: value,
    };
    for (final language in _requiredLanguages) {
      if (!names.containsKey(language)) {
        throw FormatException('$id has no "$language" name');
      }
    }
    return SoundInfo(
      id: SoundId(id),
      kind: SoundKind.fromJson(entry['kind']),
      names: Map.unmodifiable(names),
    );
  }
}
