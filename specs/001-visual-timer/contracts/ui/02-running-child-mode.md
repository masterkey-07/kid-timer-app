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
│        ╭─┤ filled         ├─╮        │  DialView: starts empty (translucent neutral) and
│        │ │ sector (image/ │ │        │  the elapsed sector fills in with the image/color;
│        ╰─┤ color)         ├─╯        │  a full turn = the set duration
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

| Element       | Key                    | Semantics                                                                                        | Behavior                                                                          |
| ------------- | ---------------------- | ------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------- |
| Dial          | `run.dial`             | `label: "Time remaining"`, `value: "4 minutes and 12 seconds"`; throttled announcements (FR-060) | Repainted by a Ticker; with reduce motion, once per second                        |
| Digits        | `run.digits`           | excluded from semantics (the dial already announces)                                             | Updates once per second                                                           |
| Padlock       | `run.lock`             | "Hold for 3 seconds to show the controls"                                                        | Press and hold 3 s → ring completes → controls; releasing earlier resets (FR-031) |
| Padlock ring  | `run.lockProgress`     | `value` in %                                                                                     | Linear 3 s animation; reduce motion: text bar "1… 2… 3"                           |
| Pause/Resume  | `run.pauseResume`      | "Pause timer" / "Resume timer"                                                                   | State machine transitions                                                         |
| Restart       | `run.restart`          | "Restart timer"                                                                                  | Confirmation if remaining < 50%                                                   |
| Stop          | `run.stop`             | "Stop timer"                                                                                     | `ConfirmDialog` → cancel → `/`                                                    |
| Mute          | `run.mute`             | "Mute ticking"                                                                                   | Toggles ticking for this session                                                  |
| Full screen   | `run.fullscreenToggle` | "Exit full screen"                                                                               | Desktop/Web only                                                                  |
| Capture layer | `run.touchShield`      | `excludeSemantics`                                                                               | Absorbs touches in child mode; feedback: padlock glow (see Behavior 2)            |

## Behavior

1. On entry: enables the wakelock (FR-014); full screen if `childLockEnabled` (FR-030); preloads
   the sound; starts ticking if enabled.
2. Child mode: `AbsorbPointer` + `touchShield`; keys ignored except Esc held for 3 s. Android
   "back" is consumed (no effect); the iOS back gesture is disabled. Padlock glow on an
   absorbed touch: opacity 0.35 → 0.8 over 100 ms, held 100 ms, back to 0.35 over 100 ms
   (300 ms total, no scale or color change); repeated touches restart it, never stacking
   faster than once per 300 ms. With reduce motion: the same opacity steps without easing.
3. Unlock: controls for 10 s; any interaction restarts the 10 s; then back to child mode. With
   `childLockEnabled = false`, controls are always visible and there is no padlock.
4. Lifecycle: `paused`/`inactive`/`hidden` → keeps the session (the OS alarm handles it);
   `resumed` → `reconcile(now)`; if `finished`, navigates to `/finished`. See Behavior 5 for
   what happens to the OS alarm on each transition.
5. End with the app open: stops ticking; plays the sound; vibrates; navigates to `/finished`.
   The end must ring exactly once, so the OS alarm is handled per platform:

   | Platform                        | OS alarm while the app is in the foreground                                                                                                                                                                              |
   | ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
   | iOS, iPadOS, macOS              | Stays scheduled; the foreground presentation options of the timer notifications are off (no banner, no sound), so only the app's sound plays. Removed from the tray on entering `/finished`.                             |
   | Android, Windows (if supported) | Cancelled on `resumed`; rescheduled (same id, session already persisted) on `inactive`/`paused`/`hidden`. Only the app's sound plays in the foreground; the OS alarm covers background, locked screen and process death. |
   | Web, Linux, Windows (fallback)  | No OS alarm; the app's sound is the only alarm.                                                                                                                                                                          |
   | iOS 26+ with AlarmKit (v1.x)    | The system alarm is the only alarm; the app plays no sound of its own and shows `/finished` when the alarm is stopped or the app is open.                                                                                |

6. On leaving (`/finished` or `/`): releases the wakelock and full screen.
7. Landscape/portrait, resizing and moving the window to another monitor: the dial recomputes
   its size without restarting; on desktop, full screen follows the window to the new monitor.
8. v1.x US9: intermediate warning → single dial pulse (scale 1.0→1.04→1.0, 400 ms) + soft sound.
   US10: image effect per `imageEffect`. US11: a single dial up to 12 h.

## Special states

| Situation                | Presentation                                                                                                                                                         |
| ------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Paused                   | Frozen dial with a translucent central ⏸ icon; same visual in child mode                                                                                            |
| System volume 0 (mobile) | When unlocking: notice "Volume is at zero"                                                                                                                           |
| Alarm permission denied  | When unlocking: reduced-accuracy notice with a link to the setting                                                                                                   |
| Image failed to load     | Falls back to color without interrupting                                                                                                                             |
| Screen reader turned on  | No restart; the semantics tree is always built, so the dial is announced at the next interval; the padlock is focusable and unlocks with double-tap and hold for 3 s |

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
