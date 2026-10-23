import 'package:flutter/material.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// Asks the adult to confirm an action; resolves to true only when
/// [confirmLabel] is tapped (cancel, Esc and tapping outside are false).
///
/// Keys: `confirm.dialog`, `confirm.confirm`, `confirm.cancel`.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool isDestructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      isDestructive: isDestructive,
    ),
  );
  return confirmed ?? false;
}

/// The dialog shown by [showConfirmDialog].
class ConfirmDialog extends StatelessWidget {
  /// Creates the dialog.
  const new({
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.isDestructive = false,
    super.key = const Key('confirm.dialog'),
  });

  /// The question.
  final String title;

  /// What happens on confirmation.
  final String message;

  /// The confirm button label.
  final String confirmLabel;

  /// Whether confirming destroys data (uses the error color).
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      scrollable: true,
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          key: const Key('confirm.cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(AppLocalizations.of(context).commonCancel),
        ),
        FilledButton(
          key: const Key('confirm.confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          style: isDestructive
              ? FilledButton.styleFrom(
                  backgroundColor: colors.error,
                  foregroundColor: colors.onError,
                )
              : null,
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
