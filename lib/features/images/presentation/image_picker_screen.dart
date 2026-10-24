import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_time_counter/app/layout.dart';
import 'package:visual_time_counter/app/router.dart';
import 'package:visual_time_counter/app/widgets/confirm_dialog.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';
import 'package:visual_time_counter/core/platform/providers.dart';
import 'package:visual_time_counter/features/images/application/image_library.dart';
import 'package:visual_time_counter/features/images/application/my_images_controller.dart';
import 'package:visual_time_counter/features/images/data/user_image_repository.dart';
import 'package:visual_time_counter/features/images/domain/image_asset.dart';
import 'package:visual_time_counter/features/images/domain/image_category.dart';
import 'package:visual_time_counter/features/images/presentation/frame_screen.dart';
import 'package:visual_time_counter/features/images/presentation/widgets/image_thumb.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// Choose the dial's image (contracts/ui/04 §4.1): the library by
/// category, own images or a new photo. Pops the chosen [VisualSource].
class ImagePickerScreen extends ConsumerStatefulWidget {
  /// Creates the screen with [selected] marked as the current choice.
  const new({this.selected, super.key = const Key('images.screen')});

  /// The dial's current source.
  final VisualSource? selected;

  @override
  ConsumerState<ImagePickerScreen> createState() => _ImagePickerScreenState();
}

/// The picker's tabs, in order.
enum _PickerTab {
  all(null),
  hygiene(ImageCategory.hygiene),
  meal(ImageCategory.meal),
  play(ImageCategory.play),
  rest(ImageCategory.rest),
  school(ImageCategory.school),
  goingOut(ImageCategory.goingOut),
  mine(null);

  new(this.category);

  final ImageCategory? category;

  String label(AppLocalizations l10n) => switch (this) {
    all => l10n.imagesTabAll,
    hygiene => l10n.imagesCategoryHygiene,
    meal => l10n.imagesCategoryMeal,
    play => l10n.imagesCategoryPlay,
    rest => l10n.imagesCategoryRest,
    school => l10n.imagesCategorySchool,
    goingOut => l10n.imagesCategoryGoingOut,
    mine => l10n.imagesTabMine,
  };
}

class _ImagePickerScreenState extends ConsumerState<ImagePickerScreen> {
  _PickerTab _tab = _PickerTab.all;

  List<ImageAsset> _imagesIn(
    _PickerTab tab,
    List<BankImageAsset> library,
    List<UserImageAsset> own,
  ) => switch (tab) {
    _PickerTab.all => [...library, ...own],
    _PickerTab.mine => own,
    _ => library.where((image) => image.category == tab.category).toList(),
  };

  VisualSource _sourceOf(ImageAsset image) => switch (image) {
    BankImageAsset(:final id) => BankImageSource(id),
    UserImageAsset(:final id) => UserImageSource(id),
  };

  Future<void> _pickFromDevice() async {
    final l10n = AppLocalizations.of(context);
    if (!ref.read(userImagesProvider.notifier).hasRoom) {
      await _explainLimit(l10n);
      return;
    }

    final picked = await ref.read(imagePickerProvider).pickImage();
    if (picked == null || !mounted) return;
    final FrameRequest request;
    try {
      final preview = await ref.read(imagePreviewDecoderProvider)(picked.bytes);
      request = FrameRequest(bytes: picked.bytes, preview: preview);
    } on Object catch (error) {
      debugPrint('Picked file cannot be opened: $error');
      _showOpenError(l10n);
      return;
    }
    if (!mounted) return;

    final framed = await context.push<VisualSource>(
      AppRoutes.imagesFrame,
      extra: request,
    );
    if (framed != null && mounted) context.pop(framed);
  }

  Future<void> _explainLimit(AppLocalizations l10n) async {
    final openMine = await showConfirmDialog(
      context,
      title: l10n.imagesLimitTitle,
      message: l10n.imagesLimitReached(UserImageRepository.maxImages),
      confirmLabel: l10n.imagesLimitManage,
    );
    if (openMine && mounted) await context.push<void>(AppRoutes.imagesMine);
  }

  void _showOpenError(AppLocalizations l10n) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const Key('images.openError'),
        content: Text(l10n.imagesOpenError),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final layout = ScreenLayout.of(MediaQuery.sizeOf(context));
    final library = ref.watch(bankImagesProvider).value ?? const [];
    final own = ref.watch(userImagesProvider);
    final isWeb = ref.watch(appPlatformProvider) == AppPlatform.web;
    final images = _imagesIn(_tab, library, own);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.imagesTitle),
        actions: [
          Semantics(
            label: l10n.imagesManageLabel,
            excludeSemantics: true,
            button: true,
            child: TextButton(
              key: const Key('images.manage'),
              onPressed: () => context.push<void>(AppRoutes.imagesMine),
              child: Text(l10n.imagesManage),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Tabs(
              selected: _tab,
              countOf: (tab) => _imagesIn(tab, library, own).length,
              onSelected: (tab) => setState(() => _tab = tab),
            ),
            if (!(_tab == _PickerTab.mine && own.isEmpty)) ...[
              Padding(
                padding: EdgeInsets.fromLTRB(
                  layout.margin,
                  8,
                  layout.margin,
                  0,
                ),
                child: _FromDeviceButton(
                  buttonKey: const Key('images.fromDevice'),
                  onPressed: _pickFromDevice,
                ),
              ),
              if (isWeb)
                Padding(
                  key: const Key('images.webNote'),
                  padding: EdgeInsets.fromLTRB(
                    layout.margin,
                    8,
                    layout.margin,
                    0,
                  ),
                  child: Text(
                    l10n.imagesWebStorageNote,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
            Expanded(
              child: _tab == _PickerTab.mine && own.isEmpty
                  ? _MineEmpty(onFromDevice: _pickFromDevice)
                  : GridView.builder(
                      key: const Key('images.grid'),
                      padding: EdgeInsets.all(layout.margin),
                      gridDelegate: imageGridDelegate(context),
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        final image = images[index];
                        final source = _sourceOf(image);
                        return _ImageTile(
                          key: Key('images.item.${image.id}'),
                          image: image,
                          isSelected: source == widget.selected,
                          onTap: () => context.pop(source),
                        );
                      },
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                layout.margin,
                0,
                layout.margin,
                layout.margin,
              ),
              child: Semantics(
                label: l10n.imagesNoneLabel,
                excludeSemantics: true,
                button: true,
                child: OutlinedButton.icon(
                  key: const Key('images.none'),
                  onPressed: () => context.pop(VisualSource.defaultSource),
                  icon: const Icon(Icons.palette_outlined),
                  label: Text(l10n.imagesNone),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The category chips.
class _Tabs extends StatelessWidget {
  const new({
    required this.selected,
    required this.countOf,
    required this.onSelected,
  });

  final _PickerTab selected;
  final int Function(_PickerTab tab) countOf;
  final ValueChanged<_PickerTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final margin = ScreenLayout.of(MediaQuery.sizeOf(context)).margin;
    // Wrapped, as in the wireframe, so no tab hides off screen.
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: margin),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final tab in _PickerTab.values)
            Semantics(
              label: l10n.imagesTabLabel(tab.label(l10n), countOf(tab)),
              selected: tab == selected,
              button: true,
              excludeSemantics: true,
              child: ChoiceChip(
                key: Key('images.tab.${tab.name}'),
                label: Text(tab.label(l10n)),
                selected: tab == selected,
                onSelected: (_) => onSelected(tab),
              ),
            ),
        ],
      ),
    );
  }
}

/// A library or own image in the grid.
class _ImageTile extends StatelessWidget {
  const new({
    required this.image,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final ImageAsset image;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    selected: isSelected,
    label: imageLabel(context, image),
    excludeSemantics: true,
    child: InkWell(
      onTap: onTap,
      customBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: ImageThumb(image: image, isSelected: isSelected),
      ),
    ),
  );
}

class _FromDeviceButton extends StatelessWidget {
  const new({required this.buttonKey, required this.onPressed});

  final Key buttonKey;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.imagesFromDeviceLabel,
      excludeSemantics: true,
      button: true,
      child: FilledButton.icon(
        key: buttonKey,
        onPressed: onPressed,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: Text(l10n.imagesFromDevice),
      ),
    );
  }
}

/// "My images" before the adult has added any.
class _MineEmpty extends StatelessWidget {
  const new({required this.onFromDevice});

  final VoidCallback onFromDevice;

  @override
  Widget build(BuildContext context) {
    final margin = ScreenLayout.of(MediaQuery.sizeOf(context)).margin;
    return Center(
      key: const Key('images.mineEmpty'),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(margin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: ImageThumb.size,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).imagesMineEmpty,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            _FromDeviceButton(
              buttonKey: const Key('images.mineEmpty.fromDevice'),
              onPressed: onFromDevice,
            ),
          ],
        ),
      ),
    );
  }
}
