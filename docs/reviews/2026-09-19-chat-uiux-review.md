# Chat Room UI/UX 體驗優化報告

狀態：reviewed report
日期：2026-09-19
覆核者：主架構 agent

## 1. 覆核範圍

檢查 `ChatShell`、Riverpod providers、media dialogs、pet message wrapper、
UI/UX spec、handoff 與現有 widget tests。最新 gate 狀態：analyzer clean、
62 tests passed；handoff 內舊的 53 tests 數字需更新。

## 2. 已完成能力

- Riverpod repository/provider 與 fake-first composition。
- room switching、文字 optimistic send。
- 圖片/影片 picker、MIME 與 50 MiB validation。
- local/remote image preview、zoom/pan。
- `video_player` local/HTTP 播放邊界。
- pending/uploading/sending/failed/retry 基本呈現。
- connection state banner、WebSocket reconnect/offline adapter。
- 每個 `ChatMessage` 經 `PetMessageBubbleTarget` 包裝。
- scroll listener + post-frame pet bounds synchronization。
- macOS Finder picker 與 entitlements。

## 3. P0：可用性／可上線阻斷

### P0-1 Timeline 會無條件跳到底部

證據：`lib/chat/presentation/chat_shell.dart` message count 增加時直接
`jumpTo(maxScrollExtent)`。

影響：使用者閱讀歷史時，incoming message、retry 或 status 變更可能拉走畫面。

建議：

- 距離底部 80–120 logical px 才 auto-follow。
- 不在底部時顯示「有新訊息」 affordance，不改變 scroll offset。
- 自己送出訊息可強制 bring-into-view。
- status/progress 更新不得觸發 auto-scroll。

驗收：near-bottom follow、history position preserved、own-send visible、
upload progress 不位移。

### P0-2 Send button 未依 draft 狀態 disabled

證據：`_MessageComposer` 的發送 `IconButton.onPressed` 目前持續存在。

影響：空白文字仍呈現可按，keyboard/screen-reader 行為不一致。

建議：以 `ValueListenableBuilder<TextEditingValue>` 或 room draft state 控制；
`trim().isNotEmpty` 才啟用。全空白不可送出，輸入清空後立即 disabled。

### P0-3 Failed/offline 缺可理解 recovery

目前有 failed/reconnect/offline visual state，但 recovery action、錯誤原因、
retry busy state 不完整。

建議：

- failure reason 分為 offline、permission、format/size、server temporary。
- failed message 保留內容、位置與 clientId。
- retry 期間 disable duplicate tap。
- offline/error banner 提供「重新連線」。

### P0-4 Message/media/retry accessibility semantics 與 hit target

目前 message card 主要是 GestureDetector；media preview/play/retry controls
沒有一致的 message-level semantics，部分 icon hit area 小於 44×44 風險。

建議：

- message semantics 包含 sender、content type、summary、delivery state、action hint。
- media card/action 至少 44×44。
- retry 明確 label；decorative pet layer `IgnorePointer`。
- contrast、focus ring、text scale 200% 做測試。

若產品尚未承諾 WCAG AA，這項仍是 release quality gate，不應當作視覺 polish。

## 4. P1：高價值 UX 改善

### P1-1 Room state isolation

`_composerController` 與單一 `_scrollController` 屬 `ChatShell` state；切換房間
未保存 draft/offset。

建議：`roomDraftProvider(roomId)`、room-specific scroll offset map；切換前保存、
切回恢復。送出時 capture roomId，避免 draft 送錯房間。

### P1-2 Loading / empty / error states

目前 loading 只有 spinner，error 只有 raw error text，empty room 無專用狀態。

補 skeleton、empty invitation、retry action、unread boundary；unread separator
不是 Pet target。

### P1-3 Media picker capability filtering

macOS camera capability 不可用，但 picker action 可能仍暴露「拍照／錄影」。
fake attachment action 也不應混入 production UI。

依 capability provider 隱藏或 disabled；測試用 fake service injection，不靠 fake
UI 選項。

### P1-4 Video dialog 三態與內容

`VideoPlayerBoundaryDialog` 初始化尚未完成時目前可能直接顯示 unavailable；
`thumbnailUrl` 尚未用於 loading/error；dialog 顯示 raw path/MIME/engine debug
資料。

補 loading / success / error / retry；thumbnail 做 placeholder；production 隱藏
raw path、signed URL、engine details，debug-only 顯示診斷資訊。

### P1-5 Timeline / media layout 穩定性

network image loading 缺 loading state、retry、固定 geometry；media card 應保持
aspect ratio，避免列表 layout shift。影片控制項與 message body action 需清楚分工。

### P1-6 Connection scope 與 manual retry

`messageConnectionStateProvider` 是 family 但 room ID 未使用；connection 實際是
app/source scoped。改為明確 global provider，或讓 room-scoped lifecycle 真正成立。
error/offline 必須提供 manual reconnect，避免使用者只能等待 backoff。

### P1-7 Pet interaction 與 media action 分工

`_MessageCard` 整卡 GestureDetector 與 media preview/play/retry 同時存在，點擊語意
不明。建議 message body 觸發 pet；media body 開 preview/play；retry 只 retry；加
semantics hint 與 keyboard action。

### P1-8 Responsive / keyboard / safe area

需補 keyboard inset、safe-area、text scale、窄視窗 dialog overflow 測試。macOS
desktop 應有 720–900px centered content width、focus ring、hover、keyboard shortcuts；
mobile 與 desktop picker capability 不混用。

## 5. P2：後續 enhancement

- pagination、persistent offline queue、unread boundary 完整化。
- read receipts、reactions、replies。
- video mute/fullscreen/buffering/captions。
- desktop sidebar/雙欄 layout。
- reduce-motion、keyboard navigation、完整 VoiceOver/TalkBack flow。
- media thumbnail/transcoding、background upload resume。

## 6. 建議驗收順序

### P0

1. near-bottom auto-scroll + new-message affordance。
2. send disabled 與 room draft isolation 的最小安全行為。
3. failed/offline reason、retry、manual reconnect。
4. message/media/retry semantics 與 44×44 hit target。

### P1

1. room scroll/draft preservation。
2. loading/empty/error/retry/unread UI。
3. picker capability filtering、fake UI 移除。
4. video loading/error/thumbnail/debug visibility。
5. keyboard/safe-area/text scale/contrast tests。
6. desktop responsive layout。

## 7. 覆核結論

目前是可展示 vertical slice，不是完整 production chat UX。優先修行為穩定性、
recovery、accessibility，再做品牌視覺。最先做 P0-1 與 P0-2，因為會直接破壞
閱讀與發送信任；接著補 P0-3/P0-4，建立可恢復與可使用的基本品質。

## 8. 本輪施作結果

已完成 P0 與主要 P1：

- near-bottom auto-follow、歷史閱讀位置保留、新訊息 affordance。
- 空白訊息禁送、房間 draft／scroll isolation。
- failed/offline reason、retry busy state、manual reconnect。
- message semantics、44×44 media actions、demo attachment production 隔離。
- loading／empty／error/retry、camera capability filtering。
- video loading／success／error/retry、thumbnail placeholder、production 隱藏 raw path 與 engine details。
- app-scoped connection provider、desktop timeline max width。

驗證：`flutter analyze` clean、`flutter test` 68 tests passed、`git diff --check` passed。
P2 的 pagination、persistent offline queue、read receipts、reactions、desktop
sidebar 與 background upload resume 仍屬 backend／產品功能階段，未納入本輪 fake-first UI gate。
