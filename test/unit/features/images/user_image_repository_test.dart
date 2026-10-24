import 'dart:io';
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:mocktail/mocktail.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';
import 'package:visual_time_counter/core/persistence/boxes.dart';
import 'package:visual_time_counter/features/images/data/user_image_repository.dart';
import 'package:visual_time_counter/features/images/domain/image_asset.dart';
import 'package:visual_time_counter/features/images/domain/image_processor.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';

import '../../../helpers/hive_test_utils.dart';

class _MockMetaBox extends Mock implements Box<Map<dynamic, dynamic>>;

class _MockBytesBox extends Mock implements LazyBox<Uint8List>;

final _now = DateTime.utc(2026, 10, 24, 12);
final _jpeg = ProcessedImage(
  jpegBytes: Uint8List.fromList(List.generate(1000, (index) => index % 256)),
  width: 1024,
  height: 1024,
);
const _storageFull = FileSystemException('No space left on device');

void main() {
  useTemporaryHive();

  late Box<Map<dynamic, dynamic>> meta;
  late LazyBox<Uint8List> bytes;
  late Box<Map<dynamic, dynamic>> presets;
  late AppSettings settings;
  late int nextId;

  setUp(() async {
    meta = await Hive.openBox<Map<dynamic, dynamic>>(BoxNames.userImagesMeta);
    bytes = await Hive.openLazyBox<Uint8List>(BoxNames.userImages);
    presets = await Hive.openBox<Map<dynamic, dynamic>>(BoxNames.presets);
    settings = AppSettings.initial;
    nextId = 0;
  });

  UserImageRepository repository({
    Box<Map<dynamic, dynamic>>? metaBox,
    LazyBox<Uint8List>? bytesBox,
  }) => UserImageRepository(
    meta: metaBox ?? meta,
    bytes: bytesBox ?? bytes,
    presets: presets,
    readSettings: () => settings,
    updateSettings: (change) async => settings = change(settings),
    clock: Clock.fixed(_now),
    newId: () => 'image-${nextId++}',
  );

  group('add', () {
    test('writes the bytes and then the metadata', () async {
      final image = await repository().add(_jpeg, label: '  Lucas  ');

      expect(image.id, 'image-0');
      expect(image.label, 'Lucas');
      expect(image.createdAt, _now);
      expect(image.width, 1024);
      expect(image.height, 1024);
      expect(image.byteLength, _jpeg.jpegBytes.length);
      expect(await bytes.get('image-0'), _jpeg.jpegBytes);
      expect(meta.get('image-0'), isNotNull);
      expect(meta.get('image-0')!['schemaVersion'], 1);
    });

    test('stores no label when it is blank', () async {
      final image = await repository().add(_jpeg, label: '   ');

      expect(image.label, isNull);
    });

    test('rejects labels over 40 characters', () {
      expect(repository().add(_jpeg, label: 'x' * 41), throwsArgumentError);
    });

    test('rejects the 51st image', () async {
      final images = repository();
      for (var index = 0; index < UserImageRepository.maxImages; index++) {
        await images.add(_jpeg);
      }

      await expectLater(
        images.add(_jpeg),
        throwsA(isA<UserImageLimitReached>()),
      );
      expect(images.count, UserImageRepository.maxImages);
      expect(bytes.length, UserImageRepository.maxImages);
    });

    test('leaves nothing behind when the bytes cannot be written', () async {
      final failingBytes = _MockBytesBox();
      when(() => failingBytes.put(any(), any())).thenThrow(_storageFull);

      await expectLater(
        repository(bytesBox: failingBytes).add(_jpeg),
        throwsA(isA<FileSystemException>()),
      );
      expect(meta.isEmpty, isTrue);
    });

    test(
      'removes the written bytes when the metadata cannot be written',
      () async {
        final failingMeta = _MockMetaBox();
        when(() => failingMeta.length).thenReturn(0);
        when(() => failingMeta.put(any(), any())).thenThrow(_storageFull);

        await expectLater(
          repository(metaBox: failingMeta).add(_jpeg),
          throwsA(isA<FileSystemException>()),
        );
        expect(bytes.isEmpty, isTrue);
      },
    );
  });

  group('reading', () {
    test('lists the images oldest first and reads their bytes', () async {
      var now = _now;
      final images = UserImageRepository(
        meta: meta,
        bytes: bytes,
        presets: presets,
        readSettings: () => settings,
        updateSettings: (change) async => settings = change(settings),
        clock: Clock(() => now),
        newId: () => 'image-${nextId++}',
      );
      await images.add(_jpeg, label: 'first');
      now = now.add(const Duration(minutes: 1));
      await images.add(_jpeg, label: 'second');

      expect(images.list().map((image) => image.label), ['first', 'second']);
      expect(images.count, 2);
      expect(images.find('image-1')?.label, 'second');
      expect(images.find('missing'), isNull);
      expect(await images.readBytes('image-0'), _jpeg.jpegBytes);
      expect(await images.readBytes('missing'), isNull);
    });

    test('round-trips the metadata document', () {
      final image = UserImageAsset(
        id: 'a',
        label: 'Park',
        createdAt: _now,
        width: 1024,
        height: 1024,
        byteLength: 1234,
      );

      expect(UserImageAsset.fromJson(image.toJson()), image);
      expect(image.toJson()['createdAt'], '2026-10-24T12:00:00.000Z');
    });
  });

  group('rename', () {
    test('changes the label', () async {
      final images = repository();
      final image = await images.add(_jpeg, label: 'old');

      await images.rename(image.id, ' new ');

      expect(images.find(image.id)?.label, 'new');
    });
  });

  group('references', () {
    test('counts the presets and the settings that use an image', () async {
      final images = repository();
      final image = await images.add(_jpeg);
      final other = await images.add(_jpeg);
      await _putPreset(presets, 'p1', 'Brush teeth', UserImageSource(image.id));
      await _putPreset(presets, 'p2', 'Park', UserImageSource(other.id));
      await _putPreset(presets, 'p3', 'Bath', UserImageSource(image.id));
      settings = settings.copyWith(
        lastConfig: _configWith(UserImageSource(image.id)),
      );

      final references = images.referencesTo(image.id);

      expect(references.presetNames, ['Brush teeth', 'Bath']);
      expect(references.isInLastConfig, isTrue);
      expect(references.isInDefaults, isFalse);
      expect(references.count, 3);
      expect(images.referencesTo(other.id).count, 1);
    });
  });

  group('delete', () {
    test(
      'removes metadata and bytes and switches references to colors',
      () async {
        final images = repository();
        final image = await images.add(_jpeg);
        final kept = await images.add(_jpeg);
        await _putPreset(presets, 'p1', 'Bath', UserImageSource(image.id));
        await _putPreset(presets, 'p2', 'Park', UserImageSource(kept.id));
        settings = settings.copyWith(
          defaults: _configWith(UserImageSource(image.id)),
          lastConfig: _configWith(UserImageSource(image.id)),
        );

        await images.delete(image.id);

        expect(meta.get(image.id), isNull);
        expect(await bytes.get(image.id), isNull);
        expect(images.list().map((image) => image.id), [kept.id]);
        expect(_presetVisual(presets, 'p1'), VisualSource.defaultSource);
        expect(_presetVisual(presets, 'p2'), UserImageSource(kept.id));
        expect(settings.defaults.visual, VisualSource.defaultSource);
        expect(settings.lastConfig.visual, VisualSource.defaultSource);
        expect(images.referencesTo(image.id).count, 0);
      },
    );

    test('leaves settings untouched when they do not use the image', () async {
      final images = repository();
      final image = await images.add(_jpeg);
      var updates = 0;
      final counting = UserImageRepository(
        meta: meta,
        bytes: bytes,
        presets: presets,
        readSettings: () => settings,
        updateSettings: (change) async {
          updates++;
          settings = change(settings);
        },
        clock: Clock.fixed(_now),
        newId: () => 'unused',
      );

      await counting.delete(image.id);

      expect(updates, 0);
      expect(images.count, 0);
    });
  });

  group('removeOrphans', () {
    test('drops bytes without metadata and metadata without bytes', () async {
      final images = repository();
      final kept = await images.add(_jpeg);
      final withoutBytes = await images.add(_jpeg);
      await bytes.delete(withoutBytes.id);
      await bytes.put('bytes-only', _jpeg.jpegBytes);

      final removed = await images.removeOrphans();

      expect(removed, 2);
      expect(images.list().map((image) => image.id), [kept.id]);
      expect(bytes.keys, [kept.id]);
    });

    test('drops unreadable metadata documents', () async {
      final images = repository();
      await bytes.put('broken', _jpeg.jpegBytes);
      await meta.put('broken', {'schemaVersion': 1, 'id': 'broken'});

      expect(await images.removeOrphans(), 1);
      expect(meta.isEmpty, isTrue);
      expect(bytes.isEmpty, isTrue);
    });
  });
}

TimerConfig _configWith(VisualSource visual) =>
    TimerConfig.defaults.copyWith(visual: visual);

Future<void> _putPreset(
  Box<Map<dynamic, dynamic>> presets,
  String id,
  String name,
  VisualSource visual,
) => presets.put(id, {
  'schemaVersion': 1,
  'id': id,
  'name': name,
  'order': presets.length,
  'isExample': false,
  'favorite': false,
  'config': _configWith(visual).toJson(),
  'createdAt': _now.toIso8601String(),
  'updatedAt': _now.toIso8601String(),
});

VisualSource _presetVisual(Box<Map<dynamic, dynamic>> presets, String id) {
  final config = presets.get(id)!['config']! as Map<dynamic, dynamic>;
  return VisualSource.fromJson(
    (config['visual']! as Map<dynamic, dynamic>).cast<String, Object?>(),
  );
}
