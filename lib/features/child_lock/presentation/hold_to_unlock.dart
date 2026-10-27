import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/features/child_lock/application/unlock_controller.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

const _touchTargetSize = 56.0;
const _ringStrokeWidth = 4.0;

/// The reduce-motion text counts one step per second of the hold.
const _holdSteps = 3;

/// Asks the padlock to glow; the touch shield requests it on every absorbed
/// touch.
class PadlockGlow extends ChangeNotifier {
  /// Makes the padlock glow, unless it already is.
  void request() => notifyListeners();
}

/// The discreet padlock of child mode: holding it for 3 s fills a ring and
/// shows the controls (contracts/ui/02, FR-031).
///
/// Keys: `run.lock`, and `run.lockProgress` while held.
class HoldToUnlock extends ConsumerStatefulWidget {
  /// Creates the padlock, glowing whenever [glow] asks.
  const new({required this.glow, super.key = const Key('run.lock')});

  /// Glow requests from absorbed touches.
  final PadlockGlow glow;

  @override
  ConsumerState<HoldToUnlock> createState() => _HoldToUnlockState();
}

class _HoldToUnlockState extends ConsumerState<HoldToUnlock>
    with TickerProviderStateMixin {
  static const _idleOpacity = 0.35;
  static const _glowOpacity = 0.8;

  /// Fade in, hold and fade out, 100 ms each (contracts/ui/02 Behavior 2).
  static const _glowDuration = Duration(milliseconds: 300);

  static const _iconSize = 40.0;

  static final _glowCurve = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: _idleOpacity,
        end: _glowOpacity,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 1,
    ),
    TweenSequenceItem(tween: ConstantTween(_glowOpacity), weight: 1),
    TweenSequenceItem(
      tween: Tween(
        begin: _glowOpacity,
        end: _idleOpacity,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 1,
    ),
  ]);

  // Both keep their real duration under reduce motion: the ring shows the
  // 3 s the hold really takes, and the glow only drops its easing.
  late final _ring = AnimationController(
    vsync: this,
    duration: UnlockController.holdDuration,
    animationBehavior: AnimationBehavior.preserve,
  );
  late final _glow = AnimationController(
    vsync: this,
    duration: _glowDuration,
    animationBehavior: AnimationBehavior.preserve,
  );

  /// Fingers on the padlock; the hold ends when the last one lifts.
  final _pointers = <int>{};

  UnlockController get _unlock => ref.read(unlockControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    widget.glow.addListener(_startGlow);
  }

  @override
  void didUpdateWidget(HoldToUnlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.glow == widget.glow) return;
    oldWidget.glow.removeListener(_startGlow);
    widget.glow.addListener(_startGlow);
  }

  @override
  void dispose() {
    widget.glow.removeListener(_startGlow);
    _ring.dispose();
    _glow.dispose();
    super.dispose();
  }

  /// Repeated touches never glow faster than once per [_glowDuration].
  void _startGlow() {
    if (_glow.isAnimating) return;
    _glow.forward(from: 0);
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointers.add(event.pointer);
    if (_pointers.length == 1) _unlock.startHold(HoldSource.padlock);
  }

  /// The padlock leaves when the controls show, often with the finger still
  /// down; unlocking already ended the hold, so a late release is ignored.
  void _onPointerUp(PointerEvent event) {
    if (!mounted) return;
    if (!_pointers.remove(event.pointer) || _pointers.isNotEmpty) return;
    _unlock.endHold(HoldSource.padlock);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(unlockControllerProvider.select((state) => state.phase), (
      _,
      phase,
    ) {
      if (phase == UnlockPhase.holding) {
        _ring.forward(from: 0);
      } else {
        _ring.reset();
      }
    });
    final isHolding =
        ref.watch(unlockControllerProvider).phase == UnlockPhase.holding;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final color = Theme.of(context).colorScheme.onSurface;

    return Semantics(
      container: true,
      label: AppLocalizations.of(context).runUnlockHint,
      child: Focus(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: _onPointerDown,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerUp,
              child: SizedBox.square(
                dimension: _touchTargetSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isHolding && !reduceMotion)
                      _RingProgress(ring: _ring, color: color),
                    AnimatedBuilder(
                      animation: _glow,
                      builder: (context, child) => Opacity(
                        opacity: _opacity(reduceMotion: reduceMotion),
                        child: child,
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        size: _iconSize,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isHolding && reduceMotion)
              _StepsProgress(ring: _ring, color: color),
          ],
        ),
      ),
    );
  }

  /// With reduce motion the glow steps to full and back without easing.
  double _opacity({required bool reduceMotion}) {
    if (!_glow.isAnimating) return _idleOpacity;
    return reduceMotion ? _glowOpacity : _glowCurve.evaluate(_glow);
  }
}

/// The ring filling over the 3 s hold.
class _RingProgress extends StatelessWidget {
  const new({required this.ring, required this.color});

  final Animation<double> ring;
  final Color color;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: ring,
    builder: (context, _) => SizedBox.expand(
      child: CircularProgressIndicator(
        key: const Key('run.lockProgress'),
        value: ring.value,
        strokeWidth: _ringStrokeWidth,
        color: color,
        semanticsValue: _percent(ring.value),
      ),
    ),
  );
}

/// "1… 2… 3" beside the padlock in place of the ring when motion is
/// reduced.
class _StepsProgress extends StatelessWidget {
  const new({required this.ring, required this.color});

  final Animation<double> ring;
  final Color color;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: ring,
    builder: (context, _) {
      final reached = (ring.value * _holdSteps).floor().clamp(0, _holdSteps);
      return Semantics(
        key: const Key('run.lockProgress'),
        value: _percent(ring.value),
        child: ExcludeSemantics(
          child: Text(
            [
              for (var step = 1; step <= reached; step++)
                '$step${step < _holdSteps ? '…' : ''}',
            ].join(' '),
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: color),
          ),
        ),
      );
    },
  );
}

String _percent(double share) => '${(share * 100).round()}%';
