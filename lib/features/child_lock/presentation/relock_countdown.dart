import 'package:flutter/material.dart';
import 'package:visual_time_counter/features/child_lock/application/unlock_controller.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// "Locks again in 8 s" with a shrinking bar under the unlocked controls
/// (contracts/ui/02). Only shows the time; [UnlockController] locks.
///
/// Key: `run.relockIn`.
class RelockCountdown extends StatefulWidget {
  /// Creates the countdown for the controls' [window].
  const new({required this.window, super.key = const Key('run.relockIn')});

  /// Starts the countdown over whenever it changes.
  final int window;

  @override
  State<RelockCountdown> createState() => _RelockCountdownState();
}

class _RelockCountdownState extends State<RelockCountdown>
    with SingleTickerProviderStateMixin {
  static const _barWidth = 200.0;
  static const _spacing = 8.0;

  // Counts real seconds, so reduce motion must not shorten it.
  late final _elapsed = AnimationController(
    vsync: this,
    duration: UnlockController.controlsDuration,
    animationBehavior: AnimationBehavior.preserve,
  )..forward();

  @override
  void didUpdateWidget(RelockCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.window != widget.window) _elapsed.forward(from: 0);
  }

  @override
  void dispose() {
    _elapsed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalSeconds = UnlockController.controlsDuration.inSeconds;
    return Padding(
      padding: const EdgeInsets.only(top: _spacing * 2),
      child: AnimatedBuilder(
        animation: _elapsed,
        builder: (context, _) {
          final left = 1 - _elapsed.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.runRelockIn((left * totalSeconds).ceil())),
              const SizedBox(height: _spacing),
              SizedBox(
                width: _barWidth,
                child: LinearProgressIndicator(value: left),
              ),
            ],
          );
        },
      ),
    );
  }
}
