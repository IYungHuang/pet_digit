# Chat Pet MVP Design

## Goal

Build a runnable Flutter prototype where an 8-bit pet inhabits a local fake chat room, uses message bubbles as platforms, reacts to emoji/GIF messages, and can move between rooms.

## Scope

- Local fake chat data only.
- No login, backend, LLM, networking, or asset pipeline.
- macOS, iOS, and Android-compatible Flutter widgets.
- Modern chat UI with a pixel-art-inspired pet rendered by `CustomPainter`.
- Deterministic domain model suitable for unit tests.

## Architecture

`ChatShell` owns room selection and ordinary message rendering. `PetWorldOverlay` is layered above the message list and owns pet presentation. `PetWorldController` maps room messages to `WorldObject`s and advances a small state machine: idle, walk, run, jump, observe, and pounce.

The domain boundary is `PetInteractable`: message bubbles expose platform behavior, emoji exposes toy behavior, and GIF/animated messages expose interest behavior. UI does not know how pet decisions are made.

## Data flow

`FakeChatRepository` → `ChatRoom`/`ChatMessage` → `ChatShell` and `PetWorldController` → `PetWorldOverlay`.

Room changes replace the active world object list and reset pet position to the room entrance. Tapping an emoji or GIF sends an interaction event to the controller; the next animation state reflects the object type.

## Acceptance criteria

1. App launches into a fake room with visible messages and pet.
2. User can switch between at least two rooms.
3. Pet visibly cycles through idle/walk behavior and can jump onto a message bubble.
4. Emoji tap triggers toy interaction.
5. GIF/animated message tap triggers observe/pounce behavior.
6. Domain tests cover room switching and object reactions.
7. README documents setup, run, architecture, and extension points.
