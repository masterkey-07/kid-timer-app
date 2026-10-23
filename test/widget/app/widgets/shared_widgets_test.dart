import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/app/theme/app_theme.dart';
import 'package:visual_time_counter/app/widgets/confirm_dialog.dart';
import 'package:visual_time_counter/app/widgets/platform_notice.dart';

import '../../../helpers/a11y_expectations.dart';
import '../../../helpers/pump_app.dart';

void main() {
  group('PlatformNotice', () {
    var learnMoreTaps = 0;

    Widget banner() => PlatformNotice(
      message: 'The alarm only rings with this window open.',
      onLearnMore: () => learnMoreTaps++,
    );

    setUp(() => learnMoreTaps = 0);

    testWidgets('shows the message under the notice.banner key', (
      tester,
    ) async {
      await tester.pumpApp(banner());

      expect(find.byKey(const Key('notice.banner')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('notice.banner')),
          matching: find.byType(Text),
        ),
        findsWidgets,
      );
    });

    testWidgets('"Learn more" calls back', (tester) async {
      await tester.pumpApp(banner());

      await tester.tap(find.byKey(const Key('notice.banner.learnMore')));

      expect(learnMoreTaps, 1);
    });

    for (final locale in const [Locale('pt'), Locale('en')]) {
      testWidgets('the warning icon has a label ($locale)', (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpApp(banner(), locale: locale);

        final icon = tester.getSemantics(
          find.byKey(const Key('notice.banner.icon')),
        );
        expect(icon.label, isNotEmpty);
        semantics.dispose();
      });
    }

    final themes = {
      'light': AppTheme.light(),
      'dark': AppTheme.dark(),
      'high-contrast light': AppTheme.highContrastLight(),
      'high-contrast dark': AppTheme.highContrastDark(),
    };
    for (final MapEntry(key: name, value: theme) in themes.entries) {
      testWidgets('meets the accessibility guidelines ($name)', (tester) async {
        await tester.pumpApp(banner(), theme: theme);

        await expectMeetsA11yGuidelines(tester);
      });
    }

    testWidgets('fits at 200% font scale', (tester) async {
      await expectNoOverflowAt200Percent(tester, banner());
    });
  });

  group('ConfirmDialog', () {
    Future<bool?> open(WidgetTester tester, {bool destructive = false}) async {
      bool? result;
      await tester.pumpApp(
        Builder(
          builder: (context) => TextButton(
            key: const Key('test.open'),
            onPressed: () async => result = await showConfirmDialog(
              context,
              title: 'Stop timer?',
              message: 'The countdown will be lost.',
              confirmLabel: 'Stop',
              isDestructive: destructive,
            ),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('test.open')));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('returns true when confirmed', (tester) async {
      bool? result;
      await tester.pumpApp(
        Builder(
          builder: (context) => TextButton(
            key: const Key('test.open'),
            onPressed: () async => result = await showConfirmDialog(
              context,
              title: 'Stop timer?',
              message: 'The countdown will be lost.',
              confirmLabel: 'Stop',
            ),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('test.open')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('confirm.dialog')), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm.confirm')));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.byKey(const Key('confirm.dialog')), findsNothing);
    });

    testWidgets('returns false when cancelled', (tester) async {
      bool? result;
      await tester.pumpApp(
        Builder(
          builder: (context) => TextButton(
            key: const Key('test.open'),
            onPressed: () async => result = await showConfirmDialog(
              context,
              title: 'Stop timer?',
              message: 'The countdown will be lost.',
              confirmLabel: 'Stop',
            ),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('test.open')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm.cancel')));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('Esc closes it as a cancel', (tester) async {
      bool? result;
      await tester.pumpApp(
        Builder(
          builder: (context) => TextButton(
            key: const Key('test.open'),
            onPressed: () async => result = await showConfirmDialog(
              context,
              title: 'Stop timer?',
              message: 'The countdown will be lost.',
              confirmLabel: 'Stop',
            ),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('test.open')));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(result, isFalse);
      expect(find.byKey(const Key('confirm.dialog')), findsNothing);
    });

    testWidgets('a destructive confirmation uses the error color', (
      tester,
    ) async {
      await open(tester, destructive: true);

      final button = tester.widget<FilledButton>(
        find.byKey(const Key('confirm.confirm')),
      );
      final context = tester.element(find.byKey(const Key('confirm.dialog')));
      expect(
        button.style?.backgroundColor?.resolve({}),
        Theme.of(context).colorScheme.error,
      );
    });

    testWidgets('meets the accessibility guidelines', (tester) async {
      await open(tester);

      await expectMeetsA11yGuidelines(tester);
    });
  });
}
