# UX & Accessibility Requirements Checklist: Kid Timer

**Purpose**: Test the quality of the UI, accessibility and child well-being requirements before
implementation (specification PR review).
**Created**: 2026-10-23
**Feature**: [spec.md](../spec.md) · [contracts/ui](../contracts/ui/)
**Depth**: Standard · **Audience**: PR reviewer

## Requirement Completeness

- [ ] CHK001 Are all states of each screen (empty, loading, error, success) defined in the UI contracts? [Completeness, contracts/ui/01–10]
- [ ] CHK002 Do the layout requirements cover the three size classes in portrait and landscape for every v1.0 screen? [Coverage, contracts/ui/00 §3]
- [ ] CHK003 Are there keyboard focus and navigation order requirements for every screen, including dialogs? [Completeness, Spec §FR-061]
- [ ] CHK004 Is the behavior of the system "back" button/gesture specified for every screen, not only for `/run`? [Gap → addressed in contracts/ui/00 §3.1]
- [ ] CHK005 Are the texts of all permission and platform notices defined in pt-BR and en or referenced by ARB key? [Completeness, contracts/ui/08]

## Requirement Clarity

- [ ] CHK006 Is the "translucent neutral tone" of the elapsed sector quantified (color and opacity per theme)? [Clarity, Spec §FR-025, contracts/ui/00 §4]
- [ ] CHK007 Are "gentle sounds" and "moderate volume" quantified (e.g., peak in dBFS, maximum duration)? [Clarity, Constitution II]
- [ ] CHK008 Does the progressive palette's color transition have explicit thresholds and interpolation duration? [Clarity, Spec US6 scenario 1, data-model PaletteId]
- [ ] CHK009 Does the padlock's "slight glow" when touched in child mode have a defined duration and intensity? [Clarity, Spec US4 scenario 2]

## Requirement Consistency

- [ ] CHK010 Is the unlocked controls display time (10 s) the same in the spec, contract 02 and the controller? [Consistency, Spec §FR-031]
- [ ] CHK011 Are the limits (100 presets, 50 images, 2–20 steps, name 1–40) identical across spec, data-model and contracts? [Consistency]
- [ ] CHK012 Do the contracts' widget keys follow the `<screen>.<element>` pattern without collisions? [Consistency, contracts/ui/00 §6]

## Acceptance Criteria Quality

- [ ] CHK013 Do SC-001 and SC-005 define the participants' profile and the "without instructions" condition reproducibly? [Measurability, Spec §SC-001/005]
- [ ] CHK014 Does SC-003 define how the "random touches" are generated (manual vs automated, distribution)? [Measurability, Spec §SC-003]

## Scenario & Edge Case Coverage

- [ ] CHK015 Is it defined what the child sees if the timer is paused by the adult while the screen stays in child mode? [Coverage, contracts/ui/02 Special states]
- [ ] CHK016 Is there a requirement for when the chosen image has low contrast with the background (e.g., a white image on a light theme)? [Gap → addressed in contracts/ui/00 §3.2]
- [ ] CHK017 Is the behavior with two monitors and the window moved during full screen defined? [Edge Case, Spec Edge Cases]
- [ ] CHK018 Is the behavior defined when the screen reader is turned on in the middle of a countdown? [Coverage, Spec §FR-060]

## Non-Functional (Accessibility and well-being)

- [ ] CHK019 Do the requirements guarantee that no animation exceeds 3 flashes per second, including the celebration particles? [Completeness, Constitution II]
- [ ] CHK020 Is there a contrast requirement for labels over images in thumbnails and on the dial? [Gap, Spec §FR-060]
- [ ] CHK021 Is the parental gate accessible to visually impaired adults without losing effectiveness against children? [Clarity, contracts/ui/07]
- [ ] CHK022 Is it defined how the app behaves with "reduce transparency" (iOS/macOS) besides "reduce motion"? [Gap]

## Dependencies & Assumptions

- [ ] CHK023 Does the assumption that the image library covers the 6 categories with images recognizable by young children have a validation criterion (e.g., a test with children/therapists)? [Assumption, Spec §FR-020]

## Notes

- Items CHK020 and CHK022 point to remaining gaps: decide during review whether they become
  requirements (update spec/contracts) or stay explicitly out of scope. CHK004 and CHK016 were
  addressed by `/speckit-analyze` (see analysis.md F7, F8).
