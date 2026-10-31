import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/features/parental/domain/number_words.dart';

void main() {
  group('multiplication in words (FR-063)', () {
    test('reads 7 × 8 in Portuguese', () {
      expect(
        NumberWords.multiplication(7, 8, languageCode: 'pt'),
        'sete vezes oito',
      );
    });

    test('reads 7 × 8 in English', () {
      expect(
        NumberWords.multiplication(7, 8, languageCode: 'en'),
        'seven times eight',
      );
    });

    test('falls back to English for an unsupported language', () {
      expect(
        NumberWords.multiplication(3, 4, languageCode: 'fr'),
        'three times four',
      );
    });
  });

  group('products in words', () {
    const portuguese = {
      9: 'nove',
      10: 'dez',
      16: 'dezesseis',
      21: 'vinte e um',
      30: 'trinta',
      56: 'cinquenta e seis',
      81: 'oitenta e um',
    };
    const english = {
      9: 'nine',
      10: 'ten',
      16: 'sixteen',
      21: 'twenty-one',
      30: 'thirty',
      56: 'fifty-six',
      81: 'eighty-one',
    };

    for (final entry in portuguese.entries) {
      test('${entry.key} in Portuguese', () {
        expect(
          NumberWords.spell(entry.key, languageCode: 'pt'),
          entry.value,
        );
      });
    }

    for (final entry in english.entries) {
      test('${entry.key} in English', () {
        expect(
          NumberWords.spell(entry.key, languageCode: 'en'),
          entry.value,
        );
      });
    }

    test('spells every product of two factors 3–9 in both languages', () {
      for (final languageCode in ['pt', 'en']) {
        for (var left = 3; left <= 9; left++) {
          for (var right = 3; right <= 9; right++) {
            expect(
              NumberWords.spell(left * right, languageCode: languageCode),
              isNotEmpty,
            );
          }
        }
      }
    });

    test('rejects a number outside 0–99', () {
      expect(
        () => NumberWords.spell(100, languageCode: 'en'),
        throwsRangeError,
      );
    });
  });
}
