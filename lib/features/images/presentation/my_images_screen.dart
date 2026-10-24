import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/app/layout.dart';
import 'package:visual_time_counter/app/widgets/confirm_dialog.dart';
import 'package:visual_time_counter/features/images/application/my_images_controller.dart';
import 'package:visual_time_counter/features/images/data/user_image_repository.dart';
import 'package:visual_time_counter/features/images/domain/image_asset.dart';
import 'package:visual_time_counter/features/images/presentation/widgets/image_thumb.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// List, rename and delete own images (contracts/ui/04 §4.3, FR-024).
class MyImagesScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key = const Key('mine.screen')});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final images = ref.watch(userImagesProvider);
    final margin = ScreenLayout.of(MediaQuery.sizeOf(context)).margin;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mineTitle)),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              key: const Key('mine.count'),
              padding: EdgeInsets.fromLTRB(margin, margin, margin, 0),
              child: Text(
                l10n.mineCount(images.length, UserImageRepository.maxImages),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Expanded(child: _buildImages(context, images, margin)),
          ],
        ),
      ),
    );
  }

  Widget _buildImages(
    BuildContext context,
    List<UserImageAsset> images,
    double margin,
  ) {
    final l10n = AppLocalizations.of(context);
    return images.isEmpty
        ? Center(
            key: const Key('mine.empty'),
            child: Padding(
              padding: EdgeInsets.all(margin),
              child: Text(
                l10n.imagesMineEmpty,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          )
        : GridView.builder(
            key: const Key('mine.grid'),
            padding: EdgeInsets.all(margin),
            gridDelegate: imageGridDelegate(context),
            itemCount: images.length,
            itemBuilder: (context, index) => _MineTile(image: images[index]),
          );
  }
}

class _MineTile extends ConsumerWidget {
  new({required this.image}) : super(key: Key('mine.item.${image.id}'));

  final UserImageAsset image;

  Future<void> _showMenu(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final action = await showModalBottomSheet<_TileAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: Key('mine.rename.${image.id}'),
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.mineRename),
              onTap: () => Navigator.of(context).pop(_TileAction.rename),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.mineDelete),
              onTap: () => Navigator.of(context).pop(_TileAction.delete),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case _TileAction.rename:
        await _rename(context, ref);
      case _TileAction.delete:
        await _confirmDelete(context, ref);
      case null:
        break;
    }
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final label = await showDialog<String>(
      context: context,
      builder: (context) => _RenameDialog(initialLabel: image.label ?? ''),
    );
    if (label == null) return;
    await ref.read(userImagesProvider.notifier).rename(image.id, label);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(userImagesProvider.notifier);
    final references = controller.referencesTo(image.id);
    final message = [
      l10n.mineDeleteConfirm,
      if (references.presetNames.isNotEmpty)
        l10n.mineAffectedPresets(references.presetNames.join(', ')),
      if (references.isInDefaults || references.isInLastConfig)
        l10n.mineAffectedTimer,
    ].join('\n\n');

    final confirmed = await showConfirmDialog(
      context,
      title: l10n.mineDeleteTitle,
      message: message,
      confirmLabel: l10n.mineDelete,
      isDestructive: true,
    );
    if (confirmed) await controller.delete(image.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: Semantics(
            container: true,
            label: imageLabel(context, image),
            onLongPressHint: l10n.mineRename,
            excludeSemantics: true,
            child: InkWell(
              onLongPress: () => _showMenu(context, ref),
              customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: ImageThumb(image: image),
              ),
            ),
          ),
        ),
        PositionedDirectional(
          top: 0,
          end: 0,
          child: IconButton.filledTonal(
            key: Key('mine.delete.${image.id}'),
            tooltip: l10n.mineDeleteLabel(imageLabel(context, image)),
            icon: const Icon(Icons.close_rounded),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ),
      ],
    );
  }
}

enum _TileAction { rename, delete }

class _RenameDialog extends StatefulWidget {
  const new({required this.initialLabel});

  final String initialLabel;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _label = TextEditingController(text: widget.initialLabel);

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.mineRenameTitle),
      content: TextField(
        key: const Key('mine.renameField'),
        controller: _label,
        autofocus: true,
        maxLength: UserImageAsset.maxLabelLength,
        decoration: InputDecoration(labelText: l10n.mineNameField),
        onSubmitted: (label) => Navigator.of(context).pop(label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          key: const Key('mine.renameSave'),
          onPressed: () => Navigator.of(context).pop(_label.text),
          child: Text(l10n.mineRename),
        ),
      ],
    );
  }
}
