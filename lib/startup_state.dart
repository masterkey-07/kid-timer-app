import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:uuid/uuid.dart';
import 'package:visual_time_counter/app/router.dart';
import 'package:visual_time_counter/core/clock/clock_provider.dart';
import 'package:visual_time_counter/core/persistence/hive_bootstrap.dart';
import 'package:visual_time_counter/core/timer_engine/timer_engine.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/images/data/user_image_repository.dart';
import 'package:visual_time_counter/features/presets/data/preset_repository.dart';
import 'package:visual_time_counter/features/presets/data/preset_seeds.dart';
import 'package:visual_time_counter/features/settings/application/app_settings_state.dart';
import 'package:visual_time_counter/features/settings/data/settings_repository.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';
import 'package:visual_time_counter/features/timer/application/active_session.dart';
import 'package:visual_time_counter/features/timer/data/session_repository.dart';

/// Problems found while loading stored data; the app shows a one-time
/// notice for them (Edge Cases).
enum StartupIssue {
  /// A document could not be migrated; it was backed up.
  migrationFailed,

  /// The saved session was unreadable and was discarded.
  sessionUnreadable,

  /// The saved settings were unreadable; defaults are in use.
  settingsUnreadable,
}

/// Issues found at startup; bootstrap provides them.
final startupIssuesProvider = Provider<Set<StartupIssue>>((ref) => const {});

/// What the app starts with.
@immutable
final class StartupState {
  /// Creates the state.
  const new({
    required this.session,
    required this.settings,
    required this.issues,
    required this.overrides,
  });

  /// The restored (and reconciled) session, if any.
  final TimerSession? session;

  /// The restored settings.
  final AppSettings settings;

  /// Problems found while loading.
  final Set<StartupIssue> issues;

  /// Provider overrides carrying this state and the repositories.
  final List<Override> overrides;
}

/// Loads the session and settings from [boxes], reconciling a session whose
/// end passed while the app was closed (plan: Boot → load → reconcile →
/// route guard), removes own images a crash left half written and, on first
/// use, creates [examplePresets].
Future<StartupState> loadStartupState({
  required PersistenceBoxes boxes,
  required Clock clock,
  List<PresetSeed> examplePresets = const [],
}) async {
  final issues = <StartupIssue>{
    if (boxes.migrationFailures.isNotEmpty) StartupIssue.migrationFailed,
  };
  final sessionRepository = SessionRepository(boxes.session);
  final settingsRepository = SettingsRepository(boxes.settings);

  final session = await _restoreSession(
    sessionRepository,
    TimerEngine(clock: clock),
    issues,
  );
  var settings = _restoreSettings(settingsRepository, issues);
  await _seedExamplePresets(
    PresetRepository(
      presets: boxes.presets,
      readSettings: () => settings,
      updateSettings: (change) async {
        settings = change(settings);
        await settingsRepository.save(settings);
      },
      clock: clock,
      newId: const Uuid().v4,
    ),
    examplePresets,
  );
  await UserImageRepository.removeOrphans(
    meta: boxes.userImagesMeta,
    bytes: boxes.userImages,
  );

  return StartupState(
    session: session,
    settings: settings,
    issues: issues,
    overrides: [
      clockProvider.overrideWithValue(clock),
      sessionRepositoryProvider.overrideWithValue(sessionRepository),
      settingsRepositoryProvider.overrideWithValue(settingsRepository),
      restoredSessionProvider.overrideWithValue(session),
      restoredSettingsProvider.overrideWithValue(settings),
      presetStorageProvider.overrideWithValue(boxes.presets),
      presetExistsProvider.overrideWithValue(boxes.presets.containsKey),
      userImageStorageProvider.overrideWithValue(
        UserImageStorage(meta: boxes.userImagesMeta, bytes: boxes.userImages),
      ),
      startupIssuesProvider.overrideWithValue(Set.unmodifiable(issues)),
    ],
  );
}

Future<TimerSession?> _restoreSession(
  SessionRepository repository,
  TimerEngine engine,
  Set<StartupIssue> issues,
) async {
  final TimerSession? stored;
  try {
    stored = repository.load();
  } on FormatException catch (error) {
    debugPrint('Discarding unreadable session: $error');
    issues.add(StartupIssue.sessionUnreadable);
    await repository.clear();
    return null;
  }
  if (stored == null) return null;

  final reconciled = engine.reconcile(stored);
  if (reconciled != stored) await repository.save(reconciled);
  return reconciled;
}

/// The examples are a convenience, so failing to create them is logged and
/// the app starts anyway.
Future<void> _seedExamplePresets(
  PresetRepository presets,
  List<PresetSeed> seeds,
) async {
  if (seeds.isEmpty) return;
  try {
    await presets.seedExamples(seeds);
  } on Object catch (error) {
    debugPrint('Could not create the example presets: $error');
  }
}

AppSettings _restoreSettings(
  SettingsRepository repository,
  Set<StartupIssue> issues,
) {
  try {
    return repository.load();
  } on FormatException catch (error) {
    debugPrint('Using default settings; stored ones are unreadable: $error');
    issues.add(StartupIssue.settingsUnreadable);
    return AppSettings.initial;
  }
}
