import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/app/theme/palettes.dart';
import 'package:visual_time_counter/core/clock/clock_provider.dart';
import 'package:visual_time_counter/core/domain/dial_scale.dart';
import 'package:visual_time_counter/core/domain/palette_id.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/domain/timer_duration.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';
import 'package:visual_time_counter/core/platform/providers.dart';
import 'package:visual_time_counter/core/timer_engine/session_status.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/timer/application/dial_geometry.dart';
import 'package:visual_time_counter/features/timer/presentation/spoken_duration.dart';
import 'package:visual_time_counter/features/timer/presentation/widgets/dial_painter.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// The visual dial (contracts/ui/00 §5): editable on the home screen,
/// counting down on the run screen. It fills the largest square that fits.
class DialView extends StatelessWidget {
  /// A dial the adult drags, or adjusts with the keyboard or a screen
  /// reader, to set [config]'s duration (FR-001).
  const new editable({
    required TimerConfig this.config,
    required ValueChanged<TimerDuration> this.onChanged,
    super.key,
  }) : session = null;

  /// A dial that shrinks with [session]'s remaining time (FR-002).
  const new countdown({required TimerSession this.session, super.key})
    : config = null,
      onChanged = null;

  /// The configuration being edited.
  final TimerConfig? config;

  /// Called with each new duration while editing.
  final ValueChanged<TimerDuration>? onChanged;

  /// The session counting down.
  final TimerSession? session;

  @override
  Widget build(BuildContext context) => session == null
      ? _EditableDial(config: config!, onChanged: onChanged!)
      : _CountdownDial(session: session!);
}

/// One marker per minute, at most 60 around the dial.
const _maxMarkers = 60;

int _markerCountFor(DialScale scale) {
  final minutes = scale.span.inMinutes;
  return minutes > _maxMarkers ? _maxMarkers : minutes;
}

DialStyle _styleFor(BuildContext context, DialScale scale) {
  final theme = Theme.of(context);
  final highContrast = MediaQuery.highContrastOf(context);
  final outline = theme.colorScheme.outline;
  return DialStyle(
    elapsedColor: DialPalettes.elapsed(
      theme.brightness,
      highContrast: highContrast,
    ),
    outlineColor: outline,
    outlineWidth: highContrast ? 3 : 2,
    markerColor: outline,
    markerCount: _markerCountFor(scale),
    sectorOutlineColor: highContrast ? theme.colorScheme.onSurface : null,
  );
}

/// The sector color for [config] at [remainingFraction] of the duration.
/// Image sources (US3) fall back to the default palette until images
/// arrive.
Color _sectorColor(TimerConfig config, double remainingFraction) {
  return switch (config.visual) {
    PaletteSource(:final paletteId, :final singleColor) => DialPalettes.colorAt(
      paletteId,
      remainingFraction,
      singleColor: singleColor,
    ),
    BankImageSource() || UserImageSource() => DialPalettes.colorAt(
      PaletteId.progressive,
      remainingFraction,
    ),
  };
}

/// The painted dial, isolated in its own layer so a repaint never spreads
/// to the rest of the screen.
class _DialCanvas extends StatefulWidget {
  const new({required this.frame, required this.style});

  final ValueListenable<DialFrame> frame;
  final DialStyle style;

  @override
  State<_DialCanvas> createState() => _DialCanvasState();
}

class _DialCanvasState extends State<_DialCanvas> {
  final _markers = DialMarkerCache();

  @override
  void dispose() {
    _markers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: DialPainter(
        frame: widget.frame,
        style: widget.style,
        markers: _markers,
      ),
      child: const SizedBox.expand(),
    ),
  );
}

class _EditableDial extends ConsumerStatefulWidget {
  const new({required this.config, required this.onChanged});

  final TimerConfig config;
  final ValueChanged<TimerDuration> onChanged;

  @override
  ConsumerState<_EditableDial> createState() => _EditableDialState();
}

class _EditableDialState extends ConsumerState<_EditableDial> {
  static const _pageStep = Duration(minutes: 5);

  late final ValueNotifier<DialFrame> _frame = ValueNotifier(
    _frameFor(widget.config),
  );
  final _focusNode = FocusNode(debugLabel: 'DialView');
  bool _isDragging = false;

  DialGeometry get _geometry => DialGeometry(
    scale: widget.config.scale,
    direction: widget.config.direction,
  );

  TimerDuration get _duration => widget.config.duration;

  @override
  void didUpdateWidget(_EditableDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    _frame.value = _frameFor(widget.config);
  }

  @override
  void dispose() {
    _frame.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  DialFrame _frameFor(TimerConfig config) => DialFrame(
    sweepAngle: DialGeometry(
      scale: config.scale,
      direction: config.direction,
    ).sweepAngleOf(config.duration.value),
    sectorColor: _sectorColor(config, 1),
  );

  /// Applies [duration] within the dial's scale.
  void _change(TimerDuration duration) {
    final max = _geometry.maxDuration;
    final limited = duration.value > max ? TimerDuration(max) : duration;
    if (limited != _duration) widget.onChanged(limited);
  }

  void _increment() => _change(_duration.increment());

  void _decrement() => _change(_duration.decrement());

  void _onPanStart(DragStartDetails details, double radius) {
    _isDragging = _geometry.isOnRing(
      details.localPosition - Offset(radius, radius),
      radius: radius,
    );
    if (_isDragging) _focusNode.requestFocus();
  }

  void _onPanUpdate(DragUpdateDetails details, double radius) {
    if (!_isDragging) return;
    final next = _geometry.durationAt(
      details.localPosition - Offset(radius, radius),
      previous: _duration.value,
    );
    if (next.value.inMinutes != _duration.value.inMinutes) {
      ref.read(hapticsProvider).selectionTick().ignore();
    }
    _change(next);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowRight) {
      _increment();
    } else if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft) {
      _decrement();
    } else if (key == LogicalKeyboardKey.pageUp) {
      _change(_duration.adjustedBy(_pageStep));
    } else if (key == LogicalKeyboardKey.pageDown) {
      _change(_duration.adjustedBy(-_pageStep));
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      container: true,
      slider: true,
      label: l10n.homeDurationLabel,
      value: spokenDuration(l10n, _duration.value),
      increasedValue: spokenDuration(l10n, _duration.increment().value),
      decreasedValue: spokenDuration(l10n, _duration.decrement().value),
      onIncrease: _increment,
      onDecrease: _decrement,
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final radius = constraints.biggest.shortestSide / 2;
            return Focus(
              focusNode: _focusNode,
              onKeyEvent: _onKey,
              child: GestureDetector(
                // The slider semantics already adjust the dial; the drag's
                // scroll actions would only confuse screen readers.
                excludeFromSemantics: true,
                onPanStart: (details) => _onPanStart(details, radius),
                onPanUpdate: (details) => _onPanUpdate(details, radius),
                onPanEnd: (_) => _isDragging = false,
                child: _DialCanvas(
                  frame: _frame,
                  style: _styleFor(context, widget.config.scale),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CountdownDial extends ConsumerStatefulWidget {
  const new({required this.session});

  final TimerSession session;

  @override
  ConsumerState<_CountdownDial> createState() => _CountdownDialState();
}

class _CountdownDialState extends ConsumerState<_CountdownDial>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((_) => _tick());
  late final ValueNotifier<DialFrame> _frame = ValueNotifier(
    _frameAt(_remaining),
  );
  late int _shownSecond = _remaining.inSeconds;

  Duration get _remaining =>
      widget.session.remaining(ref.read(clockProvider).now());

  DialGeometry get _geometry => DialGeometry(
    scale: widget.session.config.scale,
    direction: widget.session.config.direction,
  );

  bool get _isRunning => widget.session.status == SessionStatus.running;

  @override
  void initState() {
    super.initState();
    if (_isRunning) _ticker.start();
  }

  @override
  void didUpdateWidget(_CountdownDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    _frame.value = _frameAt(_remaining);
    if (_isRunning && !_ticker.isActive) _ticker.start();
    if (!_isRunning && _ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  DialFrame _frameAt(Duration remaining) {
    final config = widget.session.config;
    return DialFrame(
      sweepAngle: _geometry.sweepAngleOf(remaining),
      sectorColor: _sectorColor(
        config,
        remaining.inMicroseconds / config.duration.value.inMicroseconds,
      ),
    );
  }

  /// Every frame the sector moves smoothly; with reduce motion it moves once
  /// per second. The semantics value follows each whole second.
  void _tick() {
    final remaining = _remaining;
    final second = remaining.inSeconds;
    final secondChanged = second != _shownSecond;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (!reduceMotion || secondChanged) _frame.value = _frameAt(remaining);
    if (secondChanged) setState(() => _shownSecond = second);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isPaused = widget.session.status == SessionStatus.paused;
    return Semantics(
      container: true,
      label: l10n.runRemainingLabel,
      value: spokenDuration(l10n, _remaining),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _DialCanvas(
              frame: _frame,
              style: _styleFor(context, widget.session.config.scale),
            ),
            if (isPaused) const _PausedBadge(),
          ],
        ),
      ),
    );
  }
}

/// The ⏸ shown over a paused dial, on a surface scrim so it stays legible
/// over any image (contracts/ui/00 §3.2).
class _PausedBadge extends StatelessWidget {
  const new();

  static const _scrimOpacity = 0.7;
  static const _iconSize = 64.0;
  static const _padding = 16.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: DecoratedBox(
        key: const Key('run.pausedBadge'),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: _scrimOpacity),
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(_padding),
          child: Icon(
            Icons.pause_rounded,
            size: _iconSize,
            color: colors.onSurface,
            semanticLabel: AppLocalizations.of(context).runPausedLabel,
          ),
        ),
      ),
    );
  }
}
