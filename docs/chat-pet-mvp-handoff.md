# Chat Pet MVP Handoff Report

## Pet runtime architecture update — 2026-09-20

Pet runtime now separates decision, execution, lifecycle, action timelines, and
render projection:

```text
PetBehaviorCatalog / Selector
  -> immutable PetActionPlan
  -> PetActionRunner (live target, clocks, lifecycle)
  -> fresh action handler (timeline and effects)
  -> PetPresentationState (deep immutable render snapshot)
  -> PetWorldOverlay / PetAnimationCatalog
```

- `PetActionPlan` keeps immutable origin metadata. `PetActionRunner` owns live
  canonical target/payload bindings, elapsed clocks, replacement/cancellation,
  and natural-completion retention rules.
- Seven focused handlers own jump, chase, inspect, observe, cat paw, dog probe,
  and parrot probe timelines. `PetWorldController` remains room/reconciliation,
  shared-world, pending-stimulus, and callback facade.
- `PetAnimationCatalog` is presentation-owned and centralizes exact species and
  state frame mappings. Domain code does not import it or resolve asset paths.
- `PetPresentationState` copies pet scalars, surface/shadow inputs, ordered paw
  prints, ground/signature particles, bouncing toy values, and active target
  identity/bounds into unmodifiable value snapshots. Overlay reads one snapshot
  per build; previous snapshots cannot change after ticks or reconciliation.
- Bubble `springNotifier` remains independent. Overlay still uses
  `IgnorePointer`, nearest-neighbor sprite rendering, and controller callbacks.
  Omitted, explicit 64x64, and custom `PixelPet` sizes retain prior behavior.

Flame, `flame_behaviors`, Forge2D, Rive, and Spine remain intentionally absent.
Current synchronous Flutter runtime is preserved; engine adoption requires a
separate measured migration proposal.

## Runtime integration update — 2026-09-19

This section is the current pet runtime handoff. The original 2026-09-18 report below is retained as historical context; its test count, fixed-coordinate limitations, and proposed implementation phases are not the current runtime status.

### Runtime boundary

`PetMessageTargetFactory` adapts both Freezed chat messages and legacy demo messages into one `PetMessageTarget` collection. Text becomes a platform, emoji-only text becomes an emoji toy, and image/GIF/video becomes an animated target. Normalized content and payload travel with the target; the executor never guesses payload from a concrete message class.

`PetBehaviorNormalizer` creates an explicit `PetBehaviorStimulus`. The pure `PetBehaviorSelector` filters species profiles and trigger metadata by stimulus, content, and target kind, using catalog order to break priority ties. `PetBehaviorExecutor` then invokes controller transitions. `PetActionType` owns jump, chase, inspect, observe, cat paw-probe, dog nose-probe, and parrot beak-probe sequences; catalog names and animation keys alone do not create visual animations.

Catalog capability (`native`, `degraded`, `unsupported`) and execution outcome (`executed`, `fallback`, `ignored`) are separate contracts:

| Input / species | Catalog action | Capability | Current runtime outcome |
| --- | --- | --- | --- |
| Text tap / corgi | `nosePawBump` | native for platform + userTap | `executed`: platform jump |
| Text tap / cat, parrot | `headBuntRub`, `beakTouch` | degraded | `fallback`: platform jump |
| Emoji tap / corgi, cat | `runChase`, `pounce` | native | `executed`: payload-aware emoji chase |
| Emoji tap / parrot | `flyFlap` | degraded | `fallback`: emoji chase; no flight animation |
| Media tap / corgi | `sniffBubble` | degraded | `fallback`: legacy GIF inspect sequence |
| Media tap / cat | `sniffWhiskerScan` | degraded | `fallback`: legacy GIF inspect sequence |
| Media tap / parrot | `headTiltEyeFocus` | degraded | `fallback`: existing inspect/observe sequence |
| New text / corgi, cat, parrot | `approachArc`, `approachLowSilent`, `approachSideways` | degraded | `fallback`: light walk-toward observation |
| New media / corgi | `novelObjectNoseProbe` | native | `executed`: dog novel-object probe |
| New media / cat | `pawTest` | native | `executed`: cat novel-object probe |
| New media / parrot | `beakProbe` | native | `executed`: side-step, monocular inspection, beak touch |
| New emoji / any species | No matching new-message candidate | — | `ignored`: no selection; never treated as a tap |

`approachStopStart` follows `approachArc` at equal priority and shares the light-approach fallback. `flyBack` is ignored, never substituted with walking. `hidePeek` and `beakManipulate` remain observation fallbacks without native animation. Novel-object actions are arrival-only, so they do not replace established media-tap behavior. Other unenabled catalog actions remain outside automatic message selection.

Native novel-object sequences use dedicated generated sprite assets: four cat low-stalk frames, six corgi sniff/nose-probe frames, six parrot side-step/eye-focus/beak-probe frames, plus six cat paw-probe frames. Cat motion uses eased two-stage stalking with a full stop; dog approach follows an arc; parrot approaches by side-step. Probe impacts drive the existing bubble spring.

### Identity, geometry, and bounded retry

- Canonical domain target ID is `serverId ?? clientId`; legacy targets use their stable message ID. Each message dispatches independently, even when content is identical.
- Stable domain source identity is `(roomId, clientId)`. Source identity preserves ownership across acknowledgement; canonical identity keys layout bounds and bubble springs. Reconciliation transfers the active target, landed platform, measured bounds, spring, and pending stimulus to the live canonical target.
- Dispatch rejects stale species, source identity, content kind, target kind, or payload. Room changes cannot reuse a stale message event from another room.
- Geometry is measured from message widgets. An initial zero rectangle is not ready geometry. Layout updates also refresh airborne landing coordinates and landed platform position.
- An unmeasured selected target returns `ignored`. With no running action, only one pending stimulus is retained; the latest eligible event replaces that slot. There is no event queue. While an action runs, an unready arrival does not queue or interrupt it.
- A ready `newMessageBubble` also cannot interrupt an active action. User taps remain explicit and may replace the current action.
- `updateObjectBounds()` retries the pending stimulus at most once after its target is measured, revalidating species, source, target data, and selection. It clears the slot before execution, including unsupported results. Removal, source/content changes, room changes, or species changes invalidate pending work.

### New-message delta integration

`interact(id)` emits only `userTap`. `setMessageBubbleTargets()` now only installs and reconciles snapshots; it never guesses whether an item is live. `messageDeltaProvider` forwards repository deltas to ChatShell, which sends `MessageAdded` events to `handleMessageAdded()`.

`MessageAddedOrigin.initialSnapshot` marks Firebase initial and reconnect snapshots as history. The initial phase remains closed to behavior through cache snapshots and ends only after the first server-backed snapshot. Remote `live` additions may dispatch immediately; local optimistic sends wait for their final `sent` modification so upload URL churn cannot invalidate the pending action. Stable `(roomId, clientId)` dedupe prevents acknowledgement, rebuild, removal/reintroduction, and reconnect replay from retriggering behavior. An unmeasured live delta enters the existing bounded pending slot and executes after widget geometry arrives.

### Verification and scope

Integration tests cover delta provenance, reconnect/backfill/reintroduction suppression, species-specific arrival selection, finite text observation, active-tap preservation, room reset, and bounded geometry retry. Existing controller and ChatShell tap tests remain part of verification.

No packages or backend changes are included.

---

## Original MVP report (historical)

日期：2026-09-18

專案路徑：

```text
/Users/appgongyong/Documents/Codex/2026-09-18/referenced-chatgpt-conversation-this-is-an
```

## 1. 專案目標

Flutter MVP：現代聊天 App 中住著一隻 8-bit 2D 寵物。

- 聊天訊息是寵物生活的世界。
- 文字訊息泡泡可作為平台。
- Emoji 是玩具。
- GIF/動畫訊息會吸引寵物靠近、觀察、撲玩。
- 寵物可在不同聊天室之間移動。
- MVP 使用本機 fake data，不含後端、登入、LLM。

## 2. 目前已完成

### 專案與平台

- Flutter project scaffold 已建立。
- 已加入 macOS、iOS、Android platform folders。
- `flutter pub get` 可成功執行。
- Swift Package Manager integration 已在 `pubspec.yaml` 關閉。

### Chat UI

- Material 3 聊天介面。
- `Pixel Pals` 與 `Family Nest` 兩個 fake chat rooms。
- 頂部 ChoiceChip 可切換聊天室。
- 顯示文字、Emoji、GIF 訊息。
- Chat UI 與寵物 overlay 分離。

主要檔案：

```text
lib/app.dart
lib/main.dart
lib/chat/domain/chat_models.dart
lib/chat/data/fake_chat_repository.dart
lib/chat/presentation/chat_shell.dart
```

### Pet domain

- `PetState`：`idle`、`walk`、`run`、`jump`、`observe`、`pounce`。
- `PetInteractable` abstraction。
- `MessageWorldObject` 將聊天訊息映射成 platform、Emoji toy、animated toy。
- `PetWorldController` 負責 room loading、位置、狀態、互動。
- 寵物目前會在左右邊界間巡迴移動。
- Emoji/GIF 由實際訊息泡泡直接接收 tap。
- 點擊後顯示 `pounce!` 或 `watching`。

主要檔案：

```text
lib/pet/domain/pet_world.dart
lib/pet/domain/pet_world_controller.dart
lib/pet/presentation/pet_world_overlay.dart
lib/pet/presentation/pixel_pet.dart
```

### Tests

目前測試涵蓋：

- fake repository rooms 與訊息種類。
- platform / Emoji / GIF world object mapping。
- Emoji → `pounce`。
- GIF → `observe`。
- room switch 重置寵物位置與狀態。
- 寵物 walk 會實際改變位置。
- Chat room switch widget flow。
- Emoji/GIF widget tap flow。

最近驗證結果：

```text
flutter test    → 6 tests passed
flutter analyze → No issues found
```

測試檔案：

```text
test/chat_domain_test.dart
test/pet_world_test.dart
test/chat_shell_test.dart
```

## 3. 已知問題

### 3.1 寵物外型不像狗

目前 `pixel_pet.dart` 使用矩形 `CustomPainter` 臨時畫出角色。它缺乏：

- 清楚的狗頭、口鼻與眼睛。
- 尖耳與白色胸口。
- 橘白色 corgi 身體比例。
- 四肢、腳掌、尾巴。
- 參考圖中的黑色 pixel outline。

目前角色只能算 placeholder，不能作為正式視覺。

### 3.2 動作不像狗

目前 movement 主要是改變 x 座標與畫面姿勢，缺少真正的逐幀姿勢：

- 四腳交替走路。
- 身體前傾奔跑。
- 蹲下、起跳、空中、落地。
- 抬頭觀察 GIF。
- 撲向 Emoji/GIF。
- 落地後尾巴搖動。

### 3.3 World coordinates 尚未與訊息 layout 同步

`messageWorldPosition()` 是固定座標估算，不是從實際訊息 widget 取得。因此：

- platform 的視覺位置尚未真正貼合訊息泡泡。
- 訊息長度、視窗尺寸、scroll offset 改變後可能偏移。
- 文字訊息目前只有 platform domain model，尚未提供完整跳躍碰撞動畫。

### 3.4 macOS 執行環境注意事項

曾遇到本機 Xcode cache、CoreSimulator service、SDK cache 權限問題。若 `flutter run -d macos` 失敗，先確認 Xcode 已啟動過一次、Developer Tools 權限正常、Xcode DerivedData 與 Flutter SDK cache 可寫入。

## 4. 參考視覺方向

使用者提供參考圖：

```text
/Users/appgongyong/Documents/Codex 圖像 2026年9月18日 上午09_57_50.png
```

目標角色特徵：

- 橘色與白色 corgi。
- 小型、可愛、短腿比例。
- 尖耳、白色口鼻、胸口、腹部。
- 黑色 pixel outline。
- 黑色鼻子與眼睛。
- 捲起尾巴。
- 低解析度 pixel-art；不要 smooth vector、3D、photorealistic。

整體 UI 方向：淺色現代聊天介面、圓角訊息泡泡；寵物存在聊天室世界內，而不是貼紙浮在 UI 上。

## 5. 建議後續實作順序

### Phase 1：建立正式狗狗素材

不要繼續擴充矩形 painter。先產出固定尺寸 sprite sheet：

```text
每 frame：48x48 或 64x64 px
透明背景
nearest-neighbor scaling
黑色 pixel outline
```

建議 sprite states：

```text
idle:    4 frames
walk:    6 frames
run:     6 frames
jump:    4 frames
observe: 3 frames
pounce:  5 frames
```

先做 `idle`、`walk`、`jump` 三組，確認角色外型後再補完整動作。

### Phase 2：接入 Sprite animation

新增：

```text
assets/pets/corgi_sheet.png
lib/pet/presentation/pixel_pet_sprite.dart
```

`PixelPetSprite` 根據 `PetState` 選取 sprite frame。使用 `CustomPainter.drawImageRect` 或 `RawImage`，保持 nearest-neighbor scaling。

由 `PetAnimationController` 根據 `PetState + elapsed time + direction` 決定 frame index；不要讓 UI widget 決定 frame。

### Phase 3：重寫 movement state machine

建議加入：

```dart
class PetMotion {
  PetState state;
  Offset position;
  PetDirection direction;
  double velocityX;
  double velocityY;
  double elapsedInState;
  String? targetObjectId;
}
```

建議行為：

```text
idle → walk → idle
idle → approach(target) → observe
observe → pounce → land → idle
walk → jump(platform) → land → idle
```

加入加速度、減速度、重力、落地判定；避免每幀直接跳到新座標。

### Phase 4：同步訊息泡泡與世界座標

將 message card 位置註冊到 world controller：

```text
message id → RenderBox global/local rect
```

聊天室 scroll 或 layout 改變時更新 rect，再計算 platform top surface、Emoji/GIF target point、approach path、jump landing point。

### Phase 5：補互動回饋

- Emoji：靠近、注視、撲玩、短暫粒子/愛心。
- GIF：跑近、抬頭、觀察、撲向畫面。
- Platform：跳上、站立、尾巴搖動。
- Room switch：寵物從畫面側邊跑入新聊天室。

## 6. 接手啟動方式

```bash
cd /Users/appgongyong/Documents/Codex/2026-09-18/referenced-chatgpt-conversation-this-is-an
flutter pub get
flutter run -d macos
```

驗證：

```bash
flutter analyze
flutter test
```

## 7. 建議下一個最小任務

先完成「正式 corgi idle/walk sprite + SpritePainter」，不要同時重寫所有互動。

完成條件：

- 狗一眼可辨識為橘白 corgi。
- idle 有呼吸與尾巴微動。
- walk 有四腳交替。
- macOS、iOS、Android 都維持清晰 pixel edges。
- 現有 6 個測試仍全部通過。
