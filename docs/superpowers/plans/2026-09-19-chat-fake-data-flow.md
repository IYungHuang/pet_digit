# Chat Fake Data Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build behavior-oriented fake message adapters that exercise optimistic send, media progress, failure/retry, incoming events, deduplication, and connection lifecycle.

**Architecture:** `FakeMessageRepository` owns domain message identity, ordering, optimistic state, and event merge. Fake remote, upload, and event-source adapters implement replaceable data contracts and remain independent from UI and Riverpod.

**Tech Stack:** Dart, Flutter test, existing Freezed domain models.

**Spec:** `docs/chat-message-architecture.md`

## Global Constraints

- Do not modify `ChatShell`, pet behavior, or existing legacy fake room models.
- Do not add Riverpod in Phase 2; that is Phase 3.
- Do not add Dio, WebSocket transport, Drift, or backend DTOs.
- Repository exposes domain models only.
- `clientId` is stable across retry and optimistic-to-server merge.
- Duplicate incoming events must not duplicate ordered messages.

### Task 1: Expand repository lifecycle and adapter contracts

**Files:**
- Modify: `lib/chat/domain/message_repository.dart`
- Create: `lib/chat/data/message_data_sources.dart`

**Interfaces:**
- `MessageRepository.connect() -> Future<void>`
- `MessageRepository.disconnect() -> Future<void>`
- `MessageRepository.watchRoomMessages(String roomId) -> Stream<List<ChatMessage>>`
- `MessageRemoteDataSource.send(MessageDraft draft) -> Future<RemoteMessageReceipt>`
- `MediaUploadDataSource.upload(MessageDraft draft, {void Function(double progress)? onProgress}) -> Future<MessageContent>`
- `MessageEventSource.events() -> Stream<ChatMessage>`
- `MessageEventSource.connect() -> Future<void>`
- `MessageEventSource.disconnect() -> Future<void>`

- [x] **Step 1: Write failing contract compile/test usage**
- [x] **Step 2: Run focused test and verify missing fake contract failure**
- [x] **Step 3: Add domain-only adapter contracts**
- [x] **Step 4: Run analyzer**

### Task 2: Implement fake adapters

**Files:**
- Create: `lib/chat/data/fake/fake_message_remote_data_source.dart`
- Create: `lib/chat/data/fake/fake_media_upload_data_source.dart`
- Create: `lib/chat/data/fake/fake_message_event_source.dart`

**Behavior:**
- configurable latency
- `failNextSend`
- deterministic server IDs
- media progress callbacks
- fake remote URLs
- connect/disconnect gating
- incoming and duplicate event emission

- [x] **Step 1: Add failing adapter behavior tests**
- [x] **Step 2: Run tests and verify expected failures**
- [x] **Step 3: Implement minimal fake adapters**
- [x] **Step 4: Run focused adapter tests**

### Task 3: Implement fake repository state machine

**Files:**
- Create: `lib/chat/data/fake/fake_message_repository.dart`
- Create: `test/fake_message_repository_test.dart`

**Behavior:**
- pending insertion before network await
- text `pending → sending → sent`
- media `pending → uploading → sending → sent`
- failed status retains client ID and retry data
- retry upserts existing client ID
- incoming event merge by server ID, then client ID
- stable room ordering
- room-scoped stream updates

- [x] **Step 1: Write failing repository tests**
- [x] **Step 2: Run tests to verify expected failure**
- [x] **Step 3: Implement keyed in-memory state**
- [x] **Step 4: Run repository tests**

### Task 4: Full regression gate

**Files:**
- Modify: `docs/chat-message-architecture.md` status only
- Modify: this plan checkboxes

- [x] **Step 1: Run `flutter test`**
- [x] **Step 2: Run `flutter analyze`**
- [x] **Step 3: Run `dart run build_runner build`**
- [x] **Step 4: Confirm no UI or pet files changed**
- [x] **Step 5: Mark Phase 2 complete and Phase 3 pending**
