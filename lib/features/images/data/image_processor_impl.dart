import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:visual_time_counter/features/images/domain/frame_spec.dart';
import 'package:visual_time_counter/features/images/domain/image_processor.dart';

/// [ImageProcessor] on the pure-Dart `image` package, run in a background
/// isolate so the frame screen keeps animating (FR-023).
final class ImageProcessorImpl implements ImageProcessor {
  /// Creates the processor.
  const new();

  /// The stored image is this many pixels square.
  static const outputSize = 1024;

  /// The largest stored JPEG (data-model ImageAsset).
  static const int maxOutputBytes = 400 * 1024;

  @override
  Future<ProcessedImage> process(Uint8List input, FrameSpec frame) =>
      compute(_processInBackground, (input: input, frame: frame));
}

/// Tried in order until the JPEG fits [ImageProcessorImpl.maxOutputBytes].
const _jpegQualities = [85, 75, 65, 55, 45, 35];

ProcessedImage _processInBackground(
  ({Uint8List input, FrameSpec frame}) request,
) {
  final decoded = _decode(request.input);
  final square = _cropSquare(img.bakeOrientation(decoded), request.frame);
  final output = _withoutMetadata(_onWhite(_resized(square)));
  return ProcessedImage(
    jpegBytes: _encodeWithinLimit(output),
    width: output.width,
    height: output.height,
  );
}

/// Decodes the formats the picker accepts. The size is read from the
/// header first, so a huge file is refused before it is decoded.
img.Image _decode(Uint8List input) {
  final decoder = _decoderFor(input);
  if (decoder == null) throw const UnsupportedImageFormat();

  final info = _safely(() => decoder.startDecode(input));
  if (info == null) throw const CorruptImage();
  if (info.width * info.height > ImageTooLarge.maxPixels) {
    throw ImageTooLarge(width: info.width, height: info.height);
  }

  final image = _safely(() => decoder.decode(input));
  if (image == null || image.width == 0 || image.height == 0) {
    throw const CorruptImage();
  }
  return image;
}

/// Only common photo formats: the package also parses formats such as PSD
/// or EXR, which nobody picks for a timer and would only widen what
/// untrusted files can reach.
img.Decoder? _decoderFor(Uint8List input) {
  final candidates = <img.Decoder>[
    img.JpegDecoder(),
    img.PngDecoder(),
    img.WebPDecoder(),
    img.GifDecoder(),
    img.BmpDecoder(),
  ];
  for (final decoder in candidates) {
    if (_safely(() => decoder.isValidFile(input)) ?? false) return decoder;
  }
  return null;
}

/// Runs a decoder step; the package signals damaged data by throwing.
T? _safely<T>(T Function() step) {
  try {
    return step();
  } on Object catch (error) {
    debugPrint('Image decoding failed: $error');
    return null;
  }
}

/// The square under the frame's circle, kept inside the image.
img.Image _cropSquare(img.Image image, FrameSpec frame) {
  final side = max(1, (min(image.width, image.height) / frame.zoom).round());
  int startFor(double center, int length) =>
      (center * length - side / 2).round().clamp(0, length - side);

  return img.copyCrop(
    image,
    x: startFor(frame.centerX, image.width),
    y: startFor(frame.centerY, image.height),
    width: side,
    height: side,
  );
}

img.Image _resized(img.Image square) => img.copyResize(
  square,
  width: ImageProcessorImpl.outputSize,
  height: ImageProcessorImpl.outputSize,
  // Averaging avoids aliasing when shrinking a large photo.
  interpolation: square.width > ImageProcessorImpl.outputSize
      ? img.Interpolation.average
      : img.Interpolation.cubic,
);

/// JPEG has no transparency; transparent areas become white, not black.
img.Image _onWhite(img.Image image) {
  final opaque = img.Image(width: image.width, height: image.height)
    ..clear(img.ColorRgb8(255, 255, 255));
  return img.compositeImage(opaque, image.convert(numChannels: 4));
}

img.Image _withoutMetadata(img.Image image) => image
  ..exif = img.ExifData()
  ..iccProfile = null
  ..textData = null;

Uint8List _encodeWithinLimit(img.Image image) {
  late Uint8List jpeg;
  for (final quality in _jpegQualities) {
    jpeg = img.encodeJpg(
      image,
      quality: quality,
      chroma: img.JpegChroma.yuv420,
    );
    if (jpeg.length <= ImageProcessorImpl.maxOutputBytes) return jpeg;
  }
  return jpeg;
}
