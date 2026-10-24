import 'package:meta/meta.dart';
import 'package:visual_time_counter/core/domain/json_utils.dart';
import 'package:visual_time_counter/features/images/domain/image_category.dart';

/// An image that can fill the dial (data-model ImageAsset).
@immutable
sealed class ImageAsset {
  const new();

  /// `bank:<category>/<slug>` for the library, a UUID for own images.
  String get id;
}

/// An image of the built-in library, described by the bundled manifest.
final class BankImageAsset extends ImageAsset {
  /// Creates a library image.
  const new({
    required this.id,
    required this.category,
    required this.labels,
    required this.assetPath,
    required this.author,
    required this.license,
    required this.source,
  });

  @override
  final String id;

  /// Its library category.
  final ImageCategory category;

  /// The accessible name per language code; `pt` and `en` always exist
  /// (FR-026).
  final Map<String, String> labels;

  /// The bundled 768×768 WebP.
  final String assetPath;

  /// Who made the original artwork.
  final String author;

  /// Its SPDX license.
  final String license;

  /// Where the original came from.
  final String source;

  /// The name in [languageCode], or in English for other languages.
  String labelFor(String languageCode) =>
      labels[languageCode] ?? labels[_fallbackLanguage]!;

  static const _fallbackLanguage = 'en';

  @override
  bool operator ==(Object other) =>
      other is BankImageAsset && other.id == id && other.assetPath == assetPath;

  @override
  int get hashCode => Object.hash(id, assetPath);

  @override
  String toString() => 'BankImageAsset($id)';
}

/// An image the adult added, stored as a JPEG in the `user_images` box;
/// this is its `user_images_meta` document (contracts/persistence-schema).
final class UserImageAsset extends ImageAsset {
  /// Creates the metadata of an own image.
  const new({
    required this.id,
    required this.createdAt,
    required this.width,
    required this.height,
    required this.byteLength,
    this.label,
  });

  /// Decodes a stored metadata document.
  factory fromJson(Map<String, Object?> json) => UserImageAsset(
    id: readField<String>(json, 'id'),
    label: switch (json['label']) {
      null => null,
      final String label => label,
      final other => throw FormatException('Invalid label: $other'),
    },
    createdAt:
        readOptionalInstant(json, 'createdAt') ??
        (throw const FormatException('Field "createdAt" is required')),
    width: readField<int>(json, 'width'),
    height: readField<int>(json, 'height'),
    byteLength: readField<int>(json, 'byteLength'),
  );

  /// The schema version of the metadata document.
  static const schemaVersion = 1;

  /// The longest label (data-model ImageAsset).
  static const maxLabelLength = 40;

  @override
  final String id;

  /// The adult's name for it, also its accessible label.
  final String? label;

  /// When it was added.
  final DateTime createdAt;

  /// Width in pixels.
  final int width;

  /// Height in pixels.
  final int height;

  /// Size of the stored JPEG.
  final int byteLength;

  /// This image with [label] instead.
  UserImageAsset withLabel(String? label) => UserImageAsset(
    id: id,
    label: label,
    createdAt: createdAt,
    width: width,
    height: height,
    byteLength: byteLength,
  );

  /// Encodes the metadata document.
  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'id': id,
    'label': label,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'width': width,
    'height': height,
    'byteLength': byteLength,
  };

  @override
  bool operator ==(Object other) =>
      other is UserImageAsset &&
      other.id == id &&
      other.label == label &&
      other.createdAt == createdAt &&
      other.width == width &&
      other.height == height &&
      other.byteLength == byteLength;

  @override
  int get hashCode =>
      Object.hash(id, label, createdAt, width, height, byteLength);

  @override
  String toString() => 'UserImageAsset($id, $label)';
}
