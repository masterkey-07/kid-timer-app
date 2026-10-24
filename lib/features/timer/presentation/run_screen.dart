import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_time_counter/app/layout.dart';
import 'package:visual_time_counter/app/router.dart';
import 'package:visual_time_counter/app/widgets/confirm_dialog.dart';
import 'package:visual_time_counter/core/clock/clock_provider.dart';
import 'package:visual_time_counter/core/platform/providers.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/settings/application/app_settings_state.dart';
import 'package:visual_time_counter/features/timer/application/run_controller.dart';
import 'package:visual_time_counter/features/timer/application/timer_controller.dart';
import 'package:visual_time_counter/features/timer/presentation/widgets/background_alarm_banner.dart';
import 'package:visual_time_counter/features/timer/presentation/widgets/dial_view.dart';
import 'package:visual_time_counter/features/timer/presentation/widgets/digits_label.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// The countdown (contracts/ui/02). In v1.0 US1 the controls are always
/// visible; the child lock (US4) hides them.
class RunScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const new({super.key = const Key('run.screen')});

  @override
  ConsumerState<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends ConsumerState<RunScreen> {
  /// Below this share of the time left, restarting asks first.
  static const _restartConfirmBelow = 0.5;

  /// The dial takes this share of the smaller side (contracts/ui/00 §3).
  static const _dialShare = 0.82;

  /// Room kept under a stacked dial for the digits and the controls.
  static const _controlsHeight = 200.0;

  StreamSubscription<AppLifecycleState>? _lifecycle;

  TimerController get _controller => ref.read(timerControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _lifecycle = ref.read(appLifecycleProvider).states.listen((state) {
      // The OS alarm covers the background; back in front, catch up with
      // the clock (contracts/ui/02 Behavior 4).
      if (state == AppLifecycleState.resumed) {
        unawaited(_controller.checkTimeUp());
      }
    });
  }

  @override
  void dispose() {
    unawaited(_lifecycle?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(timerControllerProvider, (_, session) => _follow(session));
    final session = ref.watch(timerControllerProvider);
    if (session == null || !session.status.isActive) {
      return const Scaffold(body: SizedBox.expand());
    }
    // Keeps the screen on, full screen and the single ring while shown.
    ref.watch(runControllerProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_stop());
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.space): _pauseOrResume,
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) =>
                    _layout(constraints.biggest, session),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _layout(Size size, TimerSession session) {
    final layout = ScreenLayout.of(size);
    final dial = DialView.countdown(
      key: const Key('run.dial'),
      session: session,
    );
    final childLockEnabled = ref.watch(
      appSettingsProvider.select((settings) => settings.childLockEnabled),
    );
    final details = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Never in child mode (contracts/ui/08 §8.2); the child lock (US4)
        // shows it on the unlocked controls.
        if (!childLockEnabled)
          const BackgroundAlarmBanner(padding: EdgeInsets.only(bottom: 12)),
        if (session.config.showDigits)
          CountdownDigits(key: const Key('run.digits'), session: session),
        _RunControls(
          session: session,
          onPauseResume: _pauseOrResume,
          onRestart: () => unawaited(_restart()),
          onStop: () => unawaited(_stop()),
        ),
      ],
    );

    if (layout.isLandscape) {
      return Row(
        children: [
          Expanded(
            child: Center(
              child: SizedBox.square(
                dimension: size.height * _dialShare,
                child: dial,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(layout.margin),
              child: details,
            ),
          ),
        ],
      );
    }

    final dialSize = (size.height - _controlsHeight).clamp(0.0, size.width);
    return SingleChildScrollView(
      padding: EdgeInsets.all(layout.margin),
      child: Column(
        children: [
          SizedBox.square(dimension: dialSize * _dialShare, child: dial),
          details,
        ],
      ),
    );
  }

  /// Leaves the screen when the session ends or goes away.
  void _follow(TimerSession? session) {
    if (!mounted) return;
    if (session == null) {
      context.go(AppRoutes.home);
    } else if (session.status == SessionStatus.finished) {
      context.go(AppRoutes.finished);
    }
  }

  void _pauseOrResume() {
    final session = ref.read(timerControllerProvider);
    if (session == null) return;
    unawaited(
      _report(
        session.status == SessionStatus.paused
            ? _controller.resume()
            : _controller.pause(),
      ),
    );
  }

  Future<void> _restart() async {
    final session = ref.read(timerControllerProvider)!;
    final now = ref.read(clockProvider).now();
    if (session.progress(now) < _restartConfirmBelow) {
      final l10n = AppLocalizations.of(context);
      final confirmed = await showConfirmDialog(
        context,
        title: l10n.runRestartConfirmTitle,
        message: l10n.runRestartConfirmMessage,
        confirmLabel: l10n.runRestart,
      );
      if (!confirmed) return;
    }
    await _report(_controller.restart());
  }

  Future<void> _stop() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.runStopConfirmTitle,
      message: l10n.runStopConfirmMessage,
      confirmLabel: l10n.runStop,
      isDestructive: true,
    );
    if (confirmed) await _report(_controller.cancel());
  }

  /// Tells the adult when a change could not be saved.
  Future<void> _report(Future<TimerActionResult> action) async {
    final result = await action;
    if (result != TimerActionResult.storageFailed || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const Key('run.actionFailed'),
        content: Text(AppLocalizations.of(context).runActionFailed),
      ),
    );
  }
}

/// Pause/resume, restart and stop.
class _RunControls extends StatelessWidget {
  const new({
    required this.session,
    required this.onPauseResume,
    required this.onRestart,
    required this.onStop,
  });

  final TimerSession session;
  final VoidCallback onPauseResume;
  final VoidCallback onRestart;
  final VoidCallback onStop;

  static const _spacing = 12.0;
  static const _buttonHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isPaused = session.status == SessionStatus.paused;
    final buttonStyle = FilledButton.styleFrom(
      minimumSize: const Size(_buttonHeight, _buttonHeight),
    );
    return Padding(
      padding: const EdgeInsets.only(top: _spacing),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: _spacing,
        runSpacing: _spacing,
        children: [
          FilledButton.icon(
            key: const Key('run.pauseResume'),
            style: buttonStyle,
            onPressed: onPauseResume,
            icon: Icon(
              isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            ),
            label: Text(
              isPaused ? l10n.runResume : l10n.runPause,
              semanticsLabel: isPaused
                  ? l10n.runResumeSemantics
                  : l10n.runPauseSemantics,
            ),
          ),
          FilledButton.tonalIcon(
            key: const Key('run.restart'),
            style: buttonStyle,
            onPressed: onRestart,
            icon: const Icon(Icons.replay_rounded),
            label: Text(
              l10n.runRestart,
              semanticsLabel: l10n.runRestartSemantics,
            ),
          ),
          FilledButton.tonalIcon(
            key: const Key('run.stop'),
            style: buttonStyle,
            onPressed: onStop,
            icon: const Icon(Icons.stop_rounded),
            label: Text(l10n.runStop, semanticsLabel: l10n.runStopSemantics),
          ),
        ],
      ),
    );
  }
}
