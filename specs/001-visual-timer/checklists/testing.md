# Testability & Reliability Requirements Checklist: Kid Timer

**Purpose**: Test whether the reliability, privacy and testing requirements are complete and
verifiable before implementation.
**Created**: 2026-10-23
**Feature**: [spec.md](../spec.md) · [testing-strategy.md](../testing-strategy.md) · [platform-ports.md](../contracts/platform-ports.md)
**Depth**: Formal (release gate) · **Audience**: PR reviewer and QA

## Requirement Completeness

- [x] CHK001 Does every v1.0 FR have at least one test mapped in the traceability matrix? [Coverage, testing-strategy §3]
- [x] CHK002 Does every story have at least one E2E scenario or a justification for being covered only by integration/manual tests? [Completeness, testing-strategy §4]
- [x] CHK003 Are the behaviors of each port per platform (supported, degraded, unsupported) specified? [Completeness, contracts/platform-ports]
- [x] CHK004 Is it specified what happens to scheduled notifications when the app is updated (reinstall/upgrade)? [Gap → addressed in tasks T043]

## Requirement Clarity

- [x] CHK005 Do the alarm accuracy tolerances (≤ 1 s / ≤ 5 s) define how to measure the firing instant on each platform? [Clarity, Spec §SC-002]
- [x] CHK006 Is the performance "reference device" specified enough to be reproducible? [Clarity, research R21]
- [x] CHK007 Does the "0 network requests" criterion define the tool, platforms and observation duration? [Clarity, Spec §SC-008]

## Requirement Consistency

- [x] CHK008 Are the coverage thresholds the same in Constitution IV, testing-strategy §2 and `tool/check_coverage.dart` (tasks)? [Consistency]
- [x] CHK009 Is the per-routine limit of scheduled notifications (≤ 60) consistent across research R16, platform-ports and data-model? [Consistency]

## Scenario & Edge Case Coverage

- [x] CHK010 Are there requirements for the system clock manually moved backwards during the countdown? [Edge Case, Spec Edge Cases]
- [x] CHK011 Is the behavior specified when storage fills up while saving the session (before scheduling)? [Exception Flow → addressed in tasks T058]
- [x] CHK012 Is there a requirement for data migration when the user downgrades the app? [Edge Case, persistence-schema §Migrations]
- [x] CHK013 Is the duplicate alarm behavior (app sound + OS notification at the same instant) specified per platform? [Clarity, contracts/ui/02 §Behavior 5]
- [x] CHK014 Is rescheduling after a time zone change while the app is closed specified? [Coverage, Spec US2 scenario 8]

## Non-Functional (Privacy and licenses)

- [x] CHK015 Does the privacy check also cover iOS/macOS/Windows/Linux/Web, and not only the Android manifest? [Coverage, research R22]
- [x] CHK016 Do the requirements define how to validate that exported own images carry no metadata? [Gap, Spec §FR-023/FR-100]
- [x] CHK017 Does the human asset review process (Constitution II) have a defined criterion and record? [Clarity, Gap]

## Dependencies & Assumptions

- [x] CHK018 Do the "Verify in spike" points (Windows `zonedSchedule`, `flutter_alarmkit`, Fluent Emoji license) have explicit tasks and decision criteria? [Dependency, research R4/R9/R17]
- [x] CHK019 Does the dependency on emulators and paid runners (macOS) in CI have a documented alternative? [Assumption, testing-strategy §4]

## Notes

- Evaluated 2026-10-23; every item passes after the fixes below.
- CHK001: FR-007, FR-012, FR-018, FR-026 added to the testing-strategy §3 matrix.
- CHK003: support matrix added to contracts/platform-ports.
- CHK004 / CHK011: addressed by `/speckit-analyze` (analysis.md F5, F6); data-model `start`
  rule now persists before scheduling.
- CHK005 / CHK007: measurement protocols in testing-strategy §8 (SC-002, SC-008);
  `alarm_accuracy_test` added (T080).
- CHK006: reference device class and recording rules in research R21.
- CHK008: coverage exclusions aligned between testing-strategy §2 and T014.
- CHK009: ≤ 60 pending per group added to data-model.
- CHK010: spec Edge Cases aligned with Constitution III (wall clock, `endsAt − now`).
- CHK013: per-platform single-ring rule in contracts/ui/02 Behavior 5 and research R4 (T078).
- CHK015: privacy check extended to macOS/iOS/Web/Windows/Linux (research R22, T015).
- CHK016: imported images are re-processed (FR-100, export-format rule 4, T197/T201).
- CHK017: review criteria in research R9 (T094/T095).
- CHK018: decision criteria for T042 (R4) and T194 (R17); T092 already had one.
