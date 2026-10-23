/// Hive box names (contracts/persistence-schema.md).
abstract final class BoxNames {
  /// AppSettings under the key `"app"`.
  static const settings = 'settings';

  /// Presets keyed by id.
  static const presets = 'presets';

  /// Routines keyed by id (v1.x).
  static const routines = 'routines';

  /// The active TimerSession (`"timer"`) and RoutineRun (`"routineRun"`).
  static const session = 'session';

  /// Own image metadata keyed by image id.
  static const userImagesMeta = 'user_images_meta';

  /// Own image JPEG bytes keyed by image id (a lazy box).
  static const userImages = 'user_images';

  /// The boxes holding versioned JSON documents.
  static const List<String> documentBoxes = [
    settings,
    presets,
    routines,
    session,
    userImagesMeta,
  ];
}
