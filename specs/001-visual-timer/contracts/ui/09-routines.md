# UI Contract 09 — Routines (v1.x)

**Routes**: `/routines`, `/routines/new`, `/routines/:id/edit`, `/routines/:id/run`
| **Story**: US8 | **Release**: v1.x

## 9.1 List (`/routines`)

Same pattern as the preset list ([05](./05-presets.md)): an item with a strip of up to 5 step
thumbnails, name, total duration, [▶].

```text
│ ≡ Morning routine   (◯)(◯)(◯)(◯)+2   35 min  [▶] │
```

Keys: `routines.new`, `routines.item.<id>`, `routines.start.<id>`, `routines.menu.<id>`.
The "New" button offers: "Step-by-step routine" or "First / Then" (`routines.newFirstThen`).

## 9.2 Editor (`/routines/new`, `/routines/:id/edit`)

```text
┌──────────────────────────────────────┐
│ ✕ New routine                  [Save]│
├──────────────────────────────────────┤
│ Name [Morning routine______]         │
│ Advance (•) automatic ( ) manual     │
│ STEPS (5)                            │
│ ≡ 1 (◯) Wake up           5 min  ⋮  │  tap → step editor (sheet)
│ ≡ 2 (◯) Get dressed      10 min  ⋮  │
│ ≡ 3 (◯) Breakfast        15 min  ⋮  │
│ [＋ Add step]                        │  disabled at 20
│ Total duration: 35 min               │
└──────────────────────────────────────┘
```

"Step" sheet: name (1–40), duration (mini dial + buttons), image (`/images`) or color, step-end
sound (default: soft transition). Validation: 2–20 steps (FR-070); "First / Then" requires
exactly 2.

Keys: `routineEditor.name`, `routineEditor.advanceMode`, `routineEditor.addStep`,
`routineEditor.step.<index>`, `routineEditor.save`, `stepSheet.name`, `stepSheet.dial`,
`stepSheet.image`, `stepSheet.done`.

## 9.3 Run (`/routines/:id/run`)

Child mode identical to `/run` ([02](./02-running-child-mode.md)) plus a step strip.

```text
┌──────────────────────────────────────┐
│ 🔒                                    │
│ ★ ★ (◯ now) (◯) (◯)                  │  strip: finished ones with ★, current enlarged with
│                                      │  primary border, upcoming ones dimmed
│          ╭────────────────╮          │
│          │ DialView of the│          │
│          │  current step  │          │
│          ╰────────────────╯          │
│             Brush teeth              │  step name (title)
│                01:42                 │
└──────────────────────────────────────┘
```

"First / Then" layout: two cards side by side (landscape) or stacked (portrait), labeled
"First" and "Then"; the dial fills the "First" card.

Manual mode, at the end of a step (`waitingNext`):

```text
│        ✓ Get dressed — done!         │
│      ┌────────────────────────┐      │
│      │   Next: Breakfast ▶    │      │  72 dp button, key routineRun.next
│      └────────────────────────┘      │  (outside the child lock: it is the child's action)
```

| Element             | Key                                  | Behavior                                     |
| ------------------- | ------------------------------------ | -------------------------------------------- |
| Strip               | `routineRun.strip`                   | semantics "Step 3 of 5: Brush teeth. 2 done" |
| Next                | `routineRun.next`                    | only in `waitingNext`                        |
| Controls (unlocked) | `routineRun.pause`, `.skip`, `.stop` | Skipping a step marks it without a star      |

When everything is done: final screen with stars ([03](./03-finished.md)).

## Planned tests

- Unit: `RoutineRunner` (automatic/manual, skip, pause, reconcile across several steps with the
  app closed, scheduling ≤ 60 notifications).
- Widget: editor (2–20 limits, reorder), strip, Next button, goldens.
- Integration: the run persists and resumes after a restart.
- E2E: a 3-step 30 s routine with the app in the background receives 3 notifications.
