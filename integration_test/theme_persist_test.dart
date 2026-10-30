import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:visual_time_counter/core/a11y/announce_throttle.dart';
import 'package:visual_time_counter/core/domain/dial_scale.dart';
import 'package:visual_time_counter/core/domain/sound_id.dart';
import 'package:visual_time_counter/core/persistence/hive_bootstrap.dart';
import 'package:visual_time_counter/features/settings/data/settings_repository.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';

/// The appearance and sound preferences survive closing and reopening the
/// real storage (US6, contracts/persistence-schema).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const clock = Clock();
  const storageFolder = 'theme_persist_test';

  setUp(() => Hive.initFlutter(storageFolder));

  tearDown(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
  });

  Future<SettingsRepository> reopen() async {
    await Hive.close();
    await Hive.initFlutter(storageFolder);
    return SettingsRepository((await openPersistence(clock: clock)).settings);
  }

  testWidgets('the theme and the defaults are restored after a restart', (
    tester,
  ) async {
    final settings = SettingsRepository(
      (await openPersistence(clock: clock)).settings,
    );
    final changed = AppSettings.initial.copyWith(
      themeMode: AppThemeMode.dark,
      a11yAnnounceInterval: AnnounceInterval.off,
      defaults: AppSettings.initial.defaults.copyWith(
        scale: DialScale.min15,
        soundId: const SoundId('marimba'),
        tickEnabled: true,
        tickVolume: 0.2,
      ),
    );
    await settings.save(changed);

    final restored = (await reopen()).load();

    expect(restored.themeMode, AppThemeMode.dark);
    expect(restored.a11yAnnounceInterval, AnnounceInterval.off);
    expect(restored.defaults, changed.defaults);
  });
}
