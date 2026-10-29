import 'package:meta/meta.dart';
import 'package:visual_time_counter/core/domain/json_utils.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';

/// A saved timer configuration with a name (data-model Preset, FR-040).
@immutable
final class Preset {
  /// Creates a preset with [name] trimmed; throws an [ArgumentError] when
  /// the name is not 1–40 characters after trimming or [order] is negative.
  factory({
    required String id,
    required String name,
    required int order,
    required TimerConfig config,
    required DateTime createdAt,
    required DateTime updatedAt,
    bool isExample = false,
    bool favorite = false,
  }) {
    if (!isValidName(name)) {
      throw ArgumentError.value(
        name,
        'name',
        'must be 1 to $maxNameLength characters after trimming',
      );
    }
    if (order < 0) throw ArgumentError.value(order, 'order', 'is negative');
    return Preset._(
      id: id,
      name: name.trim(),
      order: order,
      config: config,
      isExample: isExample,
      favorite: favorite,
      createdAt: createdAt.toUtc(),
      updatedAt: updatedAt.toUtc(),
    );
  }

  /// Decodes a persisted document; throws a [FormatException] when it is
  /// invalid or from another schema version.
  factory fromJson(Map<String, Object?> json) {
    final version = json['schemaVersion'];
    if (version != schemaVersion) {
      throw FormatException('Unsupported Preset schema', version);
    }
    final name = readField<String>(json, 'name');
    if (!isValidName(name)) throw FormatException('Invalid preset name', name);
    final order = readField<int>(json, 'order');
    if (order < 0) throw FormatException('Negative preset order', order);
    return Preset(
      id: readField<String>(json, 'id'),
      name: name,
      order: order,
      config: TimerConfig.fromJson(readObject(json, 'config')),
      isExample: readField<bool>(json, 'isExample'),
      favorite: readField<bool>(json, 'favorite'),
      createdAt: _readInstant(json, 'createdAt'),
      updatedAt: _readInstant(json, 'updatedAt'),
    );
  }

  const new _({
    required this.id,
    required this.name,
    required this.order,
    required this.config,
    required this.isExample,
    required this.favorite,
    required this.createdAt,
    required this.updatedAt,
  });

  /// The persisted document version.
  static const schemaVersion = 1;

  /// The longest name, in characters after trimming.
  static const maxNameLength = 40;

  /// The most presets the widget shows as favorites (v1.x).
  static const maxFavorites = 4;

  /// Whether [name] has 1–40 characters after trimming.
  static bool isValidName(String name) {
    final length = nameLength(name);
    return length > 0 && length <= maxNameLength;
  }

  /// The characters [name] counts after trimming; an emoji counts as one.
  static int nameLength(String name) => name.trim().runes.length;

  /// A stable local id (UUID).
  final String id;

  /// What the adult calls it; not necessarily unique.
  final String name;

  /// Its position in the list, 0..n-1.
  final int order;

  /// The timer it starts.
  final TimerConfig config;

  /// Whether it is one of the first-use examples.
  final bool isExample;

  /// Whether the home screen widget shows it (v1.x).
  final bool favorite;

  /// When it was created (UTC).
  final DateTime createdAt;

  /// When it last changed (UTC).
  final DateTime updatedAt;

  /// A copy with the given fields replaced.
  Preset copyWith({
    String? name,
    int? order,
    TimerConfig? config,
    bool? favorite,
    DateTime? updatedAt,
  }) => Preset(
    id: id,
    name: name ?? this.name,
    order: order ?? this.order,
    config: config ?? this.config,
    isExample: isExample,
    favorite: favorite ?? this.favorite,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Encodes per contracts/persistence-schema.md.
  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'id': id,
    'name': name,
    'order': order,
    'isExample': isExample,
    'favorite': favorite,
    'config': config.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is Preset &&
      other.id == id &&
      other.name == name &&
      other.order == order &&
      other.config == config &&
      other.isExample == isExample &&
      other.favorite == favorite &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    order,
    config,
    isExample,
    favorite,
    createdAt,
    updatedAt,
  );

  @override
  String toString() => 'Preset($id, $name, #$order)';

  static DateTime _readInstant(Map<String, Object?> json, String key) =>
      readOptionalInstant(json, key) ??
      (throw FormatException('Field "$key" is required'));
}

/// [presets] in their list order, numbered 0..n-1 with no gaps; presets
/// already in place are kept as they are.
List<Preset> renumbered(List<Preset> presets) => [
  for (final (index, preset) in presets.indexed)
    if (preset.order == index) preset else preset.copyWith(order: index),
];

/// Whether another preset can become a favorite (v1.x widget).
bool hasRoomForFavorite(Iterable<Preset> presets) =>
    presets.where((preset) => preset.favorite).length < Preset.maxFavorites;
