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
  String notificationTimerEndBody(String duration) {
    return 'Timer: $duration';
  }

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

  @override
  String get noticeKeepOpenTitle => 'Keep this window open';

  @override
  String get noticeKeepOpenBody =>
      'Here the alarm only rings while Kid Timer is open. Don\'t close the window or the tab until the time is up.';

  @override
  String get noticeKeepOpenOk => 'Got it';

  @override
  String get noticeNotificationsDeniedTitle => 'Notifications are off';

  @override
  String get noticeNotificationsDeniedBody =>
      'Without notifications, the alarm only rings with the app open.';

  @override
  String get noticeOpenSettings => 'Open settings';

  @override
  String get noticeContinueAnyway => 'Continue anyway';

  @override
  String get noticeExactAlarmTitle => 'Ring right on time';

  @override
  String get noticeExactAlarmBody =>
      'To ring exactly at the end, even with the screen off, Kid Timer needs the \"Alarms & reminders\" permission. Without it, the alarm may ring a few minutes late when the app is closed.';

  @override
  String get noticeAllow => 'Allow';

  @override
  String get noticeNotNow => 'Not now';

  @override
  String get noticeIosSilentBody =>
      'In silent mode, the alarm doesn\'t ring with the app closed. Keep the sound on.';

  @override
  String get noticeIosSilentOk => 'Got it';

  @override
  String get noticeVolumeZero =>
      'The volume is at zero. Turn it up to hear the alarm.';

  @override
  String get noticeBannerNoBackgroundAlarm =>
      'The alarm only rings with the app open.';

  @override
  String get noticeBannerReducedAccuracy =>
      'With the app closed, the alarm may ring a few minutes late.';

  @override
  String get notificationChannelTimerEnd => 'Timer end';

  @override
  String get notificationChannelWarning => 'Warnings';

  @override
  String get batteryHelpTitle => 'Battery, alarms and pinning';

  @override
  String get batteryHelpAlarmsTitle => 'Alarms on time';

  @override
  String get batteryHelpAlarmsBody =>
      'Kid Timer asks the system to ring at the end of the timer, even with the app closed or the screen locked. For that it needs permission to show notifications and, on Android, the \"Alarms & reminders\" permission.';

  @override
  String get batteryHelpAlarmsApple =>
      'On iPhone, iPad and Mac: Settings › Notifications › Kid Timer › turn on Allow Notifications and Time Sensitive.';

  @override
  String get batteryHelpOpenExactAlarm => 'Open alarms & reminders';

  @override
  String get batteryHelpOpenNotifications => 'Open notification settings';

  @override
  String get batteryHelpBatteryTitle => 'Battery optimization';

  @override
  String get batteryHelpBatteryBody =>
      'Some phones close apps in the background to save battery, which can delay the alarm. Let Kid Timer run without restrictions:';

  @override
  String get batteryHelpBatterySamsung =>
      'Samsung: Settings › Apps › Kid Timer › Battery › Unrestricted.';

  @override
  String get batteryHelpBatteryXiaomi =>
      'Xiaomi, Redmi, POCO: Settings › Apps › Manage apps › Kid Timer › Battery saver › No restrictions, and turn on Autostart.';

  @override
  String get batteryHelpBatteryMotorola =>
      'Motorola: Settings › Apps › Kid Timer › App battery usage › Unrestricted.';

  @override
  String get batteryHelpBatteryHuawei =>
      'Huawei: Settings › Battery › App launch › Kid Timer › Manage manually, with Auto-launch and Run in background on.';

  @override
  String get batteryHelpBatteryOthers =>
      'Others: Settings › Apps › Kid Timer › Battery › Unrestricted (or Don\'t optimize).';

  @override
  String get batteryHelpOpenBatteryOptimization => 'Open battery optimization';

  @override
  String get batteryHelpPinningTitle => 'Keep the child in the app';

  @override
  String get batteryHelpPinningAndroid =>
      'Android: turn on Settings › Security › App pinning, then pin Kid Timer from the recent apps screen.';

  @override
  String get batteryHelpPinningApple =>
      'iPhone and iPad: turn on Settings › Accessibility › Guided Access, then triple-click the side button inside Kid Timer.';

  @override
  String get batteryHelpPinningDesktop =>
      'Computers: use full screen with the child lock on.';

  @override
  String get batteryHelpWebTitle => 'Why keep the window open';

  @override
  String get batteryHelpWebBody =>
      'Browsers and Linux don\'t let apps schedule alarms with the system. Kid Timer plays the alarm itself, so it only rings while the window or tab is open and the computer is awake.';
}
