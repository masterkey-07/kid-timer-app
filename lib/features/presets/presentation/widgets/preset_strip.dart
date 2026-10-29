import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/core/domain/duration_format.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/presets/application/presets_controller.dart';
import 'package:visual_time_counter/features/presets/domain/preset.dart';
import 'package:visual_time_counter/features/presets/presentation/widgets/preset_thumb.dart';
import 'package:visual_time_counter/features/timer/application/setup_config_controller.dart';
import 'package:visual_time_counter/features/timer/presentation/spoken_duration.dart';
import 'package:visual_time_counter/features/timer/presentation/start_timer.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// The first presets on the home screen (contracts/ui/01): tapping one
/// loads it into the setup, and its ▶ starts it at once (FR-041).
class PresetStrip extends ConsumerWidget {
  /// Creates the strip; it is empty without presets.
  const new({super.key});

  /// The most presets the strip shows.
  static const maxShown = 8;

  static const _spacing = 8.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presets = ref.watch(presetsProvider).take(maxShown).toList();
    if (presets.isEmpty) return const SizedBox.shrink();

    // A row rather than a fixed-height list, so it grows with the text size.
    return SingleChildScrollView(
      key: const Key('home.presetStrip'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (index, preset) in presets.indexed) ...[
            if (index > 0) const SizedBox(width: _spacing),
            _PresetChip(preset: preset),
          ],
        ],
      ),
    );
  }
}

class _PresetChip extends ConsumerWidget {
  const new({required this.preset});

  final Preset preset;

  static const _thumbSize = 32.0;
  static const _padding = 8.0;
  static const _radius = 24.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final duration = preset.config.duration.value;
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            key: Key('home.preset.${preset.id}'),
            button: true,
            label: l10n.homePresetSemantics(
              preset.name,
              spokenDuration(l10n, duration),
            ),
            excludeSemantics: true,
            child: InkWell(
              onTap: () =>
                  ref.read(setupConfigProvider.notifier).change(preset.config),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  _padding,
                  _padding,
                  0,
                  _padding,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PresetThumb(visual: preset.config.visual, size: _thumbSize),
                    const SizedBox(width: _padding),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(preset.name, style: theme.textTheme.bodyLarge),
                        Text(
                          formatRemaining(duration),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            key: Key('home.presetStart.${preset.id}'),
            tooltip: l10n.presetsStart(preset.name),
            icon: const Icon(Icons.play_arrow_rounded),
            onPressed: () => startTimer(
              context,
              ref,
              preset.config,
              origin: PresetOrigin(preset.id),
            ),
          ),
        ],
      ),
    );
  }
}
