import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_time_counter/app/layout.dart';
import 'package:visual_time_counter/app/router.dart';
import 'package:visual_time_counter/app/theme/palettes.dart';
import 'package:visual_time_counter/app/widgets/confirm_dialog.dart';
import 'package:visual_time_counter/core/domain/color_token.dart';
import 'package:visual_time_counter/core/domain/dial_direction.dart';
import 'package:visual_time_counter/core/domain/dial_scale.dart';
import 'package:visual_time_counter/core/domain/palette_id.dart';
import 'package:visual_time_counter/core/domain/sound_id.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/domain/timer_duration.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';
import 'package:visual_time_counter/core/platform/providers.dart';
import 'package:visual_time_counter/features/images/presentation/widgets/image_thumb.dart';
import 'package:visual_time_counter/features/presets/application/presets_controller.dart';
import 'package:visual_time_counter/features/presets/data/preset_repository.dart';
import 'package:visual_time_counter/features/presets/domain/preset.dart';
import 'package:visual_time_counter/features/presets/presentation/widgets/preset_thumb.dart';
import 'package:visual_time_counter/features/timer/presentation/widgets/dial_view.dart';
import 'package:visual_time_counter/features/timer/presentation/widgets/digits_label.dart';
import 'package:visual_time_counter/features/timer/presentation/widgets/duration_quick_buttons.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// Creates or edits a preset (contracts/ui/05 §5.2, FR-040).
class PresetEditorScreen extends ConsumerStatefulWidget {
  /// A new preset starting from [initialConfig].
  const new create({
    required TimerConfig this.initialConfig,
    super.key = const Key('presetEditor.screen'),
  }) : presetId = null;

  /// Edits the preset [presetId].
  const new edit({
    required String this.presetId,
    super.key = const Key('presetEditor.screen'),
  }) : initialConfig = null;

  /// The configuration of a new preset.
  final TimerConfig? initialConfig;

  /// The preset being edited.
  final String? presetId;

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorState();
}

class _PresetEditorState extends ConsumerState<PresetEditorScreen> {
  static const _maxContentWidth = 720.0;
  static const _dialShare = 0.6;
  static const _maxDialSize = 320.0;
  static const _gap = 16.0;
  static const _appBarGap = 8.0;

  late final String _initialName;
  late final TimerConfig _initialConfig;
  late final _name = TextEditingController(text: _initialName);
  late TimerConfig _config = _initialConfig;
  bool _showsNameError = false;
  bool _isSaving = false;

  bool get _isNew => widget.presetId == null;

  bool get _hasChanges =>
      _name.text.trim() != _initialName || _config != _initialConfig;

  @override
  void initState() {
    super.initState();
    final presetId = widget.presetId;
    final preset = presetId == null
        ? null
        : ref.read(presetsProvider.notifier).find(presetId);
    _initialName = preset?.name ?? '';
    _initialConfig = preset?.config ?? widget.initialConfig!;
    _name.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _onNameChanged() => setState(() {
    if (_showsNameError) _showsNameError = !Preset.isValidName(_name.text);
  });

  void _change(TimerConfig config) => setState(() => _config = config);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.sizeOf(context);
    final margin = ScreenLayout.of(size).margin;
    final dialSize = math.min(size.shortestSide * _dialShare, _maxDialSize);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_close());
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            key: const Key('presetEditor.close'),
            tooltip: l10n.presetEditorClose,
            icon: const Icon(Icons.close_rounded),
            onPressed: _close,
          ),
          title: Text(_isNew ? l10n.presetsNew : l10n.presetEditorEditTitle),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: _appBarGap),
              child: FilledButton(
                key: const Key('presetEditor.save'),
                onPressed: _isSaving ? null : _save,
                child: Text(l10n.presetEditorSave),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(margin),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _NameField(controller: _name, showsError: _showsNameError),
                    const SizedBox(height: _gap),
                    Center(
                      child: SizedBox.square(
                        dimension: dialSize,
                        child: DialView.editable(
                          key: const Key('presetEditor.dial'),
                          config: _config,
                          onChanged: (duration) =>
                              _change(_config.copyWith(duration: duration)),
                        ),
                      ),
                    ),
                    const SizedBox(height: _gap),
                    Center(
                      child: DigitsLabel(
                        key: const Key('presetEditor.durationDigits'),
                        duration: _config.duration.value,
                      ),
                    ),
                    const SizedBox(height: _gap),
                    DurationQuickButtons(
                      keyPrefix: 'presetEditor',
                      duration: _config.duration,
                      onChanged: (duration) =>
                          _change(_config.copyWith(duration: duration)),
                      onMaxReached: _showMaxReached,
                    ),
                    const SizedBox(height: _gap),
                    _ImageRow(
                      visual: _config.visual,
                      onChoose: _chooseImage,
                      onClear: () => _change(
                        _config.copyWith(visual: VisualSource.defaultSource),
                      ),
                    ),
                    const SizedBox(height: _gap),
                    _AppearanceControls(config: _config, onChanged: _change),
                    const SizedBox(height: _gap),
                    _SoundControls(config: _config, onChanged: _change),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _chooseImage() async {
    final chosen = await context.push<VisualSource>(
      AppRoutes.images,
      extra: _config.visual,
    );
    if (chosen == null || !mounted) return;
    _change(_config.copyWith(visual: chosen));
  }

  void _showMaxReached() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).homeMaxReached)),
      );
  }

  Future<void> _close() async {
    if (_hasChanges) {
      final l10n = AppLocalizations.of(context);
      final discards = await showConfirmDialog(
        context,
        title: l10n.presetEditorDiscardTitle,
        message: l10n.presetEditorDiscardMessage,
        confirmLabel: l10n.presetEditorDiscard,
        isDestructive: true,
      );
      if (!discards || !mounted) return;
    }
    _leave();
  }

  Future<void> _save() async {
    if (!Preset.isValidName(_name.text)) {
      setState(() => _showsNameError = true);
      return;
    }
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(presetsProvider.notifier);
    final presetId = widget.presetId;

    setState(() => _isSaving = true);
    try {
      if (presetId == null) {
        await controller.create(name: _name.text, config: _config);
      } else {
        await controller.update(presetId, name: _name.text, config: _config);
      }
    } on PresetLimitReached {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.presetsLimit(PresetRepository.maxPresets))),
      );
      return;
    } on Object catch (error) {
      debugPrint('Could not save the preset: $error');
      messenger.showSnackBar(
        SnackBar(
          key: const Key('presetEditor.saveFailed'),
          content: Text(l10n.presetsSaveFailed),
        ),
      );
      return;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
    if (mounted) _leave();
  }

  /// Back to where the editor was opened from: the list or home.
  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.presets);
    }
  }
}

class _NameField extends StatelessWidget {
  const new({required this.controller, required this.showsError});

  final TextEditingController controller;
  final bool showsError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final length = Preset.nameLength(controller.text);
    return TextField(
      key: const Key('presetEditor.name'),
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: l10n.presetEditorName,
        error: showsError
            ? Text(
                l10n.presetEditorNameError(Preset.maxNameLength),
                key: const Key('presetEditor.nameError'),
              )
            : null,
        // Counted by the preset rule (trimmed, an emoji is one character),
        // so the counter and the validation always agree.
        counter: KeyedSubtree(
          key: const Key('presetEditor.nameCounter'),
          child: Text('$length/${Preset.maxNameLength}'),
        ),
      ),
    );
  }
}

class _ImageRow extends ConsumerWidget {
  const new({
    required this.visual,
    required this.onChoose,
    required this.onClear,
  });

  final VisualSource visual;
  final VoidCallback onChoose;
  final VoidCallback onClear;

  static const _thumbSize = 40.0;
  static const _gap = 12.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final image = watchImageOf(ref, visual);
    final name = image == null ? null : imageLabel(context, image);
    return Row(
      children: [
        PresetThumb(visual: visual, size: _thumbSize),
        const SizedBox(width: _gap),
        Expanded(
          child: Text(
            name == null ? l10n.homeNoImage : l10n.homeImageChip(name),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        OutlinedButton(
          key: const Key('presetEditor.image'),
          onPressed: onChoose,
          child: Text(
            l10n.presetEditorChangeImage,
            semanticsLabel: name == null
                ? l10n.homeNoImageSemantics
                : l10n.homeImageChipSemantics(name),
          ),
        ),
        if (visual is! PaletteSource)
          IconButton(
            key: const Key('presetEditor.imageClear'),
            tooltip: l10n.imagesNoneLabel,
            icon: const Icon(Icons.close_rounded),
            onPressed: onClear,
          ),
      ],
    );
  }
}

/// Scale, direction and, without an image, the palette. Choices are chips
/// that wrap, so they fit narrow screens and large text.
class _AppearanceControls extends StatelessWidget {
  const new({required this.config, required this.onChanged});

  final TimerConfig config;
  final ValueChanged<TimerConfig> onChanged;

  static const _gap = 16.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visual = config.visual;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Labeled(
          label: l10n.presetEditorScale,
          child: _Choices(
            key: const Key('presetEditor.scale'),
            children: [
              for (final scale in DialScale.values)
                ChoiceChip(
                  key: Key('presetEditor.scale.${scale.name}'),
                  label: Text(
                    l10n.presetEditorScaleMinutes(scale.span.inMinutes),
                  ),
                  selected: scale == config.scale,
                  onSelected: (_) => onChanged(_withScale(scale)),
                ),
            ],
          ),
        ),
        const SizedBox(height: _gap),
        _Labeled(
          label: l10n.presetEditorDirection,
          child: _Choices(
            key: const Key('presetEditor.direction'),
            children: [
              for (final direction in DialDirection.values)
                ChoiceChip(
                  key: Key('presetEditor.direction.${direction.name}'),
                  label: Text(_directionName(l10n, direction)),
                  selected: direction == config.direction,
                  onSelected: (_) =>
                      onChanged(config.copyWith(direction: direction)),
                ),
            ],
          ),
        ),
        if (visual is PaletteSource) ...[
          const SizedBox(height: _gap),
          _PaletteControls(
            palette: visual,
            onChanged: (palette) => onChanged(config.copyWith(visual: palette)),
          ),
        ],
      ],
    );
  }

  /// A scale shorter than the duration clamps it (contracts/ui/01).
  TimerConfig _withScale(DialScale scale) => config.copyWith(
    scale: scale,
    duration: config.duration.value > scale.span
        ? TimerDuration(scale.span)
        : config.duration,
  );
}

class _PaletteControls extends StatelessWidget {
  const new({required this.palette, required this.onChanged});

  final PaletteSource palette;
  final ValueChanged<PaletteSource> onChanged;

  static const ColorToken _defaultColor = ColorToken.blue;
  static const _swatchSize = 18.0;
  static const _spacing = 8.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final singleColor = palette.singleColor;
    return _Labeled(
      key: const Key('presetEditor.palette'),
      label: l10n.presetEditorColors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Choices(
            children: [
              for (final paletteId in PaletteId.values)
                ChoiceChip(
                  key: Key('presetEditor.palette.${paletteId.name}'),
                  label: Text(_paletteName(l10n, paletteId)),
                  selected: paletteId == palette.paletteId,
                  onSelected: (_) => onChanged(
                    PaletteSource(
                      paletteId: paletteId,
                      singleColor: singleColor ?? _defaultColor,
                    ),
                  ),
                ),
            ],
          ),
          if (singleColor != null) ...[
            const SizedBox(height: _spacing),
            _Choices(
              children: [
                for (final token in ColorToken.values)
                  ChoiceChip(
                    key: Key('presetEditor.color.${token.name}'),
                    avatar: CircleAvatar(
                      radius: _swatchSize / 2,
                      backgroundColor: DialPalettes.tokenColor(token),
                    ),
                    label: Text(_colorName(l10n, token)),
                    selected: token == singleColor,
                    onSelected: (_) => onChanged(
                      PaletteSource(
                        paletteId: PaletteId.single,
                        singleColor: token,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Chips for one choice, wrapping onto new lines as needed, with labels
/// at body size for legibility.
class _Choices extends StatelessWidget {
  const new({required this.children, super.key});

  final List<Widget> children;

  static const _spacing = 8.0;

  @override
  Widget build(BuildContext context) => ChipTheme(
    data: ChipTheme.of(context)
        .copyWith(labelStyle: Theme.of(context).textTheme.bodyLarge),
    child: Wrap(spacing: _spacing, runSpacing: _spacing, children: children),
  );
}

/// Sound with preview, volume, ticking, vibration and digits.
class _SoundControls extends ConsumerWidget {
  const new({required this.config, required this.onChanged});

  final TimerConfig config;
  final ValueChanged<TimerConfig> onChanged;

  static const _volumeSteps = 20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final soundName = _soundName(l10n, config.soundId);
    final hasVibrator = ref.watch(hapticsProvider).hasVibrator;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          key: const Key('presetEditor.sound'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.presetEditorSound),
          subtitle: Text(soundName),
          trailing: IconButton(
            key: const Key('presetEditor.soundPreview'),
            tooltip: l10n.presetEditorSoundPreview(soundName),
            icon: const Icon(Icons.volume_up_rounded),
            onPressed: config.soundId.isAudible
                ? () => ref
                      .read(audioProvider)
                      .playPreview(config.soundId, volume: config.alarmVolume)
                : null,
          ),
        ),
        _Labeled(
          label: l10n.presetEditorVolume,
          child: Semantics(
            label: l10n.presetEditorVolume,
            child: Slider(
              key: const Key('presetEditor.volume'),
              value: config.alarmVolume,
              divisions: _volumeSteps,
              onChanged: (volume) =>
                  onChanged(config.copyWith(alarmVolume: volume)),
            ),
          ),
        ),
        SwitchListTile(
          key: const Key('presetEditor.tick'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.presetEditorTick),
          value: config.tickEnabled,
          onChanged: (isOn) => onChanged(config.copyWith(tickEnabled: isOn)),
        ),
        if (hasVibrator)
          SwitchListTile(
            key: const Key('presetEditor.vibrate'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.presetEditorVibrate),
            value: config.vibrate,
            onChanged: (isOn) => onChanged(config.copyWith(vibrate: isOn)),
          ),
        SwitchListTile(
          key: const Key('presetEditor.digits'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.presetEditorDigits),
          value: config.showDigits,
          onChanged: (isOn) => onChanged(config.copyWith(showDigits: isOn)),
        ),
      ],
    );
  }
}

/// A section title above its control.
class _Labeled extends StatelessWidget {
  const new({required this.label, required this.child, super.key});

  final String label;
  final Widget child;

  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: _gap),
      child,
    ],
  );
}

String _directionName(AppLocalizations l10n, DialDirection direction) =>
    switch (direction) {
      DialDirection.clockwise => l10n.presetEditorClockwise,
      DialDirection.counterClockwise => l10n.presetEditorCounterClockwise,
    };

String _paletteName(AppLocalizations l10n, PaletteId paletteId) =>
    switch (paletteId) {
      PaletteId.progressive => l10n.paletteProgressive,
      PaletteId.single => l10n.paletteSingle,
      PaletteId.calm => l10n.paletteCalm,
    };

String _colorName(AppLocalizations l10n, ColorToken token) => switch (token) {
  ColorToken.blue => l10n.colorBlue,
  ColorToken.green => l10n.colorGreen,
  ColorToken.yellow => l10n.colorYellow,
  ColorToken.orange => l10n.colorOrange,
  ColorToken.purple => l10n.colorPurple,
  ColorToken.pink => l10n.colorPink,
  ColorToken.teal => l10n.colorTeal,
  ColorToken.gray => l10n.colorGray,
};

/// The name of a bundled sound; until the sound picker (US6) brings the
/// full list, only the default and silence are named.
String _soundName(AppLocalizations l10n, SoundId sound) => switch (sound) {
  SoundId.none => l10n.soundNone,
  SoundId.chimeSoft => l10n.soundChimeSoft,
  _ => sound.value,
};
