# Task 4 Report: Payload-Aware Executor and Legacy Tap Runtime

## Delivered

- Added `PetBehaviorExecutor`, `PetBehaviorExecutionResult`, and runtime command port.
- `PetWorldController.dispatch()` resolves selector output and returns explicit execution results.
- `interact(String)` now normalizes a `userTap` stimulus and delegates to `dispatch()`.
- Replaced `MessageWorldObject` payload branching inside chase runtime with explicit normalized payload.
- Preserved legacy text jump, emoji chase/pounce, and media inspect behavior.
- Added explicit ignored outcomes for missing selection, unavailable target, unready bounds, `flyBack`, and unsupported approach actions. Ignored paths do not start a runtime sequence.
- Added explicit fallbacks for approved degraded mappings, including circle-sniff walk/observe and observe-only non-equivalent actions.
- Kept legacy target conversion adapter in controller. Task 5 target collection migration, reconciliation, and retry remain out of scope.

## TDD Evidence

RED:

```text
flutter test test/pet/pet_behavior_executor_test.dart test/pet/pet_world_test.dart
FAILED: pet_behavior_executor.dart missing; executor, dispatch, activeTarget, and observeTarget contracts absent.
```

GREEN focused executor/controller tests:

```text
flutter test test/pet/pet_behavior_executor_test.dart test/pet/pet_world_test.dart
PASS: 9 tests.
```

Focused runtime regression tests:

```text
flutter test test/pet/pet_behavior_executor_test.dart test/pet/pet_world_test.dart test/pet_world_test.dart test/pet_message_bubble_test.dart test/pet/pet_behavior_runtime_test.dart test/pet/pet_behavior_selector_test.dart
PASS: 37 tests.
```

## Verification

```text
flutter analyze
PASS: No issues found.

flutter test
PASS: 115 tests.

git diff --check
PASS.
```

## Review

Self-review found no unresolved Task 4 defects. No subagents used. No packages, assets, or backend files changed.

## Fix Round 1/5

### Root Cause

- Dispatch-created target copies became action-owned targets. Collection bounds updates therefore missed landed and inspected runtime targets.
- New observe/circle actions reset action timing but retained `currentPlatform` and `bouncingToy` from interrupted actions.

### TDD Evidence

RED:

```text
flutter test test/pet/pet_behavior_executor_test.dart test/pet/pet_world_test.dart
FAILED: live platform identity detached after dispatch; fallback observe retained currentPlatform; circle fallback retained BouncingEmojiToy.
```

GREEN:

```text
flutter test test/pet/pet_behavior_executor_test.dart test/pet/pet_world_test.dart
PASS: 12 tests.
```

### Verification

```text
flutter analyze
PASS: No issues found.

git diff --check
PASS.
```

### Scope

- Runtime resolves the collection object by target ID before ownership transfers, retaining live geometry without collection migration.
- Every executed or fallback runtime start now clears previous platform and chase artifacts before entering its new action.
- Task 5 reconciliation/pending retry and deferred Minor unready-ID finding remain unchanged.
