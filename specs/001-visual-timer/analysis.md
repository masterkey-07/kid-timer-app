# Specification Analysis Report — 001-visual-timer

**Command**: `/speckit-analyze` (3rd run) | **Date**: 2026-10-23 | **Artifacts**: spec.md, plan.md,
tasks.md, research.md, data-model.md, contracts/, testing-strategy.md, constitution v1.1.0

## Open findings

| ID  | Category           | Severity | Location(s)                        | Summary                                                                                                                                        | Recommendation                                                                     |
| --- | ------------------ | -------- | ---------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| A1  | Dependency         | MEDIUM   | research R19, tasks T001/T008/T009 | The Application/Bundle ID derives from the GitHub user `masterkey-07` (hyphens are not allowed in IDs); changing it after publishing is costly | The product owner confirms the ID before T001                                      |
| A2  | Dependency         | MEDIUM   | research R9, tasks T092            | The license of the Fluent Emoji assets must be confirmed in the official repository                                                            | T092 decides before generating the library; Twemoji/Noto fallbacks already defined |
| A3  | Underspecification | MEDIUM   | research R4, FR-012, tasks T042    | Scheduling support on Windows is unknown                                                                                                       | Spike T042; the spec already covers the fallback (FR-015)                          |
| A4  | Ambiguity          | LOW      | spec §Clarifications               | 8 decisions taken with the recommended option, without product owner validation                                                                | Review the Clarifications section before starting US3/US4/US7                      |
| A6  | Terminology        | INFO     | spec.md                            | Platform names and OS features in the spec                                                                                                     | Accepted: they define product scope (see checklists/requirements.md)               |

## Fixed during the analysis

| ID  | Problem                                                                                          | Fix                                                                                                                |
| --- | ------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------ |
| F1  | No explicit FR/SC → tasks traceability (27 FRs covered only by ranges)                           | "Traceability" table added to tasks.md (70/70 items mapped)                                                        |
| F2  | FR-007 (one timer at a time) and the "replace after confirmation" edge case had no test          | Included in T058                                                                                                   |
| F3  | The "system volume 0" edge case had no task                                                      | Included in T076                                                                                                   |
| F4  | `persistence_roundtrip_test` cited in the strategy without a task                                | Included in T080                                                                                                   |
| F5  | Rescheduling after an app update not specified                                                   | `MY_PACKAGE_REPLACED` in T043                                                                                      |
| F6  | Persistence failure before scheduling not specified                                              | Rule in T058; image atomicity in T097                                                                              |
| F7  | System "back" behavior defined only for `/run`                                                   | Table §3.1 in contracts/ui/00                                                                                      |
| F8  | A light image vanishes on a light theme                                                          | 2 dp outline on the dial, contracts/ui/00 §3.2                                                                     |
| F9  | Test file names diverged between testing-strategy and tasks                                      | Aligned                                                                                                            |
| F10 | SC-001/SC-005/SC-010 (user tests) had no task                                                    | Included in T164                                                                                                   |
| F11 | `.specify/feature.json` ignored by Git would prevent new sessions from finding the feature       | Committed (comment in `.specify/.gitignore`)                                                                       |
| F12 | data-model `start`/`resume` scheduled before persisting                                          | Persist (with `flush`) first, then schedule                                                                        |
| F13 | Export allowed a partial import, contradicting FR-101; image size limits disagreed               | Whole-file rejection on limits; imported images re-processed (FR-100)                                              |
| F14 | Coverage exclusions differed between testing-strategy and T014                                   | Single list in testing-strategy §2 rule 8, used by T014                                                            |
| F15 | Edge Cases said "monotonic time", contradicting Constitution III                                 | Wall-clock `endsAt − now` wording                                                                                  |
| F16 | Checklist gaps (testing CHK001–019, ux CHK001–023)                                               | Resolved; see the Notes of each checklist                                                                          |
| F17 | Web build fetched CanvasKit from the gstatic CDN (Constitution I)                                | `--no-web-resources-cdn` (R20), checked by `privacy_check` (T015, T018, T160)                                      |
| F18 | US4, US7, US9 had no integration test; US10, US11, US14 had no E2E/integration (Constitution IV) | Suites added to T115, T150, T179, T183, T186, T204 and testing-strategy §3–§5                                      |
| F19 | System high contrast not honored in v1.0; goldens lacked high contrast (Constitution IV/V)       | FR-055 high-contrast variant (T050, T051, T144); FR-110 now the manual choice; golden matrix + high-contrast light |
| F20 | Per-platform support not declared in the spec (Constitution VI)                                  | "Platform support" table in spec.md                                                                                |
| F21 | Human review of sounds and icon, and the 25 MB APK limit, had no task                            | T134, T162 (review); T018, T160 (APK size)                                                                         |
| F22 | Up to 4 warnings per step broke the 60-notification budget of routines                           | FR-080 and `WarningOffsets` capped at 2 (T178)                                                                     |
| F23 | Web base href `/visual-time-counter/` did not match the `kid-timer-app` repository               | `/kid-timer-app/` in R20, T160, quickstart                                                                         |
| F24 | Plan flow did not reflect the per-platform single-ring rule; plan tree missed new tools/docs     | plan.md execution flow and structure updated                                                                       |
| F25 | Export identifiers still used "visual-time-counter"                                              | `kid-timer-export`, `kid-timer-YYYY-MM-DD.vtc.json`                                                                |
| F26 | `pause` cancelled the alarm before persisting                                                    | Persist first, then cancel (data-model, T058)                                                                      |
| F27 | Screen reader turned on mid-countdown only checked manually                                      | Case added to T113                                                                                                 |
| F28 | Spec status stale; "bank" vs "library" naming                                                    | Status updated; naming note in data-model                                                                          |

## Coverage Summary

| Metric                                          | Value                                                     |
| ----------------------------------------------- | --------------------------------------------------------- |
| Functional requirements                         | 58                                                        |
| Success criteria                                | 12                                                        |
| Requirements and success criteria with ≥ 1 task | 70/70 (100%)                                              |
| Total tasks                                     | 212 (v1.0: T001–T165; v1.x: T166–T208; polish: T209–T212) |
| Tasks without a mapped requirement              | Setup/infra (Phases 1, 2, 10, 18, 19) — expected          |
| Stories with E2E                                | 14/14                                                     |
| Open ambiguities                                | 1 (A4)                                                    |
| CRITICAL issues                                 | 0                                                         |

## Constitution Alignment

No violations. Packages outside the approved list (`url_launcher`, `uuid`, `hive_ce_flutter`,
`share_plus`, `flutter_alarmkit`) and the own MethodChannel are justified in plan.md →
Complexity Tracking. Principle IV is met: every story has test tasks before implementation, and
testing-strategy defines levels, coverage targets and E2E. Constitution v1.1.0 (documentation
language set to English) does not change any requirement.

## Next Actions

- Resolve A1 (and optionally A4), then run `/speckit-implement` starting at T001.
- Run `/speckit-analyze` again at the end of v1.0 (T211) and whenever requirements change.
