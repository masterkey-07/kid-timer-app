import 'package:meta/meta.dart';
import 'package:visual_time_counter/core/domain/dial_scale.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/domain/timer_duration.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// A preset to create: a name and a configuration.
@immutable
final class PresetSeed {
  /// Creates the seed.
  const new({required this.name, required this.config});

  /// The preset name.
  final String name;

  /// The timer it starts.
  final TimerConfig config;
}

/// The first-use examples (FR-042): one per activity category of the
/// library, none for animals, named in the language of [l10n] when seeded.
List<PresetSeed> examplePresetSeeds(AppLocalizations l10n) => [
  _example(l10n.presetsExampleBrushTeeth, 'hygiene/brush_teeth', 2),
  _example(l10n.presetsExampleMeal, 'meal/meal', 20),
  _example(l10n.presetsExamplePlay, 'play/toys', 15),
  _example(l10n.presetsExampleQuietTime, 'rest/relax', 10),
  _example(l10n.presetsExampleHomework, 'school/homework', 25),
  _example(l10n.presetsExampleGoingOut, 'goingOut/put_on_shoes', 5),
];

PresetSeed _example(String name, String image, int minutes) {
  final duration = Duration(minutes: minutes);
  return PresetSeed(
    name: name,
    config: TimerConfig.defaults.copyWith(
      duration: TimerDuration(duration),
      scale: _smallestScaleFitting(duration),
      visual: BankImageSource('bank:$image'),
    ),
  );
}

/// The smallest dial scale that holds [duration], so a short example fills
/// a visible share of the setup dial.
DialScale _smallestScaleFitting(Duration duration) =>
    DialScale.values.firstWhere((scale) => scale.span >= duration);
