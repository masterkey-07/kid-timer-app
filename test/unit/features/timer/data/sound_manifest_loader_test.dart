import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/domain/sound_id.dart';
import 'package:visual_time_counter/core/domain/sound_info.dart';
import 'package:visual_time_counter/features/timer/data/sound_manifest_loader.dart';

const _manifestPath = 'assets/sounds/manifest.json';
const _minimumAlarmSounds = 8;

String _manifest(List<Map<String, Object?>> sounds) =>
    jsonEncode({'schemaVersion': 1, 'sounds': sounds});

Map<String, Object?> _sound({
  String id = 'bell',
  String kind = 'alarm',
  Map<String, String>? names,
}) => {
  'id': id,
  'file': '$id.wav',
  'kind': kind,
  'names': names ?? {'pt': 'Sino', 'en': 'Bell'},
};

/// The sound list the picker shows (FR-052).
void main() {
  group('the committed manifest', () {
    final sounds = SoundManifestLoader.parse(
      File(_manifestPath).readAsStringSync(),
    );

    test('offers at least 8 alarm sounds', () {
      final alarms = sounds.where((sound) => sound.kind == SoundKind.alarm);

      expect(alarms.length, greaterThanOrEqualTo(_minimumAlarmSounds));
    });

    test('contains the default alarm and the tick', () {
      final ids = sounds.map((sound) => sound.id);

      expect(ids, containsAll([SoundId.chimeSoft, const SoundId('tick_soft')]));
    });

    test('names every sound in both languages', () {
      for (final sound in sounds) {
        expect(sound.names.keys, containsAll(['pt', 'en']), reason: '$sound');
      }
    });
  });

  group('parse', () {
    test('keeps the manifest order and decodes the fields', () {
      final sounds = SoundManifestLoader.parse(
        _manifest([_sound(), _sound(id: 'tick', kind: 'tick')]),
      );

      expect(sounds.map((sound) => sound.id.value), ['bell', 'tick']);
      expect(sounds.first.kind, SoundKind.alarm);
      expect(sounds.last.kind, SoundKind.tick);
    });

    test('rejects an unknown schema version', () {
      expect(
        () => SoundManifestLoader.parse(
          jsonEncode({'schemaVersion': 2, 'sounds': <Object>[]}),
        ),
        throwsFormatException,
      );
    });

    test('rejects an unknown kind', () {
      expect(
        () => SoundManifestLoader.parse(_manifest([_sound(kind: 'siren')])),
        throwsFormatException,
      );
    });

    test('rejects a sound without a name in a language', () {
      expect(
        () => SoundManifestLoader.parse(
          _manifest([
            _sound(names: {'en': 'Bell'}),
          ]),
        ),
        throwsFormatException,
      );
    });
  });

  group('SoundInfo.nameIn', () {
    final sound = SoundManifestLoader.parse(_manifest([_sound()])).single;

    test('uses the language when it has a name', () {
      expect(sound.nameIn('pt'), 'Sino');
    });

    test('falls back to English', () {
      expect(sound.nameIn('fr'), 'Bell');
    });
  });
}
