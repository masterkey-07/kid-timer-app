# Contract — `.vtc.json` export format (v1.x)

A UTF-8 JSON file, extension `.vtc.json`, MIME `application/json`. Maximum size accepted on
import: 25 MB.

```json
{
  "format": "kid-timer-export",
  "formatVersion": 1,
  "exportedAt": "2026-10-23T12:00:00.000Z",
  "app": { "version": "1.2.0", "platform": "android" },
  "presets": [{ "...Preset without schemaVersion": "" }],
  "routines": [{ "...Routine": "" }],
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

1. `format` equals `kid-timer-export`; otherwise → `InvalidFile`.
2. `formatVersion` > supported → `UnsupportedVersion` with the message "Update the app".
3. Each preset/routine is validated by the rules in [data-model.md](../data-model.md) (name
   1–40, duration, 2–20 steps…). An invalid item → the whole file is rejected with a list of
   problems.
4. Images: valid base64, decodable JPEG, ≤ 1024 px, ≤ 1 MB each. Every
   image is re-processed by `ImageProcessor` before being stored (decode, resize to
   1024×1024, re-encode JPEG ≤ 400 KB without metadata — FR-023); the file's bytes are never
   stored as-is. `visual.type == "user"` references must point to an image in the file or one
   already on the device; if missing → the visual becomes the default palette (warning in the
   preview).
5. Ids: on an "add" import, all ids get new UUIDs and references are remapped; repeated names get
   the suffix " (2)", " (3)"…
6. Limits (100 presets, 100 routines, 50 own images) are checked against the final state (the
   existing data plus the file in "add" mode; the file alone in "replace" mode). If any limit
   would be exceeded, the whole file is rejected with `LimitExceeded` listing how many items
   fit; nothing is partially imported (FR-101).
7. Atomicity: writes go to temporary boxes and are swapped at the end; a failure restores the
   previous state (test with an injected failure).

## Export

- Presets/routines without an inner `schemaVersion` (the file has `formatVersion`).
- Images only if "Include my images" is checked; the stored processed bytes (already without
  metadata) are exported; library images are never exported (referenced
  by id).
- File name: `kid-timer-YYYY-MM-DD.vtc.json`.
