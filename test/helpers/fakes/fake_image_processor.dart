import 'dart:async';
import 'dart:typed_data';

import 'package:visual_time_counter/features/images/domain/frame_spec.dart';
import 'package:visual_time_counter/features/images/domain/image_processor.dart';

/// Records each frame, optionally waits for [gate] and then returns
/// [result] or throws [nextError] once.
class FakeImageProcessor implements ImageProcessor {
  final frames = <FrameSpec>[];

  /// When set, processing waits until it completes.
  Completer<void>? gate;

  Object? nextError;

  ProcessedImage result = ProcessedImage(
    jpegBytes: Uint8List.fromList(const [0xFF, 0xD8, 0xFF, 0xD9]),
    width: 1024,
    height: 1024,
  );

  @override
  Future<ProcessedImage> process(Uint8List input, FrameSpec frame) async {
    frames.add(frame);
    await gate?.future;
    final error = nextError;
    nextError = null;
    if (error != null) throw error;
    return result;
  }
}
