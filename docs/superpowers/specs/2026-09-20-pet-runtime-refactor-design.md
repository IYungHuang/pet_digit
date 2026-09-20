# Pet Runtime Refactor Design

## Objective

Restructure the current pet runtime so new species actions can be added without
expanding `PetWorldController`, while preserving every existing chat, message,
target-reconciliation, movement, animation, and interaction behavior.

Flame, `flame_behaviors`, Forge2D, skeletal animation, backend changes, and a
standalone-Dart portability rewrite are out of scope. Existing `dart:ui` geometry
and Flutter `ValueNotifier` use remain allowed at the world/presentation edge.

## Current problem

The selection boundary is already sound:

```text
PetBehaviorCatalog
  -> PetBehaviorSelector
  -> PetBehaviorExecutor
  -> PetWorldController
```

However, `PetWorldController` owns room lifecycle, target reconciliation,
behavior dispatch, action state, action timelines, movement, bubble physics,
particles, footsteps, animation timing, and patrol. It is over 1,200 lines.
Adding one visual behavior requires editing the same central class and parallel
action/frame switches.

Animation metadata is split between controller timing and hard-coded asset
switches. The current corgi walk also has four files but only two readable limb
poses, so correct playback still produces an incorrect gait.

## Preservation-first sequence

Before moving state, add controller-level characterization tests that run
against the current implementation. They define action phase boundaries,
completion asymmetries, interruption cleanup, clock behavior, canonical target
migration, effect ordering, and patrol resumption. Structural tasks must keep
this suite green.

Generated raster assets use visual before/after evidence plus integrity tests;
semantic gait quality is not represented as a unit-test claim.

## Required boundaries

### Behavior decision

Keep these pure and renderer-independent:

- `PetBehaviorCatalog`
- `PetBehaviorTriggerMatcher`
- `PetBehaviorSelector`
- `PetBehaviorNormalizer`

They answer which behavior is eligible. They never own sprites, clocks, Flutter
widgets, target geometry, or runtime mutation.

### Action command

`PetBehaviorExecutor` converts an executable `PetBehaviorSelection` into one
immutable `PetActionPlan`. The plan is command metadata, not live world state:

- runtime action kind;
- selected catalog action;
- immutable origin target ID for audit/debugging;
- payload when required;
- options such as `walkToward`.

Capability remains selection metadata. Execution status and reason remain in
`PetBehaviorExecutionResult`. An unsupported catalog capability may still map
to a safe fallback; only actions without a safe mapping are ignored.

Executor calls one interface method declared in `pet_world.dart`:

```dart
void startAction(PetActionPlan plan, PetInteractable target);
```

Existing public controller starters remain thin compatibility adapters during
migration because tests and callers use them directly. They delegate one-way to
the same start path without repeated cleanup.

### Live target binding

`PetActionPlan.originTargetId` never changes and is never used to resolve live
geometry after start. `PetActionRunner` owns a mutable live target binding.
Handlers read `context.target`, which always returns that binding.

Canonical client-ID to server-ID migration remains owned by the controller:

1. match stable `(roomId, clientId)` source identity;
2. transfer measured bounds and spring state;
3. update controller object collections and runner binding;
4. refresh active/platform geometry;
5. notify spring/presentation observers.

Retargeting does not restart action or phase elapsed time. Impacts after
migration use the replacement target ID and spring key. Pending-stimulus policy,
cross-room rejection, and removal remain controller concerns.

### Runner, handler, and state contract

`PetActionRunner` owns:

- active immutable plan;
- live target binding;
- compatibility payload binding;
- active handler instance;
- total action elapsed time;
- current phase elapsed time;
- natural completion, replacement cancellation, reset cancellation, and target
  removal transitions.

Handler instances are fresh for every activation. Runner advances total and
phase clocks before calling `tick`, preserving current elapsed-before-action
semantics. Durations remain integer-millisecond boundary comparisons where the
current implementation uses millisecond quantization. A handler explicitly
calls `beginPhase()` to reset phase elapsed without resetting total elapsed.

`PetActionContext` provides narrow synchronous access to:

- mutable position, state, direction, and frame index;
- live target, viewport, current platform, and surface geometry;
- current total/phase elapsed values;
- bubble impulse, spring lookup, toy, particle, trail, and footstep operations;
- jump surface and airborne-height output;
- completion result.

It does not expose chat DTOs, Riverpod, widgets, Firebase, repositories, or the
whole controller.

Every handler publishes frame index through context. Jump handler publishes
surface Y and height above surface, allowing shadow and footstep consumers to
remain action-agnostic. No action-specific frame or trajectory branch remains
in controller after extraction.

Controller tick order stays:

1. advance patrol/global clock and runner action clocks;
2. update springs;
3. age particles and paw prints;
4. update/remove bouncing toy;
5. tick active handler, or patrol when no active action existed at tick start;
6. notify presentation.

An action completing during step 5 does not run patrol until next tick.

### Clock ownership

| Clock | Owner after refactor | Preservation rule |
|---|---|---|
| patrol/global `_time` | world controller | Advances every positive tick; action-specific resets remain explicit transition effects. |
| total action elapsed | action runner | Reset on start; advances before handler tick. |
| phase elapsed | action runner | Reset only by handler `beginPhase()`; supports observe approach-to-pause transition. |
| jump trajectory | jump handler | Publishes surface/height; preserves current formulas and completion timing. |
| dust/step/paw timers | context effect state | Reset only where current starters reset them; same emission order and thresholds. |

Nonpositive ticks retain current behavior. Large ticks may cross multiple
one-shot thresholds; handlers preserve all impacts through explicit previous
and current elapsed checks.

### Lifecycle transition contract

Platform attachment is independent world state; it is not the runner's active
target after every action.

Natural completion clears active plan/handler/clocks but does not universally
clear target or payload bindings. Controller compatibility getters read runner
bindings after completion. Each handler supplies explicit completion retention
flags. Replacement overwrites bindings; world reset, pet switch, and affected
target removal clear them. This preserves observable facade state without an
event-history subsystem.

| Transition | Live action target | Platform | Payload/toy | Clock/effect rule |
|---|---|---|---|---|
| jump natural completion | retained as landed target | transfer target to `currentPlatform` | clear action payload | reset patrol clock; landing impulse preserved |
| chase natural completion | retain target | none | retain supplied payload; toy removal follows current update/caught paths | reset patrol clock to 0 |
| inspect natural completion | retain target | none | retain supplied payload | reset patrol clock to 0 |
| stationary observe completion | clear action target | none | clear payload | reset phase as characterized |
| cat paw natural completion | retain target | none | retain null payload assigned at start | preserve two impacts; reset patrol clock to 0 |
| dog/parrot probe completion | retain target | none | retain null payload assigned at start | do not reset patrol clock |
| replacement by chase | cancel active action | release platform if present | clear incompatible toy/payload | platform impulse 70; then start replacement once |
| replacement by other action | cancel active action | release platform if present | clear incompatible toy/payload | platform impulse 60; then start replacement once |
| room reset / pet switch | clear runner and target | clear without replacement semantics | clear toy/payload/pending | reset world state through existing reset path |
| target removal/kind change | cancel affected action | detach if affected | clear dependent payload/toy | preserve unrelated active action and pending policy |

Exact retain/clear and clock values marked “as characterized” must be recorded
by the preservation suite before extraction; implementation must not normalize
historical asymmetries.

### Action handlers

Per-action handlers own timeline formulas:

```text
actions/
  jump_to_platform_action.dart
  chase_emoji_action.dart
  inspect_media_action.dart
  observe_target_action.dart
  cat_paw_test_action.dart
  dog_probe_action.dart
  parrot_probe_action.dart
```

A fixed map contains exactly one handler factory per `PetRuntimeAction`. No
plugin discovery or engine adapter is introduced.

### World controller

`PetWorldController` remains facade consumed by Flutter. It owns:

- room and canonical message targets;
- measured-bounds reconciliation;
- selected species and viewport;
- platform attachment and shared world/effect state;
- stimulus dispatch and pending retry;
- runner lifecycle integration;
- synchronous projection to presentation.

It does not contain per-action timeline/frame/trajectory switches after
migration.

### Animation catalog

Presentation owns `PetAnimationSpec` and `PetAnimationCatalog`. For this
milestone specs contain only metadata with an active consumer:

- stable key;
- immutable, non-empty ordered frame paths;
- fixed logical render size used when caller omits a size.

Loop policy remains runtime/handler behavior and is not duplicated in catalog.
Ground baseline and anchor are deferred until coordinate conversion has an
actual consumer; current top-left position and 52-pixel feet offset remain
unchanged.

`PixelPet` and `PixelPetSprite` use nullable size parameters internally so an
omitted size can resolve catalog logical size while explicit `64x64` and custom
sizes remain authoritative. Existing constructors remain source compatible.
Current catalog entries all resolve to `64x64`.

Existing `petAssetFor` and `corgiAssetFor` remain compatibility facades. Their
negative and overflow index wrapping remains unchanged.

### Presentation projection

Domain/controller projection never imports animation catalog or resolves asset
paths. `PetPresentationState` is a deep immutable snapshot containing scalar
render values and copied immutable snapshots for:

- pet type, state, position, direction, frame index;
- shadow/surface values;
- paw prints;
- main and signature particles in rendering order;
- bouncing toy position, rotation, emoji, and trail values;
- action badge state and active target ID/bounds when required.

Holding a prior projection across a controller tick or target reconciliation
must not mutate it. `springNotifier` remains independent because chat bubble
physics uses it outside overlay rebuilds. `IgnorePointer`, nearest-neighbor
filtering, and existing input routing remain unchanged.

## Data flow

```text
message delta / user tap
  -> PetBehaviorStimulus
  -> PetBehaviorSelector
  -> PetBehaviorExecutor
  -> PetActionPlan (immutable origin metadata)
  -> PetWorldController.startAction
  -> PetActionRunner (live target + clocks)
  -> PetActionHandler
  -> shared world/effect state
  -> PetPresentationState snapshot
  -> presentation animation catalog
  -> PixelPetSprite
```

## Compatibility contract

The refactor must preserve:

- all existing `PetWorldController` public APIs used by chat and tests;
- canonical target reconciliation, atomic notification, and pending retry;
- current priority and interruption policy;
- action durations, paths, frame boundaries, impulses, and completion states;
- action/platform target retention asymmetries;
- tick/effect/patrol ordering and clock resets;
- message arrival deduplication and species switching;
- `PetState`, `PetActionType`, asset paths, widget semantics, and
  `springNotifier` behavior;
- both `test/pet/pet_world_test.dart` and `test/pet_world_test.dart`;
- all 179 baseline tests.

No package dependency may be added.

## Corgi walk acceptance criteria

Reference: `.superpowers/sdd/2026-09-20-pet-runtime-refactor/references/corgi-gait.mov`, 5.05 seconds. It demonstrates alternating diagonal limb contact and passing phases; it is motion reference, not style reference.

- Four 128x128 transparent PNG frames.
- Four readable contact/passing poses.
- Diagonal limb pairs alternate through cycle.
- Body length, head scale, ground baseline, palette, outline, and visual mass
  remain consistent with corgi idle/run assets.
- Existing 150 ms cadence remains unchanged initially.
- Automated tests verify dimensions, asset mapping, immutable catalog entries,
  and distinct decoded visible frames.
- App verification confirms no foot sliding, frozen leg, body stretching, or
  idle/walk size jump.

Asset correction is independent from runner extraction but must complete before
final visual acceptance.

## Migration strategy

Move one ownership boundary at a time. Production-code tasks use failing tests
first. Characterization tests pass against unchanged code before structural
edits. Generated raster work uses visual evidence plus post-generation integrity
tests. Every structural task runs characterization, both world-test files, and
reconciliation tests before proceeding.

## Completion criteria

- Preservation suite documents existing lifecycle, clocks, retargeting, and
  effect ordering.
- Corgi walk has four correct visual frames.
- Animation mapping is data-driven without speculative metadata.
- Executor emits one `PetActionPlan` through actual runtime interface.
- Runner owns active plan, live target, and action clocks.
- Per-action timelines, frames, and trajectory branches no longer live in
  controller.
- Presentation state is renderer-neutral and deeply immutable.
- No Flame dependency exists.
- Full analyze, test, diff, peer-review, and commit gates pass.
