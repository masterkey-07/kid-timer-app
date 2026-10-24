import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_time_counter/app/router.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';
import 'package:visual_time_counter/features/images/application/image_library.dart';
import 'package:visual_time_counter/features/images/application/my_images_controller.dart';
import 'package:visual_time_counter/features/images/domain/image_asset.dart';
import 'package:visual_time_counter/features/images/presentation/widgets/image_thumb.dart';
import 'package:visual_time_counter/features/timer/application/setup_config_controller.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// The home chip naming the dial's image (contracts/ui/01): opens the
/// picker, and ✕ goes back to colors. An own image deleted since it was
/// chosen falls back to colors once, with a notice.
class ImageChip extends ConsumerStatefulWidget {
  /// Creates the chip for the setup's current visual.
  const new({super.key});

  @override
  ConsumerState<ImageChip> createState() => _ImageChipState();
}

class _ImageChipState extends ConsumerState<ImageChip> {
  static const _avatarSize = 24.0;

  bool _isReplacingMissing = false;

  /// The chosen image; null for colors, and for an image that no longer
  /// exists once the library has loaded.
  ImageAsset? _imageFor(VisualSource visual) {
    final library = ref.watch(bankImagesProvider).value;
    final own = ref.watch(userImagesProvider);
    return switch (visual) {
      PaletteSource() => null,
      BankImageSource(:final imageId) =>
        library?.where((image) => image.id == imageId).firstOrNull,
      UserImageSource(:final imageId) =>
        own.where((image) => image.id == imageId).firstOrNull,
    };
  }

  bool _isMissing(VisualSource visual, ImageAsset? image) => switch (visual) {
    PaletteSource() => false,
    // Until the manifest loads, a library image is not known to be missing.
    BankImageSource() =>
      ref.watch(bankImagesProvider).hasValue && image == null,
    UserImageSource() => image == null,
  };

  void _replaceMissing() {
    if (_isReplacingMissing) return;
    _isReplacingMissing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isReplacingMissing = false;
      if (!mounted) return;
      _setVisual(VisualSource.defaultSource);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const Key('home.imageMissing'),
          content: Text(AppLocalizations.of(context).homeImageMissing),
        ),
      );
    });
  }

  Future<void> _choose(VisualSource current) async {
    final chosen = await context.push<VisualSource>(
      AppRoutes.images,
      extra: current,
    );
    if (chosen == null || !mounted) return;
    _setVisual(chosen);
  }

  void _setVisual(VisualSource visual) => ref
      .read(setupConfigProvider.notifier)
      .change(ref.read(setupConfigProvider).copyWith(visual: visual));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visual = ref.watch(setupConfigProvider.select((c) => c.visual));
    final image = _imageFor(visual);
    if (_isMissing(visual, image)) _replaceMissing();

    final name = image == null ? null : imageLabel(context, image);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Semantics(
            label: name == null
                ? l10n.homeNoImageSemantics
                : l10n.homeImageChipSemantics(name),
            button: true,
            excludeSemantics: true,
            child: ActionChip(
              key: const Key('home.imageChip'),
              avatar: image == null
                  ? const Icon(Icons.palette_outlined)
                  : ImageCircle(image: image, size: _avatarSize),
              label: Text(
                name == null ? l10n.homeNoImage : l10n.homeImageChip(name),
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: () => _choose(visual),
            ),
          ),
        ),
        if (image != null)
          IconButton(
            key: const Key('home.imageClear'),
            tooltip: l10n.imagesNoneLabel,
            icon: const Icon(Icons.close_rounded),
            onPressed: () => _setVisual(VisualSource.defaultSource),
          ),
      ],
    );
  }
}
