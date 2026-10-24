import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_time_counter/app/router.dart';
import 'package:visual_time_counter/app/theme/palettes.dart';
import 'package:visual_time_counter/core/domain/palette_id.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';
import 'package:visual_time_counter/core/platform/providers.dart';
import 'package:visual_time_counter/core/platform/wakelock/wakelock_port.dart';
import 'package:visual_time_counter/features/timer/application/timer_controller.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// The final screen: time is up, and it stays until someone taps
/// (contracts/ui/03, FR-005).
class FinishedScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const new({super.key = const Key('finished.screen')});

  @override
  ConsumerState<FinishedScreen> createState() => _FinishedScreenState();
}

class _FinishedScreenState extends ConsumerState<FinishedScreen>
    with SingleTickerProviderStateMixin {
  /// Taps this soon after the screen appears are accidental.
  static const _tapGuard = Duration(milliseconds: 800);

  /// The "tap to go back" hint appears after this delay.
  static const _hintDelay = Duration(seconds: 2);

  /// The sound repeats at this interval while the app is open…
  static const _soundRepeatEvery = Duration(seconds: 30);

  /// …this many more times after the first ring.
  static const _soundRepeats = 2;

  /// The screen stays on this long, then may turn off.
  static const _wakeLockFor = Duration(minutes: 10);

  static const _celebration = Duration(milliseconds: 2400);
  static const _spinShare = 0.5;

  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: _celebration,
  );
  final List<Timer> _timers = [];
  bool _isArmed = false;
  bool _showsHint = false;
  bool _isLeaving = false;
  int _soundsRepeated = 0;
  late final TimerConfig? _config;
  late final WakeLockPort _wakeLock;

  @override
  void initState() {
    super.initState();
    _config = ref.read(timerControllerProvider)?.config;
    _wakeLock = ref.read(wakeLockProvider);
    _timers
      ..add(Timer(_tapGuard, () => _isArmed = true))
      ..add(Timer(_hintDelay, () => setState(() => _showsHint = true)))
      ..add(Timer.periodic(_soundRepeatEvery, _repeatSound))
      ..add(Timer(_wakeLockFor, _releaseWakeLock));
    unawaited(_wakeLock.enable());
    unawaited(
      ref.read(timerControllerProvider.notifier).dismissNotifications(),
    );
    _animation.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _announce());
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _animation.dispose();
    unawaited(_wakeLock.disable());
    super.dispose();
  }

  void _announce() {
    if (!mounted) return;
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        AppLocalizations.of(context).finishedTitle,
        Directionality.of(context),
        assertiveness: Assertiveness.assertive,
      ),
    );
  }

  void _repeatSound(Timer timer) {
    final config = _config;
    if (_soundsRepeated >= _soundRepeats || config == null) {
      timer.cancel();
      return;
    }
    _soundsRepeated++;
    if (config.soundId.isAudible) {
      unawaited(
        ref
            .read(audioProvider)
            .playAlarm(config.soundId, volume: config.alarmVolume),
      );
    }
  }

  void _releaseWakeLock() => unawaited(_wakeLock.disable());

  Future<void> _acknowledge() async {
    if (!_isArmed || _isLeaving) return;
    _isLeaving = true;
    await ref.read(timerControllerProvider.notifier).acknowledge();
    if (mounted) context.go(AppRoutes.home);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final isDismissKey =
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.escape;
    if (!isDismissKey) return KeyEventResult.ignored;
    unawaited(_acknowledge());
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_acknowledge());
      },
      child: Focus(
        autofocus: true,
        onKeyEvent: _onKey,
        child: Scaffold(
          body: Semantics(
            button: true,
            label: l10n.finishedSemantics,
            excludeSemantics: true,
            onTap: () => unawaited(_acknowledge()),
            child: GestureDetector(
              key: const Key('finished.dismissArea'),
              behavior: HitTestBehavior.opaque,
              onTap: () => unawaited(_acknowledge()),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Celebration(
                          animation: _animation,
                          color: _celebrationColor(_config),
                          reduceMotion: reduceMotion,
                          spinShare: _spinShare,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.finishedTitle,
                          key: const Key('finished.title'),
                          style: theme.textTheme.displaySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        AnimatedOpacity(
                          opacity: _showsHint ? 1 : 0,
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 400),
                          child: Text(
                            l10n.finishedTapToReturn,
                            key: const Key('finished.hint'),
                            style: theme.textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The timer's own color, full: images arrive with US3.
  static Color _celebrationColor(TimerConfig? config) =>
      switch (config?.visual) {
        PaletteSource(:final paletteId, :final singleColor) =>
          DialPalettes.colorAt(paletteId, 1, singleColor: singleColor),
        _ => DialPalettes.colorAt(PaletteId.progressive, 1),
      };
}

/// The full dial with a check mark: one gentle spin and soft particles, or
/// a plain fade-in with reduce motion (contracts/ui/03).
class _Celebration extends StatelessWidget {
  const new({
    required this.animation,
    required this.color,
    required this.reduceMotion,
    required this.spinShare,
  });

  final Animation<double> animation;
  final Color color;
  final bool reduceMotion;

  /// The share of the animation spent spinning (1.2 s of 2.4 s).
  final double spinShare;

  static const _size = 200.0;
  static const _particleArea = 280.0;

  @override
  Widget build(BuildContext context) {
    final onColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
    final dial = DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 2,
        ),
      ),
      child: Icon(Icons.check_rounded, size: _size * 0.6, color: onColor),
    );

    return SizedBox.square(
      key: const Key('finished.image'),
      dimension: _particleArea,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final t = animation.value;
          if (reduceMotion) return Opacity(opacity: t, child: child);
          final spin = Curves.easeOutCubic.transform(
            (t / spinShare).clamp(0.0, 1.0),
          );
          return CustomPaint(
            painter: _ParticlesPainter(progress: t, color: color),
            child: Transform.rotate(angle: spin * 2 * pi, child: child),
          );
        },
        child: Center(
          child: SizedBox.square(dimension: _size, child: dial),
        ),
      ),
    );
  }
}

/// Up to 20 particles that fade in and out once, never blinking
/// (contracts/ui/00 §4 flash safety).
class _ParticlesPainter extends CustomPainter {
  new({required this.progress, required this.color});

  final double progress;
  final Color color;

  static const _count = 16;
  static const _radius = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    // One fade in and one fade out across the whole 2.4 s animation.
    final opacity = sin(progress * pi);
    if (opacity <= 0) return;
    final center = size.center(Offset.zero);
    final distance = size.shortestSide / 2 * (0.75 + 0.2 * progress);
    final paint = Paint()..color = color.withValues(alpha: opacity);
    for (var i = 0; i < _count; i++) {
      final angle = i * 2 * pi / _count;
      canvas.drawCircle(
        center + Offset(cos(angle), sin(angle)) * distance,
        _radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
