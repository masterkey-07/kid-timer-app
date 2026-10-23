# UI Contract 00 — Navigation, layout and design system

Cross-cutting contract every screen follows. Individual screens are in `01-*.md` to `11-*.md`.

## 1. Route map (go_router)

| Route                                 | Screen                                 | Contract                              | Release | Access                            |
| ------------------------------------- | -------------------------------------- | ------------------------------------- | ------- | --------------------------------- |
| `/`                                   | Home (set up timer)                    | [01](./01-home-setup.md)              | v1.0    | open                              |
| `/run`                                | Countdown (child mode)                 | [02](./02-running-child-mode.md)      | v1.0    | from `/`, preset, routine, widget |
| `/finished`                           | Final screen                           | [03](./03-finished.md)                | v1.0    | automatic                         |
| `/images`                             | Choose image (library + my images)     | [04](./04-image-picker.md)            | v1.0    | `/`, editors                      |
| `/images/frame`                       | Frame own image                        | [04](./04-image-picker.md)            | v1.0    | after the system picker           |
| `/images/mine`                        | Manage "My images"                     | [04](./04-image-picker.md)            | v1.0    | `/images`, `/settings`            |
| `/presets`                            | Preset list                            | [05](./05-presets.md)                 | v1.0    | `/`                               |
| `/presets/:id/edit`, `/presets/new`   | Preset editor                          | [05](./05-presets.md)                 | v1.0    | `/presets`, `/`                   |
| `/settings`                           | Settings                               | [06](./06-settings.md)                | v1.0    | `/`                               |
| `/settings/battery`                   | Help: battery and screen pinning       | [06](./06-settings.md)                | v1.0    | `/settings`, notices              |
| `/parent`                             | Parent area (About, licenses, privacy) | [07](./07-parental-gate-and-about.md) | v1.0    | after the parental gate           |
| `/routines`                           | Routine list                           | [09](./09-routines.md)                | v1.x    | `/`                               |
| `/routines/:id/edit`, `/routines/new` | Routine editor                         | [09](./09-routines.md)                | v1.x    | `/routines`                       |
| `/routines/:id/run`                   | Routine run                            | [09](./09-routines.md)                | v1.x    | `/routines`, widget               |
| `/transfer`                           | Export/Import                          | [10](./10-export-import.md)           | v1.x    | `/settings`                       |

Dialogs and sheets (not routes): parental gate, permission and platform notices
([08](./08-permissions-and-notices.md)), confirmations.

**Navigation guards**

- If a `TimerSession` is `running`/`paused`, opening the app goes to `/run`.
- If an unacknowledged `finished` session exists, opening the app goes to `/finished`.
- If a `RoutineRun` is active (v1.x), opening the app goes to `/routines/:id/run`.
- `/parent` and `/transfer` require the parental gate to have been solved less than 5 min ago.

## 2. Deep links

Scheme `vtc://` (Android intent-filter, iOS URL scheme; desktop/Web internal route only).

| Link                              | Action                                        |
| --------------------------------- | --------------------------------------------- |
| `vtc://preset/<id>/start`         | Starts the preset and opens `/run`            |
| `vtc://routine/<id>/start` (v1.x) | Starts the routine                            |
| `vtc://run`                       | Opens the active countdown (notification tap) |

Links with an unknown id open `/` with a "Preset not found" snackbar.

## 3. Size classes and layout

| Class    | Width      | Home layout                                         | Navigation                   |
| -------- | ---------- | --------------------------------------------------- | ---------------------------- |
| Compact  | < 600 dp   | column: dial on top, controls below                 | top bar with icons           |
| Medium   | 600–839 dp | portrait: column; landscape: dial left, panel right | top bar                      |
| Expanded | ≥ 840 dp   | large central dial + fixed 360 dp side panel        | top bar + keyboard shortcuts |

- Dial: diameter = `min(usable width, usable height) × 0.82` during the countdown; × 0.6 during
  setup.
- Margins: 16 dp (compact), 24 dp (medium), 32 dp (expanded). 8 dp grid.
- Touch targets ≥ 48×48 dp; primary buttons ≥ 56 dp high.
- Safe areas respected; no overlap with notch or gesture bar.

## 3.1 System back

| Screen                    | Back button/gesture                        |
| ------------------------- | ------------------------------------------ |
| `/`                       | Leaves the app (Android) / no effect (iOS) |
| `/run` (child mode)       | Consumed, no effect                        |
| `/run` (controls visible) | Same as "Stop" with confirmation           |
| `/finished`               | Same as the acknowledgement tap            |
| Editors with changes      | Asks "Discard changes?"                    |
| Other screens and dialogs | Go back/close normally                     |

## 3.2 Dial legibility

The dial always has a 2 dp outline in the secondary text color (contrast ≥ 3:1 against the
background), so light images on a light theme (or dark ones on a dark theme) do not "vanish"
into the background.

## 4. Design tokens

- **Font**: Atkinson Hyperlegible Next. Scale: display 56/64 (countdown digits), title 22/28,
  body 16/24, label 14/20. Digits with `FontFeature.tabularFigures()`.
- **Base colors** (light / dark theme): surface `#FFFBF5` / `#14161A`; primary text `#1C1B1F` /
  `#ECEDEE`; primary `#3A6FD8` / `#8AB0FF`. Minimum contrast 4.5:1 for text and 3:1 for
  components.
- **Progressive dial palette**: green `#3BAA5C`, yellow `#F2C14E`, red `#E05A47`.
- **Calm mode**: blue `#8FB8E8` → lilac `#B9A7E0` → peach `#F3C3A3`.
- **Elapsed**: neutral `#9AA0A6` at 0.18 opacity (light) / 0.28 (dark).
- **Corners**: 16 dp (cards), 28 dp (primary buttons).
- **Motion**: 200 ms default, `easeOutCubic` curve; with "reduce motion", 0 ms or opacity only.

## 5. Shared components

| Component              | File                                                        | Use                                     |
| ---------------------- | ----------------------------------------------------------- | --------------------------------------- |
| `DialView`             | `lib/features/timer/presentation/widgets/dial_view.dart`    | Dial (setup and countdown)              |
| `DurationQuickButtons` | `.../widgets/duration_quick_buttons.dart`                   | +1, +5, −1 min                          |
| `DigitsLabel`          | `.../widgets/digits_label.dart`                             | mm:ss                                   |
| `ImageThumb`           | `lib/features/images/presentation/widgets/image_thumb.dart` | Circular thumbnail                      |
| `ParentalGate`         | `lib/features/parental/presentation/parental_gate.dart`     | Parental gate dialog                    |
| `HoldToUnlock`         | `lib/features/child_lock/presentation/hold_to_unlock.dart`  | Padlock with ring                       |
| `PlatformNotice`       | `lib/app/widgets/platform_notice.dart`                      | Notice banners (Web/Linux, permissions) |
| `ConfirmDialog`        | `lib/app/widgets/confirm_dialog.dart`                       | Destructive confirmations               |

## 6. Widget keys for tests

Every testable action gets a `Key('<screen>.<element>')`, e.g. `Key('home.start')`. The keys
listed in each contract are the public API of the widget, integration and E2E tests; renaming a
key requires updating the tests in the same PR.

## 7. Common accessibility

- Focus order = visual order; one `FocusTraversalGroup` per region.
- Global shortcuts (desktop/Web): `Space` start/pause (outside child mode), `Esc` held 3 s
  unlocks, `Ctrl/Cmd+,` settings, `?` shortcut list.
- Every icon without text has a `tooltip` and a semantic label.
- Transient messages (snackbars) are also announced to the screen reader.

## 8. Strings

All in `lib/l10n/app_pt.arb` and `app_en.arb`, prefixed by screen (`homeStartButton`,
`runUnlockHint`). Each contract lists the main keys; exact copy lives in the ARB files. UI text
quoted in these contracts is the English (en) copy; pt-BR is the translation in `app_pt.arb`.
