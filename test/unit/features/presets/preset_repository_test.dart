import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:visual_time_counter/core/domain/dial_scale.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/domain/timer_duration.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';
import 'package:visual_time_counter/core/persistence/boxes.dart';
import 'package:visual_time_counter/features/presets/data/preset_repository.dart';
import 'package:visual_time_counter/features/presets/data/preset_seeds.dart';
import 'package:visual_time_counter/features/presets/domain/preset.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

import '../../../helpers/fixtures.dart';
import '../../../helpers/hive_test_utils.dart';

final _now = DateTime.utc(2026, 10, 25, 8);
final TimerConfig _twoMinutes = TimerConfig.defaults.copyWith(
  duration: TimerDuration(const Duration(minutes: 2)),
);
const _suffix = '(copy)';
final AppLocalizations _english = lookupAppLocalizations(const Locale('en'));
final AppLocalizations _portuguese = lookupAppLocalizations(const Locale('pt'));

void main() {
  useTemporaryHive();

  late Box<Map<dynamic, dynamic>> box;
  late AppSettings settings;
  late int nextId;
  late DateTime now;

  setUp(() async {
    box = await Hive.openBox<Map<dynamic, dynamic>>(BoxNames.presets);
    settings = AppSettings.initial;
    nextId = 0;
    now = _now;
  });

  PresetRepository repository() => PresetRepository(
    presets: box,
    readSettings: () => settings,
    updateSettings: (change) async => settings = change(settings),
    clock: Clock(() => now),
    newId: () => 'preset-${nextId++}',
  );

  Future<List<Preset>> createNamed(
    PresetRepository presets,
    List<String> names,
  ) async => [
    for (final name in names)
      await presets.create(name: name, config: _twoMinutes),
  ];

  List<String> names(PresetRepository presets) => [
    for (final preset in presets.list()) preset.name,
  ];

  group('create', () {
    test('stores a trimmed preset at the end of the list', () async {
      final presets = repository();
      await presets.create(name: 'Bath', config: TimerConfig.defaults);
      final created = await presets.create(
        name: '  Brush teeth ',
        config: _twoMinutes,
      );

      expect(created.id, 'preset-1');
      expect(created.name, 'Brush teeth');
      expect(created.order, 1);
      expect(created.config, _twoMinutes);
      expect(created.isExample, isFalse);
      expect(created.favorite, isFalse);
      expect(created.createdAt, _now);
      expect(created.updatedAt, _now);
      expect(box.get('preset-1')!['schemaVersion'], 1);
      expect(presets.find('preset-1'), created);
      expect(presets.count, 2);
    });

    test('rejects an invalid name without storing anything', () async {
      final presets = repository();

      await expectLater(
        presets.create(name: '  ', config: _twoMinutes),
        throwsArgumentError,
      );
      await expectLater(
        presets.create(name: 'a' * 41, config: _twoMinutes),
        throwsArgumentError,
      );
      expect(box.isEmpty, isTrue);
    });

    test('stops at the limit of 100 (FR-042)', () async {
      final presets = repository();
      await createNamed(presets, [for (var i = 0; i < 100; i++) 'P$i']);

      expect(presets.hasRoom, isFalse);
      await expectLater(
        presets.create(name: 'One more', config: _twoMinutes),
        throwsA(isA<PresetLimitReached>()),
      );
      expect(presets.count, PresetRepository.maxPresets);
    });
  });

  group('list', () {
    test('sorts by order', () async {
      final presets = repository();
      await createNamed(presets, ['A', 'B', 'C']);
      await box.put('preset-0', {...box.get('preset-0')!, 'order': 5});

      expect(names(presets), ['B', 'C', 'A']);
    });

    test('leaves out unreadable documents', () async {
      final presets = repository();
      await createNamed(presets, ['A']);
      await box.put('broken', {'schemaVersion': 1, 'name': ''});

      expect(names(presets), ['A']);
      expect(presets.find('broken'), isNull);
    });

    test('reads a v1 document from the fixture', () async {
      final document = readJsonFixture(
        'persistence/v1/preset_brush_teeth.json',
      );
      await box.put(document['id']! as String, document);

      final preset = repository().list().single;

      expect(preset.name, 'Brush teeth');
      expect(preset.isExample, isTrue);
      expect(preset.config.duration.value, const Duration(minutes: 2));
      expect(preset.config.scale, DialScale.min5);
      expect(
        preset.config.visual,
        const BankImageSource('bank:hygiene/brush_teeth'),
      );
      expect(preset.createdAt, DateTime.utc(2026, 10, 23, 12));
    });
  });

  group('update', () {
    test('replaces the name and config and stamps updatedAt', () async {
      final presets = repository();
      final [created] = await createNamed(presets, ['Bath']);
      now = _now.add(const Duration(hours: 1));

      final updated = await presets.update(
        created.id,
        name: ' Shower ',
        config: TimerConfig.defaults,
      );

      expect(updated!.name, 'Shower');
      expect(updated.config, TimerConfig.defaults);
      expect(updated.order, created.order);
      expect(updated.createdAt, _now);
      expect(updated.updatedAt, now);
      expect(presets.find(created.id), updated);
    });

    test('returns null for a preset that no longer exists', () async {
      final updated = await repository().update(
        'gone',
        name: 'Bath',
        config: _twoMinutes,
      );

      expect(updated, isNull);
      expect(box.isEmpty, isTrue);
    });

    test('rejects an invalid name', () async {
      final presets = repository();
      final [created] = await createNamed(presets, ['Bath']);

      await expectLater(
        presets.update(created.id, name: '', config: _twoMinutes),
        throwsArgumentError,
      );
      expect(presets.find(created.id)!.name, 'Bath');
    });
  });

  group('duplicate', () {
    test('adds a copy with the suffix right after the original', () async {
      final presets = repository();
      final [first, _] = await createNamed(presets, ['Bath', 'Park']);

      final copy = await presets.duplicate(first.id, suffix: _suffix);

      expect(copy!.id, 'preset-2');
      expect(copy.name, 'Bath (copy)');
      expect(copy.config, first.config);
      expect(copy.isExample, isFalse);
      expect(names(presets), ['Bath', 'Bath (copy)', 'Park']);
      expect([for (final p in presets.list()) p.order], [0, 1, 2]);
    });

    test('shortens a long name so the copy fits 40 characters', () async {
      final presets = repository();
      final [long] = await createNamed(presets, ['a' * 40]);

      final copy = await presets.duplicate(long.id, suffix: _suffix);

      expect(copy!.name, '${'a' * 33} (copy)');
      expect(Preset.nameLength(copy.name), Preset.maxNameLength);
    });

    test('stops at the limit', () async {
      final presets = repository();
      final [first, ...] = await createNamed(presets, [
        for (var i = 0; i < 100; i++) 'P$i',
      ]);

      await expectLater(
        presets.duplicate(first.id, suffix: _suffix),
        throwsA(isA<PresetLimitReached>()),
      );
    });

    test('returns null for a preset that no longer exists', () async {
      expect(await repository().duplicate('gone', suffix: _suffix), isNull);
    });
  });

  group('move', () {
    test('moves down and renumbers without gaps', () async {
      final presets = repository();
      final [a, ...] = await createNamed(presets, ['A', 'B', 'C', 'D']);

      await presets.move(a.id, 2);

      expect(names(presets), ['B', 'C', 'A', 'D']);
      expect([for (final p in presets.list()) p.order], [0, 1, 2, 3]);
    });

    test('moves up', () async {
      final presets = repository();
      final [..., d] = await createNamed(presets, ['A', 'B', 'C', 'D']);

      await presets.move(d.id, 0);

      expect(names(presets), ['D', 'A', 'B', 'C']);
    });

    test('clamps the target index', () async {
      final presets = repository();
      final [a, ...] = await createNamed(presets, ['A', 'B']);

      await presets.move(a.id, 9);

      expect(names(presets), ['B', 'A']);
    });

    test('persists the new order', () async {
      final presets = repository();
      final [a, ...] = await createNamed(presets, ['A', 'B', 'C']);
      await presets.move(a.id, 2);

      expect(names(repository()), ['B', 'C', 'A']);
    });
  });

  group('delete and restore', () {
    test('delete removes the preset and closes the gap', () async {
      final presets = repository();
      final [_, b, _] = await createNamed(presets, ['A', 'B', 'C']);

      final deleted = await presets.delete(b.id);

      expect(deleted, b);
      expect(box.containsKey(b.id), isFalse);
      expect(names(presets), ['A', 'C']);
      expect([for (final p in presets.list()) p.order], [0, 1]);
    });

    test('restore puts the preset back where it was (undo)', () async {
      final presets = repository();
      final [_, b, _] = await createNamed(presets, ['A', 'B', 'C']);
      final deleted = await presets.delete(b.id);

      await presets.restore(deleted!);

      expect(names(presets), ['A', 'B', 'C']);
      expect(presets.find(b.id), b);
    });

    test('deleting a missing preset returns null', () async {
      expect(await repository().delete('gone'), isNull);
    });
  });

  group('seedExamples', () {
    final seeds = [
      for (var i = 0; i < 6; i++)
        PresetSeed(name: 'Example $i', config: _twoMinutes),
    ];

    test('creates the examples once and marks them seeded', () async {
      final presets = repository();

      await presets.seedExamples(seeds);

      expect(names(presets), [for (final seed in seeds) seed.name]);
      expect(presets.list().every((preset) => preset.isExample), isTrue);
      expect(settings.onboarding.examplesSeeded, isTrue);

      await presets.seedExamples(seeds);
      expect(presets.count, 6);
    });

    test(
      'does nothing when already seeded, even after deleting them',
      () async {
        settings = settings.copyWith(
          onboarding: settings.onboarding.copyWith(examplesSeeded: true),
        );

        await repository().seedExamples(seeds);

        expect(box.isEmpty, isTrue);
      },
    );

    test('marks first, so a failed flag write seeds nothing', () async {
      final presets = PresetRepository(
        presets: box,
        readSettings: () => settings,
        updateSettings: (change) async =>
            throw const FileSystemException('No space left on device'),
        clock: Clock.fixed(_now),
        newId: () => 'preset-${nextId++}',
      );

      await expectLater(
        presets.seedExamples(seeds),
        throwsA(isA<FileSystemException>()),
      );
      expect(box.isEmpty, isTrue);
    });

    test('keeps under the limit', () async {
      final presets = repository();
      await createNamed(presets, [for (var i = 0; i < 97; i++) 'P$i']);

      await presets.seedExamples(seeds);

      expect(presets.count, PresetRepository.maxPresets);
    });
  });

  group('example seeds', () {
    test('are one per activity category, none for animals (FR-042)', () {
      final images = [
        for (final seed in examplePresetSeeds(_english))
          (seed.config.visual as BankImageSource).imageId,
      ];

      expect(images.map((id) => id.split('/').first), [
        'bank:hygiene',
        'bank:meal',
        'bank:play',
        'bank:rest',
        'bank:school',
        'bank:goingOut',
      ]);
    });

    test('take valid, distinct names from the given language', () {
      for (final language in [_english, _portuguese]) {
        final seeds = examplePresetSeeds(language);

        expect(seeds.map((seed) => seed.name).toSet(), hasLength(6));
        expect(seeds.every((seed) => Preset.isValidName(seed.name)), isTrue);
      }
      expect(
        examplePresetSeeds(_english).first.name,
        isNot(examplePresetSeeds(_portuguese).first.name),
      );
    });
  });

  group('images', () {
    test('namesUsing lists the presets showing a visual', () async {
      final presets = repository();
      const image = UserImageSource('image-1');
      await presets.create(
        name: 'Bath',
        config: _twoMinutes.copyWith(visual: image),
      );
      await presets.create(name: 'Park', config: _twoMinutes);

      expect(presets.namesUsing(image), ['Bath']);
    });

    test('replaceVisual switches only the presets showing it', () async {
      final presets = repository();
      const image = UserImageSource('image-1');
      final bath = await presets.create(
        name: 'Bath',
        config: _twoMinutes.copyWith(visual: image),
      );
      final park = await presets.create(name: 'Park', config: _twoMinutes);
      now = _now.add(const Duration(minutes: 5));

      await presets.replaceVisual(image, VisualSource.defaultSource);

      final switched = presets.find(bath.id)!;
      expect(switched.config.visual, VisualSource.defaultSource);
      expect(switched.updatedAt, now);
      expect(presets.find(park.id), park);
    });
  });
}
