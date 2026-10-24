import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/features/images/data/bank_manifest_loader.dart';
import 'package:visual_time_counter/features/images/domain/image_category.dart';

const Map<String, Object> _entry = {
  'id': 'bank:hygiene/brush_teeth',
  'category': 'hygiene',
  'file': 'hygiene/brush_teeth.webp',
  'names': {'pt': 'Escovar os dentes', 'en': 'Brush teeth'},
  'author': 'Microsoft Corporation',
  'license': 'MIT',
  'source': 'https://example.org/toothbrush.svg',
};

String _manifest(List<Map<String, Object?>> images) =>
    jsonEncode({'schemaVersion': 1, 'images': images});

void main() {
  group('parse', () {
    test('reads every field, with the asset path under the bank', () {
      final [image] = BankManifestLoader.parse(_manifest([_entry]));

      expect(image.id, 'bank:hygiene/brush_teeth');
      expect(image.category, ImageCategory.hygiene);
      expect(image.assetPath, 'assets/images/bank/hygiene/brush_teeth.webp');
      expect(image.author, 'Microsoft Corporation');
      expect(image.license, 'MIT');
      expect(image.source, 'https://example.org/toothbrush.svg');
    });

    test('labels follow the language, falling back to English', () {
      final [image] = BankManifestLoader.parse(_manifest([_entry]));

      expect(image.labelFor('pt'), 'Escovar os dentes');
      expect(image.labelFor('en'), 'Brush teeth');
      expect(image.labelFor('es'), 'Brush teeth');
    });

    test('keeps the manifest order', () {
      final images = BankManifestLoader.parse(
        _manifest([
          _entry,
          {..._entry, 'id': 'bank:meal/meal', 'category': 'meal'},
        ]),
      );

      expect(images.map((image) => image.id), [
        'bank:hygiene/brush_teeth',
        'bank:meal/meal',
      ]);
    });

    test('rejects another schema version, a missing name or category', () {
      expect(
        () => BankManifestLoader.parse(
          jsonEncode({'schemaVersion': 2, 'images': <Object>[]}),
        ),
        throwsFormatException,
      );
      expect(
        () => BankManifestLoader.parse(
          _manifest([
            {
              ..._entry,
              'names': {'en': 'Brush teeth'},
            },
          ]),
        ),
        throwsFormatException,
      );
      expect(
        () => BankManifestLoader.parse(
          _manifest([
            {..._entry, 'category': 'sports'},
          ]),
        ),
        throwsFormatException,
      );
    });
  });

  test('load reads the manifest from the asset bundle', () async {
    final bundle = _FakeBundle(_manifest([_entry]));

    final images = await const BankManifestLoader().load(bundle);

    expect(bundle.requestedKeys, ['assets/images/bank/manifest.json']);
    expect(images.single.id, 'bank:hygiene/brush_teeth');
  });

  test('the bundled manifest loads, with every image bundled too', () async {
    final images = await const BankManifestLoader().load(rootBundle);

    expect(images, isNotEmpty);
    for (final image in images) {
      expect(await rootBundle.load(image.assetPath), isNotNull);
    }
  });
}

class _FakeBundle extends CachingAssetBundle {
  new(this._manifest);

  final String _manifest;
  final requestedKeys = <String>[];

  @override
  Future<ByteData> load(String key) async {
    requestedKeys.add(key);
    return ByteData.sublistView(utf8.encode(_manifest));
  }
}
