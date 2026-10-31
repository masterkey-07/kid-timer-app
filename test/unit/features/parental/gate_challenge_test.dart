import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/clock/clock_provider.dart';
import 'package:visual_time_counter/features/parental/application/parental_gate_controller.dart';
import 'package:visual_time_counter/features/parental/domain/gate_challenge.dart';

const _lockoutLength = Duration(seconds: 30);
const _justUnderLockout = Duration(milliseconds: 29999);
const _validity = Duration(minutes: 5);
const _justUnderValidity = Duration(minutes: 4, seconds: 59);
const _oneSecond = Duration(seconds: 1);

void main() {
  group('GateChallenge', () {
    test('draws both factors from 3 to 9', () {
      final random = Random(42);
      for (var draw = 0; draw < 500; draw++) {
        final challenge = GateChallenge.random(random);
        expect(challenge.left, inInclusiveRange(3, 9));
        expect(challenge.right, inInclusiveRange(3, 9));
      }
    });

    test('draws the same challenge from the same seed', () {
      final first = GateChallenge.random(Random(7));
      final second = GateChallenge.random(Random(7));
      expect(first, second);
    });

    test('answer is the product', () {
      expect(const GateChallenge(left: 7, right: 8).answer, 56);
    });

    test('accepts only the typed product', () {
      const challenge = GateChallenge(left: 7, right: 8);
      expect(challenge.isCorrect('56'), true);
      expect(challenge.isCorrect('65'), false);
      expect(challenge.isCorrect(''), false);
      expect(challenge.isCorrect('056'), false);
    });
  });

  group('ParentalGateController', () {
    late ProviderContainer container;
    late DateTime now;

    ParentalGateController controller() =>
        container.read(parentalGateControllerProvider.notifier);

    GateState state() => container.read(parentalGateControllerProvider);

    void type(String digits) {
      for (final digit in digits.split('')) {
        controller().enterDigit(int.parse(digit));
      }
    }

    /// Types the right answer.
    GateOutcome answerRight() {
      type('${state().challenge.answer}');
      return controller().submit();
    }

    /// Types an answer that is never the product.
    GateOutcome answerWrong() {
      type('${state().challenge.answer + 1}');
      return controller().submit();
    }

    setUp(() {
      now = DateTime(2026, 10, 30, 9);
      container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(Clock(() => now)),
          gateRandomProvider.overrideWithValue(Random(1)),
        ],
      );
      container.listen(parentalGateControllerProvider, (_, _) {});
    });

    tearDown(() => container.dispose());

    test('starts locked with three attempts and no digits', () {
      expect(controller().isUnlocked, false);
      expect(state().attemptsLeft, 3);
      expect(state().enteredDigits, '');
    });

    test('keeps at most two digits', () {
      type('123');
      expect(state().enteredDigits, '12');
    });

    test('backspace removes the last digit', () {
      type('12');
      controller().backspace();
      expect(state().enteredDigits, '1');
      controller().backspace();
      controller().backspace();
      expect(state().enteredDigits, '');
    });

    test('submitting nothing changes nothing', () {
      expect(controller().submit(), GateOutcome.incomplete);
      expect(state().attemptsLeft, 3);
    });

    test('a right answer unlocks', () {
      expect(answerRight(), GateOutcome.unlocked);
      expect(controller().isUnlocked, true);
    });

    test('a wrong answer costs an attempt, clears the digits and asks '
        'a new question', () {
      final firstChallenge = state().challenge;
      expect(answerWrong(), GateOutcome.wrong);
      expect(state().attemptsLeft, 2);
      expect(state().enteredDigits, '');
      expect(state().challenge, isNot(firstChallenge));
      expect(controller().isUnlocked, false);
    });

    test('three wrong answers lock out for 30 s', () {
      answerWrong();
      answerWrong();
      expect(answerWrong(), GateOutcome.lockedOut);
      expect(controller().lockoutRemaining, _lockoutLength);
    });

    test('the lockout counts down with the clock', () {
      for (var attempt = 0; attempt < 3; attempt++) {
        answerWrong();
      }
      now = now.add(_justUnderLockout);
      expect(controller().lockoutRemaining, isNot(Duration.zero));

      now = now.add(const Duration(milliseconds: 1));
      expect(controller().lockoutRemaining, Duration.zero);
    });

    test('keys are ignored and a right answer is refused while locked '
        'out', () {
      for (var attempt = 0; attempt < 3; attempt++) {
        answerWrong();
      }
      type('5');
      expect(state().enteredDigits, '');
      expect(controller().submit(), GateOutcome.lockedOut);
      expect(controller().isUnlocked, false);
    });

    test('after the lockout the attempts start over', () {
      for (var attempt = 0; attempt < 3; attempt++) {
        answerWrong();
      }
      now = now.add(_lockoutLength);

      expect(answerWrong(), GateOutcome.wrong);
      expect(state().attemptsLeft, 2);
    });

    test('a right answer after the lockout unlocks', () {
      for (var attempt = 0; attempt < 3; attempt++) {
        answerWrong();
      }
      now = now.add(_lockoutLength);
      expect(answerRight(), GateOutcome.unlocked);
    });

    test('the lockout survives the dialog being closed and reopened', () {
      for (var attempt = 0; attempt < 3; attempt++) {
        answerWrong();
      }
      now = now.add(_oneSecond);

      controller().reset();

      expect(controller().lockoutRemaining, _lockoutLength - _oneSecond);
    });

    test('stays unlocked for 5 min', () {
      answerRight();
      now = now.add(_justUnderValidity);
      expect(controller().isUnlocked, true);

      now = now.add(_oneSecond);
      expect(controller().isUnlocked, false);
    });

    test('a right answer clears earlier wrong answers', () {
      answerWrong();
      answerWrong();
      answerRight();
      controller().lock();

      expect(state().attemptsLeft, 3);
    });

    test('lock ends the validity at once', () {
      answerRight();
      controller().lock();
      expect(controller().isUnlocked, false);
    });

    test('reset starts a new question without spending attempts', () {
      answerWrong();
      type('4');
      controller().reset();

      expect(state().enteredDigits, '');
      expect(state().attemptsLeft, 2);
    });

    test('validity is five minutes', () {
      expect(ParentalGateController.validity, _validity);
    });
  });
}
