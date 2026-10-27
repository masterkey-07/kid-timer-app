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
  String get runUnlockHint => 'Hold for 3 seconds to show the controls';

  @override
  String runRelockIn(int seconds) {
    return 'Locks again in $seconds s';
  }

  @override
  String get settingsSectionChildMode => 'Child mode';

  @override
  String get settingsChildLock => 'Child lock';

  @override
  String get settingsChildLockDescription =>
      'Hides the controls during the countdown; hold the padlock for 3 seconds to show them.';

  @override
  String get settingsChildLockOffConfirmTitle => 'Turn off the child lock?';

  @override
  String get settingsChildLockOffConfirm =>
      'The child will be able to pause the timer.';

  @override
  String get settingsChildLockOffConfirmAction => 'Turn off';

  @override
  String get settingsChildLockPinning => 'How to keep the child in the app';

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

  @override
  String get imagesFileTypeLabel => 'Images';

  @override
  String get imagesTitle => 'Choose image';

  @override
  String get imagesManage => 'Manage';

  @override
  String get imagesManageLabel => 'Manage my images';

  @override
  String get imagesTabAll => 'All';

  @override
  String get imagesCategoryHygiene => 'Hygiene';

  @override
  String get imagesCategoryMeal => 'Meals';

  @override
  String get imagesCategoryPlay => 'Play';

  @override
  String get imagesCategoryRest => 'Rest';

  @override
  String get imagesCategorySchool => 'School';

  @override
  String get imagesCategoryGoingOut => 'Going out';

  @override
  String get imagesTabMine => 'My images';

  @override
  String imagesTabLabel(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count images',
      one: '1 image',
    );
    return '$name, $_temp0';
  }

  @override
  String get imagesFromDevice => 'From my device';

  @override
  String get imagesFromDeviceLabel => 'Choose an image from my device';

  @override
  String get imagesNone => 'No image (use colors)';

  @override
  String get imagesNoneLabel => 'Use colors instead of an image';

  @override
  String get imagesMineEmpty => 'You haven\'t added any images yet';

  @override
  String get imagesWebStorageNote =>
      'In the browser, your images are saved only in this browser and disappear if you clear the site\'s data.';

  @override
  String get imagesOpenError =>
      'This image couldn\'t be opened. Try a JPG or PNG photo.';

  @override
  String get imagesLimitTitle => 'Image limit reached';

  @override
  String imagesLimitReached(int max) {
    return 'You already have $max images. Delete some in My images to add more.';
  }

  @override
  String get imagesLimitManage => 'Open My images';

  @override
  String get imagesOwnImage => 'My image';

  @override
  String get frameTitle => 'Frame';

  @override
  String get frameSave => 'Save';

  @override
  String get frameCanvasLabel => 'Framing area. Drag to move, pinch to zoom';

  @override
  String get frameZoom => 'Zoom';

  @override
  String frameZoomValue(int percent) {
    return '$percent%';
  }

  @override
  String get frameZoomIn => 'Zoom in';

  @override
  String get frameZoomOut => 'Zoom out';

  @override
  String get frameCenter => 'Center';

  @override
  String get frameName => 'Name (optional)';

  @override
  String get framePreparing => 'Preparing image…';

  @override
  String get frameError => 'This image couldn\'t be saved. Try another photo.';

  @override
  String get mineTitle => 'My images';

  @override
  String mineCount(int count, int max) {
    return '$count of $max';
  }

  @override
  String get mineDelete => 'Delete';

  @override
  String mineDeleteLabel(String name) {
    return 'Delete $name';
  }

  @override
  String get mineDeleteTitle => 'Delete image?';

  @override
  String get mineDeleteConfirm => 'The image will be deleted from this device.';

  @override
  String mineAffectedPresets(String names) {
    return 'These presets will switch to colors: $names.';
  }

  @override
  String get mineAffectedTimer =>
      'The timer on the home screen will switch to colors too.';

  @override
  String get mineRename => 'Rename';

  @override
  String get mineRenameTitle => 'Rename image';

  @override
  String get mineNameField => 'Name';

  @override
  String homeImageChip(String name) {
    return 'Image: $name';
  }

  @override
  String homeImageChipSemantics(String name) {
    return 'Image: $name. Tap to change';
  }

  @override
  String get homeNoImage => 'No image';

  @override
  String get homeNoImageSemantics => 'No image. Tap to choose an image';

  @override
  String get homeImageMissing =>
      'This timer\'s image was deleted, so it uses colors.';

  @override
  String get imagesCategoryAnimals => 'Animals';
}
