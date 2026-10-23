# UI Contract 06 — Settings and system help

**Routes**: `/settings`, `/settings/battery` | **Stories**: US2, US4, US6, US7
| **Release**: v1.0

## 6.1 Settings (`/settings`)

Grouped list (sections with headers). Expanded: two columns of sections.

```text
┌──────────────────────────────────────┐
│ ← Settings                           │
├──────────────────────────────────────┤
│ APPEARANCE                           │
│  Theme           [System ▾]          │  system/light/dark (v1.x: high contrast)
│  Default scale   [60 min ▾]          │
│  Direction       [Clockwise ▾]       │
│  Default colors  [Progressive ▾]     │  v1.x: color-blindness palettes
│  Show digits     [✓]                 │
│ SOUND AND VIBRATION                  │
│  Alarm sound     [Soft chime ▾] [▶]  │
│  Volume          ━━━━●━━━            │
│  Ticking         [ ]  Volume ━━●━━   │
│  Vibrate         [✓]                 │
│ CHILD MODE                           │
│  Child lock      [✓]                 │
│  How to keep the child in the app >  │  → /settings/battery#pinning
│ ALARM                                │
│  Status: ✓ Exact alarms active       │  or ⚠ with an "Allow" action
│  Notifications: ✓                    │
│  Help: battery and alarms >          │  → /settings/battery
│ ACCESSIBILITY                        │
│  Announce remaining time [Every 1 min ▾] │  1 min, 5 min, off
│ IMAGES                               │
│  My images (12) >                    │  → /images/mine
│ DATA (v1.x)                          │
│  Export and import >                 │  parental gate → /transfer
│ ABOUT                                │
│  About, licenses and privacy >       │  parental gate → /parent
└──────────────────────────────────────┘
```

| Element                                                            | Key                     | Persistence               | Notes                                                                             |
| ------------------------------------------------------------------ | ----------------------- | ------------------------- | --------------------------------------------------------------------------------- |
| Theme                                                              | `settings.theme`        | `AppSettings.themeMode`   | applies immediately                                                               |
| Scale, direction, colors, digits, sound, volumes, ticking, vibrate | `settings.<field>`      | `AppSettings.defaults`    | affect new timers; `lastConfig` is also updated if it equals the previous default |
| Child lock                                                         | `settings.childLock`    | `childLockEnabled`        | disabling asks for confirmation "The child will be able to pause the timer"       |
| Alarm status                                                       | `settings.alarmStatus`  | — (queried from the port) | states: ok, no exact alarm, no notifications, not supported on this platform      |
| Allow                                                              | `settings.alarmFix`     | —                         | opens the system setting (R15)                                                    |
| Announcements                                                      | `settings.a11yInterval` | `a11yAnnounceInterval`    | —                                                                                 |
| My images                                                          | `settings.myImages`     | —                         | —                                                                                 |
| About                                                              | `settings.about`        | —                         | parental gate                                                                     |

The sound preview plays at the selected volume; tapping another sound stops the previous one.

## 6.2 Help: battery, alarms and screen pinning (`/settings/battery`)

A localized static content page with anchors:

- `#alarms` — why the app asks for exact alarms and notifications; buttons to open the settings
  (Android) or instructions (iOS: Settings → Notifications → Kid Timer →
  "Time Sensitive").
- `#battery` — steps per vendor (Samsung, Xiaomi/Redmi/POCO, Motorola, Huawei, others), with an
  "Open battery optimization" button (Android).
- `#pinning` — Android: "Screen pinning" (Settings → Security → App pinning); iOS/iPadOS:
  "Guided Access"; desktop: full screen + child lock.
- `#web` — why the window must stay open on Web/Linux.

Keys: `battery.openExactAlarm`, `battery.openNotifications`, `battery.openBatteryOptimization`
(Android only; hidden on other platforms).

## Strings

`settingsTitle`, `settingsSection*`, `settingsTheme*`, `settingsChildLock`,
`settingsChildLockOffConfirm`, `settingsAlarmStatus*`, `settingsA11yInterval*`,
`batteryHelp*`.

## Planned tests

- Widget: each control changes the provider and persists (fake repository); alarm status states
  per platform (fake port); Android buttons hidden on other platforms; goldens.
- Integration: change the theme and reopen the app; MethodChannel intents on Android
  (instrumented test).
- E2E (Patrol, Android): deny exact alarm → ⚠ status → "Allow" opens the setting → grant → ✓
  status.
