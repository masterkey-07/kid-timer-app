import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The child lock of the countdown screen, alive while `/run` shows it.
final NotifierProvider<UnlockController, UnlockState> unlockControllerProvider =
    NotifierProvider.autoDispose<UnlockController, UnlockState>(
      UnlockController.new,
    );

/// Where the countdown screen stands in the child lock (FR-030, FR-031).
enum UnlockPhase {
  /// Child mode: no controls, touches absorbed.
  locked,

  /// The adult is holding the padlock or Esc; the ring is filling.
  holding,

  /// The controls are shown until they hide again.
  unlocked,
}

/// What the adult holds to unlock.
enum HoldSource {
  /// The padlock in the top corner, touched or pressed with a screen reader.
  padlock,

  /// The Esc key.
  escapeKey,
}

/// The child lock state.
@immutable
final class UnlockState {
  /// Creates a state.
  const new({this.phase = UnlockPhase.locked, this.window = 0});

  /// The current phase.
  final UnlockPhase phase;

  /// Grows each time the controls' 10 s start over, so the countdown bar
  /// knows when to restart.
  final int window;

  /// Whether the controls are shown.
  bool get areControlsVisible => phase == UnlockPhase.unlocked;

  @override
  bool operator ==(Object other) =>
      other is UnlockState && other.phase == phase && other.window == window;

  @override
  int get hashCode => Object.hash(phase, window);
}

/// Unlocks after a 3 s hold and locks again 10 s after the last interaction
/// (contracts/ui/02 Behavior 2 and 3).
class UnlockController extends Notifier<UnlockState> {
  /// How long the padlock or Esc must be held.
  static const holdDuration = Duration(seconds: 3);

  /// How long the controls stay without interaction.
  static const controlsDuration = Duration(seconds: 10);

  /// The padlock and Esc may be held at once; the hold lasts while either
  /// is held.
  final _heldSources = <HoldSource>{};
  Timer? _timer;

  @override
  UnlockState build() {
    ref.onDispose(() => _timer?.cancel());
    return const UnlockState();
  }

  /// [source] is pressed; from child mode, starts filling the ring.
  void startHold(HoldSource source) {
    if (state.phase == UnlockPhase.unlocked) return registerInteraction();
    _heldSources.add(source);
    if (state.phase == UnlockPhase.holding) return;

    state = UnlockState(phase: UnlockPhase.holding, window: state.window);
    _restartTimer(holdDuration, _unlock);
  }

  /// [source] is released; when nothing is held any more before the ring
  /// completes, the hold starts over.
  void endHold(HoldSource source) {
    _heldSources.remove(source);
    if (state.phase != UnlockPhase.holding || _heldSources.isNotEmpty) return;

    _timer?.cancel();
    state = UnlockState(window: state.window);
  }

  /// The adult touched or typed while the controls are shown: they stay
  /// another 10 s.
  void registerInteraction() {
    if (state.phase != UnlockPhase.unlocked) return;
    _showControls();
  }

  void _unlock() {
    // A hold still pressed now must not unlock again once the controls hide.
    _heldSources.clear();
    _showControls();
  }

  void _showControls() {
    state = UnlockState(phase: UnlockPhase.unlocked, window: state.window + 1);
    _restartTimer(controlsDuration, _lock);
  }

  void _lock() => state = UnlockState(window: state.window);

  void _restartTimer(Duration duration, VoidCallback onEnd) {
    _timer?.cancel();
    _timer = Timer(duration, onEnd);
  }
}
