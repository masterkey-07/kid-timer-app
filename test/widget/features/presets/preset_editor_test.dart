import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_time_counter/core/domain/color_token.dart';
import 'package:visual_time_counter/core/domain/dial_direction.dart';
import 'package:visual_time_counter/core/domain/dial_scale.dart';
import 'package:visual_time_counter/core/domain/palette_id.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/domain/timer_duration.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';
import 'package:visual_time_counter/features/presets/domain/preset.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';

import '../../../helpers/a11y_expectations.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/test_app.dart';

const _pageTransition = Duration(seconds: 1);

/// The preset editor (contracts/ui/05 §5.2, FR-040).
void main() {
  late TestAppDependencies dependencies;

  setUp(() async => dependencies = await TestAppDependencies.create());
  tearDown(() => dependencies.dispose());

  final lastConfig = TimerConfig(
    duration: TimerDuration(const Duration(minutes: 7)),
    alarmVolume: 0.5,
  );

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(_pageTransition);
  }

  Future<void> open(WidgetTester tester, String location) async {
    await tester.pumpKidTimerApp(
      dependencies,
      settings: AppSettings(lastConfig: lastConfig),
    );
    await settle(tester);
    final router = GoRouter.of(
      tester.element(find.byKey(const Key('home.screen'))),
    );
    unawaited(router.push<void>('/presets'));
    await settle(tester);
    unawaited(router.push<void>(location));
    await settle(tester);
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.tap(find.byKey(Key(key)));
    await settle(tester);
  }

  Future<void> enterName(WidgetTester tester, String name) async {
    await tester.enterText(find.byKey(const Key('presetEditor.name')), name);
    await tester.pump();
  }

  Map<String, Object?> stored(String id) =>
      dependencies.presets.get(id)!.cast<String, Object?>();

  TimerConfig storedConfig(String id) => TimerConfig.fromJson(
    (stored(id)['config']! as Map).cast<String, Object?>(),
  );

  group('new preset', () {
    testWidgets('saves the name and the configuration it started from', (
      tester,
    ) async {
      await open(tester, '/presets/new');

      await enterName(tester, '  Brush teeth ');
      await tapKey(tester, 'presetEditor.save');

      expect(find.byKey(const Key('presets.screen')), findsOneWidget);
      expect(find.byKey(const Key('presets.item.preset-0')), findsOneWidget);
      expect(stored('preset-0')['name'], 'Brush teeth');
      expect(storedConfig('preset-0'), lastConfig);
    });

    testWidgets('counts the name characters out of 40', (tester) async {
      await open(tester, '/presets/new');

      await enterName(tester, 'Brush teeth');

      expect(tester.textOf('presetEditor.nameCounter'), '11/40');
    });

    testWidgets('an empty name explains the rule and saves nothing', (
      tester,
    ) async {
      await open(tester, '/presets/new');

      await enterName(tester, '   ');
      await tapKey(tester, 'presetEditor.save');

      expect(find.byKey(const Key('presetEditor.screen')), findsOneWidget);
      expect(find.byKey(const Key('presetEditor.nameError')), findsOneWidget);
      expect(dependencies.presets.isEmpty, isTrue);
    });

    testWidgets('a name over 40 characters explains the rule', (tester) async {
      await open(tester, '/presets/new');

      await enterName(tester, 'a' * (Preset.maxNameLength + 1));
      await tapKey(tester, 'presetEditor.save');

      expect(find.byKey(const Key('presetEditor.nameError')), findsOneWidget);
      expect(dependencies.presets.isEmpty, isTrue);
    });
  });

  group('editing', () {
    testWidgets('changes the duration and keeps the id', (tester) async {
      await dependencies.seedPreset(
        'p1',
        'Bath',
        VisualSource.defaultSource,
        duration: const Duration(minutes: 10),
      );
      await open(tester, '/presets/p1/edit');

      expect(tester.textOf('presetEditor.durationDigits'), '10:00');
      await tapKey(tester, 'presetEditor.plus1');
      await tapKey(tester, 'presetEditor.save');

      expect(find.byKey(const Key('presets.screen')), findsOneWidget);
      expect(storedConfig('p1').duration.value, const Duration(minutes: 11));
      expect(dependencies.presets.length, 1);
    });

    testWidgets('an unknown preset goes back to the list', (tester) async {
      await open(tester, '/presets/missing/edit');

      expect(find.byKey(const Key('presets.screen')), findsOneWidget);
      expect(find.byKey(const Key('presetEditor.screen')), findsNothing);
    });
  });

  group('leaving', () {
    testWidgets('without changes closes at once', (tester) async {
      await open(tester, '/presets/new');

      await tapKey(tester, 'presetEditor.close');

      expect(find.byKey(const Key('presets.screen')), findsOneWidget);
    });

    testWidgets('with changes asks "Discard changes?"', (tester) async {
      await open(tester, '/presets/new');
      await enterName(tester, 'Bath');

      await tapKey(tester, 'presetEditor.close');
      expect(find.byKey(const Key('confirm.dialog')), findsOneWidget);
      await tapKey(tester, 'confirm.cancel');
      expect(find.byKey(const Key('presetEditor.screen')), findsOneWidget);

      await tapKey(tester, 'presetEditor.close');
      await tapKey(tester, 'confirm.confirm');
      expect(find.byKey(const Key('presets.screen')), findsOneWidget);
      expect(dependencies.presets.isEmpty, isTrue);
    });

    testWidgets('the system back asks too', (tester) async {
      await open(tester, '/presets/new');
      await enterName(tester, 'Bath');

      await tester.binding.handlePopRoute();
      await settle(tester);

      expect(find.byKey(const Key('confirm.dialog')), findsOneWidget);
    });
  });

  group('appearance and sound', () {
    testWidgets('scale, direction and colors are saved', (tester) async {
      await open(tester, '/presets/new');
      await enterName(tester, 'Bath');

      await tapKey(tester, 'presetEditor.scale.min15');
      await tapKey(tester, 'presetEditor.direction.counterClockwise');
      await tapKey(tester, 'presetEditor.palette.single');
      await tapKey(tester, 'presetEditor.color.purple');
      await tapKey(tester, 'presetEditor.save');

      final config = storedConfig('preset-0');
      expect(config.scale, DialScale.min15);
      expect(config.direction, DialDirection.counterClockwise);
      expect(
        config.visual,
        PaletteSource(
          paletteId: PaletteId.single,
          singleColor: ColorToken.purple,
        ),
      );
    });

    testWidgets('colors are hidden while an image is chosen; ✕ brings them '
        'back', (tester) async {
      await dependencies.seedPreset(
        'p1',
        'Bath',
        const BankImageSource('bank:hygiene/bath'),
      );
      await open(tester, '/presets/p1/edit');

      expect(find.byKey(const Key('presetEditor.palette')), findsNothing);
      await tapKey(tester, 'presetEditor.imageClear');

      expect(find.byKey(const Key('presetEditor.palette')), findsOneWidget);
    });

    testWidgets('Image opens the picker', (tester) async {
      await open(tester, '/presets/new');

      await tapKey(tester, 'presetEditor.image');

      expect(find.byKey(const Key('images.screen')), findsOneWidget);
    });

    testWidgets('the preview plays the sound at the chosen volume', (
      tester,
    ) async {
      await open(tester, '/presets/new');

      await tapKey(tester, 'presetEditor.soundPreview');

      expect(
        dependencies.audio.calls,
        contains('playPreview(chime_soft, 0.5)'),
      );
    });

    testWidgets('ticking, vibration and digits are saved', (tester) async {
      await open(tester, '/presets/new');
      await enterName(tester, 'Bath');

      await tapKey(tester, 'presetEditor.tick');
      await tapKey(tester, 'presetEditor.vibrate');
      await tapKey(tester, 'presetEditor.digits');
      await tapKey(tester, 'presetEditor.save');

      final config = storedConfig('preset-0');
      expect(config.tickEnabled, isTrue);
      expect(config.vibrate, isFalse);
      expect(config.showDigits, isFalse);
    });

    testWidgets('vibration is hidden without a vibrator', (tester) async {
      dependencies.haptics = FakeHaptics(hasVibrator: false);
      await open(tester, '/presets/new');

      expect(find.byKey(const Key('presetEditor.vibrate')), findsNothing);
    });

    testWidgets('the volume slider changes the alarm volume', (tester) async {
      await open(tester, '/presets/new');
      await enterName(tester, 'Bath');
      final slider = find.byKey(const Key('presetEditor.volume'));
      await tester.ensureVisible(slider);

      await tester.tapAt(tester.getTopRight(slider) + const Offset(-24, 24));
      await tapKey(tester, 'presetEditor.save');

      expect(storedConfig('preset-0').alarmVolume, greaterThan(0.9));
    });
  });

  testWidgets('meets the accessibility guidelines', (tester) async {
    await open(tester, '/presets/new');
    await expectMeetsA11yGuidelines(tester);
  });
}
