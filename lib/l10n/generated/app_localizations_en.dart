// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Kid Timer';

  @override
  String get noticeLearnMore => 'Learn more';

  @override
  String get noticeWarningLabel => 'Warning';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get deepLinkPresetNotFound => 'Preset not found';

  @override
  String get notificationTimerEndTitle => 'Time\'s up!';

  @override
  String get notificationTimerEndBody => 'Tap to open Kid Timer.';

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String durationSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seconds',
      one: '1 second',
    );
    return '$_temp0';
  }

  @override
  String durationJoin(String first, String last) {
    return '$first and $last';
  }

  @override
  String get homeDurationLabel => 'Duration';

  @override
  String get homeStartButton => 'Start';

  @override
  String homeStartSemantics(String duration) {
    return 'Start $duration timer';
  }

  @override
  String get homeMinus1 => '−1 min';

  @override
  String get homeMinus1Semantics => 'Decrease 1 minute';

  @override
  String get homePlus1 => '+1 min';

  @override
  String get homePlus1Semantics => 'Add 1 minute';

  @override
  String get homePlus5 => '+5 min';

  @override
  String get homePlus5Semantics => 'Add 5 minutes';

  @override
  String get homeMaxReached => 'Maximum of 2 hours';

  @override
  String get homeStartFailed =>
      'The timer could not be saved. Free up some space on the device and try again.';

  @override
  String get homeDialHint => 'Drag the edge of the dial to choose the time';

  @override
  String get homeDialHintDismiss => 'Got it';

  @override
  String get homeReplaceTitle => 'Replace the current timer?';

  @override
  String get homeReplaceMessage =>
      'Only one timer can run at a time. The current timer will end.';

  @override
  String get homeReplaceConfirm => 'Replace';

  @override
  String get runRemainingLabel => 'Time remaining';

  @override
  String get runPausedLabel => 'Paused';

  @override
  String get runPause => 'Pause';

  @override
  String get runPauseSemantics => 'Pause timer';

  @override
  String get runResume => 'Resume';

  @override
  String get runResumeSemantics => 'Resume timer';

  @override
  String get runRestart => 'Restart';

  @override
  String get runRestartSemantics => 'Restart timer';

  @override
  String get runRestartConfirmTitle => 'Restart the timer?';

  @override
  String get runRestartConfirmMessage =>
      'The countdown starts over from the beginning.';

  @override
  String get runStop => 'Stop';

  @override
  String get runStopSemantics => 'Stop timer';

  @override
  String get runStopConfirmTitle => 'Stop the timer?';

  @override
  String get runStopConfirmMessage =>
      'The countdown ends and nothing will ring.';

  @override
  String get runActionFailed => 'The change could not be saved. Try again.';

  @override
  String get finishedTitle => 'Time\'s up!';

  @override
  String get finishedTapToReturn => 'Tap the screen to go back';

  @override
  String get finishedSemantics => 'Time\'s up. Tap to go back';
}
