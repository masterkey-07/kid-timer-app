import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_time_counter/app/router.dart';
import 'package:visual_time_counter/app/widgets/platform_notice.dart';
import 'package:visual_time_counter/features/timer/application/background_alarm_notice.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// The `PlatformNotice` banner when the alarm is not guaranteed with the
/// app in the background (contracts/ui/08 §8.2); nothing otherwise.
class BackgroundAlarmBanner extends ConsumerWidget {
  /// Creates the banner.
  const new({super.key, this.padding = EdgeInsets.zero});

  /// Space around the banner when it shows.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notice = ref.watch(backgroundAlarmNoticeProvider).value;
    if (notice == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final (message, section) = switch (notice) {
      BackgroundAlarmNotice.keepAppOpen => (
        l10n.noticeBannerNoBackgroundAlarm,
        BatteryHelpSection.web,
      ),
      BackgroundAlarmNotice.notificationsOff => (
        l10n.noticeBannerNoBackgroundAlarm,
        BatteryHelpSection.alarms,
      ),
      BackgroundAlarmNotice.reducedAccuracy => (
        l10n.noticeBannerReducedAccuracy,
        BatteryHelpSection.alarms,
      ),
    };
    return Padding(
      padding: padding,
      child: PlatformNotice(
        message: message,
        onLearnMore: () => context.push(AppRoutes.batteryHelpAt(section)),
      ),
    );
  }
}
