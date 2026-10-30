import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/domain/sound_id.dart';
import 'package:visual_time_counter/features/timer/presentation/widgets/sound_picker_sheet.dart';

import '../../../helpers/a11y_expectations.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/test_app.dart';

const _marimba = SoundId('marimba');
const _harp = SoundId('harp');
const _volume = 0.4;

/// The sound list with preview and volume (contracts/ui/01 "Sound",
/// contracts/ui/06; FR-052).
void main() {
  late TestAppDependencies dependencies;

  setUp(() async => dependencies = await TestAppDependencies.create());
  tearDown(() => dependencies.dispose());

  Finder byKey(String key) => find.byKey(Key(key));

  SoundId? chosenSound;
  double? chosenVolume;

  Future<void> pumpSheet(
    WidgetTester tester, {
    SoundId selected = SoundId.chimeSoft,
    Locale locale = const Locale('en'),
  }) async {
    chosenSound = null;
    chosenVolume = null;
    await tester.pumpApp(
      SoundPickerSheet(
        selected: selected,
        volume: _volume,
        onSoundChanged: (sound) => chosenSound = sound,
        onVolumeChanged: (volume) => chosenVolume = volume,
      ),
      overrides: dependencies.overrides(),
      locale: locale,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists the alarm sounds and "no sound", not the tick', (
    tester,
  ) async {
    await pumpSheet(tester);

    expect(byKey('soundPicker.sound.chime_soft'), findsOneWidget);
    expect(byKey('soundPicker.sound.marimba'), findsOneWidget);
    expect(byKey('soundPicker.sound.none'), findsOneWidget);
    expect(byKey('soundPicker.sound.tick_soft'), findsNothing);
    expect(byKey('soundPicker.sound.transition_soft'), findsNothing);
  });

  testWidgets('names the sounds in the app language', (tester) async {
    await pumpSheet(tester, locale: const Locale('pt'));

    expect(find.text('Sino suave'), findsOneWidget);
    expect(find.text('Sem som'), findsOneWidget);
  });

  testWidgets('marks the selected sound', (tester) async {
    await pumpSheet(tester, selected: _marimba);

    final selected = tester.widget<ListTile>(
      byKey('soundPicker.sound.marimba'),
    );
    expect(selected.selected, isTrue);
    expect(
      tester.widget<ListTile>(byKey('soundPicker.sound.chime_soft')).selected,
      isFalse,
    );
  });

  testWidgets('tapping a sound chooses it and plays it at the volume', (
    tester,
  ) async {
    await pumpSheet(tester);

    await tester.tap(byKey('soundPicker.sound.marimba'));
    await tester.pump();

    expect(chosenSound, _marimba);
    expect(dependencies.audio.calls, ['playPreview(marimba, $_volume)']);
  });

  testWidgets('another sound replaces the preview of the previous one', (
    tester,
  ) async {
    await pumpSheet(tester);

    await tester.tap(byKey('soundPicker.sound.marimba'));
    await tester.pump();
    await tester.tap(byKey('soundPicker.sound.harp'));
    await tester.pump();

    expect(chosenSound, _harp);
    expect(dependencies.audio.previewing, _harp);
  });

  testWidgets('the play button previews without changing the choice', (
    tester,
  ) async {
    await pumpSheet(tester);

    await tester.tap(byKey('soundPicker.preview.harp'));
    await tester.pump();

    expect(chosenSound, isNull);
    expect(dependencies.audio.previewing, _harp);
  });

  testWidgets('"no sound" is chosen and silences the preview', (tester) async {
    await pumpSheet(tester);
    await tester.tap(byKey('soundPicker.sound.marimba'));
    await tester.pump();

    await tester.tap(byKey('soundPicker.sound.none'));
    await tester.pump();

    expect(chosenSound, SoundId.none);
    expect(dependencies.audio.previewing, isNull);
  });

  testWidgets('the volume slider reports the new volume', (tester) async {
    await pumpSheet(tester);

    await tester.drag(byKey('soundPicker.volume'), const Offset(1000, 0));
    await tester.pump();

    expect(chosenVolume, 1.0);
  });

  testWidgets('closing the sheet stops the preview', (tester) async {
    await pumpSheet(tester);
    await tester.tap(byKey('soundPicker.sound.marimba'));
    await tester.pump();

    await tester.pumpWidget(const SizedBox());

    expect(dependencies.audio.previewing, isNull);
  });

  testWidgets('has labeled, reachable controls', (tester) async {
    await pumpSheet(tester);

    await expectMeetsA11yGuidelines(tester);
  });
}
