import 'package:flutter/widgets.dart';

/// Absorbs every touch, drag, pinch and scroll over the countdown in child
/// mode, reporting each touch so the padlock can glow (contracts/ui/02
/// Behavior 2). Stack it above the content.
class TouchShield extends StatelessWidget {
  /// Creates the shield.
  const new({required this.onTouch, super.key = const Key('run.touchShield')});

  /// Called on every pointer that goes down on the shield.
  final VoidCallback onTouch;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => onTouch(),
      child: const SizedBox.expand(),
    ),
  );
}
