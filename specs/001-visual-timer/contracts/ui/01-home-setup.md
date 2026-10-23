# UI Contract 01 — Home: set up the timer

**Route**: `/` | **Stories**: US1, US3, US5, US6 | **Release**: v1.0

## Purpose

The adult's screen to choose duration, image or color and start. Also gives access to presets,
settings and (v1.x) routines.

## Wireframe — compact (portrait)

```text
┌──────────────────────────────────────┐
│ Kid Timer     [▦][⚙][ⓘ]    │  ▦ presets  ⚙ settings  ⓘ about (parental gate)
├──────────────────────────────────────┤
│   ⚠ Keep this window open…           │  PlatformNotice (Web/Linux/permission denied only)
│                                      │
│            ╭───────────╮             │
│          ╭─┤  image    ├─╮           │  Editable DialView (drag the edge)
│          │ │ or color  │ │           │  minute markers around it
│          ╰─┤           ├─╯           │
│            ╰───────────╯             │
│               05:00                  │  DigitsLabel: always visible during setup
│                                      │  (showDigits only affects the countdown)
│   [−1]   [+1 min]   [+5 min]         │  DurationQuickButtons
│                                      │
│   [🖼 Image: Brush teeth       ✕]    │  ImageChip: opens /images; ✕ = "No image"
│   [🎵 Sound: Soft chime ▾]           │  opens the sound picker (sheet)
│                                      │
│ ┌──────────────────────────────────┐ │
│ │         ▶  Start                 │ │  56 dp primary button
│ └──────────────────────────────────┘ │
│   [☆ Save as preset]                 │
│                                      │
│ Presets: (●Brush 2m)(●Bath 10m)…     │  horizontal strip with up to 8 presets (scrolls)
└──────────────────────────────────────┘
```

## Wireframe — expanded

```text
┌──────────────────────────────────────────────────────────────────────┐
│ Kid Timer                                  [▦][⚙][ⓘ]       │
├───────────────────────────────────────────┬──────────────────────────┤
│                                           │ Duration  05:00          │
│              ╭──────────────╮             │ [−1] [+1] [+5]           │
│            ╭─┤   DialView   ├─╮           │ Scale  [5][10][15][30]   │
│            │ │   (large)    │ │           │        [60][120]         │
│            ╰─┤              ├─╯           │ Image  [thumb] Change ✕  │
│              ╰──────────────╯             │ Sound  Soft chime ▾      │
│                  05:00                    │ Presets (2-col grid)     │
│                                           │ [▶ Start]  [☆ Save]      │
└───────────────────────────────────────────┴──────────────────────────┘
```

## Components, keys and semantics

| Element         | Key                                          | Semantics                                                                                        | Behavior                                                                                                                              |
| --------------- | -------------------------------------------- | ------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------- |
| Editable dial   | `home.dial`                                  | `Semantics(slider: true, label: "Duration", value: "5 minutes", increasedValue, decreasedValue)` | Dragging the edge adjusts the duration (FR-001); touching outside the ring does nothing; ↑/→ +step, ↓/← −step; PageUp/PageDown ±5 min |
| Digits          | `home.digits`                                | no `liveRegion` (avoids noise)                                                                   | `mm:ss` or `h:mm:ss` format                                                                                                           |
| −1 min          | `home.minus1`                                | "Decrease 1 minute"                                                                              | Disabled at the minimum (10 s)                                                                                                        |
| +1 min          | `home.plus1`                                 | "Add 1 minute"                                                                                   | Disabled at the maximum                                                                                                               |
| +5 min          | `home.plus5`                                 | "Add 5 minutes"                                                                                  | Clamps to the maximum with a "Maximum of 2 hours" snackbar                                                                            |
| Image chip      | `home.imageChip`                             | "Image: Brush teeth. Tap to change"                                                              | Opens `/images`                                                                                                                       |
| Remove image    | `home.imageClear`                            | "Use colors instead of an image"                                                                 | Back to `PaletteSource` (FR-025)                                                                                                      |
| Sound           | `home.soundPicker`                           | "Alarm sound: Soft chime"                                                                        | Sheet with list + preview                                                                                                             |
| Start           | `home.start`                                 | button "Start 5 minute timer"                                                                    | Validates duration ≥ 10 s; runs the checks in [08](./08-permissions-and-notices.md); starts the session; navigates to `/run`          |
| Save preset     | `home.savePreset`                            | "Save as preset"                                                                                 | Opens `/presets/new` with the current config                                                                                          |
| Preset strip    | `home.presetStrip` / item `home.preset.<id>` | "Preset Brush teeth, 2 minutes"                                                                  | Tap: loads the config (1st tap); the "▶" button on the item starts directly (FR-041)                                                  |
| Presets         | `home.openPresets`                           | "Presets"                                                                                        | `/presets`                                                                                                                            |
| Settings        | `home.openSettings`                          | "Settings"                                                                                       | `/settings`                                                                                                                           |
| About           | `home.openAbout`                             | "About and parent area"                                                                          | Parental gate → `/parent`                                                                                                             |
| Routines (v1.x) | `home.openRoutines`                          | "Routines"                                                                                       | `/routines`                                                                                                                           |

## States

| State                       | Presentation                                                                    |
| --------------------------- | ------------------------------------------------------------------------------- |
| Loading (boot)              | Native splash; no on-screen spinner if ≤ 300 ms                                 |
| First use                   | Example presets seeded; one-time hint "Drag the edge of the dial" (dismissible) |
| Own image missing (deleted) | Chip shows "No image"; dial uses colors; snackbar once                          |
| Duration < 10 s             | `home.start` disabled + text "Minimum of 10 seconds"                            |
| Active session on open      | The guard redirects to `/run` (this screen is not shown)                        |

## Interaction rules

- Dragging: angle → duration on the current scale, rounded to the step; light haptic (selection)
  at every whole minute on mobile.
- Changing the scale (side panel or settings) keeps the duration if ≤ scale; otherwise clamps it
  to the scale (v1.0) or creates extra dials (v1.x US11).
- `lastConfig` is saved on every change (300 ms debounce).

## Main strings (ARB)

`homeTitle`, `homeStartButton`, `homeStartSemantics`, `homeMinMinutes`, `homeMaxReached`,
`homeImageChip`, `homeNoImage`, `homeSound`, `homeSavePreset`, `homeDialHint`.

## Planned tests

- Widget: adjustment by drag (simulated gesture), buttons, limits, slider semantics, goldens
  (light/dark × compact/medium/expanded × with/without image).
- Integration: `lastConfig` persists after an app restart.
- E2E: SC-001 (set up and start 5 min), SC-006 (preset in 2 taps).
