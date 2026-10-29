import 'package:flutter/material.dart';
import 'package:visual_time_counter/core/domain/timer_duration.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// The −1 min, +1 min and +5 min buttons (FR-001); keys
/// `<keyPrefix>.minus1`, `<keyPrefix>.plus1` and `<keyPrefix>.plus5`.
class DurationQuickButtons extends StatelessWidget {
  /// Creates the buttons for [duration].
  const new({
    required this.duration,
    required this.onChanged,
    required this.onMaxReached,
    this.keyPrefix = 'home',
    super.key,
  });

  /// The screen part of the button keys.
  final String keyPrefix;

  /// The current duration.
  final TimerDuration duration;

  /// Called with the adjusted duration.
  final ValueChanged<TimerDuration> onChanged;

  /// Called when +5 min had to stop at the maximum.
  final VoidCallback onMaxReached;

  static const _oneMinute = Duration(minutes: 1);
  static const _fiveMinutes = Duration(minutes: 5);
  static const _spacing = 8.0;

  bool get _isAtMin => duration.value <= TimerDuration.min;

  bool get _isAtMax => duration.value >= TimerDuration.max;

  void _addFiveMinutes() {
    final target = duration.value + _fiveMinutes;
    onChanged(duration.adjustedBy(_fiveMinutes));
    if (target > TimerDuration.max) onMaxReached();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: _spacing,
      runSpacing: _spacing,
      children: [
        _QuickButton(
          buttonKey: Key('$keyPrefix.minus1'),
          label: l10n.homeMinus1,
          semanticsLabel: l10n.homeMinus1Semantics,
          onPressed: _isAtMin
              ? null
              : () => onChanged(duration.adjustedBy(-_oneMinute)),
        ),
        _QuickButton(
          buttonKey: Key('$keyPrefix.plus1'),
          label: l10n.homePlus1,
          semanticsLabel: l10n.homePlus1Semantics,
          onPressed: _isAtMax
              ? null
              : () => onChanged(duration.adjustedBy(_oneMinute)),
        ),
        _QuickButton(
          buttonKey: Key('$keyPrefix.plus5'),
          label: l10n.homePlus5,
          semanticsLabel: l10n.homePlus5Semantics,
          onPressed: _isAtMax ? null : _addFiveMinutes,
        ),
      ],
    );
  }
}

class _QuickButton extends StatelessWidget {
  const new({
    required this.buttonKey,
    required this.label,
    required this.semanticsLabel,
    required this.onPressed,
  });

  /// The test key goes on the button itself, so tests can read its state.
  final Key buttonKey;
  final String label;
  final String semanticsLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    key: buttonKey,
    onPressed: onPressed,
    child: Text(label, semanticsLabel: semanticsLabel),
  );
}
