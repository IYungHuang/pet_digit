# 2026-09-19 Evening Handoff

## 1. Session state

晚間從本文件接續。先處理 backend Round 4 blockers，再執行 Flutter pet behavior plan。

Workspace:
`/Users/appgongyong/Documents/Codex/2026-09-18/referenced-chatgpt-conversation-this-is-an`

Backend:
`/Users/appgongyong/Documents/Codex/2026-09-18/pet_digit_backend`

## 2. Backend status

Latest backend commit:

`f86938bf565709b97ca961e92c73c05e471c059c`

Round 4 senior review verdict:

```
REQUEST CHANGES
Production deploy: BLOCK
```

已完成：onSchedule recovery、staging TTL、orphan finalized cleanup、lease state machine、grace period、structured cleanup errors、thumbnail Option B、filename required、Storage metadata validation、sender-only tombstone、inactive member/replay/checksum/Rules hardening、Pub/Sub Emulator scheduler wiring。

### C-1 Critical：併發 replay regression

相同 `clientId` request 併發時，第二個 request 直接收到 `Request is already processing`。先前 `waitForReplay` 被移除。

修正：claim active 時 bounded polling，每 50ms 一次；500–1000ms timeout；committed 回傳同一 canonical message；failed/expired 依 retry policy 重試；timeout 回傳 `failed-precondition`。不可無限等待、不可建立第二筆 canonical message。

### H-1 High：recovery 無界查詢

目前 `collectionGroup('clientRequests').get()` 全表掃描。

修正：`leaseUntil <= now`、bounded limit、cursor/pagination、Firestore composite index，下一輪 scheduler 繼續剩餘資料。

### H-2 High：checksum 全檔載入記憶體

目前 finalize 使用 `object.download()`。

修正：`createReadStream()` + streaming SHA-256；處理 stream error、missing object、mismatch；明確 Function memory、timeout、concurrency。

### M-1 / M-2 / L-1

- M-1：評估合併 `reserved → processing` transaction，不得犧牲 lease/retry/replay/canonical uniqueness。
- M-2：orphan cleanup 分批、限制並行度、individual failure isolation、保留 grace period。
- L-1：Storage Rules 先 `firestore.exists(...)`，再判斷 `active == true`。

## 3. Backend next action

交給 backend agent 修補 Round 4 findings。完成後必須執行：

```
npm run lint
npm run typecheck
npm run build
npm test
npm run test:rules
npm run test:integration
npm run verify
git diff --check
```

Gate：integration 全綠、`npm run verify` exit code 0、C-1 race test 通過、recovery/cleanup bounded、checksum streaming、Rules tests 通過。未通過前禁止 commit/push、禁止 production deploy。

通過後派第五次 senior backend review。

仍未完成：production Firebase project deploy、App Check registration、production Scheduler alerts、thumbnail generation/transcoding/CDN/Redis/FCM、npm dependency major upgrade。DNS 失敗時不得宣稱 audit clear。

## 4. Frontend pet behavior status

目標：把早上動物行為專家整理的 catalog 接成可執行 runtime。

既有資料：

- corgi、cat、parrot 一般動作各 10 種。
- 陌生物件／訊息泡泡互動各 8 種。
- `PetBehaviorCategory`、`PetStimulusType`、`PetBehaviorAction`、species profiles 已存在。

目前 runtime：

- `PetBehaviorCatalog`：data-only。
- `PetMessageBubbleTarget`：訊息泡泡可作為互動 target。
- `PetWorldController`：仍以固定 `PetActionType` 執行 jump、chase、inspect。

文件：

- [Design spec](../superpowers/specs/2026-09-19-pet-behavior-runtime-design.md)
- [Implementation plan](../superpowers/plans/2026-09-19-pet-behavior-runtime.md)

Spec peer review：`PASS WITH CONDITIONS`。

已處理：`newMessageBubble` / `userTap` 分離；保留 text → jump、emoji → chase/pounce、media → inspect；`PetMessageTargetFactory` 統一 legacy / Freezed message model；canonical identity `serverId ?? clientId`；payload 不由 executor 猜測；bounds readiness 與一次性 retry；selector metadata；capability 與 execution result 分離；Phase 1 native/degraded/unsupported boundary。

Implementation 順序：

1. runtime value objects 與 catalog metadata。
2. normalized message target factory。
3. pure selector 與 content normalization。
4. payload-aware executor，保留 legacy tap。
5. controller target migration、identity / bounds reconciliation。
6. new-message behaviors、integration tests、Flutter verification。

主要檔案：`lib/pet/domain/pet_behavior_catalog.dart`、`lib/pet/domain/pet_world_controller.dart`、`lib/pet/domain/pet_world.dart`、`lib/pet/domain/pet_message_bubble.dart`、`lib/chat/domain/chat_message.dart`、`lib/chat/domain/message_content.dart`、`lib/chat/domain/chat_models.dart`。

## 5. Git / review gate

固定流程：

```
施工 → focused tests → full verification → peer review → commit → push
```

Backend：Round 4 `REQUEST CHANGES`，下一輪 Round 5 senior backend review。

Frontend pet behavior：spec `PASS WITH CONDITIONS`，implementation 尚未開始，plan 已建立。

目前 spec / plan 因 `.git/index.lock` 權限限制尚未 commit；檔案已寫入 workspace。晚間先檢查 `git status --short` 與 `git diff --check`。不得使用 destructive git command。

## 6. Explicit non-goals

- 不提前開 Firebase production project。
- 不進行 production deploy。
- 不在 backend blocker 未修復前接真實 Firebase。
- 不重寫聊天同步架構。
- 不新增動畫素材或新 package。
- 不把 unsupported pet actions 靜默映射成錯誤動作。

## Appendix A — Firebase project setup

此節最後處理。Backend emulator 與 Flutter fake/emulator adapter 可在沒有 production Firebase project 的情況下施工；只有進入真實雲端整合時才需要 Firebase project。

### A.1 需要 Firebase project 的時機

尚未需要 project：backend unit/Rules/emulator integration、Flutter fake adapter、Flutter Firebase emulator adapter、pet behavior runtime、local scheduler/Pub/Sub emulator。

需要 project：production Firebase deploy、真實 Auth/Firestore/Storage、App Check registration/enforcement verification、production Cloud Scheduler、production Storage lifecycle/alerting、真實 Firebase client config。

### A.2 Project 建立 checklist

建立 dev/staging project，不直接使用 production project 做初次驗證：

1. Firebase Console 建立 project。
2. 啟用 Authentication provider。
3. 建立 Firestore database，確認 region。
4. 啟用 Cloud Storage，確認 bucket region。
5. 啟用 Cloud Functions 所需 billing plan。
6. 設定 Web/macOS/mobile Flutter app identifiers。
7. 產生並保存 FlutterFire configuration。
8. 設定 Firebase CLI project alias。
9. 設定 Functions runtime、region、memory、timeout、concurrency。
10. 建立 App Check provider，先 monitor，再 enforcement。
11. 設定 Scheduler/Pub/Sub production triggers。
12. 設定 logs、error alerts、scheduled job failure alerts。

### A.3 Secrets / access

- 不把 service account key、API secret、App Check secret commit 進 repo。
- 使用 Secret Manager / CI secret store。
- 最小權限授予 Firebase deploy identity。
- Flutter production config 與 emulator config 分離。
- emulator bypass 只能存在明確 emulator mode。

### A.4 Production deployment gate

Firebase project 建立後仍不可直接 deploy。先完成 Round 5 senior backend review PASS、clean emulator verification、deployment checklist review、App Check provider registration、Scheduler production wiring/alerts、Storage lifecycle policy、rollback/incident procedure。

最後才執行：

```
firebase use <dev-project>
firebase deploy --only firestore:rules,firestore:indexes,storage,functions
```

Production project、credentials、App Check、Scheduler 尚未建立；本 handoff 不代表已授權 production deploy.
