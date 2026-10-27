import 'package:flutter/foundation.dart';
import 'package:patrol/patrol.dart';

/// How long Android takes to show its full screen hint after the app goes
/// immersive.
const _hintDelay = Duration(seconds: 2);

/// The hint's button on an English emulator (the CI and local emulators run
/// in English).
const _hintDismissText = 'Got it';

/// Dismisses Android's "Viewing full screen" hint, shown the first time an
/// install goes immersive. It covers the top of the screen, padlock
/// included, until dismissed.
Future<void> dismissFullScreenHint(PatrolIntegrationTester $) async {
  if (defaultTargetPlatform != TargetPlatform.android) return;
  await $.pump(_hintDelay);
  const hintButton = AndroidSelector(text: _hintDismissText);
  final hint = await $.platform.android.getNativeViews(hintButton);
  if (hint.roots.isEmpty) return;
  await $.platform.android.tap(hintButton);
  await $.pump();
}
