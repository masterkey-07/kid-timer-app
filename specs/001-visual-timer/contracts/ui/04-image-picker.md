# UI Contract 04 — Images: built-in library, own image and "My images"

**Routes**: `/images`, `/images/frame`, `/images/mine` | **Story**: US3 | **Release**: v1.0

## 4.1 Choose image (`/images`)

### Purpose

Choose the image for a timer or preset: built-in library by category, "My images" or a new photo
from the device.

### Wireframe — compact

```text
┌──────────────────────────────────────┐
│ ← Choose image               [Manage]│  Manage → /images/mine
├──────────────────────────────────────┤
│ [All][Hygiene][Meals][Play]          │  wrapped tabs (chips) per category + "Mine"
│ [Rest][School][Going out][Animals]   │
│ [My images]                          │
├──────────────────────────────────────┤
│ ┌────────────────────────────────┐   │
│ │ ＋ From my device               │   │  always the first item
│ └────────────────────────────────┘   │
│  (◯)   (◯)   (◯)                     │  grid of 96 dp circular thumbnails
│ Brush  Bath  Wash                    │  label below (max 2 lines)
│ teeth        hands                   │
│  (◯)   (◯)   (◯)                     │
│  …                                   │
├──────────────────────────────────────┤
│ [○ No image (use colors)]            │  fixed footer
└──────────────────────────────────────┘
```

Grid: 3 columns (compact), 5 (medium), 7 (expanded). Current selection with a 4 dp ring in the
primary color and a ✓.

### Components and keys

| Element          | Key                     | Semantics                               | Behavior                                                                        |
| ---------------- | ----------------------- | --------------------------------------- | ------------------------------------------------------------------------------- |
| Category tab     | `images.tab.<category>` | "Category Hygiene, 6 images"            | Filters the grid                                                                |
| From my device   | `images.fromDevice`     | "Choose an image from my device"        | Opens the system picker (FR-021); with 50 images, limit dialog → `/images/mine` |
| Thumbnail        | `images.item.<id>`      | the image's localized label; `selected` | Tap selects and returns (`pop(result)`)                                         |
| No image         | `images.none`           | "Use colors instead of an image"        | `pop(PaletteSource)`                                                            |
| Manage           | `images.manage`         | "Manage my images"                      | `/images/mine`                                                                  |
| All emoji (v1.x) | `images.allEmoji`       | "Browse all emoji"                      | Below the tabs; opens `/images/emoji` (contract 12) and returns what it pops    |
| Grid             | `images.grid`           | —                                       | 3/5/7 columns per size class                                                    |
| Empty "Mine"     | `images.mineEmpty`      | "You haven't added any images yet"      | Holds its own "From my device" button (`images.mineEmpty.fromDevice`)           |
| Web note         | `images.webNote`        | the note text                           | Web only, below "From my device"                                                |
| Open error       | `images.openError`      | the snackbar text                       | Snackbar for an invalid, unsupported or corrupted file                          |

### States

- Library: always available offline (assets). Empty "My images": illustration + text "You
  haven't added any images yet" + "From my device" button.
- Web: note below "From my device": "In the browser, your images are saved only in this browser
  and disappear if you clear the site's data."
- Picker cancelled by the user: nothing happens.
- Invalid file/unsupported HEIC/corrupted: snackbar "This image couldn't be opened. Try a JPG
  or PNG photo." (FR, scenario 10).

## 4.2 Frame image (`/images/frame`)

### Wireframe

```text
┌──────────────────────────────────────┐
│ ✕ Frame                        [Save]│
├──────────────────────────────────────┤
│   ┌──────────────────────────────┐   │
│   │░░░░░░╭──────────────╮░░░░░░░│   │  draggable/pinchable image under a circular mask;
│   │░░░░░╭┤   circle     ├╮░░░░░░│   │  outside the circle darkened 60%
│   │░░░░░│ │    area      │ │░░░░░│   │
│   │░░░░░╰┤              ├╯░░░░░░│   │
│   │░░░░░░╰──────────────╯░░░░░░░│   │
│   └──────────────────────────────┘   │
│   Zoom  [−] ━━━━━━●━━━━━ [+]         │  slider 1.0×–4.0× (accessible)
│   [↺ Center]                         │
│   Name (optional): [______________]  │  ≤ 40 characters
└──────────────────────────────────────┘
```

### Components and keys

| Element      | Key            | Behavior                                                                                                                       |
| ------------ | -------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| Framing area | `frame.canvas` | Drag moves; pinch zooms; keyboard: arrows move 8 px, +/− zoom                                                                  |
| Zoom slider  | `frame.zoom`   | 1.0–4.0, step 0.1; semantics "Zoom 150%"                                                                                       |
| Center       | `frame.reset`  | Back to zoom 1.0 centered                                                                                                      |
| Name         | `frame.name`   | Optional, the image's accessible label                                                                                         |
| Save         | `frame.save`   | Processes (decode, crop, 1024×1024, JPEG 85, no metadata — FR-023) with a progress indicator; success → `pop(UserImageSource)` |
| Cancel       | `frame.cancel` | Discards without saving                                                                                                        |

Processing > 300 ms shows a "Preparing image…" overlay (`frame.preparing`); errors: storage full, decoding failure →
friendly message in a snackbar (`frame.error`), nothing saved (atomic).

## 4.3 My images (`/images/mine`)

```text
┌──────────────────────────────────────┐
│ ← My images (12 of 50)               │
├──────────────────────────────────────┤
│  (◯)✕  (◯)✕  (◯)✕                   │  grid; ✕ delete
│  Lucas  School  Park                 │
└──────────────────────────────────────┘
```

| Element | Key                | Behavior                                                                                                          |
| ------- | ------------------ | ----------------------------------------------------------------------------------------------------------------- |
| Item    | `mine.item.<id>`   | Long press opens its menu: rename, delete                                                                         |
| Delete  | `mine.delete.<id>` | `ConfirmDialog` listing affected presets/routines (FR-024); confirm → removes bytes + references switch to colors |
| Counter | `mine.count`       | "12 of 50"                                                                                                        |
| Grid    | `mine.grid`        | Same columns as `/images`; empty state `mine.empty`                                                               |
| Rename  | `mine.rename.<id>` | In the item's menu; dialog with `mine.renameField` (≤ 40 characters) and `mine.renameSave`                        |

## Strings

`imagesTitle`, `imagesFromDevice`, `imagesNone`, `imagesManage`, `imagesCategory*`,
`imagesWebStorageNote`, `imagesOpenError`, `imagesLimitReached`, `frameTitle`, `frameZoom`,
`frameCenter`, `frameName`, `frameSave`, `framePreparing`, `mineTitle`, `mineCount`,
`mineDeleteConfirm`, `mineAffectedPresets`.

## Planned tests

- Unit: `ImageProcessor` (crop, 1024 size, EXIF removal verified by reading the resulting JPEG,
  rejection of invalid files); `UserImageRepository` (limit 50, reference count, atomic delete).
- Widget: grid by category, selection, empty states, keyboard framing, goldens.
- Integration: save an image and reopen the app → image available (Android, Linux, Web).
- E2E (Patrol): Android/iOS photo picker without a permission dialog (FR-021); choose a photo,
  frame, save, see it on the dial (SC-005).
