# Pet Runtime Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make pet animation and action execution extensible without adding timeline logic to `PetWorldController`.

**Architecture:** Characterize current behavior first, then add a presentation-owned animation catalog, immutable action commands, a live-target runner, focused action handlers, and a deep immutable presentation snapshot. `PetWorldController` remains facade for room, target reconciliation, viewport, shared world state, and pending stimuli.

**Tech Stack:** Flutter, Dart, existing synchronous tick loop, PNG sprite assets, flutter_test.

**Spec:** `docs/superpowers/specs/2026-09-20-pet-runtime-refactor-design.md`

## Global Constraints

- Do not add Flame, `flame_behaviors`, Forge2D, Rive, Spine, or any package dependency.
- Preserve all public chat and pet APIs, including direct controller starter calls.
- Preserve exact action timing, ordering, interruption, target reconciliation, platform attachment, and bubble effects.
- Preserve controller tick order: clocks; springs; particles/prints; toy; active action or patrol; presentation notification.
- Preserve canonical migration ordering and keep pending-stimulus policy in controller.
- Keep 128x128 transparent PNG assets and nearest-neighbor rendering.
- Production-code changes use test-first red-green-refactor. Characterization tests must pass before structural edits. Generated raster assets use before/after visual evidence plus integrity tests.
- Every structural task runs `test/pet/pet_runtime_characterization_test.dart`, both world-test files, and reconciliation tests.
- No action-specific frame or trajectory branch may remain in controller after handler extraction.

---

### Task 1: Establish executable preservation characterization

**Files:**
- Create: `test/pet/pet_runtime_characterization_test.dart`
- Modify only if a testability seam is strictly required: `lib/pet/domain/pet_world_controller.dart`

**Interfaces:**
- Consumes: current public `PetWorldController` API at HEAD `9aae760`.
- Produces: preservation suite used unchanged by Tasks 4–7.

- [ ] Add controller-level tests that pass against unchanged production code.
- [ ] Cover jump completion retaining `activeTarget`, transferring it to `currentPlatform`, resetting patrol clock behavior, landing impulse `160`, and canonical migration after landing.
- [ ] Cover replacement platform impulses: chase `70`; jump/inspect/paw/probe/observe `60`.
- [ ] Cover natural completion state for chase, inspect, paw test, dog probe, parrot probe, stationary observe, and walking observe. Assert active-target retention: observe clears; jump/inspect/paw/dog/parrot/chase retain current historical behavior.
- [ ] Start chase with a nonempty payload and characterize both early-expired-toy and caught completion paths: action becomes none/idle, toy timing stays unchanged, target and original payload remain retained. Then assert replacement/reset performs cleanup.
- [ ] Start inspection with a media payload, cross `2.8s`, and assert idle/no active action while target and original payload remain retained. Then assert replacement/reset performs cleanup.
- [ ] Cover first patrol tick after every natural completion so existing `_time` reset asymmetries are recorded.
- [ ] Cover observe approach resetting its action/phase clock upon arrival before the `0.9s` observation window.
- [ ] Cover nonpositive tick, phase-boundary tick, large tick crossing both impacts, geometry changes, and target removal.
- [ ] Cover effect ordering with observable impulses/spawns only; do not assert random particle velocities.
- [ ] Run:

```bash
flutter test test/pet/pet_runtime_characterization_test.dart
flutter test test/pet/pet_world_test.dart test/pet_world_test.dart test/pet/pet_world_reconciliation_test.dart
```

Expected: all PASS before structural production edits.

- [ ] Commit:

```bash
git add test/pet/pet_runtime_characterization_test.dart
git commit -m "test(pet): characterize runtime lifecycle"
```

### Task 2: Correct corgi walk assets

**Files:**
- Replace: `assets/pets/corgi_walk_0.png`
- Replace: `assets/pets/corgi_walk_1.png`
- Replace: `assets/pets/corgi_walk_2.png`
- Replace: `assets/pets/corgi_walk_3.png`
- Modify: `test/pixel_pet_sprite_test.dart`

**Interfaces:**
- Consumes: existing asset paths and 150ms frame cadence.
- Produces: four coherent 128x128 transparent frames.

- [ ] Use `.superpowers/sdd/2026-09-20-pet-runtime-refactor/references/corgi-gait.mov` as motion reference and current corgi assets as style/identity reference.
- [ ] Capture current four-frame nearest-neighbor contact sheet as baseline evidence.
- [ ] Generate one coherent four-frame cycle: left-front/right-rear contact; passing; right-front/left-rear contact; opposite passing.
- [ ] Preserve body length, head size, palette, outline, ground line, visual mass, and canvas across frames.
- [ ] Add integrity test that decodes every image, asserts `128x128`, valid alpha, and pairwise-distinct visible RGBA data. Do not claim this proves anatomy.
- [ ] Run `flutter test test/pixel_pet_sprite_test.dart` and inspect generated contact sheet.
- [ ] Fully restart app and record one ordinary dog walk cycle. Reject foot sliding, frozen legs, stretching, head-scale drift, or idle/walk size jump.
- [ ] Commit:

```bash
git add assets/pets/corgi_walk_*.png test/pixel_pet_sprite_test.dart
git commit -m "fix(pet): correct corgi walk cycle"
```

### Task 3: Introduce exact animation mapping catalog

**Files:**
- Create: `lib/pet/presentation/pet_animation_spec.dart`
- Create: `lib/pet/presentation/pet_animation_catalog.dart`
- Modify: `lib/pet/presentation/pixel_pet.dart`
- Modify: `lib/pet/presentation/pixel_pet_sprite.dart`
- Create: `test/pet/pet_animation_catalog_test.dart`
- Modify: `test/pixel_pet_sprite_test.dart`

**Interfaces:**
- Produces: `PetAnimationSpec` and `PetAnimationCatalog.resolve(PetType, PetState)`.
- Preserves: `petAssetFor`, `corgiAssetFor`, negative/overflow index wrapping, explicit widget sizes.

- [ ] Write failing tests for every species/state mapping, non-empty immutable frames, stable key, default `64x64`, negative index, overflow index, and full `PixelPet` wrapper size behavior.
- [ ] Verify RED: `flutter test test/pet/pet_animation_catalog_test.dart test/pixel_pet_sprite_test.dart` fails because catalog types do not exist.
- [ ] Implement:

```dart
@immutable
class PetAnimationSpec {
  PetAnimationSpec({
    required this.key,
    required Iterable<String> frames,
    this.logicalSize = const Size(64, 64),
  }) : assert(frames.isNotEmpty),
       frames = List.unmodifiable(frames);

  final String key;
  final List<String> frames;
  final Size logicalSize;

  String frameAt(int index) => frames[index.abs() % frames.length];
}
```

- [ ] Catalog contains exact current mappings only. Do not add anchor, baseline, loop policy, playback clocks, or Flame adapters.
- [ ] Change `PixelPet` and `PixelPetSprite` internal constructor size to nullable. Omitted size resolves catalog `logicalSize`; explicit `64x64` and custom sizes remain authoritative.
- [ ] Keep public source compatibility and current rendering at `64x64`.
- [ ] Verify GREEN with focused tests, preservation suite, both world tests, reconciliation.
- [ ] Commit `refactor(pet): centralize animation mappings`.

### Task 4: Introduce immutable PetActionPlan at actual runtime boundary

**Files:**
- Create: `lib/pet/domain/pet_action_plan.dart`
- Modify: `lib/pet/domain/pet_world.dart`
- Modify: `lib/pet/domain/pet_behavior_executor.dart`
- Modify: `lib/pet/domain/pet_world_controller.dart`
- Create: `test/pet/pet_action_plan_test.dart`
- Modify: `test/pet/pet_behavior_executor_test.dart`

**Interfaces:**
- Produces: `PetRuntimeAction`, `PetActionPlan`, `PetBehaviorRuntime.startAction`.
- Preserves: existing public concrete controller starters as thin adapters.

- [ ] Write table-driven failing tests covering each catalog action, target kind, stimulus, emitted runtime action/options/payload, result status/reason, unsupported-capability fallback, true ignored action, wrong target, and unmeasured target.
- [ ] Assert ignored execution makes zero runtime calls and preserves active state.
- [ ] Verify RED because `PetActionPlan` and `startAction` do not exist.
- [ ] Implement command metadata only:

```dart
enum PetRuntimeAction {
  jumpToPlatform,
  chaseEmoji,
  inspectMedia,
  observeTarget,
  catPawTest,
  dogProbe,
  parrotProbe,
}

@immutable
class PetActionPlan {
  const PetActionPlan({
    required this.runtimeAction,
    required this.catalogAction,
    required this.originTargetId,
    this.payload,
    this.walkToward = false,
  });
  final PetRuntimeAction runtimeAction;
  final PetBehaviorAction catalogAction;
  final String originTargetId;
  final Object? payload;
  final bool walkToward;
}
```

- [ ] Update sole `PetBehaviorRuntime` declaration in `pet_world.dart` to `startAction`; do not create a competing interface.
- [ ] Keep capability on selection and status/reason on `PetBehaviorExecutionResult`; do not put either in plan.
- [ ] Implement controller `startAction` compatibility dispatcher. Existing public starters delegate one-way through shared private preparation without recursion or duplicate cleanup.
- [ ] Verify each executor call invokes `startAction` exactly once and all direct starter tests still compile.
- [ ] Run focused tests, preservation suite, both world tests, reconciliation.
- [ ] Commit `refactor(pet): execute immutable action plans`.

### Task 5: Extract live-target runner and explicit lifecycle

**Files:**
- Create: `lib/pet/domain/pet_action_runner.dart`
- Modify: `lib/pet/domain/pet_world_controller.dart`
- Create: `test/pet/pet_action_runner_test.dart`
- Modify: `test/pet/pet_world_reconciliation_test.dart`

**Interfaces:**
- Produces: runner-owned active plan, live target/payload compatibility bindings, total/phase elapsed, transition reason, retargeting.
- Leaves: platform attachment and pending stimuli in controller.

- [ ] Write failing tests for fresh activation, replacement, `beginPhase`, natural completion, room reset, pet switch, target removal, and retarget without elapsed reset.
- [ ] Define:

```dart
enum PetActionEndReason { completed, replaced, worldReset, petChanged, targetRemoved }

class PetActionRunner {
  PetActionPlan? get activePlan;
  PetInteractable? get target;
  Object? get payload;
  Duration get totalElapsed;
  Duration get phaseElapsed;
  void start(PetActionPlan plan, PetInteractable target);
  void advance(Duration elapsed);
  void beginPhase();
  void retarget(PetInteractable replacement);
  void end(PetActionEndReason reason);
}
```

- [ ] Runner stores no platform, pending stimulus, sprite path, chat DTO, or widget. Natural completion clears active plan/handler/clocks but uses explicit per-handler retention flags for target/payload. Replacement overwrites bindings; reset/pet change/affected removal clears them.
- [ ] Move `_activeTarget` and `_actionElapsed` ownership only after tests exist. Preserve `_time`, jump, dust, step, and paw timers in current owners until handler extraction.
- [ ] Reconciliation updates runner target after transferring bounds/spring and before notification. `originTargetId` remains unchanged.
- [ ] Preserve existing controller getters and all lifecycle asymmetries through explicit controller transition methods.
- [ ] Add active paw/probe migration test immediately before impact: new spring key receives impulse, bounds follow replacement, elapsed does not restart.
- [ ] Run runner tests, preservation suite, both world tests, reconciliation.
- [ ] Commit `refactor(pet): extract live action lifecycle`.

### Task 6: Extract timeline handlers with explicit context

**Files:**
- Create: `lib/pet/domain/actions/pet_action_context.dart`
- Create: `lib/pet/domain/actions/pet_action_handler.dart`
- Create seven focused handler files named in spec.
- Modify: `lib/pet/domain/pet_action_runner.dart`
- Modify: `lib/pet/domain/pet_world_controller.dart`
- Create: `test/pet/actions/pet_action_handlers_test.dart`
- Modify: `test/pet/pet_world_test.dart`
- Modify: `test/pet_world_test.dart`

**Interfaces:**
- Consumes: runner total/phase clocks and live target binding.
- Produces: handler frame/surface/height outputs through narrow context.

- [ ] Write failing handler API tests separate from already-green characterization tests.
- [ ] Define fresh-per-activation handler factory map with exactly one entry per `PetRuntimeAction`; constructor validation rejects missing/duplicate actions.
- [ ] Define:

```dart
enum PetActionTickResult { running, complete }

abstract interface class PetActionHandler {
  PetRuntimeAction get action;
  void start(PetActionContext context, PetActionPlan plan);
  PetActionTickResult tick(PetActionContext context, Duration elapsed);
  void cancel(PetActionContext context, PetActionEndReason reason);
}
```

- [ ] Context exposes live `target`, total/phase elapsed, previous elapsed, position/state/direction/frame setters, viewport/platform/surface reads, effect callbacks, jump surface/height output, `beginPhase`, and completion. It does not expose whole controller.
- [ ] Preserve clock advance before action tick, millisecond rounding, large-tick threshold crossing, and tick/effect ordering.
- [ ] Extract in order: observe; cat paw; dog probe; parrot probe; inspect; chase; jump.
- [ ] After each extraction run handler tests, characterization, `test/pet/pet_world_test.dart`, `test/pet_world_test.dart`, and reconciliation. Unmigrated actions stay on old path until their handler passes.
- [ ] Jump handler owns trajectory fields and publishes `currentSurfaceY` and `heightAboveSurface`. All handlers publish frame index; remove controller action-specific frame and trajectory branches only after migration completes.
- [ ] Preserve an action completing during tick from running patrol until next tick.
- [ ] Run full pet and chat-shell suites.
- [ ] Commit `refactor(pet): extract action timeline handlers`.

### Task 7: Add deep immutable presentation snapshot

**Files:**
- Create: `lib/pet/domain/pet_presentation_state.dart`
- Modify: `lib/pet/domain/pet_world_controller.dart`
- Modify: `lib/pet/presentation/pet_world_overlay.dart`
- Modify: `lib/pet/presentation/pixel_pet.dart`
- Modify: `lib/pet/presentation/pixel_pet_sprite.dart`
- Create: `test/pet/pet_presentation_state_test.dart`
- Modify: `test/chat_shell_test.dart`
- Modify: `docs/chat-pet-mvp-handoff.md`

**Interfaces:**
- Produces: controller `presentationState` deep snapshot.
- Presentation resolves animation assets; domain never imports animation catalog.

- [ ] Write failing tests for pet scalar state, shadow/surface, paw prints, both particle layers and order, toy/trail, badge, active target ID/bounds, and snapshot immutability across tick/reconciliation.
- [ ] Create immutable value snapshots for mutable particle, print, toy, trail, and target data. Use unmodifiable copied lists; never expose mutable runtime objects.
- [ ] Overlay reads one snapshot per build. Input callbacks still call controller facade.
- [ ] Keep `springNotifier` independent, `IgnorePointer` behavior unchanged, and nearest-neighbor rendering unchanged.
- [ ] Verify full `PixelPet` wrapper omitted/explicit/custom size behavior still passes.
- [ ] Update handoff with action plan, live runner, handler, animation catalog, deep snapshot, and no-Flame decision.
- [ ] Run focused tests, characterization, both world tests, reconciliation, chat shell, full suite.
- [ ] Commit `refactor(pet): separate runtime presentation state`.

### Task 8: Final app and branch gate

**Files:**
- Modify only files required by a reproduced regression, with a failing test first.

- [ ] Fully restart app; do not rely on hot reload for assets/runtime ownership.
- [ ] Verify corgi walk/idle, cat walk/paw test, parrot patrol/probe, text/image/GIF/video arrival, old/new bubble taps, scrolling/live bounds, room switch/reconnect, and pet-switch cancellation.
- [ ] Run:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
git diff --check HEAD
./scripts/commit_gate.sh
```

- [ ] Require final peer-review `APPROVE` with no unresolved Critical, High, or Medium finding.
- [ ] Record commit hashes, test count, review verdict, no-Flame status, and visual evidence in handoff.
