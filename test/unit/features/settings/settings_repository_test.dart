import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:mocktail/mocktail.dart';
import 'package:visual_time_counter/core/a11y/announce_throttle.dart';
import 'package:visual_time_counter/core/domain/dial_scale.dart';
import 'package:visual_time_counter/core/domain/palette_id.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/domain/timer_duration.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';
import 'package:visual_time_counter/features/settings/data/settings_repository.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';

import '../../../helpers/fixtures.dart';
import '../../../helpers/hive_test_utils.dart';

class _MockBox extends Mock implements Box<Map<dynamic, dynamic>>;

void main() {
  group('AppSettings.initial (data-model defaults)', () {
    const settings = AppSettings.initial;

    test('match the data model', () {
      expect(settings.themeMode, AppThemeMode.system);
      expect(settings.childLockEnabled, isTrue);
      expect(settings.a11yAnnounceInterval, AnnounceInterval.oneMin);
      expect(settings.defaults, TimerConfig.defaults);
      expect(settings.lastConfig, TimerConfig.defaults);
      expect(settings.onboarding, OnboardingFlags.none);
    });

    test('every onboarding flag starts false', () {
      const flags = OnboardingFlags.none;

      expect(flags.exactAlarmExplained, isFalse);
      expect(flags.iosSilentWarned, isFalse);
      expect(flags.webKeepOpenSeen, isFalse);
      expect(flags.examplesSeeded, isFalse);
      expect(flags.dialHintDismissed, isFalse);
    });
  });

  group('AppSettings', () {
    test('copyWith changes only the given fields', () {
      final lastConfig = TimerConfig.defaults.copyWith(scale: DialScale.min5);
      final changed = AppSettings.initial.copyWith(
        themeMode: AppThemeMode.light,
        childLockEnabled: false,
        a11yAnnounceInterval: AnnounceInterval.off,
        lastConfig: lastConfig,
        onboarding: OnboardingFlags.none.copyWith(webKeepOpenSeen: true),
      );

      expect(changed.themeMode, AppThemeMode.light);
      expect(changed.childLockEnabled, isFalse);
      expect(changed.a11yAnnounceInterval, AnnounceInterval.off);
      expect(changed.defaults, TimerConfig.defaults);
      expect(changed.lastConfig, lastConfig);
      expect(changed.onboarding.webKeepOpenSeen, isTrue);
      expect(changed, isNot(AppSettings.initial));
      expect(AppSettings.initial.copyWith(), AppSettings.initial);
      expect(
        AppSettings.initial.copyWith().hashCode,
        AppSettings.initial.hashCode,
      );
    });

    test('OnboardingFlags.copyWith sets each flag', () {
      final all = OnboardingFlags.none.copyWith(
        exactAlarmExplained: true,
        iosSilentWarned: true,
        webKeepOpenSeen: true,
        examplesSeeded: true,
        dialHintDismissed: true,
      );

      expect(all.toJson().values, everyElement(isTrue));
      expect(OnboardingFlags.fromJson(all.toJson()), all);
      expect(all.hashCode, OnboardingFlags.fromJson(all.toJson()).hashCode);
    });

    test('JSON round-trips', () {
      final settings = AppSettings.initial.copyWith(
        themeMode: AppThemeMode.dark,
        defaults: TimerConfig.defaults.copyWith(
          visual: PaletteSource(paletteId: PaletteId.calm),
        ),
      );

      expect(AppSettings.fromJson(settings.toJson()), settings);
      expect(settings.toJson()['schemaVersion'], 1);
    });

    test('missing onboarding flags default to false', () {
      final json = AppSettings.initial.toJson()
        ..['onboarding'] = {'examplesSeeded': true};

      final flags = AppSettings.fromJson(json).onboarding;

      expect(flags.examplesSeeded, isTrue);
      expect(flags.dialHintDismissed, isFalse);
    });

    test('rejects an unsupported schema version', () {
      final json = AppSettings.initial.toJson()..['schemaVersion'] = 2;

      expect(() => AppSettings.fromJson(json), throwsFormatException);
    });

    test('rejects an unknown theme mode', () {
      final json = AppSettings.initial.toJson()..['themeMode'] = 'neon';

      expect(() => AppSettings.fromJson(json), throwsFormatException);
    });
  });

  group('SettingsRepository with Hive', () {
    useTemporaryHive();

    late Box<Map<dynamic, dynamic>> box;
    late SettingsRepository repository;

    setUp(() async {
      box = await Hive.openBox<Map<dynamic, dynamic>>('settings');
      repository = SettingsRepository(box);
    });

    test('load returns the defaults on first use', () {
      expect(repository.load(), AppSettings.initial);
    });

    test('saves and reloads lastConfig (FR-006)', () async {
      final lastConfig = TimerConfig.defaults.copyWith(
        duration: TimerDuration(const Duration(minutes: 12)),
        visual: const BankImageSource('bank:meal/plate'),
      );

      await repository.save(
        AppSettings.initial.copyWith(lastConfig: lastConfig),
      );
      await box.close();
      final reopened = await Hive.openBox<Map<dynamic, dynamic>>('settings');

      expect(SettingsRepository(reopened).load().lastConfig, lastConfig);
    });

    test('saves onboarding flags', () async {
      await repository.save(
        AppSettings.initial.copyWith(
          onboarding: OnboardingFlags.none.copyWith(dialHintDismissed: true),
        ),
      );

      expect(repository.load().onboarding.dialHintDismissed, isTrue);
    });

    test('loads the v1 fixture', () async {
      await box.put('app', readJsonFixture('persistence/v1/settings_app.json'));

      final settings = repository.load();

      expect(settings.themeMode, AppThemeMode.dark);
      expect(settings.childLockEnabled, isFalse);
      expect(settings.a11yAnnounceInterval, AnnounceInterval.fiveMin);
      expect(
        settings.defaults.visual,
        PaletteSource(paletteId: PaletteId.calm),
      );
      expect(settings.defaults.alarmVolume, 0.5);
      expect(settings.lastConfig.duration.value, const Duration(minutes: 2));
      expect(settings.lastConfig.scale, DialScale.min15);
      expect(
        settings.lastConfig.visual,
        const BankImageSource('bank:hygiene/toothbrush'),
      );
      expect(settings.onboarding.exactAlarmExplained, isTrue);
      expect(settings.onboarding.webKeepOpenSeen, isTrue);
      expect(settings.onboarding.examplesSeeded, isTrue);
      expect(settings.onboarding.iosSilentWarned, isFalse);
    });

    test('a corrupt document surfaces as a FormatException', () async {
      await box.put('app', {'schemaVersion': 1});

      expect(repository.load, throwsFormatException);
    });
  });

  test('save writes then flushes', () async {
    final box = _MockBox();
    when(() => box.put(any<Object?>(), any())).thenAnswer((_) async {});
    when(box.flush).thenAnswer((_) async {});

    await SettingsRepository(box).save(AppSettings.initial);

    verifyInOrder([
      () => box.put('app', AppSettings.initial.toJson()),
      box.flush,
    ]);
  });
}
