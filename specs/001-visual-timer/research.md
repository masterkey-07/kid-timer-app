# Research: Visual Time Counter

**Feature**: `001-visual-timer` | **Date**: 2026-10-23 | **Plan**: [plan.md](./plan.md)

Each decision follows the Decision / Rationale / Alternatives considered format. Items marked
**Verify in spike** must be confirmed in the Phase 2 (Foundational) tasks before the stories use
them.

---

## R1. Framework, version and SDK pinning

- **Decision**: Stable Flutter 3.47.x (Dart 3.x), pinned with FVM in `.fvmrc` and in the CI
  matrix.
- **Rationale**: The only stack with official support for all 6 platforms; Impeller is the
  default on desktop too since 3.47; the dial renders identically on every screen. A pinned
  version is a practical F-Droid requirement and avoids unstable goldens.
- **Alternatives considered**: React Native/Expo (no official desktop), Compose Multiplatform
  (web in beta), Capacitor/PWA (background alarm not viable on the web). Discarded during
  product planning.

## R2. Architecture and state management

- **Decision**: Feature-first with layers `presentation` → `application` → `domain` ← `data`;
  Riverpod 3 with hand-written `Notifier`/`AsyncNotifier` (no code generation); go_router for
  navigation and deep links.
- **Rationale**: Riverpod allows injecting `Clock`, repositories and ports in tests without a
  `BuildContext`; no codegen keeps the build simple for contributors.
- **Alternatives considered**: Bloc (more ceremony), Provider + ChangeNotifier (lower
  testability for async logic), riverpod_generator (adds build_runner).

## R3. Time engine

- **Decision**: `TimerEngine` in pure Dart. State holds `startedAt`, `endsAt` (UTC),
  `pausedRemaining` and `status`. Remaining = `endsAt − clock.now()`. In the foreground, a
  `Ticker` only triggers repaints; no value is accumulated. When returning from the background
  or opening the app, `reconcile(now)` decides between `running`, `finished` or keeps `paused`.
- **Rationale**: Eliminates drift and the "resume" problem reported in similar apps
  (Constitution III). An injectable `Clock` (`package:clock`) makes tests deterministic.
- **Alternatives considered**: `Timer.periodic` decrementing (drifts, loses state), background
  isolates (unnecessary; the OS schedules the alarm).
- **Time zone/clock changes**: `endsAt` in UTC makes time zones irrelevant. Manual clock
  adjustment is accepted as a limitation: the OS alarm prevails and the app reconciles on
  reopening.

## R4. Alarm with the app closed

- **Decision**: `flutter_local_notifications` 22.x with `zonedSchedule` + `timezone`.
  - **Android**: `AndroidScheduleMode.alarmClock` (exempt from Doze, alarm icon in the system).
    The manifest declares `USE_EXACT_ALARM` (timer app, reviewed in Play Console),
    `SCHEDULE_EXACT_ALARM` with `android:maxSdkVersion="32"`, `POST_NOTIFICATIONS`,
    `RECEIVE_BOOT_COMPLETED`, `VIBRATE`, `WAKE_LOCK`. A "Timer end" channel with maximum
    importance and its own sound; a "Warnings" channel (v1.x) with default importance. The
    plugin's boot receiver reschedules alarms. `USE_FULL_SCREEN_INTENT` is not used in v1.0.
  - **iOS/iPadOS/macOS**: local notification with a bundled sound (< 30 s), `timeSensitive`
    interruption level ("Time Sensitive Notifications" capability).
  - **Windows**: **Verify in spike** whether `zonedSchedule` works in the Windows plugin; if
    not, Windows falls back to "keep the window open" mode.
  - **Linux and Web**: no scheduling (documented limitation of the plugin and of browsers) →
    foreground-only alarm + notice (FR-015).
- **Rationale**: A mature plugin covering 4 of 6 platforms with native scheduling.
- **Alternatives considered**: `android_alarm_manager_plus` (runs Dart in the background, more
  fragile), push server (violates Constitution I), the `alarm` package (aimed at alarm clocks,
  plays audio in a foreground service; more permissions).
- **Limits**: iOS 64 pending notifications; Android ~500 alarms per app (Samsung). Routines
  schedule at most 20 steps + warnings, below both limits.

## R5. Screen on and full screen

- **Decision**: `wakelock_plus` (6 platforms). Full screen: immersive `SystemChrome` on
  Android/iOS; `window_manager` on desktop; Fullscreen API via `package:web` on the Web.
- **Rationale**: Official/community packages in wide use; no network.
- **Alternatives considered**: `fullscreen_window` (less maintained).

## R6. Audio

- **Decision**: `audioplayers` for foreground sounds (alarm, preview, ticking, transition). All
  sounds in WAV PCM 16-bit, mono, 44.1 kHz, ≤ 30 s, ≤ 500 KB. The same file is copied to
  `android/app/src/main/res/raw/` and into the iOS/macOS bundle as the notification sound.
- **Rationale**: The only plugin covering all 6 platforms (Linux via GStreamer). WAV is accepted
  by Android and Apple notifications and by every decoder.
- **Alternatives considered**: `just_audio` (no official Linux/Windows), OGG/AAC (uneven support
  across platforms).
- **Source**: Kenney (CC0) and the project's own sounds; licenses in
  `assets/sounds/LICENSES.md`.

## R7. Persistence

- **Decision**: `hive_ce` on every platform (files in the app support directory; IndexedDB on
  the Web). Boxes: `settings`, `presets`, `routines`, `session` (running timer/routine) holding
  JSON maps with `schemaVersion`; `user_images` as a `LazyBox<Uint8List>` for own-image bytes.
  Repositories encapsulate serialization and migrations.
- **Rationale**: A single mechanism, the same code on every platform, including image bytes on
  the Web, with no codegen (no TypeAdapters: only primitive types and maps).
- **Alternatives considered**: `shared_preferences` (no binaries; ~5 MB localStorage limit on
  the Web), Drift (SQLite WASM + worker on the Web, complex for a small volume), files with
  `path_provider` (does not work on the Web).

## R8. Picking and processing own images

- **Decision**: `image_picker` (Android Photo Picker with no permission; PHPicker on iOS; file
  input on the Web; delegates to `file_selector` on desktop). Processing with the `image`
  package (pure Dart) in an isolate (`compute`; on the Web it runs on the main thread): decode,
  apply the framing (center and zoom), crop square, resize to 1024×1024, re-encode JPEG quality
  85. Re-encoding drops EXIF/GPS. Accepted formats: JPEG, PNG, WebP, GIF (first frame), BMP;
  HEIC arrives converted on iOS; on other platforms HEIC yields a friendly error.
- **Rationale**: Meets FR-021/FR-023 without broad permissions and without native code.
- **Alternatives considered**: `image_cropper` (native UI differs per platform, no desktop),
  `flutter_image_compress` (native, incomplete Linux/Web).

## R9. Built-in image library

- **Decision**: Microsoft Fluent Emoji (MIT license; **verify the `LICENSE` of the
  `microsoft/fluentui-emoji` repository in the assets task**), "Color" SVG style rasterized
  offline to 768×768 WebP with a soft circular background. 36+ images in 6 categories, manifest
  `assets/images/bank/manifest.json` with id, category, pt-BR/en names, author, license and
  source. Reproducible pipeline in `tool/image_bank/` (Node script with `@resvg/resvg-js` and
  `sharp`, used only in development; output committed to Git).
- **Rationale**: Friendly style, coverage of children's activities (🪥 🛁 🍽️ 🧸 🛏️ 🎒 👟),
  license compatible with Constitution IX, renders the same on every platform and needs no SVG
  package at runtime.
- **Alternatives considered**: ARASAAC (CC BY-NC-SA, forbidden), OpenMoji (CC BY-SA,
  forbidden), Twemoji (CC BY 4.0, flatter and less expressive style; kept as fallback), Noto
  Emoji (Apache-2.0, fallback), original illustrations (cost; future contributions welcome).

## R10. Drawing the dial

- **Decision**: `CustomPainter` inside a `RepaintBoundary`, repainted by a `Ticker` at 60/120
  fps (or once per second with "reduce motion"). With an image: `canvas.clipPath(remaining
  sector)` + `drawImageRect` of the pre-decoded image (`ui.Image` at the dial's size); elapsed
  sector in a translucent neutral color. Without an image: `drawArc` with the palette's
  interpolated color. Minute markers drawn once in a static layer (cached `Picture`).
- **Rationale**: Full control, no dependencies, testable with goldens.
- **Alternatives considered**: Rive/Lottie (dependency, no gain), shaders (complexity).

## R11. Testing

- **Decision**:
  - Unit and widget: `flutter_test`, `mocktail`, `fake_async`, `clock`.
  - Goldens: `alchemist` (CI goldens with the Ahem font + local platform goldens).
  - Accessibility in widget tests: `meetsGuideline(androidTapTargetGuideline)`,
    `iOSTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline`.
  - Integration: `integration_test` on Android (emulator), Linux desktop (`xvfb-run`) and Web
    (`flutter drive` + chromedriver).
  - E2E: Patrol 4.x (Android and iOS; macOS and Web optional) for native interactions:
    notifications, permission dialogs, photo picker, locked screen, killed app.
  - Coverage: `flutter test --coverage` + `tool/check_coverage.dart` with the Constitution IV
    thresholds.
- **Rationale**: Patrol is the mature tool for Flutter E2E with native interaction; it does not
  support Windows/Linux, which are covered by `integration_test` + a manual checklist.
- **Alternatives considered**: Maestro (outside Dart code, YAML), Appium (heavy),
  `integration_test` only (cannot interact with notifications and system dialogs).

## R12. Accessibility

- **Decision**: Explicit `Semantics` on the dial (`value` = remaining time,
  `increasedValue`/`decreasedValue` for screen-reader adjustment), `SemanticsService.announce`
  with a configurable throttle; `MediaQuery.disableAnimationsOf` for reduce motion;
  `TextScaler` up to 2.0; `FocusTraversalGroup` and `Shortcuts`/`Actions` for keyboard (arrows,
  Enter, Space, Esc). Atkinson Hyperlegible Next font (SIL OFL 1.1) bundled.
- **Rationale**: Constitution V and FR-060/061.

## R13. Internationalization

- **Decision**: `flutter gen-l10n` with `lib/l10n/app_pt.arb` (template, pt-BR) and
  `app_en.arb`; fallback to en for unsupported locales (`localeResolutionCallback`). v1.x:
  Hosted Weblate (libre plan for open source projects) synced via PRs.
- **Rationale**: Official tooling; ARB is a format Weblate accepts.

## R14. Parental gate and external links

- **Decision**: Own `ParentalGate` widget (multiplication written in words, custom numeric
  keypad, 30 s lockout after 3 errors). Links open with `url_launcher` only after the gate and a
  confirmation.
- **Rationale**: Apple Kids (1.3) and Google Families requirement; `url_launcher` makes no
  network calls, it only delegates to the browser. Justified in Complexity Tracking.

## R15. System settings (Android)

- **Decision**: A small own `MethodChannel` (`vtc/system_settings`) in Kotlin to open: the exact
  alarm setting, the app's notifications and battery optimization. Per-vendor help pages as
  static localized content.
- **Rationale**: Avoids an extra dependency for 3 intents.
- **Alternatives considered**: `app_settings` (extra package, partial coverage).

## R16. Routines in the background (v1.x)

- **Decision**: When an automatic routine starts, schedule the end of all remaining steps
  (≤ 20) and warnings (≤ 2 per step) — at most 60 notifications, below iOS's limit of 64; on
  pause/cancel, cancel them all by id group. Manual mode schedules only the current step.
- **Rationale**: FR-073 without background execution.

## R17. Widgets and AlarmKit (v1.x)

- **Decision**: `home_widget` + an Android widget in Jetpack Glance (Kotlin) and an iOS widget in
  WidgetKit (SwiftUI) with App Group `group.<bundle-id>`; tapping opens the deep link
  `vtc://preset/<id>/start` handled by go_router. iOS 26+: `flutter_alarmkit` (MIT) behind the
  `AlarmScheduler` port (`AlarmKitScheduler` implementation), with fallback to local
  notifications; Live Activity via the plugin's `uiConfig`. **Verify in the US12 spike** the
  plugin's maturity; if inadequate, implement own Swift code behind the same port.
- **Rationale**: FR-090/091; native code isolated.

## R18. Export and import (v1.x)

- **Decision**: A `.vtc.json` file (UTF-8 JSON) with `formatVersion`, metadata, presets,
  routines and own images in base64 (optional). Export: `file_selector.getSaveLocation` on
  desktop/Web; `share_plus` on Android/iOS (system share sheet, no own networking). Import:
  `file_selector.openFile`. Validation against the schema in
  [contracts/export-format.md](./contracts/export-format.md); atomic import.
- **Rationale**: No ZIP dependency; expected maximum size ~10 MB.
- **Alternatives considered**: ZIP with `archive` (extra dependency), cloud sync (violates
  Constitution I).

## R19. App identifiers

- **Decision**: Application ID / Bundle ID `io.github.masterkey07.visualtimecounter`; display
  name "Visual Time Counter"; deep link scheme `vtc://`. **Confirm with the repository owner
  before the first release** (changing it after publishing is costly).

## R20. Web

- **Decision**: Default build (CanvasKit); a `--wasm` compilation check in CI as a non-blocking
  job. Hosting on GitHub Pages with `--base-href /visual-time-counter/`. No aggressive caching
  service worker in v1.0 (optional installable PWA in v1.x).
- **Rationale**: Some plugins may not be WASM-compatible (Patrol web is not).

## R21. Performance

- **Decision**: Reference device: Android with 3 GB RAM and a 4-core CPU (e.g., the Galaxy A0x
  line). Measured with `flutter run --profile` + a performance `integration_test`
  (`traceAction`) producing `FrameTiming`; target ≥ 99% of frames < 16 ms.
- **Rationale**: SC-004 and Constitution VIII.

## R22. CI/CD

- **Decision**: GitHub Actions: `ci.yml` (format, analyze, tests, goldens, coverage, web build,
  desktop builds in a matrix, privacy check), `e2e-android.yml` (API 34 emulator with
  `reactivecircus/android-emulator-runner` + Patrol), `release.yml` (tag `v*`: APK per ABI,
  AAB, Web on Pages, Linux AppImage/Flatpak, Windows MSIX/zip, macOS dmg; iOS via fastlane when
  secrets exist). Privacy check: a script that fails if the merged Android release manifest
  contains `INTERNET`, if `pubspec.lock` has a denylisted package (`firebase_*`,
  `google_mobile_ads`, `*analytics*`, `sentry*`, `*crashlytics*`), or if `lib/` imports
  networking APIs (`dart:io` `HttpClient`, `package:http`, `package:dio`, `WebSocket`).
  Transitive dependencies with unused networking code (e.g., `http` pulled in by
  `audioplayers`) are tolerated because the manifest without `INTERNET` prevents any connection
  on Android and the release traffic test (SC-008) covers the other platforms.
- **Rationale**: Constitution, Quality Gates.
