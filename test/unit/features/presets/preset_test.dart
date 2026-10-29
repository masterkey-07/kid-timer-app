import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/domain/timer_duration.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';
import 'package:visual_time_counter/features/presets/domain/preset.dart';

final _createdAt = DateTime.utc(2026, 10, 23, 12);
final _updatedAt = DateTime.utc(2026, 10, 24, 9, 30);
final TimerConfig _config = TimerConfig.defaults.copyWith(
  duration: TimerDuration(const Duration(minutes: 2)),
  visual: const BankImageSource('bank:hygiene/brush_teeth'),
);

Preset _preset({
  String id = 'p1',
  String name = 'Brush teeth',
  int order = 0,
  bool isExample = false,
  bool favorite = false,
}) => Preset(
  id: id,
  name: name,
  order: order,
  config: _config,
  isExample: isExample,
  favorite: favorite,
  createdAt: _createdAt,
  updatedAt: _updatedAt,
);

/// Preset (data-model Preset, contracts/persistence-schema).
void main() {
  group('name (FR-040: 1–40 characters after trim)', () {
    test('is stored trimmed', () {
      expect(_preset(name: '  Brush teeth  ').name, 'Brush teeth');
    });

    test('accepts 1 and 40 characters', () {
      expect(_preset(name: 'B').name, 'B');
      expect(_preset(name: 'a' * 40).name, 'a' * 40);
    });

    test('rejects an empty or blank name', () {
      expect(() => _preset(name: ''), throwsArgumentError);
      expect(() => _preset(name: '   '), throwsArgumentError);
    });

    test('rejects more than 40 characters after trim', () {
      expect(() => _preset(name: 'a' * 41), throwsArgumentError);
      expect(_preset(name: ' ${'a' * 40} ').name, 'a' * 40);
    });

    test('counts an emoji as one character', () {
      expect(_preset(name: '🦷' * 40).name, '🦷' * 40);
      expect(() => _preset(name: '🦷' * 41), throwsArgumentError);
    });

    test('isValidName applies the same rule', () {
      expect(Preset.isValidName(' Bath '), isTrue);
      expect(Preset.isValidName(' '), isFalse);
      expect(Preset.isValidName('a' * 41), isFalse);
    });

    test('nameLength counts the trimmed characters', () {
      expect(Preset.nameLength('  Bath  '), 4);
      expect(Preset.nameLength('🦷🛁'), 2);
    });
  });

  test('rejects a negative order', () {
    expect(() => _preset(order: -1), throwsArgumentError);
  });

  group('renumbered (gap-free order)', () {
    test('numbers the presets 0..n-1 in list order', () {
      final presets = renumbered([
        _preset(id: 'a', order: 4),
        _preset(id: 'b', order: 9),
        _preset(id: 'c', order: 1),
      ]);

      expect([for (final p in presets) p.id], ['a', 'b', 'c']);
      expect([for (final p in presets) p.order], [0, 1, 2]);
    });

    test('keeps the presets already in place', () {
      final inPlace = _preset(id: 'a');

      expect(renumbered([inPlace]).single, same(inPlace));
    });
  });

  group('favorites (v1.x widget: at most 4)', () {
    test('there is room below 4 favorites', () {
      final presets = [
        for (var i = 0; i < 3; i++) _preset(id: '$i', favorite: true),
        _preset(id: 'x'),
      ];

      expect(hasRoomForFavorite(presets), isTrue);
    });

    test('there is no room at 4 favorites', () {
      final presets = [
        for (var i = 0; i < 4; i++) _preset(id: '$i', favorite: true),
      ];

      expect(hasRoomForFavorite(presets), isFalse);
    });
  });

  group('JSON', () {
    test('encodes per contracts/persistence-schema', () {
      expect(_preset(isExample: true).toJson(), {
        'schemaVersion': 1,
        'id': 'p1',
        'name': 'Brush teeth',
        'order': 0,
        'isExample': true,
        'favorite': false,
        'config': _config.toJson(),
        'createdAt': '2026-10-23T12:00:00.000Z',
        'updatedAt': '2026-10-24T09:30:00.000Z',
      });
    });

    test('round-trips', () {
      final preset = _preset(order: 3, favorite: true);

      expect(Preset.fromJson(preset.toJson()), preset);
    });

    test('reads the instants as UTC', () {
      final json = {
        ..._preset().toJson(),
        'createdAt': '2026-10-23T09:00:00.000-03:00',
      };

      expect(Preset.fromJson(json).createdAt, _createdAt);
    });

    test('rejects another schema version', () {
      final json = {..._preset().toJson(), 'schemaVersion': 2};

      expect(() => Preset.fromJson(json), throwsFormatException);
    });

    test('rejects an invalid name or a missing field', () {
      expect(
        () => Preset.fromJson({..._preset().toJson(), 'name': ''}),
        throwsFormatException,
      );
      expect(
        () => Preset.fromJson(_preset().toJson()..remove('config')),
        throwsFormatException,
      );
      expect(
        () => Preset.fromJson({..._preset().toJson(), 'order': -2}),
        throwsFormatException,
      );
      expect(
        () => Preset.fromJson({..._preset().toJson(), 'createdAt': null}),
        throwsFormatException,
      );
    });
  });

  test('copyWith changes only the given fields', () {
    final preset = _preset();
    final changed = preset.copyWith(name: 'Bath', order: 2, favorite: true);

    expect(changed.name, 'Bath');
    expect(changed.order, 2);
    expect(changed.favorite, isTrue);
    expect(changed.id, preset.id);
    expect(changed.config, preset.config);
    expect(changed.createdAt, preset.createdAt);
    expect(preset.copyWith(), preset);
  });

  test('has value equality', () {
    expect(_preset(), _preset());
    expect(_preset().hashCode, _preset().hashCode);
    expect(_preset(), isNot(_preset(name: 'Bath')));
  });
}
