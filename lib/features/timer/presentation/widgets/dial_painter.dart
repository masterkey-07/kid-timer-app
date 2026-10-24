import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:visual_time_counter/features/timer/application/dial_geometry.dart';

/// What changes from frame to frame: the sector's sweep and color.
@immutable
final class DialFrame {
  /// Creates a frame.
  const new({required this.sweepAngle, required this.sectorColor});

  /// The signed sweep from 12 o'clock (see [DialGeometry.sweepAngleOf]).
  final double sweepAngle;

  /// The remaining sector's color.
  final Color sectorColor;

  @override
  bool operator ==(Object other) =>
      other is DialFrame &&
      other.sweepAngle == sweepAngle &&
      other.sectorColor == sectorColor;

  @override
  int get hashCode => Object.hash(sweepAngle, sectorColor);
}

/// What stays the same while the dial is on screen.
@immutable
final class DialStyle {
  /// Creates a style.
  const new({
    required this.elapsedColor,
    required this.outlineColor,
    required this.outlineWidth,
    required this.markerColor,
    required this.markerCount,
    this.sectorOutlineColor,
  });

  /// The neutral elapsed area.
  final Color elapsedColor;

  /// The dial's outline (contracts/ui/00 §3.2).
  final Color outlineColor;

  /// 2 dp, or 3 dp in high contrast.
  final double outlineWidth;

  /// The minute markers' color.
  final Color markerColor;

  /// How many markers go around the dial.
  final int markerCount;

  /// In high contrast, the sector gets an outline so phases do not rely on
  /// color alone (FR-055).
  final Color? sectorOutlineColor;

  @override
  bool operator ==(Object other) =>
      other is DialStyle &&
      other.elapsedColor == elapsedColor &&
      other.outlineColor == outlineColor &&
      other.outlineWidth == outlineWidth &&
      other.markerColor == markerColor &&
      other.markerCount == markerCount &&
      other.sectorOutlineColor == sectorOutlineColor;

  @override
  int get hashCode => Object.hash(
    elapsedColor,
    outlineColor,
    outlineWidth,
    markerColor,
    markerCount,
    sectorOutlineColor,
  );
}

/// Paints the dial: the neutral elapsed disc, the remaining sector from
/// 12 o'clock, the minute markers and the outline.
///
/// It repaints whenever [frame] notifies, without rebuilding any widget; the
/// markers are recorded once per size and style into a cached picture.
class DialPainter extends CustomPainter {
  /// Creates the painter.
  new({required this.frame, required this.style, this.markers})
    : super(repaint: frame);

  /// The sweep and color of the current frame.
  final ValueListenable<DialFrame> frame;

  /// The fixed look of the dial.
  final DialStyle style;

  /// Where the recorded markers are kept between frames; null records them
  /// on every paint.
  final DialMarkerCache? markers;

  static const _majorMarkerEvery = 5;
  static const _minorMarkerLength = 0.05;
  static const _majorMarkerLength = 0.1;
  static const _minorMarkerWidth = 1.5;
  static const _majorMarkerWidth = 3.0;
  static const _sectorOutlineWidth = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - style.outlineWidth / 2;
    final circle = Rect.fromCircle(center: center, radius: radius);
    final current = frame.value;

    canvas.drawCircle(center, radius, Paint()..color = style.elapsedColor);
    if (current.sweepAngle != 0) {
      canvas.drawArc(
        circle,
        DialGeometry.startAngle,
        current.sweepAngle,
        true,
        Paint()..color = current.sectorColor,
      );
      final sectorOutline = style.sectorOutlineColor;
      if (sectorOutline != null) {
        canvas.drawArc(
          circle,
          DialGeometry.startAngle,
          current.sweepAngle,
          true,
          Paint()
            ..color = sectorOutline
            ..style = PaintingStyle.stroke
            ..strokeWidth = _sectorOutlineWidth,
        );
      }
    }

    final markerPicture =
        markers?.pictureFor(size, style, _recordMarkers) ??
        _recordMarkers(size, style);
    canvas
      ..drawPicture(markerPicture)
      ..drawCircle(
        center,
        radius,
        Paint()
          ..color = style.outlineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = style.outlineWidth,
      );
  }

  @override
  bool shouldRepaint(DialPainter oldDelegate) =>
      oldDelegate.frame != frame || oldDelegate.style != style;

  static ui.Picture _recordMarkers(Size size, DialStyle style) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - style.outlineWidth;
    final paint = Paint()
      ..color = style.markerColor
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < style.markerCount; i++) {
      final isMajor = i % _majorMarkerEvery == 0;
      final angle = DialGeometry.startAngle + i * 2 * pi / style.markerCount;
      final direction = Offset(cos(angle), sin(angle));
      final length =
          radius * (isMajor ? _majorMarkerLength : _minorMarkerLength);
      paint.strokeWidth = isMajor ? _majorMarkerWidth : _minorMarkerWidth;
      canvas.drawLine(
        center + direction * radius,
        center + direction * (radius - length),
        paint,
      );
    }
    return recorder.endRecording();
  }
}

/// Keeps the recorded markers while the size and style stay the same.
class DialMarkerCache {
  Size? _size;
  DialStyle? _style;
  ui.Picture? _picture;

  /// The cached picture, recorded with [record] when [size] or [style]
  /// changed.
  ui.Picture pictureFor(
    Size size,
    DialStyle style,
    ui.Picture Function(Size size, DialStyle style) record,
  ) {
    if (_picture == null || size != _size || style != _style) {
      _picture?.dispose();
      _picture = record(size, style);
      _size = size;
      _style = style;
    }
    return _picture!;
  }

  /// Releases the picture.
  void dispose() {
    _picture?.dispose();
    _picture = null;
  }
}
