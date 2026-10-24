# Asset review

Human review of every bundled asset (Constitution II and IX). An asset ships only with an
`approved` verdict here. The criteria are in `specs/001-visual-timer/research.md` (R9); an asset
fails if any criterion fails:

1. License verified at the source and listed in the folder's `LICENSES.md`.
2. No violence, fear, weapons, brands, logos, text or religious/political symbols.
3. No stereotypes (gender; skin tone variants where people appear).
4. Recognizable at 64 dp.
5. Sounds only: the R6 targets pass.

Verdicts: `pending`, `approved` or `rejected` (replace a rejected asset and add a row for its
replacement). Reviewer is the person who looked at the asset; tools never sign a row.

## Image library (`assets/images/bank/`)

Source: Fluent Emoji "Color", MIT, license verified for T092 (research R9). Built by
`tool/image_bank/build.mjs`. To review, open the WebPs, or view them at 64 dp in the app's
image picker once US3 is in.

Pre-check (2026-10-24, by the implementing agent; not a review): all 48 images come from the
MIT repository at a pinned commit and are listed in `LICENSES.md`; none shows text, logos,
people or symbols; the notes column flags what a reviewer should look at closely.

| Asset                        | Label (en)      | Reviewer                     | Date       | Verdict  | Notes                                                  |
| ---------------------------- | --------------- | ---------------------------- | ---------- | -------- | ------------------------------------------------------ |
| `bank:hygiene/brush_teeth`   | Brush teeth     | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:hygiene/bath`          | Take a bath     | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:hygiene/wash_hands`    | Wash hands      | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:hygiene/shower`        | Shower          | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:hygiene/toilet`        | Use the toilet  | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:hygiene/clean_up`      | Clean up        | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:meal/meal`             | Mealtime        | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:meal/breakfast`        | Breakfast       | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:meal/drink_milk`       | Drink milk      | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:meal/eat_fruit`        | Eat fruit       | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:meal/snack`            | Snack           | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:meal/eat_vegetables`   | Eat vegetables  | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:meal/dinner`           | Dinner          | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:play/toys`             | Play with toys  | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:play/puzzle`           | Puzzle          | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:play/ball`             | Play ball       | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:play/painting`         | Painting        | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:play/drawing`          | Drawing         | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:play/kite`             | Fly a kite      | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:play/video_game`       | Video games     | Victor Jorge Carvalho Chaves | 2026-10-24 | approved | Generic gamepad: check it reads as no console brand    |
| `bank:rest/sleep`            | Sleep           | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:rest/nap`              | Nap             | Victor Jorge Carvalho Chaves | 2026-10-24 | approved | Only face in the library; default yellow, no skin tone |
| `bank:rest/bedtime`          | Bedtime         | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:rest/relax`            | Relax           | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:rest/story_time`       | Story time      | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:rest/quiet_music`      | Listen to music | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:school/go_to_school`   | Go to school    | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:school/school`         | School          | Victor Jorge Carvalho Chaves | 2026-10-24 | approved | Plain green flag, no national symbol                   |
| `bank:school/homework`       | Homework        | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:school/reading`        | Reading         | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:school/writing`        | Writing         | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:school/counting`       | Counting        | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:goingOut/put_on_shoes` | Put on shoes    | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:goingOut/put_on_coat`  | Put on a coat   | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:goingOut/car_ride`     | Car ride        | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:goingOut/bus_ride`     | Bus ride        | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:goingOut/playground`   | Playground      | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:goingOut/bike_ride`    | Bike ride       | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:goingOut/shopping`     | Go shopping     | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:goingOut/go_home`      | Go home         | Victor Jorge Carvalho Chaves | 2026-10-24 | approved |                                                        |
| `bank:animals/dog`           | Dog             | —                            | —          | pending  |                                                        |
| `bank:animals/cat`           | Cat             | —                            | —          | pending  |                                                        |
| `bank:animals/rabbit`        | Rabbit          | —                            | —          | pending  |                                                        |
| `bank:animals/panda`         | Panda           | —                            | —          | pending  |                                                        |
| `bank:animals/elephant`      | Elephant        | —                            | —          | pending  |                                                        |
| `bank:animals/turtle`        | Turtle          | —                            | —          | pending  |                                                        |
| `bank:animals/penguin`       | Penguin         | —                            | —          | pending  |                                                        |
| `bank:animals/butterfly`     | Butterfly       | —                            | —          | pending  |                                                        |

## Recognition validation (R9, before v1.0)

Each library image is shown alone at 96 dp to at least 3 children aged 3–6 (with consent from
their guardians, no data recorded beyond the tally) or, if unavailable, to at least 2
teachers/therapists who judge it for that age. An image passes if ≥ 2/3 of the children name the
activity (or all professionals agree). Failing images are replaced. Record one row per session
and list the images that failed.

| Date | Group (children 3–6 / professionals) | Participants | Failed images | Notes |
| ---- | ------------------------------------ | ------------ | ------------- | ----- |
