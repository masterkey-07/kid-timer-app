import 'package:visual_time_counter/core/domain/json_utils.dart';

/// How an image on the dial changes as time passes (FR-081; only [reveal] in
/// v1.0).
enum ImageEffect {
  /// The image fills in the elapsed sector (default).
  reveal,

  /// The image shrinks with the remaining sector (v1.x).
  vanish,

  /// The image gets progressively sharper (v1.x).
  mosaic,

  /// A 4-piece puzzle completes as time passes (v1.x).
  puzzle4,

  /// A 9-piece puzzle (v1.x).
  puzzle9,

  /// A 16-piece puzzle (v1.x).
  puzzle16;

  /// Decodes the persisted name.
  factory fromJson(Object? json) => enumFromJson(values, json, 'imageEffect');

  /// Encodes as the enum name.
  String toJson() => name;
}
