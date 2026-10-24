import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/l10n_check.dart';

void main() {
  late Directory root;

  void writeArb(String locale, Map<String, Object> messages) {
    File('${root.path}/lib/l10n/app_$locale.arb')
      ..createSync(recursive: true)
      ..writeAsStringSync(jsonEncode({'@@locale': locale, ...messages}));
  }

  void writeManifest(String path, Object manifest) {
    File('${root.path}/$path')
      ..createSync(recursive: true)
      ..writeAsStringSync(jsonEncode(manifest));
  }

  void writeMatchingArbs() {
    writeArb('pt', {'appTitle': 'Kid Timer'});
    writeArb('en', {'appTitle': 'Kid Timer'});
  }

  setUp(() => root = Directory.systemTemp.createTempSync('l10n_'));
  tearDown(() => root.deleteSync(recursive: true));

  test('passes when both files have the same keys and placeholders', () {
    writeArb('pt', {
      'appTitle': 'Kid Timer',
      '@appTitle': {'description': 'Name'},
      'minutesLeft': 'Faltam {minutes} min',
      '@minutesLeft': {
        'placeholders': {'minutes': <String, Object>{}},
      },
    });
    writeArb('en', {
      'appTitle': 'Kid Timer',
      'minutesLeft': '{minutes} min left',
    });

    expect(checkL10n(root), isEmpty);
  });

  test('fails for a key missing from en', () {
    writeArb('pt', {'appTitle': 'Kid Timer', 'homeStart': 'Começar'});
    writeArb('en', {'appTitle': 'Kid Timer'});

    expect(checkL10n(root), [
      allOf(contains('homeStart'), contains('app_en.arb')),
    ]);
  });

  test('fails for a key missing from pt', () {
    writeArb('pt', {'appTitle': 'Kid Timer'});
    writeArb('en', {'appTitle': 'Kid Timer', 'homeStart': 'Start'});

    expect(checkL10n(root), [
      allOf(contains('homeStart'), contains('app_pt.arb')),
    ]);
  });

  test('fails when placeholders differ', () {
    writeArb('pt', {'left': 'Faltam {minutes} min'});
    writeArb('en', {'left': '{mins} min left'});

    expect(checkL10n(root), [
      allOf(contains('left'), contains('minutes'), contains('mins')),
    ]);
  });

  test('compares the selector of plural messages', () {
    writeArb('pt', {
      'left':
          '{count, plural, =1{Falta 1 minuto} other{Faltam {count} minutos}}',
    });
    writeArb('en', {
      'left': '{n, plural, =1{1 minute left} other{{n} minutes left}}',
    });

    expect(checkL10n(root), [contains('left')]);
  });

  test('accepts plural branches that omit the placeholder', () {
    writeArb('pt', {
      'left': '{count, plural, =1{Falta um minuto} other{Faltam {count}}}',
    });
    writeArb('en', {
      'left': '{count, plural, =1{One minute left} other{{count} left}}',
    });

    expect(checkL10n(root), isEmpty);
  });

  test('fails when a file is missing', () {
    writeArb('pt', {'appTitle': 'Kid Timer'});

    expect(checkL10n(root), [contains('app_en.arb')]);
  });

  group('runL10nCheck', () {
    test('returns 0 when the files match', () {
      writeArb('pt', {'appTitle': 'Kid Timer'});
      writeArb('en', {'appTitle': 'Kid Timer'});

      expect(runL10nCheck(root, StringBuffer()), 0);
    });

    test('returns 1 and lists the problems otherwise', () {
      writeArb('pt', {'appTitle': 'Kid Timer', 'x': 'y'});
      writeArb('en', {'appTitle': 'Kid Timer'});
      final out = StringBuffer();

      expect(runL10nCheck(root, out), 1);
      expect(out.toString(), contains('x'));
    });
  });

  group('asset manifests (Constitution V)', () {
    const bankPath = 'assets/images/bank/manifest.json';

    test('pass when every names, labels and keywords map has pt and en', () {
      writeMatchingArbs();
      writeManifest(bankPath, {
        'images': [
          {
            'id': 'bank:meal/meal',
            'names': {'pt': 'Refeição', 'en': 'Mealtime'},
          },
        ],
      });
      writeManifest('assets/images/emoji/manifest.json', {
        'groups': [
          {
            'labels': {'pt': 'Animais e natureza', 'en': 'Animals & nature'},
            'images': [
              {
                'names': {'pt': 'girafa', 'en': 'giraffe'},
                'keywords': {
                  'pt': ['girafa', 'pescoço'],
                  'en': ['giraffe', 'neck'],
                },
              },
            ],
          },
        ],
      });

      expect(checkL10n(root), isEmpty);
    });

    test('fail for a missing or blank language, with the path', () {
      writeMatchingArbs();
      writeManifest(bankPath, {
        'images': [
          {
            'names': {'pt': 'Refeição'},
          },
          {
            'names': {'pt': '  ', 'en': 'Snack'},
          },
        ],
      });

      expect(checkL10n(root), [
        allOf(contains(bankPath), contains('images[0].names'), contains('en')),
        allOf(contains(bankPath), contains('images[1].names'), contains('pt')),
      ]);
    });

    test('fail for empty keyword lists', () {
      writeMatchingArbs();
      writeManifest('assets/images/emoji/manifest.json', {
        'images': [
          {
            'keywords': {
              'pt': <String>[],
              'en': ['dog'],
            },
          },
        ],
      });

      expect(checkL10n(root), [
        allOf(contains('images[0].keywords'), contains('pt')),
      ]);
    });

    test('check the committed sound and image manifests too', () {
      writeMatchingArbs();
      writeManifest('assets/sounds/manifest.json', {
        'sounds': [
          {
            'names': {'en': 'Soft chime'},
          },
        ],
      });

      expect(checkL10n(root), [contains('assets/sounds/manifest.json')]);
    });
  });
}
