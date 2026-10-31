import 'dart:math';

import 'package:flutter/foundation.dart';

/// A multiplication a child of the target age cannot answer yet, asked
/// before the parent area opens (FR-062).
@immutable
final class GateChallenge {
  /// Creates a challenge of [left] × [right].
  const new({required this.left, required this.right});

  /// Draws both factors from [minFactor] to [maxFactor].
  factory random(Random random) =>
      GateChallenge(left: _randomFactor(random), right: _randomFactor(random));

  /// The smallest factor drawn.
  static const minFactor = 3;

  /// The largest factor drawn.
  static const maxFactor = 9;

  /// The first factor.
  final int left;

  /// The second factor.
  final int right;

  /// The product, the only right answer.
  int get answer => left * right;

  /// Whether the [typedDigits] are exactly the answer.
  bool isCorrect(String typedDigits) => typedDigits == '$answer';

  static int _randomFactor(Random random) =>
      minFactor + random.nextInt(maxFactor - minFactor + 1);

  @override
  bool operator ==(Object other) =>
      other is GateChallenge && other.left == left && other.right == right;

  @override
  int get hashCode => Object.hash(left, right);
}
