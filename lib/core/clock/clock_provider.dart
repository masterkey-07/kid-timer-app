import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The source of the current time for the whole app (Constitution III).
///
/// Override it in tests with a fixed or controllable [Clock].
final clockProvider = Provider<Clock>((ref) => const Clock());
