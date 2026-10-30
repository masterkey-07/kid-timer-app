import 'package:visual_time_counter/core/domain/color_token.dart';
import 'package:visual_time_counter/core/domain/dial_direction.dart';
import 'package:visual_time_counter/core/domain/palette_id.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// The localized name of [direction].
String directionName(AppLocalizations l10n, DialDirection direction) =>
    switch (direction) {
      DialDirection.clockwise => l10n.presetEditorClockwise,
      DialDirection.counterClockwise => l10n.presetEditorCounterClockwise,
    };

/// The localized name of [paletteId].
String paletteName(AppLocalizations l10n, PaletteId paletteId) =>
    switch (paletteId) {
      PaletteId.progressive => l10n.paletteProgressive,
      PaletteId.single => l10n.paletteSingle,
      PaletteId.calm => l10n.paletteCalm,
    };

/// The localized name of [token].
String colorName(AppLocalizations l10n, ColorToken token) => switch (token) {
  ColorToken.blue => l10n.colorBlue,
  ColorToken.green => l10n.colorGreen,
  ColorToken.yellow => l10n.colorYellow,
  ColorToken.orange => l10n.colorOrange,
  ColorToken.purple => l10n.colorPurple,
  ColorToken.pink => l10n.colorPink,
  ColorToken.teal => l10n.colorTeal,
  ColorToken.gray => l10n.colorGray,
};
