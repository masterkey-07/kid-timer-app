import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/core/clock/clock_provider.dart';
import 'package:visual_time_counter/features/parental/domain/gate_challenge.dart';

/// The source of the gate questions; tests seed it.
final gateRandomProvider = Provider<Random>((ref) => Random());

/// The parental gate. It lives as long as the app, so a lockout survives
/// closing and reopening the dialog (contracts/ui/07 States).
final NotifierProvider<ParentalGateController, GateState>
parentalGateControllerProvider =
    NotifierProvider<ParentalGateController, GateState>(
      ParentalGateController.new,
    );

/// What pressing OK did.
enum GateOutcome {
  /// Nothing was typed yet.
  incomplete,

  /// The answer was right; the parent area is open for a while.
  unlocked,

  /// The answer was wrong and attempts are left.
  wrong,

  /// The answer was wrong and was the last attempt, or a lockout is on.
  lockedOut,
}

/// The gate dialog's state.
@immutable
final class GateState {
  /// Creates a state.
  const new({
    required this.challenge,
    this.enteredDigits = '',
    this.wrongAnswers = 0,
    this.lockoutEndsAt,
    this.unlockedAt,
  });

  /// The question being asked.
  final GateChallenge challenge;

  /// The digits typed so far.
  final String enteredDigits;

  /// Wrong answers since the last right answer or lockout.
  final int wrongAnswers;

  /// When the lockout ends, or null when none was started.
  final DateTime? lockoutEndsAt;

  /// When the gate was last answered right, or null.
  final DateTime? unlockedAt;

  /// Wrong answers left before the lockout.
  int get attemptsLeft => ParentalGateController.maxWrongAnswers - wrongAnswers;

  /// Returns a copy with the given fields changed.
  GateState copyWith({
    GateChallenge? challenge,
    String? enteredDigits,
    int? wrongAnswers,
    DateTime? Function()? lockoutEndsAt,
    DateTime? Function()? unlockedAt,
  }) => GateState(
    challenge: challenge ?? this.challenge,
    enteredDigits: enteredDigits ?? this.enteredDigits,
    wrongAnswers: wrongAnswers ?? this.wrongAnswers,
    lockoutEndsAt: lockoutEndsAt == null ? this.lockoutEndsAt : lockoutEndsAt(),
    unlockedAt: unlockedAt == null ? this.unlockedAt : unlockedAt(),
  );
}

/// Asks a multiplication, locks out after three wrong answers and stays
/// open for five minutes after a right one (FR-062, contracts/ui/07).
/// Everything is kept in memory only.
class ParentalGateController extends Notifier<GateState> {
  /// Wrong answers allowed before the lockout.
  static const maxWrongAnswers = 3;

  /// How long the keys stay disabled after the last wrong answer.
  static const lockoutDuration = Duration(seconds: 30);

  /// How long `/parent` and `/transfer` stay open after a right answer.
  static const validity = Duration(minutes: 5);

  /// The most digits an answer has (9 × 9 = 81).
  static const maxDigits = 2;

  @override
  GateState build() => GateState(challenge: _newChallenge());

  /// Whether a right answer was given within the last [validity].
  bool get isUnlocked {
    final unlockedAt = state.unlockedAt;
    if (unlockedAt == null) return false;
    return _now.difference(unlockedAt) < validity;
  }

  /// How long the keys stay disabled; zero when no lockout is on.
  Duration get lockoutRemaining {
    final lockoutEndsAt = state.lockoutEndsAt;
    if (lockoutEndsAt == null) return Duration.zero;
    final remaining = lockoutEndsAt.difference(_now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Types [digit], up to [maxDigits] digits.
  void enterDigit(int digit) {
    if (!_canType || state.enteredDigits.length >= maxDigits) return;
    state = state.copyWith(enteredDigits: '${state.enteredDigits}$digit');
  }

  /// Removes the last typed digit.
  void backspace() {
    if (!_canType || state.enteredDigits.isEmpty) return;
    final digits = state.enteredDigits;
    state = state.copyWith(
      enteredDigits: digits.substring(0, digits.length - 1),
    );
  }

  /// Checks the typed digits.
  GateOutcome submit() {
    if (!_canType) return GateOutcome.lockedOut;
    if (state.enteredDigits.isEmpty) return GateOutcome.incomplete;
    if (state.challenge.isCorrect(state.enteredDigits)) return _unlock();
    return _registerWrongAnswer();
  }

  /// Starts a new question for a reopened dialog; wrong answers and an
  /// active lockout are kept.
  void reset() {
    state = state.copyWith(enteredDigits: '', challenge: _newChallenge());
  }

  /// Ends the validity at once.
  void lock() {
    state = state.copyWith(unlockedAt: () => null);
  }

  DateTime get _now => ref.read(clockProvider).now();

  /// Whether the keys work. An ended lockout is cleared here, so the
  /// attempts start over.
  bool get _canType {
    if (state.lockoutEndsAt == null) return true;
    if (lockoutRemaining > Duration.zero) return false;

    state = state.copyWith(wrongAnswers: 0, lockoutEndsAt: () => null);
    return true;
  }

  GateOutcome _unlock() {
    state = state.copyWith(
      enteredDigits: '',
      challenge: _newChallenge(),
      wrongAnswers: 0,
      unlockedAt: () => _now,
    );
    return GateOutcome.unlocked;
  }

  GateOutcome _registerWrongAnswer() {
    final wrongAnswers = state.wrongAnswers + 1;
    final isLockedOut = wrongAnswers >= maxWrongAnswers;
    state = state.copyWith(
      enteredDigits: '',
      challenge: _newChallenge(),
      wrongAnswers: wrongAnswers,
      lockoutEndsAt: isLockedOut ? () => _now.add(lockoutDuration) : null,
    );
    return isLockedOut ? GateOutcome.lockedOut : GateOutcome.wrong;
  }

  /// Draws a question different from the one on screen, so a wrong answer
  /// cannot simply be repeated.
  GateChallenge _newChallenge() {
    final random = ref.read(gateRandomProvider);
    final previous = stateOrNull?.challenge;
    GateChallenge challenge;
    do {
      challenge = GateChallenge.random(random);
    } while (challenge == previous);
    return challenge;
  }
}
