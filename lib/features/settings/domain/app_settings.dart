import 'package:meta/meta.dart';
import 'package:visual_time_counter/core/a11y/announce_throttle.dart';
import 'package:visual_time_counter/core/domain/json_utils.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';

/// The app theme preference; the language always follows the system.
enum AppThemeMode {
  /// Follow the system (default).
  system,

  /// Always light.
  light,

  /// Always dark.
  dark;

  /// Decodes the persisted name.
  factory fromJson(Object? json) => enumFromJson(values, json, 'themeMode');

  /// Encodes as the enum name.
  String toJson() => name;
}

/// Adult preferences stored in `settings["app"]` (data-model AppSettings).
@immutable
final class AppSettings {
  /// Creates settings.
  const new({
    this.themeMode = AppThemeMode.system,
    this.childLockEnabled = true,
    this.a11yAnnounceInterval = AnnounceInterval.oneMin,
    this.defaults = TimerConfig.defaults,
    this.lastConfig = TimerConfig.defaults,
    this.onboarding = OnboardingFlags.none,
  });

  /// Decodes a persisted document; throws a [FormatException] when it is
  /// invalid or from another schema version.
  factory fromJson(Map<String, Object?> json) {
    final version = json['schemaVersion'];
    if (version != schemaVersion) {
      throw FormatException('Unsupported AppSettings schema', version);
    }
    return AppSettings(
      themeMode: AppThemeMode.fromJson(json['themeMode']),
      childLockEnabled: readField<bool>(json, 'childLockEnabled'),
      a11yAnnounceInterval: AnnounceInterval.fromJson(
        json['a11yAnnounceInterval'],
      ),
      defaults: TimerConfig.fromJson(readObject(json, 'defaults')),
      lastConfig: TimerConfig.fromJson(readObject(json, 'lastConfig')),
      onboarding: OnboardingFlags.fromJson(readObject(json, 'onboarding')),
    );
  }

  /// The settings on first use.
  static const initial = AppSettings();

  /// The persisted document version.
  static const schemaVersion = 1;

  /// Theme preference.
  final AppThemeMode themeMode;

  /// Whether the countdown screen is locked for the child (FR-030).
  final bool childLockEnabled;

  /// How often screen readers hear the remaining time.
  final AnnounceInterval a11yAnnounceInterval;

  /// The configuration new timers start from.
  final TimerConfig defaults;

  /// The last configuration used on the home screen (FR-006).
  final TimerConfig lastConfig;

  /// One-time hints and notices already shown.
  final OnboardingFlags onboarding;

  /// A copy with the given fields replaced.
  AppSettings copyWith({
    AppThemeMode? themeMode,
    bool? childLockEnabled,
    AnnounceInterval? a11yAnnounceInterval,
    TimerConfig? defaults,
    TimerConfig? lastConfig,
    OnboardingFlags? onboarding,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    childLockEnabled: childLockEnabled ?? this.childLockEnabled,
    a11yAnnounceInterval: a11yAnnounceInterval ?? this.a11yAnnounceInterval,
    defaults: defaults ?? this.defaults,
    lastConfig: lastConfig ?? this.lastConfig,
    onboarding: onboarding ?? this.onboarding,
  );

  /// Encodes per contracts/persistence-schema.md.
  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'themeMode': themeMode.toJson(),
    'childLockEnabled': childLockEnabled,
    'a11yAnnounceInterval': a11yAnnounceInterval.toJson(),
    'defaults': defaults.toJson(),
    'lastConfig': lastConfig.toJson(),
    'onboarding': onboarding.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.themeMode == themeMode &&
      other.childLockEnabled == childLockEnabled &&
      other.a11yAnnounceInterval == a11yAnnounceInterval &&
      other.defaults == defaults &&
      other.lastConfig == lastConfig &&
      other.onboarding == onboarding;

  @override
  int get hashCode => Object.hash(
    themeMode,
    childLockEnabled,
    a11yAnnounceInterval,
    defaults,
    lastConfig,
    onboarding,
  );
}

/// One-time hints and notices the adult has already seen.
@immutable
final class OnboardingFlags {
  /// Creates flags.
  const new({
    this.exactAlarmExplained = false,
    this.iosSilentWarned = false,
    this.webKeepOpenSeen = false,
    this.examplesSeeded = false,
    this.dialHintDismissed = false,
  });

  /// Decodes the persisted map; missing flags are false, so new flags need
  /// no migration.
  factory fromJson(Map<String, Object?> json) {
    bool flag(String key) => json[key] == true;
    return OnboardingFlags(
      exactAlarmExplained: flag(_exactAlarmExplained),
      iosSilentWarned: flag(_iosSilentWarned),
      webKeepOpenSeen: flag(_webKeepOpenSeen),
      examplesSeeded: flag(_examplesSeeded),
      dialHintDismissed: flag(_dialHintDismissed),
    );
  }

  /// Nothing seen yet.
  static const none = OnboardingFlags();

  static const _exactAlarmExplained = 'exactAlarmExplained';
  static const _iosSilentWarned = 'iosSilentWarned';
  static const _webKeepOpenSeen = 'webKeepOpenSeen';
  static const _examplesSeeded = 'examplesSeeded';
  static const _dialHintDismissed = 'dialHintDismissed';

  /// The Android exact alarm explanation was shown.
  final bool exactAlarmExplained;

  /// The iOS silent mode warning was shown.
  final bool iosSilentWarned;

  /// The Web "keep the tab open" notice was shown.
  final bool webKeepOpenSeen;

  /// The example presets were created.
  final bool examplesSeeded;

  /// The first-use dial hint was dismissed.
  final bool dialHintDismissed;

  /// A copy with the given flags replaced.
  OnboardingFlags copyWith({
    bool? exactAlarmExplained,
    bool? iosSilentWarned,
    bool? webKeepOpenSeen,
    bool? examplesSeeded,
    bool? dialHintDismissed,
  }) => OnboardingFlags(
    exactAlarmExplained: exactAlarmExplained ?? this.exactAlarmExplained,
    iosSilentWarned: iosSilentWarned ?? this.iosSilentWarned,
    webKeepOpenSeen: webKeepOpenSeen ?? this.webKeepOpenSeen,
    examplesSeeded: examplesSeeded ?? this.examplesSeeded,
    dialHintDismissed: dialHintDismissed ?? this.dialHintDismissed,
  );

  /// Encodes as a map of flags.
  Map<String, bool> toJson() => {
    _exactAlarmExplained: exactAlarmExplained,
    _iosSilentWarned: iosSilentWarned,
    _webKeepOpenSeen: webKeepOpenSeen,
    _examplesSeeded: examplesSeeded,
    _dialHintDismissed: dialHintDismissed,
  };

  @override
  bool operator ==(Object other) =>
      other is OnboardingFlags &&
      other.exactAlarmExplained == exactAlarmExplained &&
      other.iosSilentWarned == iosSilentWarned &&
      other.webKeepOpenSeen == webKeepOpenSeen &&
      other.examplesSeeded == examplesSeeded &&
      other.dialHintDismissed == dialHintDismissed;

  @override
  int get hashCode => Object.hash(
    exactAlarmExplained,
    iosSilentWarned,
    webKeepOpenSeen,
    examplesSeeded,
    dialHintDismissed,
  );
}
