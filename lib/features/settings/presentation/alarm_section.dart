import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_time_counter/app/router.dart';
import 'package:visual_time_counter/core/platform/providers.dart';
import 'package:visual_time_counter/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:visual_time_counter/features/timer/application/background_alarm_notice.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// The "Alarm" section (contracts/ui/06 §6.1): whether the alarm can ring
/// with the app in the background, and a way to fix it on Android.
///
/// Keys: `settings.alarmStatus`, `settings.alarmFix`, `settings.alarmHelp`.
class AlarmSection extends ConsumerWidget {
  /// Creates the section.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notice = ref.watch(backgroundAlarmNoticeProvider);
    final isAndroid = ref.watch(appPlatformProvider) == AppPlatform.android;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionHeader(
          sectionKey: 'alarm',
          title: l10n.settingsSectionAlarm,
        ),
        if (notice.hasValue)
          ListTile(
            key: const Key('settings.alarmStatus'),
            leading: Icon(
              notice.value == null
                  ? Icons.check_circle_outline_rounded
                  : Icons.warning_amber_rounded,
            ),
            title: Text(_statusText(l10n, notice.value)),
          ),
        if (isAndroid && _fixFor(notice.value) != null)
          ListTile(
            key: const Key('settings.alarmFix'),
            title: Text(l10n.settingsAlarmFix),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () => unawaited(_fixFor(notice.value)!(ref)),
          ),
        ListTile(
          key: const Key('settings.alarmHelp'),
          title: Text(l10n.settingsAlarmHelp),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => unawaited(
            context.push<void>(
              AppRoutes.batteryHelpAt(BatteryHelpSection.alarms),
            ),
          ),
        ),
      ],
    );
  }

  static String _statusText(
    AppLocalizations l10n,
    BackgroundAlarmNotice? notice,
  ) => switch (notice) {
    null => l10n.settingsAlarmStatusOk,
    BackgroundAlarmNotice.keepAppOpen => l10n.settingsAlarmStatusKeepOpen,
    BackgroundAlarmNotice.notificationsOff =>
      l10n.settingsAlarmStatusNotificationsOff,
    BackgroundAlarmNotice.reducedAccuracy =>
      l10n.settingsAlarmStatusReducedAccuracy,
  };

  /// The system setting that fixes [notice]; null when the adult cannot.
  static Future<bool> Function(WidgetRef ref)? _fixFor(
    BackgroundAlarmNotice? notice,
  ) => switch (notice) {
    BackgroundAlarmNotice.notificationsOff => (
      ref,
    ) => ref.read(systemSettingsProvider).openAppNotificationSettings(),
    BackgroundAlarmNotice.reducedAccuracy => (
      ref,
    ) => ref.read(systemSettingsProvider).openExactAlarmSettings(),
    BackgroundAlarmNotice.keepAppOpen || null => null,
  };
}
