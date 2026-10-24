import 'package:visual_time_counter/core/domain/json_utils.dart';

/// A category of the built-in library (FR-020), in the picker's tab order.
enum ImageCategory {
  /// Brushing teeth, bath, washing hands.
  hygiene,

  /// Meals and snacks.
  meal,

  /// Toys and games.
  play,

  /// Sleep and quiet time.
  rest,

  /// School and homework.
  school,

  /// Getting ready to go out and outings.
  goingOut;

  /// Decodes the manifest name.
  factory fromJson(Object? json) => enumFromJson(values, json, 'category');

  /// Encodes as the enum name.
  String toJson() => name;
}
