import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:visual_time_counter/core/persistence/boxes.dart';
import 'package:visual_time_counter/core/persistence/hive_bootstrap.dart';

import '../../../helpers/hive_test_utils.dart';

void main() {
  useTemporaryHive();

  final clock = Clock.fixed(DateTime.utc(2026, 10, 23, 12));

  test('defines the box names of the persistence schema', () {
    expect(BoxNames.documentBoxes, [
      'settings',
      'presets',
      'routines',
      'session',
      'user_images_meta',
    ]);
    expect(BoxNames.userImages, 'user_images');
  });

  test('opens every box, with user_images as a lazy byte box', () async {
    final boxes = await openPersistence(clock: clock);

    for (final name in BoxNames.documentBoxes) {
      expect(Hive.isBoxOpen(name), isTrue, reason: name);
    }
    expect(boxes.userImages, isA<LazyBox<Uint8List>>());
    expect(boxes.settings.name, BoxNames.settings);
    expect(boxes.presets.name, BoxNames.presets);
    expect(boxes.routines.name, BoxNames.routines);
    expect(boxes.session.name, BoxNames.session);
    expect(boxes.userImagesMeta.name, BoxNames.userImagesMeta);
    expect(boxes.migrationFailures, isEmpty);
  });

  test('migrates every document box and reports failures', () async {
    final presets = await Hive.openBox<Map<dynamic, dynamic>>(BoxNames.presets);
    await presets.put('p1', {'schemaVersion': 9});
    await presets.close();

    final boxes = await openPersistence(clock: clock);

    expect(boxes.migrationFailures.single.box, BoxNames.presets);
    expect(boxes.migrationFailures.single.failure.key, 'p1');
    expect(boxes.migrationFailures.single.failure.isDowngrade, isTrue);
  });
}
