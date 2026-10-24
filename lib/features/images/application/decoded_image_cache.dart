import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';
import 'package:visual_time_counter/features/images/application/image_library.dart';
import 'package:visual_time_counter/features/images/application/my_images_controller.dart';

/// The images shown on dials, decoded from the library assets and the own
/// images box.
final decodedImageCacheProvider = Provider<DecodedImageCache>((ref) {
  final cache = DecodedImageCache(
    loadBytes: (source) => switch (source) {
      BankImageSource(:final imageId) => _loadBankImage(ref, imageId),
      UserImageSource(:final imageId) =>
        ref.read(userImageRepositoryProvider).readBytes(imageId),
      PaletteSource() => Future.value(),
    },
  );
  ref.onDispose(cache.dispose);
  return cache;
});

Future<Uint8List?> _loadBankImage(Ref ref, String imageId) async {
  final images = await ref.read(bankImagesProvider.future);
  final image = images.where((image) => image.id == imageId).firstOrNull;
  if (image == null) return null;
  final data = await rootBundle.load(image.assetPath);
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

/// Decodes images at a few fixed sizes (research R10: pre-decoded at the
/// dial's size, so painting never scales a 1024 px image every frame).
///
/// Every image it returns is a clone the caller owns and disposes, so
/// evicting an entry never breaks a dial still painting it.
final class DecodedImageCache {
  /// Creates a cache that reads bytes with `loadBytes` and keeps the
  /// `capacity` most recently used images.
  new({
    required this._loadBytes,
    Future<ui.Image> Function(Uint8List bytes, int size)? decode,
    this._capacity = _defaultCapacity,
  }) : _decode = decode ?? _decodeSquare;

  /// The largest decoded size, the stored own image's size.
  static const int maxSize = 1024;

  static const List<int> _buckets = [256, 512, 768, maxSize];
  static const _defaultCapacity = 4;

  final Future<Uint8List?> Function(VisualSource source) _loadBytes;
  final Future<ui.Image> Function(Uint8List bytes, int size) _decode;
  final int _capacity;

  /// Decoded images by image id and bucket, least recently used first.
  // Map literals keep insertion order, which serves as the LRU order.
  final _entries = <(String, int), ui.Image>{};
  final _pending = <(String, int), Future<void>>{};
  final _missing = <String>{};

  /// The bucket that covers [physicalSize] pixels.
  static int bucketFor(num physicalSize) => _buckets.firstWhere(
    (bucket) => bucket >= physicalSize,
    orElse: () => maxSize,
  );

  /// An already decoded image for [source] at least [targetSize] pixels
  /// wide, or null.
  ui.Image? peek(VisualSource source, {required num targetSize}) {
    final id = _imageIdOf(source);
    if (id == null) return null;
    final wanted = bucketFor(targetSize);
    for (final bucket in _buckets.where((bucket) => bucket >= wanted)) {
      final image = _entries.remove((id, bucket));
      if (image != null) {
        _entries[(id, bucket)] = image; // most recently used
        return image.clone();
      }
    }
    return null;
  }

  /// The image for [source] at [targetSize], decoding it when needed;
  /// null for palettes and for images that are missing or cannot be
  /// decoded (the dial then uses colors).
  Future<ui.Image?> resolve(
    VisualSource source, {
    required num targetSize,
  }) async {
    final cached = peek(source, targetSize: targetSize);
    if (cached != null) return cached;
    final id = _imageIdOf(source);
    if (id == null || _missing.contains(id)) return null;

    final key = (id, bucketFor(targetSize));
    await (_pending[key] ??= _load(source, key));
    // Each caller gets its own clone; null if it was evicted meanwhile.
    return peek(source, targetSize: targetSize);
  }

  /// Forgets the image [imageId] (after it was deleted).
  void evict(String imageId) {
    _missing.remove(imageId);
    final keys = _entries.keys.where((key) => key.$1 == imageId).toList();
    for (final key in keys) {
      _entries.remove(key)?.dispose();
    }
  }

  /// Releases every decoded image.
  void dispose() {
    for (final image in _entries.values) {
      image.dispose();
    }
    _entries.clear();
  }

  Future<void> _load(VisualSource source, (String, int) key) async {
    try {
      final bytes = await _loadBytes(source);
      if (bytes == null) {
        _missing.add(key.$1);
        return;
      }
      _store(key, await _decode(bytes, key.$2));
    } on Object catch (error) {
      debugPrint('Dial image ${key.$1} unavailable: $error');
      _missing.add(key.$1);
    } finally {
      unawaited(_pending.remove(key));
    }
  }

  void _store((String, int) key, ui.Image image) {
    _entries.remove(key)?.dispose();
    _entries[key] = image;
    while (_entries.length > _capacity) {
      _entries.remove(_entries.keys.first)?.dispose();
    }
  }

  static String? _imageIdOf(VisualSource source) => switch (source) {
    BankImageSource(:final imageId) ||
    UserImageSource(:final imageId) => imageId,
    PaletteSource() => null,
  };

  static Future<ui.Image> _decodeSquare(Uint8List bytes, int size) async {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: size,
      targetHeight: size,
    );
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }
}
