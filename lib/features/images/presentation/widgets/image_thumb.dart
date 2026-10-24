import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:visual_time_counter/app/layout.dart';
import 'package:visual_time_counter/features/images/application/my_images_controller.dart';
import 'package:visual_time_counter/features/images/domain/image_asset.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// The bytes of an own image, for its thumbnail.
final FutureProviderFamily<Uint8List?, String> userImageBytesProvider =
    FutureProvider.autoDispose.family<Uint8List?, String>(
      (ref, id) => ref.read(userImageRepositoryProvider).readBytes(id),
    );

/// The accessible name of [image] (FR-026): its library label in the app's
/// language, or the adult's name for an own image.
String imageLabel(BuildContext context, ImageAsset image) => switch (image) {
  BankImageAsset() => image.labelFor(
    Localizations.localeOf(context).languageCode,
  ),
  UserImageAsset(:final label) =>
    label ?? AppLocalizations.of(context).imagesOwnImage,
};

/// Columns of the image grids (contracts/ui/04 §4.1).
int imageGridColumns(BuildContext context) =>
    switch (ScreenLayout.of(MediaQuery.sizeOf(context)).sizeClass) {
      SizeClass.compact => 3,
      SizeClass.medium => 5,
      SizeClass.expanded => 7,
    };

/// A grid layout with room for a 96 dp thumbnail and two lines of label at
/// the current text size.
SliverGridDelegate imageGridDelegate(BuildContext context) {
  final labelStyle = Theme.of(context).textTheme.bodyLarge!;
  final lineHeight = MediaQuery.textScalerOf(context)
      .scale(labelStyle.fontSize! * labelStyle.height!);
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: imageGridColumns(context),
    mainAxisExtent:
        ImageThumb.size + _labelGap + _labelLines * lineHeight + _cellPadding,
    crossAxisSpacing: _cellSpacing,
  );
}

// Wider than the 4 px the contrast check samples around text, so the
// thumbnail's outline never counts as the label's color.
const _labelGap = 8.0;
const _labelLines = 2;
const _cellPadding = 8.0;
const _cellSpacing = 8.0;

/// A circular thumbnail with its label below (text never sits on an
/// image, contracts/ui/00 §3.2) and, when [isSelected], a ring and a ✓.
class ImageThumb extends ConsumerWidget {
  /// Creates the thumbnail of [image].
  const new({required this.image, this.isSelected = false, super.key});

  /// Thumbnail diameter.
  static const size = 96.0;

  static const _ringWidth = 4.0;
  static const _checkSize = 24.0;

  /// The image shown.
  final ImageAsset image;

  /// Whether it is the current choice.
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).round();
    final picture = switch (image) {
      BankImageAsset(:final assetPath) => Image.asset(
        assetPath,
        cacheWidth: pixels,
        fit: BoxFit.cover,
        errorBuilder: _placeholder,
      ),
      UserImageAsset(:final id) => switch (ref.watch(
        userImageBytesProvider(id),
      )) {
        AsyncData(value: final bytes?) => Image.memory(
          bytes,
          cacheWidth: pixels,
          fit: BoxFit.cover,
          errorBuilder: _placeholder,
        ),
        _ => _placeholder(context, null, null),
      },
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: size,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? colors.primary : colors.outline,
                      width: isSelected ? _ringWidth : 1,
                    ),
                  ),
                  child: ClipOval(child: picture),
                ),
              ),
              if (isSelected)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleAvatar(
                    radius: _checkSize / 2,
                    backgroundColor: colors.primary,
                    child: Icon(
                      Icons.check_rounded,
                      size: _checkSize * 0.75,
                      color: colors.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: _labelGap),
        Text(
          imageLabel(context, image),
          maxLines: _labelLines,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  static Widget _placeholder(
    BuildContext context,
    Object? error,
    StackTrace? stackTrace,
  ) => ColoredBox(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Icon(
      Icons.image_outlined,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}
