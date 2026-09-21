# Agent Guidance

## Chat message architecture

Read [docs/chat-message-architecture.md](docs/chat-message-architecture.md)
before changing chat message sending, receiving, media handling, Riverpod
state, DTOs, repositories, or WebSocket behavior.

Read [docs/chat-room-ui-ux-spec.md](docs/chat-room-ui-ux-spec.md) before
changing chat room layout, message rendering, composer behavior, media states,
or pet-overlay interaction.

Read [docs/handoff/chat-room-ui-handoff.md](docs/handoff/chat-room-ui-handoff.md)
when continuing chat room UI, provider, fake-adapter, or pet-bubble work from
the current Phase 4 baseline.

Read [Firebase Chat Backend 規格書](docs/specs/2026-09-19-firebase-chat-backend-spec.md)
before changing backend composition, Auth, Firestore, Storage, Functions, or
Firebase migration boundaries.

Read [Chat Room UI/UX 體驗優化報告](docs/reviews/2026-09-19-chat-uiux-review.md)
before changing chat interaction, accessibility, media recovery, scrolling, or
responsive layout.

Read [寵物與聊天訊息泡泡互動設計參考指南](docs/references/pet-bubble-interaction-reference.md)
when ideating, designing, or implementing pet-message bubble interactions,
physical/emotional reactions, lifecycle animations, gamification, or Flutter
overlay architecture.

Read [寵物動作新增指南](docs/pet-action-authoring-guide.md) before adding or
changing pet behavior catalog entries, triggers, action plans, runtime actions,
timeline handlers, lifecycle/retargeting behavior, animation mappings, sprite
assets, or pet presentation state. Follow its tests and completion checklist;
do not add action timelines back to `PetWorldController` or introduce a
parallel runtime.

Before commit, follow [Git Commit Gate](docs/git-commit-gate.md): peer review
first, then run the automated gate. Repository hook lives at `.githooks`.

Current direction:

- Build and validate UI flow with replaceable fake adapters first.
- Keep domain models independent from backend DTOs and wire-level message type numbers.
- Use Riverpod for dependency injection, lifecycle, room state, send state, and upload progress.
- Use Freezed for immutable domain models, DTOs, state, and content unions.
- Keep backend composition replaceable; current default remains fake-first until
  authenticated Dio/WebSocket providers are supplied.
- Video playback uses `video_player`; connection state supports reconnect and
  offline UI. Delay Drift, offline persistence, and resumable uploads.

## Testing & Model Tier Guidelines (測試與模型分級原則)

- **機械化測試與回歸驗證（Mechanical Tests & Regressions）**：
  - 例行性的測試執行（`flutter test`、`flutter analyze`）、單元測試除錯、靜態代碼檢查、語法修復、機械化重構或日誌比對等任務，建議指派或使用較輕量/低階的模型（如 `flash` / `flash_lite`）運作即可，兼顧快速反饋與節省資源。
  - 核心架構設計、跨端協議制定、複雜多模態或深層邏輯推導任務，才指派或使用高階模型（如 `pro` / 主模型）。
