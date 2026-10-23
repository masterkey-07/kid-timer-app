/// The id of a bundled sound, as listed in `assets/sounds/manifest.json`.
///
/// Sounds are data-driven, so this is a typed string instead of an enum.
extension type const SoundId(String value) {
  /// Decodes the persisted id.
  factory fromJson(Object? json) {
    if (json is! String || json.isEmpty) {
      throw FormatException('Invalid soundId: $json');
    }
    return SoundId(json);
  }

  /// No sound at the end.
  static const none = SoundId('none');

  /// The default alarm sound.
  static const chimeSoft = SoundId('chime_soft');

  /// Whether a sound plays.
  bool get isAudible => this != none;

  /// Encodes as the id string.
  String toJson() => value;
}
