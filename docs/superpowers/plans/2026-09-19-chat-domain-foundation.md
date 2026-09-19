# Chat Domain Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add immutable chat domain models and repository contracts for text, image, and video messages without changing current fake UI behavior.

**Architecture:** Add new domain-first models beside legacy demo models. Keep transport, API DTOs, WebSocket events, and media upload implementations out of the domain. Later phases can migrate the UI and inject fake adapters through these contracts.

**Tech Stack:** Flutter/Dart, Freezed, JSON serialization, Flutter test.

**Spec:** `docs/chat-message-architecture.md`

## Global Constraints

- Fake adapters remain future Phase 2 work.
- Riverpod integration remains future Phase 3 work.
- Domain models must not import Gespraech DTOs or backend message type numbers.
- GIF is image content with MIME `image/gif`.
- Supported media MIME types are `image/jpeg`, `image/png`, `image/gif`, `image/webp`, `video/mp4`, and `video/quicktime`.
- Existing `ChatShell`, pet behavior, and legacy fake room rendering must keep compiling unchanged.

### Task 1: Add code-generation dependencies

**Files:**
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock` through `flutter pub get`

**Interfaces:**
- Produces Freezed and JSON serialization packages for domain model generation.

- [x] **Step 1: Add runtime and dev dependencies**

Add `freezed_annotation` and `json_annotation` under dependencies. Add `build_runner`, `freezed`, and `json_serializable` under dev dependencies.

- [x] **Step 2: Resolve packages**

Run `flutter pub get` and confirm dependency resolution succeeds.

- [x] **Step 3: Verify analyzer baseline**

Run `flutter analyze`. Expected: no new issues.

### Task 2: Define immutable message domain models

**Files:**
- Create: `lib/chat/domain/message_content.dart`
- Create: `lib/chat/domain/message_status.dart`
- Create: `lib/chat/domain/chat_message.dart`
- Create: `lib/chat/domain/chat_room.dart`
- Create: `lib/chat/domain/message_draft.dart`
- Create: generated `.freezed.dart` and `.g.dart` files through build runner
- Test: `test/chat_message_domain_test.dart`

**Interfaces:**
- `MessageContent.text({String text})`
- `MessageContent.image({String url, String mimeType, String? localPath})`
- `MessageContent.video({String url, String mimeType, String? localPath, String? thumbnailUrl, int? durationMs})`
- `MessageDeliveryStatus.pending/uploading/sending/sent/failed`
- `ChatMessage({String clientId, String? serverId, String roomId, String senderId, MessageContent content, MessageDeliveryStatus status, DateTime createdAt, DateTime? serverCreatedAt, double uploadProgress, String? error, bool isMine})`
- `ChatRoom({String id, String name, String subtitle})`
- `MessageDraft({String clientId, String roomId, String senderId, MessageContent content, DateTime createdAt, bool isMine})`

- [x] **Step 1: Write failing domain tests**

Cover content union construction, default delivery status, client/server identity, upload progress, and JSON round-trip for text/image/video values.

- [x] **Step 2: Run domain tests and verify expected failure**

Run `flutter test test/chat_message_domain_test.dart`. Expected: missing-library or missing-symbol failure before implementation.

- [x] **Step 3: Implement Freezed models**

Use separate files and `part` directives. Keep `MessageContent` as a sealed union. Add `fromJson` factories for generated JSON support. Use defaults only for `pending`, `uploadProgress = 0`, and `isMine = false`.

- [x] **Step 4: Generate code**

Run `dart run build_runner build --delete-conflicting-outputs`.

- [x] **Step 5: Run domain tests**

Run `flutter test test/chat_message_domain_test.dart`. Expected: all tests pass.

### Task 3: Add media policy and repository contracts

**Files:**
- Create: `lib/chat/domain/media_policy.dart`
- Create: `lib/chat/domain/message_repository.dart`
- Modify: `test/chat_message_domain_test.dart`

**Interfaces:**
- `MediaPolicy.isSupportedMimeType(String mimeType) -> bool`
- `MediaPolicy.kindForMimeType(String mimeType) -> MediaKind?`
- `MediaPolicy.isSupportedExtension(String pathOrExtension) -> bool`
- `MessageRepository.loadMessages(String roomId) -> Future<List<ChatMessage>>`
- `MessageRepository.watchIncomingMessages() -> Stream<ChatMessage>`
- `MessageRepository.send(MessageDraft draft, {void Function(double progress)? onUploadProgress}) -> Future<ChatMessage>`

- [x] **Step 1: Add failing media policy tests**

Assert acceptance of JPG, PNG, GIF, WebP, MP4, MOV and rejection of unsupported types. Assert GIF maps to `MediaKind.image` and MOV maps to `MediaKind.video`.

- [x] **Step 2: Run tests and verify expected failure**

Run `flutter test test/chat_message_domain_test.dart`. Expected: missing `MediaPolicy` symbols.

- [x] **Step 3: Implement media policy**

Normalize MIME and extension input to lowercase. Treat `.jpg` and `.jpeg` as `image/jpeg`; `.mov` as `video/quicktime`. Do not add file I/O or upload behavior.

- [x] **Step 4: Define repository interface**

Expose domain types only. Do not expose `FormData`, `MultipartFile`, WebSocket channel types, API DTOs, or backend numeric message types.

- [x] **Step 5: Run focused tests and analyzer**

Run `flutter test test/chat_message_domain_test.dart` and `flutter analyze`. Expected: all tests pass and no analyzer issues.

### Task 4: Review compatibility boundary

**Files:**
- Inspect: `lib/chat/domain/chat_models.dart`
- Inspect: `lib/chat/data/fake_chat_repository.dart`
- Inspect: `lib/chat/presentation/chat_shell.dart`
- Modify: `docs/chat-message-architecture.md` only if implementation details differ

- [x] **Step 1: Confirm legacy demo remains unchanged**

Run `flutter test`. Existing fake-room, pet-world, and widget tests must remain green.

- [x] **Step 2: Confirm no transport coupling**

Search new domain files for `dio`, `web_socket_channel`, `FormData`, `Gespraech`, or backend message type numbers. Expected: no matches.

- [x] **Step 3: Record Phase 1 boundary**

Report that models and contracts exist but are not yet wired into `ChatShell`; wiring belongs to Phase 2–4.
