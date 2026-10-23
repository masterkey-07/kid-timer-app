# Data Model: Visual Time Counter

**Feature**: `001-visual-timer` | **Date**: 2026-10-23 | **Plan**: [plan.md](./plan.md)

Domain entities in pure Dart (`lib/core/domain/` and `lib/features/*/domain/`), immutable, with
`copyWith`, value equality and explicit `toJson`/`fromJson`. Storage formats are in
[contracts/persistence-schema.md](./contracts/persistence-schema.md).

Conventions:

- Durations as integer milliseconds (`int`) when serialized; `Duration` in the domain.
- Instants in UTC, ISO-8601 with milliseconds when serialized; UTC `DateTime` in the domain.
- IDs: UUID v4 (string) generated locally; library images use a stable textual id
  (`bank:<category>/<slug>`).

---

## Value objects

### TimerDuration

| Field | Type | Rules |
|---|---|---|
| value | Duration | v1.0: 10 s ≤ value ≤ 2 h. v1.x (US11): ≤ 12 h. Multiple of 1 s. |

Adjustment steps: below 2 min, 10 s; from 2 min on, 1 min (FR-001).

### DialScale

Enum: `min5`, `min10`, `min15`, `min30`, `min60`, `min120`. Default: `min60`.
Dial fraction = `remaining / scale`, clamped to [0, 1]. v1.x: with duration > scale, the number
of dials = `ceil(duration / scale)`.

### DialDirection

Enum: `clockwise` (default), `counterClockwise`.

### VisualSource (sealed union)

| Variant | Fields | Rules |
|---|---|---|
| `PaletteSource` | paletteId: PaletteId, singleColor: ColorToken? | `singleColor` required if `paletteId == single`. |
| `BankImageSource` | imageId: String | Must exist in the library manifest. |
| `UserImageSource` | imageId: String (UUID) | Must exist in `user_images`; if deleted → fallback to the default `PaletteSource`. |

### PaletteId

Enum: `progressive` (green > 50%, yellow 20–50%, red < 20%, smooth 2% interpolation), `single`,
`calm` (pastel, no red), v1.x: `highContrast`, `protanopia`, `deuteranopia`, `tritanopia`.

### ColorToken

Enum of 8 design-system colors: `blue`, `green`, `yellow`, `orange`, `purple`, `pink`, `teal`,
`gray`. Values in `lib/app/theme/palettes.dart`.

### SoundId

Enum/string of bundled sounds (≥ 8) + `none`. Manifest in `assets/sounds/manifest.json`.

### ImageEffect (v1.x)

Enum: `vanish` (v1.0 default), `reveal`, `mosaic`, `puzzle4`, `puzzle9`, `puzzle16`.

### WarningOffsets (v1.x)

Set of {1, 2, 5, 10} minutes. Warnings ≥ duration are ignored at start time.

---

## Entities

### TimerConfig

Full configuration of a timer (used by TimerSession, Preset and RoutineStep).

| Field | Type | Default | Rules |
|---|---|---|---|
| duration | TimerDuration | 5 min | see value object |
| scale | DialScale | min60 | — |
| direction | DialDirection | clockwise | — |
| visual | VisualSource | PaletteSource(progressive) | — |
| soundId | SoundId | `chime_soft` | — |
| alarmVolume | double | 0.7 | 0.0–1.0 |
| tickEnabled | bool | false | — |
| tickVolume | double | 0.3 | 0.0–1.0 |
| vibrate | bool | true | ignored without support |
| showDigits | bool | true | — |
| imageEffect | ImageEffect | vanish | v1.x |
| warnings | WarningOffsets | {} | v1.x |

### TimerSession

Active timer (at most 1 at a time in v1.0; routines create one session per step).

| Field | Type | Rules |
|---|---|---|
| id | String (UUID) | — |
| config | TimerConfig | frozen copy at start |
| status | SessionStatus | see state machine |
| startedAt | DateTime? (UTC) | set on `start` |
| endsAt | DateTime? (UTC) | required when `running` |
| pausedRemaining | Duration? | required when `paused` |
| origin | SessionOrigin | `manual`, `preset(id)`, `routine(runId, stepIndex)` |
| scheduledNotificationIds | List<int> | ids scheduled with the OS, for cancellation |
| finishedAcknowledged | bool | false until the tap on the final screen |

Derived: `remaining(now)`, `progress(now)` (0..1 remaining), `isOverdue(now)`.

**State machine (SessionStatus)**

```text
           start                pause               resume
  ready ─────────▶ running ─────────▶ paused ─────────▶ running
    ▲                │  ▲                │
    │      cancel    │  │ reconcile      │ cancel
    │◀───────────────┤  │ (now<endsAt)   ▼
    │                │  │            cancelled ──▶ (discarded)
    │   now ≥ endsAt │
    │                ▼
    │            finished ──(tap on final screen)──▶ acknowledged ──▶ ready (new session)
    │
    └──────────── restart (from running/paused/finished) ─────────────
```

Rules:

- `start`: `startedAt = now`, `endsAt = now + duration`; schedules notification; persists.
- `pause`: `pausedRemaining = endsAt − now` (≥ 0); cancels notification; persists.
- `resume`: `endsAt = now + pausedRemaining`; reschedules; persists.
- `cancel`: cancels notifications; removes the persisted session.
- `restart`: equivalent to `cancel` + `start` with the same config.
- `reconcile(now)`: if `running` and `now ≥ endsAt` → `finished`; other states unchanged.
- `finished` with `finishedAcknowledged = false` is shown only once on reopening.
- Invalid transitions throw `InvalidTransition` (tested).

### ImageAsset

| Field | Type | Rules |
|---|---|---|
| id | String | `bank:<cat>/<slug>` or UUID |
| kind | `bank` \| `user` | — |
| category | ImageCategory? | required for `bank`: `hygiene`, `meal`, `play`, `rest`, `school`, `goingOut` (v1.x: `routine`) |
| labels | Map<locale, String> | `bank`: pt and en required; `user`: optional label (≤ 40) |
| assetPath | String? | `bank`: path to the 768×768 WebP |
| bytesKey | String? | `user`: key in the `user_images` `LazyBox` |
| createdAt | DateTime? | `user` |
| license / author / source | String | `bank`: required (manifest) |

Own-image rules: JPEG 1024×1024, ≤ 400 KB, no metadata; maximum 50.

### Preset

| Field | Type | Rules |
|---|---|---|
| id | String (UUID) | — |
| name | String | 1–40 characters after `trim`; uniqueness not required |
| order | int | 0..n-1, no gaps after reordering |
| config | TimerConfig | — |
| isExample | bool | first-use example presets |
| favorite | bool | v1.x (widget), at most 4 favorites |
| createdAt / updatedAt | DateTime | UTC |

Limit: 100 presets.

### Routine (v1.x)

| Field | Type | Rules |
|---|---|---|
| id | String (UUID) | — |
| name | String | 1–40 characters |
| advanceMode | `automatic` \| `manual` | default `automatic` |
| layout | `strip` \| `firstThen` | `firstThen` requires exactly 2 steps |
| steps | List<RoutineStep> | 2–20 items |
| order | int | — |

### RoutineStep (v1.x)

| Field | Type | Rules |
|---|---|---|
| id | String (UUID) | — |
| name | String | 1–40 characters |
| config | TimerConfig | step duration 10 s–2 h |

### RoutineRun (v1.x)

| Field | Type | Rules |
|---|---|---|
| id | String (UUID) | — |
| routineId | String | snapshot stored in `routineSnapshot` |
| routineSnapshot | Routine | copy at start (edits do not affect the run) |
| currentIndex | int | 0..steps-1 |
| completed | List<bool> | stars |
| session | TimerSession | current step's session |
| status | `running` \| `waitingNext` \| `paused` \| `finished` \| `cancelled` | — |

Transitions: a step ends → automatic: `currentIndex++` and a new `running` session; manual:
`waitingNext` until "Next". The last step ends → `finished`. Reconcile on reopening walks the
steps using the scheduled `endsAt` values.

### AppSettings

| Field | Type | Default |
|---|---|---|
| schemaVersion | int | 1 |
| themeMode | `system` \| `light` \| `dark` (v1.x `highContrast`) | system |
| childLockEnabled | bool | true |
| a11yAnnounceInterval | `oneMin` \| `fiveMin` \| `off` | oneMin |
| defaults | TimerConfig | defaults above |
| lastConfig | TimerConfig | same as defaults |
| onboarding | Map<String,bool> | `exactAlarmExplained`, `iosSilentWarned`, `webKeepOpenSeen`, `examplesSeeded` |

Language follows the system (no field).

### ExportBundle (v1.x)

See [contracts/export-format.md](./contracts/export-format.md).

---

## Relationships

```text
AppSettings 1 ── 1 TimerConfig (defaults, lastConfig)
Preset      * ── 1 TimerConfig ── 0..1 ImageAsset (via VisualSource)
Routine     1 ── 2..20 RoutineStep ── 1 TimerConfig
RoutineRun  1 ── 1 Routine (snapshot), 1 TimerSession (current step)
TimerSession 1 ── 1 TimerConfig (snapshot)
ImageAsset(user) ◀── referenced by Preset/RoutineStep/lastConfig (reference count computed
                     on delete; FR-024)
```
