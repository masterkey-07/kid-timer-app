import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/a11y/announce_throttle.dart';
import 'package:visual_time_counter/core/domain/color_token.dart';
import 'package:visual_time_counter/core/domain/dial_direction.dart';
import 'package:visual_time_counter/core/domain/dial_scale.dart';
import 'package:visual_time_counter/core/domain/palette_id.dart';
import 'package:visual_time_counter/core/domain/sound_id.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';
import 'package:visual_time_counter/core/platform/alarm/alarm_scheduler.dart';
import 'package:visual_time_counter/core/platform/providers.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';
import 'package:visual_time_counter/features/timer/application/setup_config_controller.dart';

import '../../../helpers/a11y_expectations.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/test_app.dart';

const _reliableAlarm = AlarmCapabilities(
  scheduling: SchedulingSupport.native,
  notifications: PermissionState.granted,
  exactAlarm: PermissionState.granted,
);

/// The settings screen (contracts/ui/06 §6.1; FR-050 to FR-053).
void main() {
  late TestAppDependencies dependencies;

  setUp(() async => dependencies = await TestAppDependencies.create());
  tearDown(() => dependencies.dispose());

  Finder byKey(String key) => find.byKey(Key(key));

  Future<void> openSettings(
    WidgetTester tester, {
    AppSettings settings = AppSettings.initial,
    ScreenClass screen = ScreenClass.compact,
    double textScale = 1,
  }) async {
    await tester.pumpKidTimerApp(
      dependencies,
      settings: settings,
      screen: screen,
      textScale: textScale,
    );
    await tester.pumpAndSettle();
    await tester.tap(byKey('home.openSettings'));
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, String key) async {
    await tester.ensureVisible(byKey(key));
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await reveal(tester, key);
    await tester.tap(byKey(key));
    await tester.pumpAndSettle();
  }

  /// Opens the dropdown [key] and picks [option]; the open menu also holds
  /// the selected item, so the last match is the one in the menu.
  Future<void> pick(WidgetTester tester, String key, String option) async {
    await tapKey(tester, key);
    await tester.tap(byKey(option).last);
    await tester.pumpAndSettle();
  }

  AppSettings saved() => dependencies.settingsRepository.load();

  group('sections', () {
    testWidgets('home opens the settings with every section', (tester) async {
      await openSettings(tester);

      expect(byKey('settings.screen'), findsOneWidget);
      for (final key in [
        'settings.section.appearance',
        'settings.section.sound',
        'settings.section.childMode',
        'settings.section.alarm',
        'settings.section.accessibility',
        'settings.section.images',
      ]) {
        await reveal(tester, key);
        expect(byKey(key), findsOneWidget, reason: key);
      }
    });

    testWidgets('My images opens the list with the count', (tester) async {
      await openSettings(tester);
      await reveal(tester, 'settings.myImages');

      expect(tester.textOf('settings.myImages'), 'My images (0)');
      await tapKey(tester, 'settings.myImages');

      expect(byKey('mine.screen'), findsOneWidget);
    });
  });

  group('appearance', () {
    testWidgets('the theme persists and applies at once', (tester) async {
      await openSettings(tester);

      await pick(tester, 'settings.theme', 'settings.theme.dark');

      expect(saved().themeMode, AppThemeMode.dark);
      final context = tester.element(byKey('settings.screen'));
      expect(Theme.of(context).brightness, Brightness.dark);
    });

    testWidgets('scale, direction and digits are saved as defaults', (
      tester,
    ) async {
      await openSettings(tester);

      await pick(tester, 'settings.scale', 'settings.scale.min15');
      await pick(
        tester,
        'settings.direction',
        'settings.direction.counterClockwise',
      );
      await tapKey(tester, 'settings.digits');

      final defaults = saved().defaults;
      expect(defaults.scale, DialScale.min15);
      expect(defaults.direction, DialDirection.counterClockwise);
      expect(defaults.showDigits, isFalse);
    });

    testWidgets('the palette and the single color are saved', (tester) async {
      await openSettings(tester);

      await pick(tester, 'settings.palette', 'settings.palette.single');
      await pick(tester, 'settings.color', 'settings.color.purple');

      expect(
        saved().defaults.visual,
        PaletteSource(
          paletteId: PaletteId.single,
          singleColor: ColorToken.purple,
        ),
      );
    });

    testWidgets('the color choice only appears for the single palette', (
      tester,
    ) async {
      await openSettings(tester);
      expect(byKey('settings.color'), findsNothing);

      await pick(tester, 'settings.palette', 'settings.palette.single');

      expect(byKey('settings.color'), findsOneWidget);
    });

    testWidgets('changing the scale updates what home shows (lastConfig)', (
      tester,
    ) async {
      await openSettings(tester);

      await pick(tester, 'settings.scale', 'settings.scale.min10');

      expect(saved().lastConfig.scale, DialScale.min10);
    });
  });

  testWidgets('home follows a changed default when going back', (tester) async {
    await openSettings(tester);

    await pick(tester, 'settings.scale', 'settings.scale.min10');
    await tester.pageBack();
    await tester.pumpAndSettle();

    final home = ProviderScope.containerOf(
      tester.element(byKey('home.screen')),
    );
    expect(home.read(setupConfigProvider).scale, DialScale.min10);
  });

  group('sound and vibration', () {
    testWidgets('the sound row opens the picker and saves the choice', (
      tester,
    ) async {
      await openSettings(tester);

      await tapKey(tester, 'settings.sound');
      await tester.tap(byKey('soundPicker.sound.harp'));
      await tester.pumpAndSettle();

      expect(saved().defaults.soundId, const SoundId('harp'));
      expect(dependencies.audio.previewing, const SoundId('harp'));
    });

    testWidgets('ticking and its volume are saved', (tester) async {
      await openSettings(tester);

      await tapKey(tester, 'settings.tick');
      await reveal(tester, 'settings.tickVolume');
      await tester.drag(byKey('settings.tickVolume'), const Offset(1000, 0));
      await tester.pumpAndSettle();

      expect(saved().defaults.tickEnabled, isTrue);
      expect(saved().defaults.tickVolume, 1.0);
    });

    testWidgets('the tick volume is disabled while ticking is off', (
      tester,
    ) async {
      await openSettings(tester);
      await reveal(tester, 'settings.tickVolume');

      expect(
        tester.widget<Slider>(byKey('settings.tickVolume')).onChanged,
        isNull,
      );
    });

    testWidgets('vibration is saved', (tester) async {
      await openSettings(tester);

      await tapKey(tester, 'settings.vibrate');

      expect(saved().defaults.vibrate, isFalse);
    });

    testWidgets('vibration is hidden without a vibrator', (tester) async {
      dependencies.haptics = FakeHaptics(hasVibrator: false);
      await openSettings(tester);

      expect(byKey('settings.vibrate'), findsNothing);
    });
  });

  group('accessibility', () {
    testWidgets('the announcement interval is saved', (tester) async {
      await openSettings(tester);

      await pick(tester, 'settings.a11yInterval', 'settings.a11yInterval.off');

      expect(saved().a11yAnnounceInterval, AnnounceInterval.off);
    });
  });

  group('alarm status', () {
    Future<void> openWith(
      WidgetTester tester,
      AlarmCapabilities capabilities, {
      AppPlatform platform = AppPlatform.android,
    }) async {
      dependencies
        ..platform = platform
        ..alarms.capabilitiesValue = capabilities;
      await openSettings(tester);
      await reveal(tester, 'settings.alarmStatus');
    }

    testWidgets('says the alarm is active when it is reliable', (tester) async {
      await openWith(tester, _reliableAlarm);

      expect(tester.textOf('settings.alarmStatus'), 'Alarm active');
      expect(byKey('settings.alarmFix'), findsNothing);
    });

    testWidgets('says the app must stay open where the OS cannot ring', (
      tester,
    ) async {
      await openWith(
        tester,
        AlarmCapabilities.unsupported,
        platform: AppPlatform.linux,
      );

      expect(
        tester.textOf('settings.alarmStatus'),
        'On this device the alarm only rings with the app open.',
      );
      expect(byKey('settings.alarmFix'), findsNothing);
    });

    testWidgets('notifications off offers to open the notification settings', (
      tester,
    ) async {
      await openWith(
        tester,
        const AlarmCapabilities(
          scheduling: SchedulingSupport.native,
          notifications: PermissionState.denied,
          exactAlarm: PermissionState.granted,
        ),
      );

      expect(
        tester.textOf('settings.alarmStatus'),
        'Notifications are off: the alarm only rings with the app open.',
      );
      await tapKey(tester, 'settings.alarmFix');
      expect(dependencies.systemSettings.opened, ['notifications']);
    });

    testWidgets('no exact alarm offers to open the exact alarm setting', (
      tester,
    ) async {
      await openWith(
        tester,
        const AlarmCapabilities(
          scheduling: SchedulingSupport.inexactOnly,
          notifications: PermissionState.granted,
          exactAlarm: PermissionState.denied,
        ),
      );

      expect(
        tester.textOf('settings.alarmStatus'),
        'Exact alarms are off: the alarm may ring a few minutes late.',
      );
      await tapKey(tester, 'settings.alarmFix');
      expect(dependencies.systemSettings.opened, ['exactAlarm']);
    });

    testWidgets('the fix button is Android only', (tester) async {
      await openWith(
        tester,
        const AlarmCapabilities(
          scheduling: SchedulingSupport.native,
          notifications: PermissionState.denied,
          exactAlarm: PermissionState.granted,
        ),
        platform: AppPlatform.ios,
      );

      expect(byKey('settings.alarmFix'), findsNothing);
    });

    testWidgets('the help link opens the battery help', (tester) async {
      await openWith(tester, _reliableAlarm);

      await tapKey(tester, 'settings.alarmHelp');

      expect(byKey('battery.screen'), findsOneWidget);
    });
  });

  testWidgets('is in Portuguese when the system is', (tester) async {
    await tester.pumpKidTimerApp(dependencies, locale: const Locale('pt'));
    await tester.pumpAndSettle();
    await tester.tap(byKey('home.openSettings'));
    await tester.pumpAndSettle();

    expect(find.text('Configurações'), findsWidgets);
    expect(find.text('Aparência'), findsOneWidget);
  });

  testWidgets('meets the accessibility guidelines', (tester) async {
    await openSettings(tester);

    await expectMeetsA11yGuidelines(tester);
  });

  for (final screen in ScreenClass.values) {
    testWidgets('lays out without overflow (${screen.name})', (tester) async {
      await openSettings(tester, screen: screen);

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('lays out without overflow at 200% text', (tester) async {
    await openSettings(tester, textScale: maxTextScale);

    expect(tester.takeException(), isNull);
  });
}
