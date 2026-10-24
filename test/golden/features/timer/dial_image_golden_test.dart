import 'dart:io';
import 'dart:typed_data';

import 'package:alchemist/alchemist.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/app/theme/app_theme.dart';
import 'package:visual_time_counter/core/clock/clock_provider.dart';
import 'package:visual_time_counter/core/domain/dial_direction.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/domain/timer_duration.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/images/application/decoded_image_cache.dart';
import 'package:visual_time_counter/features/timer/presentation/widgets/dial_view.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

final _now = DateTime.utc(2026, 10, 24, 12);
const _fullScale = Duration(minutes: 60);
const _remainingShares = [0.0, 0.25, 0.5, 1.0];
const _dialSize = 160.0;

const _bankImage = BankImageSource('bank:hygiene/brush_teeth');
const _missingImage = BankImageSource('bank:hygiene/missing');

/// Reads library images straight from the assets folder.
Future<Uint8List?> _loadFromAssets(VisualSource source) async {
  if (source is! BankImageSource) return null;
  final path = source.imageId.replaceFirst('bank:', '');
  final file = File('assets/images/bank/$path.webp');
  return file.existsSync() ? await file.readAsBytes() : null;
}

TimerSession _sessionWith({
  required double share,
  required VisualSource visual,
  required DialDirection direction,
}) => TimerSession(
  id: 'golden',
  config: TimerConfig(
    duration: TimerDuration(_fullScale),
    direction: direction,
    visual: visual,
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
  final cache = DecodedImageCache(loadBytes: _loadFromAssets);

  // Decoded before any dial is built (outside the widget tester's fake
  // clock, where decoding never completes), so every dial finds them cached.
  setUpAll(() async {
    for (final source in [_bankImage, _missingImage]) {
      final image = await cache.resolve(
        source,
        targetSize: DecodedImageCache.maxSize,
      );
      image?.dispose();
    }
  });
  tearDownAll(cache.dispose);

  for (final MapEntry(key: themeName, value: theme) in themes.entries) {
    await goldenTest(
      'dial with an image at 0/25/50/100% and the color fallback '
      '($themeName)',
      fileName: 'dial_image_$themeName',
      pumpBeforeTest: pumpOnce,
      builder: () => ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(Clock.fixed(_now)),
          decodedImageCacheProvider.overrideWithValue(cache),
        ],
        child: Localizations(
          locale: const Locale('en'),
          delegates: AppLocalizations.localizationsDelegates,
          child: GoldenTestGroup(
            columns: _remainingShares.length,
            children: [
              for (final direction in DialDirection.values)
                for (final share in _remainingShares)
                  GoldenTestScenario(
                    name: 'image ${direction.name} ${(share * 100).round()}%',
                    child: _dial(
                      _sessionWith(
                        share: share,
                        visual: _bankImage,
                        direction: direction,
                      ),
                      theme,
                    ),
                  ),
              for (final share in _remainingShares)
                GoldenTestScenario(
                  name: 'missing image ${(share * 100).round()}%',
                  child: _dial(
                    _sessionWith(
                      share: share,
                      visual: _missingImage,
                      direction: DialDirection.clockwise,
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
