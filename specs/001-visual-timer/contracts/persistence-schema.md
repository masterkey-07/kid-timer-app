# Contract — Persistence schema (hive_ce)

All boxes live in the app support directory (IO) or in IndexedDB (Web). Values are JSON-compatible
`Map<String, dynamic>`, except `user_images` (bytes). Every document has a `schemaVersion`. Boxes
are opened in `bootstrap()` before `runApp`.

| Box                | Type                 | Key                              | Value                     |
| ------------------ | -------------------- | -------------------------------- | ------------------------- |
| `settings`         | `Box<Map>`           | `"app"`                          | AppSettings               |
| `presets`          | `Box<Map>`           | preset id                        | Preset                    |
| `routines` (v1.x)  | `Box<Map>`           | routine id                       | Routine                   |
| `session`          | `Box<Map>`           | `"timer"`, `"routineRun"` (v1.x) | TimerSession / RoutineRun |
| `user_images_meta` | `Box<Map>`           | image id                         | ImageAsset(user) metadata |
| `user_images`      | `LazyBox<Uint8List>` | image id                         | 1024×1024 JPEG            |

## Documents (schemaVersion 1)

### TimerConfig (embedded)

```json
{
  "durationMs": 300000,
  "scale": "min60",
  "direction": "clockwise",
  "visual": {
    "type": "palette",
    "paletteId": "progressive",
    "singleColor": null
  },
  "soundId": "chime_soft",
  "alarmVolume": 0.7,
  "tickEnabled": false,
  "tickVolume": 0.3,
  "vibrate": true,
  "showDigits": true,
  "imageEffect": "vanish",
  "warningsMin": []
}
```

`visual` alternatives: `{ "type": "bank", "imageId": "bank:hygiene/toothbrush" }`,
`{ "type": "user", "imageId": "4f0c…" }`.

### AppSettings — `settings["app"]`

```json
{
  "schemaVersion": 1,
  "themeMode": "system",
  "childLockEnabled": true,
  "a11yAnnounceInterval": "oneMin",
  "defaults": { "...TimerConfig": "" },
  "lastConfig": { "...TimerConfig": "" },
  "onboarding": {
    "exactAlarmExplained": false,
    "iosSilentWarned": false,
    "webKeepOpenSeen": false,
    "examplesSeeded": false,
    "dialHintDismissed": false
  }
}
```

### Preset — `presets[id]`

```json
{
  "schemaVersion": 1,
  "id": "uuid",
  "name": "Brush teeth",
  "order": 0,
  "isExample": true,
  "favorite": false,
  "config": { "...TimerConfig": "" },
  "createdAt": "2026-10-23T12:00:00.000Z",
  "updatedAt": "2026-10-23T12:00:00.000Z"
}
```

### TimerSession — `session["timer"]`

```json
{
  "schemaVersion": 1,
  "id": "uuid",
  "status": "running",
  "config": { "...TimerConfig": "" },
  "startedAt": "2026-10-23T12:00:00.000Z",
  "endsAt": "2026-10-23T12:05:00.000Z",
  "pausedRemainingMs": null,
  "origin": { "type": "preset", "presetId": "uuid" },
  "scheduledNotificationIds": [123456],
  "finishedAcknowledged": false
}
```

Writing: immediately on every transition, with `await box.put` + `box.flush()` before scheduling
the alarm (guarantees that reopening after process death finds the state).

### ImageAsset(user) meta — `user_images_meta[id]`

```json
{
  "schemaVersion": 1,
  "id": "uuid",
  "label": "Lucas",
  "createdAt": "…",
  "width": 1024,
  "height": 1024,
  "byteLength": 183422
}
```

Invariant: meta exists ⇔ bytes exist. Writes in the order bytes → meta; deletes in the order
meta → bytes; `bootstrap()` removes orphans (integrity test).

### Routine / RoutineRun (v1.x)

Follow [data-model.md](../data-model.md) with the same serialization patterns; RoutineRun stores
the full `routineSnapshot`.

## Migrations

- `lib/core/persistence/migrator.dart` applies sequential `vN → vN+1` migrations per box on
  opening.
- Each migration is a pure `Map → Map` function with a dedicated test (JSON fixture of the old
  version in `test/fixtures/persistence/vN/`).
- Migration failure: the original document is copied into `<box>_backup` with a timestamp, the
  app uses defaults and shows a one-time notice (Edge Cases).
- A document with a `schemaVersion` higher than supported (downgrade): treated as a migration
  failure, without overwriting the original.
