import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/features/images/data/bank_manifest_loader.dart';
import 'package:visual_time_counter/features/images/data/image_processor_impl.dart';
import 'package:visual_time_counter/features/images/domain/image_asset.dart';
import 'package:visual_time_counter/features/images/domain/image_processor.dart';

/// The built-in library, read once from the bundled manifest.
final bankImagesProvider = FutureProvider<List<BankImageAsset>>(
  (ref) => const BankManifestLoader().load(rootBundle),
);

/// Turns picked files into stored own images.
final imageProcessorProvider = Provider<ImageProcessor>(
  (ref) => const ImageProcessorImpl(),
);

/// Decodes a picked file for the frame screen's preview; throws when the
/// file is not an image the platform can open.
final imagePreviewDecoderProvider =
    Provider<Future<ui.Image> Function(Uint8List bytes)>(
      (ref) => decodeImageFromList,
    );
