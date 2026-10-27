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
  String notificationTimerEndBody(String duration) {
    return 'Timer: $duration';
  }

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
  String get runUnlockHint => 'Segure por 3 segundos para mostrar os controles';

  @override
  String runRelockIn(int seconds) {
    return 'Bloqueia de novo em $seconds s';
  }

  @override
  String get settingsSectionChildMode => 'Modo criança';

  @override
  String get settingsChildLock => 'Bloqueio infantil';

  @override
  String get settingsChildLockDescription =>
      'Esconde os controles durante a contagem; segure o cadeado por 3 segundos para mostrá-los.';

  @override
  String get settingsChildLockOffConfirmTitle =>
      'Desativar o bloqueio infantil?';

  @override
  String get settingsChildLockOffConfirm =>
      'A criança vai poder pausar o timer.';

  @override
  String get settingsChildLockOffConfirmAction => 'Desativar';

  @override
  String get settingsChildLockPinning => 'Como manter a criança no app';

  @override
  String get finishedTitle => 'Acabou o tempo!';

  @override
  String get finishedTapToReturn => 'Toque na tela para voltar';

  @override
  String get finishedSemantics => 'Acabou o tempo. Toque para voltar';

  @override
  String get noticeKeepOpenTitle => 'Mantenha esta janela aberta';

  @override
  String get noticeKeepOpenBody =>
      'Aqui o alarme só toca com o Kid Timer aberto. Não feche a janela nem a aba até o tempo acabar.';

  @override
  String get noticeKeepOpenOk => 'Entendi';

  @override
  String get noticeNotificationsDeniedTitle =>
      'As notificações estão desligadas';

  @override
  String get noticeNotificationsDeniedBody =>
      'Sem notificações, o alarme só toca com o app aberto.';

  @override
  String get noticeOpenSettings => 'Abrir configurações';

  @override
  String get noticeContinueAnyway => 'Continuar mesmo assim';

  @override
  String get noticeExactAlarmTitle => 'Tocar na hora certa';

  @override
  String get noticeExactAlarmBody =>
      'Para tocar exatamente no fim, mesmo com a tela apagada, o Kid Timer precisa da permissão \"Alarmes e lembretes\". Sem ela, o alarme pode tocar alguns minutos depois quando o app estiver fechado.';

  @override
  String get noticeAllow => 'Permitir';

  @override
  String get noticeNotNow => 'Agora não';

  @override
  String get noticeIosSilentBody =>
      'No modo silencioso, o alarme não toca com o app fechado. Mantenha o som ligado.';

  @override
  String get noticeIosSilentOk => 'Entendi';

  @override
  String get noticeVolumeZero =>
      'O volume está no zero. Aumente para ouvir o alarme.';

  @override
  String get noticeBannerNoBackgroundAlarm =>
      'O alarme só toca com o app aberto.';

  @override
  String get noticeBannerReducedAccuracy =>
      'Com o app fechado, o alarme pode tocar alguns minutos depois.';

  @override
  String get notificationChannelTimerEnd => 'Fim do timer';

  @override
  String get notificationChannelWarning => 'Avisos';

  @override
  String get batteryHelpTitle => 'Bateria, alarmes e fixação';

  @override
  String get batteryHelpAlarmsTitle => 'Alarmes na hora certa';

  @override
  String get batteryHelpAlarmsBody =>
      'O Kid Timer pede ao sistema para tocar no fim do timer, mesmo com o app fechado ou a tela bloqueada. Para isso ele precisa da permissão de notificações e, no Android, da permissão \"Alarmes e lembretes\".';

  @override
  String get batteryHelpAlarmsApple =>
      'No iPhone, iPad e Mac: Ajustes › Notificações › Kid Timer › ative Permitir Notificações e Sensível ao Tempo.';

  @override
  String get batteryHelpOpenExactAlarm => 'Abrir alarmes e lembretes';

  @override
  String get batteryHelpOpenNotifications =>
      'Abrir configurações de notificação';

  @override
  String get batteryHelpBatteryTitle => 'Otimização de bateria';

  @override
  String get batteryHelpBatteryBody =>
      'Alguns celulares fecham apps em segundo plano para poupar bateria, o que pode atrasar o alarme. Deixe o Kid Timer rodar sem restrições:';

  @override
  String get batteryHelpBatterySamsung =>
      'Samsung: Configurações › Aplicativos › Kid Timer › Bateria › Sem restrições.';

  @override
  String get batteryHelpBatteryXiaomi =>
      'Xiaomi, Redmi, POCO: Configurações › Apps › Gerenciar apps › Kid Timer › Economia de bateria › Sem restrições, e ative a Inicialização automática.';

  @override
  String get batteryHelpBatteryMotorola =>
      'Motorola: Configurações › Apps › Kid Timer › Uso da bateria pelo app › Sem restrições.';

  @override
  String get batteryHelpBatteryHuawei =>
      'Huawei: Configurações › Bateria › Inicialização de apps › Kid Timer › Gerenciar manualmente, com Inicialização automática e Executar em segundo plano ativados.';

  @override
  String get batteryHelpBatteryOthers =>
      'Outros: Configurações › Apps › Kid Timer › Bateria › Sem restrições (ou Não otimizar).';

  @override
  String get batteryHelpOpenBatteryOptimization =>
      'Abrir otimização de bateria';

  @override
  String get batteryHelpPinningTitle => 'Manter a criança no app';

  @override
  String get batteryHelpPinningAndroid =>
      'Android: ative Configurações › Segurança › Fixar app e depois fixe o Kid Timer na tela de apps recentes.';

  @override
  String get batteryHelpPinningApple =>
      'iPhone e iPad: ative Ajustes › Acessibilidade › Acesso Guiado e depois clique três vezes no botão lateral dentro do Kid Timer.';

  @override
  String get batteryHelpPinningDesktop =>
      'Computadores: use a tela cheia com o bloqueio infantil ativado.';

  @override
  String get batteryHelpWebTitle => 'Por que manter a janela aberta';

  @override
  String get batteryHelpWebBody =>
      'Navegadores e o Linux não deixam apps agendarem alarmes no sistema. O próprio Kid Timer toca o alarme, então ele só toca com a janela ou a aba aberta e o computador ligado.';

  @override
  String get imagesFileTypeLabel => 'Imagens';

  @override
  String get imagesTitle => 'Escolher imagem';

  @override
  String get imagesManage => 'Gerenciar';

  @override
  String get imagesManageLabel => 'Gerenciar minhas imagens';

  @override
  String get imagesTabAll => 'Todas';

  @override
  String get imagesCategoryHygiene => 'Higiene';

  @override
  String get imagesCategoryMeal => 'Refeições';

  @override
  String get imagesCategoryPlay => 'Brincar';

  @override
  String get imagesCategoryRest => 'Descanso';

  @override
  String get imagesCategorySchool => 'Escola';

  @override
  String get imagesCategoryGoingOut => 'Passeio';

  @override
  String get imagesTabMine => 'Minhas imagens';

  @override
  String imagesTabLabel(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count imagens',
      one: '1 imagem',
    );
    return '$name, $_temp0';
  }

  @override
  String get imagesFromDevice => 'Do meu dispositivo';

  @override
  String get imagesFromDeviceLabel => 'Escolher uma imagem do meu dispositivo';

  @override
  String get imagesNone => 'Sem imagem (usar cores)';

  @override
  String get imagesNoneLabel => 'Usar cores em vez de uma imagem';

  @override
  String get imagesMineEmpty => 'Você ainda não adicionou nenhuma imagem';

  @override
  String get imagesWebStorageNote =>
      'No navegador, suas imagens ficam salvas só neste navegador e somem se você limpar os dados do site.';

  @override
  String get imagesOpenError =>
      'Não foi possível abrir esta imagem. Tente uma foto JPG ou PNG.';

  @override
  String get imagesLimitTitle => 'Limite de imagens';

  @override
  String imagesLimitReached(int max) {
    return 'Você já tem $max imagens. Apague algumas em Minhas imagens para adicionar outras.';
  }

  @override
  String get imagesLimitManage => 'Abrir Minhas imagens';

  @override
  String get imagesOwnImage => 'Minha imagem';

  @override
  String get frameTitle => 'Enquadrar';

  @override
  String get frameSave => 'Salvar';

  @override
  String get frameCanvasLabel =>
      'Área de enquadramento. Arraste para mover, aperte com dois dedos para ampliar';

  @override
  String get frameZoom => 'Zoom';

  @override
  String frameZoomValue(int percent) {
    return '$percent%';
  }

  @override
  String get frameZoomIn => 'Aumentar zoom';

  @override
  String get frameZoomOut => 'Diminuir zoom';

  @override
  String get frameCenter => 'Centralizar';

  @override
  String get frameName => 'Nome (opcional)';

  @override
  String get framePreparing => 'Preparando imagem…';

  @override
  String get frameError =>
      'Não foi possível salvar esta imagem. Tente outra foto.';

  @override
  String get mineTitle => 'Minhas imagens';

  @override
  String mineCount(int count, int max) {
    return '$count de $max';
  }

  @override
  String get mineDelete => 'Apagar';

  @override
  String mineDeleteLabel(String name) {
    return 'Apagar $name';
  }

  @override
  String get mineDeleteTitle => 'Apagar imagem?';

  @override
  String get mineDeleteConfirm => 'A imagem será apagada deste aparelho.';

  @override
  String mineAffectedPresets(String names) {
    return 'Estes presets vão passar a usar cores: $names.';
  }

  @override
  String get mineAffectedTimer =>
      'O timer da tela inicial também vai passar a usar cores.';

  @override
  String get mineRename => 'Renomear';

  @override
  String get mineRenameTitle => 'Renomear imagem';

  @override
  String get mineNameField => 'Nome';

  @override
  String homeImageChip(String name) {
    return 'Imagem: $name';
  }

  @override
  String homeImageChipSemantics(String name) {
    return 'Imagem: $name. Toque para trocar';
  }

  @override
  String get homeNoImage => 'Sem imagem';

  @override
  String get homeNoImageSemantics =>
      'Sem imagem. Toque para escolher uma imagem';

  @override
  String get homeImageMissing =>
      'A imagem deste timer foi apagada, então ele vai usar cores.';

  @override
  String get imagesCategoryAnimals => 'Animais';
}
