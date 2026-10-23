# Contract — `.vtc.json` export format (v1.x)

A UTF-8 JSON file, extension `.vtc.json`, MIME `application/json`. Maximum size accepted on
import: 25 MB.

```json
{
  "format": "visual-time-counter-export",
  "formatVersion": 1,
  "exportedAt": "2026-10-23T12:00:00.000Z",
  "app": { "version": "1.2.0", "platform": "android" },
  "presets": [ { "...Preset without schemaVersion": "" } ],
  "routines": [ { "...Routine": "" } ],
  "images": [
    {
      "id": "uuid",
      "label": "Lucas",
      "mime": "image/jpeg",
      "width": 1024,
      "height": 1024,
      "dataBase64": "/9j/4AAQ…"
    }
  ]
}
```

## Validation rules (import)

1. `format` equals `visual-time-counter-export`; otherwise → `InvalidFile`.
2. `formatVersion` > supported → `UnsupportedVersion` with the message "Update the app".
3. Each preset/routine is validated by the rules in [data-model.md](../data-model.md) (name
   1–40, duration, 2–20 steps…). An invalid item → the whole file is rejected with a list of
   problems.
4. Images: valid base64, decodable JPEG, ≤ 1024 px, ≤ 1 MB each; `visual.type == "user"`
   references must point to an image in the file or one already on the device; if missing →
   the visual becomes the default palette (warning in the preview).
5. Ids: on an "add" import, all ids get new UUIDs and references are remapped; repeated names get
   the suffix " (2)", " (3)"…
6. Limits (100 presets, 50 images, routines unlimited up to 100): the excess requires explicit
   confirmation of a partial import.
7. Atomicity: writes go to temporary boxes and are swapped at the end; a failure restores the
   previous state (test with an injected failure).

## Export

- Presets/routines without an inner `schemaVersion` (the file has `formatVersion`).
- Images only if "Include my images" is checked; library images are never exported (referenced
  by id).
- File name: `visual-time-counter-YYYY-MM-DD.vtc.json`.
