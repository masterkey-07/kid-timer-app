import 'package:meta/meta.dart';
import 'package:visual_time_counter/core/domain/json_utils.dart';

/// The color palette of an image-less dial (FR-051).
///
/// The domain only decides the phase for the remaining fraction; the colors
/// of each phase live in `lib/app/theme/palettes.dart`.
enum PaletteId {
  /// Green above 50%, yellow from 20% to 50%, red below 20%.
  progressive,

  /// One fixed color.
  single,

  /// Pastel phases with no red or alert color.
  calm;

  /// Decodes the persisted name.
  factory fromJson(Object? json) => enumFromJson(values, json, 'paletteId');

  /// Remaining fraction where the start phase hands over to the middle one.
  static const upperThreshold = 0.5;

  /// Remaining fraction where the middle phase hands over to the end one.
  static const lowerThreshold = 0.2;

  /// Width of the smooth transition, centered on each threshold.
  static const blendBand = 0.02;

  /// Whether this palette turns to an alert color (red) near the end.
  bool get usesAlertColors => this == progressive;

  /// The phase, or blend between two phases, for [remainingFraction].
  PaletteBlend phaseAt(double remainingFraction) {
    if (this == single) return const PaletteBlend.solid(PalettePhase.start);

    final fraction = remainingFraction.clamp(0.0, 1.0);
    return _blendAround(
          fraction,
          threshold: upperThreshold,
          above: PalettePhase.start,
          below: PalettePhase.middle,
        ) ??
        _blendAround(
          fraction,
          threshold: lowerThreshold,
          above: PalettePhase.middle,
          below: PalettePhase.end,
        ) ??
        const PaletteBlend.solid(PalettePhase.end);
  }

  /// The blend for [fraction] when it is at or above the lower edge of the
  /// band around [threshold]; null when it is further below.
  static PaletteBlend? _blendAround(
    double fraction, {
    required double threshold,
    required PalettePhase above,
    required PalettePhase below,
  }) {
    const halfBand = blendBand / 2;
    final bandTop = threshold + halfBand;
    final bandBottom = threshold - halfBand;

    if (fraction >= bandTop) return PaletteBlend.solid(above);
    if (fraction > bandBottom) {
      return PaletteBlend(above, below, (bandTop - fraction) / blendBand);
    }
    return null;
  }

  /// Encodes as the enum name.
  String toJson() => name;
}

/// A palette phase; each palette maps it to its own color.
enum PalettePhase {
  /// Plenty of time left (progressive: green).
  start,

  /// Getting closer (progressive: yellow).
  middle,

  /// Almost over (progressive: red).
  end,
}

/// A linear blend from [from] to [to] by [t] (0 = [from], 1 = [to]).
@immutable
final class PaletteBlend {
  /// Blends [from] into [to] by [t].
  const new(this.from, this.to, this.t);

  /// A single phase without blending.
  const new solid(PalettePhase phase) : this(phase, phase, 0);

  /// The phase at `t = 0`.
  final PalettePhase from;

  /// The phase at `t = 1`.
  final PalettePhase to;

  /// The blend factor in [0, 1].
  final double t;

  @override
  bool operator ==(Object other) =>
      other is PaletteBlend &&
      other.from == from &&
      other.to == to &&
      other.t == t;

  @override
  int get hashCode => Object.hash(from, to, t);

  @override
  String toString() => 'PaletteBlend($from → $to, $t)';
}
