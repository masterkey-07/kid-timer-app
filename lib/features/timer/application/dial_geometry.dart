import 'dart:math';
import 'dart:ui';

import 'package:visual_time_counter/core/domain/dial_direction.dart';
import 'package:visual_time_counter/core/domain/dial_scale.dart';
import 'package:visual_time_counter/core/domain/timer_duration.dart';

/// Maps durations to dial angles and dragged points back to durations
/// (FR-001, FR-002).
///
/// Angles follow the canvas convention: radians, y down, positive is
/// clockwise. The sector always starts at 12 o'clock; a clockwise dial opens
/// it counter-clockwise so that, as time passes, its free edge moves
/// clockwise back to 12 (like a physical visual timer).
final class DialGeometry {
  /// Creates the geometry for a dial of [scale] shrinking in [direction].
  const new({required this.scale, required this.direction});

  /// 12 o'clock.
  static const double startAngle = -pi / 2;

  static const double _fullTurn = 2 * pi;

  /// Below this share of the radius a touch is on the image, not the edge.
  static const _innerRingFraction = 0.5;

  /// How far outside the edge a touch still grabs it (half a 48 dp target).
  static const _outerTouchSlop = 24.0;

  /// A drag that jumps more than this share of a turn crossed 12 o'clock.
  static const _wrapThreshold = 0.5;

  /// The time span of the full circle.
  final DialScale scale;

  /// The direction in which the sector shrinks.
  final DialDirection direction;

  /// The longest duration the dial can show.
  Duration get maxDuration =>
      scale.span < TimerDuration.max ? scale.span : TimerDuration.max;

  /// The share of the circle covered by [remaining], in [0, 1].
  double fractionOf(Duration remaining) => scale.fractionOf(remaining);

  /// The signed sweep of the sector for [remaining], from [startAngle].
  double sweepAngleOf(Duration remaining) =>
      _openingSign * fractionOf(remaining) * _fullTurn;

  /// The remaining sector of the dial inscribed in [circle] for a signed
  /// [sweepAngle] (see [sweepAngleOf]): the whole disc at a full turn, empty
  /// at zero. An image on the dial is clipped to it (FR-025).
  static Path remainingSectorPath(Rect circle, double sweepAngle) {
    if (sweepAngle == 0) return Path();
    if (sweepAngle.abs() >= _fullTurn) return Path()..addOval(circle);
    return Path()
      ..moveTo(circle.center.dx, circle.center.dy)
      ..arcTo(circle, startAngle, sweepAngle, false)
      ..close();
  }

  /// The duration at [fromCenter] (a point relative to the dial's center),
  /// rounded to the adjustment step and kept within the limits.
  ///
  /// With the [previous] duration of an ongoing drag, crossing 12 o'clock
  /// sticks to the nearest end instead of jumping across the dial.
  TimerDuration durationAt(Offset fromCenter, {Duration? previous}) {
    final fraction = _fractionAt(fromCenter);
    final maxDuration = this.maxDuration;
    if (previous != null) {
      final previousFraction = fractionOf(previous);
      final jump = fraction - previousFraction;
      if (jump < -_wrapThreshold) return TimerDuration(maxDuration);
      if (jump > _wrapThreshold) return TimerDuration.clamped(Duration.zero);
    }

    final snapped = TimerDuration.snapped(maxDuration * fraction);
    return snapped.value > maxDuration ? TimerDuration(maxDuration) : snapped;
  }

  /// Whether a touch at [fromCenter] grabs the edge of a dial of [radius].
  bool isOnRing(Offset fromCenter, {required double radius}) {
    final distance = fromCenter.distance;
    return distance >= radius * _innerRingFraction &&
        distance <= radius + _outerTouchSlop;
  }

  /// The share of a turn from 12 o'clock to [fromCenter], measured in the
  /// direction the sector opens, in [0, 1).
  double _fractionAt(Offset fromCenter) {
    final angle = atan2(fromCenter.dy, fromCenter.dx) - startAngle;
    final turns = _openingSign * angle / _fullTurn;
    return turns - turns.floorToDouble();
  }

  /// −1 when the sector opens counter-clockwise, +1 when it opens clockwise.
  int get _openingSign => switch (direction) {
    DialDirection.clockwise => -1,
    DialDirection.counterClockwise => 1,
  };
}
