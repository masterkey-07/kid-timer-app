import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:visual_time_counter/core/domain/sound_id.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/domain/timer_duration.dart';
import 'package:visual_time_counter/features/timer/application/timer_controller.dart';

import '../test/helpers/fakes/fake_audio.dart';
import '../test/helpers/test_app.dart';

/// With the app open the alarm sounds within 1 s of the end, on the real
/// clock and real timers (SC-002; testing-strategy §8): 20 runs of 30 s,
/// about 10 minutes on Android and Linux.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const runs = 20;
  const timerLength = Duration(seconds: 30);
  const tolerance = Duration(seconds: 1);

  testWidgets('every run rings within 1 s of endsAt', (tester) async {
    final lateness = <Duration>[];
    for (var run = 0; run < runs; run++) {
      lateness.add(await tester.runAsync(_measureOneRun) ?? timerLength);
    }

    final worst = lateness.reduce((a, b) => a > b ? a : b);
    expect(
      lateness.every((late) => late >= Duration.zero && late <= tolerance),
      isTrue,
      reason: 'lateness per run: $lateness (worst $worst)',
    );
  }, timeout: const Timeout(Duration(minutes: 15)));
}

const _ringSettleStep = Duration(milliseconds: 10);

/// Starts a 30 s timer and returns how long after `endsAt` the alarm
/// played.
Future<Duration> _measureOneRun() async {
  const clock = Clock();
  final audio = _TimestampingAudio(clock);
  final dependencies = await TestAppDependencies.create(clock: clock)
    ..audio = audio;
  final container = ProviderContainer(overrides: dependencies.overrides());
  try {
    final controller = container.read(timerControllerProvider.notifier);
    container.listen(timerControllerProvider, (_, _) {});
    await controller.start(
      TimerConfig(duration: TimerDuration(const Duration(seconds: 30))),
    );
    final endsAt = container.read(timerControllerProvider)!.endsAt!;

    final playedAt = await audio.firstAlarm;
    // The ring goes on to vibrate; disposing before that would cut it off.
    while (!dependencies.haptics.calls.contains('alarmPattern')) {
      await Future<void>.delayed(_ringSettleStep);
    }
    return playedAt.difference(endsAt);
  } finally {
    container.dispose();
    await dependencies.dispose();
  }
}

/// Records when the first alarm sound was asked for.
class _TimestampingAudio extends FakeAudio {
  new(this._clock);

  final Clock _clock;
  final _firstAlarm = Completer<DateTime>();

  /// When the first alarm played.
  Future<DateTime> get firstAlarm => _firstAlarm.future;

  @override
  Future<void> playAlarm(
    SoundId sound, {
    required double volume,
    int repeat = 1,
  }) async {
    if (!_firstAlarm.isCompleted) _firstAlarm.complete(_clock.now().toUtc());
    await super.playAlarm(sound, volume: volume, repeat: repeat);
  }
}
