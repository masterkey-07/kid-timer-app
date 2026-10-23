# Architecture

A summary for contributors. The authoritative design is in
[`specs/001-visual-timer/plan.md`](../specs/001-visual-timer/plan.md) and its
[contracts](../specs/001-visual-timer/contracts/).

## Layers

Feature-first, with layers inside each feature:

```text
presentation ──▶ application ──▶ domain ◀── data
   (widgets)      (Riverpod        (pure      (repositories,
                   notifiers)       Dart)      hive_ce)
```

- **`lib/core/`** — code shared by every feature:
  - `domain/` and `timer_engine/` — pure Dart (no Flutter imports): value objects,
    `TimerConfig`, `TimerSession` and the `TimerEngine` state machine.
  - `clock/` — the injectable `Clock` provider. Remaining time is always
    `endsAt − clock.now()`.
  - `persistence/` — Hive boxes, bootstrap and schema migrations.
  - `platform/` — **ports** (interfaces) for everything that touches the operating system,
    their per-platform implementations and the Riverpod providers that select them.
  - `a11y/` — accessibility helpers (announcement throttling).
- **`lib/features/<feature>/`** — `timer`, `images`, `presets`, `settings`, `child_lock`,
  `parental` (v1.x adds `routines`, `transfer`, `home_widget`). Features talk to each other only
  through `lib/core` or public interfaces.
- **`lib/app/`** — the shell: `MaterialApp.router`, go_router routes and guards, theme tokens and
  shared widgets.
- **`lib/l10n/`** — ARB files (pt-BR template and en) and generated localizations.

## Platform ports

Every platform dependency is behind an interface in `lib/core/platform/`, with one real
implementation per platform, a fake in `test/helpers/fakes/` and a shared contract test in
`test/contract/`:

| Port                 | What it does                                   |
| -------------------- | ---------------------------------------------- |
| `AlarmScheduler`     | Schedules the end-of-timer alarm with the OS   |
| `WakeLockPort`       | Keeps the screen on during a countdown         |
| `FullscreenPort`     | Immersive/full-screen mode                     |
| `AudioPort`          | Alarm, preview and ticking sounds              |
| `HapticsPort`        | Vibration                                      |
| `ImagePickerPort`    | System image picker (no storage permission)    |
| `SystemSettingsPort` | Opens Android settings screens                 |
| `ExternalLinkPort`   | Opens links (only after the parental gate)     |
| `AppLifecyclePort`   | App lifecycle events                           |

Support per platform and degraded behavior are listed in
[`contracts/platform-ports.md`](../specs/001-visual-timer/contracts/platform-ports.md).

## Timer flow

Starting a timer: `TimerEngine.start` computes `endsAt` (UTC) → the session is persisted with
`flush` → **then** the alarm is scheduled with the OS. A crash in between therefore never leaves
a running timer without persisted state. On resume or app start, `reconcile(now)` moves an
expired session to `finished`. See the full flow in
[`plan.md`](../specs/001-visual-timer/plan.md#timer-execution-flow-implementation-reference).
