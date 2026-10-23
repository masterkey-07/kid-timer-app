import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/domain/color_token.dart';
import 'package:visual_time_counter/core/domain/palette_id.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';

void main() {
  group('PaletteSource', () {
    test('defaults to the progressive palette', () {
      expect(
        VisualSource.defaultSource,
        PaletteSource(paletteId: PaletteId.progressive),
      );
    });

    test('requires singleColor for the single palette', () {
      expect(
        () => PaletteSource(paletteId: PaletteId.single),
        throwsArgumentError,
      );
      expect(
        PaletteSource(
          paletteId: PaletteId.single,
          singleColor: ColorToken.teal,
        ).singleColor,
        ColorToken.teal,
      );
    });

    test('drops singleColor for the other palettes', () {
      expect(
        PaletteSource(
          paletteId: PaletteId.calm,
          singleColor: ColorToken.teal,
        ).singleColor,
        isNull,
      );
    });
  });

  test('has value equality per variant', () {
    expect(
      const BankImageSource('bank:meal/plate'),
      const BankImageSource('bank:meal/plate'),
    );
    expect(
      const BankImageSource('bank:meal/plate').hashCode,
      const BankImageSource('bank:meal/plate').hashCode,
    );
    expect(const UserImageSource('id-1'), isNot(const BankImageSource('id-1')));
    expect(
      PaletteSource(paletteId: PaletteId.single, singleColor: ColorToken.blue),
      isNot(
        PaletteSource(
          paletteId: PaletteId.single,
          singleColor: ColorToken.pink,
        ),
      ),
    );
  });

  group('JSON (contracts/persistence-schema.md)', () {
    final cases = <VisualSource, Map<String, Object?>>{
      PaletteSource(paletteId: PaletteId.progressive): {
        'type': 'palette',
        'paletteId': 'progressive',
        'singleColor': null,
      },
      PaletteSource(paletteId: PaletteId.single, singleColor: ColorToken.green):
          {'type': 'palette', 'paletteId': 'single', 'singleColor': 'green'},
      const BankImageSource('bank:hygiene/toothbrush'): {
        'type': 'bank',
        'imageId': 'bank:hygiene/toothbrush',
      },
      const UserImageSource('4f0c'): {'type': 'user', 'imageId': '4f0c'},
    };

    for (final MapEntry(key: source, value: json) in cases.entries) {
      test('round-trips $source', () {
        expect(source.toJson(), json);
        expect(VisualSource.fromJson(json), source);
      });
    }

    test('rejects an unknown type', () {
      expect(
        () => VisualSource.fromJson(const {'type': 'video', 'imageId': 'x'}),
        throwsFormatException,
      );
    });

    test('rejects a missing image id', () {
      expect(
        () => VisualSource.fromJson(const {'type': 'bank'}),
        throwsFormatException,
      );
    });

    test('rejects a single palette without a color', () {
      expect(
        () => VisualSource.fromJson(const {
          'type': 'palette',
          'paletteId': 'single',
          'singleColor': null,
        }),
        throwsFormatException,
      );
    });
  });
}
