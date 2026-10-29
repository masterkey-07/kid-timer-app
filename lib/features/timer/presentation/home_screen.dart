import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_time_counter/app/layout.dart';
import 'package:visual_time_counter/app/router.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/presets/application/presets_controller.dart';
import 'package:visual_time_counter/features/presets/domain/preset.dart';
import 'package:visual_time_counter/features/presets/presentation/widgets/preset_strip.dart';
import 'package:visual_time_counter/features/settings/application/app_settings_state.dart';
import 'package:visual_time_counter/features/timer/application/setup_config_controller.dart';
import 'package:visual_time_counter/features/timer/presentation/spoken_duration.dart';
import 'package:visual_time_counter/features/timer/presentation/start_timer.dart';
import 'package:visual_time_counter/features/timer/presentation/widgets/background_alarm_banner.dart';
import 'package:visual_time_counter/features/timer/presentation/widgets/dial_view.dart';
import 'package:visual_time_counter/features/timer/presentation/widgets/digits_label.dart';
import 'package:visual_time_counter/features/timer/presentation/widgets/duration_quick_buttons.dart';
import 'package:visual_time_counter/features/timer/presentation/widgets/image_chip.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// Home: the adult sets up the timer and starts it (contracts/ui/01).
class HomeScreen extends ConsumerWidget {
  /// Creates the screen; with [startPresetId] (a `vtc://preset/<id>/start`
  /// link) it starts that preset once shown.
  const new({this.startPresetId, super.key = const Key('home.screen')});

  /// The preset a deep link asked to start.
  final String? startPresetId;

  /// The dial takes this share of the smaller side during setup
  /// (contracts/ui/00 §3).
  static const _dialShare = 0.6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final config = ref.watch(setupConfigProvider);
    final setup = ref.read(setupConfigProvider.notifier);

    final dial = DialView.editable(
      key: const Key('home.dial'),
      config: config,
      onChanged: setup.setDuration,
    );
    final controls = _SetupControls(
      config: config,
      onStart: () => _start(context, ref),
    );
    final presetId = startPresetId;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): () =>
            _start(context, ref),
      },
      child: Focus(
        autofocus: true,
        child: _PresetDeepLink(
          presetId: presetId,
          onStart: (preset) => startTimer(
            context,
            ref,
            preset.config,
            origin: PresetOrigin(preset.id),
          ),
          child: Scaffold(
            appBar: AppBar(
              title: Text(l10n.appTitle),
              actions: [
                IconButton(
                  key: const Key('home.openPresets'),
                  tooltip: l10n.homeOpenPresets,
                  icon: const Icon(Icons.grid_view_rounded),
                  onPressed: () => context.push<void>(AppRoutes.presets),
                ),
              ],
            ),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => _layout(
                  constraints.biggest,
                  dial: dial,
                  controls: controls,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _layout(Size size, {required Widget dial, required Widget controls}) {
    final layout = ScreenLayout.of(size);
    final margin = layout.margin;
    const notices = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BackgroundAlarmBanner(padding: EdgeInsets.only(bottom: 16)),
        _DialHint(),
      ],
    );

    if (layout.isSideBySide) {
      final panelWidth = layout.sidePanelWidth(size);
      final dialArea = Size(size.width - panelWidth - margin * 3, size.height);
      return Row(
        children: [
          Expanded(
            child: Center(
              child: SizedBox.square(
                dimension: dialArea.shortestSide * _dialShare,
                child: dial,
              ),
            ),
          ),
          SizedBox(
            width: panelWidth,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(margin),
              child: Column(children: [notices, controls]),
            ),
          ),
          SizedBox(width: margin),
        ],
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(margin),
      child: Column(
        children: [
          notices,
          SizedBox.square(
            dimension: size.shortestSide * _dialShare,
            child: dial,
          ),
          controls,
        ],
      ),
    );
  }

  Future<void> _start(BuildContext context, WidgetRef ref) =>
      startTimer(context, ref, ref.read(setupConfigProvider));
}

/// Digits, quick buttons, the image chip, the start button and the
/// presets.
class _SetupControls extends ConsumerWidget {
  const new({required this.config, required this.onStart});

  final TimerConfig config;
  final VoidCallback onStart;

  static const _gap = 16.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final duration = config.duration;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: _gap),
        DigitsLabel(key: const Key('home.digits'), duration: duration.value),
        const SizedBox(height: _gap),
        DurationQuickButtons(
          duration: duration,
          onChanged: ref.read(setupConfigProvider.notifier).setDuration,
          onMaxReached: () => _showMaxReached(context),
        ),
        const SizedBox(height: _gap),
        const ImageChip(),
        const SizedBox(height: _gap),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('home.start'),
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
              l10n.homeStartButton,
              semanticsLabel: l10n.homeStartSemantics(
                spokenDuration(l10n, duration.value),
              ),
            ),
          ),
        ),
        const SizedBox(height: _gap / 2),
        OutlinedButton.icon(
          key: const Key('home.savePreset'),
          style: OutlinedButton.styleFrom(
            textStyle: Theme.of(context).textTheme.titleMedium,
          ),
          onPressed: () =>
              context.push<void>(AppRoutes.presetsNew, extra: config),
          icon: const Icon(Icons.star_outline_rounded),
          label: Text(l10n.homeSavePreset),
        ),
        const SizedBox(height: _gap),
        const Align(alignment: Alignment.centerLeft, child: PresetStrip()),
      ],
    );
  }

  void _showMaxReached(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('home.maxReached'),
          content: Text(AppLocalizations.of(context).homeMaxReached),
        ),
      );
  }
}

/// The one-time "drag the edge of the dial" hint (contracts/ui/01 States).
class _DialHint extends ConsumerWidget {
  const new();

  static const _padding = 16.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDismissed = ref.watch(
      appSettingsProvider.select(
        (settings) => settings.onboarding.dialHintDismissed,
      ),
    );
    if (isDismissed) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    return Card(
      key: const Key('home.dialHint'),
      // The text and the button are read on their own, not as one card.
      semanticContainer: false,
      margin: const EdgeInsets.only(bottom: _padding),
      child: Padding(
        padding: const EdgeInsets.all(_padding),
        child: Row(
          children: [
            const Icon(Icons.touch_app_rounded),
            const SizedBox(width: _padding),
            Expanded(
              child: Text(
                l10n.homeDialHint,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            TextButton(
              key: const Key('home.dialHintDismiss'),
              onPressed: () => _dismiss(ref),
              child: Text(l10n.homeDialHintDismiss),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _dismiss(WidgetRef ref) async {
    try {
      await ref
          .read(appSettingsProvider.notifier)
          .update(
            (settings) => settings.copyWith(
              onboarding: settings.onboarding.copyWith(dialHintDismissed: true),
            ),
          );
    } on Object catch (error) {
      // The hint is hidden for this run either way; if saving failed it
      // shows again next launch, which is harmless.
      debugPrint('Could not save the hint flag: $error');
    }
  }
}

/// Starts the preset a `vtc://preset/<id>/start` link names, once per link
/// (contracts/ui/00 §2).
class _PresetDeepLink extends ConsumerStatefulWidget {
  const new({
    required this.presetId,
    required this.onStart,
    required this.child,
  });

  final String? presetId;
  final Future<void> Function(Preset preset) onStart;
  final Widget child;

  @override
  ConsumerState<_PresetDeepLink> createState() => _PresetDeepLinkState();
}

class _PresetDeepLinkState extends ConsumerState<_PresetDeepLink> {
  @override
  void initState() {
    super.initState();
    _scheduleStart();
  }

  /// Home keeps its state when only the query changes.
  @override
  void didUpdateWidget(_PresetDeepLink oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.presetId != oldWidget.presetId) _scheduleStart();
  }

  void _scheduleStart() {
    final presetId = widget.presetId;
    if (presetId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // The router checked the preset exists; it may be gone since.
      final preset = ref.read(presetsProvider.notifier).find(presetId);
      if (preset != null) unawaited(widget.onStart(preset));
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
