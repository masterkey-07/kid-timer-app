import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';

import '../../../helpers/a11y_expectations.dart';
import '../../../helpers/test_app.dart';

const _pageTransition = Duration(seconds: 1);

/// My images (contracts/ui/04 §4.3).
void main() {
  late TestAppDependencies dependencies;

  setUp(() async => dependencies = await TestAppDependencies.create());
  tearDown(() => dependencies.dispose());

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(_pageTransition);
  }

  Future<void> openMine(WidgetTester tester) async {
    await tester.pumpKidTimerApp(dependencies);
    await settle(tester);
    unawaited(
      GoRouter.of(tester.element(find.byKey(const Key('home.screen'))))
          .push<void>('/images/mine'),
    );
    await settle(tester);
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await settle(tester);
  }

  String dialogMessage(WidgetTester tester) => find
      .descendant(
        of: find.byKey(const Key('confirm.dialog')),
        matching: find.byType(Text),
      )
      .evaluate()
      .map((element) => (element.widget as Text).data ?? '')
      .join('\n');

  testWidgets('counts the images against the limit of 50', (tester) async {
    await dependencies.seedUserImages(12);
    await openMine(tester);

    expect(find.byKey(const Key('mine.screen')), findsOneWidget);
    expect(tester.textOf('mine.count'), '12 of 50');
    expect(find.byKey(const Key('mine.item.seed-0')), findsOneWidget);
  });

  testWidgets('shows the empty state without images', (tester) async {
    await openMine(tester);

    expect(find.byKey(const Key('mine.empty')), findsOneWidget);
    expect(tester.textOf('mine.count'), '0 of 50');
  });

  testWidgets('deleting lists the affected presets, then switches them to '
      'colors (FR-024)', (tester) async {
    final [image, kept] = await dependencies.seedUserImages(2);
    await dependencies.seedPreset('p1', 'Bath time', UserImageSource(image.id));
    await dependencies.seedPreset('p2', 'Park', UserImageSource(kept.id));
    await openMine(tester);

    await tapKey(tester, 'mine.delete.${image.id}');
    final message = dialogMessage(tester);
    expect(message, contains('Bath time'));
    expect(message, isNot(contains('Park')));
    await tapKey(tester, 'confirm.confirm');

    expect(find.byKey(Key('mine.item.${image.id}')), findsNothing);
    expect(tester.textOf('mine.count'), '1 of 50');
    expect(dependencies.userImagesMeta.containsKey(image.id), isFalse);
    expect(await dependencies.userImageBytes.get(image.id), isNull);
    final preset = dependencies.presets.get('p1')!;
    final visual = (preset['config']! as Map)['visual']! as Map;
    expect(visual['type'], 'palette');
  });

  testWidgets('cancelling the deletion keeps the image', (tester) async {
    final [image] = await dependencies.seedUserImages(1);
    await openMine(tester);

    await tapKey(tester, 'mine.delete.${image.id}');
    await tapKey(tester, 'confirm.cancel');

    expect(find.byKey(Key('mine.item.${image.id}')), findsOneWidget);
    expect(dependencies.userImagesMeta.containsKey(image.id), isTrue);
  });

  testWidgets('renames an image from its menu', (tester) async {
    final [image] = await dependencies.seedUserImages(1);
    await openMine(tester);

    await tester.longPress(find.byKey(Key('mine.item.${image.id}')));
    await settle(tester);
    await tapKey(tester, 'mine.rename.${image.id}');
    await tester.enterText(find.byKey(const Key('mine.renameField')), 'Park');
    await tapKey(tester, 'mine.renameSave');

    expect(dependencies.userImagesMeta.get(image.id)!['label'], 'Park');
  });

  testWidgets('meets the accessibility guidelines', (tester) async {
    await dependencies.seedUserImages(3);
    await openMine(tester);

    await expectMeetsA11yGuidelines(tester);
  });
}
