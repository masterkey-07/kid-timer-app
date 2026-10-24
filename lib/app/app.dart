import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/app/locale_resolution.dart';
import 'package:visual_time_counter/app/router.dart';
import 'package:visual_time_counter/app/shortcuts.dart';
import 'package:visual_time_counter/app/theme/app_theme.dart';
import 'package:visual_time_counter/features/settings/application/app_settings_state.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// The root widget: router, themes, localization and global shortcuts.
class KidTimerApp extends ConsumerWidget {
  /// Creates the app.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(
      appSettingsProvider.select((settings) => settings.themeMode),
    );
    return MaterialApp.router(
      routerConfig: ref.watch(routerProvider),
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      highContrastTheme: AppTheme.highContrastLight(),
      highContrastDarkTheme: AppTheme.highContrastDark(),
      themeMode: _toThemeMode(themeMode),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: (locales, _) => resolveAppLocale(locales),
      shortcuts: {...WidgetsApp.defaultShortcuts, ...appShortcuts},
    );
  }

  static ThemeMode _toThemeMode(AppThemeMode mode) => switch (mode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };
}
