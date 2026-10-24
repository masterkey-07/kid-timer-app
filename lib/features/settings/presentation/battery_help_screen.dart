import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/app/layout.dart';
import 'package:visual_time_counter/app/router.dart';
import 'package:visual_time_counter/core/platform/providers.dart';
import 'package:visual_time_counter/core/platform/system_settings/system_settings_port.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// Help: battery, alarms and screen pinning (contracts/ui/06 §6.2). A static
/// page whose sections are anchors; the Android buttons open the system
/// settings and are hidden elsewhere.
class BatteryHelpScreen extends ConsumerStatefulWidget {
  /// Creates the page, scrolled to [section] when given.
  const new({this.section, super.key = const Key('battery.screen')});

  /// The section to show first, from the route's `#anchor`.
  final BatteryHelpSection? section;

  @override
  ConsumerState<BatteryHelpScreen> createState() => _BatteryHelpScreenState();
}

class _BatteryHelpScreenState extends ConsumerState<BatteryHelpScreen> {
  /// Content width per size class (contracts/ui/00 §3).
  static const _mediumMaxWidth = 600.0;
  static const _expandedMaxWidth = 720.0;

  final Map<BatteryHelpSection, GlobalKey> _anchors = {
    for (final section in BatteryHelpSection.values) section: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    final section = widget.section;
    if (section != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(section));
    }
  }

  void _scrollTo(BatteryHelpSection section) {
    final anchor = _anchors[section]!.currentContext;
    if (anchor != null) Scrollable.ensureVisible(anchor);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final platform = ref.watch(appPlatformProvider);
    final settings = ref.read(systemSettingsProvider);
    final isAndroid = platform == AppPlatform.android;
    final isApple =
        platform == AppPlatform.ios || platform == AppPlatform.macos;

    final sections = {
      BatteryHelpSection.alarms: _HelpSection(
        title: l10n.batteryHelpAlarmsTitle,
        paragraphs: [
          l10n.batteryHelpAlarmsBody,
          if (isApple) l10n.batteryHelpAlarmsApple,
        ],
        buttons: [
          if (isAndroid) ...[
            _SettingsButton(
              key: const Key('battery.openExactAlarm'),
              label: l10n.batteryHelpOpenExactAlarm,
              open: settings.openExactAlarmSettings,
            ),
            _SettingsButton(
              key: const Key('battery.openNotifications'),
              label: l10n.batteryHelpOpenNotifications,
              open: settings.openAppNotificationSettings,
            ),
          ],
        ],
      ),
      BatteryHelpSection.battery: _HelpSection(
        title: l10n.batteryHelpBatteryTitle,
        paragraphs: [
          l10n.batteryHelpBatteryBody,
          l10n.batteryHelpBatterySamsung,
          l10n.batteryHelpBatteryXiaomi,
          l10n.batteryHelpBatteryMotorola,
          l10n.batteryHelpBatteryHuawei,
          l10n.batteryHelpBatteryOthers,
        ],
        buttons: [
          if (isAndroid)
            _SettingsButton(
              key: const Key('battery.openBatteryOptimization'),
              label: l10n.batteryHelpOpenBatteryOptimization,
              open: settings.openBatteryOptimizationSettings,
            ),
        ],
      ),
      BatteryHelpSection.pinning: _HelpSection(
        title: l10n.batteryHelpPinningTitle,
        paragraphs: [
          l10n.batteryHelpPinningAndroid,
          l10n.batteryHelpPinningApple,
          l10n.batteryHelpPinningDesktop,
        ],
      ),
      BatteryHelpSection.web: _HelpSection(
        title: l10n.batteryHelpWebTitle,
        paragraphs: [l10n.batteryHelpWebBody],
      ),
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.batteryHelpTitle)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layout = ScreenLayout.of(constraints.biggest);
            return SingleChildScrollView(
              padding: EdgeInsets.all(layout.margin),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: _maxWidth(layout)),
                  child: Column(
                    key: const Key('battery.content'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final MapEntry(key: section, value: content)
                          in sections.entries)
                        KeyedSubtree(
                          key: _anchors[section],
                          child: KeyedSubtree(
                            key: Key('battery.section.${section.name}'),
                            child: content,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  double _maxWidth(ScreenLayout layout) => switch (layout.sizeClass) {
    SizeClass.compact => double.infinity,
    SizeClass.medium => _mediumMaxWidth,
    SizeClass.expanded => _expandedMaxWidth,
  };
}

/// A titled block of paragraphs with optional buttons.
class _HelpSection extends StatelessWidget {
  const new({
    required this.title,
    required this.paragraphs,
    this.buttons = const [],
  });

  final String title;
  final List<String> paragraphs;
  final List<Widget> buttons;

  static const _gap = 12.0;
  static const _sectionGap = 32.0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: _sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: textTheme.titleLarge),
          ),
          for (final paragraph in paragraphs)
            Padding(
              padding: const EdgeInsets.only(top: _gap),
              child: Text(paragraph, style: textTheme.bodyLarge),
            ),
          for (final button in buttons)
            Padding(
              padding: const EdgeInsets.only(top: _gap),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: button,
              ),
            ),
        ],
      ),
    );
  }
}

/// Opens an Android settings screen through [SystemSettingsPort].
class _SettingsButton extends StatelessWidget {
  const new({required super.key, required this.label, required this.open});

  final String label;
  final Future<bool> Function() open;

  static const _minHeight = 56.0;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    style: FilledButton.styleFrom(minimumSize: const Size(0, _minHeight)),
    // A screen that cannot open leaves the adult on this page, which
    // already says where the setting is.
    onPressed: () => unawaited(open()),
    icon: const Icon(Icons.open_in_new_rounded),
    label: Text(label),
  );
}
