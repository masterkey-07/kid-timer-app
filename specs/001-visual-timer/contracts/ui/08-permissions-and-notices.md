# UI Contract 08 — Permissions and platform notices

**Components**: `StartPreflight`, `PlatformNotice`, dialogs | **Story**: US2 | **Release**: v1.0

## 8.1 Start preflight (`StartPreflight`)

Runs when Start is tapped (home screen, preset, routine). Order:

```text
capabilities = AlarmScheduler.capabilities()
├─ scheduling == unsupported (Web, Linux, Windows without support)
│     └─ 1st time: dialog "Keep this window open" [Got it] (flag webKeepOpenSeen)
│        afterwards: only the PlatformNotice banner
├─ notifications == denied/notDetermined
│     ├─ notDetermined → requests the OS permission (Android 13+, iOS, macOS)
│     └─ denied → dialog "Without notifications, the alarm only rings with the app open"
│                [Open settings] [Continue anyway]
├─ exactAlarm == denied (Android 12–13 with SCHEDULE_EXACT_ALARM denied)
│     └─ 1st time: explanatory dialog [Allow] → system setting; re-checks on return
│        [Not now] → continues with reduced accuracy (inexact scheduling)
├─ iOS < 26 and 1st timer → one-time notice "In silent mode, the alarm with the app closed
│     doesn't ring. Keep the sound on." [Got it] (flag iosSilentWarned)
└─ system volume = 0 (Android/iOS) → 4 s notice banner, does not block
```

No dialog blocks starting once it has been answered; decisions are stored in
`AppSettings.onboarding`.

| Dialog               | Key                          | Buttons (keys)               |
| -------------------- | ---------------------------- | ---------------------------- |
| Keep window open     | `notice.keepOpen`            | `notice.keepOpen.ok`         |
| Notifications denied | `notice.notificationsDenied` | `.openSettings`, `.continue` |
| Exact alarm          | `notice.exactAlarm`          | `.allow`, `.notNow`          |
| iOS silent           | `notice.iosSilent`           | `.ok`                        |

## 8.2 `PlatformNotice` banner

- Appears at the top of the home screen and of the unlocked controls on `/run` when the alarm
  is not guaranteed in the background.
- Short text + "Learn more" link → `/settings/battery#web` or `#alarms`.
- Warning color with AA contrast; ⚠ icon with a label; never shown in child mode.
- Key: `notice.banner`.

## 8.3 System notifications (content)

| Type            | Title               | Body                            | Tap action                |
| --------------- | ------------------- | ------------------------------- | ------------------------- |
| Timer end       | "Time's up!"        | Preset name or "5 min timer"    | `vtc://run` → `/finished` |
| Step end (v1.x) | "Next: Brush teeth" | "Morning routine — step 3 of 5" | `vtc://run`               |
| Warning (v1.x)  | "1 minute left"     | name                            | `vtc://run`               |

Android channels: `timer_end` (maximum importance, the chosen alarm sound, vibration),
`timer_warning` (default, soft sound). Because an Android channel's sound is fixed once created,
each app sound has its own channel `timer_end_<soundId>`.

## Main strings

`noticeKeepOpenTitle`, `noticeKeepOpenBody`, `noticeKeepOpenOk`, `noticeNotificationsDeniedTitle`,
`noticeNotificationsDeniedBody`, `noticeOpenSettings`, `noticeContinueAnyway`,
`noticeExactAlarmTitle`, `noticeExactAlarmBody`, `noticeAllow`, `noticeNotNow`,
`noticeIosSilentBody`, `noticeVolumeZero`, `noticeBannerNoBackgroundAlarm`,
`noticeBannerReducedAccuracy`, `noticeLearnMore`, `notificationTimerEndTitle`,
`notificationTimerEndBody`, `notificationChannelTimerEnd`, `notificationChannelWarning`;
v1.x: `notificationStepEndTitle`, `notificationStepEndBody`, `notificationWarningTitle`,
`noticeAlarmKitTitle`, `noticeAlarmKitBody`. Every key exists in `app_pt.arb` and
`app_en.arb` (`tool/l10n_check.dart`).

## Planned tests

- Unit: the preflight decision tree with a fake port for every capability combination.
- Widget: each dialog, "already seen" flags.
- E2E (Patrol): Android 14 deny notifications → dialog → open settings; grant → start;
  notification content.
