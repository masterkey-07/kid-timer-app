import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';
import 'package:visual_time_counter/features/images/domain/frame_spec.dart';
import 'package:visual_time_counter/features/images/domain/image_processor.dart';
import 'package:visual_time_counter/features/images/presentation/frame_screen.dart';

import '../../../helpers/a11y_expectations.dart';
import '../../../helpers/test_app.dart';

const _pageTransition = Duration(seconds: 1);
const _overlayDelay = Duration(milliseconds: 300);

/// Frame image (contracts/ui/04 §4.2).
void main() {
  late TestAppDependencies dependencies;

  setUp(() async => dependencies = await TestAppDependencies.create());
  tearDown(() => dependencies.dispose());

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(_pageTransition);
  }

  /// Opens `/images/frame` for a 200×100 (landscape) picture.
  Future<({Future<VisualSource?> popped})> openFrame(
    WidgetTester tester, {
    double textScale = 1,
  }) async {
    final preview = await tester.runAsync(
      () => createTestImage(width: 200, height: 100),
    );
    await tester.pumpKidTimerApp(dependencies, textScale: textScale);
    await settle(tester);
    final result =
        GoRouter.of(tester.element(find.byKey(const Key('home.screen'))))
            .push<VisualSource>(
              '/images/frame',
              extra: FrameRequest(
                bytes: Uint8List.fromList(const [1, 2, 3]),
                preview: preview!,
              ),
            );
    await settle(tester);
    return (popped: result);
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await settle(tester);
  }

  double zoom(WidgetTester tester) =>
      tester.widget<Slider>(find.byKey(const Key('frame.zoom'))).value;

  Future<FrameSpec> saveAndReadFrame(WidgetTester tester) async {
    await tapKey(tester, 'frame.save');
    return dependencies.imageProcessor.frames.single;
  }

  testWidgets('starts centered at zoom 1', (tester) async {
    await openFrame(tester);

    expect(find.byKey(const Key('frame.screen')), findsOneWidget);
    expect(zoom(tester), FrameSpec.minZoom);
    expect(await saveAndReadFrame(tester), FrameSpec.centered);
  });

  testWidgets('dragging moves the frame over the picture', (tester) async {
    await openFrame(tester);

    await tester.drag(
      find.byKey(const Key('frame.canvas')),
      const Offset(-60, 0),
    );
    await tester.pump();

    final frame = await saveAndReadFrame(tester);
    expect(frame.centerX, greaterThan(0.5));
    // A landscape picture already fills the circle's height at zoom 1.
    expect(frame.centerY, 0.5);
  });

  testWidgets('pinching zooms in', (tester) async {
    await openFrame(tester);
    final center = tester.getCenter(find.byKey(const Key('frame.canvas')));

    final first = await tester.startGesture(center - const Offset(20, 0));
    final second = await tester.startGesture(center + const Offset(20, 0));
    await tester.pump();
    await first.moveBy(const Offset(-40, 0));
    await second.moveBy(const Offset(40, 0));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pump();

    expect(zoom(tester), greaterThan(FrameSpec.minZoom));
  });

  testWidgets('arrows move the frame and +/− zoom from the keyboard', (
    tester,
  ) async {
    await openFrame(tester);
    await tester.tap(find.byKey(const Key('frame.canvas')));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.numpadAdd);
    await tester.sendKeyEvent(LogicalKeyboardKey.numpadAdd);
    await tester.sendKeyEvent(LogicalKeyboardKey.minus);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(zoom(tester), closeTo(1.1, 1e-9));
    final frame = await saveAndReadFrame(tester);
    expect(frame.centerX, lessThan(0.5));
  });

  testWidgets('the zoom slider goes from 1.0 to 4.0 in 0.1 steps', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await openFrame(tester);
    await tester.tap(find.byKey(const Key('frame.canvas')));
    for (var step = 0; step < 5; step++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.numpadAdd);
    }
    await tester.pump();

    final slider = tester.widget<Slider>(find.byKey(const Key('frame.zoom')));
    expect(slider.min, FrameSpec.minZoom);
    expect(slider.max, FrameSpec.maxZoom);
    expect(slider.divisions, 30);
    expect(
      tester.getSemantics(find.byKey(const Key('frame.zoom'))),
      isSemantics(value: '150%'),
    );
    semantics.dispose();
  });

  testWidgets('Center goes back to zoom 1, centered', (tester) async {
    await openFrame(tester);
    await tester.drag(
      find.byKey(const Key('frame.canvas')),
      const Offset(-60, 0),
    );
    await tester.tap(find.byKey(const Key('frame.canvas')));
    await tester.sendKeyEvent(LogicalKeyboardKey.numpadAdd);
    await tester.pump();

    await tapKey(tester, 'frame.reset');

    expect(zoom(tester), FrameSpec.minZoom);
    expect(await saveAndReadFrame(tester), FrameSpec.centered);
  });

  testWidgets('saves with the name and returns the new image', (tester) async {
    final (:popped) = await openFrame(tester);

    await tester.enterText(find.byKey(const Key('frame.name')), 'Lucas');
    await tapKey(tester, 'frame.save');

    expect(await popped, const UserImageSource('image-0'));
    expect(dependencies.userImagesMeta.get('image-0')!['label'], 'Lucas');
    expect(await dependencies.userImageBytes.get('image-0'), isNotNull);
  });

  testWidgets('shows "Preparing image…" when saving takes over 300 ms', (
    tester,
  ) async {
    final gate = Completer<void>();
    dependencies.imageProcessor.gate = gate;
    final (:popped) = await openFrame(tester);

    await tester.tap(find.byKey(const Key('frame.save')));
    await tester.pump();
    expect(find.byKey(const Key('frame.preparing')), findsNothing);
    await tester.pump(_overlayDelay);
    expect(find.byKey(const Key('frame.preparing')), findsOneWidget);

    gate.complete();
    await settle(tester);
    expect(await popped, const UserImageSource('image-0'));
  });

  testWidgets('a quick save never shows the overlay', (tester) async {
    await openFrame(tester);

    await tester.tap(find.byKey(const Key('frame.save')));
    await tester.pump();
    await tester.pump(_overlayDelay);

    expect(find.byKey(const Key('frame.preparing')), findsNothing);
  });

  testWidgets('a processing error explains it and saves nothing', (
    tester,
  ) async {
    dependencies.imageProcessor.nextError = const CorruptImage();
    await openFrame(tester);

    await tapKey(tester, 'frame.save');

    expect(find.byKey(const Key('frame.error')), findsOneWidget);
    expect(find.byKey(const Key('frame.screen')), findsOneWidget);
    expect(dependencies.userImagesMeta.isEmpty, isTrue);
    expect(dependencies.userImageBytes.isEmpty, isTrue);
  });

  testWidgets('Cancel discards the picture', (tester) async {
    final (:popped) = await openFrame(tester);

    await tapKey(tester, 'frame.cancel');

    expect(await popped, isNull);
    expect(dependencies.imageProcessor.frames, isEmpty);
    expect(dependencies.userImagesMeta.isEmpty, isTrue);
  });

  testWidgets('fits at 200% text', (tester) async {
    await openFrame(tester, textScale: maxTextScale);

    expect(tester.takeException(), isNull);
  });

  testWidgets('meets the accessibility guidelines', (tester) async {
    await openFrame(tester);

    await expectMeetsA11yGuidelines(tester);
  });
}
