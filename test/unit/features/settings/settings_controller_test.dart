import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:visual_time_counter/features/settings/application/app_settings_state.dart';
import 'package:visual_time_counter/features/settings/application/settings_controller.dart';
import 'package:visual_time_counter/features/settings/data/settings_repository.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';

var _boxCount = 0;

void main() {
  late Box<Map<dynamic, dynamic>> settingsBox;
  late SettingsRepository repository;
  late ProviderContainer container;

  setUp(() async {
    settingsBox = await Hive.openBox<Map<dynamic, dynamic>>(
      'settings_controller_${_boxCount++}',
      bytes: Uint8List(0),
    );
    repository = SettingsRepository(settingsBox);
    container = ProviderContainer(
      overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() async {
    container.dispose();
    await settingsBox.close();
  });

  SettingsController controller() => container.read(settingsControllerProvider);

  bool isChildLockEnabled() =>
      container.read(appSettingsProvider).childLockEnabled;

  group('child lock (FR-032)', () {
    test('turning it off asks first and persists when confirmed', () async {
      var asked = 0;

      final changed = await controller().setChildLockEnabled(
        isEnabled: false,
        confirmTurnOff: () async {
          asked++;
          return true;
        },
      );

      expect(changed, isTrue);
      expect(asked, 1);
      expect(isChildLockEnabled(), isFalse);
      expect(repository.load().childLockEnabled, isFalse);
    });

    test('turning it off does nothing when not confirmed', () async {
      final changed = await controller().setChildLockEnabled(
        isEnabled: false,
        confirmTurnOff: () async => false,
      );

      expect(changed, isFalse);
      expect(isChildLockEnabled(), isTrue);
      expect(repository.load(), AppSettings.initial);
    });

    test('turning it on needs no confirmation', () async {
      await container
          .read(appSettingsProvider.notifier)
          .update((settings) => settings.copyWith(childLockEnabled: false));

      final changed = await controller().setChildLockEnabled(
        isEnabled: true,
        confirmTurnOff: () => fail('turning on must not ask'),
      );

      expect(changed, isTrue);
      expect(isChildLockEnabled(), isTrue);
      expect(repository.load().childLockEnabled, isTrue);
    });
  });
}
