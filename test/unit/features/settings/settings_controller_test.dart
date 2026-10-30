import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:visual_time_counter/core/a11y/announce_throttle.dart';
import 'package:visual_time_counter/core/domain/dial_direction.dart';
import 'package:visual_time_counter/core/domain/dial_scale.dart';
import 'package:visual_time_counter/core/domain/sound_id.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/domain/timer_duration.dart';
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

  group('theme and accessibility', () {
    test('the theme persists', () async {
      await controller().setThemeMode(AppThemeMode.dark);

      expect(container.read(appSettingsProvider).themeMode, AppThemeMode.dark);
      expect(repository.load().themeMode, AppThemeMode.dark);
    });

    test('the announcement interval persists', () async {
      await controller().setA11yAnnounceInterval(AnnounceInterval.off);

      expect(repository.load().a11yAnnounceInterval, AnnounceInterval.off);
    });
  });

  group('defaults for new timers', () {
    test('each default persists', () async {
      await controller().changeDefaults(
        (defaults) => defaults.copyWith(
          scale: DialScale.min15,
          direction: DialDirection.counterClockwise,
          soundId: const SoundId('marimba'),
          alarmVolume: 0.4,
          tickEnabled: true,
          tickVolume: 0.2,
          vibrate: false,
          showDigits: false,
        ),
      );

      final saved = repository.load().defaults;
      expect(saved.scale, DialScale.min15);
      expect(saved.direction, DialDirection.counterClockwise);
      expect(saved.soundId, const SoundId('marimba'));
      expect(saved.alarmVolume, 0.4);
      expect(saved.tickEnabled, isTrue);
      expect(saved.tickVolume, 0.2);
      expect(saved.vibrate, isFalse);
      expect(saved.showDigits, isFalse);
    });

    test('lastConfig follows while it still equals the old default', () async {
      await controller().changeDefaults(
        (defaults) => defaults.copyWith(scale: DialScale.min10),
      );

      final settings = repository.load();
      expect(settings.defaults.scale, DialScale.min10);
      expect(settings.lastConfig, settings.defaults);
    });

    test('lastConfig is kept once the adult has changed it', () async {
      final adjusted = TimerConfig.defaults.copyWith(
        duration: const TimerDuration(Duration(minutes: 7)),
      );
      await container
          .read(appSettingsProvider.notifier)
          .update((settings) => settings.copyWith(lastConfig: adjusted));

      await controller().changeDefaults(
        (defaults) => defaults.copyWith(scale: DialScale.min10),
      );

      expect(repository.load().lastConfig, adjusted);
    });
  });
}
