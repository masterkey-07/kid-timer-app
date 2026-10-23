import 'package:flutter/material.dart';
import 'package:visual_time_counter/app/theme/tokens.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// A banner telling the adult that the alarm is not guaranteed in the
/// background (contracts/ui/08 §8.2). Never shown in child mode.
class PlatformNotice extends StatelessWidget {
  /// Creates the banner with a localized [message].
  const new({
    required this.message,
    required this.onLearnMore,
    super.key = const Key('notice.banner'),
  });

  static const _padding = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const _highContrastBorderWidth = 2.0;

  /// The notice text.
  final String message;

  /// Opens the related help page.
  final VoidCallback onLearnMore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final highContrast = MediaQuery.highContrastOf(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: highContrast
            ? colors.surface
            : (isLight
                  ? WarningColors.containerLight
                  : WarningColors.containerDark),
        borderRadius: BorderRadius.circular(AppTokens.cardRadius),
        border: highContrast
            ? Border.all(
                color: colors.onSurface,
                width: _highContrastBorderWidth,
              )
            : null,
      ),
      child: Padding(
        padding: _padding,
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              key: const Key('notice.banner.icon'),
              color: colors.onSurface,
              semanticLabel: l10n.noticeWarningLabel,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: textTheme.bodyLarge?.copyWith(color: colors.onSurface),
              ),
            ),
            TextButton(
              key: const Key('notice.banner.learnMore'),
              onPressed: onLearnMore,
              style: TextButton.styleFrom(foregroundColor: colors.onSurface),
              // Underlined text color: the theme primary is below 4.5:1 on
              // the amber container.
              child: Text(
                l10n.noticeLearnMore,
                style: const TextStyle(
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
