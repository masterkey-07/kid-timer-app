import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/app/theme/app_theme.dart';
import 'package:visual_time_counter/app/theme/tokens.dart';

import '../../../helpers/contrast.dart';

/// WCAG minimums per theme family (contracts/ui/00 §4, FR-055).
typedef _Minimums = ({double text, double component});

const ({double component, double text}) _regular = (text: 4.5, component: 3.0);
const ({double component, double text}) _highContrast = (
  text: 7.0,
  component: 4.5,
);

void main() {
  final themes = <String, (ThemeData, _Minimums)>{
    'light': (AppTheme.light(), _regular),
    'dark': (AppTheme.dark(), _regular),
    'high-contrast light': (AppTheme.highContrastLight(), _highContrast),
    'high-contrast dark': (AppTheme.highContrastDark(), _highContrast),
  };

  for (final MapEntry(key: name, value: (theme, minimums)) in themes.entries) {
    group(name, () {
      final colors = theme.colorScheme;

      test('primary text on the surface', () {
        expect(
          contrastRatio(colors.onSurface, colors.surface),
          greaterThanOrEqualTo(minimums.text),
        );
      });

      test('secondary text on the surface', () {
        expect(
          contrastRatio(colors.onSurfaceVariant, colors.surface),
          greaterThanOrEqualTo(minimums.text),
        );
      });

      test('text on primary buttons', () {
        expect(
          contrastRatio(colors.onPrimary, colors.primary),
          greaterThanOrEqualTo(minimums.text),
        );
      });

      test('primary components against the surface', () {
        expect(
          contrastRatio(colors.primary, colors.surface),
          greaterThanOrEqualTo(minimums.component),
        );
      });

      test('the dial outline against the surface', () {
        expect(
          contrastRatio(colors.outline, colors.surface),
          greaterThanOrEqualTo(minimums.component),
        );
      });

      test('primary text on every surface container', () {
        final containers = [
          colors.surfaceContainerLowest,
          colors.surfaceContainerLow,
          colors.surfaceContainer,
          colors.surfaceContainerHigh,
          colors.surfaceContainerHighest,
        ];
        for (final container in containers) {
          expect(
            contrastRatio(colors.primary, container),
            greaterThanOrEqualTo(minimums.text),
            reason: 'on $container',
          );
          expect(
            contrastRatio(colors.onSurface, container),
            greaterThanOrEqualTo(minimums.text),
            reason: 'on $container',
          );
        }
      });

      test('the scaffold uses the surface color', () {
        expect(theme.scaffoldBackgroundColor, colors.surface);
      });
    });
  }

  test('uses the base colors of contracts/ui/00 §4', () {
    expect(AppTheme.light().colorScheme.surface, const Color(0xFFFFFBF5));
    expect(AppTheme.light().colorScheme.onSurface, const Color(0xFF1C1B1F));
    expect(AppTheme.light().colorScheme.primary, const Color(0xFF3A6FD8));
    expect(AppTheme.dark().colorScheme.surface, const Color(0xFF14161A));
    expect(AppTheme.dark().colorScheme.onSurface, const Color(0xFFECEDEE));
    expect(AppTheme.dark().colorScheme.primary, const Color(0xFF8AB0FF));
    expect(
      AppTheme.highContrastLight().colorScheme.primary,
      const Color(0xFF0039A6),
    );
    expect(
      AppTheme.highContrastDark().colorScheme.surface,
      const Color(0xFF000000),
    );
  });

  test('themes use the app font and the right brightness', () {
    expect(
      AppTheme.light().textTheme.bodyLarge?.fontFamily,
      AppTokens.fontFamily,
    );
    expect(AppTheme.light().brightness, Brightness.light);
    expect(AppTheme.dark().brightness, Brightness.dark);
    expect(AppTheme.highContrastDark().brightness, Brightness.dark);
  });

  test('the type scale follows the tokens', () {
    final text = AppTheme.light().textTheme;

    expect(text.displayLarge?.fontSize, 56);
    expect(text.displayLarge?.height, 64 / 56);
    expect(text.titleLarge?.fontSize, 22);
    expect(text.bodyLarge?.fontSize, 16);
    expect(text.labelLarge?.fontSize, 14);
  });

  test('countdown digits use tabular figures', () {
    expect(
      AppTheme.light().textTheme.displayLarge?.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  test('primary buttons are at least 56 dp high with 28 dp corners', () {
    final style = AppTheme.light().filledButtonTheme.style!;

    expect(style.minimumSize?.resolve({})?.height, greaterThanOrEqualTo(56));
    expect(style.shape?.resolve({}), const StadiumBorder());
  });
}
