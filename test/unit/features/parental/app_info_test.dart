import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/features/parental/domain/app_info.dart';

final _pubspecVersion = RegExp(
  r'^version:\s*(\S+?)\+(\S+)\s*$',
  multiLine: true,
);

void main() {
  test('AppInfo matches the version in pubspec.yaml', () {
    final match = _pubspecVersion.firstMatch(
      File('pubspec.yaml').readAsStringSync(),
    )!;

    expect(AppInfo.version, match.group(1));
    expect(AppInfo.build, match.group(2));
  });

  test('links point to the project repository only', () {
    expect(AppInfo.sourceUrl, 'https://github.com/masterkey-07/kid-timer-app');
    expect(AppInfo.issuesUrl, startsWith('${AppInfo.sourceUrl}/issues'));
  });
}
