import 'package:alchemist/alchemist.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../flutter_test_config.dart';

void main() {
  test('CI goldens are always enabled', () {
    expect(AlchemistConfig.current().ciGoldensConfig.enabled, isTrue);
  });

  test('platform goldens run only outside CI', () {
    expect(
      AlchemistConfig.current().platformGoldensConfig.enabled,
      !isRunningInCi,
    );
  });

  test('CI is detected from the CI environment variable', () {
    expect(isRunningInCiFor({'CI': 'true'}), isTrue);
    expect(isRunningInCiFor({}), isFalse);
  });

  test('the app font is bundled for platform goldens', () async {
    final font = await rootBundle.load(appFontAssets.first);

    expect(font.lengthInBytes, greaterThan(0));
  });
}
