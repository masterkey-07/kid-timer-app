# UI Contract 10 — Export and import (v1.x)

**Route**: `/transfer` (after the parental gate) | **Story**: US13 | **Release**: v1.x

## Wireframe

```text
┌──────────────────────────────────────┐
│ ← Export and import                  │
├──────────────────────────────────────┤
│ EXPORT                               │
│  [✓] Presets (12)                    │
│  [✓] Routines (3)                    │
│  [✓] Include my images (8, ~1.2 MB)  │
│  [ Export file ]                     │  mobile: share sheet; desktop/web: save as
│ IMPORT                               │
│  [ Choose .vtc.json file ]           │
└──────────────────────────────────────┘
```

Import preview (sheet):

```text
│ File from 2026-10-23 — v1                 │
│ 12 presets · 3 routines · 8 images        │
│ (•) Add to my data                        │
│ ( ) Replace everything (deletes current)  │
│ [Cancel]                       [Import]   │
```

| Element        | Key                                                          | Behavior                                                                              |
| -------------- | ------------------------------------------------------------ | ------------------------------------------------------------------------------------- |
| Export options | `transfer.exportPresets`, `.exportRoutines`, `.exportImages` | Estimated size recomputed                                                             |
| Export         | `transfer.export`                                            | Generates `visual-time-counter-YYYY-MM-DD.vtc.json` ([contract](../export-format.md)) |
| Import         | `transfer.import`                                            | Opens the picker; validates; shows the preview                                        |
| Mode           | `transfer.mode.add`, `transfer.mode.replace`                 | Replace asks for a second confirmation                                                |
| Confirm        | `transfer.confirmImport`                                     | Atomic import (FR-101); snackbar with a summary                                       |

Errors: invalid file, future version, corrupted image, preset/image limit exceeded (in add mode,
shows how many fit and offers a partial import — an explicit exception to atomicity, only with
confirmation).

## Planned tests

- Unit: format serialization/validation, versions, name conflicts (" (2)"), atomicity with a
  failure simulated midway.
- Widget: preview flow, modes, errors.
- Integration: export and import in the same app (identical round trip).
- E2E: Android exports via the share sheet (Patrol), Linux imports a file (integration).
