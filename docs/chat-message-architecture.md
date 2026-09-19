# Chat Message Architecture

Status: Phase 4 UI slice complete; native media picker and backend pending

Date: 2026-09-19

Scope: text messages, images (`jpg`, `png`, `gif`, `webp`), and videos (`mp4`, `mov`).

## 1. Purpose

Move chat from static local demo data toward a real message flow without coupling
the UI or domain model to the reference `gespraech` project's API, WebSocket, or
database implementation.

First milestone uses fake adapters. Later, fake adapters are replaced by
`gespraech`-compatible adapters without changing UI, application state, or
domain models.

## 2. Architectural boundary

```text
UI
  ↓
Riverpod providers/notifiers
  ↓
MessageRepository
  ├── MessageRemoteDataSource
  ├── MediaUploadDataSource
  └── MessageEventSource
        ├── Fake adapter
        └── Gespraech adapter
```

Rules:

1. UI never calls Dio, WebSocket, or a data source directly.
2. Domain never imports API DTOs, WebSocket event DTOs, or database models.
3. Fake and remote implementations share interfaces.
4. Runtime message flow owns optimistic updates and deduplication.
5. One app-scoped event source owns WebSocket lifecycle. Room providers only
   select and consume room-scoped events.

## 3. Proposed project layout

```text
lib/chat/
├── domain/
│   ├── chat_message.dart
│   ├── chat_room.dart
│   ├── message_content.dart
│   ├── message_status.dart
│   └── message_repository.dart
│
├── application/
│   ├── message_state.dart
│   ├── room_messages_notifier.dart
│   └── message_composer_notifier.dart
│
├── data/
│   ├── dto/
│   ├── mappers/
│   ├── fake/
│   │   ├── fake_message_remote_data_source.dart
│   │   ├── fake_media_upload_data_source.dart
│   │   └── fake_message_event_source.dart
│   └── remote/
│       ├── gespraech_message_data_source.dart
│       ├── gespraech_media_upload_data_source.dart
│       └── gespraech_message_event_source.dart
│
└── infrastructure/
    ├── dio_client.dart
    └── websocket_client.dart
```

Do not create a separate use-case class for every action in first milestone.
`MessageRepository` plus two Notifiers is enough until behavior becomes
independently reusable.

## 4. Domain model

### Message content

Use an immutable Freezed union:

```dart
@freezed
sealed class MessageContent with _$MessageContent {
  const factory MessageContent.text({
    required String text,
  }) = TextMessageContent;

  const factory MessageContent.image({
    required String url,
    required String mimeType,
    String? localPath,
  }) = ImageMessageContent;

  const factory MessageContent.video({
    required String url,
    required String mimeType,
    String? localPath,
    String? thumbnailUrl,
    int? durationMs,
  }) = VideoMessageContent;
}
```

GIF is an image content with `image/gif`, not a separate domain kind.

Supported MIME types:

```text
image/jpeg
image/png
image/gif
image/webp
video/mp4
video/quicktime
```

File extension is picker/UI fallback only. Validation should use MIME and, when
available, file signature/content inspection.

### Delivery status

```dart
enum MessageDeliveryStatus {
  pending,
  uploading,
  sending,
  sent,
  failed,
}
```

`ChatMessage` must retain:

```text
clientId          local stable ID / optimistic identity
serverId          nullable backend message ID
roomId
sender
content
status
uploadProgress    nullable, per message
createdAt
serverCreatedAt   nullable
error             nullable user-facing failure state
```

`clientId` remains after server acknowledgement. It is required to merge a
WebSocket echo with the optimistic local message.

## 5. Interfaces

Names may change during implementation, but responsibilities must remain:

```dart
abstract interface class MessageRemoteDataSource {
  Future<RemoteSendResult> sendText(RemoteTextDraft draft);
  Future<RemoteSendResult> sendImage(RemoteImageDraft draft);
  Future<RemoteSendResult> sendVideo(RemoteVideoDraft draft);
}

abstract interface class MediaUploadDataSource {
  Stream<double> upload({
    required String clientId,
    required String localPath,
    required String mimeType,
  });
}

abstract interface class MessageEventSource {
  Stream<IncomingMessageEvent> events();
  Future<void> connect();
  Future<void> disconnect();
}
```

`MessageRepository` maps these data sources into domain messages and owns:

- optimistic insertion
- acknowledgement merge
- failure mapping
- per-message progress
- server/client ID deduplication
- room event routing

## 6. Riverpod responsibilities

Use Riverpod now because the feature has independent lifecycles:

```text
messageRepositoryProvider
messageEventSourceProvider
roomMessagesProvider(roomId)
messageComposerProvider(roomId)
uploadProgressProvider(clientId)
connectionStateProvider
```

Expected lifecycle:

```text
ProviderScope
  → app-scoped event source connects once
  → room provider loads room messages
  → room provider consumes room-filtered events
  → leaving room disposes room subscription
  → event source remains alive
```

Use `autoDispose` for room providers in first milestone. Add cache retention or
Drift only when product requirements need it.

Avoid:

- repository creation inside widgets
- one WebSocket per room
- UI direct access to Dio or WebSocket
- one global upload progress value

## 7. Message flows

### Text

```text
create clientId
  → insert pending message
  → remote.sendText
  → success: merge serverId/serverCreatedAt, status = sent
  → failure: status = failed, retain retry data
```

### Image / video

```text
pick and validate file
  → insert pending message
  → status = uploading
  → upload with clientId-scoped progress
  → status = sending
  → send message metadata
  → success: merge remote fields, status = sent
  → failure: status = failed, retain localPath for retry
```

Progress must be keyed by `clientId`. Multiple concurrent uploads must not
overwrite each other.

## 8. WebSocket and deduplication

One app-scoped event source dispatches incoming events by `roomId`.

Deduplication priority:

```text
serverId
  → clientId / tempUid
  → fallback: roomId + sender + timestamp + content hash
```

When an echo matches a pending message:

```text
merge server fields
retain local ordering
status = sent
do not append a second row
```

The message store must not rely on an append-only `List<ChatMessage>`. It needs
keyed identity plus stable ordering:

```text
Map<serverId, ChatMessage>
Map<clientId, ChatMessage>
ordered message IDs
```

Fake event source must support duplicate event emission so this behavior is
validated before backend integration.

## 9. Fake adapters

Static `FakeChatRepository` is not the final abstraction. It can remain as seed
data during migration, but new flow must use behavior-oriented fake adapters.

Fake adapters must support:

```text
send text
send image
send video
configurable latency
configurable upload progress
configurable next-send failure
incoming event emission
duplicate event emission
connect/disconnect state
```

Useful test controls:

```dart
fake.failNextSend = true;
fake.uploadStep = const Duration(milliseconds: 50);
fake.emitIncoming(message);
fake.emitDuplicate(message);
```

## 10. Gespraech replacement boundary

The later remote adapter maps the reference project contract:

```text
POST /api/chatroom/message/add

type 0 = text
type 2 = image
type 6 = video
```

Reference project uses `tempUid` for optimistic message correlation and emits
`OnMessageReceivedData(roomId, param, unreadMessageCount)` over WebSocket.

These wire details stay inside `data/remote` and mappers. Domain code must not
contain numeric backend message types or Gespraech DTO imports.

Before remote integration, verify against the real backend contract:

- multipart field names
- accepted MIME and size limits
- `tempUid` format
- send response fields
- WebSocket envelope and auth
- reconnect and token refresh behavior

## 11. Package decisions

### Introduce now

```text
flutter_riverpod
freezed_annotation
json_annotation
dio
web_socket_channel
```

Development code generation:

```text
freezed
json_serializable
build_runner
```

### Delay

```text
drift                 persistence/offline requirement not yet in scope
retrofit              API contract still being validated
full video player     UI can start with a video placeholder
resumable upload      not required for fake-first milestone
```

## 12. Delivery phases

### Phase 1 — Domain foundation

Create immutable domain models, content union, delivery status, repository
interfaces, and MIME validation policy.

### Phase 2 — Fake data flow

Create fake remote, upload, and event adapters. Support optimistic send,
progress, failure, retry data, incoming events, and duplicate events.

### Phase 3 — Riverpod integration

Add `ProviderScope`, repository providers, app-scoped event source, room message
provider, and composer provider.

### Phase 4 — Message UI

Render text, image, and video placeholder states. Show pending, uploading,
progress, sent, failed, and retry states.

### Phase 5 — Lifecycle and dedupe

Verify room switching, event cleanup, reconnect state, client ID merge, server ID
dedupe, and stable message ordering.

### Phase 6 — Gespraech adapters

Replace fake data sources with API, multipart upload, and WebSocket adapters.
Keep domain and application layers unchanged.

## 13. Non-goals for first milestone

- Drift database
- offline-first recovery
- resumable uploads
- Retrofit generation
- full video playback
- threads
- reactions
- pagination
- read receipts
- all reference-project message types

## 14. Acceptance criteria

Before backend integration, the fake implementation must prove:

1. Text send appears immediately as pending and becomes sent or failed.
2. Image/video send exposes independent per-message upload progress.
3. JPG, PNG, GIF, WebP, MP4, and MOV are accepted by policy.
4. Unsupported media is rejected before upload.
5. Retry reuses local message identity and does not append duplicates.
6. Incoming events update the correct room.
7. Duplicate WS events do not duplicate UI messages.
8. Room switching does not create duplicate event subscriptions.
9. UI imports application/domain interfaces only, not transport details.
10. Replacing fake adapters with remote adapters requires no UI rewrite.
