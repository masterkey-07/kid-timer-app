import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

import 'a11y_expectations.dart';
import 'hive_test_utils.dart';
import 'pump_app.dart';

final _greetingProvider = Provider<String>((ref) => 'real');

void main() {
  group('pumpApp', () {
    testWidgets('applies the screen class size', (tester) async {
      await tester.pumpApp(const SizedBox(), screen: ScreenClass.expanded);

      final size = MediaQuery.sizeOf(tester.element(find.byType(SizedBox)));
      expect(size, ScreenClass.expanded.size);
    });

    for (final (locale, title) in [
      (const Locale('pt'), 'Kid Timer'),
      (const Locale('en'), 'Kid Timer'),
    ]) {
      testWidgets('provides localizations for $locale', (tester) async {
        await tester.pumpApp(
          Builder(builder: (context) => Text(AppLocalizations.of(context).appTitle)),
          locale: locale,
        );

        final context = tester.element(find.byType(Text));
        expect(Localizations.localeOf(context), locale);
        expect(AppLocalizations.of(context).appTitle, title);
      });
    }

    testWidgets('applies provider overrides', (tester) async {
      await tester.pumpApp(
        Consumer(builder: (context, ref, _) => Text(ref.watch(_greetingProvider))),
        overrides: [_greetingProvider.overrideWithValue('fake')],
      );

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.data, 'fake');
    });

    testWidgets('applies the text scale', (tester) async {
      await tester.pumpApp(const SizedBox(), textScale: 2);

      final context = tester.element(find.byType(SizedBox));
      expect(MediaQuery.textScalerOf(context), const TextScaler.linear(2));
    });
  });

  group('a11y expectations', () {
    testWidgets('pass for a labeled, large enough button', (tester) async {
      await tester.pumpApp(
        Center(
          child: ElevatedButton(onPressed: () {}, child: const Text('Start')),
        ),
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fail for an unlabeled tiny tap target', (tester) async {
      await tester.pumpApp(
        Center(
          child: GestureDetector(
            onTap: () {},
            child: const SizedBox(width: 10, height: 10),
          ),
        ),
      );

      await expectLater(
        () => expectMeetsA11yGuidelines(tester),
        throwsA(isA<TestFailure>()),
      );
    });

    testWidgets('no overflow at 200% detects overflowing layouts', (
      tester,
    ) async {
      await expectNoOverflowAt200Percent(
        tester,
        const Text('Short'),
      );

      await expectLater(
        () => expectNoOverflowAt200Percent(
          tester,
          const SizedBox(
            width: 40,
            child: Row(children: [Text('A long label that cannot fit')]),
          ),
        ),
        throwsA(isA<TestFailure>()),
      );
    });
  });

  group('useTemporaryHive', () {
    useTemporaryHive();

    test('opens boxes in a temporary directory', () async {
      final box = await Hive.openBox<Map<dynamic, dynamic>>('settings');
      await box.put('app', {'a': 1});

      expect(box.path, startsWith(Directory.systemTemp.path));
      expect(box.get('app'), {'a': 1});
    });

    test('starts every test with empty boxes', () async {
      final box = await Hive.openBox<Map<dynamic, dynamic>>('settings');

      expect(box.isEmpty, isTrue);
    });
  });
}
