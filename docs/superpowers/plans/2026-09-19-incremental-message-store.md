# Incremental Message Store Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace full-room message snapshot refresh with delta-based client synchronization that preserves chat UI state during reconnects.

**Architecture:** `MessageDelta` is the transport-neutral event contract. A room-scoped `MessageStore` owns normalized messages, deduplication, ordering, and projections. Riverpod exposes store projections; fake adapters emit deltas so Firebase can later replace only the data source.

**Tech Stack:** Dart, Flutter, Riverpod, Freezed domain models, Flutter test.

**Spec:** `docs/specs/2026-09-19-firebase-chat-backend-spec.md`

## Global Constraints

- UI never calls a data source directly.
- Message synchronization uses delta merge, not full-list replacement.
- `clientId` remains optimistic identity; `serverId` remains canonical identity.
- Reconnect preserves store, scroll state, drafts, and pending messages.
- Firebase adapter is out of scope for this phase.
- Existing text, image, video, pet interaction, and media upload behavior must remain intact.

---

### Task 1: Add delta contract and normalized message store

**Files:**
- Create: `lib/chat/application/message_delta.dart`
- Create: `lib/chat/application/message_store.dart`
- Create: `test/message_store_test.dart`

**Interfaces:**
- Produces `MessageDelta.added`, `.modified`, `.removed`.
- Produces `MessageStore.apply(MessageDelta)`, `mergeInitial(Iterable<ChatMessage>)`, and `messagesForRoom(String)`.

- [x] Write failing tests for add, modify, remove, client/server dedupe, and stable ordering.
- [x] Run `flutter test test/message_store_test.dart` and confirm failure because contracts do not exist.
- [x] Implement minimal immutable delta types and mutable store with indexes.
- [x] Run focused tests until green.

### Task 2: Convert fake repository and event source to deltas

**Files:**
- Modify: `lib/chat/data/message_data_sources.dart`
- Modify: `lib/chat/data/fake/fake_message_event_source.dart`
- Modify: `lib/chat/data/fake/fake_message_repository.dart`
- Modify: `test/fake_message_repository_test.dart`

**Interfaces:**
- `MessageEventSource.deltas()` returns `Stream<MessageDelta>`.
- Repository emits deltas into room stores and keeps send/optimistic behavior.

- [x] Add failing tests proving duplicate events do not create duplicate room messages and reconnect does not emit a full room snapshot.
- [x] Run focused fake repository tests and verify failure.
- [x] Implement delta emission and store-backed room projection.
- [x] Run focused tests until green.

### Task 3: Rewire Riverpod providers around store projections

**Files:**
- Modify: `lib/chat/presentation/chat_providers.dart`
- Modify: `lib/chat/domain/message_repository.dart`
- Modify: `test/chat_riverpod_test.dart`

**Interfaces:**
- `roomMessagesProvider(roomId)` remains UI-compatible as a list projection.
- Connection lifecycle must not invalidate or recreate message store state.

- [x] Add failing provider test for live delta merge while preserving existing message state.
- [x] Run `flutter test test/chat_riverpod_test.dart` and verify failure.
- [x] Implement app-scoped repository/store lifecycle and projection provider.
- [x] Run focused provider tests until green.

### Task 4: Remove full-refresh reconnect path from ChatShell

**Files:**
- Modify: `lib/chat/presentation/chat_shell.dart`
- Modify: `test/chat_shell_test.dart`

**Interfaces:**
- Reconnect triggers connection recovery only.
- Timeline consumes updated projection without replacing scroll controller state.

- [x] Add failing widget test for reconnect retaining message list and scroll offset.
- [x] Run focused widget test and verify failure.
- [x] Remove message reload invalidation and keep existing scroll restoration only as compatibility guard.
- [x] Run focused widget tests until green.

### Task 5: Add regression gate and complete verification

**Files:**
- Modify: `test/chat_riverpod_test.dart`
- Modify: `test/chat_shell_test.dart`
- Modify: `test/fake_message_repository_test.dart`

- [x] Add regression coverage for optimistic pending merge, reconnect, duplicate delta, media send, and pet message wrappers.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Run `git diff --check`.
- [x] Review diff and report any unrelated working-tree changes without staging them.
