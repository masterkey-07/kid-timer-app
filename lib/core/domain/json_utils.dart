/// Helpers for decoding the persisted JSON documents
/// (contracts/persistence-schema.md). Every decoding problem surfaces as a
/// [FormatException] so callers can fall back to defaults in one place.
library;

/// Returns the value of [values] whose name is [json].
///
/// Throws a [FormatException] naming [field] when there is no such value.
T enumFromJson<T extends Enum>(List<T> values, Object? json, String field) {
  for (final value in values) {
    if (value.name == json) return value;
  }
  throw FormatException('Invalid $field: $json');
}

/// Reads the required [key] of [json] as a [T].
///
/// Throws a [FormatException] when the key is missing or has another type.
T readField<T>(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is T) return value;
  throw FormatException('Field "$key" must be a $T, got ${value.runtimeType}');
}

/// Reads [key] of [json] as a JSON object.
Map<String, Object?> readObject(Map<String, Object?> json, String key) =>
    readField<Map<Object?, Object?>>(json, key).cast<String, Object?>();

/// Reads [key] of [json] as a [double], also accepting integers.
double readDouble(Map<String, Object?> json, String key) =>
    readField<num>(json, key).toDouble();

/// Reads the optional [key] of [json] as a UTC [DateTime].
DateTime? readOptionalInstant(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) {
    throw FormatException('Field "$key" must be an ISO-8601 string');
  }
  final instant = DateTime.tryParse(value);
  if (instant == null) {
    throw FormatException('Field "$key" is not an ISO-8601 instant: $value');
  }
  return instant.toUtc();
}
