# UI Contract 05 — Presets

**Routes**: `/presets`, `/presets/new`, `/presets/:id/edit` | **Story**: US5
| **Release**: v1.0 (widget favorites: v1.x)

## 5.1 List (`/presets`)

```text
┌──────────────────────────────────────┐
│ ← Presets                    [＋ New] │
├──────────────────────────────────────┤
│ ≡ (◯) Brush teeth         2 min  [▶] │  ≡ drag handle; (◯) image/color thumbnail
│ ≡ (◯) Bath               10 min  [▶] │  [▶] starts directly (FR-041)
│ ≡ (◯) Homework           25 min  [▶] │  tapping the body → edit
│ …                                    │  ⋮ menu per item: Edit, Duplicate, Favorite (v1.x),
│                                      │  Delete
└──────────────────────────────────────┘
```

Expanded: grid of 2–3 column cards, reordering by drag and by keyboard (Ctrl+↑/↓ moves the
focused item).

| Element | Key | Semantics | Behavior |
|---|---|---|---|
| New | `presets.new` | "New preset" | `/presets/new` with `lastConfig` |
| Item | `presets.item.<id>` | "Brush teeth, 2 minutes" + custom actions (Edit, Duplicate, Delete, Move up/down) | Tap → edit |
| Start | `presets.start.<id>` | "Start Brush teeth" | Starts a session with origin `preset(id)` → `/run` |
| Handle | `presets.drag.<id>` | — | Reorders; persists `order` |
| Menu | `presets.menu.<id>` | "More options" | Edit/Duplicate/Favorite/Delete |
| Delete | `presets.delete.<id>` | — | `ConfirmDialog`; undo via a 5 s snackbar |

States: empty → illustration + "Create presets to start timers with one tap" + New button.
Limit 100 → New button disabled with an explanation.

## 5.2 Editor (`/presets/new`, `/presets/:id/edit`)

```text
┌──────────────────────────────────────┐
│ ✕ New preset                   [Save]│
├──────────────────────────────────────┤
│ Name  [Brush teeth_______________]   │  1–40 characters; counter 11/40
│ (editable mini DialView)  02:00      │
│ [−1][+1][+5]                         │
│ Image  (◯) Brush teeth [Change] ✕    │
│ Scale  [5][10][15][30][60][120]      │
│ Direction (•) clockwise ( ) counter  │
│ Colors [Progressive ▾]  (no image)   │
│ Sound  [Soft chime ▾] [▶ preview]    │
│ Volume ━━━━━●━━━                     │
│ Ticking [  ]  Vibrate [✓]            │
│ Show digits [✓]                      │
│ ─ v1.x ─                             │
│ Image effect [Vanish ▾]              │
│ Warnings [ ]1 [ ]2 [✓]5 [ ]10 min    │
│ Widget favorite [ ]                  │
└──────────────────────────────────────┘
```

| Element | Key | Rules |
|---|---|---|
| Name | `presetEditor.name` | required, `trim`, 1–40 (FR-040); inline error "Use 1 to 40 characters" |
| Duration | `presetEditor.dial` | same as the home screen |
| Image | `presetEditor.image` | opens `/images` |
| Scale | `presetEditor.scale.<value>` | segmented |
| Direction | `presetEditor.direction` | — |
| Palette | `presetEditor.palette` | progressive, single color (+ 8-color picker), calm |
| Sound | `presetEditor.sound` | list + preview |
| Volume | `presetEditor.volume` | 0–100% |
| Ticking | `presetEditor.tick` | — |
| Vibrate | `presetEditor.vibrate` | hidden without support |
| Digits | `presetEditor.digits` | — |
| Save | `presetEditor.save` | validates; persists; back to the list |
| Leave without saving | `presetEditor.close` | if there are changes, confirmation "Discard changes?" |

## Strings

`presetsTitle`, `presetsNew`, `presetsEmpty`, `presetsLimit`, `presetsStart`,
`presetsDuplicateSuffix`, `presetsDeleted`, `presetsUndo`, `presetEditorName`,
`presetEditorNameError`, `presetEditorDiscard`, …

## Planned tests

- Unit: `PresetRepository` (CRUD, gap-free order, limit 100, examples seeded once, schema
  migration), name validation.
- Widget: list, reordering by drag and keyboard, undo, editor with validation, goldens.
- Integration: create → restart app → preset present and startable.
- E2E: SC-006 (from home to `/run` in 2 taps via `home.preset.<id>` + ▶ or `presets.start`).
