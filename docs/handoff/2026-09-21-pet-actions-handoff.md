# 2026-09-21 寵物動作施工 Handoff

## 明日目標

將動物行為專家整理的 catalog actions 分批接成真正可執行、可顯示、可測試的
寵物動作。遵循 [寵物動作新增指南](../pet-action-authoring-guide.md)，不把時間軸
寫回 `PetWorldController`，不建立平行 runtime，暫不引入 Flame。

## 目前基線

行為 catalog 共 55 種：

- 狗：10 種一般行為＋9 種陌生物件行為。
- 貓：10 種一般行為＋8 種陌生物件行為。
- 鸚鵡：10 種一般行為＋8 種陌生物件行為。

目前已有 7 類 runtime handlers：

- `jumpToPlatform`
- `chaseEmoji`
- `inspectMedia`
- `observeTarget`
- `catPawTest`
- `dogProbe`
- `parrotProbe`

其餘 catalog actions 多數仍為 `unsupported`、`degraded` 或沒有 trigger。存在於
catalog 不代表已有專用動畫、handler 或自動觸發。

現行執行路徑：

```text
Stimulus
  → PetBehaviorSelector
  → PetBehaviorExecutor
  → PetActionPlan
  → PetActionRunner
  → PetActionHandler
  → PetPresentationState
  → Flutter presentation
```

## 施工原則

1. 每次只完成一個可驗收 behavior slice，不同物種可共享流程，不共享錯誤姿勢。
2. 先寫 handler/selector/生命週期測試，再接 production code。
3. Catalog capability 必須誠實：有專用 runtime 與視覺才標示 `native`。
4. 新 runtime action 同步處理 `PetRuntimeAction`、相容 `PetActionType`、
   `_actionTypeFor()`、factory 與 completion retention。
5. Handler 每次 activation 建立新 instance，只透過 `PetActionContext` 操作世界。
6. 捲動、訊息重排與 client/server reconciliation 後，效果仍作用於 live target；
   elapsed 不重置，`originTargetId` 不改寫。
7. 新圖資必須完成尺寸、alpha、可見 RGBA、contact sheet 與實際 cadence 驗證。
8. 每階段先 peer review，再跑 `./scripts/commit_gate.sh`，通過才 commit。

## 建議施工順序

### Phase 0：先建立 ambient／無訊息 target 執行契約

這是一般巡邏、休息與自理動作的必要前提。目前預設 walk 由
`PetWorldController._tickDefaultPatrol()` 直接執行，不是 catalog selection、
`PetActionPlan` 或 handler runtime。現有 `PetBehaviorRuntime.startAction()` 也要求
一個 `PetInteractable` target。因此不能直接宣稱 `walkTrot`、`walkStalk`、
`walkClimb` 已接通，也不能以假的訊息泡泡當 self target。

Phase 0 先完成設計與測試，明確決定：

1. Targetless/self action 如何表達。建議讓 plan 明確區分 `self` 與
   `interactable` subject，runner 對 self action 允許沒有 live target；不要只靠
   `null` 猜語意。
2. `originTargetId` 對 self action 的替代 metadata；訊息 action 仍維持 immutable
   origin ID 與 live target 分離。
3. Ambient stimulus producer 放置位置、idle duration/cooldown、可測 clock 與
   deterministic random source。Widget 不直接發動行為。
4. Catalog 專用 trigger collection 與 selector routing。
5. Executor 如何建立 self-action plan，不經需要 message target/bounds 的現有路徑。
6. Priority、去重、pending 與 interruption policy：ambient 不得搶占 user tap、
   new message 或正在運行的明確互動。
7. Room reset、pet switch、replacement 與 App lifecycle 對 ambient action 的清理。
8. 舊 `_tickDefaultPatrol()` 在 migration 期間的相容策略；每接通一個物種後只移除
   該物種舊路徑，避免雙重 movement ownership。

Phase 0 必須先提交一份短規格與 acceptance matrix，通過 review 後才能改 runtime
interface。這是相容性 migration，不是單純新增 enum。

### Phase 1：一般移動

目的：先建立三物種可信的日常移動語言，後續 approach、社交與探索皆可重用
movement primitive，但各物種保留不同姿勢與 cadence。

#### 1A. 狗 `walkTrot`

- 現有 corgi walk cycle 可作視覺基線。
- 明確定義 trot 速度、腳步 cadence、方向切換與 idle transition。
- 檢查四腳交替、foot sliding、頭身比例與基線。
- 新增或共用明確 locomotion `PetRuntimeAction` 與 handler；不能把既有
  `_tickDefaultPatrol()` 稱為 runtime handler。
- Handler 透過 plan/profile 取得狗的速度與 cadence；不得在 overlay 判斷物種。
- 接通前 capability 維持 `unsupported`。只有 selector → plan → handler →
  presentation 全路徑完成後才能標成 `native`。

#### 1B. 貓 `walkStalk`

- 使用既有 `catStalk` state/frames 作為起點。
- 定義低姿態、步幅、速度、尾巴與頭部穩定度。
- 不可把狗 trot cadence 套用到貓。
- 驗證正常 walk 與 stalk 之間沒有尺寸跳動、身體拉長或頭部縮放。
- 使用同一 locomotion handler 或專用 handler 必須在 Phase 0 規格決定；若共享，
  差異由不可變 gait profile/plan metadata 表達。

#### 1C. 鸚鵡 `walkClimb`，再評估 `flyFlap`

- 先接地面 hop/walk 或泡泡邊緣攀爬。
- `flyFlap` 需有飛行路徑、起飛、空中、降落圖資後才標示 native。
- 沒有飛行圖資時不得以走路冒充飛行；保持 degraded/unsupported。
- `walkClimb` 接通前仍走舊巡邏相容路徑，但 catalog capability 不升級。

Phase 1 完成條件：

- 三物種巡邏姿勢可辨識。
- idle → locomotion → idle 無尺寸或 anchor 跳動。
- room switch、pet switch 會停止前一物種動作。
- App 冷啟動錄製每個物種至少一個完整 cycle。

### Phase 2：休息與自理

目的：增加不依賴訊息 target 的自主行為，驗證 runtime 能處理 ambient/self action。

#### 2A. 狗 `pantRest`

- 安靜狀態或移動後觸發；不可搶占高優先級訊息互動。
- 定義循環時間、退出條件與 idle fallback。

#### 2B. 貓 `selfGroom`

- 定義舔毛 phase、frame cadence 與可中斷點。
- 新訊息或使用者點擊可 replacement，清理後不得殘留 frame/badge。

#### 2C. 鸚鵡 `preen`

- 定義喙整理羽毛、羽毛粒子是否需要 presentation output。
- 粒子使用 snapshot value，不暴露 mutable runtime particle。

Phase 2 需要先決定 ambient trigger：

- 建議新增明確 idle-duration stimulus 或 scheduler producer。
- 在 catalog 建立專用 trigger collection，更新 selector routing。
- 定義去重、cooldown、random seed/testability 與 active-action interruption policy。
- 不使用 Widget timer 直接啟動動作。

Phase 2 完成條件：

- 三種 self action 可自然完成，也可被 replacement、room reset、pet switch 中斷。
- 自然完成不呼叫 `cancel()`；中斷恰好呼叫一次。
- 無 target 的 plan/handler contract 有明確設計；不要傳入假的訊息泡泡 target。

### Phase 3：社交反應

目的：接通可由使用者互動、其他寵物或聊天室事件觸發的情緒／社交行為。

Phase 3 前置切片：

- 為 `nearbyPet` 或選定來源建立真正 producer/normalizer；enum 已存在不代表已有
  事件來源。
- 在 catalog 建立社交 trigger collection，並在 selector stimulus switch 路由。
- 定義來源 identity、去重、cooldown、重播與 active-action interruption policy。
- 為 `playBow`、`headBuntRub`、`contactCall` 增加明確 executor mapping；沒有
  mapping 前不得標成 native。

#### 3A. 狗 `playBow`

- 建議先由 user tap 或 nearby-pet stimulus 觸發。
- 定義前肢伏低、臀部抬高、尾巴反應與恢復姿勢。

#### 3B. 貓 `headBuntRub`

- 目前文字泡泡 tap 會 degraded 成 platform jump。
- 新 native 版本應移動至泡泡側邊，再完成頭蹭/身體擦過時間軸。
- 需要 live bounds；不可使用啟動時快照位置。

#### 3C. 鸚鵡 `contactCall`

- 定義聲音或音符粒子輸出；預設避免直接播放不可控音效。
- 若加入音訊，需另行設計靜音、平台生命週期與 accessibility。

Phase 3 完成條件：

- trigger priority 不壓過使用者正在進行的明確互動。
- `executed`、`fallback`、`ignored` reason 精確且有 table test。
- 社交粒子與 badge 經深不可變 snapshot 輸出。

### Phase 4：陌生物件進階反應

目的：完成「接近 → 調查 → 評估 → 退避／投入」較長鏈條，建立物種差異。

先把下列 catalog actions 當成獨立可選動作接通，不先假設它們是一個 action 內的
phase：

1. 狗：`circleSniff` → `retreatLookback`。
2. 貓：`hidePeek` → `batPounce`。
3. 鸚鵡：`leanForwardPause` → `beakManipulate` → `flyBack`。

行為要求：

- 每個 action 先定義自己的入口 trigger、capability、plan payload、executor mapping
  與 handler。未完成這些項目時保持 unsupported。
- `circleSniff`、`retreatLookback`、`hidePeek`、`batPounce`、
  `leanForwardPause`、`beakManipulate`、`flyBack` 都維持獨立 catalog identity；
  不因被放在同一建議順序就全部標成 native。
- 若後續需要 composition，另建 orchestration plan，明確指定哪個 catalog action
  是入口、哪些只是內部 phase、完成／取消如何傳遞。未有規格前不把多個 catalog
  action 塞進單一 handler。
- 使用 `beginPhase()`，保證 previous elapsed 非負。
- 一次 large tick 跨越多個 threshold 時，效果順序正確且不重複。
- target 在捲動或 canonical ID reconciliation 後仍可 retarget。
- `flyBack` 沒有飛行圖資與路徑前維持 ignored，不以 walk fallback 欺騙 capability。
- `beakManipulate` 若會推動玩具，先決定是否只用現有 callback；暫不為此引入
  Forge2D。

Phase 4 完成條件：

- 每個物種至少兩個可獨立選擇、執行與取消的陌生物件 action。
- 若要宣稱已有完整 chain，必須先完成獨立 orchestration 規格、實作與 chain
  lifecycle tests；否則只報告個別 actions，不使用「完整 chain」描述。
- 文字、Emoji、圖片、GIF、影片 target kind 不會錯配。
- 中途移除訊息、切房、換寵物、替換 action 均正確清理。
- 動態錄影可辨識物種差異，不只是 badge 文字不同。

## 明日建議切片

明日不要一次完成全部四個 Phase。建議目標：

```text
Slice 1：完成 Phase 0 targetless/self-action 規格與相容 migration matrix
Slice 2：實作 ambient producer、selector routing、self-action plan/runner contract
Slice 3：抽出 locomotion handler，接通 dog walkTrot
Slice 4：狗冷啟動視覺驗證、peer review、commit gate
Slice 5：若 Slice 1–4 全綠，再依同一 contract 接 cat walkStalk
Slice 6：cat 通過後再接 parrot walkClimb
```

若 movement 圖資需要重畫，先完成同物種 coherent sprite cycle，再接 runtime。
不要用尺寸縮放或拉伸修補姿勢問題。

Phase 2 只做設計確認與 trigger contract，不在 Phase 0 migration 或 Phase 1 狗移動
尚未通過驗收時同時施工。

## 每個 Slice 的標準流程

1. 依 [寵物動作新增指南](../pet-action-authoring-guide.md) 判斷修改層級。
2. 建立／擴充 catalog invariant、selector、executor、runner 或 handler tests。
3. 確認 RED 原因是缺少新能力，不是破壞既有測試。
4. 實作最小完整垂直切片。
5. 跑 focused tests、world/reconciliation、chat shell。
6. 冷啟動 App，保存 contact sheet／GIF／錄影證據。
7. 交付獨立 peer review；解決 Critical 與 Important findings。
8. 執行 `./scripts/commit_gate.sh`。
9. 每個 slice 單獨 commit，不 push 未通過 gate 的中間狀態。

## 必跑測試

```bash
flutter test test/pet/pet_behavior_executor_test.dart
flutter test test/pet/pet_behavior_selector_test.dart
flutter test test/pet/pet_behavior_integration_test.dart
flutter test test/pet/pet_behavior_runtime_test.dart
flutter test test/pet/pet_ambient_stimulus_producer_test.dart
flutter test test/pet/pet_action_plan_test.dart
flutter test test/pet/pet_action_runner_test.dart
flutter test test/pet/actions/pet_action_handlers_test.dart
flutter test test/pet/pet_world_reconciliation_test.dart
flutter test test/pet/pet_world_test.dart test/pet_world_test.dart
flutter test test/pet/pet_presentation_state_test.dart
flutter test test/pet/pet_animation_catalog_test.dart test/pixel_pet_sprite_test.dart
flutter test test/chat_shell_test.dart
./scripts/commit_gate.sh
```

新增 catalog action 時，依指南新增 `test/pet/pet_behavior_catalog_test.dart` 或在
既有 selector tests 中覆蓋完整 catalog invariants。

新增 ambient producer/normalizer 時，建立
`test/pet/pet_ambient_stimulus_producer_test.dart` focused unit test，並在
`pet_behavior_integration_test.dart` 驗證 producer → normalizer → selector →
executor → runner。至少測 idle threshold、cooldown、deterministic clock/random、
user action 優先、room/pet reset、不重複觸發，以及 App pause/resume/dispose：
pause 不累積錯誤 idle 時間、resume 不立即補發過期事件、dispose 不再發出 stimulus
或持有 timer/listener。

## 明確不做

- 不一次把 55 種行為全部標成 native。
- 不只加 enum、badge 或圖檔就宣稱動作完成。
- 不建立第二套 controller／runner／animation clock。
- 不把 species switch 散落到 UI。
- 不以固定訊息座標取代 live target bounds。
- 不改聊天同步、Firebase adapter 或後端契約。
- 暫不引入 Flame、Forge2D、Rive、Spine。

## 明日完成時更新本文件

記錄：

- 完成 action 與 capability 變更。
- 新增 handler、state、圖資與 trigger。
- Focused/full test 數量。
- App 冷啟動與視覺證據路徑。
- Peer review verdict 與已解 findings。
- Commit hash、remote branch、未完成項目。
