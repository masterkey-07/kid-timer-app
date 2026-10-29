import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/app/theme/palettes.dart';
import 'package:visual_time_counter/core/domain/palette_id.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';
import 'package:visual_time_counter/features/images/application/image_library.dart';
import 'package:visual_time_counter/features/images/application/my_images_controller.dart';
import 'package:visual_time_counter/features/images/domain/image_asset.dart';
import 'package:visual_time_counter/features/images/presentation/widgets/image_thumb.dart';

/// The image [visual] shows; null for colors, for an image that no longer
/// exists, and for a library image until the manifest loads.
ImageAsset? watchImageOf(WidgetRef ref, VisualSource visual) =>
    switch (visual) {
      PaletteSource() => null,
      BankImageSource(:final imageId) =>
        ref
            .watch(bankImagesProvider)
            .value
            ?.where((image) => image.id == imageId)
            .firstOrNull,
      UserImageSource(:final imageId) =>
        ref
            .watch(userImagesProvider)
            .where((image) => image.id == imageId)
            .firstOrNull,
    };

/// A circle showing what fills a preset's dial: its image, or the full-dial
/// color of its palette (also for an image that no longer exists).
class PresetThumb extends ConsumerWidget {
  /// Creates the thumbnail of [visual].
  const new({required this.visual, required this.size, super.key});

  /// What the dial shows.
  final VisualSource visual;

  /// The diameter.
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = watchImageOf(ref, visual);
    if (image != null) return ImageCircle(image: image, size: size);

    final palette = switch (visual) {
      final PaletteSource source => source,
      _ => _missingImagePalette,
    };
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: DialPalettes.colorAt(
            palette.paletteId,
            _fullDial,
            singleColor: palette.singleColor,
          ),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
      ),
    );
  }

  static const _fullDial = 1.0;
}

/// What the dial falls back to when its image is gone (FR-024).
final _missingImagePalette = PaletteSource(paletteId: PaletteId.progressive);
