# UI Contract 07 — Parental gate and parent area

**Component**: `ParentalGate` (dialog) | **Route**: `/parent` | **Story**: US7
| **Release**: v1.0

## 7.1 Parental gate (modal dialog)

```text
┌──────────────────────────────────────┐
│ Parent area                       ✕  │
│                                      │
│ To continue, answer:                 │
│        seven times eight             │  numbers in words (FR-063), current language
│                                      │
│          [   5 6   ]                 │  read-only field
│   [1] [2] [3]                        │  custom numeric keypad (64 dp buttons)
│   [4] [5] [6]                        │  fixed digit order (accessibility)
│   [7] [8] [9]                        │
│   [⌫] [0] [OK]                       │
│                                      │
│  Attempts left: 2                    │  after the 1st error
└──────────────────────────────────────┘
```

| Element  | Key                                           | Behavior                                                            |
| -------- | --------------------------------------------- | ------------------------------------------------------------------- |
| Question | `gate.question`                               | Random factors 3–9 (seed testable via an injected `Random`)         |
| Keys     | `gate.key.<0-9>`, `gate.backspace`, `gate.ok` | At most 2 digits                                                    |
| Error    | `gate.error`                                  | "Incorrect answer"; new question                                    |
| Lockout  | `gate.lockout`                                | After 3 errors: "Try again in 30 s" with a countdown; keys disabled |

- Physical keyboard: digits, Backspace, Enter.
- Success: records `parentalUnlockedAt` in memory (not persisted); valid for 5 min for `/parent`
  and `/transfer`.
- Semantics: the question is read by the screen reader (the gate does not depend on vision).

## 7.2 Parent area (`/parent`)

```text
┌──────────────────────────────────────┐
│ ← Parent area                        │
├──────────────────────────────────────┤
│ Kid Timer  v1.0.0 (build)  │
│ Free, no ads and no data collection. │
│ ───────────────────────────────────  │
│ Privacy policy                 >     │  local localized text (does not open the web)
│ Open source licenses           >     │  showLicensePage + asset licenses
│ Image and sound credits        >     │  reads the manifests (author, license, source)
│ Source code on GitHub          ↗     │  confirmation → url_launcher
│ Report a problem               ↗     │  generates diagnostic text (no personal data)
│                                      │  to copy; button opens GitHub issues
│ Help: battery and alarms       >     │
└──────────────────────────────────────┘
```

| Element     | Key               | Behavior                                                                        |
| ----------- | ----------------- | ------------------------------------------------------------------------------- |
| Privacy     | `parent.privacy`  | Text screen (local Markdown rendered as plain text)                             |
| Licenses    | `parent.licenses` | `LicenseRegistry` includes `assets/**/LICENSES.md`                              |
| Credits     | `parent.credits`  | List from the library and sound manifests                                       |
| Source code | `parent.source`   | Dialog "Open the browser?" → `url_launcher`                                     |
| Report      | `parent.report`   | Copies: version, platform, OS, screen size, permission status; nothing personal |

## Strings

`gateTitle`, `gatePrompt`, `gateWrong`, `gateLockout`, `gateNumberWords` (0–9 and products in
words via ICU/plural or a table), `parentTitle`, `parentTagline`, `parentPrivacy`,
`parentLicenses`, `parentCredits`, `parentSource`, `parentReport`, `parentOpenBrowserConfirm`,
`privacyPolicyBody`.

## Planned tests

- Unit: question generator (factors 3–9), numbers in words in pt/en, 3-error/30 s rule with
  `fake_async`, 5 min validity.
- Widget: success/error/lockout flow, physical keyboard, goldens.
- E2E: tap ⓘ on the home screen → gate → parent area; external link asks for confirmation.
