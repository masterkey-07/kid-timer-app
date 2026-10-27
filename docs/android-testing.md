# Running the Android tests locally

How to run the integration tests (`integration_test/`) and the Patrol E2E tests
(`patrol_test/`) on a local Android emulator, and the mistakes that already cost failed runs.
CI runs the same suites through `.github/scripts/android_e2e.sh` (see
`specs/001-visual-timer/testing-strategy.md` for what each test covers).

Agents: read this file before running anything with `-d emulator-…` or `patrol test`, and add
any new failure to [Known failures](#known-failures) in the same commit as its fix.

## Setup

- Android SDK with `cmdline-tools/latest`, `platform-tools`, `emulator`, `platforms;android-36`,
  `build-tools;36.0.0` and `system-images;android-34;google_apis;x86_64`. Export
  `ANDROID_HOME` and put `cmdline-tools/latest/bin`, `platform-tools` and `emulator` on `PATH`
  (e.g. in `~/.zshrc`), then `fvm flutter config --android-sdk "$ANDROID_HOME"` and
  `fvm flutter doctor --android-licenses`.
- A JDK 17 or newer. Java 25 works with this project (Gradle 9.3.1, AGP 9.1; the app compiles
  to Java 17 bytecode). With SDKMAN: `fvm flutter config --jdk-dir "$HOME/.sdkman/candidates/java/current"`.
- An Android 14 (API 34) AVD; the permission E2E expects Android 14:
  `avdmanager create avd -n pixel_api34 -k "system-images;android-34;google_apis;x86_64" -d pixel_7`.
- Linux: KVM must be usable (`emulator -accel-check`); if not, `sudo usermod -aG kvm $USER` and
  log in again.
- Patrol CLI: `fvm dart pub global activate patrol_cli` (installs `~/.pub-cache/bin/patrol`).

## Run

Non-interactive shells (agents' Bash calls) do not read `~/.zshrc`; source it in every call that
uses `adb`, `emulator` or `patrol`.

1. Start the emulator with software rendering and wait for boot:

   ```bash
   emulator -avd pixel_api34 -no-snapshot-save -no-boot-anim -gpu swiftshader_indirect &
   adb wait-for-device
   until [ "$(adb shell getprop sys.boot_completed | tr -d '\r')" = 1 ]; do sleep 2; done
   ```

2. Integration tests, one file per run:

   ```bash
   fvm flutter test integration_test/child_lock_integration_test.dart -d emulator-5554
   ```

3. Patrol E2E, one file per run, with the FVM Flutter first on `PATH` (Patrol calls `flutter`):

   ```bash
   export PATH="$PWD/.fvm/flutter_sdk/bin:$PATH"
   patrol test --device emulator-5554 -t patrol_test/e2e_us4_child_lock_test.dart
   ```

4. Everything, in CI order (seeds the photo for the own-image test, runs the permission test on
   a fresh install, runs the killed-app test in two phases with a 65 s wait):

   ```bash
   ANDROID_DEVICE=emulator-5554 bash .github/scripts/android_e2e.sh
   ```

The first Gradle build takes several minutes and each Patrol run about a minute. Agents: keep
each tool call under its timeout (one Patrol file per call), or run it in the background and
wait for the completion notice; write output to a log and grep it for both success and failure
markers (`All tests passed|Some tests failed|Successful|Failed:|Exception`).

## Rules

- Start the emulator with `-gpu swiftshader_indirect`.
- While the emulator runs, run host tests with `fvm flutter test -j 4` (or only the changed
  paths), never the unbounded suite.
- Check that the emulator is alive with `adb devices` and `ps -C qemu-system-x86_64`, not
  `pgrep -f qemu`, which also matches the shell running the check.
- Helpers imported by `integration_test/` or `patrol_test/` read repository files through
  `rootBundle`, never `dart:io` `File`: host paths do not exist on a device.
- E2E tests that touch the top of the countdown call `dismissFullScreenHint($)` from
  `patrol_test/support/system_ui.dart` once `run.screen` is visible.
- When a device test fails without a clear message, capture the screen while it waits
  (`adb exec-out screencap -p > shot.png`) and look at it before changing code.
- Never commit `patrol_test/test_bundle.dart` (generated on every run, ignored) or
  `goldens/linux/` files.
- Mark an Android task `[x]` in `tasks.md` only after it passed on an emulator, and say in the
  task line where it ran.

## Known failures

| Symptom | Cause | Fix |
| --- | --- | --- |
| The emulator vanishes; `adb devices` is empty; `journalctl -k` shows the OOM killer | The full host test suite (one `flutter_tester` per core) plus the emulator ran out of RAM (seen on a 14 GB machine) | Restart the emulator; run host tests with `-j 4` while it is up |
| The emulator dies; its log ends with `gfxstream … gles_v2_imp.cpp … error null ctx` | The host GPU mode picked an NVIDIA GPU through Vulkan and crashed | Start with `-gpu swiftshader_indirect` |
| `PathNotFoundException: … assets/images/bank/manifest.json`, then `LateInitializationError: Local 'dependencies'` | `test/helpers/test_app.dart` read the manifest with `File` (fixed in `259c2af`) | Load repository files with `rootBundle.loadString` |
| Holding the padlock does nothing; `waitUntilVisible run.pauseResume` times out | Android's one-time "Viewing full screen · Got it" banner covers the top of the screen; Patrol reinstalls the app, so it can show on every run | `dismissFullScreenHint($)` before the gestures |
| After Start, `run.screen` is not visible within 10 s (seen once; the rerun passed) | Not confirmed; likely the notification permission dialog appearing after `isPermissionDialogVisible()` (1 s default timeout) returned false | Capture the screen if it recurs; then pass a longer `timeout` |
| `patrol_test/test_bundle.dart` shows in `git status` or `dart format` changes it | Patrol generates it on every run | It is ignored; never `git add -A` without reading the status |
| Linux: `windowManager.isFullScreen()` is false right after entering `/run` | Wayland applies full screen asynchronously | Poll for up to 3 s (`expectFullScreen` in `integration_test/child_lock_integration_test.dart`) |

## Widget-test traps that also bite on devices

- An `AnimationController` starts its clock on the frame after `forward()`: `pump()` once before
  a timed `pump(duration)` that reads an animation value.
- With reduce motion on, Flutter runs controllers at 5% of their duration. Animations that show
  real time (hold ring, glow, relock bar) use `animationBehavior: AnimationBehavior.preserve`.
- A widget can unmount while a finger is still down (the padlock does on unlock): guard
  pointer-up handlers with `if (!mounted) return;` and never use `ref` in `dispose()`.
