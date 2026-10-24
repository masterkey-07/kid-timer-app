import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/core/domain/color_token.dart';
import 'package:visual_time_counter/core/domain/dial_direction.dart';
import 'package:visual_time_counter/core/domain/dial_scale.dart';
import 'package:visual_time_counter/core/domain/image_effect.dart';
import 'package:visual_time_counter/core/domain/palette_id.dart';
import 'package:visual_time_counter/core/domain/sound_id.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/domain/timer_duration.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';
import 'package:visual_time_counter/core/domain/warning_offsets.dart';

/// The TimerConfig example from contracts/persistence-schema.md.
const _schemaExample = <String, Object?>{
  'durationMs': 300000,
  'scale': 'min60',
  'direction': 'clockwise',
  'visual': {
    'type': 'palette',
    'paletteId': 'progressive',
    'singleColor': null,
  },
  'soundId': 'chime_soft',
  'alarmVolume': 0.7,
  'tickEnabled': false,
  'tickVolume': 0.3,
  'vibrate': true,
  'showDigits': true,
  'imageEffect': 'reveal',
  'warningsMin': <int>[],
};

void main() {
  group('defaults (data-model)', () {
    const config = TimerConfig.defaults;

    test('match the data model', () {
      expect(config.duration.value, const Duration(minutes: 5));
      expect(config.scale, DialScale.min60);
      expect(config.direction, DialDirection.clockwise);
      expect(config.visual, PaletteSource(paletteId: PaletteId.progressive));
      expect(config.soundId, SoundId.chimeSoft);
      expect(config.alarmVolume, 0.7);
      expect(config.tickEnabled, isFalse);
      expect(config.tickVolume, 0.3);
      expect(config.vibrate, isTrue);
      expect(config.showDigits, isTrue);
      expect(config.imageEffect, ImageEffect.reveal);
      expect(config.warnings, WarningOffsets.none);
    });

    test('a default-constructed config equals the defaults', () {
      expect(TimerConfig(), config);
    });
  });

  group('volumes', () {
    test('accept the 0.0–1.0 range', () {
      expect(TimerConfig(alarmVolume: 0, tickVolume: 1).alarmVolume, 0);
    });

    test('reject values outside 0.0–1.0', () {
      expect(() => TimerConfig(alarmVolume: 1.1), throwsArgumentError);
      expect(() => TimerConfig(tickVolume: -0.1), throwsArgumentError);
    });
  });

  group('copyWith', () {
    test('changes only the given fields', () {
      final changed = TimerConfig.defaults.copyWith(
        duration: TimerDuration(const Duration(minutes: 2)),
        scale: DialScale.min15,
        direction: DialDirection.counterClockwise,
        visual: const BankImageSource('bank:meal/plate'),
        soundId: const SoundId('bell'),
        alarmVolume: 0.5,
        tickEnabled: true,
        tickVolume: 0.1,
        vibrate: false,
        showDigits: false,
        imageEffect: ImageEffect.mosaic,
        warnings: WarningOffsets(const {1}),
      );

      expect(changed.duration.value, const Duration(minutes: 2));
      expect(changed.scale, DialScale.min15);
      expect(changed.direction, DialDirection.counterClockwise);
      expect(changed.visual, const BankImageSource('bank:meal/plate'));
      expect(changed.soundId, const SoundId('bell'));
      expect(changed.alarmVolume, 0.5);
      expect(changed.tickEnabled, isTrue);
      expect(changed.tickVolume, 0.1);
      expect(changed.vibrate, isFalse);
      expect(changed.showDigits, isFalse);
      expect(changed.imageEffect, ImageEffect.mosaic);
      expect(changed.warnings, WarningOffsets(const {1}));
    });

    test('without arguments returns an equal config', () {
      expect(TimerConfig.defaults.copyWith(), TimerConfig.defaults);
    });

    test('validates the new volumes', () {
      expect(
        () => TimerConfig.defaults.copyWith(alarmVolume: 2),
        throwsArgumentError,
      );
    });
  });

  group('equality', () {
    test('compares every field', () {
      expect(
        TimerConfig.defaults.copyWith(vibrate: false),
        isNot(TimerConfig.defaults),
      );
      expect(
        TimerConfig.defaults.copyWith(tickVolume: 0.3).hashCode,
        TimerConfig.defaults.hashCode,
      );
    });
  });

  group('JSON (contracts/persistence-schema.md)', () {
    test('encodes the defaults as the schema example', () {
      expect(TimerConfig.defaults.toJson(), _schemaExample);
    });

    test('decodes the schema example', () {
      expect(TimerConfig.fromJson(_schemaExample), TimerConfig.defaults);
    });

    test('round-trips a fully customized config', () {
      final config = TimerConfig(
        duration: TimerDuration(const Duration(minutes: 42)),
        scale: DialScale.min120,
        direction: DialDirection.counterClockwise,
        visual: PaletteSource(
          paletteId: PaletteId.single,
          singleColor: ColorToken.purple,
        ),
        soundId: SoundId.none,
        alarmVolume: 1,
        tickEnabled: true,
        tickVolume: 0,
        vibrate: false,
        showDigits: false,
        imageEffect: ImageEffect.puzzle9,
        warnings: WarningOffsets(const {2, 10}),
      );

      expect(TimerConfig.fromJson(config.toJson()), config);
    });

    test('accepts integer volumes', () {
      final json = {..._schemaExample, 'alarmVolume': 1, 'tickVolume': 0};

      expect(TimerConfig.fromJson(json).alarmVolume, 1.0);
    });

    test('rejects a missing field', () {
      final json = {..._schemaExample}..remove('scale');

      expect(() => TimerConfig.fromJson(json), throwsFormatException);
    });

    test('rejects a field with the wrong type', () {
      final json = {..._schemaExample, 'vibrate': 'yes'};

      expect(() => TimerConfig.fromJson(json), throwsFormatException);
    });

    test('rejects an out-of-range volume', () {
      final json = {..._schemaExample, 'alarmVolume': 3};

      expect(() => TimerConfig.fromJson(json), throwsFormatException);
    });
  });
}
