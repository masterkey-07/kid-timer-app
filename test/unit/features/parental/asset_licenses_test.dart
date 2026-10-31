import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/features/parental/data/asset_licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the assets LICENSES.md reach the license registry', () async {
    registerAssetLicenses(rootBundle);

    final entries = await LicenseRegistry.licenses.toList();
    final texts = {
      for (final entry in entries)
        if (entry.packages.any((name) => name.startsWith('Kid Timer assets')))
          entry.packages.single: entry.paragraphs
              .map((paragraph) => paragraph.text)
              .join('\n'),
    };

    expect(texts.keys, [
      'Kid Timer assets: Images',
      'Kid Timer assets: Sounds',
      'Kid Timer assets: Fonts',
    ]);
    expect(texts['Kid Timer assets: Sounds'], contains('CC0-1.0'));
    expect(texts['Kid Timer assets: Fonts'], contains('OFL-1.1'));
  });
}
