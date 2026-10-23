# Quickstart & Validation Guide: Kid Timer

**Feature**: `001-visual-timer` | **Plan**: [plan.md](./plan.md)

Guide to set up the environment, run the app and validate each story end to end. Contract and
data details live in [contracts/](./contracts/) and [data-model.md](./data-model.md).

## 1. Prerequisites

| Tool                                                                      | Version                                     | Use                         |
| ------------------------------------------------------------------------- | ------------------------------------------- | --------------------------- |
| FVM                                                                       | latest                                      | Pins Flutter from `.fvmrc`  |
| Flutter                                                                   | 3.47.x (via FVM)                            | SDK                         |
| Android Studio + SDK                                                      | API 36, API 34 x86_64 emulator              | Android                     |
| Xcode                                                                     | 26+ (macOS)                                 | iOS/macOS                   |
| Visual Studio 2022 (C++ desktop)                                          | latest                                      | Windows                     |
| `clang`, `cmake`, `ninja-build`, `libgtk-3-dev`, `gstreamer1.0-*`, `xvfb` | distro                                      | Linux                       |
| Chrome + chromedriver                                                     | latest                                      | Web and web tests           |
| Patrol CLI                                                                | 4.x (`dart pub global activate patrol_cli`) | E2E                         |
| Node.js                                                                   | 22+                                         | only for `tool/image_bank/` |

## 2. Setup

```bash
fvm install && fvm use
fvm flutter pub get
fvm flutter gen-l10n
fvm flutter doctor
```

## 3. Run

```bash
fvm flutter run -d android        # or ios, macos, windows, linux, chrome
fvm flutter run --profile -d <id> # measure performance
```

## 4. Local checks (same as CI)

```bash
dart format --set-exit-if-changed .
fvm flutter analyze
fvm flutter test --coverage                      # unit + contract + widget + golden
dart run tool/check_coverage.dart
dart run tool/privacy_check.dart                 # requires a prior release APK build for the manifest
dart run tool/license_check.dart
dart run tool/l10n_check.dart
xvfb-run fvm flutter test integration_test -d linux
fvm flutter test integration_test -d emulator-5554
patrol test -t patrol_test/ --device emulator-5554
```

Update goldens after an intentional visual change: `fvm flutter test --update-goldens
test/golden` (review the image diff in the PR).

## 5. Validation scenarios per story

| Story           | How to validate                                          | Expected result                                              |
| --------------- | -------------------------------------------------------- | ------------------------------------------------------------ |
| US1             | Drag the dial to 1 min → Start                           | Dial shrinks; final screen stays until a tap                 |
| US2             | Start 1 min → lock the screen (Android/iOS)              | Alarm within ≤ 65 s; reopening shows the final screen        |
| US2 (Web/Linux) | Start                                                    | "Keep this window open" notice                               |
| US3             | Library image "Brush teeth" → 1 min; then a device photo | Image disappears with the dial; no gallery permission prompt |
| US4             | Start → tap many times → hold the padlock for 3 s        | No effect until unlocked                                     |
| US5             | Save a preset → restart the app → start with 2 taps      | The preset's timer                                           |
| US6             | Calm mode + ticking off                                  | No red, no ticking                                           |
| US7             | TalkBack/VoiceOver; English language; ⓘ → parental gate  | Everything announced/translated; parent area                 |
| US8–US14 (v1.x) | See the acceptance scenarios in the [spec](./spec.md)    | —                                                            |

## 6. Release builds (summary)

```bash
fvm flutter build apk --release --split-per-abi
fvm flutter build appbundle --release
fvm flutter build web --release --base-href /visual-time-counter/
fvm flutter build linux --release
fvm flutter build windows --release
fvm flutter build macos --release
fvm flutter build ipa --release        # requires signing
```

Before publishing: `docs/release-checklist.md`.
