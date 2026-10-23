# Testability & Reliability Requirements Checklist: Visual Time Counter

**Purpose**: Test whether the reliability, privacy and testing requirements are complete and
verifiable before implementation.
**Created**: 2026-10-23
**Feature**: [spec.md](../spec.md) · [testing-strategy.md](../testing-strategy.md) · [platform-ports.md](../contracts/platform-ports.md)
**Depth**: Formal (release gate) · **Audience**: PR reviewer and QA

## Requirement Completeness

- [ ] CHK001 Does every v1.0 FR have at least one test mapped in the traceability matrix? [Coverage, testing-strategy §3]
- [ ] CHK002 Does every story have at least one E2E scenario or a justification for being covered only by integration/manual tests? [Completeness, testing-strategy §4]
- [ ] CHK003 Are the behaviors of each port per platform (supported, degraded, unsupported) specified? [Completeness, contracts/platform-ports]
- [ ] CHK004 Is it specified what happens to scheduled notifications when the app is updated (reinstall/upgrade)? [Gap → addressed in tasks T043]

## Requirement Clarity

- [ ] CHK005 Do the alarm accuracy tolerances (≤ 1 s / ≤ 5 s) define how to measure the firing instant on each platform? [Clarity, Spec §SC-002]
- [ ] CHK006 Is the performance "reference device" specified enough to be reproducible? [Clarity, research R21]
- [ ] CHK007 Does the "0 network requests" criterion define the tool, platforms and observation duration? [Clarity, Spec §SC-008]

## Requirement Consistency

- [ ] CHK008 Are the coverage thresholds the same in Constitution IV, testing-strategy §2 and `tool/check_coverage.dart` (tasks)? [Consistency]
- [ ] CHK009 Is the per-routine limit of scheduled notifications (≤ 60) consistent across research R16, platform-ports and data-model? [Consistency]

## Scenario & Edge Case Coverage

- [ ] CHK010 Are there requirements for the system clock manually moved backwards during the countdown? [Edge Case, Spec Edge Cases]
- [ ] CHK011 Is the behavior specified when storage fills up while saving the session (before scheduling)? [Exception Flow → addressed in tasks T058]
- [ ] CHK012 Is there a requirement for data migration when the user downgrades the app? [Edge Case, persistence-schema §Migrations]
- [ ] CHK013 Is the duplicate alarm behavior (app sound + OS notification at the same instant) specified per platform? [Clarity, contracts/ui/02 §Behavior 5]
- [ ] CHK014 Is rescheduling after a time zone change while the app is closed specified? [Coverage, Spec US2 scenario 8]

## Non-Functional (Privacy and licenses)

- [ ] CHK015 Does the privacy check also cover iOS/macOS/Windows/Linux/Web, and not only the Android manifest? [Coverage, research R22]
- [ ] CHK016 Do the requirements define how to validate that exported own images carry no metadata? [Gap, Spec §FR-023/FR-100]
- [ ] CHK017 Does the human asset review process (Constitution II) have a defined criterion and record? [Clarity, Gap]

## Dependencies & Assumptions

- [ ] CHK018 Do the "Verify in spike" points (Windows `zonedSchedule`, `flutter_alarmkit`, Fluent Emoji license) have explicit tasks and decision criteria? [Dependency, research R4/R9/R17]
- [ ] CHK019 Does the dependency on emulators and paid runners (macOS) in CI have a documented alternative? [Assumption, testing-strategy §4]

## Notes

- CHK016 and CHK017 are gaps to decide during review (see also `/speckit-analyze`). CHK004 and
  CHK011 were addressed by `/speckit-analyze` (analysis.md F5, F6).
