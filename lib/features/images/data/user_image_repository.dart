import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:uuid/uuid.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';
import 'package:visual_time_counter/core/persistence/migrator.dart';
import 'package:visual_time_counter/features/images/domain/image_asset.dart';
import 'package:visual_time_counter/features/images/domain/image_processor.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';

/// The boxes holding own images; bootstrap provides them.
final userImageStorageProvider = Provider<UserImageStorage>(
  (ref) => throw StateError(
    'userImageStorageProvider must be overridden in bootstrap',
  ),
);

/// Creates the id of each new own image (a UUID); tests override it.
final userImageIdGeneratorProvider = Provider<String Function()>(
  (ref) => const Uuid().v4,
);

/// The boxes an own image lives in, and the presets that may use it.
@immutable
final class UserImageStorage {
  /// Groups the opened boxes.
  const new({required this.meta, required this.bytes, required this.presets});

  /// `user_images_meta`: one [UserImageAsset] document per image.
  final Box<Map<dynamic, dynamic>> meta;

  /// `user_images`: the JPEG of each image.
  final LazyBox<Uint8List> bytes;

  /// `presets`: read and rewritten when an image is deleted.
  final Box<Map<dynamic, dynamic>> presets;
}

/// Thrown when adding an image beyond [UserImageRepository.maxImages].
final class UserImageLimitReached implements Exception {
  /// Creates the error.
  const new();

  @override
  String toString() => 'UserImageLimitReached';
}

/// Where an own image is used.
@immutable
final class ImageReferences {
  /// Creates the references.
  const new({
    required this.presetNames,
    required this.isInDefaults,
    required this.isInLastConfig,
  });

  /// The presets showing the image, in storage order.
  final List<String> presetNames;

  /// Whether the settings' default config shows it.
  final bool isInDefaults;

  /// Whether the last used config shows it.
  final bool isInLastConfig;

  /// How many places use it.
  int get count =>
      presetNames.length + (isInDefaults ? 1 : 0) + (isInLastConfig ? 1 : 0);
}

/// Stores own images (contracts/persistence-schema): the bytes in
/// `user_images` and the metadata in `user_images_meta`, written bytes
/// first and deleted metadata first so the metadata never points at
/// missing bytes; startup removes whatever a crash left half done.
final class UserImageRepository {
  /// Creates the repository; settings are read and changed through the
  /// callbacks so the in-memory settings stay the source of truth.
  new({
    required this._meta,
    required this._bytes,
    required this._presets,
    required this._readSettings,
    required this._updateSettings,
    required this._clock,
    required this._newId,
  });

  /// The most own images the app keeps (FR-024).
  static const maxImages = 50;

  final Box<Map<dynamic, dynamic>> _meta;
  final LazyBox<Uint8List> _bytes;
  final Box<Map<dynamic, dynamic>> _presets;
  final AppSettings Function() _readSettings;
  final Future<void> Function(AppSettings Function(AppSettings current))
  _updateSettings;
  final Clock _clock;
  final String Function() _newId;

  /// How many images are stored.
  int get count => _meta.length;

  /// The images, oldest first; unreadable documents are left out (startup
  /// removes them).
  List<UserImageAsset> list() =>
      _meta.keys.map((key) => find('$key')).nonNulls.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  /// The image with [id], or null when there is none or it is unreadable.
  UserImageAsset? find(String id) {
    final stored = _meta.get(id);
    return stored == null ? null : _readMeta(id, stored);
  }

  /// The JPEG of the image with [id], or null when there is none.
  Future<Uint8List?> readBytes(String id) => _bytes.get(id);

  /// Stores [image] under a new id; throws [UserImageLimitReached] at the
  /// limit and an [ArgumentError] for a label over 40 characters. When a
  /// write fails, nothing of the image is left behind and the error
  /// propagates.
  Future<UserImageAsset> add(ProcessedImage image, {String? label}) async {
    final normalizedLabel = _normalizeLabel(label);
    if (count >= maxImages) throw const UserImageLimitReached();

    final asset = UserImageAsset(
      id: _newId(),
      label: normalizedLabel,
      createdAt: _clock.now().toUtc(),
      width: image.width,
      height: image.height,
      byteLength: image.jpegBytes.length,
    );
    await _bytes.put(asset.id, image.jpegBytes);
    await _bytes.flush();
    try {
      await _writeMeta(asset);
    } on Object {
      await _bytes.delete(asset.id);
      await _bytes.flush();
      rethrow;
    }
    return asset;
  }

  /// Gives the image with [id] a new [label] (blank clears it).
  Future<void> rename(String id, String? label) async {
    final image = find(id);
    if (image == null) return;
    await _writeMeta(image.withLabel(_normalizeLabel(label)));
  }

  /// Where the image with [id] is used.
  ImageReferences referencesTo(String id) {
    final source = UserImageSource(id);
    final settings = _readSettings();
    return ImageReferences(
      presetNames: [
        for (final preset in _readablePresets())
          if (preset.config.visual == source) preset.name,
      ],
      isInDefaults: settings.defaults.visual == source,
      isInLastConfig: settings.lastConfig.visual == source,
    );
  }

  /// Deletes the image with [id]; the presets and settings that showed it
  /// switch to the default palette first (FR-024).
  Future<void> delete(String id) async {
    await _switchReferencesToColors(UserImageSource(id));
    await _meta.delete(id);
    await _meta.flush();
    await _bytes.delete(id);
    await _bytes.flush();
  }

  /// Removes bytes without metadata, and metadata without bytes or that
  /// cannot be read; returns how many images were affected. Runs at
  /// startup, before the app reads either box.
  static Future<int> removeOrphans({
    required Box<Map<dynamic, dynamic>> meta,
    required LazyBox<Uint8List> bytes,
  }) async {
    final byteIds = bytes.keys.map((key) => '$key').toSet();
    final validMetaIds = {
      for (final key in meta.keys)
        if (byteIds.contains('$key') &&
            _readMeta('$key', meta.get(key)!) != null)
          '$key',
    };
    final orphans = {
      ...meta.keys.map((key) => '$key'),
      ...byteIds,
    }.difference(validMetaIds);

    for (final id in orphans) {
      await meta.delete(id);
      await bytes.delete(id);
    }
    if (orphans.isNotEmpty) {
      debugPrint('Removed ${orphans.length} incomplete own images');
      await meta.flush();
      await bytes.flush();
    }
    return orphans.length;
  }

  static UserImageAsset? _readMeta(String id, Map<dynamic, dynamic> stored) {
    try {
      return UserImageAsset.fromJson(toDocument(stored));
    } on FormatException catch (error) {
      debugPrint('Unreadable own image metadata $id: $error');
      return null;
    }
  }

  Future<void> _writeMeta(UserImageAsset image) async {
    await _meta.put(image.id, image.toJson());
    await _meta.flush();
  }

  static String? _normalizeLabel(String? label) {
    final trimmed = label?.trim() ?? '';
    if (trimmed.length > UserImageAsset.maxLabelLength) {
      throw ArgumentError.value(
        label,
        'label',
        'must be at most ${UserImageAsset.maxLabelLength} characters',
      );
    }
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _switchReferencesToColors(UserImageSource source) async {
    for (final preset in _readablePresets()) {
      if (preset.config.visual != source) continue;
      await _presets.put(preset.key, {
        ...preset.document,
        'config': _withColors(preset.config).toJson(),
        'updatedAt': _clock.now().toUtc().toIso8601String(),
      });
    }
    await _presets.flush();

    final settings = _readSettings();
    final usesImage =
        settings.defaults.visual == source ||
        settings.lastConfig.visual == source;
    if (!usesImage) return;
    await _updateSettings(
      (current) => current.copyWith(
        defaults: current.defaults.visual == source
            ? _withColors(current.defaults)
            : current.defaults,
        lastConfig: current.lastConfig.visual == source
            ? _withColors(current.lastConfig)
            : current.lastConfig,
      ),
    );
  }

  static TimerConfig _withColors(TimerConfig config) =>
      config.copyWith(visual: VisualSource.defaultSource);

  /// Presets as raw documents: the presets feature (US5) owns their model;
  /// only the name and config matter here.
  Iterable<_StoredPreset> _readablePresets() sync* {
    for (final key in _presets.keys) {
      final document = toDocument(_presets.get(key)!);
      try {
        yield _StoredPreset(
          key: key,
          document: document,
          name: document['name']! as String,
          config: TimerConfig.fromJson(
            document['config']! as Map<String, Object?>,
          ),
        );
      } on Object catch (error) {
        debugPrint('Skipping unreadable preset $key: $error');
      }
    }
  }
}

final class _StoredPreset {
  const new({
    required this.key,
    required this.document,
    required this.name,
    required this.config,
  });

  final Object? key;
  final Map<String, Object?> document;
  final String name;
  final TimerConfig config;
}
