import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_time_counter/app/layout.dart';
import 'package:visual_time_counter/app/router.dart';
import 'package:visual_time_counter/core/a11y/announce_throttle.dart';
import 'package:visual_time_counter/features/images/application/my_images_controller.dart';
import 'package:visual_time_counter/features/settings/application/app_settings_state.dart';
import 'package:visual_time_counter/features/settings/application/settings_controller.dart';
import 'package:visual_time_counter/features/settings/presentation/alarm_section.dart';
import 'package:visual_time_counter/features/settings/presentation/appearance_section.dart';
import 'package:visual_time_counter/features/settings/presentation/child_mode_section.dart';
import 'package:visual_time_counter/features/settings/presentation/sound_section.dart';
import 'package:visual_time_counter/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// The adult's preferences (contracts/ui/06 §6.1). The "Data" and "About"
/// sections arrive with the stories that own their destinations.
class SettingsScreen extends StatelessWidget {
  /// Creates the screen.
  const new({super.key = const Key('settings.screen')});

  /// Content width per size class (contracts/ui/00 §3).
  static const _mediumMaxWidth = 600.0;
  static const _expandedMaxWidth = 720.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layout = ScreenLayout.of(constraints.biggest);
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: layout.margin),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: _maxWidth(layout)),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppearanceSection(),
                      SoundSection(),
                      ChildModeSection(),
                      AlarmSection(),
                      _AccessibilitySection(),
                      _ImagesSection(),
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

  static double _maxWidth(ScreenLayout layout) => switch (layout.sizeClass) {
    SizeClass.compact => double.infinity,
    SizeClass.medium => _mediumMaxWidth,
    SizeClass.expanded => _expandedMaxWidth,
  };
}

class _AccessibilitySection extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final interval = ref.watch(
      appSettingsProvider.select((settings) => settings.a11yAnnounceInterval),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionHeader(
          sectionKey: 'accessibility',
          title: l10n.settingsSectionAccessibility,
        ),
        SettingsDropdown<AnnounceInterval>(
          keyPrefix: 'settings.a11yInterval',
          label: l10n.settingsA11yInterval,
          values: AnnounceInterval.values,
          value: interval,
          labelOf: (option) => switch (option) {
            AnnounceInterval.oneMin => l10n.settingsA11yIntervalOneMin,
            AnnounceInterval.fiveMin => l10n.settingsA11yIntervalFiveMin,
            AnnounceInterval.off => l10n.settingsA11yIntervalOff,
          },
          onChanged: ref
              .read(settingsControllerProvider)
              .setA11yAnnounceInterval,
        ),
      ],
    );
  }
}

class _ImagesSection extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final count = ref.watch(
      userImagesProvider.select((images) => images.length),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionHeader(
          sectionKey: 'images',
          title: l10n.settingsSectionImages,
        ),
        ListTile(
          key: const Key('settings.myImages'),
          title: Text(l10n.settingsMyImages(count)),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => unawaited(context.push<void>(AppRoutes.imagesMine)),
        ),
      ],
    );
  }
}
