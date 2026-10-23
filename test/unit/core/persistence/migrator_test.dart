import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:visual_time_counter/core/persistence/migrator.dart';

import '../../../helpers/hive_test_utils.dart';

void main() {
  useTemporaryHive();

  final now = DateTime.utc(2026, 10, 23, 12);
  final clock = Clock.fixed(now);

  late Box<Map<dynamic, dynamic>> box;

  setUp(() async => box = await Hive.openBox<Map<dynamic, dynamic>>('presets'));

  Future<Box<Map<dynamic, dynamic>>> backupBox() =>
      Hive.openBox<Map<dynamic, dynamic>>('presets_backup');

  Map<String, Object?> addField(String field, Object value) => {field: value};

  test('leaves documents at the current version untouched', () async {
    await box.put('a', {'schemaVersion': 1, 'name': 'Teeth'});

    final report = await Migrator(
      currentVersion: 1,
      clock: clock,
    ).migrateBox(box);

    expect(box.get('a'), {'schemaVersion': 1, 'name': 'Teeth'});
    expect(report.migratedKeys, isEmpty);
    expect(report.failures, isEmpty);
  });

  test('applies migrations sequentially up to the current version', () async {
    await box.put('a', {'schemaVersion': 1, 'name': 'Teeth'});
    final migrator = Migrator(
      currentVersion: 3,
      clock: clock,
      migrations: {
        1: (doc) => {...doc, ...addField('favorite', false)},
        2: (doc) => {...doc, 'order': doc.containsKey('favorite') ? 0 : -1},
      },
    );

    final report = await migrator.migrateBox(box);

    expect(box.get('a'), {
      'schemaVersion': 3,
      'name': 'Teeth',
      'favorite': false,
      'order': 0,
    });
    expect(report.migratedKeys, ['a']);
    expect(report.failures, isEmpty);
  });

  group('on failure', () {
    test('backs up the original, keeps it and reports the key', () async {
      final original = {'schemaVersion': 1, 'name': 'Teeth'};
      await box.put('a', original);
      final migrator = Migrator(
        currentVersion: 2,
        clock: clock,
        migrations: {1: (_) => throw const FormatException('broken')},
      );

      final report = await migrator.migrateBox(box);

      expect(box.get('a'), original);
      final backups = await backupBox();
      expect(backups.get('a@${now.toIso8601String()}'), original);
      expect(report.failures.single.key, 'a');
      expect(report.failures.single.isDowngrade, isFalse);
      expect(report.hasFailures, isTrue);
    });

    test('a missing migration step is a failure', () async {
      await box.put('a', {'schemaVersion': 1});

      final report = await Migrator(
        currentVersion: 2,
        clock: clock,
      ).migrateBox(box);

      expect(report.failures.single.reason, contains('1'));
    });

    test('a document without schemaVersion is a failure', () async {
      await box.put('a', {'name': 'Teeth'});

      final report = await Migrator(
        currentVersion: 1,
        clock: clock,
      ).migrateBox(box);

      expect(report.failures.single.key, 'a');
    });

    test('does not duplicate an identical backup on the next run', () async {
      await box.put('a', {'schemaVersion': 1});
      final migrator = Migrator(currentVersion: 2, clock: clock);

      await migrator.migrateBox(box);
      final later = Migrator(
        currentVersion: 2,
        clock: Clock.fixed(now.add(const Duration(days: 1))),
      );
      final report = await later.migrateBox(box);

      expect((await backupBox()).length, 1);
      expect(report.failures.single.isNewBackup, isFalse);
    });
  });

  test('a schemaVersion above the supported one never overwrites', () async {
    final newer = {'schemaVersion': 5, 'name': 'From the future'};
    await box.put('a', newer);

    final report = await Migrator(
      currentVersion: 1,
      clock: clock,
    ).migrateBox(box);

    expect(box.get('a'), newer);
    expect((await backupBox()).values.single, newer);
    expect(report.failures.single.isDowngrade, isTrue);
  });

  test(
    'migrations receive a copy and cannot corrupt the stored document',
    () async {
      await box.put('a', {
        'schemaVersion': 1,
        'tags': ['x'],
      });
      final migrator = Migrator(
        currentVersion: 2,
        clock: clock,
        migrations: {
          1: (doc) {
            doc['name'] = 'mutated';
            throw StateError('bug in migration');
          },
        },
      );

      final report = await migrator.migrateBox(box);

      expect(box.get('a'), {
        'schemaVersion': 1,
        'tags': ['x'],
      });
      expect(report.failures.single.reason, contains('bug in migration'));
    },
  );

  test('converts stored maps into JSON-style documents', () {
    final document = toDocument({
      'schemaVersion': 1,
      'config': {
        'visual': {'type': 'bank'},
      },
      'list': [
        {'a': 1},
      ],
    });

    expect(document['config'], isA<Map<String, Object?>>());
    expect((document['config']! as Map)['visual'], isA<Map<String, Object?>>());
    expect((document['list']! as List).single, isA<Map<String, Object?>>());
  });
}
