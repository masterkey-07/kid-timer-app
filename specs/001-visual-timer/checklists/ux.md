# UX & Accessibility Requirements Checklist: Kid Timer

**Purpose**: Test the quality of the UI, accessibility and child well-being requirements before
implementation (specification PR review).
**Created**: 2026-10-23
**Feature**: [spec.md](../spec.md) · [contracts/ui](../contracts/ui/)
**Depth**: Standard · **Audience**: PR reviewer

## Requirement Completeness

- [x] CHK001 Are all states of each screen (empty, loading, error, success) defined in the UI contracts? [Completeness, contracts/ui/01–10]
- [x] CHK002 Do the layout requirements cover the three size classes in portrait and landscape for every v1.0 screen? [Coverage, contracts/ui/00 §3]
- [x] CHK003 Are there keyboard focus and navigation order requirements for every screen, including dialogs? [Completeness, Spec §FR-061]
- [x] CHK004 Is the behavior of the system "back" button/gesture specified for every screen, not only for `/run`? [Gap → addressed in contracts/ui/00 §3.1]
- [x] CHK005 Are the texts of all permission and platform notices defined in pt-BR and en or referenced by ARB key? [Completeness, contracts/ui/08]

## Requirement Clarity

- [x] CHK006 Is the "translucent neutral tone" of the elapsed sector quantified (color and opacity per theme)? [Clarity, Spec §FR-025, contracts/ui/00 §4]
- [x] CHK007 Are "gentle sounds" and "moderate volume" quantified (e.g., peak in dBFS, maximum duration)? [Clarity, Constitution II]
- [x] CHK008 Does the progressive palette's color transition have explicit thresholds and interpolation duration? [Clarity, Spec US6 scenario 1, data-model PaletteId]
- [x] CHK009 Does the padlock's "slight glow" when touched in child mode have a defined duration and intensity? [Clarity, Spec US4 scenario 2]

## Requirement Consistency

- [x] CHK010 Is the unlocked controls display time (10 s) the same in the spec, contract 02 and the controller? [Consistency, Spec §FR-031]
- [x] CHK011 Are the limits (100 presets, 50 images, 2–20 steps, name 1–40) identical across spec, data-model and contracts? [Consistency]
- [x] CHK012 Do the contracts' widget keys follow the `<screen>.<element>` pattern without collisions? [Consistency, contracts/ui/00 §6]

## Acceptance Criteria Quality

- [x] CHK013 Do SC-001 and SC-005 define the participants' profile and the "without instructions" condition reproducibly? [Measurability, Spec §SC-001/005]
- [x] CHK014 Does SC-003 define how the "random touches" are generated (manual vs automated, distribution)? [Measurability, Spec §SC-003]

## Scenario & Edge Case Coverage

- [x] CHK015 Is it defined what the child sees if the timer is paused by the adult while the screen stays in child mode? [Coverage, contracts/ui/02 Special states]
- [x] CHK016 Is there a requirement for when the chosen image has low contrast with the background (e.g., a white image on a light theme)? [Gap → addressed in contracts/ui/00 §3.2]
- [x] CHK017 Is the behavior with two monitors and the window moved during full screen defined? [Edge Case, Spec Edge Cases]
- [x] CHK018 Is the behavior defined when the screen reader is turned on in the middle of a countdown? [Coverage, Spec §FR-060]

## Non-Functional (Accessibility and well-being)

- [x] CHK019 Do the requirements guarantee that no animation exceeds 3 flashes per second, including the celebration particles? [Completeness, Constitution II]
- [x] CHK020 Is there a contrast requirement for labels over images in thumbnails and on the dial? [Gap, Spec §FR-060]
- [x] CHK021 Is the parental gate accessible to visually impaired adults without losing effectiveness against children? [Clarity, contracts/ui/07]
- [x] CHK022 Is it defined how the app behaves with "reduce transparency" (iOS/macOS) besides "reduce motion"? [Gap]

## Dependencies & Assumptions

- [x] CHK023 Does the assumption that the image library covers the 6 categories with images recognizable by young children have a validation criterion (e.g., a test with children/therapists)? [Assumption, Spec §FR-020]

## Notes

- Evaluated 2026-10-23; every item passes after the fixes below.
- CHK001: States sections added to contracts/ui/03, 07, 09 and 11.
- CHK002: per-screen layout table and compact landscape in contracts/ui/00 §3; goldens add
  800×360.
- CHK003: dialog focus rules in contracts/ui/00 §7.
- CHK004 / CHK016: addressed by `/speckit-analyze` (analysis.md F7, F8).
- CHK005: ARB keys listed in contracts/ui/08.
- CHK007: loudness targets in research R6, `tool/sounds/check_sounds.dart` (T134).
- CHK009: glow opacity and timing in contracts/ui/02 Behavior 2.
- CHK013 / CHK014: protocols in testing-strategy §8.
- CHK017 / CHK018: new spec Edge Cases; contracts/ui/02 Behavior 7 and Special states.
- CHK019: flash-safety rule in contracts/ui/00 §4; particle limits in contracts/ui/03.
- CHK020: text never over images, scrim rule in contracts/ui/00 §3.2.
- CHK022: decided: "reduce transparency" is not exposed by Flutter; covered through the
  increase-contrast setting (spec Assumptions, contracts/ui/00 §4).
- CHK023: recognition validation in research R9 (T094, T164).
