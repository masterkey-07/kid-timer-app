import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';
import 'package:visual_time_counter/features/images/application/decoded_image_cache.dart';

const _bank = BankImageSource('bank:hygiene/brush_teeth');
const _own = UserImageSource('own-1');
final _bytes = Uint8List.fromList(const [1, 2, 3]);

/// Every image the cache hands out is a clone the caller disposes.
void main() {
  late List<VisualSource> loads;
  late List<int> decodedSizes;

  DecodedImageCache cacheWith({
    Future<Uint8List?> Function(VisualSource source)? loadBytes,
    int capacity = 4,
  }) {
    final cache = DecodedImageCache(
      loadBytes:
          loadBytes ??
          (source) async {
            loads.add(source);
            return _bytes;
          },
      decode: (bytes, size) {
        decodedSizes.add(size);
        return createTestImage(width: size, height: size);
      },
      capacity: capacity,
    );
    addTearDown(cache.dispose);
    return cache;
  }

  setUp(() {
    loads = [];
    decodedSizes = [];
  });

  test('rounds sizes up to a few buckets, at most 1024 px', () {
    expect(DecodedImageCache.bucketFor(1), 256);
    expect(DecodedImageCache.bucketFor(256), 256);
    expect(DecodedImageCache.bucketFor(300), 512);
    expect(DecodedImageCache.bucketFor(700), 768);
    expect(DecodedImageCache.bucketFor(4000), DecodedImageCache.maxSize);
  });

  test('ignores palettes', () async {
    final cache = cacheWith();

    expect(
      await cache.resolve(VisualSource.defaultSource, targetSize: 300),
      isNull,
    );
    expect(loads, isEmpty);
  });

  testWidgets('decodes once per bucket and serves larger ones', (tester) async {
    final cache = cacheWith();
    expect(cache.peek(_bank, targetSize: 300), isNull);

    final image = await tester.runAsync(
      () => cache.resolve(_bank, targetSize: 700),
    );

    expect(image!.width, 768);
    expect(decodedSizes, [768]);
    final peeked = cache.peek(_bank, targetSize: 300)!;
    expect(peeked.isCloneOf(image), isTrue);
    expect(cache.peek(_bank, targetSize: 1000), isNull);
    peeked.dispose();
    image.dispose();
  });

  testWidgets('concurrent requests share one load', (tester) async {
    final cache = cacheWith();

    final images = await tester.runAsync(
      () => Future.wait([
        cache.resolve(_own, targetSize: 500),
        cache.resolve(_own, targetSize: 500),
      ]),
    );

    expect(loads, [_own]);
    for (final image in images!) {
      image!.dispose();
    }
  });

  testWidgets('remembers a missing image until it is evicted', (tester) async {
    var attempts = 0;
    final cache = cacheWith(
      loadBytes: (source) async {
        attempts++;
        return null;
      },
    );

    await tester.runAsync(() => cache.resolve(_own, targetSize: 500));
    await tester.runAsync(() => cache.resolve(_own, targetSize: 500));
    expect(attempts, 1);

    cache.evict(_own.imageId);
    await tester.runAsync(() => cache.resolve(_own, targetSize: 500));
    expect(attempts, 2);
  });

  testWidgets('a decoding failure counts as missing', (tester) async {
    final cache = DecodedImageCache(
      loadBytes: (source) async => _bytes,
      decode: (bytes, size) => throw Exception('not an image'),
    );
    addTearDown(cache.dispose);

    expect(
      await tester.runAsync(() => cache.resolve(_own, targetSize: 500)),
      isNull,
    );
  });

  testWidgets('keeps only the most recently used images', (tester) async {
    final cache = cacheWith(capacity: 1);

    final first = await tester.runAsync(
      () => cache.resolve(_bank, targetSize: 256),
    );
    final second = await tester.runAsync(
      () => cache.resolve(_own, targetSize: 256),
    );

    expect(cache.peek(_bank, targetSize: 256), isNull);
    cache.peek(_own, targetSize: 256)!.dispose();
    // A handle given out survives the eviction.
    expect(first!.debugDisposed, isFalse);
    first.dispose();
    second!.dispose();
  });
}
