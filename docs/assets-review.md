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

Pre-check (2026-10-24, by the implementing agent; not a review): all 40 images come from the
MIT repository at a pinned commit and are listed in `LICENSES.md`; none shows text, logos,
people or symbols; the notes column flags what a reviewer should look at closely.

| Asset                        | Label (en)      | Reviewer | Date | Verdict | Notes                                                  |
| ---------------------------- | --------------- | -------- | ---- | ------- | ------------------------------------------------------ |
| `bank:hygiene/brush_teeth`   | Brush teeth     | —        | —    | pending |                                                        |
| `bank:hygiene/bath`          | Take a bath     | —        | —    | pending |                                                        |
| `bank:hygiene/wash_hands`    | Wash hands      | —        | —    | pending |                                                        |
| `bank:hygiene/shower`        | Shower          | —        | —    | pending |                                                        |
| `bank:hygiene/toilet`        | Use the toilet  | —        | —    | pending |                                                        |
| `bank:hygiene/clean_up`      | Clean up        | —        | —    | pending |                                                        |
| `bank:meal/meal`             | Mealtime        | —        | —    | pending |                                                        |
| `bank:meal/breakfast`        | Breakfast       | —        | —    | pending |                                                        |
| `bank:meal/drink_milk`       | Drink milk      | —        | —    | pending |                                                        |
| `bank:meal/eat_fruit`        | Eat fruit       | —        | —    | pending |                                                        |
| `bank:meal/snack`            | Snack           | —        | —    | pending |                                                        |
| `bank:meal/eat_vegetables`   | Eat vegetables  | —        | —    | pending |                                                        |
| `bank:meal/dinner`           | Dinner          | —        | —    | pending |                                                        |
| `bank:play/toys`             | Play with toys  | —        | —    | pending |                                                        |
| `bank:play/puzzle`           | Puzzle          | —        | —    | pending |                                                        |
| `bank:play/ball`             | Play ball       | —        | —    | pending |                                                        |
| `bank:play/painting`         | Painting        | —        | —    | pending |                                                        |
| `bank:play/drawing`          | Drawing         | —        | —    | pending |                                                        |
| `bank:play/kite`             | Fly a kite      | —        | —    | pending |                                                        |
| `bank:play/video_game`       | Video games     | —        | —    | pending | Generic gamepad: check it reads as no console brand    |
| `bank:rest/sleep`            | Sleep           | —        | —    | pending |                                                        |
| `bank:rest/nap`              | Nap             | —        | —    | pending | Only face in the library; default yellow, no skin tone |
| `bank:rest/bedtime`          | Bedtime         | —        | —    | pending |                                                        |
| `bank:rest/relax`            | Relax           | —        | —    | pending |                                                        |
| `bank:rest/story_time`       | Story time      | —        | —    | pending |                                                        |
| `bank:rest/quiet_music`      | Listen to music | —        | —    | pending |                                                        |
| `bank:school/go_to_school`   | Go to school    | —        | —    | pending |                                                        |
| `bank:school/school`         | School          | —        | —    | pending | Plain green flag, no national symbol                   |
| `bank:school/homework`       | Homework        | —        | —    | pending |                                                        |
| `bank:school/reading`        | Reading         | —        | —    | pending |                                                        |
| `bank:school/writing`        | Writing         | —        | —    | pending |                                                        |
| `bank:school/counting`       | Counting        | —        | —    | pending |                                                        |
| `bank:goingOut/put_on_shoes` | Put on shoes    | —        | —    | pending |                                                        |
| `bank:goingOut/put_on_coat`  | Put on a coat   | —        | —    | pending |                                                        |
| `bank:goingOut/car_ride`     | Car ride        | —        | —    | pending |                                                        |
| `bank:goingOut/bus_ride`     | Bus ride        | —        | —    | pending |                                                        |
| `bank:goingOut/playground`   | Playground      | —        | —    | pending |                                                        |
| `bank:goingOut/bike_ride`    | Bike ride       | —        | —    | pending |                                                        |
| `bank:goingOut/shopping`     | Go shopping     | —        | —    | pending |                                                        |
| `bank:goingOut/go_home`      | Go home         | —        | —    | pending |                                                        |

## Recognition validation (R9, before v1.0)

Each library image is shown alone at 96 dp to at least 3 children aged 3–6 (with consent from
their guardians, no data recorded beyond the tally) or, if unavailable, to at least 2
teachers/therapists who judge it for that age. An image passes if ≥ 2/3 of the children name the
activity (or all professionals agree). Failing images are replaced. Record one row per session
and list the images that failed.

| Date | Group (children 3–6 / professionals) | Participants | Failed images | Notes |
| ---- | ------------------------------------ | ------------ | ------------- | ----- |
