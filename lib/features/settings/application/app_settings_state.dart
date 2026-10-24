import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';

/// The settings loaded from storage at startup; bootstrap overrides it.
final restoredSettingsProvider = Provider<AppSettings>(
  (ref) => AppSettings.initial,
);

/// The current settings. Seeded from storage; the settings controller (US6)
/// becomes its owner.
final appSettingsProvider = Provider<AppSettings>(
  (ref) => ref.watch(restoredSettingsProvider),
);
