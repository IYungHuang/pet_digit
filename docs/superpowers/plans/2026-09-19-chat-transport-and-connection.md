# Phase 8-9: Transport Adapters and Connection UI

Status: complete; production provider composition remains deferred.

## Delivered

- [x] Dio adapter posts Gespraech `message/add` contracts: text `type=0`, image
  `type=2`, video `type=6`.
- [x] Multipart media uploads use local picker paths and expose progress.
- [x] WebSocket adapter decodes `roomId` + `param` message envelopes.
- [x] Mapper covers text, image/GIF, video, server/client IDs, timestamps, and
  ignores unsupported types.
- [x] Connection states are exposed through event-source streams.
- [x] WebSocket drops trigger bounded exponential-backoff reconnect; exhausted
  attempts emit `offline`.
- [x] Chat UI displays transient connection banner states.
- [x] Fake-first provider remains default, so backend is not contacted by demo
  or widget tests.
- [x] Analyzer and full test suite pass.

## Deferred integration

Production composition must inject authenticated `Dio` and WebSocket URI,
headers/token refresh, reconnect backoff, and staging-verified response fields.
