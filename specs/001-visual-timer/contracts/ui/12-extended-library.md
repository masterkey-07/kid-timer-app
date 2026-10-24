# UI Contract 12 — Extended emoji library

**Routes**: `/images/emoji`, `/images/emoji/:group` | **Story**: US15 | **Release**: v1.x

Both screens are opened from "Choose image" (contract 04) and pop the chosen image's
`BankImageSource` (id `emoji:<slug>` or `emoji:<slug>/<tone>`) back to it, which pops it to the
caller.

## 12.1 Groups and search (`/images/emoji`)

### Purpose

Show the whole Fluent Emoji set (minus the denylist) without overwhelming the adult: one card
per group first, and a search across every group.

### Wireframe — compact

```text
┌──────────────────────────────────────┐
│ ← All emoji                          │
├──────────────────────────────────────┤
│ [🔍 Search: name or keyword       ✕] │  search field, pt-BR and en
├──────────────────────────────────────┤
│ ┌────────────────┐┌────────────────┐ │  2 columns (compact), 3 (medium), 4 (expanded)
│ │ (◯)(◯)(◯)(◯)   ││ (◯)(◯)(◯)(◯)   │ │  four previews
│ │ Animals &      ││ Food & drink   │ │  group name
│ │ nature  · 140  ││          · 120 │ │  image count
│ └────────────────┘└────────────────┘ │
│ ┌────────────────┐┌────────────────┐ │
│ │ …              ││ …              │ │
└──────────────────────────────────────┘
```

With a query, the cards give way to one grid of every match (same tiles as contract 04, 3/5/7
columns), grouped under the name of the group each match belongs to.

### Components and keys

| Element      | Key                   | Semantics                              | Behavior                                                        |
| ------------ | --------------------- | -------------------------------------- | --------------------------------------------------------------- |
| Screen       | `emoji.screen`        | —                                      | —                                                               |
| Search field | `emoji.search`        | "Search emoji by name"                 | Filters as the adult types (case and accents ignored, FR-122)   |
| Clear search | `emoji.searchClear`   | "Clear search"                         | Back to the group cards                                         |
| Group card   | `emoji.group.<group>` | "Animals & nature, 140 images"         | Opens `/images/emoji/<group>`                                   |
| Result tile  | `emoji.item.<id>`     | the image's localized name; `selected` | Tap chooses and returns; long press opens the tones when it has |
| No results   | `emoji.noResults`     | "No emoji found for “…”"               | Shown instead of the grid                                       |

## 12.2 Group (`/images/emoji/:group`)

### Wireframe — compact

```text
┌──────────────────────────────────────┐
│ ← Animals & nature                   │
├──────────────────────────────────────┤
│ Mammals                              │  section header (subgroup)
│  (◯)   (◯)   (◯)                     │  3/5/7 columns, 96 dp thumbnails
│ Dog    Cat   Rabbit                  │
│ …                                    │
│ Birds                                │
│  (◯)   (◯)   (◯)                     │
└──────────────────────────────────────┘
```

Images are built and decoded only while on screen (a sliver grid per section), so opening a
group shows its first images within 300 ms (FR-121).

### Components and keys

| Element     | Key                        | Semantics                              | Behavior                                           |
| ----------- | -------------------------- | -------------------------------------- | -------------------------------------------------- |
| Screen      | `emojiGroup.screen`        | —                                      | —                                                  |
| Section     | `emojiGroup.section.<sub>` | header                                 | Labels the subgroup's images                       |
| Tile        | `emoji.item.<id>`          | the image's localized name; `selected` | Tap chooses and returns                            |
| Tone button | `emoji.tones.<id>`         | "Skin tones for Waving hand"           | Only on images with tones; opens the tone sheet    |
| Tone option | `emoji.tone.<id>.<tone>`   | "Medium skin tone"; `selected`         | In the sheet: default plus five tones; tap chooses |

## States

- Loading the manifest: a progress indicator in place of the cards (no spinner if ≤ 300 ms).
- An unknown `:group` (e.g., a reloaded Web page): redirect to `/images/emoji`.
- The tile of the current selection carries the 4 dp ring and ✓ of contract 04, also when the
  selection is a tone variant (its tile shows that tone).

## Strings

`emojiTitle`, `emojiOpen` (the entry in `/images`), `emojiSearchHint`, `emojiSearchLabel`,
`emojiSearchClear`, `emojiGroupLabel`, `emojiNoResults`, `emojiTonesLabel`, `emojiToneDefault`,
`emojiToneLight`, `emojiToneMediumLight`, `emojiToneMedium`, `emojiToneMediumDark`,
`emojiToneDark`. Group, subgroup and image names come from the manifest in pt-BR and en.

## Planned tests

- Unit: library index (groups in order with counts and previews, sections, search in both
  languages ignoring accents, tone variants, unknown ids).
- Widget: cards, opening a group, sections, lazy building, search and empty result, tone sheet,
  selection ring on a tone variant, 2/3/4 and 3/5/7 columns, accessibility guidelines, 200% text.
- Golden: groups screen and a group, light and dark.
- E2E: All emoji → Animals & nature → giraffe on the dial; search "girafa".
