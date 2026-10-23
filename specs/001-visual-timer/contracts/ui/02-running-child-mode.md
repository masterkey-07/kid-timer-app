# UI Contract 02 — Countdown and child mode

**Route**: `/run` | **Stories**: US1, US2, US3, US4, US6, US7 (v1.x: US9, US10, US11)
| **Release**: v1.0

## Purpose

Show the child time passing, without distractions and without any way to change the timer.

## Wireframe — child mode (locked, default)

```text
┌──────────────────────────────────────┐
│ 🔒                                    │  HoldToUnlock: 40 dp icon, 0.35 opacity
│                                      │
│          ╭────────────────╮          │
│        ╭─┤ remaining      ├─╮        │  DialView: image cropped to the remaining sector;
│        │ │ sector (image/ │ │        │  elapsed sector translucent neutral
│        ╰─┤ color)         ├─╯        │
│          ╰────────────────╯          │
│                04:12                 │  DigitsLabel if showDigits=true
│                                      │
└──────────────────────────────────────┘
  full screen, no system bars; theme surface background
```

## Wireframe — controls unlocked (10 s)

```text
┌──────────────────────────────────────┐
│ ⚠ Keep this window open (Web)        │  PlatformNotice only with controls visible
│          ╭────────────────╮          │
│          │    DialView    │          │
│          ╰────────────────╯          │
│                04:12                 │
│                                      │
│   [⏸ Pause] [↻ Restart] [✕ Stop]     │  56 dp buttons
│   [🔇 Sound] [⤢ Exit full screen]     │
│   Locks again in 8 s ▬▬▬▬▬▭▭          │  countdown bar
└──────────────────────────────────────┘
```

## Components, keys and semantics

| Element | Key | Semantics | Behavior |
|---|---|---|---|
| Dial | `run.dial` | `label: "Time remaining"`, `value: "4 minutes and 12 seconds"`; throttled announcements (FR-060) | Repainted by a Ticker; with reduce motion, once per second |
| Digits | `run.digits` | excluded from semantics (the dial already announces) | Updates once per second |
| Padlock | `run.lock` | "Hold for 3 seconds to show the controls" | Press and hold 3 s → ring completes → controls; releasing earlier resets (FR-031) |
| Padlock ring | `run.lockProgress` | `value` in % | Linear 3 s animation; reduce motion: text bar "1… 2… 3" |
| Pause/Resume | `run.pauseResume` | "Pause timer" / "Resume timer" | State machine transitions |
| Restart | `run.restart` | "Restart timer" | Confirmation if remaining < 50% |
| Stop | `run.stop` | "Stop timer" | `ConfirmDialog` → cancel → `/` |
| Mute | `run.mute` | "Mute ticking" | Toggles ticking for this session |
| Full screen | `run.fullscreenToggle` | "Exit full screen" | Desktop/Web only |
| Capture layer | `run.touchShield` | `excludeSemantics` | Absorbs touches in child mode; feedback: padlock glow for 300 ms |

## Behavior

1. On entry: enables the wakelock (FR-014); full screen if `childLockEnabled` (FR-030); preloads
   the sound; starts ticking if enabled.
2. Child mode: `AbsorbPointer` + `touchShield`; keys ignored except Esc held for 3 s. Android
   "back" is consumed (no effect); the iOS back gesture is disabled.
3. Unlock: controls for 10 s; any interaction restarts the 10 s; then back to child mode. With
   `childLockEnabled = false`, controls are always visible and there is no padlock.
4. Lifecycle: `paused`/`inactive` → keeps the session (the OS alarm handles it); `resumed` →
   `reconcile(now)`; if `finished`, navigates to `/finished`.
5. End with the app open: stops ticking; plays the sound; vibrates; cancels the scheduled
   notification (or lets the OS show it, depending on the platform, without ringing twice);
   navigates to `/finished`.
6. On leaving (`/finished` or `/`): releases the wakelock and full screen.
7. Landscape/portrait and resizing: the dial recomputes its size without restarting.
8. v1.x US9: intermediate warning → single dial pulse (scale 1.0→1.04→1.0, 400 ms) + soft sound.
   US10: image effect per `imageEffect`. US11: dial grid.

## Special states

| Situation | Presentation |
|---|---|
| Paused | Frozen dial with a translucent central ⏸ icon; same visual in child mode |
| System volume 0 (mobile) | When unlocking: notice "Volume is at zero" |
| Alarm permission denied | When unlocking: reduced-accuracy notice with a link to the setting |
| Image failed to load | Falls back to color without interrupting |

## Main strings

`runUnlockHint`, `runPause`, `runResume`, `runRestart`, `runStop`, `runStopConfirm`,
`runMuteTick`, `runExitFullscreen`, `runRelockIn`, `runRemainingSemantics`,
`runVolumeZeroWarning`.

## Planned tests

- Unit: announcement throttle; sector computation; unlock logic (3 s, cancellation, 10 s
  display) with `fake_async`.
- Widget: touches in child mode do not change state (SC-003 simulated with 30 seeded random
  gestures); Esc 3 s; dial goldens at 0%, 25%, 50%, 100% with image and colors, clockwise and
  counter-clockwise.
- Integration: wakelock enabled/disabled (fake port); reconcile after a lifecycle pause.
- E2E (Patrol): lock the screen for 1 min and receive the alarm; kill the app and reopen on
  `/finished`; Android back button has no effect.
