# Kid Timer

A **free and open source** visual timer for children. The adult picks a time and an image; the
child watches a dial shrink until time is up. Works on phones, tablets, computers and in the
browser.

- No ads, no purchases, no accounts.
- Works offline; no data ever leaves the device.
- Built-in image library, plus photos from the device itself.
- Alarm that rings even with the app closed (Android, iOS, macOS).
- Child lock, calm mode, accessible (screen readers, keyboard, large fonts).
- Brazilian Portuguese and English.

> **Status**: specification and planning complete; implementation not started yet.

## Platforms

Android 8+, iOS/iPadOS 16+, macOS 13+, Windows 10+, Linux (x64) and Web.

## How the project is developed

We use **Spec-Driven Development** with [GitHub Spec Kit](https://github.com/github/spec-kit)
and Claude Code:

- Project rules: [`.specify/memory/constitution.md`](.specify/memory/constitution.md)
- Specification, plan, UI contracts, tests and tasks:
  [`specs/001-visual-timer/`](specs/001-visual-timer/)
- Agent guide: [`CLAUDE.md`](CLAUDE.md)

To continue the implementation with Claude Code, open the repository and run
`/speckit-implement`.

## Development

Prerequisites and commands are in
[`specs/001-visual-timer/quickstart.md`](specs/001-visual-timer/quickstart.md). In short:

```bash
fvm install && fvm use
fvm flutter pub get
fvm flutter run
fvm flutter test
```

## Privacy

The app does not collect, send or store any data outside the device. Chosen images stay only
in the app's own storage.

## License

Code under [Apache-2.0](LICENSE). Images, sounds and fonts carry their own free licenses,
listed in `assets/**/LICENSES.md`.

Inspired by the general concept of visual timers; not affiliated with Fehners Software or
Time Timer LLC.
