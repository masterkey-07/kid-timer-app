import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/app/theme/app_theme.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// Reference screen sizes per layout class (testing-strategy §2 rule 7).
enum ScreenClass {
  compact(Size(360, 800)),
  compactLandscape(Size(800, 360)),
  medium(Size(800, 1280)),
  expanded(Size(1440, 900));

  new(this.size);

  final Size size;
}

extension PumpApp on WidgetTester {
  /// Pumps [widget] inside a [ProviderScope] and a localized [MaterialApp]
  /// sized as [screen].
  Future<void> pumpApp(
    Widget widget, {
    List<Override> overrides = const [],
    Locale locale = const Locale('en'),
    ScreenClass screen = ScreenClass.compact,
    ThemeData? theme,
    double textScale = 1,
  }) async {
    view
      ..physicalSize = screen.size
      ..devicePixelRatio = 1;
    addTearDown(view.reset);

    await pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: theme ?? AppTheme.light(),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(body: widget),
        ),
      ),
    );
  }
}
