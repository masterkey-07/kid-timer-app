import 'package:meta/meta.dart';

/// How an own image is framed in the circle (FR-022): the circle's center
/// as a share of the image's width and height, and the zoom (1 = the
/// circle spans the image's shorter side).
@immutable
final class FrameSpec {
  /// Creates a frame; throws an [ArgumentError] when a center is outside
  /// 0..1 or [zoom] outside [minZoom]..[maxZoom].
  factory({double centerX = 0.5, double centerY = 0.5, double zoom = 1}) {
    _checkShare(centerX, 'centerX');
    _checkShare(centerY, 'centerY');
    if (zoom < minZoom || zoom > maxZoom) {
      throw ArgumentError.value(zoom, 'zoom', 'must be $minZoom–$maxZoom');
    }
    return FrameSpec._(centerX, centerY, zoom);
  }

  const new _(this.centerX, this.centerY, this.zoom);

  /// The whole shorter side, centered.
  static const centered = FrameSpec._(0.5, 0.5, minZoom);

  /// No zoom.
  static const minZoom = 1.0;

  /// The largest zoom the frame screen offers.
  static const maxZoom = 4.0;

  /// Horizontal center, 0 (left edge) to 1 (right edge).
  final double centerX;

  /// Vertical center, 0 (top edge) to 1 (bottom edge).
  final double centerY;

  /// How far the image is zoomed in.
  final double zoom;

  static void _checkShare(double value, String name) {
    if (value < 0 || value > 1) {
      throw ArgumentError.value(value, name, 'must be 0–1');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is FrameSpec &&
      other.centerX == centerX &&
      other.centerY == centerY &&
      other.zoom == zoom;

  @override
  int get hashCode => Object.hash(centerX, centerY, zoom);

  @override
  String toString() => 'FrameSpec($centerX, $centerY, ×$zoom)';
}
