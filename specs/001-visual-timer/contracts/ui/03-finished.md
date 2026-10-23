# UI Contract 03 — Final screen (celebration)

**Route**: `/finished` | **Stories**: US1, US2, US7 (v1.x: US8) | **Release**: v1.0

## Purpose

Show clearly that time is up, in a joyful and calm way, and stay until someone taps (a recurring
request from teachers).

## Wireframe

```text
┌──────────────────────────────────────┐
│                                      │
│              ✦    ✦                  │  soft particles (off with reduce motion)
│          ╭────────────────╮          │
│          │  whole image   │          │  image (or full dial in the color) with a gentle
│          │   or ✓ icon    │          │  360° spin over 1.2 s (opacity only with reduce motion)
│          ╰────────────────╯          │
│              Time's up!              │  title 28 dp
│                                      │
│          Tap the screen to go back   │  secondary hint after 2 s
└──────────────────────────────────────┘
```

## Components and keys

| Element    | Key                    | Semantics                          | Behavior                                                                     |
| ---------- | ---------------------- | ---------------------------------- | ---------------------------------------------------------------------------- |
| Whole area | `finished.dismissArea` | button "Time's up. Tap to go back" | Tap (after an 800 ms guard against accidental touches) → `acknowledge` → `/` |
| Image/icon | `finished.image`       | the image's label                  | Celebration animation                                                        |
| Title      | `finished.title`       | header                             | —                                                                            |

## Behavior

- Sound: plays the chosen sound once (repeats every 30 s up to 3 times if the app is open;
  configurable in v1.x). Default vibration: 2 pulses.
- Screen reader announcement: "Time's up" (assertive) on entry.
- The wakelock stays for 10 min and is then released (the screen may turn off; when it turns on
  again, the final screen is still there).
- Persistence: `finishedAcknowledged` only becomes `true` with the tap; reopening the app before
  that returns to this screen (FR-005, Edge Cases).
- OS notification: on entering this screen, the timer's notifications are removed from the
  tray.
- Keyboard: Enter/Space/Esc trigger the tap.
- v1.x routine: shows the stars of all steps and the routine's name; for an intermediate step in
  manual mode, this screen is not used (see [09](./09-routines.md)).

## States

| Situation            | Presentation                                                                                |
| -------------------- | ------------------------------------------------------------------------------------------- |
| Image failed to load | ✓ icon on the full dial in the timer's color; no error message                              |
| Sound failed to play | Visual celebration only; the failure is logged locally (no network)                         |
| Reduce motion        | No spin and no particles; opacity transition only                                           |
| Particles            | ≤ 20 particles, each fading in/out over ≥ 400 ms, no blinking (contract 00 §4 flash safety) |

## Strings

`finishedTitle`, `finishedTapToReturn`, `finishedSemantics`.

## Planned tests

- Widget: 800 ms guard; tap acknowledges; reduce motion removes spin and particles; goldens with
  image, with color, dark theme.
- Integration: an unacknowledged `finished` session reopens this screen after a restart.
- E2E: with the app closed, the alarm rings; opening from the notification shows this screen.
