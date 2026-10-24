// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Kid Timer';

  @override
  String get noticeLearnMore => 'Saiba mais';

  @override
  String get noticeWarningLabel => 'Aviso';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get deepLinkPresetNotFound => 'Predefinição não encontrada';

  @override
  String get notificationTimerEndTitle => 'Acabou o tempo!';

  @override
  String get notificationTimerEndBody => 'Toque para abrir o Kid Timer.';

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count horas',
      one: '1 hora',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutos',
      one: '1 minuto',
    );
    return '$_temp0';
  }

  @override
  String durationSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count segundos',
      one: '1 segundo',
    );
    return '$_temp0';
  }

  @override
  String durationJoin(String first, String last) {
    return '$first e $last';
  }

  @override
  String get homeDurationLabel => 'Duração';

  @override
  String get homeStartButton => 'Iniciar';

  @override
  String homeStartSemantics(String duration) {
    return 'Iniciar timer de $duration';
  }

  @override
  String get homeMinus1 => '−1 min';

  @override
  String get homeMinus1Semantics => 'Diminuir 1 minuto';

  @override
  String get homePlus1 => '+1 min';

  @override
  String get homePlus1Semantics => 'Adicionar 1 minuto';

  @override
  String get homePlus5 => '+5 min';

  @override
  String get homePlus5Semantics => 'Adicionar 5 minutos';

  @override
  String get homeMaxReached => 'Máximo de 2 horas';

  @override
  String get homeStartFailed =>
      'Não foi possível salvar o timer. Libere espaço no aparelho e tente de novo.';

  @override
  String get homeDialHint =>
      'Arraste a borda do mostrador para escolher o tempo';

  @override
  String get homeDialHintDismiss => 'Entendi';

  @override
  String get homeReplaceTitle => 'Substituir o timer atual?';

  @override
  String get homeReplaceMessage =>
      'Só um timer pode rodar por vez. O timer atual será encerrado.';

  @override
  String get homeReplaceConfirm => 'Substituir';

  @override
  String get runRemainingLabel => 'Tempo restante';

  @override
  String get runPausedLabel => 'Pausado';

  @override
  String get runPause => 'Pausar';

  @override
  String get runPauseSemantics => 'Pausar timer';

  @override
  String get runResume => 'Continuar';

  @override
  String get runResumeSemantics => 'Continuar timer';

  @override
  String get runRestart => 'Reiniciar';

  @override
  String get runRestartSemantics => 'Reiniciar timer';

  @override
  String get runRestartConfirmTitle => 'Reiniciar o timer?';

  @override
  String get runRestartConfirmMessage => 'A contagem recomeça do início.';

  @override
  String get runStop => 'Parar';

  @override
  String get runStopSemantics => 'Parar timer';

  @override
  String get runStopConfirmTitle => 'Parar o timer?';

  @override
  String get runStopConfirmMessage => 'A contagem termina e nada vai tocar.';

  @override
  String get runActionFailed =>
      'Não foi possível salvar a alteração. Tente de novo.';

  @override
  String get finishedTitle => 'Acabou o tempo!';

  @override
  String get finishedTapToReturn => 'Toque na tela para voltar';

  @override
  String get finishedSemantics => 'Acabou o tempo. Toque para voltar';
}
