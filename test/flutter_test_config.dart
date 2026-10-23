import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _appFontFamily = 'AtkinsonHyperlegibleNext';

/// Font files loaded so platform goldens render the real app font.
const appFontAssets = [
  'assets/fonts/AtkinsonHyperlegibleNext/AtkinsonHyperlegibleNext-Regular.ttf',
  'assets/fonts/AtkinsonHyperlegibleNext/AtkinsonHyperlegibleNext-Bold.ttf',
];

/// Whether the tests run in CI (GitHub Actions sets `CI=true`).
bool get isRunningInCi => isRunningInCiFor(Platform.environment);

bool isRunningInCiFor(Map<String, String> environment) =>
    environment['CI'] == 'true';

/// Runs before every test file: CI goldens (text obscured, identical on every
/// host) always run; platform goldens with real fonts only run locally.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadAppFonts();

  await AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(enabled: !isRunningInCi),
    ),
    run: testMain,
  );
}

Future<void> _loadAppFonts() async {
  final loader = FontLoader(_appFontFamily);
  for (final asset in appFontAssets) {
    loader.addFont(rootBundle.load(asset));
  }
  await loader.load();
}
