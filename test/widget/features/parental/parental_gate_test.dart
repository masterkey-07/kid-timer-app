import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/clock/clock_provider.dart';
import 'package:visual_time_counter/features/parental/application/parental_gate_controller.dart';
import 'package:visual_time_counter/features/parental/domain/gate_challenge.dart';
import 'package:visual_time_counter/features/parental/presentation/parental_gate.dart';

import '../../../helpers/a11y_expectations.dart';
import '../../../helpers/pump_app.dart';

const _seed = 11;
const _lockoutSeconds = 30;
const _digitKeyCount = 10;

final List<LogicalKeyboardKey> _digitKeys = [
  LogicalKeyboardKey.digit0,
  LogicalKeyboardKey.digit1,
  LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3,
  LogicalKeyboardKey.digit4,
  LogicalKeyboardKey.digit5,
  LogicalKeyboardKey.digit6,
  LogicalKeyboardKey.digit7,
  LogicalKeyboardKey.digit8,
  LogicalKeyboardKey.digit9,
];

/// The parental gate dialog (contracts/ui/07 §7.1).
void main() {
  var now = DateTime.utc(2026, 10, 30, 12);

  setUp(() => now = DateTime.utc(2026, 10, 30, 12));

  List<Override> overrides() => [
    gateRandomProvider.overrideWithValue(Random(_seed)),
    clockProvider.overrideWithValue(Clock(() => now)),
  ];

  /// Opens the gate over a button and exposes what it resolved to.
  Future<ValueGetter<bool?>> openGate(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    double textScale = 1,
    ScreenClass screen = ScreenClass.compact,
  }) async {
    bool? result;
    await tester.pumpApp(
      Builder(
        builder: (context) => TextButton(
          key: const Key('opener'),
          onPressed: () async => result = await showParentalGate(context),
          child: const Text('open'),
        ),
      ),
      overrides: overrides(),
      locale: locale,
      textScale: textScale,
      screen: screen,
    );
    await tester.tap(find.byKey(const Key('opener')));
    await tester.pumpAndSettle();
    return () => result;
  }

  GateChallenge challengeOf(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byKey(const Key('gate.dialog'))),
  ).read(parentalGateControllerProvider).challenge;

  Future<void> typeNumber(WidgetTester tester, int number) async {
    for (final digit in '$number'.split('')) {
      await tester.tap(find.byKey(Key('gate.key.$digit')));
      await tester.pump();
    }
  }

  Future<void> typeOnKeyboard(WidgetTester tester, String digits) async {
    for (final digit in digits.split('')) {
      await tester.sendKeyEvent(_digitKeys[int.parse(digit)]);
    }
    await tester.pump();
  }

  Future<void> answerWrong(WidgetTester tester) async {
    await typeNumber(tester, challengeOf(tester).answer + 1);
    await tester.tap(find.byKey(const Key('gate.ok')));
    await tester.pump();
  }

  String answerText(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('gate.answer'))).data ?? '';

  testWidgets('asks the question in words in the current language', (
    tester,
  ) async {
    await openGate(tester);
    final challenge = challengeOf(tester);

    final question = tester.widget<Text>(
      find.byKey(const Key('gate.question')),
    );
    expect(question.data, contains('times'));
    expect(question.data, isNot(contains('${challenge.left}')));
  });

  testWidgets('asks in Portuguese on a pt-BR device', (tester) async {
    await openGate(tester, locale: const Locale('pt'));

    final question = tester.widget<Text>(
      find.byKey(const Key('gate.question')),
    );
    expect(question.data, contains('vezes'));
  });

  testWidgets('the screen reader reads the question', (tester) async {
    final semantics = tester.ensureSemantics();
    await openGate(tester);

    final question = tester.widget<Text>(
      find.byKey(const Key('gate.question')),
    );
    expect(find.bySemanticsLabel(question.data!), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a right answer closes the gate with true', (tester) async {
    final result = await openGate(tester);

    await typeNumber(tester, challengeOf(tester).answer);
    await tester.tap(find.byKey(const Key('gate.ok')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('gate.dialog')), findsNothing);
    expect(result(), true);
  });

  testWidgets('the keypad types at most two digits and backspace erases', (
    tester,
  ) async {
    await openGate(tester);

    await tester.tap(find.byKey(const Key('gate.key.1')));
    await tester.tap(find.byKey(const Key('gate.key.2')));
    await tester.tap(find.byKey(const Key('gate.key.3')));
    await tester.pump();
    expect(answerText(tester), '12');

    await tester.tap(find.byKey(const Key('gate.backspace')));
    await tester.pump();
    expect(answerText(tester), '1');
  });

  testWidgets('the physical keyboard types, erases and confirms', (
    tester,
  ) async {
    final result = await openGate(tester);
    final answer = '${challengeOf(tester).answer}';

    await typeOnKeyboard(tester, answer);
    expect(answerText(tester), answer);

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(answerText(tester), answer.substring(0, answer.length - 1));

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await typeOnKeyboard(tester, answer);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(result(), true);
  });

  testWidgets('a wrong answer shows the error, a new question and attempts', (
    tester,
  ) async {
    await openGate(tester);
    final before = challengeOf(tester);

    await answerWrong(tester);

    expect(find.byKey(const Key('gate.error')), findsOneWidget);
    expect(find.byKey(const Key('gate.attempts')), findsOneWidget);
    expect(challengeOf(tester), isNot(before));
    expect(answerText(tester), isEmpty);
    expect(find.byKey(const Key('gate.dialog')), findsOneWidget);
  });

  testWidgets('three wrong answers lock the keys with a countdown', (
    tester,
  ) async {
    await openGate(tester);

    for (
      var attempt = 0;
      attempt < ParentalGateController.maxWrongAnswers;
      attempt++
    ) {
      await answerWrong(tester);
    }

    expect(find.byKey(const Key('gate.lockout')), findsOneWidget);
    for (var digit = 0; digit < _digitKeyCount; digit++) {
      final key = tester.widget<ButtonStyleButton>(
        find.byKey(Key('gate.key.$digit')),
      );
      expect(key.onPressed, isNull, reason: 'digit $digit');
    }
    expect(
      tester
          .widget<ButtonStyleButton>(find.byKey(const Key('gate.ok')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('the lockout counts down and ends after 30 seconds', (
    tester,
  ) async {
    await openGate(tester);
    for (
      var attempt = 0;
      attempt < ParentalGateController.maxWrongAnswers;
      attempt++
    ) {
      await answerWrong(tester);
    }
    expect(
      tester.widget<Text>(find.byKey(const Key('gate.lockout'))).data,
      contains('$_lockoutSeconds'),
    );

    now = now.add(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 1));
    expect(
      tester.widget<Text>(find.byKey(const Key('gate.lockout'))).data,
      contains('${_lockoutSeconds - 10}'),
    );

    now = now.add(const Duration(seconds: _lockoutSeconds));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('gate.lockout')), findsNothing);
    expect(
      tester
          .widget<ButtonStyleButton>(find.byKey(const Key('gate.key.1')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('closing and reopening keeps the lockout', (tester) async {
    await openGate(tester);
    for (
      var attempt = 0;
      attempt < ParentalGateController.maxWrongAnswers;
      attempt++
    ) {
      await answerWrong(tester);
    }

    await tester.tap(find.byKey(const Key('gate.close')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('opener')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('gate.lockout')), findsOneWidget);
  });

  testWidgets('the close button resolves to false', (tester) async {
    final result = await openGate(tester);

    await tester.tap(find.byKey(const Key('gate.close')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('gate.dialog')), findsNothing);
    expect(result(), false);
  });

  testWidgets('keeps every key reachable at 200% font on a small screen', (
    tester,
  ) async {
    await openGate(
      tester,
      textScale: maxTextScale,
      screen: ScreenClass.compactLandscape,
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('gate.ok')), findsOneWidget);
  });

  testWidgets('meets the accessibility guidelines', (tester) async {
    await openGate(tester);

    await expectMeetsA11yGuidelines(tester);
  });
}
