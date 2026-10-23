import 'dart:typed_data';

import 'package:meta/meta.dart';

/// Opens the system image picker without broad storage permissions
/// (FR-021).
abstract interface class ImagePickerPort {
  /// Lets the adult pick an image; null when cancelled.
  Future<PickedImage?> pickImage();
}

/// An image chosen in the system picker.
@immutable
final class PickedImage {
  /// Creates a picked image.
  const new({required this.bytes, this.mimeType, this.name});

  /// The raw file bytes.
  final Uint8List bytes;

  /// The MIME type, when known.
  final String? mimeType;

  /// The file name, when known.
  final String? name;
}
