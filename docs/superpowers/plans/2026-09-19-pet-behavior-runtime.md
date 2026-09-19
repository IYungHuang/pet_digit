# Pet Behavior Runtime Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 將既有 `PetBehaviorCatalog` 接入寵物 runtime，保留 user tap 相容行為，並讓 novel-object behavior 以物種與 target capability 安全執行或明確 fallback。

**Architecture:** 以 `PetMessageTargetFactory` 統一兩套 message model，產生帶 canonical identity、normalized content、payload、bounds readiness 的 runtime target。`PetBehaviorSelector` 只做純選擇；`PetBehaviorExecutor` 負責 action capability、fallback 與既有 `PetWorldController` transition。

**Tech Stack:** Flutter / Dart、Riverpod 現有架構、Freezed message models、Flutter test。禁止新增 package、backend 修改與新動畫素材。

**Spec:** `docs/superpowers/specs/2026-09-19-pet-behavior-runtime-design.md`

## Global Constraints

- `userTap` 與 `newMessageBubble` 必須分離。
- user tap legacy compatibility：text → jump、emoji → chase/pounce、media → inspect。
- 所有 message target 必須經由單一 factory 與 canonical identity `serverId ?? clientId`。
- executor 不得從具體 target class 猜 message payload。
- bounds 未 ready 最多 pending retry 一次，且由 `updateObjectBounds()` 觸發。
- `native`、`degraded`、`unsupported` 是 catalog capability；`executed`、`fallback`、`ignored` 是 execution result。
- unsupported action 不得誤映射成其他物種或其他 target 的動作。
- backend repository 不得修改。

---

### Task 1: Define behavior runtime value objects and catalog metadata

**Files:**
- Create: `lib/pet/domain/pet_behavior_runtime.dart`
- Create: `lib/pet/domain/pet_message_content_kind.dart`
- Modify: `lib/pet/domain/pet_behavior_catalog.dart`
- Test: `test/pet/pet_behavior_runtime_test.dart`

**Interfaces:**
- Produces `PetNormalizedContentKind { text, emoji, image, gif, video }`.
- Produces `PetBehaviorCapability { native, degraded, unsupported }`.
- Produces `PetBehaviorExecutionStatus { executed, fallback, ignored }`.
- Produces immutable `PetBehaviorStimulus` with `stimulusType`, `petType`, `targetId`, `targetKind`, `contentKind`, and `payload`.
- Produces immutable `PetBehaviorSelection` with `action`, `targetId`, `capability`, and `reason`.
- Extends catalog definitions with supported stimulus types, content kinds, target kinds, and capability.

- [ ] **Step 1: Write failing value-object tests**

```dart
test('selection separates catalog capability from execution status', () {
  const selection = PetBehaviorSelection(
    action: PetBehaviorAction.sniffBubble,
    targetId: 'm1',
    capability: PetBehaviorCapability.degraded,
    reason: 'observe fallback',
  );

  expect(selection.capability, PetBehaviorCapability.degraded);
});
```

- [ ] **Step 2: Run focused test and verify failure**

Run: `flutter test test/pet/pet_behavior_runtime_test.dart`

Expected: FAIL because runtime value objects do not exist.

- [ ] **Step 3: Implement value objects and metadata**

Keep them immutable and dependency-free. Add `userTap` to `PetStimulusType`. Do not make selector depend on Flutter widgets.

- [ ] **Step 4: Run focused test**

Run: `flutter test test/pet/pet_behavior_runtime_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit checkpoint**

```bash
git add lib/pet/domain/pet_behavior_runtime.dart lib/pet/domain/pet_message_content_kind.dart lib/pet/domain/pet_behavior_catalog.dart test/pet/pet_behavior_runtime_test.dart
git commit -m "feat: define pet behavior runtime contracts"
```

### Task 2: Build normalized message target factory

**Files:**
- Create: `lib/pet/domain/pet_message_target.dart`
- Create: `lib/pet/domain/pet_message_target_factory.dart`
- Modify: `lib/pet/domain/pet_message_bubble.dart`
- Modify: `lib/pet/domain/pet_world.dart`
- Test: `test/pet/pet_message_target_factory_test.dart`

**Interfaces:**
- `PetMessageTargetData` exposes `id`, `kind`, `contentKind`, `payload`, `messageText`, `bounds`, and `hasMeasuredBounds`.
- `PetMessageTargetFactory.fromDomainMessage(domain.ChatMessage message)` returns `PetMessageTarget` with `serverId ?? clientId`.
- `PetMessageTargetFactory.fromLegacyMessage(chat_models.ChatMessage message)` returns the same target contract using legacy stable id.
- `PetMessageTarget.markMeasuredBounds(Rect bounds)` updates bounds and readiness.

- [ ] **Step 1: Write failing factory tests**

```dart
test('domain message uses server id as canonical target id', () {
  final target = PetMessageTargetFactory.fromDomainMessage(message);
  expect(target.id, 'server-1');
  expect(target.hasMeasuredBounds, isFalse);
});

test('emoji and media normalize to distinct content kinds', () {
  expect(emojiTarget.contentKind, PetNormalizedContentKind.emoji);
  expect(imageTarget.contentKind, PetNormalizedContentKind.image);
  expect(gifTarget.contentKind, PetNormalizedContentKind.gif);
});
```

- [ ] **Step 2: Run focused test and verify failure**

Run: `flutter test test/pet/pet_message_target_factory_test.dart`

Expected: FAIL because factory and unified target do not exist.

- [ ] **Step 3: Implement factory and target**

Use one runtime target implementation. Keep existing `PetMessageBubbleTarget` only as compatibility surface if needed; it must delegate identity, content kind, payload, and readiness to the unified target instead of maintaining another identity path. Do not use placeholder Rect as measured bounds.

- [ ] **Step 4: Run focused tests**

Run: `flutter test test/pet/pet_message_target_factory_test.dart test/pet/pet_world_test.dart`

Expected: PASS, with no regression in existing world tests.

- [ ] **Step 5: Commit checkpoint**

```bash
git add lib/pet/domain/pet_message_target.dart lib/pet/domain/pet_message_target_factory.dart lib/pet/domain/pet_message_bubble.dart lib/pet/domain/pet_world.dart test/pet/pet_message_target_factory_test.dart
git commit -m "feat: unify pet message runtime targets"
```

### Task 3: Implement pure selector and stimulus normalization

**Files:**
- Create: `lib/pet/domain/pet_behavior_selector.dart`
- Create: `lib/pet/domain/pet_behavior_normalizer.dart`
- Modify: `lib/pet/domain/pet_behavior_catalog.dart`
- Test: `test/pet/pet_behavior_selector_test.dart`

**Interfaces:**
- `PetBehaviorNormalizer.fromTarget(PetMessageTarget target, PetStimulusType stimulusType)` returns `PetBehaviorStimulus`.
- `PetBehaviorSelector.select(PetBehaviorStimulus stimulus)` returns `PetBehaviorSelection?`.
- Selector filters by species, stimulus, normalized content kind, target kind, metadata capability, and profile source precedence.

- [ ] **Step 1: Write failing selector matrix tests**

Cover:

```dart
test('user tap text selects legacy platform action', () { /* expect jump-compatible action */ });
test('user tap emoji selects emoji-compatible action', () { /* expect chase/pounce-compatible action */ });
test('user tap media selects inspect-compatible action', () { /* expect inspect-compatible action */ });
test('same new-message stimulus selects species-specific candidates', () { /* corgi != cat != parrot */ });
test('wrong target kind returns no candidate', () { /* no jump on animatedToy */ });
```

- [ ] **Step 2: Run focused tests and verify failure**

Run: `flutter test test/pet/pet_behavior_selector_test.dart`

Expected: FAIL because selector and normalized trigger metadata do not exist.

- [ ] **Step 3: Implement metadata-driven selector**

Use deterministic ordering for equal priority. `userTap` reads only legacy-compatible triggers; `newMessageBubble` reads only novel-object-compatible triggers. Ordinary care/locomotion actions remain excluded unless metadata explicitly opts them in.

- [ ] **Step 4: Run selector tests**

Run: `flutter test test/pet/pet_behavior_selector_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit checkpoint**

```bash
git add lib/pet/domain/pet_behavior_selector.dart lib/pet/domain/pet_behavior_normalizer.dart lib/pet/domain/pet_behavior_catalog.dart test/pet/pet_behavior_selector_test.dart
git commit -m "feat: select pet behaviors by stimulus and target"
```

### Task 4: Implement payload-aware executor and preserve legacy tap runtime

**Files:**
- Create: `lib/pet/domain/pet_behavior_executor.dart`
- Modify: `lib/pet/domain/pet_world_controller.dart`
- Modify: `lib/pet/domain/pet_world.dart`
- Test: `test/pet/pet_behavior_executor_test.dart`
- Test: `test/pet/pet_world_test.dart`

**Interfaces:**
- `PetBehaviorExecutor.execute(PetBehaviorSelection selection, PetMessageTarget target)` returns `PetBehaviorExecutionResult`.
- `PetWorldController.dispatch(PetBehaviorStimulus stimulus)` returns `PetBehaviorExecutionResult`.
- `PetWorldController.interact(String objectId)` creates `userTap` stimulus and delegates to `dispatch()`.

- [ ] **Step 1: Write failing executor tests**

```dart
test('platform user tap starts jump runtime', () { /* currentAction jumpToPlatform */ });
test('emoji user tap passes normalized payload to chase runtime', () { /* no class-based text guess */ });
test('media user tap starts inspect runtime', () { /* currentAction inspectGif */ });
test('unsupported action returns fallback without fake motion', () { /* status fallback/ignored */ });
```

- [ ] **Step 2: Run focused tests and verify failure**

Run: `flutter test test/pet/pet_behavior_executor_test.dart test/pet/pet_world_test.dart`

Expected: FAIL because controller has no dispatch contract and runtime still guesses target class payload.

- [ ] **Step 3: Implement executor adapter**

Preserve existing jump, chase, and inspect internals. Pass target payload explicitly into chase/inspect entry points. Unsupported `flyBack`, `beakProbe`, `beakManipulate`, and `hidePeek` must return explicit fallback or ignored result; never map `flyBack` to walk.

- [ ] **Step 4: Implement complete fallback transition**

When fallback executes, set action, active target, timer, and state consistently. When ignored, do not mutate active runtime state.

- [ ] **Step 5: Run focused tests**

Run: `flutter test test/pet/pet_behavior_executor_test.dart test/pet/pet_world_test.dart`

Expected: PASS, including existing interaction regression tests.

- [ ] **Step 6: Commit checkpoint**

```bash
git add lib/pet/domain/pet_behavior_executor.dart lib/pet/domain/pet_world_controller.dart lib/pet/domain/pet_world.dart test/pet/pet_behavior_executor_test.dart test/pet/pet_world_test.dart
git commit -m "feat: execute catalog behaviors through pet world"
```

### Task 5: Migrate controller targets and implement bounds/id reconciliation

**Files:**
- Modify: `lib/pet/domain/pet_world_controller.dart`
- Modify: `lib/pet/domain/pet_message_target.dart`
- Modify: `lib/pet/domain/pet_message_target_factory.dart`
- Test: `test/pet/pet_world_reconciliation_test.dart`

**Interfaces:**
- `setMessageTargets(Iterable<PetMessageTarget> targets)` replaces parallel target construction.
- `updateObjectBounds(Map<String, Rect> boundsMap)` marks targets measured and retries one pending stimulus.
- reconciliation keeps active target, `currentPlatform`, bounds, and bubble spring keyed by canonical id.

- [ ] **Step 1: Write failing reconciliation tests**

```dart
test('all message models use one target collection', () { /* no parallel MessageWorldObject path */ });
test('bounds update retries pending stimulus once', () { /* second dispatch not repeated */ });
test('removed target cancels active action', () { /* returns idle */ });
test('canonical id reconciliation preserves active target', () { /* serverId transition atomic */ });
```

- [ ] **Step 2: Run focused tests and verify failure**

Run: `flutter test test/pet/pet_world_reconciliation_test.dart`

Expected: FAIL while controller maintains separate target paths and default bounds.

- [ ] **Step 3: Migrate `loadRoom()` and `setMessageBubbleTargets()`**

Both paths must call `PetMessageTargetFactory`; controller stores one target collection. Preserve existing UI-facing method as adapter if callers still use it.

- [ ] **Step 4: Implement readiness and one-shot retry**

`updateObjectBounds()` marks measured bounds, verifies target id/species/action still valid, retries at most once, then clears pending stimulus.

- [ ] **Step 5: Run reconciliation tests**

Run: `flutter test test/pet/pet_world_reconciliation_test.dart test/pet/pet_world_test.dart`

Expected: PASS.

- [ ] **Step 6: Commit checkpoint**

```bash
git add lib/pet/domain/pet_world_controller.dart lib/pet/domain/pet_message_target.dart lib/pet/domain/pet_message_target_factory.dart test/pet/pet_world_reconciliation_test.dart
git commit -m "refactor: reconcile pet targets by canonical identity"
```

### Task 6: Integrate new-message behaviors and run full verification

**Files:**
- Modify: `lib/pet/domain/pet_world_controller.dart`
- Modify: `lib/pet/domain/pet_behavior_catalog.dart`
- Modify: `docs/chat-pet-mvp-handoff.md`
- Test: `test/pet/pet_behavior_integration_test.dart`

- [ ] **Step 1: Write failing integration tests**

```dart
test('new message stimulus can select species-specific novel-object action', () { /* corgi/cat/parrot differ */ });
test('unsupported novel-object action does not replace user tap compatibility', () { /* tap still jumps/chases/inspects */ });
test('every message target can dispatch independently', () { /* distinct canonical ids */ });
```

- [ ] **Step 2: Run focused integration tests and verify failure**

Run: `flutter test test/pet/pet_behavior_integration_test.dart`

Expected: FAIL until controller dispatches normalized new-message stimulus.

- [ ] **Step 3: Wire new-message dispatch**

Dispatch only after target exists. Use species profile and metadata selector. Unsupported approach actions return explicit ignored/fallback and do not mutate current tap action.

- [ ] **Step 4: Update handoff documentation**

Document runtime boundaries, native/degraded/unsupported status, target factory, canonical identity, one-shot bounds retry, and current unsupported animation actions.

- [ ] **Step 5: Run full verification**

Run:

```bash
flutter analyze
flutter test
git diff --check
```

Expected: all pass; backend repo unchanged.

- [ ] **Step 6: Commit final implementation**

```bash
git add lib/pet test/pet docs/chat-pet-mvp-handoff.md
git commit -m "feat: connect pet behavior catalog to runtime"
```
