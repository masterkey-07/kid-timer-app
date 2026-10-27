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

  /// Body of the system notification shown when a timer ends; names the timer by its duration until presets (US5) give it a name.
  ///
  /// In pt, this message translates to:
  /// **'Timer: {duration}'**
  String notificationTimerEndBody(String duration);

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

  /// Screen reader label of the padlock in child mode.
  ///
  /// In pt, this message translates to:
  /// **'Segure por 3 segundos para mostrar os controles'**
  String get runUnlockHint;

  /// Countdown under the unlocked controls until child mode returns.
  ///
  /// In pt, this message translates to:
  /// **'Bloqueia de novo em {seconds} s'**
  String runRelockIn(int seconds);

  /// Settings section header.
  ///
  /// In pt, this message translates to:
  /// **'Modo criança'**
  String get settingsSectionChildMode;

  /// Switch that locks the countdown screen for the child.
  ///
  /// In pt, this message translates to:
  /// **'Bloqueio infantil'**
  String get settingsChildLock;

  /// Explanation under the child lock switch.
  ///
  /// In pt, this message translates to:
  /// **'Esconde os controles durante a contagem; segure o cadeado por 3 segundos para mostrá-los.'**
  String get settingsChildLockDescription;

  /// Confirmation title when turning the child lock off.
  ///
  /// In pt, this message translates to:
  /// **'Desativar o bloqueio infantil?'**
  String get settingsChildLockOffConfirmTitle;

  /// Confirmation message when turning the child lock off.
  ///
  /// In pt, this message translates to:
  /// **'A criança vai poder pausar o timer.'**
  String get settingsChildLockOffConfirm;

  /// Confirm button that turns the child lock off.
  ///
  /// In pt, this message translates to:
  /// **'Desativar'**
  String get settingsChildLockOffConfirmAction;

  /// Link to the screen pinning help.
  ///
  /// In pt, this message translates to:
  /// **'Como manter a criança no app'**
  String get settingsChildLockPinning;

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

  /// Title of the one-time start dialog on platforms without background alarms (Web, Linux).
  ///
  /// In pt, this message translates to:
  /// **'Mantenha esta janela aberta'**
  String get noticeKeepOpenTitle;

  /// Body of the keep-the-window-open dialog.
  ///
  /// In pt, this message translates to:
  /// **'Aqui o alarme só toca com o Kid Timer aberto. Não feche a janela nem a aba até o tempo acabar.'**
  String get noticeKeepOpenBody;

  /// Button that closes the keep-the-window-open dialog.
  ///
  /// In pt, this message translates to:
  /// **'Entendi'**
  String get noticeKeepOpenOk;

  /// Title of the start dialog when notifications are denied.
  ///
  /// In pt, this message translates to:
  /// **'As notificações estão desligadas'**
  String get noticeNotificationsDeniedTitle;

  /// Body of the notifications-denied dialog.
  ///
  /// In pt, this message translates to:
  /// **'Sem notificações, o alarme só toca com o app aberto.'**
  String get noticeNotificationsDeniedBody;

  /// Button that opens the app notification settings.
  ///
  /// In pt, this message translates to:
  /// **'Abrir configurações'**
  String get noticeOpenSettings;

  /// Button that starts the timer without notifications.
  ///
  /// In pt, this message translates to:
  /// **'Continuar mesmo assim'**
  String get noticeContinueAnyway;

  /// Title of the one-time exact alarm explanation (Android 12–13).
  ///
  /// In pt, this message translates to:
  /// **'Tocar na hora certa'**
  String get noticeExactAlarmTitle;

  /// Body of the exact alarm explanation.
  ///
  /// In pt, this message translates to:
  /// **'Para tocar exatamente no fim, mesmo com a tela apagada, o Kid Timer precisa da permissão \"Alarmes e lembretes\". Sem ela, o alarme pode tocar alguns minutos depois quando o app estiver fechado.'**
  String get noticeExactAlarmBody;

  /// Button that opens the Alarms & reminders setting.
  ///
  /// In pt, this message translates to:
  /// **'Permitir'**
  String get noticeAllow;

  /// Button that starts with reduced alarm accuracy.
  ///
  /// In pt, this message translates to:
  /// **'Agora não'**
  String get noticeNotNow;

  /// One-time iOS notice before the first timer.
  ///
  /// In pt, this message translates to:
  /// **'No modo silencioso, o alarme não toca com o app fechado. Mantenha o som ligado.'**
  String get noticeIosSilentBody;

  /// Button that closes the iOS silent mode notice.
  ///
  /// In pt, this message translates to:
  /// **'Entendi'**
  String get noticeIosSilentOk;

  /// Brief notice when the timer starts with the system volume at zero.
  ///
  /// In pt, this message translates to:
  /// **'O volume está no zero. Aumente para ouvir o alarme.'**
  String get noticeVolumeZero;

  /// Banner when the platform or the permissions give no background alarm.
  ///
  /// In pt, this message translates to:
  /// **'O alarme só toca com o app aberto.'**
  String get noticeBannerNoBackgroundAlarm;

  /// Banner when only inexact alarms are allowed.
  ///
  /// In pt, this message translates to:
  /// **'Com o app fechado, o alarme pode tocar alguns minutos depois.'**
  String get noticeBannerReducedAccuracy;

  /// Android notification channel for the end of a timer.
  ///
  /// In pt, this message translates to:
  /// **'Fim do timer'**
  String get notificationChannelTimerEnd;

  /// Android notification channel for warnings before the end.
  ///
  /// In pt, this message translates to:
  /// **'Avisos'**
  String get notificationChannelWarning;

  /// Title of the help page about battery, alarms and screen pinning.
  ///
  /// In pt, this message translates to:
  /// **'Bateria, alarmes e fixação'**
  String get batteryHelpTitle;

  /// Help section about alarm permissions.
  ///
  /// In pt, this message translates to:
  /// **'Alarmes na hora certa'**
  String get batteryHelpAlarmsTitle;

  /// Why the app needs alarm and notification permissions.
  ///
  /// In pt, this message translates to:
  /// **'O Kid Timer pede ao sistema para tocar no fim do timer, mesmo com o app fechado ou a tela bloqueada. Para isso ele precisa da permissão de notificações e, no Android, da permissão \"Alarmes e lembretes\".'**
  String get batteryHelpAlarmsBody;

  /// Instructions for Apple platforms.
  ///
  /// In pt, this message translates to:
  /// **'No iPhone, iPad e Mac: Ajustes › Notificações › Kid Timer › ative Permitir Notificações e Sensível ao Tempo.'**
  String get batteryHelpAlarmsApple;

  /// Android button that opens the exact alarm setting.
  ///
  /// In pt, this message translates to:
  /// **'Abrir alarmes e lembretes'**
  String get batteryHelpOpenExactAlarm;

  /// Android button that opens the app notification settings.
  ///
  /// In pt, this message translates to:
  /// **'Abrir configurações de notificação'**
  String get batteryHelpOpenNotifications;

  /// Help section about battery optimization.
  ///
  /// In pt, this message translates to:
  /// **'Otimização de bateria'**
  String get batteryHelpBatteryTitle;

  /// Intro to the per-vendor battery steps.
  ///
  /// In pt, this message translates to:
  /// **'Alguns celulares fecham apps em segundo plano para poupar bateria, o que pode atrasar o alarme. Deixe o Kid Timer rodar sem restrições:'**
  String get batteryHelpBatteryBody;

  /// Battery steps for Samsung.
  ///
  /// In pt, this message translates to:
  /// **'Samsung: Configurações › Aplicativos › Kid Timer › Bateria › Sem restrições.'**
  String get batteryHelpBatterySamsung;

  /// Battery steps for Xiaomi, Redmi and POCO.
  ///
  /// In pt, this message translates to:
  /// **'Xiaomi, Redmi, POCO: Configurações › Apps › Gerenciar apps › Kid Timer › Economia de bateria › Sem restrições, e ative a Inicialização automática.'**
  String get batteryHelpBatteryXiaomi;

  /// Battery steps for Motorola.
  ///
  /// In pt, this message translates to:
  /// **'Motorola: Configurações › Apps › Kid Timer › Uso da bateria pelo app › Sem restrições.'**
  String get batteryHelpBatteryMotorola;

  /// Battery steps for Huawei.
  ///
  /// In pt, this message translates to:
  /// **'Huawei: Configurações › Bateria › Inicialização de apps › Kid Timer › Gerenciar manualmente, com Inicialização automática e Executar em segundo plano ativados.'**
  String get batteryHelpBatteryHuawei;

  /// Battery steps for other vendors.
  ///
  /// In pt, this message translates to:
  /// **'Outros: Configurações › Apps › Kid Timer › Bateria › Sem restrições (ou Não otimizar).'**
  String get batteryHelpBatteryOthers;

  /// Android button that opens the battery optimization settings.
  ///
  /// In pt, this message translates to:
  /// **'Abrir otimização de bateria'**
  String get batteryHelpOpenBatteryOptimization;

  /// Help section about screen pinning.
  ///
  /// In pt, this message translates to:
  /// **'Manter a criança no app'**
  String get batteryHelpPinningTitle;

  /// Screen pinning on Android.
  ///
  /// In pt, this message translates to:
  /// **'Android: ative Configurações › Segurança › Fixar app e depois fixe o Kid Timer na tela de apps recentes.'**
  String get batteryHelpPinningAndroid;

  /// Guided Access on iOS and iPadOS.
  ///
  /// In pt, this message translates to:
  /// **'iPhone e iPad: ative Ajustes › Acessibilidade › Acesso Guiado e depois clique três vezes no botão lateral dentro do Kid Timer.'**
  String get batteryHelpPinningApple;

  /// Keeping the child in the app on desktop.
  ///
  /// In pt, this message translates to:
  /// **'Computadores: use a tela cheia com o bloqueio infantil ativado.'**
  String get batteryHelpPinningDesktop;

  /// Help section about Web and Linux.
  ///
  /// In pt, this message translates to:
  /// **'Por que manter a janela aberta'**
  String get batteryHelpWebTitle;

  /// Why Web and Linux need the window open.
  ///
  /// In pt, this message translates to:
  /// **'Navegadores e o Linux não deixam apps agendarem alarmes no sistema. O próprio Kid Timer toca o alarme, então ele só toca com a janela ou a aba aberta e o computador ligado.'**
  String get batteryHelpWebBody;

  /// Name of the image filter in the desktop file dialog.
  ///
  /// In pt, this message translates to:
  /// **'Imagens'**
  String get imagesFileTypeLabel;

  /// Title of the image picker (/images).
  ///
  /// In pt, this message translates to:
  /// **'Escolher imagem'**
  String get imagesTitle;

  /// App bar button that opens My images.
  ///
  /// In pt, this message translates to:
  /// **'Gerenciar'**
  String get imagesManage;

  /// Screen reader label of the Manage button.
  ///
  /// In pt, this message translates to:
  /// **'Gerenciar minhas imagens'**
  String get imagesManageLabel;

  /// Picker tab with every library image.
  ///
  /// In pt, this message translates to:
  /// **'Todas'**
  String get imagesTabAll;

  /// Library category.
  ///
  /// In pt, this message translates to:
  /// **'Higiene'**
  String get imagesCategoryHygiene;

  /// Library category.
  ///
  /// In pt, this message translates to:
  /// **'Refeições'**
  String get imagesCategoryMeal;

  /// Library category.
  ///
  /// In pt, this message translates to:
  /// **'Brincar'**
  String get imagesCategoryPlay;

  /// Library category.
  ///
  /// In pt, this message translates to:
  /// **'Descanso'**
  String get imagesCategoryRest;

  /// Library category.
  ///
  /// In pt, this message translates to:
  /// **'Escola'**
  String get imagesCategorySchool;

  /// Library category.
  ///
  /// In pt, this message translates to:
  /// **'Passeio'**
  String get imagesCategoryGoingOut;

  /// Picker tab with the adult's own images.
  ///
  /// In pt, this message translates to:
  /// **'Minhas imagens'**
  String get imagesTabMine;

  /// Screen reader label of a picker tab.
  ///
  /// In pt, this message translates to:
  /// **'{name}, {count, plural, =1{1 imagem} other{{count} imagens}}'**
  String imagesTabLabel(String name, int count);

  /// Button that opens the system image picker.
  ///
  /// In pt, this message translates to:
  /// **'Do meu dispositivo'**
  String get imagesFromDevice;

  /// Screen reader label of the From my device button.
  ///
  /// In pt, this message translates to:
  /// **'Escolher uma imagem do meu dispositivo'**
  String get imagesFromDeviceLabel;

  /// Footer button that removes the image.
  ///
  /// In pt, this message translates to:
  /// **'Sem imagem (usar cores)'**
  String get imagesNone;

  /// Screen reader label of the No image button.
  ///
  /// In pt, this message translates to:
  /// **'Usar cores em vez de uma imagem'**
  String get imagesNoneLabel;

  /// Empty state of My images.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não adicionou nenhuma imagem'**
  String get imagesMineEmpty;

  /// Web-only note below From my device.
  ///
  /// In pt, this message translates to:
  /// **'No navegador, suas imagens ficam salvas só neste navegador e somem se você limpar os dados do site.'**
  String get imagesWebStorageNote;

  /// Snackbar for a picked file that is not a usable image.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir esta imagem. Tente uma foto JPG ou PNG.'**
  String get imagesOpenError;

  /// Title of the dialog shown at the own image limit.
  ///
  /// In pt, this message translates to:
  /// **'Limite de imagens'**
  String get imagesLimitTitle;

  /// Body of the image limit dialog.
  ///
  /// In pt, this message translates to:
  /// **'Você já tem {max} imagens. Apague algumas em Minhas imagens para adicionar outras.'**
  String imagesLimitReached(int max);

  /// Button of the image limit dialog.
  ///
  /// In pt, this message translates to:
  /// **'Abrir Minhas imagens'**
  String get imagesLimitManage;

  /// Name of an own image that has no name.
  ///
  /// In pt, this message translates to:
  /// **'Minha imagem'**
  String get imagesOwnImage;

  /// Title of the framing screen.
  ///
  /// In pt, this message translates to:
  /// **'Enquadrar'**
  String get frameTitle;

  /// Saves the framed image.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get frameSave;

  /// Screen reader label of the framing area.
  ///
  /// In pt, this message translates to:
  /// **'Área de enquadramento. Arraste para mover, aperte com dois dedos para ampliar'**
  String get frameCanvasLabel;

  /// Label of the zoom slider.
  ///
  /// In pt, this message translates to:
  /// **'Zoom'**
  String get frameZoom;

  /// Zoom slider value, as a percentage.
  ///
  /// In pt, this message translates to:
  /// **'{percent}%'**
  String frameZoomValue(int percent);

  /// Button next to the zoom slider.
  ///
  /// In pt, this message translates to:
  /// **'Aumentar zoom'**
  String get frameZoomIn;

  /// Button next to the zoom slider.
  ///
  /// In pt, this message translates to:
  /// **'Diminuir zoom'**
  String get frameZoomOut;

  /// Resets the framing to centered, no zoom.
  ///
  /// In pt, this message translates to:
  /// **'Centralizar'**
  String get frameCenter;

  /// Optional name of the own image; also its screen reader label.
  ///
  /// In pt, this message translates to:
  /// **'Nome (opcional)'**
  String get frameName;

  /// Overlay while the image is processed.
  ///
  /// In pt, this message translates to:
  /// **'Preparando imagem…'**
  String get framePreparing;

  /// Snackbar when processing or storing the image fails.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar esta imagem. Tente outra foto.'**
  String get frameError;

  /// Title of My images (/images/mine).
  ///
  /// In pt, this message translates to:
  /// **'Minhas imagens'**
  String get mineTitle;

  /// How many own images there are, out of the limit.
  ///
  /// In pt, this message translates to:
  /// **'{count} de {max}'**
  String mineCount(int count, int max);

  /// Deletes an own image.
  ///
  /// In pt, this message translates to:
  /// **'Apagar'**
  String get mineDelete;

  /// Screen reader label of an image's delete button.
  ///
  /// In pt, this message translates to:
  /// **'Apagar {name}'**
  String mineDeleteLabel(String name);

  /// Title of the delete confirmation.
  ///
  /// In pt, this message translates to:
  /// **'Apagar imagem?'**
  String get mineDeleteTitle;

  /// Body of the delete confirmation.
  ///
  /// In pt, this message translates to:
  /// **'A imagem será apagada deste aparelho.'**
  String get mineDeleteConfirm;

  /// Added to the delete confirmation when presets use the image.
  ///
  /// In pt, this message translates to:
  /// **'Estes presets vão passar a usar cores: {names}.'**
  String mineAffectedPresets(String names);

  /// Added to the delete confirmation when the home timer or the defaults use the image.
  ///
  /// In pt, this message translates to:
  /// **'O timer da tela inicial também vai passar a usar cores.'**
  String get mineAffectedTimer;

  /// Menu item and dialog action that renames an own image.
  ///
  /// In pt, this message translates to:
  /// **'Renomear'**
  String get mineRename;

  /// Title of the rename dialog.
  ///
  /// In pt, this message translates to:
  /// **'Renomear imagem'**
  String get mineRenameTitle;

  /// Label of the name field in the rename dialog.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get mineNameField;

  /// Home chip naming the dial's image.
  ///
  /// In pt, this message translates to:
  /// **'Imagem: {name}'**
  String homeImageChip(String name);

  /// Screen reader label of the home image chip.
  ///
  /// In pt, this message translates to:
  /// **'Imagem: {name}. Toque para trocar'**
  String homeImageChipSemantics(String name);

  /// Home chip when the dial uses colors.
  ///
  /// In pt, this message translates to:
  /// **'Sem imagem'**
  String get homeNoImage;

  /// Screen reader label of the home image chip without an image.
  ///
  /// In pt, this message translates to:
  /// **'Sem imagem. Toque para escolher uma imagem'**
  String get homeNoImageSemantics;

  /// One-time snackbar when the chosen own image no longer exists.
  ///
  /// In pt, this message translates to:
  /// **'A imagem deste timer foi apagada, então ele vai usar cores.'**
  String get homeImageMissing;

  /// Library category.
  ///
  /// In pt, this message translates to:
  /// **'Animais'**
  String get imagesCategoryAnimals;
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
