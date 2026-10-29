import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:uuid/uuid.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/domain/timer_duration.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';
import 'package:visual_time_counter/core/persistence/hive_bootstrap.dart';
import 'package:visual_time_counter/features/presets/data/preset_repository.dart';
import 'package:visual_time_counter/features/presets/data/preset_seeds.dart';
import 'package:visual_time_counter/features/settings/data/settings_repository.dart';
import 'package:visual_time_counter/startup_state.dart';

/// Presets survive closing and reopening the real storage of each platform
/// (files on Android and Linux, IndexedDB on the Web), with their order
/// (US5 scenario 3, contracts/persistence-schema).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const clock = Clock();
  const storageFolder = 'presets_persist_test';
  final bathConfig = TimerConfig.defaults.copyWith(
    duration: TimerDuration(const Duration(minutes: 10)),
    visual: const BankImageSource('bank:hygiene/bath'),
  );

  setUp(() => Hive.initFlutter(storageFolder));

  tearDown(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
  });

  Future<PersistenceBoxes> reopen() async {
    await Hive.close();
    await Hive.initFlutter(storageFolder);
    return await openPersistence(clock: clock);
  }

  PresetRepository repositoryOver(PersistenceBoxes boxes) {
    final settings = SettingsRepository(boxes.settings);
    return PresetRepository(
      presets: boxes.presets,
      readSettings: settings.load,
      updateSettings: (change) => settings.save(change(settings.load())),
      clock: clock,
      newId: const Uuid().v4,
    );
  }

  List<String> names(PresetRepository presets) => [
    for (final preset in presets.list()) preset.name,
  ];

  testWidgets('create, edit, duplicate, reorder and delete persist', (
    tester,
  ) async {
    var presets = repositoryOver(await openPersistence(clock: clock));
    final bath = await presets.create(name: 'Bath', config: bathConfig);
    final park = await presets.create(
      name: 'Park',
      config: TimerConfig.defaults,
    );
    final homework = await presets.create(
      name: 'Homework',
      config: TimerConfig.defaults,
    );
    await presets.update(park.id, name: 'Playground', config: bathConfig);
    await presets.duplicate(bath.id, suffix: '(copy)');
    await presets.move(homework.id, 0);
    await presets.delete(park.id);

    presets = repositoryOver(await reopen());

    expect(names(presets), ['Homework', 'Bath', 'Bath (copy)']);
    expect([for (final p in presets.list()) p.order], [0, 1, 2]);
    expect(presets.find(bath.id)!.config, bathConfig);
    expect(presets.find(park.id), isNull);
  });

  testWidgets('the examples are seeded once across restarts', (tester) async {
    final seeds = [
      PresetSeed(name: 'Brush teeth', config: bathConfig),
      const PresetSeed(name: 'Homework', config: TimerConfig.defaults),
    ];
    var boxes = await openPersistence(clock: clock);
    await loadStartupState(boxes: boxes, clock: clock, examplePresets: seeds);
    expect(boxes.presets.length, 2);
    await repositoryOver(boxes).delete(repositoryOver(boxes).list().first.id);

    boxes = await reopen();
    await loadStartupState(boxes: boxes, clock: clock, examplePresets: seeds);

    expect(names(repositoryOver(boxes)), ['Homework']);
  });
}
