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

Current direction:

- Build and validate UI flow with replaceable fake adapters first.
- Keep domain models independent from backend DTOs and wire-level message type numbers.
- Use Riverpod for dependency injection, lifecycle, room state, send state, and upload progress.
- Use Freezed for immutable domain models, DTOs, state, and content unions.
- Delay Drift, Retrofit, full video playback, offline persistence, and resumable uploads.
