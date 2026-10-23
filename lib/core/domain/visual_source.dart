import 'package:meta/meta.dart';
import 'package:visual_time_counter/core/domain/color_token.dart';
import 'package:visual_time_counter/core/domain/json_utils.dart';
import 'package:visual_time_counter/core/domain/palette_id.dart';

/// What fills the dial: a color palette or an image.
@immutable
sealed class VisualSource {
  const new();

  /// Decodes a persisted visual source.
  factory fromJson(Map<String, Object?> json) {
    return switch (json['type']) {
      _paletteType => PaletteSource._fromJson(json),
      _bankType => BankImageSource(readField<String>(json, _imageIdKey)),
      _userType => UserImageSource(readField<String>(json, _imageIdKey)),
      final type => throw FormatException('Unknown visual type: $type'),
    };
  }

  /// The default source: the progressive palette.
  static final defaultSource = PaletteSource(paletteId: PaletteId.progressive);

  static const _paletteType = 'palette';
  static const _bankType = 'bank';
  static const _userType = 'user';
  static const _imageIdKey = 'imageId';

  /// Encodes this source.
  Map<String, Object?> toJson();
}

/// A dial colored by a palette.
final class PaletteSource extends VisualSource {
  /// Creates a palette source; [singleColor] is required for
  /// [PaletteId.single] and ignored for the other palettes.
  factory({required PaletteId paletteId, ColorToken? singleColor}) {
    if (paletteId == PaletteId.single && singleColor == null) {
      throw ArgumentError.notNull('singleColor');
    }
    return PaletteSource._(
      paletteId,
      paletteId == PaletteId.single ? singleColor : null,
    );
  }

  factory _fromJson(Map<String, Object?> json) {
    final paletteId = PaletteId.fromJson(json['paletteId']);
    final color = json['singleColor'];
    if (paletteId == PaletteId.single && color == null) {
      throw const FormatException('singleColor is required for "single"');
    }
    return PaletteSource(
      paletteId: paletteId,
      singleColor: color == null ? null : ColorToken.fromJson(color),
    );
  }

  const new _(this.paletteId, this.singleColor);

  /// The palette.
  final PaletteId paletteId;

  /// The color of the single palette; null for the other palettes.
  final ColorToken? singleColor;

  @override
  Map<String, Object?> toJson() => {
    'type': VisualSource._paletteType,
    'paletteId': paletteId.toJson(),
    'singleColor': singleColor?.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is PaletteSource &&
      other.paletteId == paletteId &&
      other.singleColor == singleColor;

  @override
  int get hashCode => Object.hash(paletteId, singleColor);

  @override
  String toString() => 'PaletteSource($paletteId, $singleColor)';
}

/// A dial showing an image from the built-in library.
final class BankImageSource extends VisualSource {
  /// Creates a source for the library image [imageId]
  /// (`bank:<category>/<slug>`).
  const new(this.imageId);

  /// The library image id.
  final String imageId;

  @override
  Map<String, Object?> toJson() => {
    'type': VisualSource._bankType,
    VisualSource._imageIdKey: imageId,
  };

  @override
  bool operator ==(Object other) =>
      other is BankImageSource && other.imageId == imageId;

  @override
  int get hashCode => Object.hash(BankImageSource, imageId);

  @override
  String toString() => 'BankImageSource($imageId)';
}

/// A dial showing an image the adult added from the device.
final class UserImageSource extends VisualSource {
  /// Creates a source for the own image [imageId] (UUID).
  const new(this.imageId);

  /// The own image id.
  final String imageId;

  @override
  Map<String, Object?> toJson() => {
    'type': VisualSource._userType,
    VisualSource._imageIdKey: imageId,
  };

  @override
  bool operator ==(Object other) =>
      other is UserImageSource && other.imageId == imageId;

  @override
  int get hashCode => Object.hash(UserImageSource, imageId);

  @override
  String toString() => 'UserImageSource($imageId)';
}
