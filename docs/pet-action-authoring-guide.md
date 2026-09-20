# 寵物動作新增指南

本文件說明如何在目前 Flutter 架構中新增、觸發、顯示及驗證寵物動作。
修改任何寵物行為、動畫、訊息泡泡互動或動作生命週期前，先閱讀本文件。

目前不使用 Flame。行為選擇、執行時間軸與 Flutter 顯示彼此分離，未來若更換
渲染引擎，只應替換 presentation adapter，不應重寫行為規則。

## 1. 先判斷要新增哪一層

| 需求 | 需要修改 |
| --- | --- |
| 只增加行為名稱，尚不可觸發 | Behavior catalog、profile；標記 `unsupported` |
| 讓既有 runtime 動作接受新行為 | Catalog definition、trigger、executor mapping 與測試 |
| 增加全新可執行動作 | Catalog、`PetRuntimeAction`、相容 `PetActionType`、`PetActionPlan` mapping、handler、factory、動畫 mapping、測試 |
| 只替換或增加 sprite frame | Assets、`PetAnimationCatalog`、sprite integrity test |
| 增加新觸發來源 | `PetStimulusType`、normalizer/producer、catalog trigger collection、selector routing、去重/排隊政策與 integration test |
| 改變 UI 顯示資料 | Handler/context output、`PetPresentationState`、overlay 與 snapshot test |

只把名稱加入 `PetBehaviorAction` 不會產生可見動作。完整路徑必須成立：

```text
訊息事件或點擊
  → PetBehaviorStimulus
  → PetBehaviorSelector
  → PetBehaviorExecutor
  → PetActionPlan
  → PetActionRunner
  → PetActionHandler
  → PetPresentationState
  → PetWorldOverlay / PixelPet
```

## 2. 各層責任

### Behavior catalog：描述可選行為

檔案：`lib/pet/domain/pet_behavior_catalog.dart`

1. 將名稱加入 `PetBehaviorAction`。
2. 選擇 `PetBehaviorCategory`。
3. 在 `actionDefinitions` 設定穩定 `animationKey`。
4. 宣告允許的 stimulus、content kind 與 target kind。
5. 設定 capability：
   - `native`：有專用 runtime 與動畫。
   - `degraded`：會明確映射到既有 fallback。
   - `unsupported`：只保留 catalog 資料，不會自動執行。
6. 將動作放入正確物種 profile；陌生物件互動放在
   `novelObjectActions`，一般行為放在 `actions`。
7. 需要自動觸發時，加入對應 `PetBehaviorTrigger`。

Catalog 只描述「可選什麼」，不保存位置、時鐘、sprite frame 或 UI 狀態。

### Executor 與 Plan：把選擇轉成命令

檔案：

- `lib/pet/domain/pet_behavior_executor.dart`
- `lib/pet/domain/pet_action_plan.dart`

`PetBehaviorExecutor` 必須明確處理新 catalog action：

- 驗證 target kind 與已量測 bounds。
- 選擇 `executed`、`fallback` 或 `ignored`。
- 產生精確、可測試的 `reason`。
- 需要執行時，只呼叫一次 `PetBehaviorRuntime.startAction()`。

全新動作需加入 `PetRuntimeAction`。`PetActionPlan` 只保存不可變命令資料：

- `runtimeAction`
- 原始 `catalogAction`
- `originTargetId`
- 必要 payload
- `walkToward` 等執行選項

不要把 capability、執行結果、Widget、聊天 DTO 或可變 target bounds 放進 plan。
`originTargetId` 是來源紀錄；訊息 reconciliation 後的即時位置由 runner target
負責，不應改寫 plan。

目前 `PetWorldController` 仍以 `PetActionType` 提供舊呼叫端相容狀態。新增
`PetRuntimeAction` 時，也必須：

1. 在 `PetActionType` 增加對應值。
2. 更新 `PetWorldController._actionTypeFor()` 的 exhaustive mapping。
3. 保留既有 public starter 時，讓 starter 單向建立 plan，不可形成遞迴或重複清理。
4. 增加 mapping 與舊 starter source-compatibility 測試。

### Runner：管理執行生命週期

檔案：`lib/pet/domain/pet_action_runner.dart`

新增 `PetRuntimeAction` 後必須：

1. 在 handler factory registry 加入恰好一個 factory。
2. 在 completion retention table 明確決定完成後是否保留 target/payload。
3. 驗證 replacement、room reset、pet switch、target removal 的清理結果。

生命週期原因：

```text
completed
replaced
worldReset
petChanged
targetRemoved
```

自然完成不呼叫 `cancel()`；其他中斷原因呼叫一次。Runner 擁有 total/phase
elapsed 與 live target。訊息 client ID 轉 server ID、重新排序或捲動時，使用
`retarget()` 更新即時 target，不重置 elapsed，也不改寫 `originTargetId`。

### Handler：實作動作時間軸

目錄：`lib/pet/domain/actions/`

每個全新 runtime action 建立一個 handler：

```dart
final class ExampleAction extends PetActionHandlerBase {
  @override
  PetRuntimeAction get action => PetRuntimeAction.example;

  @override
  void start(PetActionContext context, PetActionPlan plan) {
    // 設定初始 state、direction、frame 或效果。
  }

  @override
  PetActionTickResult tick(PetActionContext context, Duration elapsed) {
    // 使用 context 的 live target 與 runner clocks。
    return PetActionTickResult.running;
  }

  @override
  void cancel(PetActionContext context, PetActionEndReason reason) {
    // 只清理本動作擁有的暫態效果。
  }
}
```

Handler 不可持有或取得整個 `PetWorldController`。只能透過
`PetActionContext` 使用：

- live target、position、state、direction、frame
- total/phase/previous elapsed
- viewport、platform、surface、jump height
- bubble impulse、腳步、粒子等效果 callback
- `beginPhase()` 與 `complete()`

時間軸規則：

- Runner 先 advance clock，再呼叫 handler tick。
- 保留既有毫秒取整語意。
- 一次 large tick 跨過多個 threshold 時，效果順序仍需正確。
- `beginPhase()` 後 previous elapsed 不可為負數。
- 動作在本 tick 完成後，巡邏從下一 tick 才恢復。
- 需要撞擊泡泡時，每次 effect 發生前讀取 live target，不快取舊 bounds 或 ID。

### Animation catalog 與圖資

檔案：

- `lib/pet/presentation/pet_animation_catalog.dart`
- `lib/pet/presentation/pet_animation_spec.dart`
- `assets/pets/`

新增 `PetState` 或專用視覺狀態時，為每個物種提供明確 mapping。沒有專用圖資的
物種必須選擇可接受 fallback，不可引用不存在檔案。

`PetState` 是 exhaustive enum。加入新值時同步檢查：

- `PetAnimationCatalog`：每個物種的 frame mapping。
- `PetWorldController.frameIndex`：非 active action 時的 cadence/frame count；若
  frame 完全由 handler 發布，也要明確回傳 `_actionFrameIndex`。
- `PetWorldController.presentationState.showActionBadge`：是否顯示 badge。
- `PetWorldOverlay` badge label switch：需要 badge 時提供正確文字。
- `petAssetFor`/`corgiAssetFor` 相容 API 與 mapping tests。

圖資要求：

- PNG、透明背景、固定 `128x128` canvas。
- 相同物種保持頭身比例、基線、視覺重量與朝向。
- Pixel art 使用 nearest-neighbor rendering。
- 同一 cycle 的可見 RGBA 必須確實不同；不要用透明像素下的 RGB 製造差異。
- 動態驗證不能只看 contact sheet；至少檢查一個實際 cadence cycle。

`PetAnimationCatalog` 只存在 presentation layer。Domain 不可 import 它。

### Presentation snapshot：輸出，不是控制器

檔案：

- `lib/pet/domain/pet_presentation_state.dart`
- `lib/pet/presentation/pet_world_overlay.dart`

若新動作需要新的顯示資料，先由 handler/context 產生 scalar 或 value output，再
加入深不可變 snapshot。禁止把可變 particle、toy、trail、target runtime object
直接暴露給 UI。Overlay 每次 build 只讀一次 `presentationState`；輸入 callback
仍呼叫 controller facade。

## 3. 常見施工方式

### A. 新行為沿用既有 runtime

適用：新 catalog 名稱可安全映射到 jump、observe、inspect 或 chase。

1. 新增 catalog action、definition、profile、trigger。
2. 在 executor 增加明確 mapping 與 fallback reason。
3. 不新增 `PetRuntimeAction` 或 handler。
4. 增加 selector/executor table tests 與整合測試。

### B. 新增物種專用可執行動作

適用：貓拍打、狗鼻探、鸚鵡喙探等不同節奏與效果。

1. 完成 catalog 與 trigger。
2. 新增 `PetRuntimeAction` 與相容 `PetActionType`，更新 `_actionTypeFor()`。
3. Executor 建立 `PetActionPlan`。
4. 新增獨立 handler。
5. 登錄 factory 與 completion retention。
6. 增加 `PetState`、frame cadence、animation mapping 與圖資；若可重用既有
   state，可省略。
7. 需要 badge 時更新 snapshot 判斷與 overlay label。
8. 更新 snapshot 只在需要新顯示值時進行。
9. 完成單元、相容 starter、生命週期、reconciliation 與 UI 整合測試。

### C. 新增「有新訊息」觸發

1. Catalog definition 支援 `PetStimulusType.newMessageBubble`。
2. 限定 content kind、target kind、pet type 與 priority。
3. 保留首次 room snapshot 為 baseline，不對歷史訊息觸發。
4. client/server acknowledgement、重排與 rebuild 不得重複觸發。
5. 未量測 target 只保留一個 bounded pending stimulus；bounds 就緒後重試一次。
6. 既有 action 運行時，未量測 arrival 不排隊、不打斷。

### D. 新增其他觸發來源

1. 將來源加入 `PetStimulusType`。
2. 定義事件 producer 與 normalizer；UI 不直接挑選動作。
3. 在 `PetBehaviorCatalog` 建立來源專用 `PetBehaviorTrigger` collection。
4. 更新 `PetBehaviorSelector` 的 stimulus switch，將新來源路由到該 collection；
   不可落入目前的空 trigger list。
5. 決定 profile action 範圍：一般 `actions`、`novelObjectActions` 或兩者。
6. 明確定義來源的去重、重播、排序、pending 與 active-action interruption 政策。
   訊息 arrival 的 baseline/ack 規則不可無條件套用到其他事件。
7. 測試 producer → normalizer → selector → executor 全路徑，以及 rebuild/retry
   不重複觸發。

### E. 只換動畫或增加 frame

1. 不改 behavior catalog、plan、runner 或 handler。
2. 更換 assets 與 animation mapping。
3. 保持 logical size；若必須調整，驗證 idle/action 轉換沒有 size jump。
4. 在 `test/pixel_pet_sprite_test.dart` 為每個變更 cycle 加入完整 frame 路徑，
   解碼每張圖片並檢查尺寸、alpha 與可見 RGBA 差異；現有自動完整性檢查只涵蓋
   corgi walk，不會自動保護其他 cycle。
5. 執行：

   ```bash
   flutter test test/pixel_pet_sprite_test.dart
   ```

6. 依實際播放順序產生 1:1 或整數 nearest-neighbor 放大的 contact sheet，逐格
   檢查頭身比例、基線與足序。
7. 完整停止並重新啟動 App，錄製至少一個實際 cadence cycle；比較 idle → action
   → idle，拒絕 foot sliding、凍結肢體、拉伸、頭部縮放與尺寸跳動。保存 contact
   sheet/GIF/錄影路徑於施工報告。

## 4. 必要測試

依修改層級增加測試，不以大量無關測試取代精準測試。

| 層級 | 主要測試 |
| --- | --- |
| Catalog / trigger | 新增 `test/pet/pet_behavior_catalog_test.dart`（目前尚無專用檔）、既有 selector/trigger tests |
| Executor / plan | `test/pet/pet_behavior_executor_test.dart`、`pet_action_plan_test.dart` |
| Runner lifecycle | `test/pet/pet_action_runner_test.dart` |
| Handler timeline | `test/pet/actions/pet_action_handlers_test.dart` |
| Animation mapping/assets | `test/pet/pet_animation_catalog_test.dart`、`test/pixel_pet_sprite_test.dart` |
| Snapshot / UI | `test/pet/pet_presentation_state_test.dart`、`test/chat_shell_test.dart` |
| Target migration | `test/pet/pet_world_reconciliation_test.dart` |
| World behavior | `test/pet/pet_world_test.dart`、`test/pet_world_test.dart` |

每個全新 handler 至少驗證：

- start 初始狀態。
- 關鍵 phase boundary 前、當下、之後。
- large tick threshold crossing。
- effect 次數與順序。
- live retarget 後效果作用於新 target。
- natural completion 與四種 interruption。
- payload/target retention 或清除策略。

新增 `pet_behavior_catalog_test.dart` 時，至少鎖定：每個 profile 引用的 action
都有 definition、definition key 與 action 一致、animation key 非空、trigger 引用
的 action 存在且屬於正確 profile、stimulus/content/target 限制一致、同 priority
維持 catalog order。若此次只擴充既有 selector test，也必須覆蓋相同 invariants，
不可只測最後選出的 action。

## 5. 完成條件

提交前逐項確認：

- [ ] Catalog action、分類、profile、trigger 與 capability 正確。
- [ ] Executor 對 target/payload/status/reason 有精確測試。
- [ ] ignored 路徑零 runtime call，且不改變 active action。
- [ ] 新 runtime action 有且只有一個 fresh handler factory。
- [ ] Handler 不依賴 controller、Widget、chat DTO 或 animation catalog。
- [ ] Room reset、pet switch、replacement、target removal 無殘留狀態。
- [ ] Reconciliation/scroll 後使用 live target，elapsed 不重置。
- [ ] Snapshot 深不可變，Overlay 每 build 只讀一次。
- [ ] Sprite 尺寸、頭身比例、基線、cadence 經靜態與動態驗證。
- [ ] App 完整重啟驗證；不可只用 hot reload 驗證新 assets。
- [ ] Peer review 通過，依 `docs/git-commit-gate.md` 解決所有 Critical 與
  Important finding；團隊若採更嚴格分級，也需處理其阻擋級別。
- [ ] 執行 `./scripts/commit_gate.sh`。

## 6. 禁止事項

- 不因增加動作而把 timeline 寫回 `PetWorldController`。
- 不讓 catalog 直接控制 sprite frame。
- 不把 target 啟動時座標當成永久座標。
- 不在 plan 保存 mutable runtime/UI object。
- 不用 handler 間共享可變 singleton；每次 activation 建立新 instance。
- 不以 fallback 假裝 native capability。
- 不新增圖資卻宣稱已有不同視覺動作。
- 未經獨立架構決策，不引入 Flame、Forge2D 或另一套平行 runtime。
