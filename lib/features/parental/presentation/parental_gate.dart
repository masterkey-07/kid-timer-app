import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/features/parental/application/parental_gate_controller.dart';
import 'package:visual_time_counter/features/parental/domain/number_words.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

const _keySize = 64.0;
const _keySpacing = 8.0;
const _lockoutRefresh = Duration(seconds: 1);
const _answerMinHeight = 56.0;

/// Digits on the keypad rows, in a fixed order so a screen reader user always
/// finds them in the same place (contracts/ui/07 §7.1).
const _digitRows = [
  [1, 2, 3],
  [4, 5, 6],
  [7, 8, 9],
];

final Map<LogicalKeyboardKey, int> _physicalDigitKeys = {
  LogicalKeyboardKey.digit0: 0,
  LogicalKeyboardKey.digit1: 1,
  LogicalKeyboardKey.digit2: 2,
  LogicalKeyboardKey.digit3: 3,
  LogicalKeyboardKey.digit4: 4,
  LogicalKeyboardKey.digit5: 5,
  LogicalKeyboardKey.digit6: 6,
  LogicalKeyboardKey.digit7: 7,
  LogicalKeyboardKey.digit8: 8,
  LogicalKeyboardKey.digit9: 9,
  LogicalKeyboardKey.numpad0: 0,
  LogicalKeyboardKey.numpad1: 1,
  LogicalKeyboardKey.numpad2: 2,
  LogicalKeyboardKey.numpad3: 3,
  LogicalKeyboardKey.numpad4: 4,
  LogicalKeyboardKey.numpad5: 5,
  LogicalKeyboardKey.numpad6: 6,
  LogicalKeyboardKey.numpad7: 7,
  LogicalKeyboardKey.numpad8: 8,
  LogicalKeyboardKey.numpad9: 9,
};

/// Asks the multiplication and resolves to true only when it was answered
/// right (closing the dialog is false). Skips the question while an earlier
/// right answer is still valid.
Future<bool> showParentalGate(BuildContext context) async {
  final container = ProviderScope.containerOf(context);
  final gate = container.read(parentalGateControllerProvider.notifier);
  if (gate.isUnlocked) return true;

  gate.reset();
  final unlocked = await showDialog<bool>(
    context: context,
    builder: (context) => const ParentalGate(),
  );
  return unlocked ?? false;
}

/// The parental gate dialog.
///
/// Keys: `gate.dialog`, `gate.close`, `gate.question`, `gate.answer`,
/// `gate.key.<0-9>`, `gate.backspace`, `gate.ok`, `gate.error`,
/// `gate.attempts`, `gate.lockout`.
class ParentalGate extends ConsumerStatefulWidget {
  /// Creates the dialog.
  const new({super.key = const Key('gate.dialog')});

  @override
  ConsumerState<ParentalGate> createState() => _ParentalGateState();
}

class _ParentalGateState extends ConsumerState<ParentalGate> {
  Timer? _lockoutTicker;
  bool _hasWrongAnswer = false;

  @override
  void initState() {
    super.initState();
    // The remaining time comes from the clock; the timer only repaints it.
    _lockoutTicker = Timer.periodic(_lockoutRefresh, (_) => _refreshLockout());
  }

  @override
  void dispose() {
    _lockoutTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final gate = ref.watch(parentalGateControllerProvider);
    final controller = ref.read(parentalGateControllerProvider.notifier);
    final lockoutRemaining = controller.lockoutRemaining;
    final isLocked = lockoutRemaining > Duration.zero;

    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) => _handleKey(event, isLocked: isLocked),
      child: AlertDialog(
        scrollable: true,
        title: _Title(title: strings.gateTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(strings.gatePrompt),
            const SizedBox(height: _keySpacing),
            _Question(gate: gate),
            const SizedBox(height: _keySpacing),
            _Answer(digits: gate.enteredDigits),
            const SizedBox(height: _keySpacing),
            _Feedback(
              hasWrongAnswer: _hasWrongAnswer,
              attemptsLeft: gate.attemptsLeft,
              hasAttemptsCounted:
                  gate.wrongAnswers > 0 && gate.lockoutEndsAt == null,
              lockoutRemaining: lockoutRemaining,
            ),
            _Keypad(
              isEnabled: !isLocked,
              onDigit: _enterDigit,
              onBackspace: _backspace,
              onConfirm: _confirm,
            ),
          ],
        ),
      ),
    );
  }

  KeyEventResult _handleKey(KeyEvent event, {required bool isLocked}) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (_physicalDigitKeys[key] case final digit?) {
      _enterDigit(digit);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace) {
      _backspace();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _confirm();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _enterDigit(int digit) {
    setState(() => _hasWrongAnswer = false);
    ref.read(parentalGateControllerProvider.notifier).enterDigit(digit);
  }

  void _backspace() {
    setState(() => _hasWrongAnswer = false);
    ref.read(parentalGateControllerProvider.notifier).backspace();
  }

  void _confirm() {
    final outcome = ref.read(parentalGateControllerProvider.notifier).submit();
    if (outcome == GateOutcome.unlocked) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _hasWrongAnswer = outcome == GateOutcome.wrong);
  }

  void _refreshLockout() {
    final gate = ref.read(parentalGateControllerProvider);
    if (mounted && gate.lockoutEndsAt != null) setState(() {});
  }
}

class _Title extends StatelessWidget {
  const new({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title)),
        IconButton(
          key: const Key('gate.close'),
          tooltip: AppLocalizations.of(context).gateClose,
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}

class _Question extends StatelessWidget {
  const new({required this.gate});

  final GateState gate;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final words = NumberWords.multiplication(
      gate.challenge.left,
      gate.challenge.right,
      languageCode: languageCode,
    );
    return Text(
      words,
      key: const Key('gate.question'),
      style: Theme.of(context).textTheme.headlineSmall,
      textAlign: TextAlign.center,
    );
  }
}

class _Answer extends StatelessWidget {
  const new({required this.digits});

  final String digits;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: AppLocalizations.of(context).gateAnswerLabel,
      value: digits,
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: _answerMinHeight),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(_keySpacing),
        ),
        child: Text(
          digits,
          key: const Key('gate.answer'),
          style: theme.textTheme.headlineMedium,
        ),
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  const new({
    required this.hasWrongAnswer,
    required this.attemptsLeft,
    required this.hasAttemptsCounted,
    required this.lockoutRemaining,
  });

  final bool hasWrongAnswer;
  final int attemptsLeft;
  final bool hasAttemptsCounted;
  final Duration lockoutRemaining;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final errorStyle = TextStyle(color: Theme.of(context).colorScheme.error);
    final isLocked = lockoutRemaining > Duration.zero;
    return Semantics(
      liveRegion: true,
      child: Column(
        children: [
          if (isLocked)
            Text(
              strings.gateLockout(_secondsLeft(lockoutRemaining)),
              key: const Key('gate.lockout'),
              style: errorStyle,
            ),
          if (hasWrongAnswer && !isLocked)
            Text(
              strings.gateWrong,
              key: const Key('gate.error'),
              style: errorStyle,
            ),
          if (hasAttemptsCounted && !isLocked)
            Text(
              strings.gateAttemptsLeft(attemptsLeft),
              key: const Key('gate.attempts'),
            ),
        ],
      ),
    );
  }

  /// Rounds up, so the countdown never shows 0 while the keys are locked.
  int _secondsLeft(Duration remaining) =>
      (remaining.inMilliseconds / Duration.millisecondsPerSecond).ceil();
}

class _Keypad extends StatelessWidget {
  const new({
    required this.isEnabled,
    required this.onDigit,
    required this.onBackspace,
    required this.onConfirm,
  });

  final bool isEnabled;
  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _digitRows)
          _KeyRow([for (final digit in row) _digitKey(digit)]),
        _KeyRow([
          _KeypadButton(
            buttonKey: const Key('gate.backspace'),
            onPressed: isEnabled ? onBackspace : null,
            child: Icon(
              Icons.backspace_outlined,
              semanticLabel: strings.gateBackspace,
            ),
          ),
          _digitKey(0),
          _KeypadButton(
            buttonKey: const Key('gate.ok'),
            onPressed: isEnabled ? onConfirm : null,
            child: Text(strings.gateConfirm),
          ),
        ]),
      ],
    );
  }

  Widget _digitKey(int digit) => _KeypadButton(
    buttonKey: Key('gate.key.$digit'),
    onPressed: isEnabled ? () => onDigit(digit) : null,
    child: Text('$digit'),
  );
}

class _KeyRow extends StatelessWidget {
  const new(this.keys);

  final List<Widget> keys;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: _keySpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: _keySpacing,
        children: keys,
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const new({
    required this.buttonKey,
    required this.onPressed,
    required this.child,
  });

  final Key buttonKey;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      key: buttonKey,
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.square(_keySize),
        padding: EdgeInsets.zero,
        textStyle: Theme.of(context).textTheme.headlineSmall,
      ),
      child: child,
    );
  }
}
