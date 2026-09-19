# Pet Behavior Catalog Runtime Design

## Goal

將既有 `PetBehaviorCatalog` 從 data-only catalog 接入寵物 runtime，使三種物種能依 stimulus、訊息目標與自身 profile 選擇可執行行為，同時保留現有寵物互動流程與 fallback。

## Scope

本階段只處理 catalog-to-runtime wiring：

- 將每則訊息泡泡視為獨立互動 target。
- 將新訊息、emoji、圖片、GIF、影片轉成 behavior stimulus。
- 依物種 profile、target kind、priority 選擇 catalog action。
- 將 catalog action 映射至現有 `PetWorldController` runtime。
- 未有動畫資產或 runtime mapping 時，使用安全 fallback。

本階段不包含：

- 新增動畫素材。
- 修改 backend 或 Firebase contract。
- 引入新 package。
- 重寫既有寵物物理與移動系統。

## Current boundaries

- `PetBehaviorCatalog` 保存 enum、category、animation key、species profile。
- `PetMessageBubbleTarget` 將 `ChatMessage` 暴露為 `PetBoundedInteractable`。
- `PetWorldController` 目前以 `PetActionType` 執行 jump、pounce、observe 等 runtime flow。
- 既有 `interactionFor()` 保留作為相容 fallback，不再作為主要行為選擇來源。

## Runtime model

```text
PetStimulus
  -> PetBehaviorCandidateSelector
  -> PetBehaviorAction
  -> PetBehaviorExecutor
  -> PetWorldController / existing runtime action
```

### Stimulus

`PetBehaviorStimulus` 包含：

- `PetStimulusType`。
- selected `PetType`。
- canonical message target id。
- target `WorldObjectKind`。
- normalized content kind。
- optional source message metadata。

Stimulus 不直接指定 action；它只描述事件與互動目標。

本階段新增 `userTap` stimulus；`newMessageBubble` 與 `userTap` 不可混用：

- `newMessageBubble`：新訊息事件，可選擇性觸發接近／觀察；不改變既有 tap 行為。
- `userTap`：使用者點擊訊息 target；維持既有 text → jump、emoji → chase/pounce、media → inspect 相容流程。

#### Content normalization

目前 chat domain 的 `MessageContent` 是 `text`、`image`、`video`；舊 demo domain 的 `MessageKind` 是 `text`、`emoji`、`gif`。Behavior layer 不新增 message type，而是統一轉成：

- `text`：一般文字。
- `emoji`：text content 經既有 emoji-only 判斷成立。
- `image`：`ImageMessageContent`。
- `gif`：既有 demo `MessageKind.gif` 或 video content 的 GIF MIME。
- `video`：`VideoMessageContent` 且非 GIF。

Normalization 必須是純函式，並由 adapter 依實際 message model 呼叫；selector 不直接依賴 UI widget。

### Candidate selection

`PetBehaviorCandidateSelector` 負責：

1. 讀取 selected species 的 `PetBehaviorProfile`。
2. 依 `stimulus type + normalized content kind + target kind + species` 過濾合法 action。
3. 只使用 catalog 已宣告且符合 target capability 的 action。
4. 以 priority 選擇候選；同 priority 使用 deterministic selection，避免測試與 UI 行為不穩定。
5. 找不到候選時回傳明確 `fallback` 或 `ignored` result。

Selector 不執行動畫、不修改 controller state、不持有 UI reference。

Selector API 必須具備下列語意：

```text
select(PetBehaviorStimulus) -> PetBehaviorSelection
```

`PetBehaviorSelection` 至少包含 selected action、target id、selection reason，以及 `native / degraded / fallback / ignored` capability result。

`PetActionDefinition` / trigger metadata 需補足：

- supported `PetStimulusType`。
- supported normalized content kinds。
- supported `WorldObjectKind`。
- capability class：`native`、`degraded` 或 `unsupported`。

沒有 target kind metadata 的 action 不得被 selector 當成可執行候選。

Candidate source precedence：

1. `userTap` 優先使用 target-kind compatible 的 legacy-compatible trigger。
2. `newMessageBubble` 只使用 `novelObjectActions` 與明確標記為 new-message compatible 的 trigger。
3. 一般 `actions`（walk、care、social 等）不得自動成為訊息 target candidate，除非 action metadata 明確宣告 stimulus 與 target capability。

目前 catalog 中 `approachArc`、`approachLowSilent`、`approachSideways` 尚無原生 runtime mapping；new-message stimulus 對這些 action 回傳 `ignored` 或明確 `fallback`，不得取代 user tap 的 legacy action。

### Execution

`PetBehaviorExecutor` 將 catalog action 轉成現有 runtime 行為。Mapping 必須先通過 target capability 檢查；不能只依 action 名稱強制轉換。

| Catalog action | Capability | Existing runtime mapping |
|---|---|---|
| `sniffBubble` | degraded | `observe`，附帶 target identity |
| `circleSniff` | degraded | walk toward target + `observe` |
| `headTiltFocus` | degraded | `observe` |
| `nosePawBump` | native only for `platform` and `userTap` | `jumpToPlatform`；其他 target 回 `fallback` |
| `sniffWhiskerScan` | degraded | `observe` |
| `pawTest` | degraded only for `emojiToy` | payload-aware `chaseEmoji` / pounce adapter |
| `hidePeek` | fallback | `observe` 不得宣稱等價；記錄 degraded reason |
| `batPounce` | degraded only for `emojiToy` | payload-aware `chaseEmoji` |
| `headTiltEyeFocus` | degraded | `observe` |
| `beakProbe` | fallback | `observe`，記錄 unsupported native motion |
| `beakManipulate` | fallback | `observe`，記錄 unsupported native motion |
| `flyBack` | fallback | `ignored` 或 `observe`，不得映射成 walk |

Mapping 屬於 adapter，不修改 catalog 的語意。`fallback` 必須是完整 runtime transition；不能只設定 `PetState.observe` 後讓下一個 tick 立即回到 patrol。`ignored` 不得改變 active target 或 controller state。

## Runtime API and state transitions

`PetWorldController` 新增單一入口：

```text
dispatch(PetBehaviorStimulus) -> PetBehaviorExecutionResult
```

執行結果至少區分：

- `executed`：native 或 degraded action 已啟動。
- `fallback`：原 action 不可執行，已啟動明確 fallback。
- `ignored`：target 不存在、bounds 未 ready 或 action 不適用。

Executor 負責 active target ownership、action timer reset、取消前一個 action，以及將既有 `PetActionType` 流程啟動。`PetWorldController.interact(String)` 保留並改為建立 stimulus 後呼叫 `dispatch()`。

Fallback transition 必須完整設定 `currentAction`、`_activeTarget`、timer 與 state；不得只設定 `state`。

## Species behavior

同一 stimulus 可依 species 產生不同候選：

- corgi：`sniffBubble`、`nosePawBump`。
- cat：`sniffWhiskerScan`、`pawTest`、`hidePeek`。
- parrot：`headTiltEyeFocus`、`beakProbe`、`beakManipulate`。

Species profile 是唯一行為差異來源；聊天 UI 不判斷物種。

## Integration points

- `PetMessageTargetFactory`：將 Freezed `domain.ChatMessage` 與 legacy demo `chat_models.ChatMessage` 轉成同一 runtime target data contract。
- `PetMessageTarget`：唯一 runtime message interactable，提供 target kind、canonical message identity、normalized content、payload、bounds readiness。
- `PetWorldController`：只持有 `PetMessageTarget`（或其共同 `PetInteractable` interface），新增 stimulus dispatch 與 catalog action execution entry point。
- 現有 `PetActionType`：暫時保留，作為 runtime compatibility boundary。
- `PetBehaviorCatalog`：補足 selector 所需的 action、trigger、target metadata，不改變既有 public enum 意義。

### Canonical message identity

所有 message interactable 必須經由同一 factory 並使用同一 identity：

```text
serverId ?? clientId
```

在 serverId 尚未產生時，clientId 是暫時 identity；legacy demo message 使用其 adapter-provided stable id。兩套 model 不得各自建立 runtime object。serverId 到達時需由 message store / target reconciliation 更新；active target、bounds map、bubble spring、remove handling 全部使用 canonical identity。

`PetMessageTarget` 必須攜帶 normalized content 與 payload（例如 emoji text、media kind、display text）；executor 不得從具體 target class 猜 payload。

### Bounds readiness

`PetMessageBubbleTarget` 不得用預設 Rect 代表已完成 layout。需加入明確 readiness（例如 `hasMeasuredBounds`），selector / executor 對未 ready target 回傳 `ignored`，待 layout update 後才能執行需要位置的 action。

## Fallback and failure handling

- action 沒有 definition：回傳 `fallback`，使用完整、可追蹤的 observe transition。
- action 沒有 runtime mapping：回傳 `fallback` 或 `ignored`，不得假裝等價執行。
- target 已離開列表：取消 active action，回到 idle。
- bounds 尚未 ready：回傳 `ignored`，等待下一次 layout update。
- bounds 未 ready 且目前沒有 active action：保留 pending stimulus，layout ready 後最多重試一次。
- bounds 未 ready 且目前已有 active action：不取消舊 action、不排隊無限事件；回傳 `ignored`。
- selected pet 改變：取消目前 species-specific action，清除 active target；下一個 stimulus 依新 species 重新選擇。
- 不允許 selector throw 影響聊天訊息列表。

## Testing

新增測試覆蓋：

- 三種 species 對同一 stimulus 產生不同 action。
- text、emoji、image、GIF、video 經 normalization 產生正確 stimulus。
- selector 依 species、content kind、target kind 過濾候選。
- stimulus matrix 覆蓋 new message / user tap × text / emoji / image / GIF / video。
- user tap legacy compatibility：text → jump、emoji → chase/pounce、media → inspect。
- 每個 message target 使用自身 message id，不共享固定 target。
- legacy 與 Freezed message model 經同一 target factory，產生相同 target contract。
- canonical id reconciliation 會同步 active target、bounds、spring、current platform。
- priority 選擇 deterministic。
- 沒有候選時回傳明確 fallback / ignored result。
- native、degraded、fallback、ignored capability 分類正確。
- 未支援 animation/runtime mapping 時不 crash、不假裝執行錯誤動作。
- bounds 未 ready、target removed、pet switched 都有明確 state transition。
- catalog action 可進入 controller 既有 runtime。
- 既有 jump、emoji、GIF、media interaction 不回歸。

## Phase 1 executable boundary

本階段不宣稱 50 個 catalog action 全部已有視覺 runtime。可執行範圍分為：

- Native：既有 runtime 可完整執行，且 target capability 相符。
- Degraded：使用既有 runtime 完成語意近似行為，結果需標示 degraded。
- Unsupported：保留在 catalog，但 selector 回傳 fallback / ignored，不得誤映射成其他物種或其他 target 的動作。

第一階段優先保證 user tap native compatibility，再讓可安全降級的 novel-object action 接入。新增動畫 state 不在本階段。

## Acceptance criteria

- catalog action 可由 runtime 觸發並執行。
- 每則訊息泡泡都可成為獨立互動目標。
- 三種物種對相同訊息事件可呈現不同 behavior action。
- 新增 catalog action 不需修改聊天 UI。
- 不修改 backend、不引入新 package、不新增動畫資產。
- `flutter analyze` 與 `flutter test` 通過。
- backend repository working tree 保持不變。
