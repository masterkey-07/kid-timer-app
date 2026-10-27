import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_time_counter/features/child_lock/application/unlock_controller.dart';

const _justUnder = Duration(milliseconds: 2999);
const _oneMillisecond = Duration(milliseconds: 1);

void main() {
  late ProviderContainer container;
  late ProviderSubscription<UnlockState> subscription;

  UnlockController controller() =>
      container.read(unlockControllerProvider.notifier);

  UnlockPhase phase() => container.read(unlockControllerProvider).phase;

  /// Runs [body] in fake time with a container kept alive by a listener,
  /// as the countdown screen keeps it.
  void inFakeTime(void Function(FakeAsync async) body) {
    fakeAsync((async) {
      container = ProviderContainer();
      subscription = container.listen(unlockControllerProvider, (_, _) {});
      body(async);
      subscription.close();
      container.dispose();
    });
  }

  void unlock(FakeAsync async) {
    controller().startHold(HoldSource.padlock);
    async.elapse(UnlockController.holdDuration);
    controller().endHold(HoldSource.padlock);
  }

  test('starts locked', () {
    inFakeTime((async) {
      expect(phase(), UnlockPhase.locked);
      expect(
        container.read(unlockControllerProvider).areControlsVisible,
        false,
      );
    });
  });

  test('holding the padlock for 3 s shows the controls (FR-031)', () {
    inFakeTime((async) {
      controller().startHold(HoldSource.padlock);
      expect(phase(), UnlockPhase.holding);

      async.elapse(_justUnder);
      expect(phase(), UnlockPhase.holding);

      async.elapse(_oneMillisecond);
      expect(phase(), UnlockPhase.unlocked);
      expect(container.read(unlockControllerProvider).areControlsVisible, true);
    });
  });

  test('releasing before 3 s resets the hold', () {
    inFakeTime((async) {
      controller().startHold(HoldSource.padlock);
      async.elapse(_justUnder);
      controller().endHold(HoldSource.padlock);
      expect(phase(), UnlockPhase.locked);

      // A new hold starts over instead of finishing the old one.
      controller().startHold(HoldSource.padlock);
      async.elapse(const Duration(seconds: 2));
      expect(phase(), UnlockPhase.holding);
      async.elapse(const Duration(seconds: 1));
      expect(phase(), UnlockPhase.unlocked);
    });
  });

  test('holding Esc for 3 s shows the controls, as the padlock', () {
    inFakeTime((async) {
      controller().startHold(HoldSource.escapeKey);
      async.elapse(UnlockController.holdDuration);

      expect(phase(), UnlockPhase.unlocked);
    });
  });

  test('the hold lasts while either the padlock or Esc is held', () {
    inFakeTime((async) {
      controller()
        ..startHold(HoldSource.padlock)
        ..startHold(HoldSource.escapeKey);
      async.elapse(const Duration(seconds: 1));
      controller().endHold(HoldSource.padlock);
      expect(phase(), UnlockPhase.holding);

      async.elapse(const Duration(seconds: 2));
      expect(phase(), UnlockPhase.unlocked);
    });
  });

  test('the controls hide again 10 s after unlocking', () {
    inFakeTime((async) {
      unlock(async);

      async.elapse(UnlockController.controlsDuration - _oneMillisecond);
      expect(phase(), UnlockPhase.unlocked);

      async.elapse(_oneMillisecond);
      expect(phase(), UnlockPhase.locked);
    });
  });

  test('an interaction restarts the 10 s', () {
    inFakeTime((async) {
      unlock(async);
      final firstWindow = container.read(unlockControllerProvider).window;

      async.elapse(const Duration(seconds: 8));
      controller().registerInteraction();
      expect(
        container.read(unlockControllerProvider).window,
        isNot(firstWindow),
      );

      async.elapse(const Duration(seconds: 9));
      expect(phase(), UnlockPhase.unlocked);

      async.elapse(const Duration(seconds: 1));
      expect(phase(), UnlockPhase.locked);
    });
  });

  test('interactions while locked do nothing', () {
    inFakeTime((async) {
      controller().registerInteraction();
      async.elapse(UnlockController.controlsDuration);

      expect(phase(), UnlockPhase.locked);
    });
  });

  test('a hold that is still pressed when the controls hide does not '
      'unlock again by itself', () {
    inFakeTime((async) {
      controller().startHold(HoldSource.padlock);
      async
        ..elapse(UnlockController.holdDuration)
        ..elapse(UnlockController.controlsDuration);
      expect(phase(), UnlockPhase.locked);

      async.elapse(UnlockController.holdDuration);
      expect(phase(), UnlockPhase.locked);
    });
  });

  test('disposing cancels the pending timers', () {
    fakeAsync((async) {
      container = ProviderContainer();
      subscription = container.listen(unlockControllerProvider, (_, _) {});
      container
          .read(unlockControllerProvider.notifier)
          .startHold(HoldSource.padlock);
      subscription.close();
      container.dispose();

      expect(async.pendingTimers, isEmpty);
    });
  });
}
