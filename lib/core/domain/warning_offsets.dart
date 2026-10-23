import 'package:meta/meta.dart';

/// Warnings before the end, in minutes (FR-080; v1.x).
@immutable
final class WarningOffsets {
  /// Creates offsets; throws an [ArgumentError] for more than [maxCount]
  /// values or values outside [allowedMinutes].
  factory(Set<int> minutes) {
    final violation = _violationOf(minutes);
    if (violation != null) {
      throw ArgumentError.value(minutes, 'minutes', violation);
    }
    return WarningOffsets._(Set.unmodifiable(minutes));
  }

  /// Decodes the persisted list of minutes.
  factory fromJson(Object? json) {
    if (json is! List || json.any((value) => value is! int)) {
      throw FormatException('warningsMin must be a list of ints: $json');
    }
    final minutes = json.cast<int>().toSet();
    final violation = _violationOf(minutes);
    if (violation != null) throw FormatException(violation, json);
    return WarningOffsets._(Set.unmodifiable(minutes));
  }

  const new _(this.minutes);

  /// No warnings (default).
  static const none = WarningOffsets._({});

  /// The minute values a warning can use.
  static const allowedMinutes = {1, 2, 5, 10};

  /// The most warnings per timer (keeps a 20-step routine at ≤ 60 pending
  /// notifications; research R16).
  static const maxCount = 2;

  /// The selected minutes.
  final Set<int> minutes;

  /// The warnings that apply to a timer of [duration], longest first;
  /// warnings at or beyond the duration are ignored.
  List<Duration> effectiveFor(Duration duration) =>
      (minutes.toList()..sort((a, b) => b.compareTo(a)))
          .map((value) => Duration(minutes: value))
          .where((offset) => offset < duration)
          .toList();

  /// Encodes as a sorted list of minutes.
  List<int> toJson() => minutes.toList()..sort();

  @override
  bool operator ==(Object other) =>
      other is WarningOffsets &&
      other.minutes.length == minutes.length &&
      other.minutes.containsAll(minutes);

  @override
  int get hashCode => Object.hashAllUnordered(minutes);

  @override
  String toString() => 'WarningOffsets($minutes)';

  static String? _violationOf(Set<int> minutes) {
    if (minutes.length > maxCount) return 'at most $maxCount warnings';
    if (!allowedMinutes.containsAll(minutes)) {
      return 'values must be in $allowedMinutes';
    }
    return null;
  }
}
