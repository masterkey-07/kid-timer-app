# UI Contract 11 — System surfaces: widgets, Live Activity, AlarmKit (v1.x)

**Story**: US12 | **Release**: v1.x | **Platforms**: Android, iOS/iPadOS

## 11.1 Home screen widget

Sizes: Android 2×2 and 4×2 (Glance); iOS small and medium (WidgetKit).

```text
small / 2×2                 medium / 4×2
┌───────────────┐           ┌────────────────────────────────┐
│ (◯)    (◯)    │           │ (◯) Brush 2m     (◯) Bath 10m  │
│ Brush  Bath   │           │ (◯) Homework 25m (◯) Sleep 15m │
│ (◯)    (◯)    │           │ ▶ Running: Bath — ends 19:42   │
└───────────────┘           └────────────────────────────────┘
```

- Shows up to 4 presets marked as favorites (FR-090), in list order.
- Tapping a preset → deep link `vtc://preset/<id>/start`.
- Status line (medium): active preset and end time (not a per-second countdown, to save
  battery); tap → `vtc://run`.
- No favorites: "Choose favorites in the app" → opens `/presets`.
- Data shared via `home_widget` (App Group on iOS; SharedPreferences on Android): JSON
  `{favorites:[{id,name,durationMs,thumbPath}], active:{presetName, endsAtUtc}}` and 128×128 PNG
  thumbnails written by the app.
- Accessibility: each cell described as "Start Brush teeth, 2 minutes".

## 11.2 iOS 26+: AlarmKit and Live Activity

- When starting a timer with `AlarmScheduler` = `AlarmKitScheduler` and authorization granted:
  schedules a system countdown alarm (rings in silent mode and in Focus).
- Live Activity / Dynamic Island: title = preset name or "Timer"; system countdown; "Pause" and
  "Stop" buttons (labeled) reflected in the app via the plugin's intents.
- Authorization requested on the first timer on iOS 26+ after a prior explanation (dialog
  `notice.alarmKit` with `.allow` / `.notNow`).
- Denied or iOS < 26: falls back to local notifications (US2) without error messages.

## 11.3 Ongoing notification (Android, optional v1.x)

A continuous silent notification with the system chronometer (`setUsesChronometer` +
`setChronometerCountDown`) during the countdown, with Pause/Stop actions. Can be enabled in
settings ("Show the countdown in the notification bar"), off by default.

## States

| Surface       | Situation                        | Presentation                                                                                    |
| ------------- | -------------------------------- | ----------------------------------------------------------------------------------------------- |
| Widget        | Before the app is first opened   | "Open the app to set up" → opens `/`                                                            |
| Widget        | No favorites                     | "Choose favorites in the app" → `/presets`                                                      |
| Widget        | Favorite deleted                 | Removed at the next payload publish; a stale tap opens `/` with the "Preset not found" snackbar |
| Widget        | Thumbnail missing                | Colored circle with the preset's initial                                                        |
| Widget        | Timer finished, not acknowledged | Status line "Time's up" → `vtc://run`                                                           |
| Live Activity | Authorization denied/revoked     | Not shown; falls back to US2 notifications silently                                             |

## Planned tests

- Unit: widget payload serialization; favorites selection (max. 4).
- Integration: `home_widget` receives the correct payload when presets change and when starting/
  stopping.
- Native tests: minimal Glance (Robolectric/screenshot) and WidgetKit (preview snapshot).
- E2E (Patrol): tapping the widget starts the preset (Android); iOS 26 on the simulator: alarm
  in silent mode (manual release checklist, since the simulator does not reproduce silent
  mode).
