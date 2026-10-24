import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/features/timer/application/dial_geometry.dart';
import 'package:visual_time_counter/features/timer/presentation/widgets/dial_painter.dart';

const _dialSize = 100;
const _circle = Rect.fromLTWH(0, 0, 100, 100);

const _imageColor = Color(0xFFFF0000);
const _sectorColor = Color(0xFF00FF00);
const _elapsedColor = Color(0xFF0000FF);

// For a clockwise dial, 25% left opens a quarter counter-clockwise from
// 12 o'clock: the top-left quadrant.
const _remainingPoint = Offset(30, 30);
const _elapsedPoint = Offset(70, 70);

void main() {
  group('remainingSectorPath', () {
    test('covers the opened quarter only', () {
      final path = DialGeometry.remainingSectorPath(_circle, -pi / 2);

      expect(path.contains(_remainingPoint), isTrue);
      expect(path.contains(_elapsedPoint), isFalse);
      expect(path.contains(const Offset(70, 30)), isFalse);
      expect(path.contains(const Offset(30, 70)), isFalse);
    });

    test('opens the other way for a positive sweep', () {
      final path = DialGeometry.remainingSectorPath(_circle, pi / 2);

      expect(path.contains(const Offset(70, 30)), isTrue);
      expect(path.contains(_remainingPoint), isFalse);
    });

    test('is the whole disc for a full turn, but not its corners', () {
      final path = DialGeometry.remainingSectorPath(_circle, -2 * pi);

      for (final point in const [
        _remainingPoint,
        _elapsedPoint,
        Offset(70, 30),
        Offset(30, 70),
      ]) {
        expect(path.contains(point), isTrue, reason: '$point');
      }
      expect(path.contains(const Offset(2, 2)), isFalse);
    });

    test('is empty when nothing is left', () {
      final path = DialGeometry.remainingSectorPath(_circle, 0);

      expect(path.getBounds().isEmpty, isTrue);
    });
  });

  group('DialPainter with an image (FR-025)', () {
    testWidgets('shows the image in the remaining sector only', (tester) async {
      final pixels = await tester.runAsync(
        () => _paint(sweepAngle: -pi / 2, withImage: true),
      );

      expect(pixels!.at(_remainingPoint), _imageColor);
      expect(pixels.at(_elapsedPoint), _elapsedColor);
    });

    testWidgets('keeps the image inside the circle at 100%', (tester) async {
      final pixels = await tester.runAsync(
        () => _paint(sweepAngle: -2 * pi, withImage: true),
      );

      expect(pixels!.at(_elapsedPoint), _imageColor);
      expect(pixels.at(const Offset(1, 1)).a, 0);
    });

    testWidgets('paints the sector color without an image', (tester) async {
      final pixels = await tester.runAsync(
        () => _paint(sweepAngle: -pi / 2, withImage: false),
      );

      expect(pixels!.at(_remainingPoint), _sectorColor);
      expect(pixels.at(_elapsedPoint), _elapsedColor);
    });
  });
}

Future<_Pixels> _paint({
  required double sweepAngle,
  required bool withImage,
}) async {
  final image = withImage ? _solidImage(_imageColor) : null;
  final painter = DialPainter(
    frame: ValueNotifier(
      DialFrame(sweepAngle: sweepAngle, sectorColor: _sectorColor),
    ),
    style: const DialStyle(
      elapsedColor: _elapsedColor,
      outlineColor: Color(0x00000000),
      outlineWidth: 0,
      markerColor: Color(0x00000000),
      markerCount: 0,
    ),
    image: image,
  );

  final recorder = ui.PictureRecorder();
  painter.paint(
    Canvas(recorder),
    Size(_dialSize.toDouble(), _dialSize.toDouble()),
  );
  final rendered = await recorder.endRecording().toImage(_dialSize, _dialSize);
  final bytes = await rendered.toByteData();
  image?.dispose();
  rendered.dispose();
  return _Pixels(bytes!);
}

ui.Image _solidImage(Color color) {
  final recorder = ui.PictureRecorder();
  Canvas(recorder)
      .drawRect(const Rect.fromLTWH(0, 0, 8, 8), Paint()..color = color);
  return recorder.endRecording().toImageSync(8, 8);
}

/// RGBA pixels of a rendered dial.
class _Pixels {
  const new(this._bytes);

  final ByteData _bytes;

  Color at(Offset point) {
    final offset = (point.dy.toInt() * _dialSize + point.dx.toInt()) * 4;
    return Color.fromARGB(
      _bytes.getUint8(offset + 3),
      _bytes.getUint8(offset),
      _bytes.getUint8(offset + 1),
      _bytes.getUint8(offset + 2),
    );
  }
}
