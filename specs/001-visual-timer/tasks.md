---
description: "Task list to implement Kid Timer (v1.0 and v1.x)"
---

# Tasks: Kid Timer (v1.0 and v1.x)

**Input**: Design documents from `/specs/001-visual-timer/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md),
[data-model.md](./data-model.md), [contracts/](./contracts/),
[testing-strategy.md](./testing-strategy.md), [quickstart.md](./quickstart.md)

**Tests**: MANDATORY (Constitution IV + explicit request from the product owner): unit,
widget/golden, integration and End-to-End. In every story, test tasks come first and MUST fail
before the implementation (`test:` commit before `feat:`).

**Organization**: Tasks grouped by story (US1–US14). v1.0 = Phases 1–10; v1.x = Phases 11–18;
Phase 19 = final polish.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: spec story (US1…US14)
- Paths relative to the repository root (single Flutter project, see plan.md)
- Test conventions: `test/unit/…`, `test/widget/…`, `test/golden/…`, `test/contract/…`,
  `integration_test/…`, `patrol_test/…`

## Rules for whoever executes (`/speckit-implement`)

1. Follow the phase order; within a phase, respect the stated dependencies.
2. Before each implementation task, run the corresponding test and confirm it fails.
3. When a task is done, mark it `[x]` in this file and commit (Conventional Commits, in English,
   with `Signed-off-by`).
4. At every **Checkpoint**, run: `dart format --set-exit-if-changed .`, `flutter analyze`,
   `flutter test --coverage`, `dart run tool/check_coverage.dart` and the story's
   integration/E2E tests.
5. Data constraints quoted in tasks are normative (copied from data-model.md).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the Flutter project, tooling and conventions.

- [x] T001 Create the Flutter project at the root with `flutter create --org io.github.masterkey07 --project-name visual_time_counter --platforms android,ios,macos,windows,linux,web .` preserving `.specify/`, `.claude/`, `specs/`, `docs/`, `CLAUDE.md`, `README.md`, `LICENSE`
- [x] T002 Pin the SDK in `.fvmrc` (stable Flutter 3.47.x) and document the exact version in `README.md` (Development section)
- [x] T003 Configure `pubspec.yaml` with the plan.md dependencies (Technical Context), `flutter: generate: true`, assets (`assets/images/bank/`, `assets/sounds/`, `assets/legal/`) and fonts (Atkinson Hyperlegible Next)
- [x] T004 [P] Configure `analysis_options.yaml` with `very_good_analysis`, generated-file exclusions and the `public_member_api_docs` rule restricted to `lib/core/**`
- [x] T005 [P] Configure `l10n.yaml` (template `app_pt.arb`, output `lib/l10n/generated`, `nullable-getter: false`) and create `lib/l10n/app_pt.arb` and `lib/l10n/app_en.arb` with `appTitle`
- [x] T006 [P] Create the folder structure for `lib/`, `test/`, `integration_test/`, `patrol_test/`, `tool/`, `assets/`, `docs/` per plan.md (Project Structure), with `.gitkeep` where empty
- [x] T007 [P] Adjust `.gitignore` for Flutter + FVM (`.fvm/flutter_sdk`), `coverage/`, `build/`, `tool/image_bank/node_modules/`, golden failures (`**/failures/`)
- [x] T008 [P] Configure Android: `minSdk 26`, `targetSdk 36`, `compileSdk 36`, core library desugaring (required by `flutter_local_notifications`), `applicationId io.github.masterkey07.visualtimecounter` in `android/app/build.gradle.kts`
- [x] T009 [P] Configure iOS/macOS: deployment target iOS 16 / macOS 13, bundle id `io.github.masterkey07.visualtimecounter`, display name "Kid Timer" in `ios/Runner/Info.plist` and `macos/Runner/Configs/AppInfo.xcconfig`
- [ ] T010 [P] Configure Patrol: `patrol` in `pubspec.yaml` (`patrol:` section with `app_name`, `android.package_name`, `ios.bundle_id`), instrumentation in `android/app/build.gradle.kts` and `android/app/src/androidTest/java/.../MainActivityTest.java`, `RunnerUITests` target in `ios/` — **partial**: pubspec + Android done and `ios/RunnerUITests/RunnerUITests.m` added; the Xcode `RunnerUITests` target (linked to the patrol SPM package) still has to be created on a Mac
- [x] T011 [P] Create `test_driver/integration_test.dart` for Web runs via `flutter drive`
- [x] T012 [P] Download and add the Atkinson Hyperlegible Next font (Regular, Bold) to `assets/fonts/AtkinsonHyperlegibleNext/` with `OFL.txt`
- [x] T013 Create `CONTRIBUTING.md` (Spec Kit flow, DCO, Conventional Commits, how to run tests) and `docs/architecture.md` summarizing layers and ports (link to plan.md)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Domain, time engine, ports, persistence, theme, routes, l10n, CI and quality
tooling. **⚠️ No story starts before this phase is done.**

### 2a. Quality tooling and CI

- [x] T014 [P] Implement `tool/check_coverage.dart` (reads `coverage/lcov.info`; fails if `lib/core/**` < 95%, `lib/features/**/application/**` < 85%, overall < 80%; excludes exactly the testing-strategy §2 rule 8 list: `lib/**/*.g.dart`, `lib/l10n/generated/**`, `lib/main*.dart`, `lib/core/platform/**/impl/**`) with a test in `test/unit/tool/check_coverage_test.dart`
- [ ] T015 [P] Implement `tool/privacy_check.dart` (fails if the merged release manifest `build/app/intermediates/merged_manifests/release/**/AndroidManifest.xml` contains `android.permission.INTERNET` or broad storage permissions; if `pubspec.lock` contains `firebase_*`, `google_mobile_ads`, `*analytics*`, `sentry*`, `*crashlytics*`; if `lib/` imports `package:http`, `package:dio`, `HttpClient` or `WebSocket`; if macOS entitlements allow `network.client`/`network.server`; if iOS/macOS `Info.plist` has `NSAppTransportSecurity` exceptions; if `web/index.html`/`web/manifest.json` reference external URLs or CDNs; if `build/web/` references `gstatic.com` or any other external origin (CanvasKit CDN, research R20); if `windows/runner/` or `linux/` sources call WinHTTP/WinINet/libcurl/libsoup — research R22) with a test in `test/unit/tool/privacy_check_test.dart`
- [ ] T016 [P] Implement `tool/license_check.dart` (every file in `assets/images/**`, `assets/sounds/**`, `assets/fonts/**` listed in the folder's `LICENSES.md`; allowed licenses: CC0-1.0, CC-BY-4.0, MIT, Apache-2.0, OFL-1.1) with a test in `test/unit/tool/license_check_test.dart`
- [ ] T017 [P] Implement `tool/l10n_check.dart` (same set of keys and placeholders in `app_pt.arb` and `app_en.arb`) with a test in `test/unit/tool/l10n_check_test.dart`
- [ ] T018 Create `.github/workflows/ci.yml`: FVM; `dart format --set-exit-if-changed`; `flutter analyze`; `flutter test --coverage` with `TZ=UTC` and `TZ=America/Sao_Paulo`; `tool/check_coverage.dart`; `tool/license_check.dart`; `tool/l10n_check.dart`; release APK build (`--split-per-abi`) + `tool/privacy_check.dart` + fail if any APK > 25 MB (Constitution VIII); `xvfb-run flutter test integration_test -d linux`; web build with `--no-web-resources-cdn`; desktop build matrix (ubuntu, windows, macos); non-blocking `flutter build web --wasm` job
- [ ] T019 [P] Create `.github/workflows/e2e-android.yml` (API 34 x86_64 emulator with `reactivecircus/android-emulator-runner`, `patrol test -t patrol_test/`, Android integration; triggers: `e2e` label, daily schedule on `main`, `workflow_dispatch`)
- [ ] T020 [P] Create `test/helpers/pump_app.dart` (wraps a widget with `ProviderScope` + overrides, `MaterialApp` with pt/en l10n, theme, screen size per class), `test/helpers/hive_test_utils.dart` (Hive in a temporary directory per test) and `test/helpers/a11y_expectations.dart` (shortcut for the 4 guidelines + 200% font)
- [ ] T021 [P] Configure `alchemist` in `test/flutter_test_config.dart` (CI goldens with Ahem; app fonts loaded for platform goldens)

### 2b. Domain and time engine (TDD)

- [ ] T022 [P] Write value object tests in `test/unit/core/domain/timer_duration_test.dart` (limits "10 s ≤ value ≤ 2 h" in v1.0, adjustment steps: 10 s below 2 min and 1 min from 2 min on, multiple of 1 s), `dial_scale_test.dart` (fraction clamped to [0,1]), `visual_source_test.dart` (`singleColor` required if `paletteId == single`), `palette_test.dart` (thresholds green > 50%, yellow 20–50%, red < 20%, 2% interpolation; calm mode without red)
- [ ] T023 [P] Implement value objects in `lib/core/domain/timer_duration.dart`, `dial_scale.dart`, `dial_direction.dart`, `visual_source.dart`, `palette_id.dart`, `color_token.dart`, `sound_id.dart`, `image_effect.dart`, `warning_offsets.dart` (depends on T022)
- [ ] T024 Write `TimerConfig` tests (data-model defaults, `copyWith`, equality, `toJson`/`fromJson` per contracts/persistence-schema.md) in `test/unit/core/domain/timer_config_test.dart`
- [ ] T025 Implement `TimerConfig` in `lib/core/domain/timer_config.dart` (alarmVolume and tickVolume 0.0–1.0; defaults: 5 min, min60, clockwise, progressive, `chime_soft`, 0.7, false, 0.3, true, true, vanish, {}) (depends on T024)
- [ ] T026 Write state machine tests in `test/unit/core/timer_engine/timer_engine_test.dart`: start/pause/resume/cancel/restart/reconcile, `remaining`/`progress` with a fixed `Clock`, a 20 s pause preserves the remaining time, `reconcile` with `now ≥ endsAt` → finished, invalid transitions throw `InvalidTransition`, time zone independence (endsAt UTC)
- [ ] T027 Implement `SessionStatus`, `SessionOrigin`, `TimerSession` (with `toJson`/`fromJson`) and `TimerEngine` in `lib/core/timer_engine/` (depends on T025, T026)
- [ ] T028 [P] Implement `clockProvider` in `lib/core/clock/clock_provider.dart` (uses `package:clock`)
- [ ] T029 [P] Write `AnnounceThrottle` tests in `test/unit/core/a11y/announce_throttle_test.dart` (at most 1 announcement per interval; intervals 1 min, 5 min, off) and implement it in `lib/core/a11y/announce_throttle.dart`
- [ ] T030 [P] Write `mm:ss`/`h:mm:ss` formatting tests in `test/unit/core/domain/duration_format_test.dart` and implement it in `lib/core/domain/duration_format.dart`

### 2c. Persistence

- [ ] T031 Write `Migrator` tests in `test/unit/core/persistence/migrator_test.dart` (applies sequential migrations; failure → backup into `<box>_backup` and defaults; a `schemaVersion` higher than supported does not overwrite)
- [ ] T032 Implement `lib/core/persistence/boxes.dart` (box names: `settings`, `presets`, `routines`, `session`, `user_images_meta`, `user_images`), `hive_bootstrap.dart` (opens boxes; `user_images` as `LazyBox<Uint8List>`) and `migrator.dart` (depends on T031)
- [ ] T033 [P] Write `SessionRepository` tests in `test/unit/features/timer/data/session_repository_test.dart` (save with flush, load, clear, fixture `test/fixtures/persistence/v1/session_running.json`)
- [ ] T034 Implement `SessionRepository` in `lib/features/timer/data/session_repository.dart` (depends on T032, T033)
- [ ] T035 [P] Write `AppSettings` and `SettingsRepository` tests in `test/unit/features/settings/settings_repository_test.dart` (data-model defaults; `lastConfig`; onboarding flags; v1 fixture)
- [ ] T036 Implement `AppSettings` in `lib/features/settings/domain/app_settings.dart` and `SettingsRepository` in `lib/features/settings/data/settings_repository.dart` (depends on T032, T035)

### 2d. Platform ports (contracts + fakes + base implementations)

- [ ] T037 Define the interfaces and types of all ports per contracts/platform-ports.md in `lib/core/platform/alarm/alarm_scheduler.dart`, `wakelock/wakelock_port.dart`, `fullscreen/fullscreen_port.dart`, `audio/audio_port.dart`, `haptics/haptics_port.dart`, `image_picker/image_picker_port.dart`, `system_settings/system_settings_port.dart`, `external_link/external_link_port.dart`, `lifecycle/app_lifecycle_port.dart`
- [ ] T038 [P] Write reusable contract suites in `test/contract/alarm_scheduler_contract.dart` (same id replaces; cancelling an unknown id does not fail; past → `Failed(pastTime)`; ≤ 60 pending per group), `wakelock_contract.dart`, `audio_contract.dart`
- [ ] T039 [P] Implement fakes in `test/helpers/fakes/fake_alarm_scheduler.dart`, `fake_wakelock.dart`, `fake_fullscreen.dart`, `fake_audio.dart`, `fake_haptics.dart`, `fake_image_picker.dart`, `fake_system_settings.dart`, `fake_external_link.dart`, `fake_lifecycle.dart` and run the contracts against them in `test/contract/fakes_contract_test.dart`
- [ ] T040 Implement `LocalNotificationsAlarmScheduler` in `lib/core/platform/alarm/local_notifications_alarm_scheduler.dart` (`zonedSchedule` with `AndroidScheduleMode.alarmClock`; channels `timer_end_<soundId>` and `timer_warning`; iOS/macOS `timeSensitive` with bundled sound; `capabilities()` queries permissions; `notificationTaps` and `launchPayload`)
- [ ] T041 Implement `ForegroundOnlyAlarmScheduler` in `lib/core/platform/alarm/foreground_only_alarm_scheduler.dart` (Web, Linux; `scheduling = unsupported`)
- [ ] T042 **Spike** Windows: test `flutter_local_notifications` `zonedSchedule` on Windows 10/11; apply the R4 decision criterion (10/10 runs ≤ 5 s on Windows 10 22H2 and 11, sound, tap payload); record the result in `specs/001-visual-timer/research.md` (R4) and select the Windows implementation in `lib/core/platform/providers.dart`
- [ ] T043 Configure Android for alarms in `android/app/src/main/AndroidManifest.xml`: `USE_EXACT_ALARM`, `SCHEDULE_EXACT_ALARM` with `android:maxSdkVersion="32"`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `VIBRATE`, `WAKE_LOCK`, receivers `ScheduledNotificationReceiver` and `ScheduledNotificationBootReceiver` (actions `BOOT_COMPLETED`, `MY_PACKAGE_REPLACED`, `QUICKBOOT_POWERON`) to reschedule after reboot and app update; make sure the `main` manifest does not declare `INTERNET`
- [ ] T044 [P] Configure iOS/macOS for notifications: "Time Sensitive Notifications" capability in `ios/Runner/Runner.entitlements` and `macos/Runner/*.entitlements`; `UNUserNotificationCenter` delegate in `ios/Runner/AppDelegate.swift`
- [ ] T045 [P] Implement `WakelockPlusPort` (`lib/core/platform/wakelock/wakelock_plus_port.dart`), `SystemChromeFullscreen`, `WindowManagerFullscreen`, `WebFullscreen` (`lib/core/platform/fullscreen/`), `AudioplayersAudioPort` (`lib/core/platform/audio/audioplayers_audio_port.dart`, one player per channel), `FlutterHapticsPort` (`lib/core/platform/haptics/flutter_haptics_port.dart`), `FlutterAppLifecyclePort` (`lib/core/platform/lifecycle/`)
- [ ] T046 [P] Implement the Android `SystemSettingsPort`: `MethodChannel('vtc/system_settings')` in `lib/core/platform/system_settings/method_channel_system_settings.dart` and `android/app/src/main/kotlin/io/github/masterkey07/visualtimecounter/SystemSettingsChannel.kt` (methods `openExactAlarm`, `openNotifications`, `openBatteryOptimization`), no-op on other platforms
- [ ] T047 Create `lib/core/platform/providers.dart` with Riverpod providers for all ports and per-platform selection (`kIsWeb`, `defaultTargetPlatform`)
- [ ] T048 Write the integration test `integration_test/alarm_scheduler_contract_test.dart` running `test/contract/alarm_scheduler_contract.dart` against the real implementation on Android (schedule, replace, cancel, `pendingNotificationRequests`)

### 2e. App shell: bootstrap, theme, routes, l10n

- [ ] T049 Implement `lib/bootstrap.dart` (initializes `timezone`, Hive, migrations, loads session and settings, creates the `ProviderContainer` with platform overrides) and `lib/main.dart`
- [ ] T050 [P] Implement tokens and themes in `lib/app/theme/tokens.dart`, `palettes.dart` (progressive palette `#3BAA5C`/`#F2C14E`/`#E05A47`, calm `#8FB8E8`/`#B9A7E0`/`#F3C3A3`, elapsed `#9AA0A6` 0.18 light/0.28 dark, 8 `ColorToken`s), `typography.dart` (Atkinson, tabular digits), `app_theme.dart` (light/dark, each with a high-contrast variant selected by `MediaQuery.highContrastOf` — FR-055) per contracts/ui/00 §4
- [ ] T051 [P] Write a contrast test in `test/unit/app/theme/contrast_test.dart` (text ≥ 4.5:1 and components ≥ 3:1 in both themes; text and icons ≥ 7:1 and components ≥ 4.5:1 in both high-contrast variants)
- [ ] T052 Write route and guard tests in `test/widget/app/router_test.dart` (running session → `/run`; unacknowledged finished → `/finished`; deep links `vtc://preset/<id>/start`, `vtc://run`; unknown id → `/` with a snackbar)
- [ ] T053 Implement `lib/app/router.dart` (routes from contracts/ui/00 §1, guards and deep links) and `lib/app/app.dart` (`MaterialApp.router`, themes, `localizationsDelegates`, `localeResolutionCallback` with en fallback, global `Shortcuts`/`Actions`) (depends on T052)
- [ ] T054 [P] Write `test/unit/app/locale_resolution_test.dart` (pt-_ → pt-BR, en-_ → en, others → en)
- [ ] T055 [P] Implement the shared components `lib/app/widgets/platform_notice.dart` (key `notice.banner`) and `lib/app/widgets/confirm_dialog.dart` with tests in `test/widget/app/widgets/shared_widgets_test.dart`
- [ ] T056 Configure the `vtc://` deep link in `android/app/src/main/AndroidManifest.xml` (intent-filter) and `ios/Runner/Info.plist` (`CFBundleURLTypes`)

**Checkpoint**: Foundation ready. CI green, `lib/core` coverage ≥ 95%, the app opens an empty
screen at route `/` on every platform (`flutter run -d <each>`). Stories can start.

---

## Phase 3: User Story 1 - Visual countdown with a shrinking dial (Priority: P1) 🎯 MVP

**Goal**: Set a duration, start, watch the dial shrink, pause/resume/cancel and see the final
screen that stays until a tap.

**Independent Test**: Drag the dial to 2 min, start, follow it to zero, final screen until a tap
(contracts/ui/01, 02, 03).

### Tests for User Story 1 ⚠️ (write first, they must fail)

- [ ] T057 [P] [US1] Dial geometry tests in `test/unit/features/timer/application/dial_geometry_test.dart` (angle ↔ duration per scale, rounding to the step, clockwise/counter-clockwise, remaining fraction)
- [ ] T058 [P] [US1] `TimerController` tests in `test/unit/features/timer/application/timer_controller_test.dart` (start and resume persist before scheduling; pause persists before cancelling; pause/resume/cancel/restart call the right ports; end with the app open plays the alarm once, vibrates, goes to finished; acknowledge clears the session; `lastConfig` saved with a 300 ms debounce; starting with an active session requires confirmation and replaces the previous one (v1.0: one timer at a time, FR-007); a failure to persist the session (storage full) prevents starting, without scheduling an alarm, and shows an error)
- [ ] T059 [P] [US1] Home screen widget tests in `test/widget/features/timer/home_screen_test.dart` (drag adjusts duration; −1/+1/+5 and the 10 s–2 h limits; keyboard arrows/PageUp/PageDown; slider semantics; `home.start` disabled < 10 s; navigation to `/run`)
- [ ] T060 [P] [US1] Countdown widget tests in `test/widget/features/timer/run_screen_test.dart` (with `childLockEnabled=false`: pause/resume/restart with confirmation < 50%/stop with confirmation; digits hidden if `showDigits=false`; repaint isolated in a `RepaintBoundary`)
- [ ] T061 [P] [US1] Final screen widget tests in `test/widget/features/timer/finished_screen_test.dart` (800 ms guard; tap acknowledges and returns to `/`; Enter/Space/Esc; "Time's up" announcement; stays after 10 simulated minutes)
- [ ] T062 [P] [US1] Goldens in `test/golden/features/timer/dial_view_golden_test.dart` (dial 0/25/50/100% × progressive/calm × clockwise/counter-clockwise × light/dark) and `test/golden/features/timer/screens_golden_test.dart` (home, run, finished × compact/medium/expanded)
- [ ] T063 [P] [US1] Accessibility tests in `test/widget/features/timer/timer_a11y_test.dart` (guidelines on the 3 screens; 200% font without overflow; pt and en)
- [ ] T064 [P] [US1] Integration test `integration_test/restart_shows_finished_test.dart` (expired unacknowledged session → `/finished` after a restart)
- [ ] T065 [P] [US1] E2E `patrol_test/e2e_us1_basic_timer_test.dart` (drag to 1 min, start, wait, final screen, tap returns)

### Implementation for User Story 1

- [ ] T066 [US1] Implement `DialGeometry` in `lib/features/timer/application/dial_geometry.dart` (depends on T057)
- [ ] T067 [US1] Implement `TimerController` (Riverpod Notifier) in `lib/features/timer/application/timer_controller.dart` using `TimerEngine`, `SessionRepository`, `AlarmScheduler`, `AudioPort`, `HapticsPort`, `SettingsRepository` (depends on T058, T066)
- [ ] T068 [P] [US1] Implement `DialPainter` (`CustomPainter`: remaining arc with interpolated color, neutral elapsed sector, minute markers in a cached `Picture`, direction) in `lib/features/timer/presentation/widgets/dial_painter.dart`
- [ ] T069 [US1] Implement `DialView` (editable mode with gestures/keyboard/slider semantics and countdown mode with `Ticker` + `RepaintBoundary`; 1 repaint/s with reduce motion) in `lib/features/timer/presentation/widgets/dial_view.dart` (depends on T066, T068)
- [ ] T070 [P] [US1] Implement `DigitsLabel` and `DurationQuickButtons` in `lib/features/timer/presentation/widgets/digits_label.dart` and `duration_quick_buttons.dart`
- [ ] T071 [US1] Implement `HomeScreen` (compact/medium/expanded layouts, keys from contracts/ui/01, first-use hint) in `lib/features/timer/presentation/home_screen.dart` (depends on T067, T069, T070)
- [ ] T072 [US1] Implement `RunScreen` without child mode (controls always visible; lifecycle → `reconcile`; end with the app open) in `lib/features/timer/presentation/run_screen.dart` (depends on T067, T069)
- [ ] T073 [US1] Implement `FinishedScreen` (celebration with spin/particles and an opacity variant with reduce motion; sound repeated every 30 s up to 3×; 10 min wakelock) in `lib/features/timer/presentation/finished_screen.dart`
- [ ] T074 [US1] Add US1 strings (`home*`, `run*`, `finished*`) to `lib/l10n/app_pt.arb` and `lib/l10n/app_en.arb`
- [ ] T075 [US1] Add the default sound `chime_soft.wav` (CC0) to `assets/sounds/`, the manifest `assets/sounds/manifest.json` and `assets/sounds/LICENSES.md`

**Checkpoint**: US1 working and tested with the app open on every platform.

---

## Phase 4: User Story 2 - Reliable alarm and screen always on (Priority: P1)

**Goal**: Alarm with the app in the background/killed/screen locked; screen on; state restored;
honest notices where unsupported.

**Independent Test**: Start 1 min, lock the screen, receive the alarm, reopen on the final screen.

### Tests for User Story 2 ⚠️

- [ ] T076 [P] [US2] `StartPreflight` tests in `test/unit/features/timer/application/start_preflight_test.dart` (the contracts/ui/08 §8.1 tree for every `AlarmCapabilities` combination; flags `webKeepOpenSeen`, `iosSilentWarned`, `exactAlarmExplained`; system volume 0 → 4 s notice banner without blocking)
- [ ] T077 [P] [US2] Reconcile/restore tests in `test/unit/features/timer/application/reconcile_test.dart` (resume before the end continues with the real remaining time; after the end → finished; app reopened hours later shows finished once)
- [ ] T078 [P] [US2] `RunController` tests in `test/unit/features/timer/application/run_controller_test.dart` (wakelock on when entering and off when leaving; fullscreen; single ring per platform per contracts/ui/02 Behavior 5: Android/Windows cancel the OS alarm on `resumed` and reschedule on `inactive`/`paused`/`hidden`, iOS/macOS foreground presentation off, Web/Linux app sound only)
- [ ] T079 [P] [US2] Notice widget tests in `test/widget/features/timer/notices_test.dart` (dialogs `notice.keepOpen`, `notice.notificationsDenied`, `notice.exactAlarm`, `notice.iosSilent`; `notice.banner` on home and on the unlocked controls, never in child mode)
- [ ] T080 [P] [US2] Integration `integration_test/restart_resumes_running_test.dart`, `integration_test/wakelock_integration_test.dart` (Android and Linux) and `integration_test/persistence_roundtrip_test.dart` (Android, Linux, Web), and `integration_test/alarm_accuracy_test.dart` (Android, Linux: 20 runs of 30 s, `playAlarm` within ≤ 1 s of `endsAt`; testing-strategy §8 SC-002)
- [ ] T081 [P] [US2] E2E `patrol_test/e2e_us2_alarm_locked_screen_test.dart` (Android/iOS: `$.native.pressHome()` and lock; notification within ≤ 65 s; on Android, assert `postTime − endsAt ≤ 5 s` from `dumpsys notification`)
- [ ] T082 [P] [US2] E2E `patrol_test/e2e_us2_alarm_closed_app_test.dart` (Android: kill the app; tapping the notification opens `/finished`)
- [ ] T083 [P] [US2] E2E `patrol_test/e2e_us2_permissions_android_test.dart` (Android 14: deny notifications → dialog → "Open settings")

### Implementation for User Story 2

- [ ] T084 [US2] Implement `StartPreflight` in `lib/features/timer/application/start_preflight.dart` and wire it into `home.start` (depends on T076)
- [ ] T085 [US2] Implement `RunController` (wakelock, fullscreen, ticking, lifecycle) in `lib/features/timer/application/run_controller.dart` (depends on T078)
- [ ] T086 [US2] Wire `reconcile` into bootstrap and `AppLifecyclePort.resumed`; handle `launchPayload`/`notificationTaps` → route in `lib/bootstrap.dart`, `lib/app/router.dart` and `lib/features/timer/application/timer_controller.dart` (depends on T077)
- [ ] T087 [US2] Enforce the "persist + flush → schedule" order and stable ids (`hash(sessionId) & 0x7fffffff`) in `lib/features/timer/application/timer_controller.dart`
- [ ] T088 [P] [US2] Implement the notice dialogs in `lib/features/timer/presentation/widgets/preflight_dialogs.dart` (keys from contracts/ui/08)
- [ ] T089 [P] [US2] Copy sounds for notifications: `android/app/src/main/res/raw/*.wav` and iOS/macOS bundle resources (`ios/Runner/Sounds/`, `macos/Runner/Sounds/`), with the script `tool/sounds/sync_notification_sounds.dart`
- [ ] T090 [US2] Implement `BatteryHelpScreen` (`/settings/battery`, anchors `#alarms`, `#battery`, `#pinning`, `#web`; Android buttons via `SystemSettingsPort`) in `lib/features/settings/presentation/battery_help_screen.dart` with a test in `test/widget/features/settings/battery_help_screen_test.dart`
- [ ] T091 [US2] Add US2 strings (`notice*`, `batteryHelp*`, notification titles/bodies) to `lib/l10n/app_pt.arb` and `lib/l10n/app_en.arb`

**Checkpoint**: Reliable alarm on Android/iOS/macOS (+Windows per T042); Web/Linux with a notice.
US2 E2E green on the emulator.

---

## Phase 5: User Story 3 - Image on the dial: built-in library and own image (Priority: P1)

**Goal**: A library of ≥ 36 images in 6 categories, own images framed without metadata, "My
images", image on the dial with a fallback to colors.

**Independent Test**: Library image on the dial; framed device photo; no image → colors.

### Assets (story prerequisite)

- [ ] T092 [US3] Verify the license of `microsoft/fluentui-emoji` (the `LICENSE` file and its scope over the assets) and record the result in `specs/001-visual-timer/research.md` (R9); if it is not MIT/compatible, use the fallback (Twemoji CC BY 4.0 or Noto Emoji Apache-2.0)
- [ ] T093 [US3] Create the `tool/image_bank/` pipeline (`package.json`, `build.mjs` with `@resvg/resvg-js` + `sharp`, `sources.json` mapping emoji → id/category/pt-en names) that generates `assets/images/bank/<category>/<slug>.webp` at 768×768 with a soft circular background and `assets/images/bank/manifest.json`
- [ ] T094 [US3] Generate and commit ≥ 36 images (≥ 6 per category: `hygiene`, `meal`, `play`, `rest`, `school`, `goingOut`), `assets/images/bank/manifest.json` and `assets/images/bank/LICENSES.md` (author, license, source per file); human review recorded in `docs/assets-review.md` using the research R9 criteria (per asset: reviewer, date, verdict) and the R9 recognition validation; replace failing images

### Tests for User Story 3 ⚠️

- [ ] T095 [P] [US3] Manifest test in `test/unit/features/images/image_bank_manifest_test.dart` (≥ 36 images; 6 categories with ≥ 6 each; non-empty pt and en names (FR-026); allowed license; file exists; every image has an approved entry in `docs/assets-review.md`)
- [ ] T096 [P] [US3] `ImageProcessor` tests in `test/unit/features/images/image_processor_test.dart` (JPEG 1024×1024 output; EXIF/GPS absent from the result using the fixture `test/fixtures/images/with_gps.jpg`; center/zoom framing; errors `UnsupportedImageFormat`, `CorruptImage`, `ImageTooLarge` > 100 MP)
- [ ] T097 [P] [US3] `UserImageRepository` tests in `test/unit/features/images/user_image_repository_test.dart` (write bytes → meta; remove meta → bytes; orphans cleaned at bootstrap; limit 50; reference count in presets/`lastConfig`; deleting converts references to the default palette; storage full during writing leaves no partial bytes or meta)
- [ ] T098 [P] [US3] Geometry/painting tests with an image in `test/unit/features/timer/application/dial_image_clip_test.dart` (remaining sector clipped; neutral elapsed) and image goldens in `test/golden/features/timer/dial_image_golden_test.dart`
- [ ] T099 [P] [US3] Widget tests in `test/widget/features/images/image_picker_screen_test.dart` (tabs, 3/5/7-column grid, selection, "No image", empty "My images" state, Web note, invalid file error), `frame_screen_test.dart` (drag, pinch, keyboard, 1.0–4.0 slider, save with overlay), `my_images_screen_test.dart` ("12 of 50" counter, delete with the list of affected presets)
- [ ] T100 [P] [US3] Integration `integration_test/user_image_persist_test.dart` (Android, Linux, Web: save, restart, bytes intact)
- [ ] T101 [P] [US3] E2E `patrol_test/e2e_us3_bank_image_test.dart` and `patrol_test/e2e_us3_own_image_test.dart` (system picker without a permission dialog; photo seeded via `adb push`/simulator; frame; see it on the dial)

### Implementation for User Story 3

- [ ] T102 [P] [US3] Implement `ImageAsset`, `ImageCategory`, `FrameSpec` in `lib/features/images/domain/`
- [ ] T103 [P] [US3] Implement `BankManifestLoader` in `lib/features/images/data/bank_manifest_loader.dart` (reads the manifest, label per language) (depends on T095)
- [ ] T104 [US3] Implement `ImageProcessorImpl` (`image` package, `compute`) in `lib/features/images/data/image_processor_impl.dart` (depends on T096)
- [ ] T105 [US3] Implement `UserImageRepository` in `lib/features/images/data/user_image_repository.dart` and orphan cleanup in `bootstrap()` (depends on T097)
- [ ] T106 [P] [US3] Implement the real `ImagePickerPort` in `lib/core/platform/image_picker/image_picker_port_impl.dart` (`image_picker` + `file_selector` on desktop)
- [ ] T107 [US3] Implement an `ImageCache` of `ui.Image`s decoded at the dial's size in `lib/features/images/application/decoded_image_cache.dart` and extend `DialPainter` for `BankImageSource`/`UserImageSource` with a fallback to color on failure (depends on T098)
- [ ] T108 [US3] Implement `ImagePickerScreen` (`/images`), `FrameScreen` (`/images/frame`), `MyImagesScreen` (`/images/mine`) and `ImageThumb` in `lib/features/images/presentation/` with the keys from contracts/ui/04 (depends on T103–T107)
- [ ] T109 [US3] Wire the image chip into `HomeScreen` (`home.imageChip`, `home.imageClear`) and a one-time notice when the own image was deleted in `lib/features/timer/presentation/home_screen.dart`
- [ ] T110 [US3] Verify in the Android manifest that no `READ_MEDIA_IMAGES`/`READ_EXTERNAL_STORAGE` permission is added (remove them with `tools:node="remove"` if a plugin includes them) in `android/app/src/main/AndroidManifest.xml`
- [ ] T111 [US3] Add US3 strings (`images*`, `frame*`, `mine*`, category labels) to `lib/l10n/app_pt.arb` and `lib/l10n/app_en.arb`

**Checkpoint**: US1–US3 complete = usable MVP core.

---

## Phase 6: User Story 4 - Child lock and full screen (Priority: P2)

**Goal**: Child mode in full screen, touches ignored, unlock by holding the padlock for 3 s or
Esc for 3 s, controls for 10 s.

**Independent Test**: Tapping many times has no effect; holding the padlock for 3 s shows the
controls.

### Tests for User Story 4 ⚠️

- [ ] T112 [P] [US4] `UnlockController` tests in `test/unit/features/child_lock/unlock_controller_test.dart` (`fake_async`: 3 s completes; releasing earlier resets; controls for 10 s; interaction restarts the 10 s; Esc held for 3 s)
- [ ] T113 [P] [US4] Widget tests in `test/widget/features/child_lock/run_screen_child_lock_test.dart` (30 random gestures with `Random(42)`: tap, drag, double tap, pinch → state unchanged; Android back button consumed; padlock glow; `childLockEnabled=false` always shows controls; reduce motion replaces the ring with "1… 2… 3"; turning on accessible navigation mid-countdown keeps the session unchanged and the padlock focusable)
- [ ] T114 [P] [US4] Goldens of child mode and unlocked controls in `test/golden/features/child_lock/child_lock_golden_test.dart`
- [ ] T115 [P] [US4] E2E `patrol_test/e2e_us4_child_lock_test.dart` (30 taps + native back with no effect; holding for 3 s shows the controls) and integration `integration_test/child_lock_integration_test.dart` (Android, Linux: real `FullscreenPort` and `AppLifecyclePort`; entering `/run` enters full screen, Esc held 3 s on Linux shows the controls, leaving exits full screen)

### Implementation for User Story 4

- [ ] T116 [US4] Implement `UnlockController` in `lib/features/child_lock/application/unlock_controller.dart` (depends on T112)
- [ ] T117 [P] [US4] Implement `HoldToUnlock` (key `run.lock`, ring `run.lockProgress`) and `TouchShield` (key `run.touchShield`) in `lib/features/child_lock/presentation/`
- [ ] T118 [US4] Integrate child mode into `RunScreen`: `PopScope(canPop: false)`, full screen via `FullscreenPort`, temporary controls with a countdown bar, `Shortcuts` for Esc in `lib/features/timer/presentation/run_screen.dart` (depends on T116, T117)
- [ ] T119 [US4] Add the "Child mode" section (`settings.childLock` with confirmation on disabling) — prepare the provider in `lib/features/settings/application/settings_controller.dart` (the full screen comes in US6)
- [ ] T120 [US4] Add US4 strings (`runUnlockHint`, `runRelockIn`, `settingsChildLock*`, `batteryHelpPinning*`) to `lib/l10n/app_pt.arb` and `lib/l10n/app_en.arb`

**Checkpoint**: SC-003 validated (30 attempts with no effect).

---

## Phase 7: User Story 5 - Activity presets (Priority: P2)

**Goal**: CRUD, reordering, start in 2 taps, 6 examples on first use, limit 100.

**Independent Test**: Create a preset, restart the app, start it with 2 taps.

### Tests for User Story 5 ⚠️

- [ ] T121 [P] [US5] `Preset` and validation tests in `test/unit/features/presets/preset_test.dart` (name "1–40 characters after trim"; gap-free `order`; `favorite` at most 4 — v1.x; `toJson`/`fromJson`)
- [ ] T122 [P] [US5] `PresetRepository` tests in `test/unit/features/presets/preset_repository_test.dart` (CRUD, duplicate with suffix, reorder, limit 100, seeding of 6 examples only once via `onboarding.examplesSeeded`, v1 fixture)
- [ ] T123 [P] [US5] Widget tests in `test/widget/features/presets/presets_screen_test.dart` (list, start `presets.start.<id>`, reorder by drag and Ctrl+↑/↓, delete with a 5 s undo, empty, limit) and `preset_editor_test.dart` (validation, sound preview, discard changes)
- [ ] T124 [P] [US5] Goldens in `test/golden/features/presets/presets_golden_test.dart`
- [ ] T125 [P] [US5] Integration `integration_test/presets_persist_test.dart` (Android, Linux, Web)
- [ ] T126 [P] [US5] E2E `patrol_test/e2e_us5_presets_test.dart` (create → restart → `/run` in 2 taps — SC-006)

### Implementation for User Story 5

- [ ] T127 [P] [US5] Implement `Preset` in `lib/features/presets/domain/preset.dart` (depends on T121)
- [ ] T128 [US5] Implement `PresetRepository` + seeds (6 examples, one per library category, with names localized at seeding time) in `lib/features/presets/data/preset_repository.dart` and `preset_seeds.dart` (depends on T122, T127, T094)
- [ ] T129 [US5] Implement `PresetsController` in `lib/features/presets/application/presets_controller.dart`
- [ ] T130 [US5] Implement `PresetsScreen` and `PresetEditorScreen` in `lib/features/presets/presentation/` with the keys from contracts/ui/05 (depends on T129)
- [ ] T131 [US5] Wire the preset strip into `HomeScreen` (`home.presetStrip`, `home.preset.<id>`, `home.savePreset`) and the `preset(id)` origin in the session in `lib/features/timer/presentation/home_screen.dart` and `lib/features/timer/application/timer_controller.dart`
- [ ] T132 [US5] When an own image is deleted, update affected presets in `lib/features/images/data/user_image_repository.dart` + `lib/features/presets/data/preset_repository.dart` (integration with T105)
- [ ] T133 [US5] Add US5 strings (`presets*`, `presetEditor*`) to `lib/l10n/app_pt.arb` and `lib/l10n/app_en.arb`

**Checkpoint**: SC-006 validated.

---

## Phase 8: User Story 6 - Appearance, sound and preferences (Priority: P2)

**Goal**: Scales, direction, palettes (progressive, single color, calm), sounds (≥ 8), volumes,
ticking, vibration, theme; all persisted.

**Independent Test**: Calm mode + ticking off → no red and no tick.

### Assets

- [ ] T134 [US6] Select ≥ 8 friendly sounds (Kenney CC0 or own), normalize them (WAV 16-bit mono 44.1 kHz, ≤ 30 s, ≤ 500 KB, research R6 targets: −20 LUFS ± 1 (tick −30), true peak ≤ −3 dBTP, attack ≥ 20 ms, alarm 1–5 s), implement `tool/sounds/check_sounds.dart` (with a test in `test/unit/tool/check_sounds_test.dart`) and run it in CI, add `tick_soft.wav` and `transition_soft.wav`, update `assets/sounds/manifest.json` and `LICENSES.md`; human review of every sound recorded in `docs/assets-review.md` (research R9 criteria); run `tool/sounds/sync_notification_sounds.dart`

### Tests for User Story 6 ⚠️

- [ ] T135 [P] [US6] `SettingsController` tests in `test/unit/features/settings/settings_controller_test.dart` (each field persists; changing defaults updates `lastConfig` when it equals the previous default; disabling the lock requires confirmation)
- [ ] T136 [P] [US6] Palette/color tests in `test/unit/app/theme/palette_interpolation_test.dart` (50%/20% thresholds with 2% interpolation; calm without a red hue — hue outside [345°, 15°]; single color constant)
- [ ] T137 [P] [US6] Audio tests in `test/unit/features/timer/application/tick_and_alarm_audio_test.dart` (ticking only with `tickEnabled`; volumes applied; preview stops the previous one)
- [ ] T138 [P] [US6] Widget tests in `test/widget/features/settings/settings_screen_test.dart` (every section from contracts/ui/06; alarm status per platform via a fake; Android buttons hidden elsewhere) and goldens in `test/golden/features/settings/settings_golden_test.dart`
- [ ] T139 [P] [US6] Integration `integration_test/theme_persist_test.dart` (Linux)
- [ ] T140 [P] [US6] E2E `patrol_test/e2e_us6_calm_mode_test.dart` (calm mode, ticking off, screen golden without red)

### Implementation for User Story 6

- [ ] T141 [US6] Implement `SettingsController` in `lib/features/settings/application/settings_controller.dart` (depends on T135)
- [ ] T142 [US6] Implement `SettingsScreen` (`/settings`) with every section and the keys from contracts/ui/06 in `lib/features/settings/presentation/settings_screen.dart` (depends on T141)
- [ ] T143 [P] [US6] Implement `SoundPickerSheet` (list + preview + volume) in `lib/features/timer/presentation/widgets/sound_picker_sheet.dart` and wire it into `home.soundPicker` and the preset editor
- [ ] T144 [US6] Apply `themeMode` and the system high-contrast variant in `lib/app/app.dart`, scale/direction/palette in `lib/features/timer/presentation/widgets/dial_painter.dart`, ticking in `lib/features/timer/application/run_controller.dart` (depends on T136, T137)
- [ ] T145 [US6] Validate palettes for color vision deficiency with simulation (Machado/Brettel) in `test/unit/app/theme/colorblind_check_test.dart` (phases distinguishable by luminance ≥ 20%) and adjust colors if needed
- [ ] T146 [US6] Add US6 strings (`settings*`, sound names, palettes, colors) to `lib/l10n/app_pt.arb` and `lib/l10n/app_en.arb`

**Checkpoint**: Preferences complete and persisted.

---

## Phase 9: User Story 7 - Accessibility, languages and parent area (Priority: P2)

**Goal**: Screen reader, keyboard, 200% font, reduce motion, complete pt-BR/en, parental gate and
parent area with privacy and licenses.

**Independent Test**: TalkBack/VoiceOver from start to finish; complete English; ⓘ → gate → area.

### Tests for User Story 7 ⚠️

- [ ] T147 [P] [US7] Parental gate tests in `test/unit/features/parental/gate_challenge_test.dart` (factors 3–9 with a seeded `Random`; 3 errors → 30 s lockout with `fake_async`; 5 min validity) and `number_words_test.dart` (products in words in pt and en, e.g. 7×8 → "sete vezes oito"/"seven times eight")
- [ ] T148 [P] [US7] Widget tests in `test/widget/features/parental/parental_gate_test.dart` (custom and physical keypad, error, lockout, screen reader reading) and `parent_area_test.dart` (privacy, licenses including assets' `LICENSES.md`, credits from the manifests, confirmation before an external link, diagnostic report without personal data)
- [ ] T149 [P] [US7] Accessibility sweep in `test/widget/a11y/all_screens_a11y_test.dart` (every v1.0 screen × pt/en × light/dark: 4 guidelines, 200% font, Tab focus reaches every control, dial announcements via `AnnounceThrottle`, reduce motion; dialogs move focus in, trap it and return it to the opener; compact landscape 800×360 without overflow; elapsed sector opaque with `highContrast`; every repeating animation cycle ≥ 400 ms (flash safety, contracts/ui/00 §4))
- [ ] T150 [P] [US7] E2E `patrol_test/e2e_us7_parental_gate_test.dart` and `patrol_test/e2e_us7_a11y_smoke_test.dart` (TalkBack enabled via `adb shell settings put secure enabled_accessibility_services …`), and integration `integration_test/locale_and_gate_integration_test.dart` (Linux, Web: app boots in en and pt-BR from the platform locale, an unsupported locale falls back to en; gate → `/parent`; the external link asks for confirmation through the real `ExternalLinkPort` wiring)

### Implementation for User Story 7

- [ ] T151 [P] [US7] Implement `GateChallenge`, `NumberWords` in `lib/features/parental/domain/` and `ParentalGateController` in `lib/features/parental/application/` (depends on T147)
- [ ] T152 [US7] Implement `ParentalGate` (dialog, keys `gate.*`) in `lib/features/parental/presentation/parental_gate.dart`
- [ ] T153 [US7] Implement `ParentAreaScreen` (`/parent`), `PrivacyScreen`, `CreditsScreen` and the `ExternalLinkPort` with `url_launcher` in `lib/features/parental/presentation/` and `lib/core/platform/external_link/url_launcher_external_link.dart`; register the assets' `LICENSES.md` in the `LicenseRegistry` in `bootstrap.dart`
- [ ] T154 [P] [US7] Write the privacy policy in `assets/legal/privacy_pt.md` and `assets/legal/privacy_en.md` (nothing is collected; images stay local; no network; contact) and publish a copy in `docs/privacy-policy.md`
- [ ] T155 [US7] Fix every issue found by the T149 sweep (semantics, focus, overflow) in the screens under `lib/features/**/presentation/` and `lib/app/widgets/`
- [ ] T156 [US7] Review and complete `app_en.arb` (100% of keys) and run `tool/l10n_check.dart`
- [ ] T157 [US7] Add US7 strings (`gate*`, `parent*`, `privacyPolicyBody`) to `lib/l10n/app_pt.arb` and `lib/l10n/app_en.arb`

**Checkpoint**: All v1.0 stories complete.

---

## Phase 10: Release v1.0 (hardening and distribution)

**Purpose**: Performance, final verification and v1.0 publication.

- [ ] T158 [P] Performance tests `integration_test/perf_dial_animation_test.dart` (profile; 10 s `traceAction`; ≥ 99% frames < 16 ms; result saved as an artifact) and `integration_test/perf_startup_test.dart` (≤ 2 s)
- [ ] T159 [P] Write `docs/release-checklist.md` (devices, alarm locked/killed per vendor, reboot, iOS silent, screen readers (incl. turning one on mid-countdown), projector and moving the full-screen window between monitors, APK and IPA privacy check; the testing-strategy §8 protocols for SC-002 background, SC-003 manual and SC-008)
- [ ] T160 [P] Create `.github/workflows/release.yml` (tag `v*`: APK per ABI, AAB, Web on GitHub Pages with `--base-href /kid-timer-app/ --no-web-resources-cdn`, a check that every APK per ABI is ≤ 25 MB, Linux AppImage, Windows zip/MSIX, macOS dmg; artifacts on the GitHub Release; iOS via fastlane when secrets exist)
- [ ] T161 [P] Create store metadata in `fastlane/metadata/android/pt-BR/` and `en-US/` (title, short/full descriptions, screenshots, changelog), F-Droid compatible
- [ ] T162 [P] Create the app icon and splash (original art, license recorded, human review in `docs/assets-review.md`) in `assets/branding/` and generate per-platform icons
- [ ] T163 Prepare store declarations in `docs/store-declarations.md` (Google Play: target audience, Data Safety "no data collected", `USE_EXACT_ALARM` justification; Apple: privacy nutrition label "Data Not Collected", decision on the Kids Category; IARC)
- [ ] T164 Run `quickstart.md` §5 (US1–US7), the release checklist and the usability protocols of testing-strategy §8 (SC-001, SC-005 with 5 adults; SC-010 with 3 families/teachers/therapists over 1 week) and the library recognition validation (research R9); record the results in `docs/releases/v1.0.0.md`
- [ ] T165 Update `CHANGELOG.md` and create the `v1.0.0` tag

**Checkpoint**: v1.0 published (Web, GitHub Releases; stores depending on available accounts).

---

## Phase 11: User Story 8 - Routines in sequence (Priority: P3) — v1.x

**Goal**: Routines of 2–20 steps, automatic/manual, step strip with stars, "First / Then",
per-step notifications.

**Independent Test**: A 3-step 30 s routine in automatic mode with 3 alarms and 3 stars.

### Tests for User Story 8 ⚠️

- [ ] T166 [P] [US8] `Routine`/`RoutineStep` tests in `test/unit/features/routines/routine_test.dart` (name 1–40; "2–20 items"; `firstThen` requires exactly 2 steps; step duration 10 s–2 h)
- [ ] T167 [P] [US8] `RoutineRunner` tests in `test/unit/features/routines/routine_runner_test.dart` (automatic and manual; skip without a star; pause; reconcile across several steps with the app closed; snapshot immune to edits; schedules ≤ 60 notifications and cancels by group)
- [ ] T168 [P] [US8] `RoutineRepository` tests in `test/unit/features/routines/routine_repository_test.dart` (CRUD, order, limit 100, migration of the `routines` box)
- [ ] T169 [P] [US8] Widget tests in `test/widget/features/routines/routine_editor_test.dart`, `routines_screen_test.dart`, `routine_run_screen_test.dart` (strip, stars, `routineRun.next` button in `waitingNext`, First/Then layout) and goldens in `test/golden/features/routines/`
- [ ] T170 [P] [US8] Integration `integration_test/routine_persist_test.dart` and E2E `patrol_test/e2e_us8_routine_background_test.dart`

### Implementation for User Story 8

- [ ] T171 [P] [US8] Implement the domain in `lib/features/routines/domain/routine.dart`, `routine_step.dart`, `routine_run.dart`
- [ ] T172 [US8] Implement `RoutineRepository` in `lib/features/routines/data/routine_repository.dart` and the `session["routineRun"]` key
- [ ] T173 [US8] Implement `RoutineRunner` in `lib/features/routines/application/routine_runner.dart` (reuses `TimerEngine` per step; `AlarmRequest.kind = stepEnd`; `groupKey = runId`)
- [ ] T174 [US8] Extend the library with routine pictograms (≥ 24 images, category `routine`) via `tool/image_bank/` and update `LICENSES.md`/human review
- [ ] T175 [US8] Implement the screens `/routines`, `/routines/new`, `/routines/:id/edit`, `/routines/:id/run` in `lib/features/routines/presentation/` per contracts/ui/09; shortcut `home.openRoutines`
- [ ] T176 [US8] Route guards and the `vtc://routine/<id>/start` deep link in `lib/app/router.dart`; final screen with stars in `lib/features/timer/presentation/finished_screen.dart`
- [ ] T177 [US8] Add US8 strings (`routines*`, `routineEditor*`, `routineRun*`) to `lib/l10n/app_pt.arb` and `lib/l10n/app_en.arb`

**Checkpoint**: SC-011 validated.

---

## Phase 12: User Story 9 - Intermediate warnings (Priority: P3) — v1.x

**Goal**: Warnings 1, 2, 5, 10 min before the end, also with the app closed.

### Tests for User Story 9 ⚠️

- [ ] T178 [P] [US9] Tests in `test/unit/features/timer/application/warning_schedule_test.dart` (at most 2 warnings accepted — FR-080; warnings ≥ duration ignored; scheduling with `kind = warning`; cancelled together with the session)
- [ ] T179 [P] [US9] Widget tests in `test/widget/features/timer/run_screen_warning_test.dart` (pulse 1.0→1.04→1.0 over 400 ms; soft sound; no pulse with reduce motion), E2E `patrol_test/e2e_us9_warnings_test.dart` and integration `integration_test/warning_schedule_integration_test.dart` (Android: the real `AlarmScheduler` holds the end and warning requests under one group; cancel removes all)

### Implementation for User Story 9

- [ ] T180 [US9] Schedule warnings in the `TimerController` and the `RoutineRunner` (channel `timer_warning`) in `lib/features/timer/application/timer_controller.dart` and `lib/features/routines/application/routine_runner.dart`
- [ ] T181 [US9] Dial pulse and `transition_soft` sound in `RunScreen`; warning selector in the preset editor and settings in `lib/features/timer/presentation/run_screen.dart`, `lib/features/presets/presentation/preset_editor_screen.dart`, `lib/features/settings/presentation/settings_screen.dart`; strings in `lib/l10n/*.arb`

---

## Phase 13: User Story 10 - Image reveal effects (Priority: P3) — v1.x

### Tests for User Story 10 ⚠️

- [ ] T182 [P] [US10] Tests in `test/unit/features/timer/application/image_effect_test.dart` (reveal inverts sectors; mosaic ≥ 10 steps; puzzle 4/9/16 pieces, one piece every 1/n of the time, pseudo-random order stable per `sessionId`)
- [ ] T183 [P] [US10] Goldens in `test/golden/features/timer/effect_goldens_test.dart` (each effect at 0/33/66/100%; reduce motion), E2E `patrol_test/e2e_us10_effects_test.dart` (Android: preset with the puzzle effect → start 30 s → app in background and back → the dial shows the effect at the real progress) and integration `integration_test/effect_persist_test.dart` (Android, Linux: `imageEffect` survives a restart in presets and in the running session)

### Implementation for User Story 10

- [ ] T184 [US10] Implement effects in `lib/features/timer/presentation/widgets/effects/` (`reveal_painter.dart`, `mosaic_painter.dart`, `puzzle_painter.dart`) and the selection in `DialView`
- [ ] T185 [US10] `imageEffect` selector in the preset editor/home in `lib/features/presets/presentation/preset_editor_screen.dart` and `lib/features/timer/presentation/home_screen.dart`; strings in `lib/l10n/*.arb`

---

## Phase 14: User Story 11 - Long timers with multiple dials (Priority: P3) — v1.x

### Tests for User Story 11 ⚠️

- [ ] T186 [P] [US11] Tests in `test/unit/features/timer/application/multi_dial_layout_test.dart` (dials = ceil(duration/scale); empty from right to left; maximum 12 h) and goldens in `test/golden/features/timer/multi_dial_golden_test.dart` (grid without scrolling on compact), E2E `patrol_test/e2e_us11_long_timer_test.dart` (Android: 2 h 30 min → start → kill the app → reopen shows 3 dials with the real remaining time; the end alarm is pending in `dumpsys alarm`) and integration `integration_test/long_timer_restart_test.dart` (Android, Linux: a 12 h session survives a restart)

### Implementation for User Story 11

- [ ] T187 [US11] Raise the `TimerDuration` limit to 12 h (`FR-082`) in `lib/core/domain/timer_duration.dart` with migration/compatibility, and adjust existing validations and tests
- [ ] T188 [US11] Implement `MultiDialView` in `lib/features/timer/presentation/widgets/multi_dial_view.dart` and wire it into home/run; strings in `lib/l10n/*.arb`

---

## Phase 15: User Story 12 - Widgets and system-level alarm (Priority: P3) — v1.x

### Tests for User Story 12 ⚠️

- [ ] T189 [P] [US12] Tests in `test/unit/features/home_widget/widget_payload_test.dart` (JSON payload from contracts/ui/11; at most 4 favorites; 128×128 thumbnails)
- [ ] T190 [P] [US12] Integration `integration_test/home_widget_integration_test.dart` and E2E `patrol_test/e2e_us12_widget_start_test.dart` (Android)

### Implementation for User Story 12

- [ ] T191 [US12] Implement `HomeWidgetPort` + `WidgetSync` in `lib/core/platform/home_widget/` and `lib/features/home_widget/application/widget_sync.dart` (publishes when favorites change and when starting/stopping)
- [ ] T192 [P] [US12] Android widget in Jetpack Glance: `android/app/src/main/kotlin/io/github/masterkey07/visualtimecounter/widget/PresetsWidget.kt` + `res/xml/presets_widget_info.xml` (2×2 and 4×2)
- [ ] T193 [P] [US12] iOS widget in WidgetKit: `ios/PresetsWidget/` target (SwiftUI, small/medium) with App Group `group.io.github.masterkey07.visualtimecounter`
- [ ] T194 [US12] **Spike** `flutter_alarmkit` on iOS 26 (countdown, Live Activity, authorization); apply the R17 decision criterion (license, release in the last 6 months, 10/10 runs ringing in silent mode within ≤ 1 s, denial handled, no networking); record the decision in `specs/001-visual-timer/research.md` (R17)
- [ ] T195 [US12] Implement `AlarmKitScheduler` (decorator with fallback) in `lib/core/platform/alarm/alarmkit_alarm_scheduler.dart`, the `notice.alarmKit` dialog and the Live Activity; decorator tests in `test/unit/core/platform/alarmkit_alarm_scheduler_test.dart`
- [ ] T196 [US12] Favorites in the preset editor/list (`favorite`, at most 4) in `lib/features/presets/presentation/`; strings in `lib/l10n/*.arb`

---

## Phase 16: User Story 13 - Export and import (Priority: P3) — v1.x

### Tests for User Story 13 ⚠️

- [ ] T197 [P] [US13] Codec tests in `test/unit/features/transfer/export_codec_test.dart` (format from contracts/export-format.md; validations 1–7; id remapping; " (2)" suffixes; exported images are the stored bytes; an imported JPEG fixture with EXIF/GPS is stored re-encoded without metadata; exceeding any limit rejects the whole file with `LimitExceeded`)
- [ ] T198 [P] [US13] Atomicity tests in `test/unit/features/transfer/import_atomicity_test.dart` (a failure injected midway restores state; replace mode)
- [ ] T199 [P] [US13] Widget tests in `test/widget/features/transfer/transfer_screen_test.dart`; integration `integration_test/transfer_roundtrip_test.dart`; E2E `patrol_test/e2e_us13_export_android_test.dart`

### Implementation for User Story 13

- [ ] T200 [US13] Implement `ExportBundle` and `ExportCodec` in `lib/features/transfer/domain/` and `lib/features/transfer/data/export_codec.dart`
- [ ] T201 [US13] Implement an atomic `ImportService` (temporary boxes and swap; every image re-processed through `ImageProcessor`; limits checked before writing) in `lib/features/transfer/application/import_service.dart`
- [ ] T202 [US13] Implement `TransferScreen` (`/transfer`, parental gate) with `share_plus` (mobile) and `file_selector` (desktop/Web) in `lib/features/transfer/presentation/transfer_screen.dart`; strings in `lib/l10n/*.arb`

**Checkpoint**: SC-012 validated.

---

## Phase 17: User Story 14 - Additional themes, palettes and languages (Priority: P3) — v1.x

### Tests for User Story 14 ⚠️

- [ ] T203 [P] [US14] Tests in `test/unit/app/theme/high_contrast_test.dart` (the manual high-contrast choice overrides the system setting; text and icons ≥ 7:1) and `test/unit/app/theme/colorblind_palettes_test.dart` (protanopia, deuteranopia, tritanopia: distinguishable phases, luminance ≥ 20%)
- [ ] T204 [P] [US14] High-contrast theme and palette goldens in `test/golden/app/themes_golden_test.dart`, E2E `patrol_test/e2e_us14_high_contrast_test.dart` (Android: choose high contrast and the deuteranopia palette in settings → restart → home and `/run` use them) and the `highContrast`/palette cases in `integration_test/theme_persist_test.dart`

### Implementation for User Story 14

- [ ] T205 [US14] Add the manual high-contrast option (reusing the T050 high-contrast variant) and implement the `protanopia`, `deuteranopia`, `tritanopia` palettes in `lib/app/theme/`, with the options in settings
- [ ] T206 [US14] Set up Hosted Weblate (project, ARB component, automatic PRs) and document it in `docs/translations.md`; CI accepts a new language only if 100% translated (`tool/l10n_check.dart --complete-only`)

---

## Phase 18: Release v1.x

- [ ] T207 Update `docs/release-checklist.md` with routines, warnings, widgets, AlarmKit, export
- [ ] T208 Run validation of US8–US14 (quickstart §5) and the checklist; record in `docs/releases/v1.x.md`; update `CHANGELOG.md` and create tags `v1.1.0`… for the incremental deliveries

---

## Phase 19: Polish & Cross-Cutting Concerns

- [ ] T209 [P] Update `README.md` (screenshots, platforms, installation, privacy, how to contribute) and `docs/architecture.md`
- [ ] T210 [P] Review coverage and add missing tests to reach the thresholds across `lib/` (report `coverage/lcov.info`, tests in `test/`)
- [ ] T211 Run `/speckit-analyze` again and resolve inconsistencies between `specs/001-visual-timer/` (spec, plan, tasks) and the code
- [ ] T212 Final security/privacy review: traffic inspection on every platform (SC-008), review of each platform's permissions and of new dependencies

## Traceability (requirement → tasks)

Every requirement and success criterion in the spec has test and implementation tasks. The
corresponding tests per level are in [testing-strategy.md](./testing-strategy.md) §3.

| Requirement | Tasks                                          |
| ----------- | ---------------------------------------------- |
| FR-001      | T022, T023, T057, T059, T066, T071             |
| FR-002      | T057, T062, T068, T069                         |
| FR-003      | T026, T027, T058, T060, T067, T072             |
| FR-004      | T030, T070                                     |
| FR-005      | T058, T061, T073                               |
| FR-006      | T035, T036, T058, T067                         |
| FR-007      | T058, T067                                     |
| FR-010      | T026, T027                                     |
| FR-011      | T038, T040, T043, T044, T048, T081, T082, T087 |
| FR-012      | T042                                           |
| FR-013      | T033, T034, T077, T080, T086                   |
| FR-014      | T078, T080, T085                               |
| FR-015      | T041, T076, T079, T084, T088                   |
| FR-016      | T040, T076, T083, T084, T088                   |
| FR-017      | T043                                           |
| FR-018      | T046, T090                                     |
| FR-020      | T092, T093, T094, T095, T103                   |
| FR-021      | T101, T106, T110                               |
| FR-022      | T096, T099, T108                               |
| FR-023      | T096, T104                                     |
| FR-024      | T097, T099, T105, T108, T132                   |
| FR-025      | T098, T107, T109                               |
| FR-026      | T094, T095, T103                               |
| FR-030      | T113, T117, T118                               |
| FR-031      | T112, T116, T117                               |
| FR-032      | T119, T142                                     |
| FR-033      | T090                                           |
| FR-040      | T121, T122, T123, T127, T128, T129, T130       |
| FR-041      | T126, T131                                     |
| FR-042      | T122, T128                                     |
| FR-050      | T022, T062, T144                               |
| FR-051      | T022, T136, T144, T145                         |
| FR-052      | T134, T137, T143                               |
| FR-053      | T137, T144                                     |
| FR-054      | T045, T058                                     |
| FR-055      | T050, T051, T138, T144                         |
| FR-056      | T135, T139, T141                               |
| FR-060      | T029, T149, T155                               |
| FR-061      | T063, T149, T155                               |
| FR-062      | T054, T156                                     |
| FR-063      | T147, T148, T151, T152                         |
| FR-064      | T148, T153, T154                               |
| FR-065      | T015, T018, T212                               |
| FR-070      | T166, T168, T171, T172, T175                   |
| FR-071      | T167, T173                                     |
| FR-072      | T169, T175                                     |
| FR-073      | T167, T170, T173                               |
| FR-074      | T166, T169, T175                               |
| FR-075      | T174                                           |
| FR-080      | T178, T179, T180, T181                         |
| FR-081      | T182, T183, T184, T185                         |
| FR-082      | T186, T187, T188                               |
| FR-090      | T189, T190, T191, T192, T193, T196             |
| FR-091      | T194, T195                                     |
| FR-100      | T197, T199, T200, T202                         |
| FR-101      | T198, T201                                     |
| FR-110      | T203, T204, T205                               |
| FR-111      | T206                                           |
| SC-001      | T164                                           |
| SC-002      | T081, T082, T164                               |
| SC-003      | T113, T115                                     |
| SC-004      | T158                                           |
| SC-005      | T101, T164                                     |
| SC-006      | T126                                           |
| SC-007      | T149                                           |
| SC-008      | T015, T164, T212                               |
| SC-009      | T158                                           |
| SC-010      | T164                                           |
| SC-011      | T170, T208                                     |
| SC-012      | T199, T208                                     |

---

## Dependencies & Execution Order

### Phase Dependencies

```text
Phase 1 Setup ─▶ Phase 2 Foundational ─▶ US1 ─▶ US2 ─▶ US3 ─┬─▶ US4 ─┐
                                                            ├─▶ US5 ─┼─▶ US7 ─▶ Phase 10 (v1.0)
                                                            └─▶ US6 ─┘
Phase 10 ─▶ US8 ─▶ US9 ─┐
          ├─▶ US10      ├─▶ Phase 18 (v1.x) ─▶ Phase 19
          ├─▶ US11      │
          ├─▶ US12 ─────┤   (US12 needs US5 favorites)
          ├─▶ US13 ─────┤   (US13 needs US5 and US8)
          └─▶ US14 ─────┘
```

### User Story Dependencies

- **US1 (P1)**: depends only on Phase 2.
- **US2 (P1)**: depends on US1 (TimerController, RunScreen).
- **US3 (P1)**: depends on US1 (DialPainter, HomeScreen); independent of US2.
- **US4 (P2)**: depends on US1 (RunScreen); independent of US2/US3.
- **US5 (P2)**: depends on US1; uses US3 (images in the examples; T128 depends on T094).
- **US6 (P2)**: depends on US1; integrates with US5 (preset editor).
- **US7 (P2)**: depends on the existing screens (final a11y sweep); the parental gate is
  independent.
- **US8 (P3)**: depends on US1–US3; US9 uses the RoutineRunner for step warnings.
- **US10, US11, US14**: depend on US1/US3/US6.
- **US12**: depends on US5 (favorites) and US2 (alarm).
- **US13**: depends on US5 and US8.

### Within Each User Story

- Tests (unit → widget/golden → integration → E2E) written and failing before implementation.
- Domain → data → application → presentation → strings.
- Green checkpoint before the next story.

### Parallel Opportunities

- Phase 1: T004–T012 in parallel.
- Phase 2: tooling (T014–T017), value objects (T022/T023), fakes (T038/T039), real ports
  (T045/T046), theme (T050/T051) in parallel.
- After US1: US3 and US4 can proceed in parallel; then US5 and US6.
- Within each story, all [P] test tasks in parallel.
- v1.x: US10, US11 and US14 in parallel after v1.0.

---

## Parallel Example: User Story 1

```bash
# US1 tests together (must fail):
Task: "Dial geometry tests in test/unit/features/timer/application/dial_geometry_test.dart"
Task: "TimerController tests in test/unit/features/timer/application/timer_controller_test.dart"
Task: "Home screen widget tests in test/widget/features/timer/home_screen_test.dart"
Task: "Goldens in test/golden/features/timer/dial_view_golden_test.dart"

# Independent visual components together:
Task: "Implement DialPainter in lib/features/timer/presentation/widgets/dial_painter.dart"
Task: "Implement DigitsLabel and DurationQuickButtons in lib/features/timer/presentation/widgets/"
```

## Parallel Example: User Story 3

```bash
Task: "Manifest test in test/unit/features/images/image_bank_manifest_test.dart"
Task: "ImageProcessor tests in test/unit/features/images/image_processor_test.dart"
Task: "UserImageRepository tests in test/unit/features/images/user_image_repository_test.dart"
Task: "Implement the real ImagePickerPort in lib/core/platform/image_picker/image_picker_port_impl.dart"
```

---

## Implementation Strategy

### MVP First

1. Phases 1 and 2 (foundation, CI, time engine, ports).
2. US1 → **validate** (working timer with the app open).
3. US2 → **validate** (reliable alarm) — first trust milestone.
4. US3 → **validate** (mandatory image requirement) — minimal demonstrable MVP.
5. US4, US5, US6, US7 → Phase 10 → **v1.0**.

### Incremental Delivery (v1.x)

Each P3 story becomes a minor version: v1.1 (US8 + US9), v1.2 (US10 + US11), v1.3 (US12), v1.4
(US13), v1.5 (US14). Each one goes through the release checklist.

### Execution by an agent (another session)

1. Read `CLAUDE.md`, the constitution and this list.
2. `/speckit-implement` (or "Implement the tasks of Phase N") executes in order, marking `[x]`.
3. Stop at every Checkpoint and report the result of the verification commands.
4. Tasks marked **Spike** record their decisions in research.md before moving on.

---

## Notes

- [P] = different files, no pending dependencies.
- [Story] maps the task to a story (traceability with the spec and testing-strategy §3).
- Never implement before seeing the test fail.
- Commit after each task or logical group; one PR per story.
- Avoid: vague tasks, conflicts in the same file in parallel, cross-story dependencies that
  break independence.
