import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:visual_time_counter/core/domain/json_utils.dart';
import 'package:visual_time_counter/features/images/domain/image_asset.dart';
import 'package:visual_time_counter/features/images/domain/image_category.dart';

/// Reads the built-in library from `assets/images/bank/manifest.json`, as
/// written by `tool/image_bank` (research R9).
final class BankManifestLoader {
  /// Creates the loader.
  const new();

  static const _bankDirectory = 'assets/images/bank';
  static const _manifestPath = '$_bankDirectory/manifest.json';
  static const _schemaVersion = 1;
  static const _requiredLanguages = ['pt', 'en'];

  /// Loads the manifest from [bundle].
  Future<List<BankImageAsset>> load(AssetBundle bundle) async =>
      parse(await bundle.loadString(_manifestPath));

  /// Decodes [manifestJson], keeping its order; throws a [FormatException]
  /// when an entry is invalid.
  static List<BankImageAsset> parse(String manifestJson) {
    final manifest = jsonDecode(manifestJson);
    if (manifest is! Map<String, Object?>) {
      throw const FormatException('The manifest must be a JSON object');
    }
    final version = manifest['schemaVersion'];
    if (version != _schemaVersion) {
      throw FormatException('Unsupported manifest version: $version');
    }
    return [
      for (final entry in readField<List<Object?>>(manifest, 'images'))
        _imageFrom(entry),
    ];
  }

  static BankImageAsset _imageFrom(Object? entry) {
    if (entry is! Map<String, Object?>) {
      throw FormatException('Invalid manifest entry: $entry');
    }
    final id = readField<String>(entry, 'id');
    final names = readObject(entry, 'names');
    final labels = {
      for (final MapEntry(:key, :value) in names.entries)
        if (value is String && value.trim().isNotEmpty) key: value,
    };
    for (final language in _requiredLanguages) {
      if (!labels.containsKey(language)) {
        throw FormatException('$id has no "$language" name');
      }
    }

    return BankImageAsset(
      id: id,
      category: ImageCategory.fromJson(entry['category']),
      labels: Map.unmodifiable(labels),
      assetPath: '$_bankDirectory/${readField<String>(entry, 'file')}',
      author: readField<String>(entry, 'author'),
      license: readField<String>(entry, 'license'),
      source: readField<String>(entry, 'source'),
    );
  }
}
