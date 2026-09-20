# Task 6 report — action timeline handlers

Base: `e00f221549058e3d0fa25f9ed21a20a8ddc84153`

## TDD

- RED: `flutter test test/pet/actions/pet_action_handlers_test.dart` failed to compile because `PetActionContext`, `PetActionHandler`, registry injection, and `createHandler` did not exist.
- GREEN: same command passed 3 tests covering complete registry, missing-action rejection, duplicate-action rejection, and fresh instances.
- Regression RED during integration: structural gate failed surface projection (`expected 202.9316252256174`, actual `200.0`) after jump landing.
- Regression GREEN: completion clears airborne surface output so landed platform deflection becomes live again; structural gate passed 91 tests.
- Peer-review RED: loading another room during a jump retained airborne surface/height (`74.6` height after reset).
- Peer-review GREEN: room load now clears handler projection output; focused regression passes.

## Ordered extraction gates

Each row used:

`flutter test test/pet/actions/pet_action_handlers_test.dart test/pet/pet_runtime_characterization_test.dart test/pet/pet_world_test.dart test/pet_world_test.dart test/pet/pet_world_reconciliation_test.dart`

| Step | Result |
|---|---:|
| observe | PASS, 91 |
| cat paw | PASS, 91 |
| dog probe | PASS, 91 |
| parrot probe | PASS, 91 |
| inspect | PASS, 91 |
| chase | PASS, 91 |
| jump | PASS, 91 |

Handlers receive only `PetActionContext`. Runner validates exactly one factory per runtime action and creates fresh handler per activation. Clock advance remains before handler tick with integer-millisecond elapsed. Jump owns and publishes trajectory surface/height. Every handler publishes frame index. Controller runs patrol only when tick began without active action.

## Suites

- Baseline structural suite: PASS, 89.
- Full pet suite (`flutter test test/pet test/pet_world_test.dart`): PASS, 243.
- Chat-shell (`flutter test test/chat_shell_test.dart`): PASS, 20.
- `flutter analyze`: PASS, no issues.
- `git diff --check`: PASS.

No Flame dependency or presentation snapshot added. No push performed.
