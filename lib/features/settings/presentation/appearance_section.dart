import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/core/domain/color_token.dart';
import 'package:visual_time_counter/core/domain/dial_direction.dart';
import 'package:visual_time_counter/core/domain/dial_scale.dart';
import 'package:visual_time_counter/core/domain/palette_id.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/domain/timer_duration.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';
import 'package:visual_time_counter/features/settings/application/app_settings_state.dart';
import 'package:visual_time_counter/features/settings/application/settings_controller.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';
import 'package:visual_time_counter/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:visual_time_counter/features/timer/presentation/option_names.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// The "Appearance" section (contracts/ui/06 §6.1): theme and the defaults
/// new timers start from.
///
/// Keys: `settings.theme`, `settings.scale`, `settings.direction`,
/// `settings.palette`, `settings.color`, `settings.digits`.
class AppearanceSection extends ConsumerWidget {
  /// Creates the section.
  const new({super.key});

  static const ColorToken _defaultColor = ColorToken.blue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(appSettingsProvider);
    final defaults = settings.defaults;
    final controller = ref.read(settingsControllerProvider);
    final visual = defaults.visual is PaletteSource
        ? defaults.visual as PaletteSource
        : VisualSource.defaultSource as PaletteSource;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionHeader(
          sectionKey: 'appearance',
          title: l10n.settingsSectionAppearance,
        ),
        SettingsDropdown<AppThemeMode>(
          keyPrefix: 'settings.theme',
          label: l10n.settingsTheme,
          values: AppThemeMode.values,
          value: settings.themeMode,
          labelOf: (mode) => _themeName(l10n, mode),
          onChanged: controller.setThemeMode,
        ),
        SettingsDropdown<DialScale>(
          keyPrefix: 'settings.scale',
          label: l10n.presetEditorScale,
          values: DialScale.values,
          value: defaults.scale,
          labelOf: (scale) =>
              l10n.presetEditorScaleMinutes(scale.span.inMinutes),
          onChanged: (scale) =>
              controller.changeDefaults((config) => _withScale(config, scale)),
        ),
        SettingsDropdown<DialDirection>(
          keyPrefix: 'settings.direction',
          label: l10n.presetEditorDirection,
          values: DialDirection.values,
          value: defaults.direction,
          labelOf: (direction) => directionName(l10n, direction),
          onChanged: (direction) => controller.changeDefaults(
            (config) => config.copyWith(direction: direction),
          ),
        ),
        SettingsDropdown<PaletteId>(
          keyPrefix: 'settings.palette',
          label: l10n.presetEditorColors,
          values: PaletteId.values,
          value: visual.paletteId,
          labelOf: (palette) => paletteName(l10n, palette),
          onChanged: (palette) => controller.changeDefaults(
            (config) => config.copyWith(
              visual: PaletteSource(
                paletteId: palette,
                singleColor: visual.singleColor ?? _defaultColor,
              ),
            ),
          ),
        ),
        if (visual.paletteId == PaletteId.single)
          SettingsDropdown<ColorToken>(
            keyPrefix: 'settings.color',
            label: l10n.settingsColor,
            values: ColorToken.values,
            value: visual.singleColor ?? _defaultColor,
            labelOf: (token) => colorName(l10n, token),
            onChanged: (token) => controller.changeDefaults(
              (config) => config.copyWith(
                visual: PaletteSource(
                  paletteId: PaletteId.single,
                  singleColor: token,
                ),
              ),
            ),
          ),
        SwitchListTile(
          key: const Key('settings.digits'),
          title: Text(l10n.presetEditorDigits),
          value: defaults.showDigits,
          onChanged: (isOn) => controller.changeDefaults(
            (config) => config.copyWith(showDigits: isOn),
          ),
        ),
      ],
    );
  }

  /// A scale shorter than the duration clamps it (contracts/ui/01).
  static TimerConfig _withScale(TimerConfig config, DialScale scale) =>
      config.copyWith(
        scale: scale,
        duration: config.duration.value > scale.span
            ? TimerDuration(scale.span)
            : config.duration,
      );

  static String _themeName(AppLocalizations l10n, AppThemeMode mode) =>
      switch (mode) {
        AppThemeMode.system => l10n.settingsThemeSystem,
        AppThemeMode.light => l10n.settingsThemeLight,
        AppThemeMode.dark => l10n.settingsThemeDark,
      };
}
