# CLAUDE.md — Kid Timer

Runtime guide for agents (Claude Code) in this repository. Read it before any task.

## What this is

A free, open source visual timer for children (parents, teachers, therapists). A single
Flutter codebase for Android, iOS/iPadOS, Windows, macOS, Linux and Web. No ads, no network,
no data collection. Apache-2.0 license.

## Source of truth (Spec-Driven Development with GitHub Spec Kit)

| Artifact                                  | Path                                                |
| ----------------------------------------- | --------------------------------------------------- |
| Constitution (non-negotiable rules)       | `.specify/memory/constitution.md`                   |
| Active feature                            | `.specify/feature.json` → `specs/001-visual-timer/` |
| Specification (what and why)              | `specs/001-visual-timer/spec.md`                    |
| Technical plan (how)                      | `specs/001-visual-timer/plan.md`                    |
| Decisions and alternatives                | `specs/001-visual-timer/research.md`                |
| Data model                                | `specs/001-visual-timer/data-model.md`              |
| UI contracts (one per screen)             | `specs/001-visual-timer/contracts/ui/00…11-*.md`    |
| Platform ports, persistence, export       | `specs/001-visual-timer/contracts/*.md`             |
| Testing strategy (unit, integration, E2E) | `specs/001-visual-timer/testing-strategy.md`        |
| Executable task list                      | `specs/001-visual-timer/tasks.md`                   |
| Manual validation                         | `specs/001-visual-timer/quickstart.md`              |
| Requirement quality checklists            | `specs/001-visual-timer/checklists/`                |
| Latest consistency analysis               | `specs/001-visual-timer/analysis.md`                |

On conflict: constitution > spec > plan/contracts > tasks > code.

## Current state

- Spec Kit phases completed: constitution → specify → clarify → plan → checklist → tasks →
  analyze.
- **No code has been written yet.** Next step: `/speckit-implement` starting at Phase 1 (T001)
  of `tasks.md`.
- Scope: v1.0 = US1–US7 (Phases 1–10); v1.x = US8–US15 (Phases 11–19).

## Available Spec Kit skills (`.claude/skills/`)

`/speckit-implement` (run tasks), `/speckit-analyze` (cross-artifact consistency),
`/speckit-clarify`, `/speckit-checklist`, `/speckit-converge` (code vs. tasks),
`/speckit-specify` (new feature), `/speckit-plan`, `/speckit-tasks`, `/speckit-taskstoissues`
(create GitHub issues), `/speckit-constitution` (amendments).

Scripts: `.specify/scripts/bash/check-prerequisites.sh --json` resolves the feature paths.

## How to work

1. Execute tasks in `tasks.md` order; respect dependencies and `[P]` markers.
2. **TDD is mandatory**: write the test, run it and watch it fail, then implement. Commit
   `test:` before `feat:`.
3. Mark the finished task `[x]` in `tasks.md` in the same commit.
4. At every **Checkpoint**, run and report:
   ```bash
   dart format --set-exit-if-changed .
   flutter analyze
   flutter test --coverage
   dart run tool/check_coverage.dart
   ```
   plus the story's integration/E2E tests (see `testing-strategy.md`). Before running anything
   on an Android emulator, read `docs/android-testing.md` (setup, commands, known failures).
5. **Spike** tasks record their decision in `research.md` before moving on.
6. Requirement changed? Update `spec.md` (and `plan.md`/contracts/tasks if needed) before the
   code, then run `/speckit-analyze`.

## Rules that most often break builds and reviews

- No network: do not add `INTERNET` to the Android `main` manifest, nor `package:http`/`dio` in
  `lib/`, nor analytics/ads/crash SDKs. `tool/privacy_check.dart` fails CI.
- Remaining time is always `endsAt − clock.now()`; never tick counters. Use `clockProvider`.
- Persist the session (with `flush`) **before** scheduling the alarm.
- Platform code only behind the ports in `lib/core/platform/`; tests use the fakes in
  `test/helpers/fakes/`.
- The domain (`lib/core/domain`, `lib/core/timer_engine`) is pure Dart: no
  `import 'package:flutter/…'`.
- Every visible string goes into `lib/l10n/app_pt.arb` **and** `app_en.arb`.
- Testable widgets use the `Key('<screen>.<element>')` from the UI contracts; tests never find
  widgets by text.
- Assets only under CC0, CC BY 4.0, MIT, Apache-2.0 (fonts: OFL), recorded in the folder's
  `LICENSES.md`. Nothing from Fehners Software and no "Time Timer" trademark.
- New dependencies outside the constitution's list require justification in
  `plan.md` → Complexity Tracking.

## Conventions

- Everything in English: SDD docs, code, identifiers, commits and comments. The app UI is
  localized in pt-BR and en.
- Conventional Commits with `Signed-off-by` (DCO).
- Flutter pinned in `.fvmrc` (use `fvm flutter …`).
- Application/Bundle ID: `io.github.masterkey07.visualtimecounter` (confirm before the first
  release; see research R19).
