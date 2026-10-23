#!/usr/bin/env bash
# Runs the Android integration tests and the Patrol E2E suite on the emulator
# started by e2e-android.yml. Suites without test files are skipped.
set -euo pipefail

device="${ANDROID_DEVICE:-emulator-5554}"

if ls integration_test/*_test.dart >/dev/null 2>&1; then
  flutter test integration_test -d "$device"
else
  echo "No integration tests yet."
fi

if ls patrol_test/*_test.dart >/dev/null 2>&1; then
  patrol test -t patrol_test/ --device "$device"
else
  echo "No Patrol tests yet."
fi
