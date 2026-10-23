import 'package:meta/meta.dart';

/// The length of a timer, validated against the v1.0 limits (FR-001).
@immutable
final class TimerDuration {
  /// Creates a duration; throws an [ArgumentError] outside the limits or when
  /// [value] is not a whole number of seconds.
  factory(Duration value) {
    final violation = _violationOf(value);
    if (violation != null) throw ArgumentError.value(value, 'value', violation);
    return TimerDuration._(value);
  }

  /// The closest valid duration to [value]: clamped to the limits and
  /// truncated to whole seconds.
  factory clamped(Duration value) {
    final wholeSeconds = Duration(seconds: value.inSeconds);
    return TimerDuration._(_clamp(wholeSeconds));
  }

  /// Rounds [value] to the nearest adjustment step, then clamps it (dial
  /// dragging).
  factory snapped(Duration value) {
    final step = stepAt(value).inMilliseconds;
    final steps = (value.inMilliseconds / step).round();
    return TimerDuration._(_clamp(Duration(milliseconds: steps * step)));
  }

  /// Decodes the persisted integer milliseconds.
  factory fromJson(Object? json) {
    if (json is! int) throw FormatException('durationMs must be an int: $json');
    final value = Duration(milliseconds: json);
    final violation = _violationOf(value);
    if (violation != null) throw FormatException(violation, json);
    return TimerDuration._(value);
  }

  const new _(this.value);

  /// The shortest allowed timer.
  static const min = Duration(seconds: 10);

  /// The longest allowed timer in v1.0.
  static const max = Duration(hours: 2);

  /// Below this length the adjustment step is [fineStep].
  static const fineStepLimit = Duration(minutes: 2);

  /// Adjustment step below [fineStepLimit].
  static const fineStep = Duration(seconds: 10);

  /// Adjustment step from [fineStepLimit] on.
  static const coarseStep = Duration(minutes: 1);

  /// The default timer length (data-model TimerConfig).
  static const defaultValue = TimerDuration._(Duration(minutes: 5));

  /// The validated length.
  final Duration value;

  /// The adjustment step that applies at [value].
  static Duration stepAt(Duration value) =>
      value < fineStepLimit ? fineStep : coarseStep;

  /// One step longer, stopping at [max].
  TimerDuration increment() => TimerDuration.clamped(value + stepAt(value));

  /// One step shorter, stopping at [min]; uses the step of the range below so
  /// 2 min goes to 1 min 50 s.
  TimerDuration decrement() {
    final belowValue = value - const Duration(seconds: 1);
    return TimerDuration.clamped(value - stepAt(belowValue));
  }

  /// Adds [delta] (negative to subtract) and clamps; used by the quick
  /// buttons.
  TimerDuration adjustedBy(Duration delta) =>
      TimerDuration.clamped(value + delta);

  /// Encodes as integer milliseconds.
  int toJson() => value.inMilliseconds;

  @override
  bool operator ==(Object other) =>
      other is TimerDuration && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'TimerDuration($value)';

  static String? _violationOf(Duration value) {
    if (value < min || value > max) return 'must be between $min and $max';
    if (value.inMicroseconds % Duration.microsecondsPerSecond != 0) {
      return 'must be a whole number of seconds';
    }
    return null;
  }

  static Duration _clamp(Duration value) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}
