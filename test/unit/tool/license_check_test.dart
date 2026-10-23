import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/license_check.dart';

void main() {
  late Directory root;

  void write(String path, [String content = 'x']) {
    File('${root.path}/$path')
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  String table(List<(String file, String license)> rows) => [
    '# Licenses',
    '',
    '| File | Author | License | Source |',
    '| ---- | ------ | ------- | ------ |',
    for (final (file, license) in rows) '| `$file` | Someone | $license | x |',
  ].join('\n');

  setUp(() => root = Directory.systemTemp.createTempSync('licenses_'));
  tearDown(() => root.deleteSync(recursive: true));

  test('passes when every asset is listed with an allowed license', () {
    write('assets/fonts/Font/Font-Regular.ttf');
    write('assets/fonts/Font/OFL.txt');
    write(
      'assets/fonts/LICENSES.md',
      table([('Font/Font-Regular.ttf', 'OFL-1.1'), ('Font/OFL.txt', 'OFL-1.1')]),
    );
    write('assets/sounds/chime_soft.wav');
    write('assets/sounds/manifest.json', '{}');
    write('assets/sounds/LICENSES.md', table([('chime_soft.wav', 'CC0-1.0')]));
    write('assets/images/bank/meal/plate.webp');
    write('assets/images/bank/manifest.json', '{}');
    write('assets/images/bank/LICENSES.md', table([('meal/plate.webp', 'MIT')]));
    write('assets/images/.gitkeep', '');

    expect(checkLicenses(root), isEmpty);
  });

  test('accepts every allowed license', () {
    const allowed = ['CC0-1.0', 'CC-BY-4.0', 'MIT', 'Apache-2.0', 'OFL-1.1'];
    for (final (index, _) in allowed.indexed) {
      write('assets/sounds/s$index.wav');
    }
    write(
      'assets/sounds/LICENSES.md',
      table([
        for (final (index, license) in allowed.indexed)
          ('s$index.wav', license),
      ]),
    );

    expect(checkLicenses(root), isEmpty);
  });

  test('fails for an asset missing from LICENSES.md', () {
    write('assets/sounds/a.wav');
    write('assets/sounds/b.wav');
    write('assets/sounds/LICENSES.md', table([('a.wav', 'CC0-1.0')]));

    expect(checkLicenses(root), [
      allOf(contains('assets/sounds/b.wav'), contains('not listed')),
    ]);
  });

  test('fails for an asset folder without LICENSES.md', () {
    write('assets/images/bank/meal/plate.webp');

    expect(checkLicenses(root), [
      allOf(contains('assets/images/bank/meal/plate.webp'), contains('not listed')),
    ]);
  });

  for (final license in ['CC-BY-SA-4.0', 'CC-BY-NC-4.0', 'GPL-3.0', '']) {
    test('fails for the disallowed license "$license"', () {
      write('assets/sounds/a.wav');
      write('assets/sounds/LICENSES.md', table([('a.wav', license)]));

      expect(checkLicenses(root), [
        allOf(contains('assets/sounds/a.wav'), contains('not allowed')),
      ]);
    });
  }

  test('fails for a listed file that does not exist', () {
    write('assets/sounds/LICENSES.md', table([('gone.wav', 'CC0-1.0')]));

    expect(checkLicenses(root), [
      allOf(contains('assets/sounds/LICENSES.md'), contains('gone.wav')),
    ]);
  });

  test('uses the nearest LICENSES.md', () {
    write('assets/images/bank/meal/plate.webp');
    write('assets/images/bank/LICENSES.md', table([]));
    write('assets/images/bank/meal/LICENSES.md', table([('plate.webp', 'MIT')]));

    expect(checkLicenses(root), isEmpty);
  });

  test('ignores assets outside images, sounds and fonts', () {
    write('assets/legal/privacy_en.md');

    expect(checkLicenses(root), isEmpty);
  });

  group('runLicenseCheck', () {
    test('returns 0 when all assets are licensed', () {
      expect(runLicenseCheck(root, StringBuffer()), 0);
    });

    test('returns 1 and lists the violations otherwise', () {
      write('assets/sounds/a.wav');
      final out = StringBuffer();

      expect(runLicenseCheck(root, out), 1);
      expect(out.toString(), contains('assets/sounds/a.wav'));
    });
  });
}
