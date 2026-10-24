# Testing Strategy: Kid Timer

**Feature**: `001-visual-timer` | **Date**: 2026-10-23 | **Plan**: [plan.md](./plan.md)
**Governance**: Constitution, Principle IV (Test-First and the Test Pyramid)

This document defines **which tests are mandatory**, at which level, where they live and how
they run. The tasks in [tasks.md](./tasks.md) create each suite before the corresponding
implementation.

## 1. Pyramid and responsibilities

| Level       | Tool                                              | Folder                      | Runs on                                                                 | What it proves                                                                                                          | Target                      |
| ----------- | ------------------------------------------------- | --------------------------- | ----------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- | --------------------------- |
| Unit        | `flutter_test`, `mocktail`, `fake_async`, `clock` | `test/unit/`                | VM (CI on every PR)                                                     | Domain, time engine, controllers, repositories (with in-memory Hive), validation, migrations                            | ~70% of tests; < 30 s       |
| Contract    | `flutter_test`                                    | `test/contract/`            | VM + integration                                                        | That fakes and real port implementations obey the same contract                                                         | 1 suite per port            |
| Widget      | `flutter_test`                                    | `test/widget/`              | VM                                                                      | Screens and components, semantics, accessibility guidelines, keyboard, states                                           | ~20%                        |
| Golden      | `alchemist`                                       | `test/golden/`              | VM (CI goldens with Ahem)                                               | Visual regression of the dial and screens across themes and sizes                                                       | 1 per relevant visual state |
| Integration | `integration_test`                                | `integration_test/`         | Android emulator, Linux desktop (xvfb), Chrome                          | Real app with real persistence and ports; app restart; performance                                                      | flows per story             |
| End-to-End  | Patrol 4.x                                        | `patrol_test/`              | Android emulator (CI), iOS simulator/device (release), macOS (optional) | Complete flows with the system: notifications, permissions, photo picker, locked screen, killed app, deep links, widget | 1+ per story                |
| Manual      | checklist                                         | `docs/release-checklist.md` | Real devices                                                            | Vendors with aggressive optimization, iPhone silent mode, real audio, projector                                         | per release                 |

## 2. Rules

1. **TDD**: every implementation task has a preceding test task that MUST fail first (`test:`
   commit before `feat:`).
2. **Determinism**: injected `Clock` (`package:clock` + provider), `fake_async` for timers,
   injected `Random` (parental gate, puzzle), no `sleep`, no network, no dependency on the local
   time zone (tests run with `TZ=America/Sao_Paulo` and `TZ=UTC` in CI).
3. **Hive in tests**: `Hive.init(tempDir)` per test with cleanup; never the user's real boxes.
4. **Keys**: tests find widgets by the `Key`s defined in the UI contracts, never by text (text
   changes with the language).
5. **Languages**: the main widget tests run in `pt` and `en` (parameterized).
6. **Accessibility in widget tests**: every screen has a test with
   `meetsGuideline(androidTapTargetGuideline)`, `iOSTapTargetGuideline`,
   `labeledTapTargetGuideline` and `textContrastGuideline`, and a test with
   `textScaler: TextScaler.linear(2.0)` without overflow (`tester.takeException() == null`).
7. **Goldens**: minimum matrix per screen = {light, dark, high-contrast light} × {compact 360×800, compact
   landscape 800×360, medium 800×1280, expanded 1440×900}; dial: {0, 25, 50, 100%} × {progressive color, calm, image} ×
   {clockwise, counter-clockwise}.
8. **Coverage**: `lib/core/**` ≥ 95%, `lib/features/**/application/**` ≥ 85%, overall ≥ 80%
   (excluding exactly: `lib/**/*.g.dart`, `lib/l10n/generated/**`, `lib/main*.dart`,
   `lib/core/platform/**/impl/**` — platform implementations covered by integration tests).
   `tool/check_coverage.dart` (T014) uses this same list.
9. **Regression**: every fixed bug gets a test that failed before the fix.
10. **Flakiness**: an unstable test is quarantined with an issue opened within 24 h; it may not
    stay quarantined for more than 7 days.

## 3. Traceability matrix (requirement → tests)

| Req.                                 | Unit                                                                      | Widget/Golden                                                         | Integration                                | E2E                                                       |
| ------------------------------------ | ------------------------------------------------------------------------- | --------------------------------------------------------------------- | ------------------------------------------ | --------------------------------------------------------- |
| FR-001 duration/adjustment           | `timer_duration_test`, `dial_geometry_test`                               | `home_screen_test` (drag, buttons, keyboard)                          | —                                          | `e2e_us1_basic_timer`                                     |
| FR-002 proportional dial             | `dial_geometry_test`                                                      | `dial_view_golden_test`                                               | —                                          | —                                                         |
| FR-003 controls                      | `timer_engine_test`, `timer_controller_test`                              | `run_screen_test`                                                     | —                                          | `e2e_us1_basic_timer`                                     |
| FR-004 digits                        | `duration_format_test`                                                    | `home_screen_test`, `run_screen_test`                                 | —                                          | —                                                         |
| FR-005 final screen                  | `timer_controller_test`                                                   | `finished_screen_test` + golden                                       | `restart_shows_finished_test`              | `e2e_us2_alarm_closed_app`                                |
| FR-006 last config                   | `settings_repository_test`                                                | —                                                                     | `persistence_roundtrip_test`               | —                                                         |
| FR-007 one timer at a time           | `timer_controller_test` (replace after confirmation)                      | `home_screen_test`                                                    | —                                          | —                                                         |
| FR-010 absolute time                 | `timer_engine_test` (pause, resume, clock, time zone)                     | —                                                                     | —                                          | —                                                         |
| FR-011 OS alarm                      | `alarm_scheduler_contract` (fake)                                         | —                                                                     | `alarm_scheduler_contract` (real, Android) | `e2e_us2_alarm_locked_screen`, `e2e_us2_alarm_closed_app` |
| FR-012 Windows alarm                 | `alarm_scheduler_contract` (fake)                                         | —                                                                     | spike T042 (manual, criteria in R4)        | manual (release checklist, Windows)                       |
| FR-013 restore state                 | `session_repository_test`, `reconcile_test`                               | —                                                                     | `restart_resumes_running_test`             | `e2e_us2_alarm_closed_app`                                |
| FR-014 screen on                     | `run_controller_test` (fake)                                              | —                                                                     | `wakelock_integration_test`                | —                                                         |
| FR-015/016 notices/permissions       | `start_preflight_test`                                                    | `notices_test`                                                        | —                                          | `e2e_us2_permissions_android`                             |
| FR-017 reboot                        | —                                                                         | —                                                                     | —                                          | manual (checklist)                                        |
| FR-018 battery help                  | —                                                                         | `battery_help_screen_test`                                            | —                                          | —                                                         |
| FR-020 library                       | `image_bank_manifest_test` (42+, 7 categories, licenses)                  | `image_picker_screen_test`                                            | —                                          | —                                                         |
| FR-021 picker without permission     | `tool/privacy_check.dart` (manifest without media permissions)            | —                                                                     | —                                          | `e2e_us3_own_image`                                       |
| FR-022/023 frame/process             | `image_processor_test` (EXIF removed, 1024 px)                            | `frame_screen_test`                                                   | `user_image_persist_test`                  | `e2e_us3_own_image`                                       |
| FR-024 my images                     | `user_image_repository_test`                                              | `my_images_screen_test`                                               | —                                          | —                                                         |
| FR-025 image on the dial             | `dial_geometry_test`                                                      | `dial_view_golden_test` (image)                                       | —                                          | `e2e_us3_bank_image`                                      |
| FR-026 accessible image names        | `image_bank_manifest_test` (pt and en names)                              | `image_picker_screen_test` (semantics labels)                         | —                                          | —                                                         |
| FR-030–033 child mode                | `unlock_controller_test`                                                  | `run_screen_child_lock_test` (30 random gestures, Esc)                | `child_lock_integration_test`              | `e2e_us4_child_lock`                                      |
| FR-040–042 presets                   | `preset_repository_test`, `preset_test`                                   | `presets_screen_test`, `preset_editor_test`                           | `presets_persist_test`                     | `e2e_us5_presets`                                         |
| FR-050–056 appearance/sound          | `palette_test`, `settings_controller_test`                                | `settings_screen_test`, palette goldens (incl. high-contrast variant) | `theme_persist_test`                       | `e2e_us6_calm_mode`                                       |
| FR-060–062 a11y/i18n                 | `announce_throttle_test`, `locale_resolution_test`                        | per-screen guidelines, 200% font, keyboard                            | `locale_and_gate_integration_test`         | `e2e_us7_a11y_smoke`                                      |
| FR-063/064 gate/parent area          | `gate_challenge_test`, `number_words_test`                                | `parental_gate_test`, `parent_area_test`                              | —                                          | `e2e_us7_parental_gate`                                   |
| FR-065 no collection                 | `tool/privacy_check.dart` (CI)                                            | —                                                                     | —                                          | traffic inspection (release)                              |
| FR-070–075 routines                  | `routine_test`, `routine_runner_test`                                     | `routine_editor_test`, `routine_run_screen_test`                      | `routine_persist_test`                     | `e2e_us8_routine_background`                              |
| FR-080 warnings                      | `warning_schedule_test`                                                   | `run_screen_warning_test`                                             | `warning_schedule_integration_test`        | `e2e_us9_warnings`                                        |
| FR-081 effects                       | `image_effect_test`                                                       | `effect_goldens_test`                                                 | `effect_persist_test`                      | `e2e_us10_effects`                                        |
| FR-082 multiple dials                | `multi_dial_layout_test`                                                  | `multi_dial_golden_test`                                              | `long_timer_restart_test`                  | `e2e_us11_long_timer`                                     |
| FR-090/091 widgets/AlarmKit          | `widget_payload_test`                                                     | —                                                                     | `home_widget_integration_test`             | `e2e_us12_widget_start` (Android)                         |
| FR-100/101 export/import             | `export_codec_test`, `import_atomicity_test`                              | `transfer_screen_test`                                                | `transfer_roundtrip_test`                  | `e2e_us13_export_android`                                 |
| FR-110 high contrast/color blindness | `high_contrast_test`, `colorblind_palettes_test`, `colorblind_check_test` | theme goldens                                                         | `theme_persist_test`                       | `e2e_us14_high_contrast`                                  |
| SC-004 performance                   | —                                                                         | —                                                                     | `perf_dial_animation_test` (profile)       | —                                                         |
| SC-009 cold start                    | —                                                                         | —                                                                     | `perf_startup_test`                        | —                                                         |

## 4. Mandatory E2E scenarios (Patrol)

| ID                            | Platforms                          | Steps                                                                                                            | Verification                                                                     |
| ----------------------------- | ---------------------------------- | ---------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| `e2e_us1_basic_timer`         | Android, iOS                       | Open app → drag dial to 1 min → Start → wait                                                                     | Final screen appears; tap returns home                                           |
| `e2e_us2_alarm_locked_screen` | Android, iOS                       | Start 1 min → `$.native.pressHome()`/lock screen → wait                                                          | "Time's up!" notification visible in the tray/lock screen within ≤ 65 s          |
| `e2e_us2_alarm_closed_app`    | Android                            | Start 1 min → kill the app (not `am force-stop`; use `killApp`/swipe from recents) → wait → tap the notification | App opens on `/finished`                                                         |
| `e2e_us2_permissions_android` | Android 14                         | Deny notifications → Start                                                                                       | `notice.notificationsDenied` dialog; "Open settings" opens the app's page        |
| `e2e_us3_bank_image`          | Android, iOS                       | Choose a library image → Start 30 s                                                                              | Screenshot of the dial with the image at ~50%                                    |
| `e2e_us3_own_image`           | Android, iOS                       | "From my device" → system picker (seeded photo) → frame → save                                                   | No permission dialog; image appears on the dial                                  |
| `e2e_us4_child_lock`          | Android, iOS                       | Start → 30 taps/gestures → back button (Android) → hold padlock 3 s                                              | State unchanged until unlock; controls appear                                    |
| `e2e_us5_presets`             | Android                            | Create preset → restart app → start in 2 taps                                                                    | `/run` with the preset's config                                                  |
| `e2e_us6_calm_mode`           | Android                            | Enable calm mode, ticking off → start 20 s                                                                       | Screen golden with no red; no tick audio (audio port instrumented in debug mode) |
| `e2e_us7_a11y_smoke`          | Android (TalkBack enabled via adb) | Navigate and start using accessibility focus                                                                     | Timer starts                                                                     |
| `e2e_us7_parental_gate`       | Android                            | ⓘ → answer wrong 3× → wait 30 s → answer right                                                                   | Parent area opens                                                                |
| `e2e_us8_routine_background`  | Android                            | Automatic 3×30 s routine → app in background                                                                     | 3 step notifications                                                             |
| `e2e_us9_warnings`            | Android                            | 2 min timer with 1 min warning → background                                                                      | Warning and end notifications                                                    |
| `e2e_us12_widget_start`       | Android                            | Add widget (adb) → tap preset                                                                                    | App on `/run`                                                                    |
| `e2e_us10_effects`            | Android                            | Preset with the puzzle effect → Start 30 s → background → foreground                                             | Dial shows the effect at the real progress (screenshot)                          |
| `e2e_us11_long_timer`         | Android                            | 2 h 30 min → Start → kill the app → reopen                                                                       | 3 dials with the real remaining time; end alarm pending in `dumpsys alarm`       |
| `e2e_us13_export_android`     | Android                            | Export → share sheet appears                                                                                     | File generated                                                                   |
| `e2e_us14_high_contrast`      | Android                            | Settings: high contrast + deuteranopia palette → restart                                                         | Home and `/run` use the chosen theme and palette (screenshot)                    |

Local run: `patrol test -t patrol_test/<file>.dart --device <id>`.
CI: `e2e-android.yml` runs the whole folder on the API 34 (x86_64) emulator for PRs labeled
`e2e` and daily on `main`; iOS runs in the release checklist (optional macOS runner).

## 5. Integration tests (`integration_test/`)

| File                                                                                                                                                                           | CI platforms                      | Scenario                                                                   |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------- | -------------------------------------------------------------------------- |
| `persistence_roundtrip_test.dart`                                                                                                                                              | Android, Linux, Web               | Write settings/presets/session, restart `ProviderContainer` + reopen boxes |
| `restart_resumes_running_test.dart`                                                                                                                                            | Android, Linux                    | Persisted `running` session → new app → `/run` with correct remaining time |
| `restart_shows_finished_test.dart`                                                                                                                                             | Android, Linux                    | Expired, unacknowledged session → `/finished`                              |
| `alarm_scheduler_contract_test.dart`                                                                                                                                           | Android                           | Real port contract (schedule, replace, cancel, group)                      |
| `wakelock_integration_test.dart`                                                                                                                                               | Android, Linux                    | Entering/leaving `/run` toggles the wakelock                               |
| `user_image_persist_test.dart`                                                                                                                                                 | Android, Linux, Web               | Save processed image; reopen; bytes intact                                 |
| `presets_persist_test.dart`                                                                                                                                                    | Android, Linux, Web               | CRUD + order after restart                                                 |
| `alarm_accuracy_test.dart`                                                                                                                                                     | Android, Linux                    | 20 runs of 30 s; `playAlarm` within ≤ 1 s of `endsAt` (SC-002 foreground)  |
| `theme_persist_test.dart`                                                                                                                                                      | Linux                             | Theme and palette persist (v1.x: high contrast and color-blind palettes)   |
| `child_lock_integration_test.dart`                                                                                                                                             | Android, Linux                    | Real fullscreen/lifecycle ports; Esc 3 s unlocks on Linux                  |
| `locale_and_gate_integration_test.dart`                                                                                                                                        | Linux, Web                        | en/pt-BR from the platform locale, en fallback; gate → `/parent`           |
| `perf_dial_animation_test.dart`                                                                                                                                                | Android (profile, manual/nightly) | `traceAction` over 10 s of countdown; ≥ 99% frames < 16 ms                 |
| `perf_startup_test.dart`                                                                                                                                                       | Android (profile, nightly)        | Time to first useful frame ≤ 2 s                                           |
| v1.x: `routine_persist_test`, `transfer_roundtrip_test`, `home_widget_integration_test`, `warning_schedule_integration_test`, `effect_persist_test`, `long_timer_restart_test` | per story                         | —                                                                          |

Commands: `flutter test integration_test -d linux` (with `xvfb-run`), `flutter test
integration_test -d emulator-5554`, Web: `flutter drive --driver=test_driver/integration_test.dart
--target=integration_test/<f>.dart -d web-server --browser-name=chrome`.

## 6. Verification tools (tool/)

- `tool/check_coverage.dart` — reads `coverage/lcov.info`, applies per-path thresholds, fails
  CI.
- `tool/privacy_check.dart` — fails if: the merged release manifest contains `INTERNET`;
  `pubspec.lock` contains a denylisted package; `lib/` imports networking APIs; macOS
  entitlements allow network; iOS/macOS `Info.plist` has ATS exceptions; `web/` references
  external URLs or CDNs; Windows/Linux runner sources call networking APIs (research R22).
- `tool/sounds/check_sounds.dart` — fails if any bundled sound misses the research R6 targets
  (loudness, true peak, attack, duration).
- `tool/license_check.dart` — fails if any asset is missing from the folder's `LICENSES.md` or
  if the license is not allowed (Constitution IX).
- `tool/l10n_check.dart` — fails if any key in `app_pt.arb` is missing from `app_en.arb` or
  vice versa.

## 7. Manual release checklist (summary; full version in `docs/release-checklist.md`)

- Alarm with locked screen and killed app on: Samsung (One UI), Xiaomi (HyperOS), Motorola,
  Pixel; iPhone (silent on/off), iPad; macOS; Windows.
- Device reboot with a pending timer (Android).
- Traffic inspection (mitmproxy/Little Snitch/Wireshark) showing 0 connections (SC-008).
- VoiceOver/TalkBack/NVDA/Orca: main flow.
- Projector/external monitor in full screen (desktop).

## 8. Measurement protocols (success criteria)

Results of every protocol are recorded in `docs/releases/<version>.md` with device, OS version,
app commit and date.

**SC-001 / SC-005 (usability)**

- Participants: 5 adults aged 18+, each a parent, caregiver, teacher or therapist of children
  aged 3–12; they own a smartphone; they have never seen the app; at least 2 are not developers.
- "Without instructions": the facilitator reads the task once ("Start a 5-minute timer" /
  "Put a photo of your choice on the dial") and answers no questions; no onboarding beyond what
  the app shows.
- Timing: from the home screen being visible to the `home.start` tap (SC-001) or to the photo
  appearing on the dial (SC-005), from a screen recording. Pass: median ≤ 15 s / ≤ 30 s.

**SC-002 (alarm accuracy)**

- Foreground (≤ 1 s): debug-instrumented build logs `endsAt` and the instant `AudioPort.playAlarm`
  is called (both from the same clock); automated on Android and Linux in
  `integration_test/alarm_accuracy_test.dart` (20 runs of 30 s).
- Background (≤ 5 s): the notification's post time vs. `endsAt`. Android: `adb shell dumpsys
notification --noredact` (`when`/`postTime`) in `e2e_us2_alarm_locked_screen` and
  `e2e_us2_alarm_closed_app`; iOS/macOS/Windows: screen recording with an on-screen
  reference clock synced to the device, frame-accurate reading. 20 runs per platform.

**SC-003 (child lock)**

- Automated (`run_screen_child_lock_test`): 30 seeded sequences (`Random(42)`), each of 20
  gestures drawn uniformly from {tap, double tap, long press < 3 s, drag, fling, pinch, two-
  finger tap, back button, system keys except Esc held 3 s}, at positions uniform over the
  whole screen including the padlock. Pass: session state and route unchanged.
- Manual (release checklist): 30 sessions of 20 s each with a child aged 3–6 (guardian
  present) or, if unavailable, an adult imitating free play with both hands; Android and iPad.
  Pass: 0 pauses, cancellations or exits.

**SC-004 / SC-009 (performance)**: on the reference device of research R21, profile build,
battery ≥ 50% and battery saver off; `perf_dial_animation_test` and `perf_startup_test`, 5 runs,
worst run reported.

**SC-008 (no network)**

- Tools: Android — PCAPdroid (no root) or mitmproxy with the device on a controlled Wi-Fi;
  iOS/macOS — Little Snitch (macOS) and a Wireshark capture of the iPhone's tethered interface
  (`rvictl`); Windows — Windows Firewall logging in "block all outbound" mode for the app plus
  Wireshark; Linux — `nethogs` and `strace -f -e trace=network`; Web — the browser DevTools
  Network tab with "Preserve log" (only same-origin static asset requests are allowed).
- Scenario: cold start → the quickstart §5 main flow (timer, image from the library and from
  the device, preset, settings, parent area without confirming the external link) → a 10 min
  timer running in the background → reopen. Minimum observation: 15 min per platform.
- Pass: 0 connections initiated by the app's process (Web: 0 requests to any origin other than
  the one serving the app).

**SC-010 (field test)**: 3 participants (families, teachers or therapists) use the app for 7
consecutive days; at the end they answer "Would you use this app instead of your current
solution?" (yes/no + comment). Pass: ≥ 2 of 3 "yes".
