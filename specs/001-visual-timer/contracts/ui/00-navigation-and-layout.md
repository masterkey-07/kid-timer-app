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

**Other screens** (portrait and landscape, every class):

| Screen                                                   | Compact                                                             | Medium                              | Expanded                              |
| -------------------------------------------------------- | ------------------------------------------------------------------- | ----------------------------------- | ------------------------------------- |
| `/run`, `/finished`, `/routines/:id/run`                 | dial centered; controls below (portrait) or at the side (landscape) | same                                | same                                  |
| `/images`, `/images/mine`                                | 3-column grid                                                       | 4–5 columns                         | 6 columns, max width 1200 dp          |
| `/presets`, `/routines`                                  | list                                                                | list                                | 2–3 column card grid                  |
| Editors, `/images/frame`                                 | single column, scrolls                                              | landscape: preview left, form right | preview left, form right, max 1200 dp |
| `/settings`, `/settings/battery`, `/parent`, `/transfer` | single column, scrolls                                              | single centered column, max 600 dp  | single centered column, max 720 dp    |
| Dialogs                                                  | full width − 2 × margin; full screen if the height < 480 dp         | max 560 dp wide                     | max 560 dp wide                       |

- Compact landscape (height < 480 dp, e.g. a phone sideways): every screen scrolls vertically;
  the home screen places the dial on the left and the controls on the right.
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

Text is never drawn directly over an image (thumbnails put their labels below; digits sit
below the dial). Where an overlay over an image is unavoidable (e.g., the paused ⏸ icon), it
sits on a scrim of the theme surface color at 0.7 opacity, guaranteeing ≥ 4.5:1 for text and
≥ 3:1 for icons regardless of the image.

## 4. Design tokens

- **Font**: Atkinson Hyperlegible Next. Scale: display 56/64 (countdown digits), title 22/28,
  body 16/24, label 14/20. Digits with `FontFeature.tabularFigures()`.
- **Base colors** (light / dark theme): surface `#FFFBF5` / `#14161A`; primary text `#1C1B1F` /
  `#ECEDEE`; primary `#3A6FD8` / `#8AB0FF`. Minimum contrast 4.5:1 for text and 3:1 for
  components.
- **High-contrast variant** (FR-055; on when `MediaQuery.highContrastOf` is true, and in v1.x
  also when chosen in settings, FR-110): light — surface `#FFFFFF`, text `#000000`, primary
  `#0039A6`, secondary text `#1F1F1F`; dark — surface `#000000`, text `#FFFFFF`, primary
  `#A8C7FF`, secondary text `#E6E6E6`. Text and icons ≥ 7:1, components ≥ 4.5:1, focus ring
  3 dp, dial outline 3 dp in the text color. Dial palettes keep their hues; their sectors get a
  2 dp outline in the text color so phases do not rely on color alone.
- **Progressive dial palette**: green `#3BAA5C`, yellow `#F2C14E`, red `#E05A47`.
- **Calm mode**: blue `#8FB8E8` → lilac `#B9A7E0` → peach `#F3C3A3`.
- **Empty (not yet filled)**: neutral `#9AA0A6` at 0.18 opacity (light) / 0.28 (dark). With the system's
  increase-contrast setting on (`MediaQuery.highContrastOf`), an opaque tone is used instead:
  `#E3E5E8` (light) / `#2A2D33` (dark); the padlock is then drawn at full opacity. This also
  covers users of "reduce transparency" (not exposed by Flutter; see spec Assumptions).
- **Corners**: 16 dp (cards), 28 dp (primary buttons).
- **Motion**: 200 ms default, `easeOutCubic` curve; with "reduce motion", 0 ms or opacity only.
- **Flash safety** (Constitution II, WCAG 2.3.1): no animated element (including celebration
  particles, the padlock glow and the v1.x warning pulse) may change its luminance by more than
  10% of the screen's relative luminance more than 3 times per second. In practice: every
  repeating animation has a cycle ≥ 400 ms, particles fade in/out over ≥ 400 ms and never
  blink, and no full-screen color change happens more than once per second.

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
| `ConfirmDialog`        | `lib/app/widgets/confirm_dialog.dart`                       | Destructive confirmations (keys `confirm.dialog`, `confirm.confirm`, `confirm.cancel`) |

## 6. Widget keys for tests

Every testable action gets a `Key('<screen>.<element>')`, e.g. `Key('home.start')`. Each routed
screen's `Scaffold` has `Key('<screen>.screen')` (e.g. `home.screen`, `run.screen`,
`finished.screen`), used by the route and guard tests; the deep link snackbar is
`deepLink.presetNotFound`. The keys
listed in each contract are the public API of the widget, integration and E2E tests; renaming a
key requires updating the tests in the same PR.

## 7. Common accessibility

- Focus order = visual order; one `FocusTraversalGroup` per region.
- Dialogs and sheets: on opening, focus moves to the first interactive element (the question
  in the parental gate, so the screen reader reads it first); focus is trapped inside the modal;
  Esc closes it (except the parental gate during lockout, where Esc still closes the dialog but
  the lockout keeps running); on closing, focus returns to the element that opened it.
- Global shortcuts (desktop/Web): `Space` start/pause (outside child mode), `Esc` held 3 s
  unlocks, `Ctrl/Cmd+,` settings, `?` shortcut list.
- Every icon without text has a `tooltip` and a semantic label.
- Transient messages (snackbars) are also announced to the screen reader.

## 8. Strings

All in `lib/l10n/app_pt.arb` and `app_en.arb`, prefixed by screen (`homeStartButton`,
`runUnlockHint`). Each contract lists the main keys; exact copy lives in the ARB files. UI text
quoted in these contracts is the English (en) copy; pt-BR is the translation in `app_pt.arb`.
