import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:visual_time_counter/features/images/domain/frame_spec.dart';

/// Turns a picked file into the stored own image (FR-023,
/// contracts/platform-ports.md): decodes it, applies [FrameSpec], crops a
/// square, resizes it and re-encodes it as JPEG without metadata.
abstract interface class ImageProcessor {
  /// Processes [input]; throws an [ImageProcessingException] when it cannot.
  Future<ProcessedImage> process(Uint8List input, FrameSpec frame);
}

/// A processed own image.
@immutable
final class ProcessedImage {
  /// Creates the result.
  const new({
    required this.jpegBytes,
    required this.width,
    required this.height,
  });

  /// The JPEG file, without metadata.
  final Uint8List jpegBytes;

  /// Width in pixels.
  final int width;

  /// Height in pixels.
  final int height;
}

/// Why an image could not be processed; the UI shows one friendly message
/// for all of them.
sealed class ImageProcessingException implements Exception {
  const new();
}

/// Not a format the app can decode (e.g. HEIC, or not an image at all).
final class UnsupportedImageFormat extends ImageProcessingException {
  /// Creates the error.
  const new();

  @override
  String toString() => 'UnsupportedImageFormat';
}

/// A known format whose data is damaged.
final class CorruptImage extends ImageProcessingException {
  /// Creates the error.
  const new();

  @override
  String toString() => 'CorruptImage';
}

/// More pixels than the app decodes ([ImageTooLarge.maxPixels]).
final class ImageTooLarge extends ImageProcessingException {
  /// Creates the error for an image of [width] × [height].
  const new({required this.width, required this.height});

  /// 100 megapixels.
  static const int maxPixels = 100 * 1000 * 1000;

  /// The image's width.
  final int width;

  /// The image's height.
  final int height;

  @override
  String toString() => 'ImageTooLarge($width×$height)';
}
