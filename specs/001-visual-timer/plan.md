# Implementation Plan: Visual Time Counter (v1.0 and v1.x)

**Branch**: `001-visual-timer` | **Date**: 2026-10-23 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-visual-timer/spec.md`

## Summary

A single Flutter app for Android, iOS/iPadOS, Windows, macOS, Linux and Web: the adult sets up a
timer (duration, an image from the built-in library or from the device, or colors) and the
child watches a dial shrink until the celebration screen. The central technical approach is a
**pure-Dart time engine based on absolute instants** (`endsAt − now`) with an **alarm scheduled
with the operating system** via `flutter_local_notifications`, local persistence with `hive_ce`,
a dial drawn by a `CustomPainter` and every platform dependency behind testable ports. v1.0
delivers US1–US7; v1.x delivers US8–US14. Details in [research.md](./research.md).

## Technical Context

**Language/Version**: Dart 3.x with stable Flutter 3.47.x (pinned in `.fvmrc`)

**Primary Dependencies**: `flutter_riverpod` 3, `go_router`, `flutter_local_notifications`
22.x + `timezone`, `wakelock_plus`, `audioplayers`, `hive_ce` + `hive_ce_flutter`,
`image_picker`, `file_selector`, `image`, `path_provider`, `window_manager`, `url_launcher`,
`uuid`, `clock`, `flutter_localizations`/`intl`; v1.x: `home_widget`, `flutter_alarmkit`,
`share_plus`. Dev: `very_good_analysis`, `mocktail`, `fake_async`, `alchemist`, `patrol`,
`integration_test`.

**Storage**: `hive_ce` (files in the app support directory; IndexedDB on the Web). Schema in
[contracts/persistence-schema.md](./contracts/persistence-schema.md).

**Testing**: unit/widget/golden (`flutter_test`, `mocktail`, `fake_async`, `alchemist`),
integration (`integration_test` on Android, Linux and Web), E2E (Patrol on Android and iOS). See
[testing-strategy.md](./testing-strategy.md).

**Target Platform**: Android 8.0+ (API 26, target 36), iOS/iPadOS 16+, macOS 13+, Windows 10+,
Linux x64 (GTK 3), Web (current Chrome, Edge, Firefox, Safari).

**Project Type**: cross-platform client application (mobile + desktop + web), no backend.

**Performance Goals**: dial at 60 fps (120 fps where available), ≥ 99% of frames < 16 ms on the
reference device; cold start ≤ 2 s; own-image processing ≤ 1.5 s.

**Constraints**: 100% offline, zero network/telemetry, no `INTERNET` permission in the Android
release, no broad storage permissions; APK per ABI ≤ 25 MB; alarm ≤ 1 s in the foreground and
≤ 5 s in the background; WCAG 2.2 AA; complete pt-BR and en.

**Scale/Scope**: ~13 screens/flows (v1.0: 9), ≤ 100 presets, ≤ 50 own images, ≤ 100 routines of
up to 20 steps; 36+ bundled images and 8+ sounds.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | How the plan complies | Status |
|---|---|---|
| I. Privacy by Design | No network, no third-party SDKs that collect data; Android release without `INTERNET`; images processed and stored locally without EXIF; export only by adult action; `tool/privacy_check.dart` in CI | ✅ |
| II. Child Safety and Well-being | Child mode absorbs touches with a 3 s unlock; parental gate for ways out; gentle sounds; calm mode; reviewed assets; no ads/purchases | ✅ |
| III. Time Reliability | Pure `TimerEngine` with `Clock`; `endsAt` in UTC; persistence before scheduling; reconcile on resume/boot; OS alarm; notices where unsupported | ✅ |
| IV. Test-First | Test tasks before each implementation; unit/widget/golden/integration/E2E suites per story; coverage thresholds in CI ([testing-strategy.md](./testing-strategy.md)) | ✅ |
| V. Accessibility | Dial semantics as a slider, throttled announcements, full keyboard support, 200% font, reduce motion, Atkinson Hyperlegible, guidelines in widget tests | ✅ |
| VI. Parity and Honest Degradation | Ports with per-platform implementations and `capabilities()`; `PlatformNotice` and preflight; compact/medium/expanded layouts | ✅ |
| VII. Clean Architecture and Simplicity | Layered feature-first; Flutter-free domain; Riverpod without codegen; single persistence (hive_ce) | ✅ (extra dependencies justified below) |
| VIII. Quality and Performance | `very_good_analysis`, `RepaintBoundary`, cached static layer, targets measured by performance tests | ✅ |
| IX. Free Software | Apache-2.0; Fluent Emoji assets (MIT), CC0 sounds, OFL font; `tool/license_check.dart`; no third-party trademarks | ✅ |

**Post-design re-check (Phase 1)**: the UI, port, persistence and export contracts introduced no
violations. Packages outside the Constitution's approved list are justified in Complexity
Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/001-visual-timer/
├── spec.md                 # /speckit-specify + /speckit-clarify
├── plan.md                 # This file
├── research.md             # Phase 0
├── data-model.md           # Phase 1
├── testing-strategy.md     # Phase 1 (required by Constitution IV)
├── quickstart.md           # Phase 1
├── contracts/
│   ├── platform-ports.md
│   ├── persistence-schema.md
│   ├── export-format.md
│   └── ui/                 # 00 navigation/layout + 01–11 per screen
├── checklists/
│   ├── requirements.md
│   ├── ux.md
│   └── testing.md
├── tasks.md                # /speckit-tasks
└── analysis.md             # /speckit-analyze
```

### Source Code (repository root)

```text
lib/
├── main.dart                         # entry point; calls bootstrap()
├── bootstrap.dart                    # Hive, timezone, per-platform ports, ProviderScope
├── app/
│   ├── app.dart                      # MaterialApp.router, themes, l10n, global shortcuts
│   ├── router.dart                   # go_router: routes, guards, deep links
│   ├── theme/                        # tokens, palettes.dart, app_theme.dart, typography.dart
│   └── widgets/                      # platform_notice.dart, confirm_dialog.dart
├── core/
│   ├── clock/clock_provider.dart
│   ├── domain/                       # timer_config.dart, timer_duration.dart, dial_scale.dart,
│   │                                 # visual_source.dart, palette_id.dart, sound_id.dart,
│   │                                 # image_effect.dart, json_utils.dart
│   ├── timer_engine/                 # timer_session.dart, session_status.dart, timer_engine.dart
│   ├── platform/                     # ports + implementations + providers.dart
│   │   ├── alarm/                    # alarm_scheduler.dart, local_notifications_*.dart,
│   │   │                             # foreground_only_*.dart, alarmkit_*.dart (v1.x)
│   │   ├── wakelock/  fullscreen/  audio/  haptics/  image_picker/  system_settings/
│   │   ├── external_link/  lifecycle/  home_widget/ (v1.x)
│   │   └── providers.dart
│   ├── persistence/                  # hive_bootstrap.dart, boxes.dart, migrator.dart
│   └── a11y/announce_throttle.dart
├── features/
│   ├── timer/
│   │   ├── application/              # timer_controller.dart, start_preflight.dart,
│   │   │                             # run_controller.dart, dial_geometry.dart
│   │   ├── data/session_repository.dart
│   │   └── presentation/             # home_screen.dart, run_screen.dart, finished_screen.dart,
│   │       └── widgets/              # dial_view.dart, dial_painter.dart, digits_label.dart,
│   │                                 # duration_quick_buttons.dart, sound_picker_sheet.dart
│   ├── images/
│   │   ├── domain/                   # image_asset.dart, image_category.dart, frame_spec.dart
│   │   ├── data/                     # bank_manifest_loader.dart, user_image_repository.dart,
│   │   │                             # image_processor_impl.dart
│   │   ├── application/              # image_picker_controller.dart, my_images_controller.dart
│   │   └── presentation/             # image_picker_screen.dart, frame_screen.dart,
│   │                                 # my_images_screen.dart, widgets/image_thumb.dart
│   ├── presets/                      # domain/preset.dart, data/preset_repository.dart,
│   │                                 # application/presets_controller.dart,
│   │                                 # presentation/presets_screen.dart, preset_editor_screen.dart
│   ├── settings/                     # domain/app_settings.dart, data/settings_repository.dart,
│   │                                 # application/settings_controller.dart,
│   │                                 # presentation/settings_screen.dart, battery_help_screen.dart
│   ├── child_lock/                   # application/unlock_controller.dart,
│   │                                 # presentation/hold_to_unlock.dart, touch_shield.dart
│   ├── parental/                     # domain/gate_challenge.dart, number_words.dart,
│   │                                 # application/parental_gate_controller.dart,
│   │                                 # presentation/parental_gate.dart, parent_area_screen.dart,
│   │                                 # privacy_screen.dart, credits_screen.dart
│   ├── routines/        (v1.x)       # domain/, data/, application/routine_runner.dart, presentation/
│   ├── transfer/        (v1.x)       # domain/export_bundle.dart, data/export_codec.dart, presentation/
│   └── home_widget/     (v1.x)       # application/widget_sync.dart
└── l10n/                             # app_pt.arb (template), app_en.arb

assets/
├── fonts/AtkinsonHyperlegibleNext/   # + OFL.txt
├── images/bank/<category>/*.webp     # + manifest.json + LICENSES.md
├── sounds/*.wav                      # + manifest.json + LICENSES.md
└── legal/privacy_pt.md, privacy_en.md

test/
├── unit/        (mirrors lib/)
├── contract/    (port contract suites)
├── widget/
├── golden/      (+ goldens/ci/*.png)
├── fixtures/persistence/v1/
└── helpers/     (pump_app.dart, fakes/, hive_test_utils.dart)
integration_test/
patrol_test/
test_driver/integration_test.dart
tool/            # check_coverage.dart, privacy_check.dart, license_check.dart, l10n_check.dart,
                 # image_bank/ (Node: build.mjs, package.json), sounds/README.md
docs/            # release-checklist.md, architecture.md, contributing-assets.md
android/ ios/ macos/ windows/ linux/ web/
.github/workflows/  # ci.yml, e2e-android.yml, release.yml
fastlane/metadata/android/{pt-BR,en-US}/
```

**Structure Decision**: A single Flutter project at the repository root, organized by feature
with internal layers; platform-specific code restricted to `lib/core/platform/` and to the
native folders (`android/`, `ios/`) only for the settings MethodChannel (v1.0) and
widgets/AlarmKit (v1.x).

## Timer execution flow (implementation reference)

```text
[Home] Start
  └─ StartPreflight (capabilities, permissions, notices)          contracts/ui/08
      └─ TimerController.start(config)
          ├─ TimerEngine.start(now) → TimerSession(running, endsAt)
          ├─ SessionRepository.save(session) + flush             (before scheduling)
          ├─ AlarmScheduler.schedule(end)                        (if supported)
          ├─ WakeLock.enable, Fullscreen.enter, Audio.preload/startTicking
          └─ router.go('/run')
[Run] Ticker → DialView.repaint(remaining = endsAt − clock.now())
  ├─ lifecycle resumed → reconcile(now) → finished? → /finished
  └─ now ≥ endsAt (app open) → Audio.playAlarm, Haptics, cancel notification → /finished
[Finished] tap → acknowledge → session cleared → WakeLock.disable → /
[Boot] bootstrap → load session → reconcile → route guard (/run | /finished | /)
```

## Complexity Tracking

> Packages outside the Constitution's approved list (Technical Constraints) and decisions that
> require justification.

| Item | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| `url_launcher` | Open source code/issues from the parent area (after the parental gate) | Copying the URL to the clipboard is worse UX; the package makes no network calls |
| `uuid` | Stable local ids for presets, images, sessions | Generating with our own `Random` reimplements something trivial and well tested |
| `hive_ce_flutter` | Initialize Hive in the right directory in Flutter | Manual `path_provider` + `Hive.init` duplicates what the package offers |
| `share_plus` (v1.x) | Export a file on Android/iOS through the system sheet | `file_selector` cannot save on mobile; an own MethodChannel for 2 OSes is more code |
| `flutter_alarmkit` (v1.x) | Alarm that breaks through silent mode on iOS 26+ (FR-091) | An own Swift implementation remains the fallback if the plugin falls short (R17) |
| Own MethodChannel `vtc/system_settings` | Open 3 Android settings screens | `app_settings` would add a dependency with partial coverage |
| Node script in `tool/image_bank/` | Rasterize the library's SVGs into WebP reproducibly | Rasterizing at runtime would require `flutter_svg` and CPU cost; the tool is dev-only and does not ship in the app |
