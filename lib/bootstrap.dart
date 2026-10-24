import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest_10y.dart' as time_zones;
import 'package:visual_time_counter/app/locale_resolution.dart';
import 'package:visual_time_counter/core/persistence/hive_bootstrap.dart';
import 'package:visual_time_counter/core/platform/impl/platform_ports.dart';
import 'package:visual_time_counter/core/platform/providers.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';
import 'package:visual_time_counter/startup_state.dart';
import 'package:window_manager/window_manager.dart';

/// Prepares everything the app needs before `runApp` and returns the
/// provider overrides: platform ports, storage and the restored state.
Future<List<Override>> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  const clock = Clock();
  final platform = AppPlatform.resolve(
    isWeb: kIsWeb,
    target: defaultTargetPlatform,
  );

  time_zones.initializeTimeZones();
  if (_isDesktop(platform)) await windowManager.ensureInitialized();
  await _initStorage();

  final boxes = await openPersistence(clock: clock);
  final startup = await loadStartupState(boxes: boxes, clock: clock);
  final texts = lookupAppLocalizations(
    resolveAppLocale(WidgetsBinding.instance.platformDispatcher.locales),
  );
  final ports = await createPlatformPortOverrides(
    platform,
    clock: clock,
    alarmChannelNames: (
      timerEnd: texts.notificationChannelTimerEnd,
      warning: texts.notificationChannelWarning,
    ),
    imageFileTypeLabel: texts.imagesFileTypeLabel,
  );
  return [...ports, ...startup.overrides];
}

/// Hive files go to the app support directory (private, not the user's
/// Documents); the Web uses IndexedDB.
Future<void> _initStorage() async {
  if (kIsWeb) {
    await Hive.initFlutter();
    return;
  }
  final directory = await getApplicationSupportDirectory();
  await Hive.initFlutter(directory.path);
}

bool _isDesktop(AppPlatform platform) => switch (platform) {
  AppPlatform.windows || AppPlatform.macos || AppPlatform.linux => true,
  AppPlatform.android || AppPlatform.ios || AppPlatform.web => false,
};
