# Phase 4: Chat Room UI Slice

## Goal

Connect Riverpod message flow to a usable chat room surface while preserving
pet overlay interactions.

## Delivered

- `ChatShell` migrated to `ConsumerStatefulWidget`.
- Room messages read from `roomMessagesProvider`.
- Text composer sends optimistic text messages.
- Fake image/video attachment chooser creates media drafts.
- Message cards render text, image, and video content variants.
- Upload/sending/failed states render inline; failed messages expose retry.
- Existing room selector, pet selector, and pet overlay remain functional.
- Fake repository seeds demo messages through the new domain model.

## Deferred

- Native image/video picker.
- Real image preview and video playback.
- Attachment size/duration validation UI.
- Keyboard-aware auto-scroll and unread boundary.
- Final visual polish and Figma component library.

## Acceptance

- [x] Existing room switching still works.
- [x] Existing pet interactions still work.
- [x] Text composer sends and displays optimistic message.
- [x] Fake image attachment displays media card.
- [x] Riverpod provider tests and widget tests pass.
