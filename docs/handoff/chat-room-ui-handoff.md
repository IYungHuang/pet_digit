# Chat Room UI Handoff

Date: 2026-09-19
Status: Phase 9 transport adapters and connection UI complete; fake provider remains active

## Current result

Chat room now runs through Riverpod, Native Media Picker, Media Validation Policy, and replaceable fake/remote adapters.

Supported UI flows:

- Room switching.
- Text composer and optimistic text send.
- Native image and video attachment flow via `image_picker` (Photo Gallery, Camera, Video Gallery, Camera Video).
- Preset demo image/video attachments for automated tests and desktop simulators.
- Strict media format validation via `MediaPolicy` (accepts `image/jpeg`, `image/png`, `image/gif`, `image/webp`, `video/mp4`, `video/quicktime`; rejects unsupported formats with SnackBar feedback without clearing composer text).
- 50MB file-size limit enforced before draft creation.
- Real local image preview (`Image.file`) and remote/asset image preview in message cards.
- Interactive `ImagePreviewDialog` with zoom & pan (`InteractiveViewer`).
- Video message cards with duration badge, play action, and `VideoPlayerBoundaryDialog` backed by `video_player` for local files and HTTP/HTTPS URLs; unavailable fake sources show an explicit fallback.
- Replaceable Dio `message/add` adapter for text, image, and video multipart requests; upload progress is reported through existing repository callback.
- Replaceable WebSocket adapter for Gespraech `OnMessageReceivedData` envelopes, including text/image/video mapping and unsupported-type filtering.
- Connection state stream and banner for connecting, reconnecting, offline, error, and disconnected states; WebSocket adapter retries dropped connections with exponential backoff and enters offline after the configured attempt cap.
- Uploading, sending, failed, and retry states with inline progress indicator.
- Scrollable message history.
- Fixed bottom composer.
- Pet interaction for every rendered message bubble (text, emoji, image, video).

## Architecture entry points

- [Architecture](../chat-message-architecture.md)
- [UI/UX spec](../chat-room-ui-ux-spec.md)
- [Implementation Plan](../superpowers/plans/2026-09-19-chat-media-picker-preview.md)
- [Media policy](../../lib/chat/domain/media_policy.dart)
- [Media picker service](../../lib/chat/application/media_picker_service.dart)
- [Riverpod providers](../../lib/chat/presentation/chat_providers.dart)
- [Media preview dialogs](../../lib/chat/presentation/widgets/media_preview_dialog.dart)
- [Video player dialog](../../lib/chat/presentation/widgets/video_player_dialog.dart)
- [Dio message adapters](../../lib/chat/data/remote/dio_message_data_sources.dart)
- [WebSocket message adapter](../../lib/chat/data/remote/web_socket_message_event_source.dart)
- [Remote message mapper](../../lib/chat/data/remote/remote_message_mapper.dart)
- [Chat shell](../../lib/chat/presentation/chat_shell.dart)
- [Pet bubble wrapper](../../lib/pet/domain/pet_message_bubble.dart)

## Message flow

```text
ChatShell
  -> MediaPickerService (ImagePicker / Fake)
  -> MediaPolicy validation
  -> roomMessagesProvider(roomId)
  -> MessageRepository
  -> Fake remote/upload/event adapters (default UI wiring)
  -> Dio/WebSocket adapters (available for backend composition)
```

Composer sends `MessageDraft`. Repository owns optimistic insertion, upload
progress, status transitions, retry identity, and deduplication.

## Pet interaction flow

Every domain `ChatMessage` becomes `PetMessageBubbleTarget`.

- text -> platform/jump
- emoji-only text -> emoji toy/pounce
- image/video -> animated target/observe

Rendered bubble bounds use `clientId`, so late-arriving and newly sent messages
remain interactable. Pet bounds synchronization remains active across media card
rendering and status transitions.

## Run and verify

```bash
flutter pub get
flutter run -d macos
flutter test
flutter analyze
```

Current verification: 53 tests passed; analyzer clean.

### Platform notes (macOS Desktop)
- App Sandbox requires `<key>com.apple.security.files.user-selected.read-only</key><true/>` in both `DebugProfile.entitlements` and `Release.entitlements` to read files chosen by the user in Finder via `image_picker`.
- `image_picker_macos` delegates to Finder file selection (camera is not implemented on desktop; application layer catches this and guides the user to select local files).

## Next work

1. Compose authenticated Dio/WebSocket instances in production provider.
2. Validate live backend response fields and reconnect/backoff policy against staging.
3. Add unread boundary, pagination, and persistence only when product scope requires them.

## Important boundaries

- UI must depend on providers/repository/media picker service, never directly on transport or native platform channels.
- Pet wrapper must remain keyed by domain `clientId`.
- Keep `MessageContent` independent from API message type numbers.
