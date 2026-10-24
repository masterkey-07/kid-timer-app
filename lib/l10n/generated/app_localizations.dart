import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// Application name shown in the window title and task switcher.
  ///
  /// In pt, this message translates to:
  /// **'Kid Timer'**
  String get appTitle;

  /// Link on a platform notice banner that opens the help page.
  ///
  /// In pt, this message translates to:
  /// **'Saiba mais'**
  String get noticeLearnMore;

  /// Screen reader label of the warning icon on notice banners.
  ///
  /// In pt, this message translates to:
  /// **'Aviso'**
  String get noticeWarningLabel;

  /// Cancel button of confirmation dialogs.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// Snackbar when a vtc://preset/<id>/start link names a preset that no longer exists.
  ///
  /// In pt, this message translates to:
  /// **'Predefinição não encontrada'**
  String get deepLinkPresetNotFound;

  /// Title of the system notification shown when a timer ends with the app in the background.
  ///
  /// In pt, this message translates to:
  /// **'Acabou o tempo!'**
  String get notificationTimerEndTitle;

  /// Body of the system notification shown when a timer ends.
  ///
  /// In pt, this message translates to:
  /// **'Toque para abrir o Kid Timer.'**
  String get notificationTimerEndBody;

  /// Spoken hours part of a duration (screen readers).
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 hora} other{{count} horas}}'**
  String durationHours(int count);

  /// Spoken minutes part of a duration (screen readers).
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 minuto} other{{count} minutos}}'**
  String durationMinutes(int count);

  /// Spoken seconds part of a duration (screen readers).
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 segundo} other{{count} segundos}}'**
  String durationSeconds(int count);

  /// Joins the last part of a spoken duration, e.g. '4 minutes and 12 seconds'.
  ///
  /// In pt, this message translates to:
  /// **'{first} e {last}'**
  String durationJoin(String first, String last);

  /// Screen reader label of the editable dial on the home screen.
  ///
  /// In pt, this message translates to:
  /// **'Duração'**
  String get homeDurationLabel;

  /// Primary button on the home screen that starts the timer.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar'**
  String get homeStartButton;

  /// Screen reader label of the start button.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar timer de {duration}'**
  String homeStartSemantics(String duration);

  /// Quick button that removes one minute.
  ///
  /// In pt, this message translates to:
  /// **'−1 min'**
  String get homeMinus1;

  /// Screen reader label of the −1 min button.
  ///
  /// In pt, this message translates to:
  /// **'Diminuir 1 minuto'**
  String get homeMinus1Semantics;

  /// Quick button that adds one minute.
  ///
  /// In pt, this message translates to:
  /// **'+1 min'**
  String get homePlus1;

  /// Screen reader label of the +1 min button.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar 1 minuto'**
  String get homePlus1Semantics;

  /// Quick button that adds five minutes.
  ///
  /// In pt, this message translates to:
  /// **'+5 min'**
  String get homePlus5;

  /// Screen reader label of the +5 min button.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar 5 minutos'**
  String get homePlus5Semantics;

  /// Snackbar when a quick button reaches the 2 hour limit.
  ///
  /// In pt, this message translates to:
  /// **'Máximo de 2 horas'**
  String get homeMaxReached;

  /// Snackbar when the session cannot be saved (e.g. storage full), so the timer did not start.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar o timer. Libere espaço no aparelho e tente de novo.'**
  String get homeStartFailed;

  /// One-time hint shown on first use above the dial.
  ///
  /// In pt, this message translates to:
  /// **'Arraste a borda do mostrador para escolher o tempo'**
  String get homeDialHint;

  /// Button that dismisses the first-use dial hint.
  ///
  /// In pt, this message translates to:
  /// **'Entendi'**
  String get homeDialHintDismiss;

  /// Confirmation title when starting a timer while another one is running (only one timer at a time).
  ///
  /// In pt, this message translates to:
  /// **'Substituir o timer atual?'**
  String get homeReplaceTitle;

  /// Confirmation message when starting a timer while another one is running.
  ///
  /// In pt, this message translates to:
  /// **'Só um timer pode rodar por vez. O timer atual será encerrado.'**
  String get homeReplaceMessage;

  /// Confirm button that replaces the running timer.
  ///
  /// In pt, this message translates to:
  /// **'Substituir'**
  String get homeReplaceConfirm;

  /// Screen reader label of the countdown dial.
  ///
  /// In pt, this message translates to:
  /// **'Tempo restante'**
  String get runRemainingLabel;

  /// Screen reader label of the pause icon shown over the dial while paused.
  ///
  /// In pt, this message translates to:
  /// **'Pausado'**
  String get runPausedLabel;

  /// Countdown control that pauses the timer.
  ///
  /// In pt, this message translates to:
  /// **'Pausar'**
  String get runPause;

  /// Screen reader label of the pause control.
  ///
  /// In pt, this message translates to:
  /// **'Pausar timer'**
  String get runPauseSemantics;

  /// Countdown control that resumes a paused timer.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get runResume;

  /// Screen reader label of the resume control.
  ///
  /// In pt, this message translates to:
  /// **'Continuar timer'**
  String get runResumeSemantics;

  /// Countdown control that starts the same timer over.
  ///
  /// In pt, this message translates to:
  /// **'Reiniciar'**
  String get runRestart;

  /// Screen reader label of the restart control.
  ///
  /// In pt, this message translates to:
  /// **'Reiniciar timer'**
  String get runRestartSemantics;

  /// Confirmation title when restarting with less than half of the time left.
  ///
  /// In pt, this message translates to:
  /// **'Reiniciar o timer?'**
  String get runRestartConfirmTitle;

  /// Confirmation message when restarting the timer.
  ///
  /// In pt, this message translates to:
  /// **'A contagem recomeça do início.'**
  String get runRestartConfirmMessage;

  /// Countdown control that stops and discards the timer.
  ///
  /// In pt, this message translates to:
  /// **'Parar'**
  String get runStop;

  /// Screen reader label of the stop control.
  ///
  /// In pt, this message translates to:
  /// **'Parar timer'**
  String get runStopSemantics;

  /// Confirmation title when stopping the timer.
  ///
  /// In pt, this message translates to:
  /// **'Parar o timer?'**
  String get runStopConfirmTitle;

  /// Confirmation message when stopping the timer.
  ///
  /// In pt, this message translates to:
  /// **'A contagem termina e nada vai tocar.'**
  String get runStopConfirmMessage;

  /// Snackbar when pausing, resuming, restarting or stopping fails to save.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar a alteração. Tente de novo.'**
  String get runActionFailed;

  /// Title of the final (celebration) screen; also announced to screen readers.
  ///
  /// In pt, this message translates to:
  /// **'Acabou o tempo!'**
  String get finishedTitle;

  /// Hint shown on the final screen after 2 seconds.
  ///
  /// In pt, this message translates to:
  /// **'Toque na tela para voltar'**
  String get finishedTapToReturn;

  /// Screen reader label of the final screen's tap area.
  ///
  /// In pt, this message translates to:
  /// **'Acabou o tempo. Toque para voltar'**
  String get finishedSemantics;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
