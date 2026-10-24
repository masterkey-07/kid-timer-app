import 'package:alchemist/alchemist.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/app/theme/app_theme.dart';
import 'package:visual_time_counter/core/clock/clock_provider.dart';
import 'package:visual_time_counter/core/domain/dial_direction.dart';
import 'package:visual_time_counter/core/domain/palette_id.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/domain/timer_duration.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/timer/presentation/widgets/dial_view.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

final _now = DateTime.utc(2026, 10, 23, 12);
const _fullScale = Duration(minutes: 60);
const _remainingShares = [0.0, 0.25, 0.5, 1.0];
const _dialSize = 160.0;

/// A running 60 min timer on the 60 min scale with [share] of it left.
TimerSession _sessionWith({
  required double share,
  required PaletteId palette,
  required DialDirection direction,
}) => TimerSession(
  id: 'golden',
  config: TimerConfig(
    duration: TimerDuration(_fullScale),
    direction: direction,
    visual: PaletteSource(paletteId: palette),
  ),
  status: SessionStatus.running,
  startedAt: _now,
  endsAt: _now.add(_fullScale * share),
);

Widget _dial(TimerSession session, ThemeData theme) => Theme(
  data: theme,
  child: ColoredBox(
    color: theme.colorScheme.surface,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: SizedBox.square(
        dimension: _dialSize,
        child: DialView.countdown(session: session),
      ),
    ),
  ),
);

Future<void> main() async {
  final themes = {'light': AppTheme.light(), 'dark': AppTheme.dark()};

  for (final MapEntry(key: themeName, value: theme) in themes.entries) {
    await goldenTest(
      'dial at 0/25/50/100% per palette and direction ($themeName)',
      fileName: 'dial_view_$themeName',
      pumpBeforeTest: pumpOnce,
      builder: () => ProviderScope(
        overrides: [clockProvider.overrideWithValue(Clock.fixed(_now))],
        child: Localizations(
          locale: const Locale('en'),
          delegates: AppLocalizations.localizationsDelegates,
          child: GoldenTestGroup(
            columns: _remainingShares.length,
            children: [
              for (final palette in [PaletteId.progressive, PaletteId.calm])
                for (final direction in DialDirection.values)
                  for (final share in _remainingShares)
                    GoldenTestScenario(
                      name:
                          '${palette.name} ${direction.name} '
                          '${(share * 100).round()}%',
                      child: _dial(
                        _sessionWith(
                          share: share,
                          palette: palette,
                          direction: direction,
                        ),
                        theme,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
