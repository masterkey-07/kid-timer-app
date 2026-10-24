# Kid Timer Constitution

A free, open source visual timer for children, built with Flutter for Android, iOS, iPadOS,
Windows, macOS, Linux and Web. This document defines the project's non-negotiable rules.
Every specification, plan, task, line of code and review MUST comply with it.

The keywords MUST, MUST NOT, SHOULD and MAY follow RFC 2119.

## Core Principles

### I. Privacy by Design (NON-NEGOTIABLE)

- The app MUST NOT collect, transmit or store outside the device any personal data, device
  identifier, telemetry, analytics or automatic error report.
- The app MUST work 100% offline. The Android build MUST NOT declare the
  `android.permission.INTERNET` permission; no platform may make network requests at runtime.
- Dependencies MUST NOT include advertising SDKs, analytics, Firebase, Google Play Services or
  any library that makes network calls.
- Images chosen by the adult MUST be copied into the app's private storage and MUST NOT leave
  the device. Selection MUST use the system picker, without broad storage permissions.
- Data export (presets, routines) only happens through an explicit action by the adult and
  produces a local file.

Rationale: the audience is children (COPPA, LGPD/ECA Digital, Google Play Families, Apple Kids
Category, F-Droid). Collecting nothing removes legal and ethical risk and is verifiable in code.

### II. Child Safety and Well-being

- The app MUST NOT contain ads, purchases, external links exposed to the child, compulsive
  engagement mechanics (punitive streaks, come-back notifications, random rewards) or
  third-party content.
- Any way out of the app (links, "About", repository, donations) MUST sit behind a parental
  gate.
- During a countdown the child's screen MUST be free of controls; reaching the controls
  requires the unlock gesture defined in the specification (child lock).
- Sounds and animations MUST be gentle by default: moderate volume, no startling sounds, no
  more than 3 flashes per second (WCAG 2.3.1). A calm mode (no red) MUST exist.
- Every bundled asset (images, sounds, icons) MUST be appropriate for children aged 3 to 12 and
  reviewed by a human before merge.
- For the extended emoji library (the complete Microsoft Fluent Emoji set, bundled offline), the
  human review MAY be done per group instead of per asset, provided that:
  - a committed, versioned denylist removes, before any review, everything showing weapons,
    violence or injury, alcohol, smoking, drugs or medical needles, gambling, religious symbols,
    political or national symbols and flags, scary or horror figures, bodily functions, and
    sexual or romantic innuendo;
  - the reviewer sees every remaining image of the group on a contact sheet;
  - the verdict per group (reviewer, date, image count, contact sheet) is recorded in
    `docs/assets-review.md`, and every image the reviewer rejects is added to the denylist.
- Images showing people MUST offer the five skin-tone variants wherever the source provides them.

Rationale: the product exists to reduce anxiety around transitions, not to capture attention.
Reviewing about 1,300 emoji one by one is impractical; the denylist and full contact sheets keep
a human eye on every image that ships.

### III. Time Reliability (NON-NEGOTIABLE)

- Remaining time MUST be derived from absolute instants (`endsAt − now`) using an injectable
  `Clock`. Decrementing counters on ticks (`Timer.periodic` as the source of truth) is
  forbidden.
- When a timer starts on a platform with native scheduling (Android, iOS, macOS), its end MUST
  be scheduled with the operating system so it fires with the app in the background, closed or
  with the screen locked.
- The running timer's state MUST be persisted on every transition (start, pause, resume,
  cancel, finish) and reconciled when the app reopens.
- Accuracy: the alarm MUST fire within ≤ 1 s in the foreground and ≤ 5 s in the background on
  platforms where exact scheduling is granted.
- Where the system does not allow a reliable alarm (Web, Linux, permission denied on Android),
  the app MUST clearly inform the adult before starting and never fail silently.

Rationale: a children's timer that does not ring breaks the trust of both child and adult.

### IV. Test-First and the Test Pyramid (NON-NEGOTIABLE)

- TDD is mandatory for domain and application logic: test written, test failing, then
  implementation (Red → Green → Refactor). Test commits precede implementation commits.
- Every user story MUST have:
  - unit tests for the domain and controllers;
  - widget and golden tests for the affected screens (light, dark, high contrast; phone,
    tablet and desktop);
  - integration tests (`integration_test`) covering persistence and platform adapters;
  - at least one End-to-End test (Patrol) of the story's main flow on a real device or
    emulator, including system interaction (notification, image picker) when applicable.
- Minimum line coverage: 95% in `lib/core/**`, 85% in `lib/features/**/application/**`, 80%
  overall. CI MUST block merges below these thresholds.
- Tests MUST be deterministic: time via `Clock`/`fake_async`, no real `sleep`, no network.
- Every bug fix MUST come with a regression test that failed before the fix.

Rationale: time, alarms and persisted state are areas where regressions are silent.

### V. Accessibility and Inclusion

- The app MUST meet WCAG 2.2 level AA on both adult and child screens.
- Every interactive element MUST have a semantic label, a touch target ≥ 48×48 dp and a
  visible keyboard focus (desktop/web). Screen readers (TalkBack, VoiceOver, NVDA, Orca) MUST
  announce the remaining time understandably, without excessive announcements (at most once
  per minute, configurable).
- The app MUST honor the system font scale up to 200% without losing content, the system
  "reduce motion" setting and high contrast.
- Color MUST NOT be the only means of conveying information (remaining time is also given by
  the dial's area and, optionally, by digits).
- Palettes MUST be validated for color vision deficiency (protanopia, deuteranopia,
  tritanopia).
- All visible text MUST come from localization files (`.arb`); pt-BR and en are mandatory and
  MUST be 100% translated in every release. The one exception is bundled asset metadata (the
  names, keywords, groups and subgroups of library images and the names of sounds), which MAY
  live in the asset folder's `manifest.json`, with pt-BR and en both required for every entry
  and verified in CI by `tool/l10n_check.dart`.

Rationale: the audience includes children with ADHD, autism and visual or motor impairments.

### VI. Cross-Platform Parity and Honest Degradation

- A single Flutter codebase serves all platforms. Platform-specific code MUST sit behind
  interfaces (ports) in `lib/core/platform/`, with one implementation per platform and a fake
  implementation for tests.
- Every feature MUST declare its per-platform support in the specification. Differences MUST be
  communicated to the user in the UI itself when they affect behavior.
- Layouts MUST be responsive for three classes: compact (< 600 dp), medium (600–839 dp) and
  expanded (≥ 840 dp), in portrait and landscape.

Rationale: parents and schools use phones, tablets and projectors; the experience must be
consistent.

### VII. Clean Architecture and Simplicity

- Feature-first structure with layers: `presentation` → `application` → `domain` ← `data`.
  The domain (`lib/core/timer_engine`, entities) MUST be pure Dart, without importing Flutter.
- Dependencies between features MUST go through `lib/core` or public interfaces; cross-imports
  of internal details are forbidden.
- State with Riverpod; navigation with go_router; persistence behind repositories.
- YAGNI: nothing outside the specified scope up to version 1.x. Every new dependency or extra
  layer MUST be justified in the plan's "Complexity Tracking" section.

Rationale: an open source project must be easy to understand and contribute to.

### VIII. Code Quality and Performance

- `flutter analyze` with zero warnings using `very_good_analysis` (or a stricter equivalent
  set); `dart format` mandatory; no `// ignore` without a justifying comment.
- The dial animation MUST hold 60 fps (120 fps on capable screens) without jank on a low-end
  reference device (Android with 3 GB RAM and a 4-core CPU), measured in profile mode.
- Cold start ≤ 2 s to the first useful frame on the reference device; APK per ABI ≤ 50 MB, of
  which the extended emoji library (Principle II) takes at most 25 MB.
- Power: with the screen on and the timer running, the app MUST NOT repaint more than needed
  (dial repaint isolated with `RepaintBoundary`).
- Public APIs in `lib/core` MUST have `///` documentation.

Rationale: the visual experience is the product; stutter and slowness undermine trust.

### IX. Free Software and Licensing

- Code under Apache-2.0. Art, images and sounds under CC0, CC BY 4.0, MIT or Apache-2.0; fonts
  under SIL OFL 1.1. Share-alike (CC BY-SA) and non-commercial (CC BY-NC) licenses are
  forbidden. Authorship and license MUST be recorded in a `LICENSES.md` inside each asset
  folder.
- Every dependency MUST have a license compatible with Apache-2.0 and with the F-Droid policy.
- The project MUST NOT use the name, trademark, images, sounds or visual identity of Fehners
  Software, nor the "Time Timer" trademark.
- Contributions require the DCO (`Signed-off-by`).

Rationale: freedom to use and distribute through every store, including F-Droid.

## Technical Constraints

- Language and framework: Dart 3.x and stable Flutter (version pinned in `.fvmrc` and in CI).
- Target platforms: Android 8.0+ (API 26), iOS/iPadOS 16+, macOS 13+, Windows 10+,
  Linux (x64, GTK 3), Web (evergreen browsers).
- Approved base packages: `flutter_riverpod`, `go_router`, `flutter_local_notifications`,
  `timezone`, `wakelock_plus`, `audioplayers`, `hive_ce`, `image_picker`, `file_selector`,
  `image`, `path_provider`, `window_manager`, `home_widget`, `flutter_localizations`/`intl`,
  `patrol`, `mocktail`, `fake_async`, `clock`, `alchemist`, `very_good_analysis`.
  Any other package requires justification in the plan.
- Persistence: versioned JSON documents (`schemaVersion`) with explicit migrations and
  migration tests for every version.
- Language: all project documentation (SDD specs, plans, tasks, README, guides), code,
  identifiers, commit messages and code comments are written in English. The app UI is
  localized (pt-BR and en, see Principle V).

## Development Workflow and Quality Gates

- All work starts from a specification in `specs/` (Spec Kit): `specify` → `clarify` →
  `plan` → `tasks` → `analyze` → `implement`.
- Feature branches (`NNN-short-name`); Conventional Commits; small, reviewable PRs.
- A PR may only be merged when CI is green with:
  1. `dart format --set-exit-if-changed` and `flutter analyze` with no warnings;
  2. unit, widget and golden tests passing;
  3. coverage above the Principle IV thresholds;
  4. integration tests passing on an Android emulator;
  5. Patrol E2E for the affected flow passing (Android in CI; iOS in the release checklist);
  6. privacy check: Android manifest without `INTERNET`, no new networking dependency,
     compatible licenses;
  7. new strings present in pt-BR and en.
- Releases follow SemVer, have a changelog and pass the manual checklist on real devices
  (an Android device from a vendor with aggressive battery optimization, an iPhone in silent
  mode, an iPad, a desktop).

## Governance

- This constitution supersedes any other practice, template or session instruction.
- Amendments require a dedicated PR changing this file, with rationale, impact on existing
  artifacts and a migration plan when applicable.
- Versioning: MAJOR for removing or incompatibly redefining a principle; MINOR for a new
  principle or section or materially changed guidance; PATCH for clarifications.
- Every `plan.md` MUST contain the "Constitution Check" with each principle assessed;
  violations are only accepted when justified in "Complexity Tracking".
- PR reviews MUST verify compliance. Runtime guidance for agents lives in `CLAUDE.md`.

**Version**: 1.4.0 | **Ratified**: 2026-10-23 | **Last Amended**: 2026-10-24
