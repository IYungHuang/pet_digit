# Chat Room UI/UX Specification

Status: design baseline for Phase 3–4

## 1. Current baseline

Current screen uses `ChatShell`, local `setState`, legacy `ChatMessage`, and
`PetWorldOverlay`. Pet interaction reads rendered message-card bounds, so the
message list remains the source of truth for visible message targets.

New message domain already supports text, image, video, lifecycle status, and
upload progress. UI must consume that domain without coupling to fake or real
transport adapters.

## 2. Product goals

- Make text chat primary and fast.
- Treat image/video as first-class messages, not special text rows.
- Show sending, upload, failure, and retry states without losing message order.
- Keep pet reactions attached to visible message cards.
- Preserve room switching and support future incoming events.

## 3. Screen structure

```text
AppBar
  room name / subtitle
  pet selector
Room selector
Message timeline
  date or event separators when needed
  incoming/outgoing message bubbles
  media preview cards
  status/progress/error affordances
Pet overlay layer
Composer
  attachment button
  text field
  send button
```

Composer stays outside the scrollable message timeline. Pet overlay stays in
the same `Stack` as the timeline so it can continue to target message bounds.

## 4. Message presentation

### Text

- Incoming: light surface bubble, left aligned.
- Outgoing: purple accent bubble, right aligned.
- Preserve existing asymmetric bubble corners.
- Long text wraps; bubble max width approximately 78% of viewport.

### Image

- Rounded thumbnail/card with fixed aspect-ratio container.
- Local upload: show preview immediately when local path exists.
- Uploading: progress overlay and percentage or linear progress.
- Sent: remove progress overlay.
- Failed: preserve preview, show retry action and short error label.

### Video

- Same media card geometry as image.
- Show play icon and duration when available.
- Before player integration, tapping opens a placeholder preview state.
- Upload status behavior matches image.

### Status

Status is secondary to content and must not change card position:

```text
pending   -> subtle sending indicator
uploading -> progress overlay
sending   -> sending indicator
sent      -> optional delivery state
failed    -> error label + retry button
```

## 5. Composer behavior

- Empty text: send disabled.
- Text present: send enabled.
- Attachment action: choose supported image/video only.
- Unsupported type: inline, non-blocking error; keep composer content.
- Send creates optimistic message immediately and clears text input.
- Failed send keeps failed message in timeline; retry reuses same `clientId`.
- While media is uploading, composer remains usable for another message.

## 6. Room lifecycle

- Room switch preserves each room's message list and scroll position when
  practical.
- Initial load shows skeleton or compact loading state.
- Empty room shows an invitation/empty state, not a blank screen.
- Incoming event for inactive room updates unread state but does not force
  navigation.
- Re-entering room scrolls to latest unread boundary.

## 7. Pet interaction contract

- Every rendered message card exposes stable `clientId` as its target key.
- Every domain message is wrapped by `PetMessageBubbleTarget`; no message is
  excluded because it arrived after initial room seed data.
- Pet overlay receives bounds after list layout and scroll changes.
- Message status changes update card content in place; avoid replacing key.
- Pet behavior remains presentation-independent: it reacts to domain event or
  interaction intent, not to transport implementation.
- Media cards are valid interaction targets after preview is rendered.

## 8. Accessibility and responsive rules

- Text contrast must meet WCAG AA for bubble text and status labels.
- Every attachment and retry control has semantic label.
- Hit targets minimum 44 logical pixels.
- Do not encode meaning by color alone; status also uses icon/text.
- Composer respects keyboard insets and safe areas.

## 9. Implementation boundaries

Phase 3:

- Add Riverpod providers for repository, room messages, connection, and draft.
- Keep fake adapters as default composition root.
- Adapt `MessageContent` pattern matching into presentation widgets.

Phase 4:

- Replace legacy message rendering with domain-backed widgets.
- Add composer and attachment picker flow.
- Add lifecycle/status/progress/retry rendering.
- Preserve `PetWorldOverlay` layering and bounds synchronization.

Out of scope for first UI pass:

- Full video playback engine.
- Message reactions/replies/read receipts.
- Pagination and local database persistence.
- Final visual branding and Figma component library.

## 10. Acceptance checklist

- Text send appears immediately, then becomes sent.
- Image/video preview appears before upload completes.
- Progress is visible and does not reorder messages.
- Failure preserves message and exposes retry.
- Duplicate incoming event creates one visible message.
- Pet overlay still follows cards during scroll and status updates.
- Room switching does not mix messages between rooms.
