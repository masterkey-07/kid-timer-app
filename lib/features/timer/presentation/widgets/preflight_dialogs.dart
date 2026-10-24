import 'package:flutter/material.dart';
import 'package:visual_time_counter/features/timer/application/start_preflight.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// The start preflight's dialogs and notices, keyed per contracts/ui/08.
///
/// Dialogs need an explicit answer (no barrier tap); if the screen goes
/// away mid-preflight, each prompt answers with the choice that just
/// starts the timer.
class DialogPreflightPrompts implements PreflightPrompts {
  /// Creates the prompts shown over the given context.
  const new(this._context);

  final BuildContext _context;

  AppLocalizations get _l10n => AppLocalizations.of(_context);

  @override
  Future<void> showKeepOpen() => _show<void>(
    key: 'notice.keepOpen',
    title: _l10n.noticeKeepOpenTitle,
    body: _l10n.noticeKeepOpenBody,
    actions: {'notice.keepOpen.ok': (_l10n.noticeKeepOpenOk, null)},
  );

  @override
  Future<NotificationsDeniedChoice> showNotificationsDenied() async =>
      await _show(
        key: 'notice.notificationsDenied',
        title: _l10n.noticeNotificationsDeniedTitle,
        body: _l10n.noticeNotificationsDeniedBody,
        actions: {
          'notice.notificationsDenied.continue': (
            _l10n.noticeContinueAnyway,
            NotificationsDeniedChoice.continueAnyway,
          ),
          'notice.notificationsDenied.openSettings': (
            _l10n.noticeOpenSettings,
            NotificationsDeniedChoice.openSettings,
          ),
        },
      ) ??
      NotificationsDeniedChoice.continueAnyway;

  @override
  Future<ExactAlarmChoice> showExactAlarm() async =>
      await _show(
        key: 'notice.exactAlarm',
        title: _l10n.noticeExactAlarmTitle,
        body: _l10n.noticeExactAlarmBody,
        actions: {
          'notice.exactAlarm.notNow': (
            _l10n.noticeNotNow,
            ExactAlarmChoice.notNow,
          ),
          'notice.exactAlarm.allow': (
            _l10n.noticeAllow,
            ExactAlarmChoice.allow,
          ),
        },
      ) ??
      ExactAlarmChoice.notNow;

  @override
  Future<void> showIosSilent() => _show<void>(
    key: 'notice.iosSilent',
    body: _l10n.noticeIosSilentBody,
    actions: {'notice.iosSilent.ok': (_l10n.noticeIosSilentOk, null)},
  );

  @override
  void showVolumeZero() {
    if (!_context.mounted) return;
    ScaffoldMessenger.of(_context).showSnackBar(
      // The default 4 s duration is the one contracts/ui/08 §8.1 asks for.
      SnackBar(
        key: const Key('notice.volumeZero'),
        content: Text(_l10n.noticeVolumeZero),
      ),
    );
  }

  /// Shows a dialog whose [actions] map a button key to its label and the
  /// value it answers; the last action is the primary one.
  Future<T?> _show<T>({
    required String key,
    required String body,
    required Map<String, (String, T)> actions,
    String? title,
  }) async {
    if (!_context.mounted) return null;
    final buttons = actions.entries.toList();
    final primary = buttons.removeLast();
    return await showDialog<T>(
      context: _context,
      barrierDismissible: false,
      builder: (context) {
        void answer(T value) => Navigator.of(context).pop(value);
        return AlertDialog(
          key: Key(key),
          title: title == null ? null : Text(title),
          content: Text(body),
          actions: [
            for (final MapEntry(key: buttonKey, value: (label, value))
                in buttons)
              TextButton(
                key: Key(buttonKey),
                onPressed: () => answer(value),
                child: Text(label),
              ),
            FilledButton(
              key: Key(primary.key),
              onPressed: () => answer(primary.value.$2),
              child: Text(primary.value.$1),
            ),
          ],
        );
      },
    );
  }
}
