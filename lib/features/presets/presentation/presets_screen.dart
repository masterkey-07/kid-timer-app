import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_time_counter/app/layout.dart';
import 'package:visual_time_counter/app/router.dart';
import 'package:visual_time_counter/app/widgets/confirm_dialog.dart';
import 'package:visual_time_counter/core/domain/duration_format.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/presets/application/presets_controller.dart';
import 'package:visual_time_counter/features/presets/data/preset_repository.dart';
import 'package:visual_time_counter/features/presets/domain/preset.dart';
import 'package:visual_time_counter/features/presets/presentation/widgets/preset_thumb.dart';
import 'package:visual_time_counter/features/timer/application/setup_config_controller.dart';
import 'package:visual_time_counter/features/timer/presentation/spoken_duration.dart';
import 'package:visual_time_counter/features/timer/presentation/start_timer.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// The preset list (contracts/ui/05 §5.1): start, edit, duplicate, reorder
/// and delete presets (FR-040–042).
class PresetsScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key = const Key('presets.screen')});

  /// How long a deleted preset can be restored.
  static const undoWindow = Duration(seconds: 5);

  /// The widest the list grows on large screens, so rows stay readable.
  static const _maxListWidth = 720.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final presets = ref.watch(presetsProvider);
    final hasRoom = presets.length < PresetRepository.maxPresets;
    final margin = ScreenLayout.of(MediaQuery.sizeOf(context)).margin;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.presetsTitle),
        actions: [
          IconButton(
            key: const Key('presets.new'),
            tooltip: l10n.presetsNew,
            icon: const Icon(Icons.add_rounded),
            onPressed: hasRoom ? () => _openNew(context, ref) : null,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxListWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!hasRoom)
                  Padding(
                    key: const Key('presets.limit'),
                    padding: EdgeInsets.fromLTRB(margin, margin, margin, 0),
                    child: Text(
                      l10n.presetsLimit(PresetRepository.maxPresets),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                Expanded(
                  child: presets.isEmpty
                      ? _EmptyPresets(
                          margin: margin,
                          onNew: () => _openNew(context, ref),
                        )
                      : _PresetList(presets: presets, margin: margin),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A new preset starts from the configuration set up on home.
  void _openNew(BuildContext context, WidgetRef ref) => context.push<void>(
    AppRoutes.presetsNew,
    extra: ref.read(setupConfigProvider),
  );
}

class _EmptyPresets extends StatelessWidget {
  const new({required this.margin, required this.onNew});

  final double margin;
  final VoidCallback onNew;

  static const _iconSize = 64.0;
  static const _gap = 16.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      key: const Key('presets.empty'),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(margin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_outlined,
              size: _iconSize,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: _gap),
            Text(
              l10n.presetsEmpty,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: _gap),
            FilledButton.icon(
              key: const Key('presets.emptyNew'),
              onPressed: onNew,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.presetsNew),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetList extends ConsumerWidget {
  const new({required this.presets, required this.margin});

  final List<Preset> presets;
  final double margin;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ReorderableListView.builder(
        padding: EdgeInsets.all(margin),
        buildDefaultDragHandles: false,
        itemCount: presets.length,
        onReorderItem: (from, to) => unawaited(
          _StorageGuard.of(context).run(() => _move(ref, presets[from], to)),
        ),
        itemBuilder: (context, index) => _PresetTile(
          key: ValueKey(presets[index].id),
          preset: presets[index],
          index: index,
          isLast: index == presets.length - 1,
        ),
      );
}

Future<void> _move(WidgetRef ref, Preset preset, int toIndex) =>
    ref.read(presetsProvider.notifier).move(preset.id, toIndex);

/// Runs preset changes and tells the adult when storage failed; the list
/// already shows what storage holds. [PresetLimitReached] propagates.
final class _StorageGuard {
  const new(this._messenger, this._failureMessage);

  /// Captures what a failure needs while [context] is still mounted.
  factory of(BuildContext context) => _StorageGuard(
    ScaffoldMessenger.of(context),
    AppLocalizations.of(context).presetsSaveFailed,
  );

  final ScaffoldMessengerState _messenger;
  final String _failureMessage;

  Future<void> run(Future<void> Function() change) async {
    try {
      await change();
    } on PresetLimitReached {
      rethrow;
    } on Object catch (error) {
      debugPrint('Preset change failed: $error');
      _messenger.showSnackBar(
        SnackBar(
          key: const Key('presets.saveFailed'),
          content: Text(_failureMessage),
        ),
      );
    }
  }
}

enum _PresetAction { edit, duplicate, delete }

class _PresetTile extends ConsumerWidget {
  const new({
    required this.preset,
    required this.index,
    required this.isLast,
    super.key,
  });

  final Preset preset;
  final int index;
  final bool isLast;

  static const _thumbSize = 40.0;
  static const _gap = 12.0;
  static const _rowPadding = 8.0;

  String get _id => preset.id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final duration = preset.config.duration.value;
    final isFirst = index == 0;

    void moveBy(int offset) => unawaited(
      _StorageGuard.of(context).run(() => _move(ref, preset, index + offset)),
    );

    return CallbackShortcuts(
      bindings: {
        if (!isFirst)
          const SingleActivator(
            LogicalKeyboardKey.arrowUp,
            control: true,
          ): () =>
              moveBy(-1),
        if (!isLast)
          const SingleActivator(
            LogicalKeyboardKey.arrowDown,
            control: true,
          ): () =>
              moveBy(1),
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: _rowPadding / 2),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            ReorderableDragStartListener(
              key: Key('presets.drag.$_id'),
              index: index,
              child: Tooltip(
                message: l10n.presetsDragHandle,
                excludeFromSemantics: true,
                child: const Padding(
                  padding: EdgeInsets.all(_gap),
                  child: Icon(Icons.drag_indicator_rounded),
                ),
              ),
            ),
            Expanded(
              child: Semantics(
                key: Key('presets.item.$_id'),
                button: true,
                label: l10n.presetsItemSemantics(
                  preset.name,
                  spokenDuration(l10n, duration),
                ),
                excludeSemantics: true,
                customSemanticsActions: {
                  CustomSemanticsAction(label: l10n.presetsEdit): () =>
                      _edit(context),
                  CustomSemanticsAction(label: l10n.presetsDuplicate): () =>
                      _duplicate(context, ref),
                  CustomSemanticsAction(label: l10n.presetsDelete): () =>
                      _delete(context, ref),
                  if (!isFirst)
                    CustomSemanticsAction(label: l10n.presetsMoveUp): () =>
                        moveBy(-1),
                  if (!isLast)
                    CustomSemanticsAction(label: l10n.presetsMoveDown): () =>
                        moveBy(1),
                },
                child: InkWell(
                  onTap: () => _edit(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: _rowPadding),
                    child: Row(
                      children: [
                        PresetThumb(
                          visual: preset.config.visual,
                          size: _thumbSize,
                        ),
                        const SizedBox(width: _gap),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                preset.name,
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                formatRemaining(duration),
                                style: theme.textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              key: Key('presets.start.$_id'),
              tooltip: l10n.presetsStart(preset.name),
              icon: const Icon(Icons.play_arrow_rounded),
              onPressed: () => startTimer(
                context,
                ref,
                preset.config,
                origin: PresetOrigin(_id),
                screen: 'presets',
              ),
            ),
            PopupMenuButton<_PresetAction>(
              key: Key('presets.menu.$_id'),
              tooltip: l10n.presetsMoreOptions,
              onSelected: (action) => switch (action) {
                _PresetAction.edit => _edit(context),
                _PresetAction.duplicate => _duplicate(context, ref),
                _PresetAction.delete => _delete(context, ref),
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  key: Key('presets.edit.$_id'),
                  value: _PresetAction.edit,
                  child: Text(l10n.presetsEdit),
                ),
                PopupMenuItem(
                  key: Key('presets.duplicate.$_id'),
                  value: _PresetAction.duplicate,
                  child: Text(l10n.presetsDuplicate),
                ),
                PopupMenuItem(
                  key: Key('presets.delete.$_id'),
                  value: _PresetAction.delete,
                  child: Text(l10n.presetsDelete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context) =>
      context.push<void>(AppRoutes.presetEdit(_id));

  Future<void> _duplicate(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _StorageGuard.of(context).run(
        () => ref
            .read(presetsProvider.notifier)
            .duplicate(_id, suffix: l10n.presetsDuplicateSuffix),
      );
    } on PresetLimitReached {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.presetsLimit(PresetRepository.maxPresets))),
      );
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(presetsProvider.notifier);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.presetsDeleteTitle,
      message: l10n.presetsDeleteMessage(preset.name),
      confirmLabel: l10n.presetsDelete,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final guard = _StorageGuard.of(context);
    Preset? deleted;
    await guard.run(() async => deleted = await controller.delete(_id));
    final restorable = deleted;
    if (restorable == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('presets.deleted'),
          content: Text(l10n.presetsDeleted),
          duration: PresetsScreen.undoWindow,
          // Undo only makes sense for a few seconds (contracts/ui/05).
          persist: false,
          action: SnackBarAction(
            key: const Key('presets.undo'),
            label: l10n.presetsUndo,
            onPressed: () =>
                unawaited(guard.run(() => controller.restore(restorable))),
          ),
        ),
      );
  }
}
