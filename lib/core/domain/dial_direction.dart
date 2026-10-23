import 'package:visual_time_counter/core/domain/json_utils.dart';

/// The direction in which the remaining sector shrinks (FR-050).
enum DialDirection {
  /// Shrinks clockwise (default).
  clockwise,

  /// Shrinks counter-clockwise.
  counterClockwise;

  /// Decodes the persisted name.
  factory fromJson(Object? json) => enumFromJson(values, json, 'direction');

  /// Encodes as the enum name.
  String toJson() => name;
}
