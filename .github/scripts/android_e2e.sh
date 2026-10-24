#!/usr/bin/env bash
# Runs the Android integration tests and the Patrol E2E suite on the emulator
# started by e2e-android.yml. Suites without test files are skipped.
set -euo pipefail

device="${ANDROID_DEVICE:-emulator-5554}"
package="io.github.masterkey07.visualtimecounter"

# The desktop runner cannot attach to a second app in one `flutter test`
# call, so each integration file runs on its own (same on the emulator, for
# isolation between files).
if ls integration_test/*_test.dart >/dev/null 2>&1; then
  for file in integration_test/*_test.dart; do
    flutter test "$file" -d "$device"
  done
else
  echo "No integration tests yet."
fi

if ! ls patrol_test/*_test.dart >/dev/null 2>&1; then
  echo "No Patrol tests yet."
  exit 0
fi

patrol_run() {
  patrol test --device "$device" "$@"
}

# The permission test needs a fresh install, where notifications were never
# granted; the others grant the permission themselves.
if [[ -f patrol_test/e2e_us2_permissions_android_test.dart ]]; then
  patrol_run -t patrol_test/e2e_us2_permissions_android_test.dart
fi

# The killed-app test spans two processes: start a timer, let the system kill
# the app (`am kill` keeps its alarms, unlike `force-stop`), wait for the end
# and verify through the notification.
closed_app_test=patrol_test/e2e_us2_alarm_closed_app_test.dart
if [[ -f "$closed_app_test" ]]; then
  patrol_run -t "$closed_app_test" --dart-define=E2E_PHASE=start --no-uninstall
  adb -s "$device" shell am kill "$package"
  sleep 65
  patrol_run -t "$closed_app_test" --dart-define=E2E_PHASE=verify
fi

for file in patrol_test/*_test.dart; do
  case "$file" in
    "$closed_app_test" | patrol_test/e2e_us2_permissions_android_test.dart) ;;
    *) patrol_run -t "$file" ;;
  esac
done
