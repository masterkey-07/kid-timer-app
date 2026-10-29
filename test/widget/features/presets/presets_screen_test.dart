import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/images/application/my_images_controller.dart';
import 'package:visual_time_counter/features/presets/application/presets_controller.dart';
import 'package:visual_time_counter/features/presets/data/preset_repository.dart';

import '../../../helpers/a11y_expectations.dart';
import '../../../helpers/test_app.dart';

const _pageTransition = Duration(seconds: 1);
const _undoWindow = Duration(seconds: 5);

/// The preset list (contracts/ui/05 §5.1, FR-040–042).
void main() {
  late TestAppDependencies dependencies;

  setUp(() async => dependencies = await TestAppDependencies.create());
  tearDown(() => dependencies.dispose());

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(_pageTransition);
  }

  Future<void> openPresets(WidgetTester tester) async {
    await tester.pumpKidTimerApp(dependencies);
    await settle(tester);
    unawaited(
      GoRouter.of(tester.element(find.byKey(const Key('home.screen'))))
          .push<void>('/presets'),
    );
    await settle(tester);
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await settle(tester);
  }

  Future<void> seedThree() async {
    await dependencies.seedPreset(
      'a',
      'Brush teeth',
      VisualSource.defaultSource,
      duration: const Duration(minutes: 2),
    );
    await dependencies.seedPreset(
      'b',
      'Bath',
      const BankImageSource('bank:hygiene/bath'),
      duration: const Duration(minutes: 10),
    );
    await dependencies.seedPreset(
      'c',
      'Homework',
      VisualSource.defaultSource,
      duration: const Duration(minutes: 25),
    );
  }

  List<String> storedOrder() {
    final documents = [
      for (final key in dependencies.presets.keys)
        dependencies.presets.get(key)!,
    ]..sort((a, b) => (a['order']! as int).compareTo(b['order']! as int));
    return [for (final document in documents) document['id']! as String];
  }

  double topOf(WidgetTester tester, String id) =>
      tester.getTopLeft(find.byKey(Key('presets.item.$id'))).dy;

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(
        tester.element(find.byKey(const Key('presets.screen'))),
      );

  testWidgets('lists the presets in order with name and duration', (
    tester,
  ) async {
    await seedThree();
    await openPresets(tester);

    expect(find.byKey(const Key('presets.screen')), findsOneWidget);
    expect(topOf(tester, 'a'), lessThan(topOf(tester, 'b')));
    expect(topOf(tester, 'b'), lessThan(topOf(tester, 'c')));
    expect(
      tester.getSemantics(find.byKey(const Key('presets.item.b'))).label,
      'Bath, 10 minutes',
    );
    expect(find.byKey(const Key('presets.start.b')), findsOneWidget);
    expect(find.byKey(const Key('presets.drag.b')), findsOneWidget);
    expect(find.byKey(const Key('presets.menu.b')), findsOneWidget);
  });

  testWidgets('shows the empty state with a New button', (tester) async {
    await openPresets(tester);

    expect(find.byKey(const Key('presets.empty')), findsOneWidget);
    await tapKey(tester, 'presets.emptyNew');
    expect(find.byKey(const Key('presetEditor.screen')), findsOneWidget);
  });

  testWidgets('▶ starts the preset in one tap with its origin (FR-041)', (
    tester,
  ) async {
    await seedThree();
    await openPresets(tester);

    await tapKey(tester, 'presets.start.b');

    expect(find.byKey(const Key('run.screen')), findsOneWidget);
    final session = dependencies.sessionRepository.load()!;
    expect(session.origin, const PresetOrigin('b'));
    expect(session.config.duration.value, const Duration(minutes: 10));
    expect(session.config.visual, const BankImageSource('bank:hygiene/bath'));
  });

  testWidgets('tapping a preset opens its editor', (tester) async {
    await seedThree();
    await openPresets(tester);

    await tapKey(tester, 'presets.item.b');

    expect(find.byKey(const Key('presetEditor.screen')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('presetEditor.name')))
          .controller!
          .text,
      'Bath',
    );
  });

  testWidgets('New opens the editor', (tester) async {
    await seedThree();
    await openPresets(tester);

    await tapKey(tester, 'presets.new');

    expect(find.byKey(const Key('presetEditor.screen')), findsOneWidget);
  });

  group('reordering', () {
    testWidgets('dragging the handle moves the preset and persists', (
      tester,
    ) async {
      await seedThree();
      await openPresets(tester);
      final rowHeight = tester
          .getSize(find.byKey(const Key('presets.item.a')))
          .height;

      final drag = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('presets.drag.a'))),
      );
      await tester.pump(kLongPressTimeout);
      for (var step = 0; step < 10; step++) {
        await drag.moveBy(Offset(0, rowHeight * 0.25));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await drag.up();
      await settle(tester);

      expect(storedOrder(), ['b', 'c', 'a']);
      expect(topOf(tester, 'b'), lessThan(topOf(tester, 'a')));
    });

    testWidgets('Ctrl+↓ and Ctrl+↑ move the focused preset', (tester) async {
      await seedThree();
      await openPresets(tester);
      final itemBody = find.descendant(
        of: find.byKey(const Key('presets.item.a')),
        matching: find.byType(Text),
      );
      Focus.of(tester.element(itemBody.first)).requestFocus();
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await settle(tester);
      expect(storedOrder(), ['b', 'a', 'c']);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await settle(tester);
      expect(storedOrder(), ['a', 'b', 'c']);
    });

    testWidgets('screen readers get move up and move down actions', (
      tester,
    ) async {
      await seedThree();
      await openPresets(tester);
      final semantics = tester.getSemantics(
        find.byKey(const Key('presets.item.b')),
      );
      final labels = [
        for (final id
            in semantics.getSemanticsData().customSemanticsActionIds ?? [])
          CustomSemanticsAction.getAction(id)!.label,
      ];

      expect(
        labels,
        containsAll(['Edit', 'Duplicate', 'Delete', 'Move up', 'Move down']),
      );
    });
  });

  testWidgets('Duplicate adds a copy right after the original', (tester) async {
    await seedThree();
    await openPresets(tester);

    await tapKey(tester, 'presets.menu.a');
    await tapKey(tester, 'presets.duplicate.a');

    expect(storedOrder(), ['a', 'preset-0', 'b', 'c']);
    expect(dependencies.presets.get('preset-0')!['name'], 'Brush teeth (copy)');
    expect(find.byKey(const Key('presets.item.preset-0')), findsOneWidget);
  });

  group('delete', () {
    testWidgets('asks, deletes, and Undo restores within 5 s', (tester) async {
      await seedThree();
      await openPresets(tester);

      await tapKey(tester, 'presets.menu.b');
      await tapKey(tester, 'presets.delete.b');
      expect(find.byKey(const Key('confirm.dialog')), findsOneWidget);
      await tapKey(tester, 'confirm.confirm');

      expect(find.byKey(const Key('presets.item.b')), findsNothing);
      expect(dependencies.presets.containsKey('b'), isFalse);
      expect(storedOrder(), ['a', 'c']);

      await tapKey(tester, 'presets.undo');

      expect(find.byKey(const Key('presets.item.b')), findsOneWidget);
      expect(storedOrder(), ['a', 'b', 'c']);
    });

    testWidgets('the undo offer disappears after 5 s', (tester) async {
      await seedThree();
      await openPresets(tester);
      await tapKey(tester, 'presets.menu.b');
      await tapKey(tester, 'presets.delete.b');
      await tapKey(tester, 'confirm.confirm');

      await tester.pump(_undoWindow);
      await settle(tester);

      expect(find.byKey(const Key('presets.undo')), findsNothing);
      expect(dependencies.presets.containsKey('b'), isFalse);
    });

    testWidgets('cancelling keeps the preset', (tester) async {
      await seedThree();
      await openPresets(tester);

      await tapKey(tester, 'presets.menu.b');
      await tapKey(tester, 'presets.delete.b');
      await tapKey(tester, 'confirm.cancel');

      expect(find.byKey(const Key('presets.item.b')), findsOneWidget);
      expect(storedOrder(), ['a', 'b', 'c']);
    });
  });

  testWidgets('at 100 presets New is disabled with an explanation', (
    tester,
  ) async {
    for (var i = 0; i < PresetRepository.maxPresets; i++) {
      await dependencies.seedPreset(
        'p$i',
        'Preset $i',
        VisualSource.defaultSource,
      );
    }
    await openPresets(tester);

    final newButton = tester.widget<IconButton>(
      find.byKey(const Key('presets.new')),
    );
    expect(newButton.onPressed, isNull);
    expect(find.byKey(const Key('presets.limit')), findsOneWidget);
  });

  testWidgets('a deleted own image switches the listed presets to colors '
      '(FR-024)', (tester) async {
    final [image] = await dependencies.seedUserImages(1);
    await dependencies.seedPreset('p1', 'Bath', UserImageSource(image.id));
    await openPresets(tester);
    final container = containerOf(tester);

    await container.read(userImagesProvider.notifier).delete(image.id);
    await settle(tester);

    expect(
      container.read(presetsProvider).single.config.visual,
      VisualSource.defaultSource,
    );
  });

  testWidgets('meets the accessibility guidelines', (tester) async {
    await seedThree();
    await openPresets(tester);

    await expectMeetsA11yGuidelines(tester);
  });
}
