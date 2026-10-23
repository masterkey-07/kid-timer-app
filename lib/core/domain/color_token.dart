import 'package:visual_time_counter/core/domain/json_utils.dart';

/// The design-system colors offered for the single color palette (FR-051).
/// Their values live in `lib/app/theme/palettes.dart`.
enum ColorToken {
  /// Blue.
  blue,

  /// Green.
  green,

  /// Yellow.
  yellow,

  /// Orange.
  orange,

  /// Purple.
  purple,

  /// Pink.
  pink,

  /// Teal.
  teal,

  /// Gray.
  gray;

  /// Decodes the persisted name.
  factory fromJson(Object? json) => enumFromJson(values, json, 'singleColor');

  /// Encodes as the enum name.
  String toJson() => name;
}
