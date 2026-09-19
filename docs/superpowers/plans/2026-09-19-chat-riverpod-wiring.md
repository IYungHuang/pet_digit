# Phase 3: Riverpod Wiring

## Goal

Wire the existing fake message flow into Riverpod without changing chat UI or
introducing backend transport.

## Scope

- Add `flutter_riverpod`.
- Provide one repository instance per provider scope.
- Connect/disconnect repository with provider lifecycle.
- Expose initial and live room messages.
- Expose a send command that preserves repository-owned message lifecycle.
- Test provider overrides and lifecycle behavior.

## Non-goals

- Chat composer widgets.
- Media picker or preview UI.
- Real Dio/WebSocket adapters.
- Replacing legacy `ChatShell`.

## Design

```text
chatRepositoryProvider
  -> chatConnectionProvider
  -> roomMessagesProvider(roomId)
  -> sendMessageProvider
```

Fake adapters remain the default composition root. Tests override the
repository, so UI wiring does not depend on fake implementation details.

## Acceptance

- [x] Provider scope creates one repository instance.
- [x] Watching connection connects repository.
- [x] Provider disposal disconnects repository.
- [x] Room provider yields initial messages and subsequent snapshots.
- [x] Send command delegates draft and progress callback to repository.
- [x] Existing test suite remains green.
