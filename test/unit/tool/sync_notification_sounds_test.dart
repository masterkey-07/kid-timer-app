import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/sounds/sync_notification_sounds.dart';

const _targets = [
  'android/app/src/main/res/raw',
  'ios/Runner/Sounds',
  'macos/Runner/Sounds',
];

void main() {
  late Directory root;

  void writeSound(String file, List<int> bytes) =>
      File('${root.path}/assets/sounds/$file')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes);

  void writeManifest(List<String> ids) =>
      File('${root.path}/assets/sounds/manifest.json')
        ..createSync(recursive: true)
        ..writeAsStringSync(
          jsonEncode({
            'schemaVersion': 1,
            'sounds': [
              for (final id in ids)
                {'id': id, 'file': '$id.wav', 'kind': 'alarm'},
            ],
          }),
        );

  File target(String folder, String file) => File('${root.path}/$folder/$file');

  setUp(() {
    root = Directory.systemTemp.createTempSync('sounds_sync_');
    writeManifest(['chime_soft']);
    writeSound('chime_soft.wav', [1, 2, 3]);
  });
  tearDown(() => root.deleteSync(recursive: true));

  test('copies every manifest sound into the Android and Apple bundles', () {
    final problems = syncNotificationSounds(root);

    expect(problems, isEmpty);
    for (final folder in _targets) {
      expect(target(folder, 'chime_soft.wav').readAsBytesSync(), [1, 2, 3]);
    }
  });

  test('removes copies of sounds that left the manifest', () {
    for (final folder in _targets) {
      target(folder, 'old_bell.wav')
        ..createSync(recursive: true)
        ..writeAsBytesSync([9]);
    }

    syncNotificationSounds(root);

    for (final folder in _targets) {
      expect(target(folder, 'old_bell.wav').existsSync(), isFalse);
    }
  });

  test('never touches non-sound resources such as keep.xml', () {
    final keep = target(_targets.first, 'keep.xml')
      ..createSync(recursive: true)
      ..writeAsStringSync('<resources/>');

    syncNotificationSounds(root);

    expect(keep.readAsStringSync(), '<resources/>');
  });

  test('check mode reports missing and stale copies without writing', () {
    target(_targets.first, 'chime_soft.wav')
      ..createSync(recursive: true)
      ..writeAsBytesSync([0]);

    final problems = syncNotificationSounds(root, checkOnly: true);

    expect(
      problems,
      contains(
        contains('android/app/src/main/res/raw/chime_soft.wav: out of date'),
      ),
    );
    expect(
      problems,
      contains(contains('ios/Runner/Sounds/chime_soft.wav: missing')),
    );
    expect(target(_targets.first, 'chime_soft.wav').readAsBytesSync(), [0]);
  });

  test('check mode passes once synced', () {
    syncNotificationSounds(root);

    expect(syncNotificationSounds(root, checkOnly: true), isEmpty);
  });

  test('rejects ids that are not valid Android resource names', () {
    writeManifest(['Chime-Soft']);
    writeSound('Chime-Soft.wav', [1]);

    expect(syncNotificationSounds(root), [
      contains('Chime-Soft: not a valid Android resource name'),
    ]);
  });

  test('reports a sound file missing from assets', () {
    writeManifest(['chime_soft', 'rain']);

    expect(syncNotificationSounds(root), [contains('rain.wav: not found')]);
  });

  test('the exit code reflects the problems', () {
    final out = StringBuffer();

    expect(runSyncNotificationSounds(root, out, checkOnly: true), 1);
    expect(runSyncNotificationSounds(root, out), 0);
    expect(runSyncNotificationSounds(root, out, checkOnly: true), 0);
  });
}
