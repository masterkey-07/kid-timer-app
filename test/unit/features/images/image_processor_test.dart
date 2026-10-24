import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:visual_time_counter/features/images/data/image_processor_impl.dart';
import 'package:visual_time_counter/features/images/domain/frame_spec.dart';
import 'package:visual_time_counter/features/images/domain/image_processor.dart';

const _outputSize = 1024;
const int _maxOutputBytes = 400 * 1024;
const _gpsFixture = 'test/fixtures/images/with_gps.jpg';
const _fixtureCameraMake = 'KidTimerFixtureCam';

final _red = img.ColorRgb8(255, 0, 0);
final _blue = img.ColorRgb8(0, 0, 255);
final _green = img.ColorRgb8(0, 255, 0);
final _yellow = img.ColorRgb8(255, 255, 0);

void main() {
  const processor = ImageProcessorImpl();

  group('output', () {
    test('is a 1024×1024 JPEG (FR-023)', () async {
      final result = await processor.process(_fixture(), FrameSpec.centered);

      expect(result.width, _outputSize);
      expect(result.height, _outputSize);
      final decoded = img.decodeJpg(result.jpegBytes)!;
      expect(decoded.width, _outputSize);
      expect(decoded.height, _outputSize);
    });

    test('drops EXIF, GPS and camera data', () async {
      final input = _fixture();
      expect(img.decodeJpg(input)!.exif.gpsIfd.isEmpty, isFalse);

      final result = await processor.process(input, FrameSpec.centered);

      expect(img.decodeJpg(result.jpegBytes)!.exif.isEmpty, isTrue);
      expect(_jpegMarkers(result.jpegBytes), isNot(contains(_app1Exif)));
      expect(
        String.fromCharCodes(result.jpegBytes),
        isNot(contains(_fixtureCameraMake)),
      );
    });

    test('stays within 400 KB even for a noisy photo', () async {
      final noise = img.Image(width: 1600, height: 1600);
      final random = Random(42);
      for (final pixel in noise) {
        pixel
          ..r = random.nextInt(256)
          ..g = random.nextInt(256)
          ..b = random.nextInt(256);
      }

      final result = await processor.process(
        img.encodePng(noise),
        FrameSpec.centered,
      );

      expect(result.jpegBytes.length, lessThanOrEqualTo(_maxOutputBytes));
    });

    test('applies the EXIF orientation before dropping it', () async {
      // Stored landscape, left red and right blue; orientation 6 means
      // "rotate 90° clockwise", so it is shown portrait, red on top.
      final stored = _split(width: 200, height: 100, first: _red, second: _blue)
        ..exif.imageIfd.orientation = 6;

      final result = await processor.process(
        img.encodeJpg(stored),
        FrameSpec.centered,
      );

      final output = img.decodeJpg(result.jpegBytes)!;
      expect(_isNear(output.getPixel(800, 200), _red), isTrue);
      expect(_isNear(output.getPixel(200, 800), _blue), isTrue);
    });
  });

  group('framing', () {
    final landscape = img.encodePng(
      _split(width: 2000, height: 1000, first: _red, second: _blue),
    );

    test('centered at zoom 1 takes the middle square', () async {
      final output = await _framed(processor, landscape, FrameSpec.centered);

      expect(_isNear(output.getPixel(100, 512), _red), isTrue);
      expect(_isNear(output.getPixel(924, 512), _blue), isTrue);
    });

    test('moves the square towards the frame center', () async {
      final output = await _framed(
        processor,
        landscape,
        FrameSpec(centerX: 0.25),
      );

      expect(_isNear(output.getPixel(100, 512), _red), isTrue);
      expect(_isNear(output.getPixel(924, 512), _red), isTrue);
    });

    test('keeps the square inside the image at the edges', () async {
      final output = await _framed(
        processor,
        landscape,
        FrameSpec(centerX: 1, centerY: 0),
      );

      expect(_isNear(output.getPixel(100, 100), _blue), isTrue);
      expect(_isNear(output.getPixel(924, 924), _blue), isTrue);
    });

    test('zoom 2 takes a square half as wide', () async {
      final quadrants = img.Image(width: 1000, height: 1000);
      for (final pixel in quadrants) {
        final isLeft = pixel.x < 500;
        final isTop = pixel.y < 500;
        pixel.set(switch ((isLeft, isTop)) {
          (true, true) => _red,
          (false, true) => _blue,
          (true, false) => _green,
          (false, false) => _yellow,
        });
      }

      final output = await _framed(
        processor,
        img.encodePng(quadrants),
        FrameSpec(centerX: 0.75, centerY: 0.75, zoom: 2),
      );

      expect(_isNear(output.getPixel(50, 50), _yellow), isTrue);
      expect(_isNear(output.getPixel(974, 974), _yellow), isTrue);
    });
  });

  group('errors', () {
    test('rejects bytes that are not an image', () {
      final notAnImage = Uint8List.fromList(
        List.generate(4000, (index) => (index * 7919) & 0xFF),
      );

      expect(
        processor.process(notAnImage, FrameSpec.centered),
        throwsA(isA<UnsupportedImageFormat>()),
      );
    });

    test('rejects HEIC, which it cannot decode', () {
      final heic = Uint8List.fromList([
        ...[0, 0, 0, 0x18],
        ...'ftypheic'.codeUnits,
        ...[0, 0, 0, 0],
        ...'mif1heic'.codeUnits,
        ...List.filled(100, 0),
      ]);

      expect(
        processor.process(heic, FrameSpec.centered),
        throwsA(isA<UnsupportedImageFormat>()),
      );
    });

    test('rejects a known format with damaged data', () {
      final png = img.encodePng(img.Image(width: 64, height: 64));
      // Keep the signature and header, overwrite the pixel data.
      for (var index = 40; index < png.length - 12; index++) {
        png[index] = 0x5A;
      }

      expect(
        processor.process(png, FrameSpec.centered),
        throwsA(isA<CorruptImage>()),
      );
    });

    test('rejects images over 100 MP before decoding them', () {
      final huge = _withJpegSize(_fixture(), width: 12000, height: 9000);

      expect(
        processor.process(huge, FrameSpec.centered),
        throwsA(isA<ImageTooLarge>()),
      );
    });
  });

  group('FrameSpec', () {
    test('rejects centers outside 0..1 and zoom outside 1..4', () {
      expect(() => FrameSpec(centerX: -0.1), throwsArgumentError);
      expect(() => FrameSpec(centerY: 1.1), throwsArgumentError);
      expect(() => FrameSpec(zoom: 0.9), throwsArgumentError);
      expect(() => FrameSpec(zoom: 4.1), throwsArgumentError);
    });

    test('centered is the middle at zoom 1', () {
      expect(FrameSpec.centered, FrameSpec());
      expect(FrameSpec.centered.centerX, 0.5);
      expect(FrameSpec.centered.centerY, 0.5);
      expect(FrameSpec.centered.zoom, FrameSpec.minZoom);
    });
  });
}

const _app1Exif = 0xFFE1;
const _jpegStartOfFrame = 0xFFC0;

Uint8List _fixture() => File(_gpsFixture).readAsBytesSync();

Future<img.Image> _framed(
  ImageProcessor processor,
  Uint8List input,
  FrameSpec frame,
) async {
  final result = await processor.process(input, frame);
  return img.decodeJpg(result.jpegBytes)!;
}

img.Image _split({
  required int width,
  required int height,
  required img.Color first,
  required img.Color second,
}) {
  final image = img.Image(width: width, height: height);
  for (final pixel in image) {
    pixel.set(pixel.x < width / 2 ? first : second);
  }
  return image;
}

/// JPEG compression shifts flat colors slightly.
bool _isNear(img.Color actual, img.Color expected) {
  const tolerance = 40;
  return (actual.r - expected.r).abs() <= tolerance &&
      (actual.g - expected.g).abs() <= tolerance &&
      (actual.b - expected.b).abs() <= tolerance;
}

/// The marker of every segment before the image data.
List<int> _jpegMarkers(Uint8List jpeg) {
  final data = ByteData.sublistView(jpeg);
  final markers = <int>[];
  var offset = 2; // after SOI
  while (offset + 4 <= jpeg.length) {
    final marker = data.getUint16(offset);
    markers.add(marker);
    if (marker == 0xFFDA) break; // start of scan: entropy-coded data follows
    offset += 2 + data.getUint16(offset + 2);
  }
  return markers;
}

/// Rewrites the baseline frame header so the JPEG claims another size.
Uint8List _withJpegSize(
  Uint8List jpeg, {
  required int width,
  required int height,
}) {
  final copy = Uint8List.fromList(jpeg);
  final data = ByteData.sublistView(copy);
  var offset = 2;
  while (data.getUint16(offset) != _jpegStartOfFrame) {
    offset += 2 + data.getUint16(offset + 2);
  }
  // FFC0, length (2), precision (1), height (2), width (2).
  data
    ..setUint16(offset + 5, height)
    ..setUint16(offset + 7, width);
  return copy;
}
