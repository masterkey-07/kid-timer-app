import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:mocktail/mocktail.dart';
import 'package:visual_time_counter/core/domain/dial_scale.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/domain/timer_duration.dart';
import 'package:visual_time_counter/features/settings/application/app_settings_state.dart';
import 'package:visual_time_counter/features/settings/data/settings_repository.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';
import 'package:visual_time_counter/features/timer/application/setup_config_controller.dart';

class _MockBox extends Mock implements Box<Map<dynamic, dynamic>>;

class _StorageFull implements Exception {
  const new();
}

final _saved = AppSettings(
  lastConfig: TimerConfig(
    duration: TimerDuration(const Duration(minutes: 3)),
    scale: DialScale.min15,
  ),
);

final _sevenMinutes = TimerDuration(const Duration(minutes: 7));
final _eightMinutes = TimerDuration(const Duration(minutes: 8));

var _boxCount = 0;

void main() {
  late Box<Map<dynamic, dynamic>> settingsBox;
  late ProviderContainer container;

  ProviderContainer containerFor(Box<Map<dynamic, dynamic>> box) =>
      ProviderContainer(
        overrides: [
          restoredSettingsProvider.overrideWithValue(_saved),
          settingsRepositoryProvider.overrideWithValue(SettingsRepository(box)),
        ],
      );

  SetupConfigController controller() =>
      container.read(setupConfigProvider.notifier);

  setUp(() async {
    settingsBox = await Hive.openBox<Map<dynamic, dynamic>>(
      'setup_config_${_boxCount++}',
      bytes: Uint8List(0),
    );
    container = containerFor(settingsBox);
  });

  tearDown(() async {
    container.dispose();
    await settingsBox.close();
  });

  test('starts from the last configuration used (FR-006)', () {
    expect(container.read(setupConfigProvider), _saved.lastConfig);
  });

  test('changes apply immediately', () {
    controller().setDuration(_sevenMinutes);

    expect(container.read(setupConfigProvider).duration, _sevenMinutes);
    expect(container.read(setupConfigProvider).scale, DialScale.min15);
  });

  test('saves lastConfig 300 ms after the last change', () {
    fakeAsync((async) {
      controller().setDuration(_sevenMinutes);
      async.elapse(const Duration(milliseconds: 200));
      controller().setDuration(_eightMinutes);
      async.elapse(const Duration(milliseconds: 299));

      expect(container.read(appSettingsProvider).lastConfig, _saved.lastConfig);
      expect(SettingsRepository(settingsBox).load(), AppSettings.initial);

      async
        ..elapse(const Duration(milliseconds: 1))
        ..flushMicrotasks();

      final expected = _saved.lastConfig.copyWith(duration: _eightMinutes);
      expect(container.read(appSettingsProvider).lastConfig, expected);
      expect(SettingsRepository(settingsBox).load().lastConfig, expected);
    });
  });

  test('a failure to save keeps the configuration on screen', () {
    final failingBox = _MockBox();
    when(() => failingBox.put(any<Object?>(), any()))
        .thenThrow(const _StorageFull());
    container.dispose();
    container = containerFor(failingBox);

    fakeAsync((async) {
      controller().setDuration(_sevenMinutes);
      async
        ..elapse(const Duration(milliseconds: 300))
        ..flushMicrotasks();

      expect(container.read(setupConfigProvider).duration, _sevenMinutes);
    });
  });
}
