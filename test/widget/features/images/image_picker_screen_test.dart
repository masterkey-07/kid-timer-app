import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';
import 'package:visual_time_counter/core/platform/image_picker/image_picker_port.dart';
import 'package:visual_time_counter/core/platform/providers.dart';
import 'package:visual_time_counter/features/images/data/user_image_repository.dart';

import '../../../helpers/a11y_expectations.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/test_app.dart';

const _pageTransition = Duration(seconds: 1);
const _brushTeeth = 'bank:hygiene/brush_teeth';
const _mealtime = 'bank:meal/meal';
const _categories = [
  'hygiene',
  'meal',
  'play',
  'rest',
  'school',
  'goingOut',
  'animals',
];

final _pickedFile = PickedImage(
  bytes: Uint8List.fromList(const [1, 2, 3]),
  name: 'photo.jpg',
);

/// Choose image (contracts/ui/04 §4.1).
void main() {
  late TestAppDependencies dependencies;

  setUp(() async => dependencies = await TestAppDependencies.create());
  tearDown(() => dependencies.dispose());

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(_pageTransition);
  }

  /// Opens `/images` over home and returns what it pops.
  Future<({Future<VisualSource?> popped})> openPicker(
    WidgetTester tester, {
    VisualSource? selected,
    AppPlatform platform = AppPlatform.android,
    ScreenClass screen = ScreenClass.compact,
    double textScale = 1,
  }) async {
    dependencies.platform = platform;
    await tester.pumpKidTimerApp(
      dependencies,
      screen: screen,
      textScale: textScale,
    );
    await settle(tester);
    final result = GoRouter.of(
      tester.element(find.byKey(const Key('home.screen'))),
    ).push<VisualSource>('/images', extra: selected);
    await settle(tester);
    return (popped: result);
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await settle(tester);
  }

  testWidgets('offers All, each category and My images as tabs', (
    tester,
  ) async {
    await openPicker(tester);

    expect(find.byKey(const Key('images.screen')), findsOneWidget);
    for (final tab in ['all', ..._categories, 'mine']) {
      expect(
        find.byKey(Key('images.tab.$tab'), skipOffstage: false),
        findsOneWidget,
        reason: tab,
      );
    }
  });

  testWidgets('a category tab shows only its images', (tester) async {
    await openPicker(tester);
    expect(find.byKey(const Key('images.item.$_mealtime')), findsOneWidget);

    await tapKey(tester, 'images.tab.hygiene');

    expect(find.byKey(const Key('images.item.$_brushTeeth')), findsOneWidget);
    expect(find.byKey(const Key('images.item.$_mealtime')), findsNothing);
  });

  for (final (screen, columns) in [
    (ScreenClass.compact, 3),
    (ScreenClass.medium, 5),
    (ScreenClass.expanded, 7),
  ]) {
    testWidgets('lays the grid out in $columns columns (${screen.name})', (
      tester,
    ) async {
      await openPicker(tester, screen: screen);

      final grid = tester.widget<GridView>(
        find.byKey(const Key('images.grid')),
      );
      final layout =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(layout.crossAxisCount, columns);
    });
  }

  testWidgets('tapping a library image returns it', (tester) async {
    final (:popped) = await openPicker(tester);

    await tapKey(tester, 'images.item.$_brushTeeth');

    expect(await popped, const BankImageSource(_brushTeeth));
  });

  testWidgets('marks the current selection', (tester) async {
    final semantics = tester.ensureSemantics();
    await openPicker(tester, selected: const BankImageSource(_brushTeeth));

    expect(
      tester.getSemantics(find.byKey(const Key('images.item.$_brushTeeth'))),
      isSemantics(isSelected: true, hasSelectedState: true),
    );
    expect(
      tester.getSemantics(find.byKey(const Key('images.item.$_mealtime'))),
      isSemantics(isSelected: false, hasSelectedState: true),
    );
    semantics.dispose();
  });

  testWidgets('"No image" returns the default palette', (tester) async {
    final (:popped) = await openPicker(
      tester,
      selected: const BankImageSource(_brushTeeth),
    );

    await tapKey(tester, 'images.none');

    expect(await popped, VisualSource.defaultSource);
  });

  testWidgets('My images without images shows the empty state', (tester) async {
    await openPicker(tester);

    await tapKey(tester, 'images.tab.mine');

    expect(find.byKey(const Key('images.mineEmpty')), findsOneWidget);
    expect(
      find.byKey(const Key('images.mineEmpty.fromDevice')),
      findsOneWidget,
    );
  });

  testWidgets('My images lists own images and returns the tapped one', (
    tester,
  ) async {
    final [image] = await dependencies.seedUserImages(1);
    final (:popped) = await openPicker(tester);

    await tapKey(tester, 'images.tab.mine');
    expect(find.byKey(const Key('images.item.$_brushTeeth')), findsNothing);
    await tapKey(tester, 'images.item.${image.id}');

    expect(await popped, UserImageSource(image.id));
  });

  testWidgets('shows the browser storage note only on the Web', (tester) async {
    await openPicker(tester, platform: AppPlatform.web);
    expect(find.byKey(const Key('images.webNote')), findsOneWidget);
  });

  testWidgets('has no browser storage note outside the Web', (tester) async {
    await openPicker(tester);
    expect(find.byKey(const Key('images.webNote')), findsNothing);
  });

  testWidgets('cancelling the system picker changes nothing', (tester) async {
    await openPicker(tester);

    await tapKey(tester, 'images.fromDevice');

    expect(dependencies.imagePicker.pickCount, 1);
    expect(find.byKey(const Key('images.screen')), findsOneWidget);
    expect(find.byKey(const Key('images.openError')), findsNothing);
  });

  testWidgets('a file that cannot be opened shows an error', (tester) async {
    await openPicker(tester);
    dependencies.imagePicker.nextResult = _pickedFile;

    await tapKey(tester, 'images.fromDevice');

    expect(find.byKey(const Key('images.openError')), findsOneWidget);
    expect(find.byKey(const Key('frame.screen')), findsNothing);
  });

  testWidgets('a picked image is framed, saved and returned', (tester) async {
    dependencies.pickedPreview = await tester.runAsync(
      () => createTestImage(width: 200, height: 100),
    );
    final (:popped) = await openPicker(tester);
    dependencies.imagePicker.nextResult = _pickedFile;

    await tapKey(tester, 'images.fromDevice');
    expect(find.byKey(const Key('frame.screen')), findsOneWidget);
    await tapKey(tester, 'frame.save');

    expect(await popped, const UserImageSource('image-0'));
    expect(dependencies.userImagesMeta.containsKey('image-0'), isTrue);
  });

  testWidgets('at 50 images, From my device explains the limit', (
    tester,
  ) async {
    await dependencies.seedUserImages(UserImageRepository.maxImages);
    await openPicker(tester);
    dependencies.imagePicker.nextResult = _pickedFile;

    await tapKey(tester, 'images.fromDevice');
    expect(find.byKey(const Key('confirm.dialog')), findsOneWidget);
    await tapKey(tester, 'confirm.confirm');

    expect(dependencies.imagePicker.pickCount, 0);
    expect(find.byKey(const Key('mine.screen')), findsOneWidget);
  });

  testWidgets('Manage opens My images', (tester) async {
    await openPicker(tester);

    await tapKey(tester, 'images.manage');

    expect(find.byKey(const Key('mine.screen')), findsOneWidget);
  });

  testWidgets('fits at 200% text', (tester) async {
    await openPicker(
      tester,
      textScale: maxTextScale,
      platform: AppPlatform.web,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('meets the accessibility guidelines', (tester) async {
    await openPicker(tester);

    await expectMeetsA11yGuidelines(tester);
  });
}
