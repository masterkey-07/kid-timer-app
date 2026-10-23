import 'package:meta/meta.dart';
import 'package:visual_time_counter/core/domain/dial_direction.dart';
import 'package:visual_time_counter/core/domain/dial_scale.dart';
import 'package:visual_time_counter/core/domain/image_effect.dart';
import 'package:visual_time_counter/core/domain/json_utils.dart';
import 'package:visual_time_counter/core/domain/sound_id.dart';
import 'package:visual_time_counter/core/domain/timer_duration.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';
import 'package:visual_time_counter/core/domain/warning_offsets.dart';

/// The full configuration of a timer, shared by sessions, presets and
/// routine steps (data-model TimerConfig).
@immutable
final class TimerConfig {
  /// Creates a config; throws an [ArgumentError] when a volume is outside
  /// 0.0–1.0.
  factory({
    TimerDuration duration = TimerDuration.defaultValue,
    DialScale scale = DialScale.defaultScale,
    DialDirection direction = DialDirection.clockwise,
    VisualSource visual = VisualSource.defaultSource,
    SoundId soundId = SoundId.chimeSoft,
    double alarmVolume = _defaultAlarmVolume,
    bool tickEnabled = false,
    double tickVolume = _defaultTickVolume,
    bool vibrate = true,
    bool showDigits = true,
    ImageEffect imageEffect = ImageEffect.vanish,
    WarningOffsets warnings = WarningOffsets.none,
  }) {
    _checkVolume(alarmVolume, 'alarmVolume');
    _checkVolume(tickVolume, 'tickVolume');
    return TimerConfig._(
      duration: duration,
      scale: scale,
      direction: direction,
      visual: visual,
      soundId: soundId,
      alarmVolume: alarmVolume,
      tickEnabled: tickEnabled,
      tickVolume: tickVolume,
      vibrate: vibrate,
      showDigits: showDigits,
      imageEffect: imageEffect,
      warnings: warnings,
    );
  }

  /// Decodes a persisted config; throws a [FormatException] when a field is
  /// missing or invalid.
  factory fromJson(Map<String, Object?> json) => TimerConfig(
    duration: TimerDuration.fromJson(json['durationMs']),
    scale: DialScale.fromJson(json['scale']),
    direction: DialDirection.fromJson(json['direction']),
    visual: VisualSource.fromJson(readObject(json, 'visual')),
    soundId: SoundId.fromJson(json['soundId']),
    alarmVolume: _readVolume(json, 'alarmVolume'),
    tickEnabled: readField<bool>(json, 'tickEnabled'),
    tickVolume: _readVolume(json, 'tickVolume'),
    vibrate: readField<bool>(json, 'vibrate'),
    showDigits: readField<bool>(json, 'showDigits'),
    imageEffect: ImageEffect.fromJson(json['imageEffect']),
    warnings: WarningOffsets.fromJson(json['warningsMin']),
  );

  const new _({
    required this.duration,
    required this.scale,
    required this.direction,
    required this.visual,
    required this.soundId,
    required this.alarmVolume,
    required this.tickEnabled,
    required this.tickVolume,
    required this.vibrate,
    required this.showDigits,
    required this.imageEffect,
    required this.warnings,
  });

  /// The default configuration (data-model defaults).
  static const defaults = TimerConfig._(
    duration: TimerDuration.defaultValue,
    scale: DialScale.defaultScale,
    direction: DialDirection.clockwise,
    visual: VisualSource.defaultSource,
    soundId: SoundId.chimeSoft,
    alarmVolume: _defaultAlarmVolume,
    tickEnabled: false,
    tickVolume: _defaultTickVolume,
    vibrate: true,
    showDigits: true,
    imageEffect: ImageEffect.vanish,
    warnings: WarningOffsets.none,
  );

  static const _defaultAlarmVolume = 0.7;
  static const _defaultTickVolume = 0.3;

  /// How long the timer runs.
  final TimerDuration duration;

  /// The time span of a full dial.
  final DialScale scale;

  /// The direction in which the dial shrinks.
  final DialDirection direction;

  /// What fills the dial.
  final VisualSource visual;

  /// The sound played at the end.
  final SoundId soundId;

  /// Alarm volume, 0.0–1.0.
  final double alarmVolume;

  /// Whether a tick plays every second while the app is open.
  final bool tickEnabled;

  /// Tick volume, 0.0–1.0.
  final double tickVolume;

  /// Whether to vibrate at the end (ignored without a vibrator).
  final bool vibrate;

  /// Whether to show the remaining time as digits.
  final bool showDigits;

  /// How an image on the dial changes (v1.x).
  final ImageEffect imageEffect;

  /// Warnings before the end (v1.x).
  final WarningOffsets warnings;

  /// A copy with the given fields replaced.
  TimerConfig copyWith({
    TimerDuration? duration,
    DialScale? scale,
    DialDirection? direction,
    VisualSource? visual,
    SoundId? soundId,
    double? alarmVolume,
    bool? tickEnabled,
    double? tickVolume,
    bool? vibrate,
    bool? showDigits,
    ImageEffect? imageEffect,
    WarningOffsets? warnings,
  }) => TimerConfig(
    duration: duration ?? this.duration,
    scale: scale ?? this.scale,
    direction: direction ?? this.direction,
    visual: visual ?? this.visual,
    soundId: soundId ?? this.soundId,
    alarmVolume: alarmVolume ?? this.alarmVolume,
    tickEnabled: tickEnabled ?? this.tickEnabled,
    tickVolume: tickVolume ?? this.tickVolume,
    vibrate: vibrate ?? this.vibrate,
    showDigits: showDigits ?? this.showDigits,
    imageEffect: imageEffect ?? this.imageEffect,
    warnings: warnings ?? this.warnings,
  );

  /// Encodes per contracts/persistence-schema.md.
  Map<String, Object?> toJson() => {
    'durationMs': duration.toJson(),
    'scale': scale.toJson(),
    'direction': direction.toJson(),
    'visual': visual.toJson(),
    'soundId': soundId.toJson(),
    'alarmVolume': alarmVolume,
    'tickEnabled': tickEnabled,
    'tickVolume': tickVolume,
    'vibrate': vibrate,
    'showDigits': showDigits,
    'imageEffect': imageEffect.toJson(),
    'warningsMin': warnings.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is TimerConfig &&
      other.duration == duration &&
      other.scale == scale &&
      other.direction == direction &&
      other.visual == visual &&
      other.soundId == soundId &&
      other.alarmVolume == alarmVolume &&
      other.tickEnabled == tickEnabled &&
      other.tickVolume == tickVolume &&
      other.vibrate == vibrate &&
      other.showDigits == showDigits &&
      other.imageEffect == imageEffect &&
      other.warnings == warnings;

  @override
  int get hashCode => Object.hash(
    duration,
    scale,
    direction,
    visual,
    soundId,
    alarmVolume,
    tickEnabled,
    tickVolume,
    vibrate,
    showDigits,
    imageEffect,
    warnings,
  );

  @override
  String toString() => 'TimerConfig(${toJson()})';

  static bool _isValidVolume(double volume) => volume >= 0 && volume <= 1;

  static void _checkVolume(double volume, String name) {
    if (!_isValidVolume(volume)) {
      throw ArgumentError.value(volume, name, 'must be between 0.0 and 1.0');
    }
  }

  static double _readVolume(Map<String, Object?> json, String key) {
    final volume = readDouble(json, key);
    if (!_isValidVolume(volume)) {
      throw FormatException('$key must be between 0.0 and 1.0', volume);
    }
    return volume;
  }
}
