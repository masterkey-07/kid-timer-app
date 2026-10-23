# Contributing to Kid Timer

Thank you for helping! Kid Timer is a free, open source visual timer for children. Before you
start, read the project rules in [`.specify/memory/constitution.md`](.specify/memory/constitution.md):
they are non-negotiable (privacy, child safety, time reliability, test-first, accessibility).

## How work is organized (Spec-Driven Development)

We use [GitHub Spec Kit](https://github.com/github/spec-kit). Every change starts from the
specification, never from the code:

1. **Specification** — what and why: [`specs/001-visual-timer/spec.md`](specs/001-visual-timer/spec.md).
2. **Plan and contracts** — how: [`plan.md`](specs/001-visual-timer/plan.md),
   [`contracts/`](specs/001-visual-timer/contracts/), [`data-model.md`](specs/001-visual-timer/data-model.md).
3. **Tasks** — executable steps in [`tasks.md`](specs/001-visual-timer/tasks.md), done in order.

On conflict: constitution > spec > plan/contracts > tasks > code. If a requirement changes,
update `spec.md` (and the plan, contracts and tasks if needed) **before** the code.

## Development setup

The Flutter SDK is pinned in [`.fvmrc`](.fvmrc). Install [FVM](https://fvm.app) and run:

```bash
fvm install && fvm use
fvm flutter pub get
```

Per-platform prerequisites are listed in
[`quickstart.md`](specs/001-visual-timer/quickstart.md#1-prerequisites).

## Test-first (mandatory)

1. Write the test and run it: it MUST fail.
2. Implement until it passes, then refactor.
3. Commit the test (`test:`) before the implementation (`feat:`).

Tests never find widgets by text: use the `Key('<screen>.<element>')` values from the UI
contracts. Time always comes from the injected `Clock`; no real `sleep`, no network.

## Running the checks

Run these before opening a pull request (CI runs the same):

```bash
dart format --set-exit-if-changed .
fvm flutter analyze
fvm flutter test --coverage
dart run tool/check_coverage.dart
dart run tool/license_check.dart
dart run tool/l10n_check.dart
```

Integration and End-to-End tests:

```bash
xvfb-run fvm flutter test integration_test -d linux
fvm flutter test integration_test -d emulator-5554
patrol test -t patrol_test/ --device emulator-5554
```

The full test strategy is in [`testing-strategy.md`](specs/001-visual-timer/testing-strategy.md).

### iOS End-to-End setup (one time, on a Mac)

Patrol needs a `RunnerUITests` UI-testing target in `ios/Runner.xcodeproj`. The source file
already exists in `ios/RunnerUITests/RunnerUITests.m`. In Xcode: *File → New → Target → UI
Testing Bundle* named `RunnerUITests` (Objective-C, target to be tested: `Runner`), replace the
generated file with the existing one, link the `patrol` Swift package product, and set the
deployment target to iOS 16. See Patrol's iOS setup guide for Swift Package Manager projects.

## Commits and pull requests

- [Conventional Commits](https://www.conventionalcommits.org/) in English
  (`feat:`, `fix:`, `test:`, `docs:`, `build:`, `chore:` …).
- Every commit is signed off under the [Developer Certificate of Origin](https://developercertificate.org/):
  `git commit -s`.
- Mark the finished task as `[x]` in `tasks.md` in the same commit.
- Small, reviewable pull requests; CI must be green.

## Hard rules that most often break reviews

- **No network**: no `INTERNET` permission in the Android `main` manifest, no `package:http`/`dio`
  in `lib/`, no analytics, ads or crash-reporting SDKs (`tool/privacy_check.dart` fails CI).
- **Remaining time** is always `endsAt − clock.now()`; never decrement counters.
- **Platform code** lives only behind the ports in `lib/core/platform/`.
- **The domain** (`lib/core/domain`, `lib/core/timer_engine`) is pure Dart: no Flutter imports.
- **Strings**: every visible text goes into both `lib/l10n/app_pt.arb` and `lib/l10n/app_en.arb`.
- **Assets** only under CC0, CC BY 4.0, MIT, Apache-2.0 (fonts: OFL), recorded in the folder's
  `LICENSES.md`, and reviewed by a human for children aged 3–12.
- **New dependencies** outside the constitution's list need a justification in `plan.md` →
  Complexity Tracking.

## License

By contributing you agree that your contribution is licensed under [Apache-2.0](LICENSE).
