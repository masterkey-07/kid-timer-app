import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_time_counter/app/router.dart';
import 'package:visual_time_counter/app/widgets/confirm_dialog.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/timer/application/start_preflight.dart';
import 'package:visual_time_counter/features/timer/application/timer_controller.dart';
import 'package:visual_time_counter/features/timer/presentation/widgets/preflight_dialogs.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// Starts a timer with [config] from a screen of the adult: runs the start
/// checks (contracts/ui/08), asks before replacing an active timer
/// (FR-007) and opens the countdown. A storage failure shows a snackbar
/// keyed `<screen>.startFailed`.
Future<void> startTimer(
  BuildContext context,
  WidgetRef ref,
  TimerConfig config, {
  SessionOrigin origin = const ManualOrigin(),
  String screen = 'home',
}) async {
  final l10n = AppLocalizations.of(context);
  final controller = ref.read(timerControllerProvider.notifier);

  await ref.read(startPreflightProvider).run(DialogPreflightPrompts(context));
  if (!context.mounted) return;
  var result = await controller.start(config, origin: origin);
  if (result == TimerActionResult.needsConfirmation) {
    if (!context.mounted) return;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.homeReplaceTitle,
      message: l10n.homeReplaceMessage,
      confirmLabel: l10n.homeReplaceConfirm,
    );
    if (!confirmed) return;
    result = await controller.start(
      config,
      origin: origin,
      replaceActive: true,
    );
  }

  if (!context.mounted) return;
  switch (result) {
    case TimerActionResult.done:
      context.go(AppRoutes.run);
    case TimerActionResult.storageFailed:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: Key('$screen.startFailed'),
          content: Text(l10n.homeStartFailed),
        ),
      );
    case TimerActionResult.needsConfirmation:
      break;
  }
}
