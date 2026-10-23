import 'package:visual_time_counter/core/domain/json_utils.dart';

/// The time span a full dial represents (FR-050).
enum DialScale {
  /// 5 minutes.
  min5(Duration(minutes: 5)),

  /// 10 minutes.
  min10(Duration(minutes: 10)),

  /// 15 minutes.
  min15(Duration(minutes: 15)),

  /// 30 minutes.
  min30(Duration(minutes: 30)),

  /// 60 minutes (default).
  min60(Duration(minutes: 60)),

  /// 120 minutes.
  min120(Duration(minutes: 120));

  new(this.span);

  /// Decodes the persisted name.
  factory fromJson(Object? json) => enumFromJson(values, json, 'scale');

  /// The default scale.
  static const DialScale defaultScale = min60;

  /// The duration of a full circle.
  final Duration span;

  /// The share of the circle covered by [remaining], clamped to [0, 1].
  double fractionOf(Duration remaining) =>
      (remaining.inMicroseconds / span.inMicroseconds).clamp(0.0, 1.0);

  /// Encodes as the enum name.
  String toJson() => name;
}
